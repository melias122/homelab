{ config, lib, pkgs, ... }:

let
  # Standard blackbox pattern: the target moves into ?target=, the probe
  # itself is answered by the exporter on this host.
  blackboxRelabel = [
    { source_labels = [ "__address__" ]; target_label = "__param_target"; }
    { source_labels = [ "__param_target" ]; target_label = "instance"; }
    { target_label = "__address__"; replacement = "100.98.141.25:9115"; }
  ];

  textfileDir = "/var/lib/prometheus-node-exporter-textfile";

  # Writes a "last success" timestamp after a restic backup finishes;
  # alerted on staleness in alerts.yml (catches a timer that never fires,
  # which the SystemdUnitFailed alert cannot see).
  resticStamp = pkgs.writeShellScript "restic-stamp" ''
    printf 'restic_backup_last_success_seconds{repo="%s"} %s\n' "$1" "$(date +%s)" \
      > "${textfileDir}/restic-$1.prom.tmp"
    mv "${textfileDir}/restic-$1.prom.tmp" "${textfileDir}/restic-$1.prom"
  '';
in
{
  # Prometheus + Alertmanager with mail-only alerting through the local
  # postfix relay (services/postfix.nix). Tailscale-only like Home Assistant:
  # the firewall is disabled on this host, so the bind address is what keeps
  # the web UIs off the LAN. Prometheus: http://server:9090, Alertmanager:
  # http://server:9093 over the tailnet.

  # No firewall on this host, so bind node_exporter to the tailnet IP too.
  services.prometheus.exporters.node.listenAddress = "100.98.141.25";

  # SMART health of the physical disks. Explicit list: auto-discovery misses
  # the NVMe here. The namespace block device, not /dev/nvme0: the char
  # device is root-only and the exporter's DynamicUser reads via group disk.
  services.prometheus.exporters.smartctl = {
    enable = true;
    listenAddress = "100.98.141.25";
    devices = [ "/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd" "/dev/nvme0n1" ];
  };

  # UPS metrics from the local apcupsd NIS socket (127.0.0.1:3551).
  services.prometheus.exporters.apcupsd = {
    enable = true;
    listenAddress = "100.98.141.25";
  };

  # Active probes: HTTPS vhosts (incl. cert expiry), ICMP to WAN and both
  # routers, DNS against blocky. Modules in ./blackbox.yml.
  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = "100.98.141.25";
    configFile = ./blackbox.yml;
  };

  # UniFi controller metrics (APs, clients, ports). Needs a local read-only
  # UniFi admin named "unpoller"; its password lives in the agenix secret.
  age.secrets.unpoller-pass = {
    file = ../../secrets/unpoller-pass.age;
    # The module's service user (not "unpoller" - that's the UniFi login).
    owner = "unifi-poller";
  };

  services.unpoller = {
    enable = true;
    # Prometheus only; the module's InfluxDB output defaults to a
    # nonexistent local DB and just logs errors.
    influxdb.disable = true;
    prometheus.http_listen = "100.98.141.25:9130";
    unifi.defaults = {
      url = "https://127.0.0.1:8443";
      user = "unpoller";
      pass = config.age.secrets.unpoller-pass.path;
      verify_ssl = false;
    };
  };

  # Snapshot counts / repo size / latest-snapshot age of the local restic
  # repo for the Backups dashboard. B2 on purpose has no live exporter
  # (each refresh would burn paid B2 API calls); its freshness comes from
  # the textfile stamp below.
  services.prometheus.exporters.restic = {
    enable = true;
    listenAddress = "100.98.141.25";
    repository = "/backup/restic";
    passwordFile = config.age.secrets.restic-password.path;
    refreshInterval = 3600;
  };

  # The repo and its password are (rightly) root-only, and the same root
  # already runs the backups; the exporter only exposes aggregate numbers
  # on the tailnet. PrivateUsers would map root to nobody inside the
  # sandbox, which is what breaks repo access, and restic needs to write
  # its lock files into the (ProtectSystem=strict) repo path.
  systemd.services.prometheus-restic-exporter = {
    # `restic check` takes an exclusive lock and would eventually collide
    # with the nightly backups; snapshots/stats are enough for the metrics.
    environment.NO_CHECK = "true";

    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "root";
      Group = lib.mkForce "root";
      PrivateUsers = lib.mkForce false;
      ReadWritePaths = [ "/backup/restic" ];
      # The repo dir is mode 600 (no traverse bit), so even root needs
      # DAC capabilities - the module empties the bounding set.
      CapabilityBoundingSet = lib.mkForce [ "CAP_DAC_OVERRIDE" "CAP_DAC_READ_SEARCH" ];
    };
  };

  # Textfile collector carries the restic/scrub stamps below.
  services.prometheus.exporters.node.extraFlags = [
    "--collector.textfile.directory=${textfileDir}"
  ];

  systemd.tmpfiles.rules = [ "d ${textfileDir} 0755 root root -" ];

  # Seed the stamps at activation so the staleness alerts don't fire (or
  # stay blind) between deploy and the first timer run.
  system.activationScripts.monitoring-stamps.text = ''
    mkdir -p ${textfileDir}
    for repo in local b2; do
      f="${textfileDir}/restic-$repo.prom"
      if [ ! -e "$f" ]; then
        printf 'restic_backup_last_success_seconds{repo="%s"} %s\n' "$repo" "$(date +%s)" > "$f"
      fi
    done
  '';

  systemd.services."restic-backups-local".serviceConfig.ExecStartPost = "${resticStamp} local";
  systemd.services."restic-backups-b2".serviceConfig.ExecStartPost = "${resticStamp} b2";

  # Timestamp of each pool's last finished scrub, parsed from zpool status.
  # While a scrub is running the pool drops out of the file until it
  # finishes; the staleness alert tolerates that (absent = no data).
  systemd.services.zfs-scrub-stamp = {
    script = ''
      tmp="${textfileDir}/zfs-scrub.prom.tmp"
      : > "$tmp"
      for pool in $(${pkgs.zfs}/bin/zpool list -H -o name); do
        d=$(LC_ALL=C ${pkgs.zfs}/bin/zpool status "$pool" | ${pkgs.gnused}/bin/sed -n 's/.*errors on \(.*\)$/\1/p' | tail -n1)
        if [ -n "$d" ]; then
          printf 'zfs_last_scrub_seconds{zpool="%s"} %s\n' "$pool" "$(date -d "$d" +%s)" >> "$tmp"
        fi
      done
      mv "$tmp" "${textfileDir}/zfs-scrub.prom"
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.zfs-scrub-stamp = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  services.prometheus = {
    enable = true;
    listenAddress = "100.98.141.25";

    # Targets resolve through MagicDNS (search robin-shark.ts.net). The server
    # itself needs the FQDN: the bare name resolves to its scoped IPv6
    # self-entries, not the tailnet IPv4 the exporter is bound to.
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [
            "server.robin-shark.ts.net:9100"
            "router-home:9100"
            "router:9100"
          ];
        }];
      }
      {
        job_name = "smartctl";
        static_configs = [{ targets = [ "server.robin-shark.ts.net:9633" ]; }];
      }
      {
        job_name = "apcupsd";
        static_configs = [{ targets = [ "server.robin-shark.ts.net:9162" ]; }];
      }
      {
        job_name = "blackbox-http";
        metrics_path = "/probe";
        params.module = [ "http_2xx" ];
        static_configs = [{
          targets = [
            "https://nextcloud.elias.sx"
            "https://frigate.elias.sx"
            "https://unifi.elias.sx"
          ];
        }];
        relabel_configs = blackboxRelabel;
      }
      {
        job_name = "blackbox-icmp";
        metrics_path = "/probe";
        params.module = [ "icmp" ];
        static_configs = [{
          targets = [
            "1.1.1.1"
            "router-home"
            "router"
          ];
        }];
        relabel_configs = blackboxRelabel;
      }
      {
        job_name = "blackbox-dns";
        metrics_path = "/probe";
        params.module = [ "dns" ];
        static_configs = [{
          targets = [
            "router-home:53"
            "router:53"
          ];
        }];
        relabel_configs = blackboxRelabel;
      }
      {
        job_name = "blocky";
        static_configs = [{ targets = [ "router-home:4000" "router:4000" ]; }];
      }
      {
        # Caddy admin endpoint; per-request metrics need the global
        # "servers { metrics }" option (see caddy.nix).
        job_name = "caddy";
        static_configs = [{ targets = [ "127.0.0.1:2019" ]; }];
      }
      {
        # Frigate 0.16+ native metrics on the internal (unauthenticated)
        # API port, published tailnet-only in frigate.nix.
        job_name = "frigate";
        metrics_path = "/api/metrics";
        static_configs = [{ targets = [ "100.98.141.25:5000" ]; }];
      }
      {
        job_name = "unpoller";
        static_configs = [{ targets = [ "100.98.141.25:9130" ]; }];
      }
      {
        job_name = "restic";
        static_configs = [{ targets = [ "100.98.141.25:9753" ]; }];
      }
    ];

    ruleFiles = [ ./alerts.yml ];

    alertmanagers = [{
      static_configs = [{ targets = [ "100.98.141.25:9093" ]; }];
    }];
  };

  # Dashboards on http://server:3000 over the tailnet. Anonymous viewing is
  # fine there; log in as admin to edit. The homelab dashboard is provisioned
  # from ./dashboards and managed in this repo.
  age.secrets.grafana-secret-key = {
    file = ../../secrets/grafana-secret-key.age;
    owner = "grafana";
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "100.98.141.25";
        http_port = 3000;
      };

      # 26.05 requires an explicit secret_key (encrypts secrets in the
      # Grafana DB, of which we have none, but set a real one anyway).
      security.secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";

      analytics.reporting_enabled = false;

      "auth.anonymous" = {
        enabled = true;
        org_role = "Viewer";
      };
    };

    provision = {
      enable = true;

      datasources.settings.datasources = [{
        name = "Prometheus";
        type = "prometheus";
        uid = "prometheus";
        url = "http://100.98.141.25:9090";
        isDefault = true;
      }];

      dashboards.settings.providers = [{
        name = "homelab";
        options.path = ./dashboards;
      }];
    };
  };

  # Dead-man's switch: the always-firing Watchdog alert pings healthchecks.io
  # every few minutes over a webhook (independent of the postfix/gmail mail
  # path); when the pings stop, healthchecks.io alarms from the outside.
  # The ping URL is a secret - anyone who has it can fake the pings.
  age.secrets.hc-ping-url.file = ../../secrets/hc-ping-url.age;

  systemd.services.alertmanager.serviceConfig.LoadCredential = [
    "hc-ping-url:${config.age.secrets.hc-ping-url.path}"
  ];

  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = "100.98.141.25";

    # Single instance: don't listen for HA cluster gossip on 0.0.0.0:9094.
    extraFlags = [ "--cluster.listen-address=" ];

    configuration = {
      route = {
        receiver = "email";
        group_by = [ "alertname" ];
        group_wait = "1m";
        group_interval = "15m";
        repeat_interval = "24h";

        routes = [{
          matchers = [ "alertname=\"Watchdog\"" ];
          receiver = "deadman";
          group_wait = "15s";
          group_interval = "1m";
          repeat_interval = "4m";
        }];
      };

      receivers = [
        {
          name = "email";
          email_configs = [{
            to = "martin@elias.sx";
            from = "alertmanager@elias.sx";
            smarthost = "127.0.0.1:25";
            require_tls = false;
            send_resolved = true;
          }];
        }
        {
          name = "deadman";
          webhook_configs = [{
            url_file = "/run/credentials/alertmanager.service/hc-ping-url";
            send_resolved = false;
          }];
        }
      ];
    };
  };
}
