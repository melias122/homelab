# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ../../services/bluetooth.nix
      ../../services/docker-rootless.nix
      ../../services/printer.nix
      ../../services/tailscale.nix
      ../../services/touchpad.nix
    ];

  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
  };

  # Workaround for touchpad not working sometimes after suspend.
  boot.extraModprobeConfig = ''
    options psmouse synaptics_intertouch=0
  '';

  networking.hostName = "t14";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

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
    layout = "us";
    xkbVariant = "";

    desktopManager = {
      xterm.enable = false;
    };
    displayManager = {
      defaultSession = "none+i3";
      lightdm = {
        greeters.enso = {
          enable = true;
          blur = true;
        };
      };
    };
    windowManager = {
      i3 = {
        enable = true;
        extraPackages = with pkgs; [
          arandr
          brightnessctl
          dex
          dmenu    # application launcher most people use
          i3status # gives you the default i3 status bar
          i3lock   # default i3 screen locker
          i3blocks # if you are planning on using i3blocks over i3status
          networkmanagerapplet
          pavucontrol # for volume control
          volumeicon
          xss-lock
        ];
      };
    };

    # desktopManager.lxqt.enable = true;
  };

  # Enable sound with pipewire.
  sound.enable = false;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;

    wireplumber.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # Needed for some applications, e.g. "zoom". Pipewire can also be configured via pulseaudio commands.
    pulseaudioFull
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.melias122 = {
    isNormalUser = true;
    description = "Martin Eliáš";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # No packages here as I am using Home Manager.
    ];
  };

  fonts.fonts = with pkgs; [
    fira-code
    fira-code-symbols
    ibm-plex
  ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # Firmware updater
  services.fwupd.enable = true;

  # Use kanata to remap caps -> ctrl
  services.kanata.enable = true;
  services.kanata.keyboards.t14 = {
    config = ''
    (defsrc
      caps)
    (deflayer default
      lctl)
    '';
    devices = [
      "/dev/input/by-path/platform-i8042-serio-0-event-kbd" # T14 keyboard
    ];
  };

  system.stateVersion = "22.11"; # Did you read the comment? YES!
}
