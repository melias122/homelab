{ config, pkgs, ... }:

{
  # Frigate NVR (https://frigate.video) for the Dahua cams (192.168.1.50-53).
  #
  # Runs as the upstream container: caddy owns :80/:443 on this host and
  # upstream only supports the Docker image. Config comes from
  # ./frigate-config.yml in this repo (mounted read-only, so the UI config
  # editor can't write — edit here + redeploy). /pool/frigate/config keeps
  # only state (frigate.db, model cache), recordings land on pool/frigate.
  # UI: http://server:8971 (authenticated; the initial admin password is
  # printed to the logs on first start: `podman logs frigate`).
  # Camera RTSP password; frigate substitutes {FRIGATE_*} placeholders
  # in config.yml with these env vars.
  age.secrets.frigate-env.file = ../../secrets/frigate-env.age;

  virtualisation.oci-containers.containers.frigate = {
    image = "ghcr.io/blakeblackshear/frigate:0.17.2";

    volumes = [
      "${./frigate-config.yml}:/config.yml:ro"
      "/pool/frigate/config:/config"
      "/pool/frigate:/media/frigate"
    ];

    environmentFiles = [ config.age.secrets.frigate-env.path ];

    environment = {
      TZ = "Europe/Bratislava";
      CONFIG_FILE = "/config.yml";
    };

    # Bound to the tailnet IP + home LAN (the firewall is disabled on this
    # host, bind addresses are what keeps this off the internet). Web access
    # goes through caddy (frigate.elias.sx), these are for WebRTC/RTSP and
    # direct access.
    ports = [
      "100.98.141.25:8971:8971" # web UI + API (authenticated)
      "100.98.141.25:8554:8554" # go2rtc RTSP restream
      "100.98.141.25:8555:8555/tcp" # WebRTC
      "100.98.141.25:8555:8555/udp"
      "192.168.1.45:8971:8971"
      "192.168.1.45:8554:8554"
      "192.168.1.45:8555:8555/tcp"
      "192.168.1.45:8555:8555/udp"
    ];

    extraOptions = [
      # Decoded frames are handed between processes through /dev/shm.
      "--shm-size=256m"
      # Recording segments are buffered in tmpfs before moving to disk.
      "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
    ];
  };

  # The ports above bind to the tailscale IP, which must exist before the
  # container starts (relevant on boot).
  systemd.services.podman-frigate = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    serviceConfig.RestartSec = "5s";
  };
}
