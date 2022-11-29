{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mailutils
  ];

  services.postfix = {
    enable = true;
    setSendmail = true;
    networks = [ "127.0.0.0/24" ];
    relayHost = "smtp.gmail.com";
    relayPort = 587;
    rootAlias = "martin@elias.sx";

    config = {
      smtp_use_tls = "yes";
      smtp_sasl_auth_enable = "yes";
      smtp_sasl_security_options = "noanonymous";
      smtp_sasl_tls_security_options = "noanonymous";
      smtp_sasl_password_maps = "hash:/etc/nixos/x/postfix-password-maps";
    };
  };
}
