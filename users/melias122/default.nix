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
    postman
    ripgrep
    thunderbird
    vscode

    #
    # Langs.
    # Cleanup later if needed move to separate config.
    #

    # Java :-(
    zulu

    # Web magic
    nodejs-14_x
    nodePackages.eslint
    nodePackages.prettier
    nodePackages.typescript-language-server

    # Snake
    python3Minimal
    python3Packages.python-lsp-server

    # Nextgen C++
    cargo
    rustc
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
