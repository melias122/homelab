{ config, pkgs, ... }:

{
  services.avahi.extraServiceFiles = {
    smb = ''
        <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
         <name replace-wildcards="yes">%h</name>
         <service>
          <type>_adisk._tcp</type>
          <txt-record>sys=waMa=0,adVF=0x100</txt-record>
          <txt-record>dk0=adVN=Time Capsule,adVF=0x82</txt-record>
         </service>
         <service>
          <type>_smb._tcp</type>
          <port>445</port>
         </service>
        </service-group>
        '';
  };

  # Most of the Samba configuration is coppied from dperson/samba container.
  # Note: when adding user do not forge to run `smbpasswd -a <USER>`.
  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
        workgroup = WORKGROUP
        server role = standalone server
        dns proxy = no
        vfs objects = catia fruit streams_xattr

        pam password change = yes
        map to guest = bad user
        usershare allow guests = yes
        create mask = 0664
        force create mode = 0664
        directory mask = 0775
        force directory mode = 0775
        follow symlinks = yes
        load printers = no
        printing = bsd
        printcap name = /dev/null
        disable spoolss = yes
        strict locking = no
        aio read size = 0
        aio write size = 0
        vfs objects = catia fruit streams_xattr

        # Security
        client ipc max protocol = SMB3
        client ipc min protocol = SMB2_10
        client max protocol = SMB3
        client min protocol = SMB2_10
        server max protocol = SMB3
        server min protocol = SMB2_10

        # Time Machine
        fruit:delete_empty_adfiles = yes
        fruit:time machine = yes
        fruit:veto_appledouble = no
        fruit:wipe_intentionally_left_blank_rfork = yes
      '';

    shares = {
      "Time Capsule" = {
        path = "/pool/samba/timemachine";
        browseable = "no";
        "read only" = "no";

        # Authenticate ?
        # "valid users" = "melias122";

        # Or allow guests
        "guest ok" = "yes";
        "force user" = "nobody";
        "force group" = "nogroup";
      };
      public = {
        path = "/pool/samba/public";
        browseable = "yes";
        "read only" = "no";

        # This is public, everybody can access.
        "guest ok" = "yes";
        "force user" = "nobody";
        "force group" = "nogroup";

        "veto files" = "/.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/";
        "delete veto files" = "yes";
      };
      melias122 = {
        path = "/pool/samba/melias122";
        browseable = "yes";
        "read only" = "no";

        # Make this private
        "guest ok" = "no";
        "valid users" = "melias122";

        "veto files" = "/.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/";
        "delete veto files" = "yes";
      };
    };
  };
}
