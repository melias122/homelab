{ config, pkgs, ... }:

let
  secrets = import ../../secrets.nix;

in {
  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/1 * * * *      root    curl -s https://api.myip.com | jq -j .ip > /tmp/ipaddr; VULTR_API_KEY=${secrets.vultr-api-key} vultr-cli dns record update ${secrets.domain} -d $(cat /tmp/ipaddr)"
    ];
  };
}
