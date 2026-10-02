{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mailutils
  ];

  # Read by the smtp(8) client which runs as the postfix user.
  age.secrets.postfix-sasl = {
    file = ../secrets/postfix-sasl.age;
    owner = "postfix";
  };

  services.postfix = {
    enable = true;
    setSendmail = true;
    rootAlias = "martin@elias.sx";

    settings.main = {
      relayhost = [ "[smtp.gmail.com]:587" ];
      mynetworks = [ "127.0.0.0/24" ];
      # Outbound relay only; Alertmanager submits to 127.0.0.1:25.
      inet_interfaces = "loopback-only";
      # "may" would let a downgrade send the Gmail app password in clear.
      smtp_tls_security_level = "secure";
      smtp_sasl_auth_enable = "yes";
      smtp_sasl_security_options = "noanonymous, noplaintext";
      smtp_sasl_tls_security_options = "noanonymous";
      smtp_sasl_password_maps = "texthash:${config.age.secrets.postfix-sasl.path}";
    };
  };
}
