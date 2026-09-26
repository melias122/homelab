{ config, lib, pkgs, ... }:

let
  # The target moves into ?target=, the probe is answered by the local exporter.
  blackboxRelabel = [
    { source_labels = [ "__address__" ]; target_label = "__param_target"; }
    { source_labels = [ "__param_target" ]; target_label = "instance"; }
    { target_label = "__address__"; replacement = "100.98.141.25:9115"; }
  ];

  textfileDir = "/var/lib/prometheus-node-exporter-textfile";

  # Staleness alert in alerts.yml: catches a timer that never fires, which
  # SystemdUnitFailed cannot see.
  resticStamp = pkgs.writeShellScript "restic-stamp" ''
    printf 'restic_backup_last_success_seconds{repo="%s"} %s\n' "$1" "$(date +%s)" \
      > "${textfileDir}/restic-$1.prom.tmp"
    mv "${textfileDir}/restic-$1.prom.tmp" "${textfileDir}/restic-$1.prom"
  '';
in
{
  # No firewall on this host: the tailnet bind addresses are what keep every
  # exporter and web UI off the LAN.
  services.prometheus.exporters.node.listenAddress = "100.98.141.25";

  # Explicit list: auto-discovery misses the NVMe. Namespace block device, not
  # /dev/nvme0: the char device is root-only, DynamicUser reads via group disk.
  services.prometheus.exporters.smartctl = {
    enable = true;
    listenAddress = "100.98.141.25";
    devices = [ "/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd" "/dev/sde" "/dev/nvme0n1" "/dev/nvme1n1" ];
  };

  services.prometheus.exporters.apcupsd = {
    enable = true;
    listenAddress = "100.98.141.25";
  };

  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = "100.98.141.25";
    configFile = ./blackbox.yml;
  };

  # Password of the read-only UniFi admin "unpoller".
  age.secrets.unpoller-pass = {
    file = ../../secrets/unpoller-pass.age;
    # The module's service user, not the UniFi login.
    owner = "unifi-poller";
  };

  services.unpoller = {
    enable = true;
    # The module's InfluxDB output defaults to a nonexistent local DB and logs errors.
    influxdb.disable = true;
    prometheus.http_listen = "100.98.141.25:9130";
    unifi.defaults = {
      url = "https://127.0.0.1:8443";
      user = "unpoller";
      pass = config.age.secrets.unpoller-pass.path;
      verify_ssl = false;
    };
  };

  # Local repo only: a B2 exporter would burn paid API calls on every refresh,
  # B2 freshness comes from the textfile stamp below.
  services.prometheus.exporters.restic = {
    enable = true;
    listenAddress = "100.98.141.25";
    repository = "/backup/restic";
    passwordFile = config.age.secrets.restic-password.path;
    refreshInterval = 3600;
  };

  # The repo and its password are root-only and the same root runs the
  # backups. PrivateUsers would map root to nobody and break repo access;
  # restic needs to write lock files into the ProtectSystem=strict repo path.
  systemd.services.prometheus-restic-exporter = {
    # `restic check` takes an exclusive lock and would collide with the nightly backups.
    environment.NO_CHECK = "true";

    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = lib.mkForce "root";
      Group = lib.mkForce "root";
      PrivateUsers = lib.mkForce false;
      ReadWritePaths = [ "/backup/restic" ];
      # The repo dir is mode 600, so even root needs DAC caps; the module empties the set.
      CapabilityBoundingSet = lib.mkForce [ "CAP_DAC_OVERRIDE" "CAP_DAC_READ_SEARCH" ];
    };
  };

  services.prometheus.exporters.node.extraFlags = [
    "--collector.textfile.directory=${textfileDir}"
  ];

  systemd.tmpfiles.rules = [ "d ${textfileDir} 0755 root root -" ];

  # Mastertherm heat pump: the pGDx touch controller serves the pCO variables over
  # Modbus TCP, register map in ./mastertherm-modbus.yml. nixpkgs ships the package
  # but no exporters.modbus module. Multi-target exporter: the scrape job below
  # passes the device in ?target=.
  systemd.services.prometheus-modbus-exporter = {
    description = "Prometheus Modbus exporter";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.prometheus-modbus-exporter}/bin/modbus_exporter --config.file=${./mastertherm-modbus.yml} --web.listen-address=100.98.141.25:9602";
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # Without a seed the staleness alerts fire (or stay blind) until the first timer run.
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

  # A running scrub drops the pool out of the file until it finishes; the
  # staleness alert tolerates that (absent = no data).
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

    # The server needs its FQDN: the bare name resolves to scoped IPv6
    # self-entries, not the tailnet IPv4 the exporters are bound to.
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
        # Per-request metrics need "servers { metrics }" in caddy.nix.
        job_name = "caddy";
        static_configs = [{ targets = [ "127.0.0.1:2019" ]; }];
      }
      {
        # Internal unauthenticated API port, tailnet-only in frigate.nix.
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
      {
        job_name = "mastertherm";
        metrics_path = "/modbus";
        params = {
          target = [ "192.168.1.86:502" ];
          module = [ "mastertherm" ];
          sub_target = [ "1" ];
        };
        scrape_interval = "30s";
        static_configs = [{ targets = [ "100.98.141.25:9602" ]; }];
      }
    ];

    ruleFiles = [ ./alerts.yml ];

    alertmanagers = [{
      static_configs = [{ targets = [ "100.98.141.25:9093" ]; }];
    }];
  };

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

      # 26.05 requires an explicit secret_key.
      security.secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";

      analytics.reporting_enabled = false;

      # Tailnet-only, so anonymous viewing is fine; log in as admin to edit.
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

  # Dead-man's switch: the always-firing Watchdog alert pings healthchecks.io,
  # independent of the mail path; when the pings stop it alarms from outside.
  # The ping URL is a secret: anyone who has it can fake the pings.
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

  # autoUpgrade can die between "stopping" and "starting" units (2026-09-20:
  # systemd 260.2→260.4 reexec hung past the 180s limit, ~45 units incl. HA
  # stayed down 3h). Re-run the switch for the now-current generation to start
  # them, and flip the deadman check to failed so healthchecks alerts.
  systemd.services.nixos-upgrade.onFailure = [ "nixos-upgrade-recover.service" ];
  systemd.services.nixos-upgrade-recover = {
    path = [ pkgs.curl ];
    serviceConfig = {
      Type = "oneshot";
      LoadCredential = [ "hc-ping-url:${config.age.secrets.hc-ping-url.path}" ];
    };
    script = ''
      curl -fsS -m 10 --retry 3 --data-raw "nixos-upgrade failed, re-running switch-to-configuration" \
        "$(< "$CREDENTIALS_DIRECTORY/hc-ping-url")/fail" || true
      /run/current-system/bin/switch-to-configuration switch
    '';
  };
}
