{ config, pkgs, ... }:

{
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53;
      connectIPVersion = "v4";

      # Metrics for the server's Prometheus (scraped over the tailnet)
      # and the Blocky DNS dashboard in Grafana.
      ports.http = 4000;
      prometheus.enable = true;

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

      # Split-DNS: LAN clients without tailscale can't reach these over the
      # public record (-> tailnet IP), so send them to the server's LAN IP.
      customDNS.mapping = {
        "frigate.elias.sx" = "192.168.1.45";
        "timemachine.elias.sx" = "192.168.1.45";
        "unifi.elias.sx" = "192.168.1.45";
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
