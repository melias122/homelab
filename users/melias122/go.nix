{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    delve
    gopls
  ];

  # add CGO_ENABLED=0
  programs.go = {
    enable = true;
    package = pkgs.go_1_22;
  };

  home.sessionPath = [
    "$HOME/go/bin"
  ];
}
