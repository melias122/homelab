# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
 secrets = import ./secrets.nix;

in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
    };

   kernel.sysctl = {
      "vm.swappiness" = 10;

      # if you use ipv4, this is all you need
      "net.ipv4.conf.all.forwarding" = true;

      # If you want to use it for ipv6
      "net.ipv6.conf.all.forwarding" = false;

      # source: https://github.com/mdlayher/homelab/blob/master/nixos/routnerr-2/configuration.nix#L52
      # By default, not automatically configure any IPv6 addresses.
      #"net.ipv6.conf.all.accept_ra" = 0;
      #"net.ipv6.conf.all.autoconf" = 0;
      #"net.ipv6.conf.all.use_tempaddr" = 0;

      # On WAN, allow IPv6 autoconfiguration and tempory address use.
      #"net.ipv6.conf.${name}.accept_ra" = 2;
      #"net.ipv6.conf.${name}.autoconf" = 1;
    };
  };

  networking = {
    useDHCP = false;
    nat.enable = false;
    firewall.enable = false;

    hostName = "router";

    # use CoreDNS
    nameservers = [ "127.0.0.1" ];

    interfaces = {
      # 1GbE unused
      eno1 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.1.1";
          prefixLength = 24;
        }];
      };

      # WAN/PPPoE
      eno2.useDHCP = false;

      # 10GbE LAN
      enp2s0 = {
        useDHCP = false;
        #ipv4.addresses = [{
        #  address = "192.168.1.1";
        #  prefixLength = 24;
        #}];
      };
    };

    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {

          # Enable flow offloading for better throughput
          flowtable f {
            hook ingress priority filter;
            devices = { ppp0, eno1 };
          }

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
              "eno1",
            } counter accept comment "Allow localhost and trusted LANs to router"
          }

          chain forward {
            type filter hook forward priority filter
            policy drop

            # Enable flow offloading for better throughput
            ip protocol { tcp, udp } flow offload @f

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
  };

  # Set your time zone.
  time.timeZone = "Europe/Bratislava";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.melias122 = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4E9fCQDVnvqYRINH0XcCZbH/VS65RfAQfOA+eDYlHJ"
    ];

    hashedPassword = secrets.users.melias122.passwordHash;
  };

  environment.systemPackages = with pkgs; [
    conntrack-tools
    ethtool
    htop
    iperf3
    ipmitool
    lm_sensors
    nftables
    nmap
    ppp
    tcpdump
    vim
    wget
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # setup pppoe session
  services.pppd = {
    enable = true;
    peers = {
      telekom = {
        # Autostart the PPPoE session on boot
        autostart = true;
        enable = true;
        config = ''
          plugin rp-pppoe.so eno2

          # pppd supports multiple ways of entering credentials,
          # this is just 1 way
          name ""
          password ""

          persist
          maxfail 0
          holdoff 5

          noipdefault
          defaultroute
        '';
      };
    };
  };

  services.dhcpd4 = {
    enable = true;
    interfaces = [ "eno1" ];
    machines = [
      { ethernetAddress = "68:d7:9a:22:65:25"; ipAddress = "192.168.1.2";  hostName = "UnifiSW-USW-Pro-24"; }
      { ethernetAddress = "80:2a:a8:40:3b:1c"; ipAddress = "192.168.1.10"; hostName = "UnifiAP-pivnica"; }
      { ethernetAddress = "80:2a:a8:80:0d:fb"; ipAddress = "192.168.1.11"; hostName = "UnifiAP-prizemie"; }
      { ethernetAddress = "e0:63:da:21:09:46"; ipAddress = "192.168.1.12"; hostName = "UnifiAP-poschodie"; }
      { ethernetAddress = "00:24:a6:00:31:82"; ipAddress = "192.168.1.20"; hostName = "Digibit-R1"; }
    ];
    extraConfig = ''
      default-lease-time 86400;
      max-lease-time 86400;

      option domain-name-servers 192.168.1.1, 1.1.1.1;
      option subnet-mask 255.255.255.0;

      subnet 192.168.1.0 netmask 255.255.255.0 {
        option broadcast-address 192.168.1.255;
        option routers 192.168.1.1;
        option domain-name-servers 192.168.1.1;
        interface eno1;
        range 192.168.1.100 192.168.1.200;
      }
    '';
  };

  services.coredns = {
    enable = true;
    config = ''
      (defaults) {
        # whoami
        log
        errors
        cache 3600 {
          success 8192
          denial 4096
        }
        # prometheus :9153
        # dnssec
        # loadbalance
      }

      (cloudflare) {
        forward . tls://1.1.1.1 tls://1.0.0.1 {
          tls_servername cloudflare-dns.com
          health_check 30s
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
        import cloudflare
    }
    '';
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
