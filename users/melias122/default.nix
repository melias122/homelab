{ config, pkgs, home, ... }:

{
  imports = [
    ./go.nix
  ];

  home.packages = with pkgs; [
    appimage-run
    awscli
    beekeeper-studio # nice SQL browser
    curl
    editorconfig-core-c
    emacs29
    gcc
    gnumake
    google-chrome
    grpcurl
    jq
    libreoffice
    postman
    ripgrep
    thunderbird
    vlc
    vscode
    xarchiver
    zip unzip

    #
    # Langs.
    # Cleanup later if needed move to separate config.
    #

    # Java :-(
    zulu

    # Web magic
    nodejs
    nodePackages.typescript-language-server

    # Snake
    python3Minimal
    python3Packages.python-lsp-server

    # Nextgen C++
    cargo
    rustc
    rust-analyzer

    # Nextgen C
    zig
    zls
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

    bash = {
      enable = true;
      historyControl = [
        "erasedups"
        "ignoredups"
      ];
    };

    git = {
      enable = true;
      userName  = "Martin Eliáš";
      userEmail = "martin@elias.sx";

      includes = [
        {
          contents = {
            remote.pushdefault = "origin";
            core.whitespace = "tabsize=4";
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
