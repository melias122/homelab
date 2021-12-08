{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nftables
  ];

  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet filter {
        # Enable flow offloading for better throughput
        # flowtable f {
        #  hook ingress priority filter;
        #  devices = { ppp0, eno1 };
        # }

        chain output {
          type filter hook output priority filter
          policy accept
          counter accept
        }

        chain input {
          type filter hook input priority filter
          policy drop

          # Allow returning traffic from ppp0 and drop everthing else
          iifname "ppp0" ct state { established, related } counter accept
          iifname "ppp0" ct state invalid counter drop

          # Drop malicious subnets
          # ip saddr {
          #  49.64.0.0/11,
          #  218.92.0.0/16,
          #  222.184.0.0/13,
          # } counter drop comment "Drop malicious subnets"

          # ICMPv4 filtering
          ip protocol icmp icmp type {
            echo-request,
            destination-unreachable,
            time-exceeded,
            parameter-problem,
         } counter accept

          # Allow trusted networks to access the router
          iifname {
            "lo",
            "tailscale0",
            "eno1",
          } counter accept comment "Allow trusted interfaces to router"
        }

        chain forward {
          type filter hook forward priority filter
          policy drop

          # Enable flow offloading for better throughput
          # ip protocol { tcp, udp } flow offload @f

          # Because of PPPoE
          tcp flags syn tcp option maxseg size set rt mtu

          # Allow trusted network WAN access
          iifname {
            "eno1",
          } oifname {
            "ppp0",
          } counter accept comment "Allow trusted LAN to WAN"

          # Allow established WAN to return
          iifname {
            "ppp0",
          } oifname {
            "eno1",
          } ct state established,related counter accept comment "Allow established back to LANs"
        }
      }

      table ip nat {
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
        }

        # Setup NAT masquerading on the ppp0 interface
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          oifname "ppp0" masquerade
        }
      }
      '';
  };
}
