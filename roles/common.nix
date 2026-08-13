{ config, pkgs, ... }:

let
  agenix = builtins.fetchTarball {
    url = "https://github.com/ryantm/agenix/archive/0.15.0.tar.gz";
    sha256 = "01dhrghwa7zw93cybvx4gnrskqk97b004nfxgsys0736823956la";
  };
in {
  imports =
    [
      "${agenix}/modules/age.nix"

      ../services/openssh.nix
      ../services/tailscale.nix
    ];

  boot = {
    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
  };

  powerManagement.cpuFreqGovernor = "ondemand";

  hardware.enableRedistributableFirmware = true;

  time.timeZone = "Europe/Bratislava";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  environment.systemPackages = with pkgs; [
    bash
    curl
    ethtool
    git
    go
    htop
    iperf3
    ipmitool
    jq
    lm_sensors
    lshw
    mailutils
    nmap
    nmon
    pciutils
    smartmontools
    tcpdump
    unzip
    usbutils
    zip
    vim
    wget
  ];

  users = {
    users.root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIND17TDL2rPoWedCiuSq2dklxRkvtDufAWo5U/ZCRCtD"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwuhSIOGM2vy0OFOku+itsEMqDW0a93MQNg4cjGncub"
      ];
    };

    # Password is set imperatively with `passwd`.
    users.melias122 = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" "networkmanager" ];
    };
  };

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };

    extraOptions = ''
      min-free = ${toString (500 * 1024 * 1024)}
      experimental-features = nix-command flakes
    '';

    package = pkgs.nixVersions.stable;
  };

  nixpkgs.config.allowUnfree = true;

  system.autoUpgrade.enable = true;
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-26.05-small";

  services = {
    fstrim.enable = true;
  };
}
