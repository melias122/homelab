{ config, pkgs, ... }:

{
  services.restic.backups = {
    local = {
      repository = "/backup/restic";
      passwordFile = "/etc/nixos/x/restic-password";
      paths = [
        "/pool"
        "/var/lib/unifi/data/backup"
      ];
      extraBackupArgs = [
        "-e public/Movies"
        "-e public/Downloads"
        "-e public/timemachine"
      ];
    };
    b2 = {
      repository = "b2:restic-homelab-backup:/pve-homelab-backup";
      passwordFile = "/etc/nixos/x/restic-password";
      environmentFile = "/etc/nixos/x/restic-b2";
      timerConfig = {
        OnCalendar = "monthly";
      };
      paths = [ "/pool" ];
      extraBackupArgs = [
        "-e pool/containers"
        "-e pool/nextcloud"

        "-e public/Movies"
        "-e public/Downloads"
        "-e public/timemachine"
      ];
    };
  };
}
