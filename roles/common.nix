# Common configuration accross all machines

{ config, pkgs, ... }:

let
  x = import ../x/config.nix;
in {
  imports =
    [
      ../services/openssh.nix
      ../services/tailscale.nix
    ];

  boot = {
    kernel.sysctl = {
      "vm.swappiness" = 10;
    };
  };

  # Scale down CPU frequency when load is low.
  powerManagement.cpuFreqGovernor = "ondemand";

  # Enable firmware updates when possible.
  hardware.enableRedistributableFirmware = true;

  # Set your time zone.
  time.timeZone = "Europe/Bratislava";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    # Force declarative user configuration.
    # mutableUsers = false;

    users.root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIND17TDL2rPoWedCiuSq2dklxRkvtDufAWo5U/ZCRCtD"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwuhSIOGM2vy0OFOku+itsEMqDW0a93MQNg4cjGncub"
      ];
    };

    # Set melias122's account sudo, SSH login.
    users.melias122 = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" "networkmanager" ];

      hashedPassword = "$6$5OrUriMQbOhi$VpUVX6Fy3wS1adO8TLftjNFTRq9wRA7VQO6rMcm06HcyQlBnQH5pKiIQvpz2CwToVDhUiTwqFF.N888.VdZt31";
    };
  };

  nix = {
    # Automatic Nix GC.
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

  # Enable unfree packages
  nixpkgs.config.allowUnfree = true;

  # Automatic upgrades.
  system.autoUpgrade.enable = true;
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-25.11-small";

  # Don’t shutdown when power button is short-pressed
  services = {
    logind.extraConfig = ''
      HandlePowerKey=ignore
    '';

    fstrim.enable = true;
  };
}
