{ config, pkgs, home, ... }:

{
  imports = [
    ./go.nix
  ];

  home.packages = with pkgs; [
    awscli
    beekeeper-studio # nice SQL browser
    curl
    editorconfig-core-c
    emacs
    gcc
    gnumake
    google-chrome
    grpcurl
    jq
    ripgrep
    thunderbird
    vscode
    zulu # Java

    nodejs-14_x
    nodePackages.eslint
    nodePackages.prettier
    nodePackages.typescript-language-server

  ];

  home.file = {
    ".editorconfig".source = ./home/.editorconfig;
  };

  xdg.configFile = {
    "." = {
      source = ./home/.config;
      recursive = true;
    };
  };

  programs = {
    # Fast terminal emulator
    alacritty.enable = true;

    bash.enable = true;

    git = {
      enable = true;
      userName  = "Martin Eliáš";
      userEmail = "martin@elias.sx";

      includes = [
        {
          contents = {
            remote.pushdefault = "origin";
          };
        }
      ];
    };

    ssh.enable = true;

    # Terminal multiplexer
    tmux = {
      enable = true;
      keyMode = "emacs";
      mouse = true;
    };
  };

  home.stateVersion = "22.11";
}
