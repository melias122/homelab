{ ... }:
{
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
    daemon.settings = {
      dns = [ "8.8.8.8" "1.1.1.1" ];
    };
  };
}
