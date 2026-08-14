# Recipient manifest for the agenix CLI (not imported by NixOS).
#
# Edit a secret:  cd secrets && nix run github:ryantm/agenix -- -e <name>.age -i ~/.ssh/id_ed25519
# Rekey all:      cd secrets && nix run github:ryantm/agenix -- --rekey -i ~/.ssh/id_ed25519
let
  martin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIND17TDL2rPoWedCiuSq2dklxRkvtDufAWo5U/ZCRCtD";
  martin-mac = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwuhSIOGM2vy0OFOku+itsEMqDW0a93MQNg4cjGncub";
  users = [ martin martin-mac ];

  # /etc/ssh/ssh_host_ed25519_key.pub of each machine
  server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILRmr8J+XfTK/i8PbX5dmU7qkld5WlIshbqPj7jVuROO";
  router = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEYNmUYSnXw65WNWeV3jD5FQG6Gy/kJaREgCRmzd2ER8";
  router-home = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGWnzFE073jXShRM9Z1DSltsGkTxLgcwisSTxKw2ZjBZ";
in
{
  "restic-password.age".publicKeys = users ++ [ server ];
  "restic-b2-env.age".publicKeys = users ++ [ server ];
  "nextcloud-adminpass.age".publicKeys = users ++ [ server ];
  "caddy-env.age".publicKeys = users ++ [ server ];
  "frigate-env.age".publicKeys = users ++ [ server ];
  "grafana-secret-key.age".publicKeys = users ++ [ server ];
  "hc-ping-url.age".publicKeys = users ++ [ server ];
  "unpoller-pass.age".publicKeys = users ++ [ server ];
  "postfix-sasl.age".publicKeys = users ++ [ server router router-home ];
  "pppd-telekom.age".publicKeys = users ++ [ router ];
  "pppd-telekom-home.age".publicKeys = users ++ [ router-home ];

  # Work credentials, not used by any machine.
  "work-aws-config.age".publicKeys = users;
  "work-aws-credentials.age".publicKeys = users;
  "work-aws-ssh-user.age".publicKeys = users;
  "work-id-rsa.age".publicKeys = users;
  "work-id-rsa.pub.age".publicKeys = users;
}
