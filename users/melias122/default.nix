{ config, pkgs, unstable, ... }:

{
  imports = [
    ./copilot.nix
    ./go.nix
  ];

  home.packages = with pkgs; [
    appimage-run
    awscli2
    # unstable: 26.05 has 5.3.4 marked insecure; 6.0.0 is clean and cached
    unstable.beekeeper-studio # nice SQL browser
    bruno # postman
    curl
    docker-compose
    editorconfig-core-c
    emacs30
    gcc
    gh # GitHub CLI
    gnomeExtensions.appindicator # tray icons in GNOME (needed by tailscale systray)
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
    unstable.pi-coding-agent # AI coding agent, https://pi.dev
    # unstable: 26.05 has 2.70.0 which depends on EOL nodejs-slim-20 (insecure,
    # not in binary cache -> compiles nodejs locally); 3.6.0 does not
    unstable.redisinsight
    ripgrep
    thunderbird
    vlc
    vscode
    wl-clipboard # clipboard actions in tailscale systray (Wayland)
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
    typescript-language-server

    # Snake
    python3Minimal
    python3Packages.python-lsp-server

    # Nextgen C++
    cargo
    rustc
    rust-analyzer

    # terraform
    mise
    opentofu
    terraform
    terraform-ls

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

    # Official tailscale systray (beta); autostart declaratively instead of
    # `tailscale configure systray --enable-startup` which writes outside nix.
    "autostart/tailscale-systray.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Tailscale Systray
      Exec=/run/current-system/sw/bin/tailscale systray
    '';
  };

  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
      ];
    };
  };

  programs = {
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
  };

  programs.home-manager.enable = true;
  home.username = "melias122";
  home.homeDirectory = "/home/melias122";
  home.stateVersion = "22.11";
}
