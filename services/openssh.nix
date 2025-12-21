{ config, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.melias122.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIND17TDL2rPoWedCiuSq2dklxRkvtDufAWo5U/ZCRCtD"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwuhSIOGM2vy0OFOku+itsEMqDW0a93MQNg4cjGncub"
  ];
}
