# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ../../roles/common.nix

      ./apcupsd.nix
      ./avahi.nix
      ./containers.nix
      ./restic.nix
      ./samba.nix
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
