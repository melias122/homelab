{ config, pkgs, home, ... }:

{
  imports = [
    ./go.nix
  ];

  home.packages = with pkgs; [
    appimage-run
    awscli
    beekeeper-studio # nice SQL browser
    bruno # postman
    curl
    editorconfig-core-c
    emacs30
    gcc
    gnumake
    google-chrome
    graphviz
    grpcurl
    jq
    multimarkdown
    kodi
    libreoffice
    redisinsight
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
    yarn
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
            url = {
              "ssh://git@github.com" = {
                insteadOf = "https://github.com";
              };
            };
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

  # Should be same as 'export NIXPKGS_ALLOW_UNFREE=1'
  nixpkgs.config.allowUnfreePredicate = _: true;

  programs.home-manager.enable = true;
  home.username = "melias122";
  home.homeDirectory = "/home/melias122";
  home.stateVersion = "22.11";
}
