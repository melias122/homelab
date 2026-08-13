{ config, lib, ... }:

{
  services.minidlna = {
    enable = false;
    settings.media_dir = [
      "V,/pool/nextcloud-new/data/melias122/files/Videos"
    ];
    settings.inotify = "yes";
  };

  # Needs read access to the nextcloud data dir.
  users.users.minidlna = lib.mkIf config.services.minidlna.enable {
    extraGroups = [ "nextcloud" ];
  };
}
