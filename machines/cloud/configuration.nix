{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix

      ../../roles/common.nix
      ../../services/tailscale.nix
    ];

  boot = {
    loader.grub = {
      enable = true;

      device = "/dev/vda";
    };
  };

  networking = {
    hostName = "cloud";

    useDHCP = false;

    interfaces = {
      enp1s0.useDHCP = true;
    };

    firewall.enable = true;
  };

  system.stateVersion = "20.09";
}
