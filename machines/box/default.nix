{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix

      ../../services/docker-rootless.nix
      ../../services/openssh.nix
      ../../services/printer.nix
      ../../services/tailscale.nix
    ];

  # Let the user-session systray control tailscaled without sudo.
  services.tailscale.extraSetFlags = [ "--operator=melias122" ];

  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # permittedInsecurePackages is set in flake.nix (single source of truth).
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 15;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };

  networking.hostName = "box";

  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  time.timeZone = "Europe/Bratislava";

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

  services.xserver = {
    enable = true;

    xkb.layout = "us";
    xkb.variant = "";

    desktopManager = {
      xterm.enable = false;
    };
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome = {
    enable = true;
    # 4K monitor scaling.
    extraGSettingsOverrides = ''
      [org.gnome.mutter]
      experimental-features=['scale-monitor-framebuffer']
      '';
  };

  environment.systemPackages = with pkgs; [
    # Some apps (zoom) still need the pulseaudio tooling.
    pulseaudioFull
  ];

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

  networking.firewall.enable = true;

  # Also enables AMD microcode updates.
  services.fwupd.enable = true;
  hardware.enableRedistributableFirmware = true;

  services.fstrim.enable = true;

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
  ];

  system.stateVersion = "22.11";
}
