{ config, pkgs, ... }:

let
  secrets = import ../../secrets.nix;

in {
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      certificatesResolvers.letsencrypt.acme = {
        email = "melias122@gmail.com";
        storage = "/var/lib/traefik/acme.json";
        dnsChallenge.provider = "vultr";
      };

      entryPoints = {
        # External entry points.
        http = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "https";
            scheme = "https";
          };
        };
        https.address = ":443";
      };
    };

    dynamicConfigOptions = {
      http = {
        routers = {
          web = {
            rule = "Host(`elias.sx`)";
            service = "web";
            tls.certResolver = "letsencrypt";
          };
        };

        services = {
          web.loadBalancer.servers = [{ url = "http://server:54380"; }];
        };
      };
    };
  };

  # Looks like there is no other way to pass enviroment to traefik
  systemd.services.traefik.serviceConfig.Environment = "VULTR_API_KEY=${secrets.vultr-api-key}";
}
