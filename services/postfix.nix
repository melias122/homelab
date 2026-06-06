{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mailutils
  ];

  services.postfix = {
    enable = true;
    setSendmail = true;
    rootAlias = "martin@elias.sx";

    settings.main = {
      relayhost = [ "smtp.gmail.com:587" ];
      mynetworks = [ "127.0.0.0/24" ];
      smtp_use_tls = "yes";
      smtp_sasl_auth_enable = "yes";
      smtp_sasl_security_options = "noanonymous";
      smtp_sasl_tls_security_options = "noanonymous";
      smtp_sasl_password_maps = "hash:/etc/nixos/x/postfix-password-maps";
    };
  };
}
