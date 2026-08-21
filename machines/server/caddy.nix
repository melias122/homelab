{ config, pkgs, ... }:

let
  # One wildcard cert in /var/lib/acme covers every vhost below.
  certDir = config.security.acme.certs."elias.sx".directory;
in
{
  age.secrets.cf-dns-api-token.file = ../../secrets/cf-dns-api-token.age;

  # Certs come from lego, not caddy's cloudflare plugin: withPlugins pins a hash
  # over the whole xcaddy-vendored Go tree, which changes on any go/xcaddy bump
  # and fails the entire system closure, killing autoUpgrade (twice in 2026-08).
  security.acme = {
    acceptTerms = true;
    defaults.email = "melias122@gmail.com";

    certs."elias.sx" = {
      # DNS-01: these names resolve to tailnet/LAN IPs, HTTP-01 can't reach us.
      domain = "*.elias.sx";
      dnsProvider = "cloudflare";
      credentialFiles."CF_DNS_API_TOKEN_FILE" = config.age.secrets.cf-dns-api-token.path;

      # Public resolver: blocky rewrites elias.sx and would answer for the zone.
      dnsResolver = "1.1.1.1:53";

      # caddy reads the pems from certDir directly, and needs a reload on renewal.
      group = "caddy";
      reloadServices = [ "caddy.service" ];
    };
  };

  # acme-elias.sx.service drops the selfsigned placeholder into certDir on first
  # run; caddy exits 1 on a missing cert file and the module sets
  # RestartPreventExitStatus=1, so losing this race keeps caddy down until
  # started by hand. Not acme-finished-elias.sx.target - this module version
  # never defines it and systemd silently ignores deps on unknown units.
  systemd.services.caddy = {
    after = [ "acme-elias.sx.service" ];
    wants = [ "acme-elias.sx.service" ];
  };

  services.caddy = {
    enable = true;

    # No `email` on purpose: every HTTPS vhost names its cert explicitly. A vhost
    # without a `tls` line falls back to caddy's ACME, which can't do DNS-01.

    # Metrics on localhost:2019/metrics, scraped by monitoring.nix.
    globalConfig = ''
      servers {
        metrics
      }
    '';

    virtualHosts.${config.services.nextcloud.hostName}.extraConfig = ''
      tls ${certDir}/fullchain.pem ${certDir}/key.pem
      reverse_proxy http://100.98.141.25:54443
    '';

    # Devices inform over plain http://unifi.elias.sx/inform; a 308 to https
    # makes the inform agent drop the POST and remote APs loop offline.
    virtualHosts."http://unifi.elias.sx".extraConfig = ''
      handle /inform* {
        reverse_proxy http://100.98.141.25:8080
      }
      handle {
        redir https://{host}{uri} permanent
      }
    '';

    virtualHosts."unifi.elias.sx".extraConfig = ''
      tls ${certDir}/fullchain.pem ${certDir}/key.pem

      handle /inform* {
        reverse_proxy http://100.98.141.25:8080
      }

      handle {
        reverse_proxy https://100.98.141.25:8443 {
          header_up Host {host}
          transport http {
            tls_insecure_skip_verify
          }
        }
      }
    '';

    virtualHosts."frigate.elias.sx".extraConfig = ''
      tls ${certDir}/fullchain.pem ${certDir}/key.pem

      @denied not remote_ip 100.64.0.0/10 192.168.1.0/24
      abort @denied

      reverse_proxy http://100.98.141.25:8971
    '';
  };
}
