{ config, pkgs, ... }:

let
  # Official MongoDB 8.0 LTS binary, pinned on purpose (migrated from
  # source-built 7.0 in 2026-08, featureCompatibilityVersion is "8.0").
  # MongoDB is unfree so cache.nixos.org never caches it - a nixpkgs
  # mongodb would compile for hours on every channel bump. The channel's
  # mongodb-ce is a rapid release outside UniFi's support matrix; staying
  # on pinned LTS is deliberate.
  #
  # Patch bumps are manual: pick the newest 8.0.x ubuntu2404 tarball from
  # https://downloads.mongodb.org/full.json, nix-prefetch-url it, update
  # version+hash here. A future major bump (9.0) needs the FCV dance again:
  # stop unifi + copy data/db, swap the binary, then via mongosh
  # db.adminCommand({setFeatureCompatibilityVersion:"9.0", confirm: true}).
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
