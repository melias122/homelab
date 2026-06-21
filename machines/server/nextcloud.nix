{ config, pkgs, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud33;
    hostName = "nextcloud.elias.sx";
    home = "/pool/nextcloud-new";
    https = true;
    autoUpdateApps.enable = true;
    maxUploadSize = "16G";
    configureRedis = true;
    config = {
      adminuser = "melias122";
      adminpassFile = "/etc/nixos/x/nextcloud-adminpass";
      dbtype = "sqlite";
    };
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    listen = [{ addr = "100.98.141.25"; port = 54443; }];
  };
}
