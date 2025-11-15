{ config, pkgs, lib, unstable, ... }: {

  system.primaryUser = "m";

  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    ibm-plex
  ];

  homebrew = {
    enable = true;
    casks = [
      "beekeeper-studio"
      "emacs-app"
      "google-chrome"
      "insomnia"
      "redis-insight"
      "tailscale-app"
      "the-unarchiver"
      "tunnelblick"
      "visual-studio-code"
    ];

    # Ensures only packages specified in homebrew configurations are installed
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  environment.systemPackages = with pkgs; [
    alacritty
    delta
    git
    git-extras
    go
    gopls
    gnumake
    nodejs
    ripgrep
    yarn
  ];

  system.defaults = {
    dock = {
      autohide = true;
      orientation = "left";
    };
  };
}
