{ config, pkgs, ... }:

{
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      oscam = {
        # https://hub.docker.com/r/linuxserver/oscam/tags
        image = "ghcr.io/linuxserver/oscam:version-11718";
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Bratislava";
        };
        volumes = [ "/pool/containers:/config" ];
        ports = [
          "100.98.141.25:8888:8888"
          "127.0.0.1:9000:9000"
        ];
      };

      tvheadend = {
        # https://hub.docker.com/r/linuxserver/tvheadend/tags
        image = "ghcr.io/linuxserver/tvheadend:version-abcb0ea6";
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Europe/Bratislava";
          # RUN_OPTS = "--http_port 9981 --htsp_port 9982";
        };
        volumes = [ "/pool/containers/tvheadend:/config" ];
        extraOptions = [ "--network=host" ];
      };

      domov = {
        image = "docker.io/melias122/domov:2b42ecc";
        ports = [ "54380:8080" ];
      };
    };
  };
}
