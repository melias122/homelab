{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix

      ../../roles/common.nix
      ../../services/node-exporter.nix
     ../../services/postfix.nix

     ./blocky.nix
      ./dhcpd4.nix
      ./nftables.nix
      ./pppd.nix
    ];

  hardware.cpu.intel.updateMicrocode = true;

  # "switch" restarts networkd/pppd mid-night when glibc bumps (~10s WAN outage); apply on reboot like deploy.
  system.autoUpgrade.operation = "boot";

  boot = {
    loader.grub = {
      enable = true;

      device = "/dev/sda";
    };

   kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = false;
    };
  };

  networking = {
    hostName = "router";
    
    useDHCP = false;
    useNetworkd = true;
    nat.enable = false;
    firewall.enable = false;
  };

  systemd.network.networks = {
    "10-lan" = {
      matchConfig.Name = "eno1";
      address = [ "192.168.1.1/24" ];
      linkConfig.RequiredForOnline = "routable";
    };

    # Raw PPPoE link, pppd owns ppp0 on top of it.
    "10-wan" = {
      matchConfig.Name = "eno2";
      networkConfig.LinkLocalAddressing = "no";
      linkConfig.RequiredForOnline = "no";
    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = "::1 127.0.0.1";
      DNSStubListener = "no";
    };
  };

  systemd.network.wait-online.ignoredInterfaces = [ "tailscale0" ];

  systemd.services.tailscaled = {
    after = [
      "network-online.target"
      "systemd-resolved.service"
    ];
    wants = [ "network-online.target" ];
  };

  services.tailscale.useRoutingFeatures = "server";

  environment.systemPackages = with pkgs; [
    conntrack-tools
  ];

  system.stateVersion = "25.05";

}
