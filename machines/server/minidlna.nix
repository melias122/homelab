{ config, lib, ... }:

{
  services.minidlna = {
    enable = false;
    settings.media_dir = [
      "V,/pool/nextcloud-new/data/melias122/files/Videos"
    ];
    settings.inotify = "yes";
  };

  # Add minidlna to nextcloud group (only when the service exists).
  users.users.minidlna = lib.mkIf config.services.minidlna.enable {
    extraGroups = [ "nextcloud" ];
  };
}
