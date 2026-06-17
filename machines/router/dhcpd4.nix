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
            pool = "192.168.2.100 - 192.168.2.250";
          }];
          subnet = "192.168.2.0/24";
          interface = "eno1";
          option-data = [
            { name = "routers"; data = "192.168.2.1"; }
            { name = "domain-name-servers"; data = "192.168.2.1"; }
          ];
          reservations = [
            { hw-address = "80:2a:a8:40:3b:1c"; ip-address = "192.168.2.10"; hostname = "unifi-ap-pivnica"; }
            { hw-address = "80:2a:a8:80:0d:fb"; ip-address = "192.168.2.11"; hostname = "unifi-ap-prizemie"; }
          ];
        }
      ];
    };
  };
}
