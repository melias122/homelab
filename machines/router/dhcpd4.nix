{ config, pkgs, ... }:

{
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "eno1" ];
      };

      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };

      subnet4 = [
        {
          interface = "eno1";
          subnet = "192.168.1.0/24";
          pools = [{ pool = "192.168.1.100 - 192.168.1.240"; }];
          option-data = [
            { name = "domain-name-servers"; data = "192.168.1.1"; }
            { name = "routers"; data = "192.168.1.1"; }
          ];
          reservations = [
            { hw-address = "68:d7:9a:22:65:25"; ip-address = "192.168.1.2";  hostname = "unifi-switch-usw-pro-24"; }
            { hw-address = "80:2a:a8:40:3b:1c"; ip-address = "192.168.1.10"; hostname = "unifi-ap-pivnica"; }
            { hw-address = "80:2a:a8:80:0d:fb"; ip-address = "192.168.1.11"; hostname = "unifi-ap-prizemie"; }
            { hw-address = "e0:63:da:21:09:46"; ip-address = "192.168.1.12"; hostname = "unifi-ap-poschodie"; }
            { hw-address = "68:d7:9a:1c:33:1e"; ip-address = "192.168.1.13"; hostname = "unifi-ap-pracovna"; }
            { hw-address = "00:24:a6:00:31:82"; ip-address = "192.168.1.20"; hostname = "digibit-r1"; }
            { hw-address = "e4:e7:49:a5:1e:86"; ip-address = "192.168.1.21"; hostname = "tlaciaren"; }
            { hw-address = "48:5f:99:2c:00:25"; ip-address = "192.168.1.22"; hostname = "tlaciaren-wifi"; }

            { hw-address = "0c:c4:7a:44:52:ea"; ip-address = "192.168.1.35"; hostname = "server-ipmi"; }
            # { hw-address = "0c:c4:7a:44:53:14"; ip-address = "192.168.1.45"; hostname = "server-1gbe-lan1"; }
            # { hw-address = "0c:c4:7a:44:53:15"; ip-address = "192.168.1.45"; hostname = "server-1gbe-lan2"; }
            { hw-address = "00:1b:21:bc:15:67"; ip-address = "192.168.1.45"; hostname = "server-10gbe"; }
          ];
        }
      ];
    };
  };
}
