{ config, pkgs, ... }:

{
  services.restic.backups = {
    local = {
      repository = "/backup/restic";
      passwordFile = "/etc/nixos/secrets/restic-password";
      paths = [
        "/pool"
      ];
    };
    b2 = {
      repository = "b2:restic-homelab-backup:/pve-homelab-backup";
      passwordFile = "/etc/nixos/secrets/restic-password";
      environmentFile = "/etc/nixos/secrets/restic-env";
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
