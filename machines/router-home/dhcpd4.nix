{ config, pkgs, ... }:

{
  systemd.network.networks."10-lan" = {
    networkConfig.DHCPServer = true;

    dhcpServerConfig = {
      PoolOffset = 100;
      PoolSize = 151; # .100 - .250 inclusive
      EmitDNS = true;
      DNS = "192.168.1.1";
    };

    dhcpServerStaticLeases = [
      { MACAddress = "68:d7:9a:22:65:25"; Address = "192.168.1.2"; }  # unifi-switch-usw-pro-24
      { MACAddress = "74:fa:29:5f:26:06"; Address = "192.168.1.3"; }  # unifi-switch-usw-pro-max-16-poe
      { MACAddress = "0c:ea:14:cc:aa:c1"; Address = "192.168.1.10"; } # unifi-ap-predsien
      { MACAddress = "0c:ea:14:c1:10:75"; Address = "192.168.1.11"; } # unifi-ap-satnik
      { MACAddress = "e0:63:da:21:09:46"; Address = "192.168.1.12"; } # unifi-ap-poschodie
      { MACAddress = "68:d7:9a:1c:33:1e"; Address = "192.168.1.13"; } # unifi-ap-terasa
      { MACAddress = "e4:e7:49:a5:1e:86"; Address = "192.168.1.21"; } # tlaciaren
      { MACAddress = "48:5f:99:2c:00:25"; Address = "192.168.1.22"; } # tlaciaren-wifi
      { MACAddress = "0c:c4:7a:44:53:14"; Address = "192.168.1.45"; } # server

      { MACAddress = "30:dd:aa:77:ad:ca"; Address = "192.168.1.50"; } # cam1
      { MACAddress = "30:dd:aa:77:af:13"; Address = "192.168.1.51"; } # cam2
      { MACAddress = "30:dd:aa:77:ab:af"; Address = "192.168.1.52"; } # cam3
      { MACAddress = "30:dd:aa:77:b2:1b"; Address = "192.168.1.53"; } # cam4
    ];
  };
}
