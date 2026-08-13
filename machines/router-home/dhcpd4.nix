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

      { MACAddress = "f4:70:18:5b:df:e2"; Address = "192.168.1.54"; } # zvoncek-vchod (EZVIZ HP7 Pro)
      { MACAddress = "50:91:e3:d0:d5:15"; Address = "192.168.1.55"; } # kamera-detska-poschodie (Tapo C225)

      { MACAddress = "ec:b5:fa:aa:37:9d"; Address = "192.168.1.60"; } # hue-bridge
      { MACAddress = "d4:d4:da:35:95:f4"; Address = "192.168.1.70"; } # svetlo-pracovna (Shelly Plus 1PM)
      { MACAddress = "08:b6:1f:cc:18:0c"; Address = "192.168.1.71"; } # zaluzia-pracovna (Shelly Plus 2PM)
      { MACAddress = "8c:bf:ea:94:e0:4c"; Address = "192.168.1.72"; } # zaluzia-obyvacka-hsportal (Shelly 2PM G3)
      { MACAddress = "8c:bf:ea:99:de:74"; Address = "192.168.1.73"; } # zaluzia-obyvacka-fix (Shelly 2PM G3)
      { MACAddress = "e4:b3:23:13:d5:c4"; Address = "192.168.1.74"; } # zaluzia-detska-prizemie-fix (Shelly 2PM G3)
      { MACAddress = "8c:bf:ea:9b:8b:40"; Address = "192.168.1.75"; } # zaluzia-detska-prizemie-zahrada (Shelly 2PM G3)
      { MACAddress = "d4:d4:da:ec:69:ac"; Address = "192.168.1.76"; } # zasuvka-cerpadlo-tuv (Shelly Plug S, obehove cerpadlo TUV)
      { MACAddress = "08:92:72:4f:ae:04"; Address = "192.168.1.77"; } # zavlaha (Shelly XT1 irrigation)

      # HA discovers the Gree units by broadcast; the leases only pin the addresses.
      { MACAddress = "c0:39:37:8c:93:39"; Address = "192.168.1.80"; } # klima-obyvacka
      { MACAddress = "c0:39:37:b1:2b:52"; Address = "192.168.1.81"; } # klima-pracovna
      { MACAddress = "c0:39:37:b0:db:ee"; Address = "192.168.1.82"; } # klima-spalna
      { MACAddress = "c0:39:37:b0:82:2c"; Address = "192.168.1.83"; } # klima-detska-prizemie
      { MACAddress = "c0:39:37:a0:f0:e3"; Address = "192.168.1.84"; } # klima-detska-poschodie
      { MACAddress = "c0:39:37:a1:41:cf"; Address = "192.168.1.85"; } # klima-izba3
      { MACAddress = "00:0a:5c:85:15:35"; Address = "192.168.1.86"; } # ovladac-tepelne-cerpadlo

      { MACAddress = "44:27:45:5d:09:dc"; Address = "192.168.1.90"; } # chladnicka-kuchyna
      { MACAddress = "04:7b:cb:d1:00:2f"; Address = "192.168.1.91"; } # zmakcovac-technicka
      { MACAddress = "ec:30:8e:2b:12:54"; Address = "192.168.1.92"; } # kosacka-zahrada
      { MACAddress = "b0:4a:39:ba:fb:8e"; Address = "192.168.1.93"; } # vysavac-prizemie
      { MACAddress = "b0:4a:39:31:04:a7"; Address = "192.168.1.94"; } # vysavac-poschodie
      { MACAddress = "cc:98:8b:9f:33:7b"; Address = "192.168.1.95"; } # tv-obyvacka
      { MACAddress = "ac:9b:0a:30:0c:42"; Address = "192.168.1.96"; } # reprak-prenosny (Sony SRS-X77, wired port)

      # Inside the dynamic pool on purpose; the lease keeps .100 from being handed out.
      { MACAddress = "08:bf:b8:01:ff:f0"; Address = "192.168.1.100"; } # box (pracovna)

      { MACAddress = "02:00:00:00:01:08"; Address = "192.168.1.108"; } # reserved: Dahua factory default

      # Static in the unit's own web UI, never requested; the lease only keeps
      # the pool from handing .119 to somebody else and breaking Modbus from HA.
      { MACAddress = "00:12:13:16:80:02"; Address = "192.168.1.119"; } # rekuperacia (Komfovent C6)
    ];
  };
}
