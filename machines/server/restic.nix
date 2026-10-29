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

        # State outside /pool git can't restore.
        "/var/lib/hass"
        "/var/lib/samba"
        "/var/lib/caddy"

        # Heat pump history on nvme/prometheus. Not in b2: compaction keeps rewriting blocks.
        "/var/lib/prometheus2"
      ];
      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 8"
        "--keep-monthly 12"
        "--keep-yearly 3"
        "--no-cache"
      ];
      extraBackupArgs = [
        # A check/prune from the backrest UI holds an exclusive lock; wait it out.
        "--retry-lock=1h"

        "-e timemachine"

        # The repo is a local disk, a cache would only duplicate its metadata.
        "--no-cache"
      ];
    };
    b2 = {
      repository = "b2:restic-homelab-backup:/pve-homelab-backup";
      passwordFile = config.age.secrets.restic-password.path;
      environmentFile = config.age.secrets.restic-b2-env.path;
      timerConfig = {
        OnCalendar = "weekly";
        # Overriding timerConfig drops the module's default; catch up a run missed while down.
        Persistent = true;
      };
      paths = [
        "/pool"
        "/var/lib/hass"
      ];
      extraBackupArgs = [
        "--retry-lock=1h"

        "-e timemachine"
      ];
      pruneOpts = [
        "--keep-weekly 8"
        "--keep-monthly 12"
        "--keep-yearly 3"
      ];
      # Read back a random 5 % of packs each run, not just the index; ~15 GB/week fits B2's free 3× egress.
      checkOpts = [ "--read-data-subset=5%" ];
    };
  };
}
