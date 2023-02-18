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

  programs.bash = {
    enable = true;
  };

  programs.git = {
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

  programs.ssh = {
    enable = true;
  };

  home.file = {
    ".editorconfig".source = ./home/.editorconfig;
  };

  home.stateVersion = "22.11";
}
