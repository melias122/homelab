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

      # Optional: Configure the web interface
      # http = {
      #   enable = true;
      #   listen = "0.0.0.0:4000"; # Access Blocky dashboard on port 4000
      #   # username = "admin";
      #   # password = "yourpassword";
      # };

      # https://v.firebog.net
      # https://oisd.nl
      # blocking = {
      #   denylists = {
      #     default = [
      #       "https://hosts.oisd.nl"
      #     ];
      #     ads = [
      #       "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
      #       "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
      #     ];
      #   };
      #   clientGroupsBlock = {
      #     default = [
      #       "default"
      #       "ads"
      #     ];

      #     router = [];
      #   };
      # };
    };
  };
}
