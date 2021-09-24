# Common configuration accross all machines

{ config, pkgs, ... }:

let
  secrets = import ../secrets.nix;
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
    git
    htop
    iperf3
    ipmitool
    lm_sensors
    lshw
    nmap
    nmon
    pciutils
    smartmontools
    tcpdump
    unzip
    usbutils
    vim
    wget
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    # Force declarative user configuration.
    # mutableUsers = false;

    users.root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4E9fCQDVnvqYRINH0XcCZbH/VS65RfAQfOA+eDYlHJ"
      ];
    };

    # Set melias122's account sudo, SSH login.
    users.melias122 = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" "networkmanager" ];

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4E9fCQDVnvqYRINH0XcCZbH/VS65RfAQfOA+eDYlHJ"
      ];

      hashedPassword = secrets.users.melias122.passwordHash;
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
    '';
  };

  # Enable unfree packages
  nixpkgs.config.allowUnfree = true;

  # Automatic upgrades.
  system.autoUpgrade.enable = true;

  # Don’t shutdown when power button is short-pressed
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';
}
