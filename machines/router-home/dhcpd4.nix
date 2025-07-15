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
            { hw-address = "68:d7:9a:22:65:25"; ip-address = "192.168.1.2";  hostname = "unifi-switch-usw-pro-24"; }
            { hw-address = "0c:ea:14:cc:aa:c1"; ip-address = "192.168.1.10"; hostname = "unifi-ap-predsien"; }
            { hw-address = "0c:ea:14:c1:10:75"; ip-address = "192.168.1.11"; hostname = "unifi-ap-satnik"; }
            { hw-address = "e0:63:da:21:09:46"; ip-address = "192.168.1.12"; hostname = "unifi-ap-poschodie"; }
            { hw-address = "68:d7:9a:1c:33:1e"; ip-address = "192.168.1.13"; hostname = "unifi-ap-terasa"; }
            { hw-address = "e4:e7:49:a5:1e:86"; ip-address = "192.168.1.21"; hostname = "tlaciaren"; }
            { hw-address = "48:5f:99:2c:00:25"; ip-address = "192.168.1.22"; hostname = "tlaciaren-wifi"; }
          ];
        }
      ];
    };
  };
}
