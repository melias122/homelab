{ config, pkgs, ... }:

{
  services.blocky = {
    enable = true;
    settings = {
      port = 53;

      connectIPVersion = "v4";
      bootstrapDns = "tcp+udp:1.1.1.1";

      upstream.default = [
        "tcp-tls:1.1.1.1:853"
        "tcp-tls:1.0.0.1:853"
        "tcp-tls:8.8.8.8:853"
        "tcp-tls:8.8.4.4:853"
      ];

      # https://v.firebog.net
      # https://oisd.nl
      blocking = {
        blackLists = {
          default = [
            "https://hosts.oisd.nl"
          ];
          tracking = [
            "https://v.firebog.net/hosts/Easyprivacy.txt"
            "https://v.firebog.net/hosts/Prigent-Ads.txt"
          ];
          malicious = [
            "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
            "https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
            "https://v.firebog.net/hosts/Prigent-Crypto.txt"
            "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
            "https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt"
            "https://phishing.army/download/phishing_army_blocklist_extended.txt"
            "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
            "https://v.firebog.net/hosts/RPiList-Malware.txt"
            "https://v.firebog.net/hosts/RPiList-Phishing.txt"
            "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
            "https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/generated/hosts"
            "https://urlhaus.abuse.ch/downloads/hostfile/"
          ];
          special = [
            "https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser"
          ];
        };
        clientGroupsBlock = {
          default = [
            "default"
            "tracking"
            "malicious"
            "special"
          ];
        };
      };
    };
  };
}
