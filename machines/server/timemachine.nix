{ config, pkgs, ... }:

{
  services.avahi.extraServiceFiles = {
    timemachine = ''
      <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
       <name replace-wildcards="yes">%h</name>
       <service>
        <type>_adisk._tcp</type>
        <txt-record>sys=waMa=0,adVF=0x100</txt-record>
        <txt-record>dk0=adVN=timemachine,adVF=0x82</txt-record>
       </service>
       <service>
        <type>_smb._tcp</type>
        <port>445</port>
       </service>
       <service>
        <type>_device-info._tcp</type>
        <txt-record>model=TimeCapsule8,119</txt-record>
       </service>
      </service-group>
    '';
  };

  services.samba = {
    enable = true;
    openFirewall = false; # firewall is off, the server sits behind NAT
    settings = {
      global = {
        security = "user";
        "server role" = "standalone server";
        "map to guest" = "never";
        "server min protocol" = "SMB3_00";
        "dns proxy" = "no";
        "load printers" = "no";
        "printing" = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";

        # Apple interop
        "vfs objects" = "fruit streams_xattr";
        "fruit:aapl" = "yes";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:nfs_aces" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";

        # Durable handles: the TM session survives short dropouts/sleep.
        "durable handles" = "yes";
        "kernel oplocks" = "no";
        "kernel share modes" = "no";
        "posix locking" = "no";
        "smb2 leases" = "yes";
      };

      timemachine = {
        path = "/pool/timemachine";
        "valid users" = "melias122";
        browseable = "yes";
        "read only" = "no";
        "inherit acls" = "yes";
        "fruit:time machine" = "yes";
        # Cap for TM so it doesn't eat the pool; ZFS refquota=1T is the
        # second safeguard.
        "fruit:time machine max size" = "950G";
      };
    };
  };
}
