{ config, pkgs, ... }:

{
  age.secrets = {
    restic-password.file = ../../secrets/restic-password.age;
    restic-b2-env.file = ../../secrets/restic-b2-env.age;
  };

  services.restic.backups = {
    local = {
      repository = "/backup/restic";
      passwordFile = config.age.secrets.restic-password.path;
      paths = [
        "/pool"
        "/var/lib/unifi/data/backup"

        # State on the root SSD that git can't restore: HA .storage
        # (pairings, entities), samba passdb, caddy certs.
        "/var/lib/samba"
        "/var/lib/caddy"
      ];
      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 8"
        "--keep-monthly 12"
        "--keep-yearly 3"
      ];
      extraBackupArgs = [
        # A check or prune started from the backrest UI holds an exclusive
        # lock; wait it out instead of failing the nightly backup.
        "--retry-lock=1h"

        "-e timemachine"
      ];
    };
    b2 = {
      repository = "b2:restic-homelab-backup:/pve-homelab-backup";
      passwordFile = config.age.secrets.restic-password.path;
      environmentFile = config.age.secrets.restic-b2-env.path;
      timerConfig = {
        OnCalendar = "monthly";
      };
      paths = [ "/pool" ];
      extraBackupArgs = [
        "--retry-lock=1h"

        "-e pool/containers"
        "-e timemachine"
      ];
      pruneOpts = [
        "--keep-monthly 12"
        "--keep-yearly 3"
      ];
    };
  };
}
