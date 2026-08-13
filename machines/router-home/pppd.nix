{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ppp
  ];

  # Contains `name` and `password` pppd options.
  age.secrets.pppd-telekom-home.file = ../../secrets/pppd-telekom-home.age;

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

          file ${config.age.secrets.pppd-telekom-home.path}

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
