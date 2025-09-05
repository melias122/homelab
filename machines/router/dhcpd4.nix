{ config, pkgs, ... }:

{
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "eno1" ];

        # Temporary hack for retrying if interface is not running on startup
        service-sockets-max-retries = 100;
        service-sockets-retry-wait-time = 10000;
      };

      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };

      # https://kea.readthedocs.io/en/kea-2.0.0/arm/dhcp4-srv.html
      valid-lifetime = 4000;
      renew-timer = 1000;
      rebind-timer = 2000;

      subnet4 = [
        {
          id = 1;
          pools = [{
            pool = "192.168.1.100 - 192.168.1.250";
          }];
          subnet = "192.168.1.0/24";
          interface = "eno1";
          option-data = [
            { name = "routers"; data = "192.168.1.1"; }
            { name = "domain-name-servers"; data = "192.168.1.1"; }
          ];
          reservations = [
            { hw-address = "80:2a:a8:40:3b:1c"; ip-address = "192.168.1.10"; hostname = "unifi-ap-pivnica"; }
            { hw-address = "80:2a:a8:80:0d:fb"; ip-address = "192.168.1.11"; hostname = "unifi-ap-prizemie"; }
            { hw-address = "0c:c4:7a:44:52:ea"; ip-address = "192.168.1.35"; hostname = "server-ipmi"; }
            { hw-address = "00:1b:21:bc:15:67"; ip-address = "192.168.1.45"; hostname = "server-10gbe"; }
          ];
        }
      ];
    };
  };
}
