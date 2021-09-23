{ config, pkgs, ... }:
let
  secrets = import ../../secrets.nix;
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
          plugin rp-pppoe.so eno2

          name ${secrets.tcom.username}
          password ${secrets.tcom.password}

          persist
          maxfail 0
          holdoff 5

          noipdefault
          defaultroute
        '';
      };
    };
  };
}
