{ config, pkgs, ... }:

{
  services.dhcpd4 = {
    enable = true;
    interfaces = [ "eno1" ];
    machines = [
      { ethernetAddress = "68:d7:9a:22:65:25"; ipAddress = "192.168.1.2";  hostName = "UnifiSW-USW-Pro-24"; }
      { ethernetAddress = "80:2a:a8:40:3b:1c"; ipAddress = "192.168.1.10"; hostName = "UnifiAP-pivnica"; }
      { ethernetAddress = "80:2a:a8:80:0d:fb"; ipAddress = "192.168.1.11"; hostName = "UnifiAP-prizemie"; }
      { ethernetAddress = "e0:63:da:21:09:46"; ipAddress = "192.168.1.12"; hostName = "UnifiAP-poschodie"; }
      { ethernetAddress = "00:24:a6:00:31:82"; ipAddress = "192.168.1.20"; hostName = "Digibit-R1"; }
      { ethernetAddress = "e4:e7:49:a5:1e:86"; ipAddress = "192.168.1.21"; hostName = "Tlaciaren"; }

      { ethernetAddress = "0c:c4:7a:44:52:ea"; ipAddress = "192.168.1.35"; hostName = "Server-IPMI"; }
      # { ethernetAddress = "0c:c4:7a:44:53:14"; ipAddress = "192.168.1.45"; hostName = "Server-1GbE-LAN1"; }
      # { ethernetAddress = "0c:c4:7a:44:53:15"; ipAddress = "192.168.1.45"; hostName = "Server-1GbE-LAN2"; }
      { ethernetAddress = "00:1b:21:bc:15:67"; ipAddress = "192.168.1.45"; hostName = "Server-10GbE"; }
    ];
    extraConfig = ''
      default-lease-time 86400;
      max-lease-time 86400;

      option domain-name-servers 192.168.1.1, 1.1.1.1;
      option subnet-mask 255.255.255.0;

      subnet 192.168.1.0 netmask 255.255.255.0 {
        option broadcast-address 192.168.1.255;
        option routers 192.168.1.1;
        option domain-name-servers 192.168.1.1;
        interface eno1;
        range 192.168.1.100 192.168.1.200;
      }
    '';
  };
}
