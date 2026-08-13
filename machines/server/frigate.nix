{ config, pkgs, ... }:

{
  # Runs as the upstream container: caddy owns :80/:443 here and upstream only
  # ships the Docker image. Config is mounted read-only, so the UI editor can't
  # write; edit ./frigate-config.yml and redeploy. Recordings land on the
  # dedicated frigate pool, deliberately not backed up (restic only covers /pool).
  # frigate substitutes {FRIGATE_*} placeholders in config.yml from these env vars.
  age.secrets.frigate-env.file = ../../secrets/frigate-env.age;

  virtualisation.oci-containers.containers.frigate = {
    image = "ghcr.io/blakeblackshear/frigate:0.17.2";

    volumes = [
      "${./frigate-config.yml}:/config.yml:ro"
      "/pool/frigate/config:/config"
      "/frigate:/media/frigate"
    ];

    environmentFiles = [ config.age.secrets.frigate-env.path ];

    environment = {
      TZ = "Europe/Bratislava";
      CONFIG_FILE = "/config.yml";
    };

    # No firewall on this host: the bind addresses are what keeps this off the
    # internet. Web access goes through caddy; these are for WebRTC/RTSP.
    ports = [
      "100.98.141.25:8971:8971" # web UI + API (authenticated)
      "100.98.141.25:8554:8554" # go2rtc RTSP restream
      "100.98.141.25:8555:8555/tcp" # WebRTC
      "100.98.141.25:8555:8555/udp"
      # Internal UNAUTHENTICATED API, tailnet only (the cameras live on the LAN).
      "100.98.141.25:5000:5000"
      "192.168.1.45:8971:8971"
      "192.168.1.45:8554:8554"
      "192.168.1.45:8555:8555/tcp"
      "192.168.1.45:8555:8555/udp"
    ];

    extraOptions = [
      # A capture worker leaked to 9.5G on 2026-08-20 after all RTSP streams
      # dropped at once, drained swap and tripped the global OOM killer. Steady
      # state is ~1.2G, worst legit case ~2.5G; memory-swap == memory keeps the
      # container out of swap so a leak can't starve HA/Nextcloud/mongo.
      "--memory=6g"
      "--memory-swap=6g"
      # Decoded frames are handed between processes through /dev/shm.
      "--shm-size=256m"
      # Recording segments are buffered in tmpfs before moving to disk.
      "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
    ];
  };

  # The tailscale IP must exist before the ports above can bind (boot).
  systemd.services.podman-frigate = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    serviceConfig.RestartSec = "5s";
  };
}
