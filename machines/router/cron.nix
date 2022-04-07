{ config, pkgs, ... }:

let
  secrets = import ../../secrets.nix;

in {
  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/1 * * * *      root    /root/go/bin/dnsctl -token=${secrets.digitalocean-token} -no6 -hostname=${secrets.domain}"
    ];
  };
}
