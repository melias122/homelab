{ config, pkgs, ... }:

{
  age.secrets.caddy-env.file = ../../secrets/caddy-env.age;

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.4"
      ];
      # Vendor hash of caddy+plugins; changes when the channel bumps caddy or
      # Go. On mismatch nixos-upgrade fails with the new hash in the log
      # ("got: sha256-..."), paste it here.
      hash = "sha256-PWadA5qr/gR2qDcT8l8u1Xku7LM2HIfWTLOkzezCYy0=";
    };
    email = "melias122@gmail.com";

    # Per-request Prometheus metrics, scraped from the admin endpoint
    # (localhost:2019/metrics) by machines/server/monitoring.nix.
    globalConfig = ''
      servers {
        metrics
      }
    '';

    # Contains CF_API_TOKEN for the cloudflare dns plugin.
    environmentFile = config.age.secrets.caddy-env.path;

    virtualHosts.${config.services.nextcloud.hostName}.extraConfig = ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
      }
      reverse_proxy http://100.98.141.25:54443
    '';

    # Devices inform to http://unifi.elias.sx/inform (port 80, no explicit
    # :8080 in the controller's Override Inform Host). Without this, port 80
    # 308-redirects to https and the UniFi inform agent drops the POST, so
    # remote-site APs loop offline. Proxy /inform straight to the inform port;
    # everything else on :80 keeps redirecting to https.
    virtualHosts."http://unifi.elias.sx".extraConfig = ''
      handle /inform* {
        reverse_proxy http://100.98.141.25:8080
      }
      handle {
        redir https://{host}{uri} permanent
      }
    '';

    virtualHosts."unifi.elias.sx".extraConfig = ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
      }

      # Device inform endpoint "set-inform https://unifi.elias.sx/inform"
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
      tls {
        dns cloudflare {env.CF_API_TOKEN}
      }

      @denied not remote_ip 100.64.0.0/10 192.168.1.0/24
      abort @denied

      reverse_proxy http://100.98.141.25:8971
    '';
  };
}
