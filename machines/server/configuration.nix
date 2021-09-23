# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ../roles/common.nix
    ];

  # Use the GRUB 2 boot loader.
  boot = {
    loader.grub = {
      enable = true;
      version = 2;

      # Define on which hard drive you want to install Grub.
      device = "/dev/sda";
    };

    # Enable ZFS.
    supportedFilesystems = [ "zfs" ];

    # Tune ZFS ARC size
    # kernelParams = ["zfs.zfs_arc_max=12884901888"]; 12GB, currently 8383029248 (8GB), maybe try 16GB (17179860388)
  };

  networking = {
    hostName = "server";

    # ZFS needs hostId
    # generate the hostID through executing: `head -c4 /dev/urandom | od -A none -t x4`
    hostId = "e6680915";

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;

    interfaces = {
      # upper 1GbE (management)
      enp0s25.useDHCP = false;
      enp0s25.ipv4.addresses = [ {
        address = "192.168.1.45";
        prefixLength = 24;
      } ];

      # lower 1GbE
      eno1.useDHCP = true;

      # 10GbE
      enp2s0.useDHCP = true;
    };

    defaultGateway = "192.168.1.1";
    nameservers = [ "192.168.1.1" ];

    # Open ports in the firewall.
    # firewall.allowedTCPPorts = [ ... ];
    # firewall.allowedUDPPorts = [ ... ];

    # Or disable the firewall altogether.
    firewall.enable = false;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    restic
    zfs
  ];

  # List services that you want to enable:
  services = {
    avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
      };
      extraServiceFiles = {
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
    };

    # Most of the Samba configuration is coppied from dperson/samba container.
    # Note: when adding user do not forge to run `smbpasswd -a <USER>`.
    samba = {
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

    restic.backups = {
      local = {
        repository = "/backup/restic";
        passwordFile = "/etc/nixos/secrets/restic-password";
        paths = [
          "/pool"
        ];
      };
      # remote = {
      # repository = "b2:restic-homelab-backup:/pve-homelab-backup";
      # passwordFile = "/etc/nixos/secrets/restic-password";
      # };
    };

    zfs.autoScrub.enable = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      oscam = {
        image = "ghcr.io/linuxserver/oscam";
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Bratislava";
        };
        volumes = [ "/pool/containers:/config" ];
        ports = [
          "8888:8888"
          "127.0.0.1:9000:9000"
        ];
      };

      tvheadend = {
        image = "ghcr.io/linuxserver/tvheadend";
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Bratislava";
          # RUN_OPTS = "--http_port 9981 --htsp_port 9982";
        };
        volumes = [ "/pool/containers/tvheadend:/config" ];
        extraOptions = [ "--network=host" ];
      };

      unifi = {
        image = "ghcr.io/linuxserver/unifi-controller";
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Bratislava";
        };
        volumes = [ "/pool/containers/unifi/config:/config" ];
        extraOptions = [ "--network=host" ];
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
