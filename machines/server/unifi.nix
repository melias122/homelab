{ config, pkgs, ... }:

{
  containers.unifi = {
    autoStart = true;
    bindMounts = {
      "/var/lib/unifi" = {
        hostPath = "/pool/containers/unifi";
        isReadOnly = false;
      };
    };
    config = { ... }:
      let
        unstable = import
          (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/nixos-unstable-small) {
            # reuse the current configuration
            config = config.nixpkgs.config;
          };
      in {
        services.unifi = {
          enable = true;
          unifiPackage = unstable.unifi;
        };
      };
  };
}
