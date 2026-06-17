{ config, pkgs, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "nextcloud.elias.sx";
    home = "/pool/nextcloud-new";
    https = true;
    autoUpdateApps.enable = true;
    maxUploadSize = "16G";
    configureRedis = true;
    # hostName (nextcloud.elias.sx) is auto-added to trusted_domains, so only
    # list the extra one here. Reachable via tailscale on :54443; the port is
    # stripped before matching, so no port in the entry.
    settings.trusted_domains = [ "server.elias.sx" ];
    config = {
      adminuser = "melias122";
      adminpassFile = "/etc/nixos/x/nextcloud-adminpass";
      dbtype = "sqlite";
    };
  };

  services.nginx.virtualHosts = {
    "nextcloud.elias.sx" = {
      listen = [{ addr = "100.98.141.25"; port = 54443; }]; # use tailscale interface
    };
  };
}
