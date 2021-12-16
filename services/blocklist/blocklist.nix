{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    go
  ];

  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 0 * * *      root    go run /etc/nixos/services/blocklist/main.go > /etc/hosts.blocklist"
    ];
  };
}
