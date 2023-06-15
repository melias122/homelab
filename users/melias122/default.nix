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
    emacs
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

  services.grobi = {
    enable = true;
    rules = [
      {
        name = "T14";
        outputs_disconnected = [ "DP-?" ];
        configure_single = "eDP-1";
        primary = true;
        atomic = true;
        # execute_after = [
        # "${pkgs.xorg.xrandr}/bin/xrandr --dpi 120"
        # "${pkgs.xmonad-with-packages}/bin/xmonad --restart";
        # ];
      }
      {
        name = "Dock";
        outputs_connected = [ "DP-5" ];
        configure_row = ["DP-5" "eDP-1"];
        primary = "DP-5";
        # atomic = true;
        # execute_after = [
        # "${pkgs.xorg.xrandr}/bin/xrandr --dpi 96"
        # "${pkgs.xmonad-with-packages}/bin/xmonad --restart";
        # ];
      }
    ];
  };

  home.stateVersion = "22.11";
}
