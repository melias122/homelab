{ config, pkgs, ... }:

let
  # Pinned official 8.0 LTS binary: MongoDB is unfree so cache.nixos.org never
  # has it and a nixpkgs build compiles for hours on every channel bump; the
  # channel's mongodb-ce is a rapid release outside UniFi's support matrix.
  # Data has featureCompatibilityVersion 8.0, a major bump needs
  # setFeatureCompatibilityVersion first.
  mongodb-ce-8_0 = pkgs.mongodb-ce.overrideAttrs (
    old: rec {
      version = "8.0.29";
      src = pkgs.fetchurl {
        url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2404-${version}.tgz";
        hash = "sha256-yJe+lr3aAy3jiIH2Gt2YNIrbACK9l2amlWFglRuW7QA=";
      };
    }
  );
in
{
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi;
    mongodbPackage = mongodb-ce-8_0;
  };
}
