{ config, pkgs, ... }:

{
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53;
      connectIPVersion = "v4";

      upstreams.groups = {
        default = [
          "https://dns.quad9.net/dns-query"
        ];

        router = [
          # https://quad9.net/service/service-addresses-and-features/#rec
          "9.9.9.9"
          "149.112.112.112"
        ];
      };

      bootstrapDns = {
        upstream = "https://dns.quad9.net/dns-query";
        ips = [ "9.9.9.9" "149.112.112.112" ];
      };

      caching = {
        minTime = "5m";
        maxTime = "1h";
        maxItemsCount = 10000;
        prefetching = true;
        prefetchExpires = "2h";
        prefetchThreshold = 5;
        cacheTimeNegative = "30m";
      };

      # https://v.firebog.net
      # https://oisd.nl
      blocking = {
        denylists = {
          default = [
            "https://big.oisd.nl/domainswild"
          ];
        };
        clientGroupsBlock = {
          default = [
            "default"
          ];
        };
      };
    };
  };
}
