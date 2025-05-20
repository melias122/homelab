{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    copilot-language-server
  ];
}
