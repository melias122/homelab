{ config, pkgs, ... }:

{
  age.secrets.caddy-env.file = ../../secrets/caddy-env.age;

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.4"
      ];
      hash = "sha256-8yZDrejNKsaUnUaTUFYbarWNmxafqp2z2rWo+XRsxV8=";
    };
    email = "melias122@gmail.com";

    # Contains CF_API_TOKEN for the cloudflare dns plugin.
    environmentFile = config.age.secrets.caddy-env.path;

    virtualHosts.${config.services.nextcloud.hostName}.extraConfig = ''
      tls {
        dns cloudflare {env.CF_API_TOKEN}
      }
      reverse_proxy http://100.98.141.25:54443
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
  };
}
