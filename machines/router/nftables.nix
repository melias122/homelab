{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nftables
  ];

  networking.nftables = {
    enable = true;
    rulesetFile = ./nftables.conf;
  };
}
