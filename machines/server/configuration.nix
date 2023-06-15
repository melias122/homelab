# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ../../roles/common.nix
      ../../services/postfix.nix

      ./apcupsd.nix
      ./avahi.nix
      ./containers.nix
      ./minidlna.nix
      ./nextcloud.nix
      ./restic.nix
      ./samba.nix
      ./unifi.nix
    ];

  hardware.cpu.intel.updateMicrocode = true;

  boot = {
    loader.grub = {
      enable = true;

      # Define on which hard drive you want to install Grub.
      device = "/dev/sda";
    };

    # Enable ZFS.
    supportedFilesystems = [ "zfs" ];

    zfs.extraPools = [
      "backup"
      "pool"
      "nvme"
    ];

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
      enp0s25.useDHCP = true;

      # lower 1GbE
      eno1.useDHCP = true;

      # 10GbE
      enp2s0.useDHCP = true;
    };

    nameservers = [
      "100.100.100.100"
      "192.168.1.1"
    ];

    search = [
      "robin-shark.ts.net"
    ];

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

  # ZFS
  services.zfs = {
    autoScrub.enable = true;

    zed.settings = {
      ZED_EMAIL_ADDR = [ "martin@elias.sx" ];
      ZED_EMAIL_PROG = "${pkgs.mailutils}/bin/mail";
      ZED_EMAIL_OPTS = "-s '@SUBJECT@' @ADDRESS@";

      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
