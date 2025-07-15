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

      # Optional: Configure the web interface
      # http = {
      #   enable = true;
      #   listen = "0.0.0.0:4000"; # Access Blocky dashboard on port 4000
      #   # username = "admin";
      #   # password = "yourpassword";
      # };

      # https://v.firebog.net
      # https://oisd.nl
      blocking = {
        denylists = {
          default = [
            "https://hosts.oisd.nl"
          ];
          ads = [
            "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
          ];
        };
        clientGroupsBlock = {
          default = [
            "default"
            "ads"
          ];

          router = [];
        };
      };
    };
  };
}
