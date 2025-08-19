{ config, pkgs, ... }:

let
  x = import ../../x/config.nix;

in {
  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/5 * * * *      root    cd /root/dnsctl && go run main.go -token=${x.digitalocean-token} -no6 -hostname=elias.sx"
    ];
  };
}
