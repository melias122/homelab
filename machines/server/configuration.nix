{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix

      ../../roles/common.nix
      ../../services/node-exporter.nix
      ../../services/postfix.nix

      ./apcupsd.nix
      ./avahi.nix
      ./caddy.nix
      ./frigate.nix
      ./home-assistant.nix
      ./minidlna.nix
      ./monitoring.nix
      ./mosquitto.nix
      ./nextcloud.nix
      ./restic.nix
      ./timemachine.nix
      ./unifi.nix
    ];

  hardware.cpu.intel.updateMicrocode = true;

  boot = {
    loader.grub = {
      enable = true;

      # by-id because /dev/sd* enumeration drifts: after the 2026-08-18 reboot
      # /dev/sda was a ZFS pool disk, grub-install failed and every
      # switch-to-configuration aborted before activating any unit.
      device = "/dev/disk/by-id/ata-ADATA_SU800NS38_2I4820029397";
    };

    supportedFilesystems = [ "zfs" ];

    # Root is ext4, no root pool to force-import (26.11 default).
    zfs.forceImportRoot = false;

    zfs.extraPools = [
      "backup"
      "pool"
      "nvme"
      "frigate"
    ];

    kernelParams = ["zfs.zfs_arc_max=17179860388"]; # 16G
  };

  networking = {
    hostName = "server";

    # Required by ZFS.
    hostId = "e6680915";

    useDHCP = false;

    interfaces = {
      # upper 1GbE (management)
      enp0s25.useDHCP = true;

      # lower 1GbE
      eno1.useDHCP = true;
    };

    # No 100.100.100.100 here: tailscaled reads it back as a system resolver and forwards to itself (DNS loop).
    nameservers = [
      "192.168.1.1"
    ];

    search = [
      "robin-shark.ts.net"
    ];

    firewall.enable = false;
  };

  environment.systemPackages = with pkgs; [
    restic
    zfs
  ];

  # ZED watches the pools, smartd the physical disks.
  services.smartd = {
    enable = true;
    notifications.mail = {
      enable = true;
      recipient = "martin@elias.sx";
    };
  };

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

  services.tailscale.extraSetFlags = [
    "--accept-routes"
  ];

  # Tailscale sets MagicDNS per-interface via resolved instead of rewriting resolv.conf.
  services.resolved.enable = true;

  system.stateVersion = "22.05";

}
