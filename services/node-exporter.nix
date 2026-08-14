{ config, pkgs, ... }:

{
  # Prometheus node_exporter, scraped by the server (machines/server/monitoring.nix).
  # Listens on 0.0.0.0:9100 by default: on the routers nftables only accepts
  # lo/LAN/tailscale0 input; the server binds it to its tailnet IP instead.
  services.prometheus.exporters.node = {
    enable = true;

    # Failed units (including restic-backups-*) become alertable metrics.
    enabledCollectors = [ "systemd" ];
  };
}
