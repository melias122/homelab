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
      ];
      # Runs `forget --prune` after each nightly backup; without this the
      # repo grew unbounded (1944 daily snapshots, 2019-2026, 3.09T).
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

        "-e public/Movies"
        "-e public/Downloads"
        "-e samba/timemachine"
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
        "-e pool/nextcloud"

        "-e public/Movies"
        "-e public/Downloads"
        "-e samba/timemachine"
        "-e timemachine"
      ];
    };
  };
}
