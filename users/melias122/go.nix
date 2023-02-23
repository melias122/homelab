{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    delve
    golint
    gopls
  ];

  # add CGO_ENABLED=0
  programs.go = {
    enable = true;
    package = pkgs.go_1_20;
  };

  home.sessionPath = [
    "$HOME/go/bin"
  ];

  xdg.configFile."go/env".source = ./home/.config/go/env;
}
