{
  services.minidlna = {
    enable = true;
    settings.media_dir = [
      "V,/pool/nextcloud/data/melias122/files/Videos"
    ];
    settings.inotify = "yes";
  };

  # Add minidlna to nextcloud group.
  users.users.minidlna.extraGroups = [ "nextcloud" ];
}
