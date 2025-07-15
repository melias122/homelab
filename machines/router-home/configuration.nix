# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # roles
      ../../roles/common.nix
     ../../services/postfix.nix

      # services
     ./blocky.nix
#      ./caddy.nix
#      ./cron.nix
      ./dhcpd4.nix
      ./nftables.nix
     ./pppd.nix
    ];

  hardware.cpu.intel.updateMicrocode = true;

  boot = {
    loader.grub = {
      enable = true;

      # Define on which hard drive you want to install Grub.
      device = "/dev/sda";
    };

   kernel.sysctl = {
      # if you use ipv4, this is all you need
      "net.ipv4.conf.all.forwarding" = true;

      # If you want to use it for ipv6
      "net.ipv6.conf.all.forwarding" = false;

      # source: https://github.com/mdlayher/homelab/blob/master/nixos/routnerr-2/configuration.nix#L52
      # By default, not automatically configure any IPv6 addresses.
      #"net.ipv6.conf.all.accept_ra" = 0;
      #"net.ipv6.conf.all.autoconf" = 0;
      #"net.ipv6.conf.all.use_tempaddr" = 0;

      # On WAN, allow IPv6 autoconfiguration and tempory address use.
      #"net.ipv6.conf.${name}.accept_ra" = 2;
      #"net.ipv6.conf.${name}.autoconf" = 1;
    };
  };

  networking = {
    hostName = "router";
    
    useDHCP = false;

    # Disable nat and firewall in favor of nftables
    nat.enable = false;
    firewall.enable = false;

    interfaces = {
      # LAN
      eno1 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.1.1";
          prefixLength = 24;
        }];
      };

      # WAN/PPPoE
      eno2.useDHCP = false;
    };
  };

  services.resolved = {
    enable = true;
    extraConfig = ''
      DNS=::1 127.0.0.1
      DNSStubListener=no
    '';
  };

  # Tailscale readiness and DNS tweaks.
  systemd.network.wait-online.ignoredInterfaces = [ "tailscale0" ];

  systemd.services.tailscaled = {
    after = [
      "network-online.target"
      "systemd-resolved.service"
    ];
    wants = [ "network-online.target" ];
  };


  environment.systemPackages = with pkgs; [
    conntrack-tools
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
