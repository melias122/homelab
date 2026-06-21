{ config, pkgs, ... }:

let
  x = import ../../x/config.nix;

in {
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.4"
      ];
      hash = "sha256-8yZDrejNKsaUnUaTUFYbarWNmxafqp2z2rWo+XRsxV8=";
    };
    email = "melias122@gmail.com";

    virtualHosts.${config.services.nextcloud.hostName}.extraConfig = ''
      tls {
        dns cloudflare ${x.cloudflare-token}
      }
      reverse_proxy http://100.98.141.25:54443
    '';

    virtualHosts."unifi.elias.sx".extraConfig = ''
      tls {
        dns cloudflare ${x.cloudflare-token}
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
  };
}
