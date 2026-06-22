{ config, pkgs, ... }:

{
  systemd.network.networks."10-lan" = {
    networkConfig.DHCPServer = true;

    dhcpServerConfig = {
      PoolOffset = 100;
      PoolSize = 151; # .100 - .250 inclusive
      EmitDNS = true;
      DNS = "192.168.2.1";
    };

    dhcpServerStaticLeases = [
      { MACAddress = "80:2a:a8:40:3b:1c"; Address = "192.168.2.10"; } # unifi-ap-bazen
      { MACAddress = "80:2a:a8:80:0d:fb"; Address = "192.168.2.11"; } # unifi-ap-prizemie
      { MACAddress = "0c:ea:14:8b:a2:ed"; Address = "192.168.2.12"; } # unifi-ap-pivnica
    ];
  };
}
