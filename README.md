# homelab

## Secrets

Managed with [agenix](https://github.com/ryantm/agenix). Encrypted `secrets/*.age` files live in
the repo; per-secret recipients (machine SSH host keys + personal keys) are declared in
[secrets/secrets.nix](secrets/secrets.nix). Each machine decrypts its secrets at activation with
`/etc/ssh/ssh_host_ed25519_key` into `/run/agenix/` (tmpfs), where services read them via
`config.age.secrets.<name>.path`.

Edit an existing secret (opens $EDITOR):

    make edit-secret name=cf-dns-api-token

Add a new secret:

1. add an entry with recipients to `secrets/secrets.nix`
2. `make edit-secret name=<name>` and fill in the content
3. reference it in nix: `age.secrets.<name>.file = ../../secrets/<name>.age;`
   and use `config.age.secrets.<name>.path`

After adding a machine or key to `secrets.nix`, re-encrypt everything:

    make rekey-secrets

Plain age (no agenix CLI) works too:

    age -d -i ~/.ssh/id_ed25519 secrets/<name>.age            # read
    age -d -i ~/.ssh/id_ed25519 secrets/work-id-rsa.age       # e.g. work ssh key
