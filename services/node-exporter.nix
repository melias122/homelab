{ config, pkgs, ... }:

{
  # Listens on 0.0.0.0:9100: the routers' nftables only accept lo/LAN/tailscale0,
  # the server rebinds it to its tailnet IP in monitoring.nix.
  services.prometheus.exporters.node = {
    enable = true;

    # Failed units (restic-backups-* included) become alertable metrics.
    enabledCollectors = [ "systemd" ];
  };
}
