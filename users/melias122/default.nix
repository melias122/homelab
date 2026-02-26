{ config, pkgs, unstable, home, ... }:

{
  imports = [
    ./copilot.nix
    ./go.nix
  ];

  home.packages = with pkgs; [
    appimage-run
    awscli2
    beekeeper-studio # nice SQL browser
    bruno # postman
    curl
    docker-compose
    editorconfig-core-c
    emacs30
    gcc
    gnumake
    google-chrome
    graphviz
    grpcurl
    hplip # HP printer drivers
    jq
    multimarkdown
    natscli
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

    # terraform
    terraform
    terraform-ls

    # Nextgen C
    zig
    zls

    unstable.opencode-claude-auth
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
      settings = {
        user.name  = "Martin Eliáš";
        user.email = "martin@elias.sx";
      };

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

    opencode = {
      enable = true;
      package = unstable.opencode;
      settings = {
        plugin = ["opencode-claude-auth"];
        permission = {
          external_directory = {
            "`/tmp/*" = "allow";
            "~/code/oddin/**" = "allow";
            "~/code/gadget/**" = "allow";
            "~/go/**" = "allow";
          };
        };
      };
    };

    claude-code = {
      enable = true;
      package = unstable.claude-code;
    };


    ssh = {
      enable = true;
      enableDefaultConfig = false;
    };

    # Terminal multiplexer
    tmux = {
      enable = true;
      keyMode = "emacs";
      mouse = true;
    };
  };

  programs.home-manager.enable = true;
  home.username = "melias122";
  home.homeDirectory = "/home/melias122";
  home.stateVersion = "22.11";
}
