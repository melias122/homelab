{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ppp
  ];

  # Contains `name` and `password` pppd options.
  age.secrets.pppd-telekom-home.file = ../../secrets/pppd-telekom-home.age;

  services.pppd = {
    enable = true;
    peers = {
      telekom = {
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

          # Probe whether Telekom does v6 on PPPoE; a rejected IPV6CP leaves
          # pppd IPv4-only, so this is safe to keep.
          +ipv6
        '';
      };
    };
  };
}
