{ config, pkgs, ... }:

{
  # This is a workaroud for oscam, which from time to time stops working.
  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/5 * * * *     root     nc -zvw10 100.98.141.25 8888 &>/dev/null || systemctl restart podman-oscam.service"
    ];
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      domov = {
        image = "docker.io/melias122/domov:latest";
        ports = [ "54380:8080" ];
      };

      recepty = {
        image = "docker.io/melias122/recepty";
        volumes = [ "/pool/containers/recepty:/data" ];
        ports = [ "54381:8080" ];
      };
    };
  };
}
