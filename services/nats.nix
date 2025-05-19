{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    natscli
  ];

  services.nats = {
    enable = false;
    jetstream = {
      max_mem = "2G";
      max_file = "20G";
    };
  };
}
