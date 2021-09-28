{ config, pkgs, ... }:

{
  services.apcupsd = {
    enable = true;
  };
}
