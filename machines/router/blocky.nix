{ config, pkgs, ... }:

{
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53;
      connectIPVersion = "v4";

      ports.http = 4000;
      prometheus.enable = true;

      # Console log floods the journal (4G/24d), boot logs rotate away.
      queryLog.type = "none";

      upstreams.groups = {
        default = [
          "https://dns.quad9.net/dns-query"
          "https://one.one.one.one/dns-query"
        ];

        router = [
          "1.1.1.1"
          "9.9.9.9"
        ];
      };
      upstreams.strategy = "strict";

      bootstrapDns = {
        upstream = "https://dns.quad9.net/dns-query";
        ips = [ "9.9.9.9" "149.112.112.112" ];
      };

      caching = {
        prefetching = true;
        minTime = "1m";
        maxTime = "1h";
        maxItemsCount = 100000;
      };

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
          router = [];
        };
      };
    };
  };
}
