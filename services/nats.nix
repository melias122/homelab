{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    natscli
  ];

  services.nats = {
    enable = true;
    settings = {
      listen = "127.0.0.1:4222";
      jetstream = {
        max_mem = "2G";
        max_file = "20G";
      };
    };
  };
}
