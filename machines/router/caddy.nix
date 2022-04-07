{ config, pkgs, ... }:

{
  services.caddy = {
    enable = true;
    email = "melias122@gmail.com";
    extraConfig = ''
      elias.sx {
          reverse_proxy http://server.elias.sx:54380
      }

      www.elias.sx {
        redir https://elias.sx{uri}
      }

      recepty.elias.sx {
        @private_ranges remote_ip 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 127.0.0.1/8

        route @private_ranges {
          reverse_proxy http://server.elias.sx:54381
        }
        handle {
          abort
        }
      }

      nextcloud.elias.sx {
        reverse_proxy http://server.elias.sx:54443
      }

      unifi.elias.sx {
        @private_ranges remote_ip 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 127.0.0.1/8

        route @private_ranges {
          reverse_proxy https://server.elias.sx:8443 {
            transport http {
              tls_insecure_skip_verify
            }
          }
        }
        handle {
          abort
        }
      }
    '';
  };
}
