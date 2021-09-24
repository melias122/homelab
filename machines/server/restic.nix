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
    # remote = {
    # repository = "b2:restic-homelab-backup:/pve-homelab-backup";
    # passwordFile = "/etc/nixos/secrets/restic-password";
    # };
  };
}
