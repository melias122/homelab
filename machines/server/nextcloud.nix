{ config, pkgs, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud25;
    hostName = "nextcloud.elias.sx";
    home = "/pool/nextcloud";
    https = true;
    autoUpdateApps.enable = true;
    autoUpdateApps.startAt = "05:00:00";
    maxUploadSize = "16G";
    enableBrokenCiphersForSSE = false;
    config = {
      adminuser = "melias122";
      adminpassFile = "/etc/nixos/x/nextcloud-adminpass";
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql"; # nextcloud will add /.s.PGSQL.5432 by itself
      dbname = "nextcloud";
    };
  };

  # ensure that postgres is running *before* running the setup
  systemd.services."nextcloud-setup" = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };

  services.nginx.virtualHosts = {
    "nextcloud.elias.sx" = {
      listen = [{ addr = "100.98.141.25"; port = 54443; }]; # use tailscale interface
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    dataDir = "/nvme/postgres";
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensurePermissions = {
          "DATABASE nextcloud" = "ALL PRIVILEGES"; # GRANT ALL ON SCHEMA public TO nextcloud
        };
      }
    ];
  };

  services.postgresqlBackup = {
    enable = true;
    location = "/pool/postgres-backup";
    databases = [ "nextcloud" ];
  };
}
