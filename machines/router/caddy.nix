{ config, pkgs, ... }:

{
  services.caddy = {
    enable = true;
    email = "melias122@gmail.com";
    extraConfig = ''
      elias.sx  {
        reverse_proxy http://server.elias.sx:54380
      }

      www.elias.sx {
        redir https://elias.sx{uri}
      }
    '';
  };
}
