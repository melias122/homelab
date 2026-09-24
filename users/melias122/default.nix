{ config, pkgs, unstable, agents, ... }:

{
  imports = [
    ./copilot.nix
    ./go.nix
  ];

  home.packages = with pkgs; [
    appimage-run
    awscli2
    # unstable: 26.05 has 5.3.4 marked insecure
    unstable.beekeeper-studio
    bruno
    agents.codex
    curl
    docker-compose
    editorconfig-core-c
    emacs30
    firefox
    gcc
    gh
    gnomeExtensions.appindicator # tray icons, needed by the tailscale systray
    gnumake
    google-chrome
    graphviz
    grpcurl
    hplip
    jq
    multimarkdown
    natscli
    kodi
    libreoffice
    unstable.pi-coding-agent
    # unstable: 26.05 has 2.70.0 which depends on EOL nodejs-slim-20 (insecure,
    # not in binary cache -> compiles nodejs locally); 3.6.0 does not
    # unstable.redisinsight
    ripgrep
    thunderbird
    vlc
    vscode
    wl-clipboard # tailscale systray clipboard actions on Wayland
    xarchiver
    zip unzip

    zulu

    nodejs
    yarn
    typescript-language-server

    python3Minimal
    python3Packages.python-lsp-server

    cargo
    rustc
    rust-analyzer

    mise
    opentofu
    terraform
    terraform-ls

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

    # `tailscale configure systray --enable-startup` would write outside nix.
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
      package = agents.opencode;
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
      package = agents.claude-code;
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
