# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ../../services/docker-rootless.nix
      ../../services/openssh.nix
      ../../services/printer.nix
      ../../services/tailscale.nix
    ];

  # Let the user-session systray control tailscaled without sudo.
  services.tailscale.extraSetFlags = [ "--operator=melias122" ];

  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  # Automatic Nix store garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Allow unfree packages.
  # permittedInsecurePackages is set in flake.nix (single source of truth).
  nixpkgs.config.allowUnfree = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 15;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };

  networking.hostName = "box";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Bratislava";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sk_SK.UTF-8";
    LC_IDENTIFICATION = "sk_SK.UTF-8";
    LC_MEASUREMENT = "sk_SK.UTF-8";
    LC_MONETARY = "sk_SK.UTF-8";
    LC_NAME = "sk_SK.UTF-8";
    LC_NUMERIC = "sk_SK.UTF-8";
    LC_PAPER = "sk_SK.UTF-8";
    LC_TELEPHONE = "sk_SK.UTF-8";
    LC_TIME = "sk_SK.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;

    # Configure keymap in X11
    xkb.layout = "us";
    xkb.variant = "";

    desktopManager = {
      xterm.enable = false;
    };
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome = {
    enable = true;
    # 4K monitor scalling support
    extraGSettingsOverrides = ''
      [org.gnome.mutter]
      experimental-features=['scale-monitor-framebuffer']
      '';
  };

  environment.systemPackages = with pkgs; [
    # Needed for some applications, e.g. "zoom". Pipewire can also be configured via pulseaudio commands.
    pulseaudioFull
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # User packages are managed by Home Manager (see users/melias122).
  users.users.melias122 = {
    isNormalUser = true;
    description = "Martin Eliáš";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    ibm-plex
  ];

  # Firewall. Note: services.openssh opens port 22 by default.
  networking.firewall.enable = true;

  # Firmware updater + redistributable firmware (also enables AMD microcode updates)
  services.fwupd.enable = true;
  hardware.enableRedistributableFirmware = true;

  # Periodic TRIM for the NVMe SSD
  services.fstrim.enable = true;

  # Use kanata to remap caps -> ctrl
  services.kanata.enable = true;
  services.kanata.keyboards.box = {
    config = ''
    (defsrc
      caps)
    (deflayer default
      lctl)
    '';
    devices = [];
  };

  programs.steam.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
  ];

  system.stateVersion = "22.11"; # Did you read the comment? YES!
}
