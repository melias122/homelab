{ config, pkgs, ... }:

{
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      domov = {
        image = "docker.io/melias122/domov:latest";
        ports = [ "54380:8080" ];
      };
    };
  };
}
