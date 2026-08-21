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

          # Ask for IPV6CP on the session (link-local only, probe whether
          # Telekom supports v6 on PPPoE). If the BRAS rejects it, pppd
          # continues IPv4-only, so this is safe to keep enabled. Routable
          # v6 would additionally need RA/DHCPv6-PD handling on ppp0.
          +ipv6
        '';
      };
    };
  };
}
