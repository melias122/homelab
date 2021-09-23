{ config, pkgs, ... }:

{
  services.coredns = {
    enable = true;
    config = ''
      (defaults) {
        log
        cache 3600 {
          success 8192
          denial 4096
        }
        prometheus :9153
      }

      (cloudflare) {
        forward . tls://1.1.1.1 tls://1.0.0.1 {
          tls_servername cloudflare-dns.com
          health_check 10s
        }
      }

      (google) {
        forward . tls://8.8.8.8 tls://8.8.4.4 {
          tls_servername dns.google
          health_check 10s
        }
      }

      (blocklist) {
        hosts /etc/hosts.blocklist {
          reload 3600s
          no_reverse
          fallthrough
        }
      }

      .:53 {
        import defaults
        # import blocklist
        import google
      }
    '';
  };
}
