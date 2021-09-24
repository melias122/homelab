# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ../../roles/common.nix

      ./avahi.nix
      ./samba.nix
      ./restic.nix
      ./unifi.nix
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
    kernelParams = ["zfs.zfs_arc_max=17179860388"]; # 16GB, was 8383029248 (8GB)
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

  # ZFS auto scrub
  services.zfs.autoScrub.enable = true;

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
