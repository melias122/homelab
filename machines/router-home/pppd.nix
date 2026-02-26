{ config, pkgs, ... }:
let
  x = import ../../x/config.nix;
in {
  environment.systemPackages = with pkgs; [
    ppp
  ];

  # setup pppoe session
  services.pppd = {
    enable = true;
    peers = {
      telekom = {
        # Autostart the PPPoE session on boot
        autostart = true;
        enable = true;
        config = ''
          plugin pppoe.so eno2

          name ${x.tcom-home.username}
          password ${x.tcom-home.password}

          # PPPoE MTU (1500 - 8 byte PPPoE header)
          # mtu 1492
          # mru 1492

          persist
          maxfail 0
          holdoff 10

          noipdefault
          defaultroute
        '';
      };
    };
  };
}
