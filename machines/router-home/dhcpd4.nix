{ config, pkgs, ... }:

{
  systemd.network.networks."10-lan" = {
    networkConfig.DHCPServer = true;

    dhcpServerConfig = {
      PoolOffset = 100;
      PoolSize = 151; # .100 - .250 inclusive
      DefaultLeaseTimeSec = 43200; # 12h (networkd default is 1h)
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

      # Gree AC units. HA discovers them by broadcast, so these leases are not
      # needed for the integration -- they keep the units at a known address.
      { MACAddress = "c0:39:37:8c:93:39"; Address = "192.168.1.80"; } # klima-obyvacka
      { MACAddress = "c0:39:37:b1:2b:52"; Address = "192.168.1.81"; } # klima-pracovna
      { MACAddress = "c0:39:37:b0:db:ee"; Address = "192.168.1.82"; } # klima-spalna
      { MACAddress = "c0:39:37:b0:82:2c"; Address = "192.168.1.83"; } # klima-detska-prizemie
      { MACAddress = "c0:39:37:a0:f0:e3"; Address = "192.168.1.84"; } # klima-detska-poschodie
      { MACAddress = "c0:39:37:a1:41:cf"; Address = "192.168.1.85"; } # klima-izba3

      { MACAddress = "02:00:00:00:01:08"; Address = "192.168.1.108"; } # reserved: Dahua factory default

      # Komfovent C6 rekuperacia. The unit has this address configured
      # statically in its own web UI, so the lease is never requested; it is
      # here only to keep the dynamic pool (.100-.250) from handing .119 to
      # somebody else and breaking the Modbus TCP connection from HA.
      { MACAddress = "00:12:13:16:80:02"; Address = "192.168.1.119"; } # rekuperacia (Komfovent C6)
    ];
  };
}
