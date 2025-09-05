{ config, pkgs, ... }:

{
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53;
      connectIPVersion = "v4";

      upstreams.groups = {
        default = [
          "https://one.one.one.one/dns-query" # Using Cloudflare's DNS over HTTPS server for resolving queries.
          "https://dns.google/dns-query"
        ];

        router = [
          "1.1.1.1"
          "8.8.8.8"
        ];
      };

      bootstrapDns = {
        upstream = "https://one.one.one.one/dns-query";
        ips = [ "1.1.1.1" "1.0.0.1" ];
      };

      caching = {
        maxTime = "1h";
        prefetching = true;
      };

      # https://v.firebog.net
      # https://oisd.nl
      blocking = {
        denylists = {
          default = [
            "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
            "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
            "https://hosts.oisd.nl"
          ];
        };
        clientGroupsBlock = {
          default = [
            "default"
          ];

          router = [];
        };
      };
    };
  };
}
