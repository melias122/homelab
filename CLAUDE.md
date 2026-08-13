# CLAUDE.md

## Repo overview

NixOS configs for the homelab, deployed by rsync + `nixos-rebuild` from the Makefile (no
flakes for the remote machines, no deploy tool). `README.md` covers secrets; this file covers
layout, workflow and the things that aren't obvious from a single file.

```
machines/<host>/   per-host configuration.nix + host-specific service modules
roles/common.nix   imported by every host: agenix, users/root SSH keys, timezone,
                   base packages, nix GC, system.autoUpgrade (nixos-26.05-small)
services/          host-agnostic modules (openssh, tailscale, node-exporter, postfix, …)
secrets/           agenix *.age + secrets.nix recipient manifest
shelly/            scripts running on Shelly devices, deployed with shelly/deploy.sh
users/, home/      melias122 desktop/home-manager bits (used by box / MacBook-Air)
```

### Hosts

| host | role | how it's deployed |
| --- | --- | --- |
| `server` | Xeon + ZFS: HA, Frigate, Nextcloud, UniFi, Caddy, restic, Prometheus/Grafana, Time Machine | `make deploy-server` (`switch`) |
| `router-home` | home site router: PPPoE (Telekom), networkd DHCP server, blocky, nftables | `make deploy-router-home` (`boot`) |
| `router` | second site router, same module set | `make deploy-router` (`boot`) |
| `box` | desktop, flake-based | `make flake-switch-box` locally |
| `MacBook-Air` | nix-darwin, flake-based | `make flake-switch-MacBook-Air` |
| `cloud` | config only, no Makefile target | — |

Both routers set `networking.hostName = "router"`; they are told apart by SSH target
(`root@router-home` vs `root@router`) and by their host keys in `secrets/secrets.nix`.
Router deploys use `nixos-rebuild boot`, so changes land on reboot, not immediately.

### Deploy workflow

`make deploy-<host>` rsyncs the repo to `/etc/nixos` (`--delete`, excluding `.git`, `flake*`,
`*oddin*`), symlinks `machines/<host>/configuration.nix` into `/etc/nixos/`, then rebuilds
over SSH. Consequences worth remembering:

- Uncommitted changes deploy too — the working tree is the source of truth, not git.
- `make deploy-all` = server + both routers.
- Hosts also self-upgrade via `system.autoUpgrade`, so an unrelated channel bump can be the
  reason a build suddenly fails (e.g. the Caddy plugin vendor hash in `machines/server/caddy.nix`).

### Networking

- Home LAN `192.168.1.0/24`, gateway `router-home` = `192.168.1.1`, DHCP pool `.100–.250`,
  static leases (switches, APs, cams, printer, Hue bridge `.60`, Shellys `.70–.77`,
  server `.45`) in `machines/router-home/dhcpd4.nix`. Second site is `192.168.2.0/24`.
- Tailnet `robin-shark.ts.net`; server = `100.98.141.25`. `firewall.enable = false` on server
  and routers, so services are kept private by *binding to the tailnet IP* (HA, Grafana,
  Frigate, node-exporter, nginx:54443) — never assume a firewall will save an exposed port.
- Caddy terminates TLS for `*.elias.sx` via the Cloudflare DNS plugin and reverse-proxies to
  `100.98.141.25`. `router-home/blocky.nix` adds split-DNS so LAN clients without Tailscale
  resolve those names to `192.168.1.45`.

### Conventions

- Nix files carry *why* comments (pins, workarounds, non-obvious bindings). Keep that style:
  when adding a pin, hash or workaround, say what breaks without it.
- Comments are terse and to the point — one line where one line does, no restating the code,
  no background essays. Prefer trimming a comment to padding it.
- Secrets are never plaintext in the repo. Add to `secrets/secrets.nix` → `make edit-secret
  name=<x>` → reference via `config.age.secrets.<x>.path` (decrypted to `/run/agenix`).
  Secrets used only from the laptop (work creds, `hue-shelly-key`) list `users` as recipients.
- Home Assistant: UI/config-flow integrations live in `.storage` on the server (backed up by
  restic, not in git); only YAML-only bits go into `services.home-assistant.config`. New
  integrations usually just need an entry in `extraComponents`.
- Backups: `restic.local` → `/backup/restic` daily, `restic.b2` → Backblaze monthly. Both
  cover `/pool` + root-SSD state git can't restore (`/var/lib/hass`, `samba`, `caddy`).

## Naming Conventions — Home Assistant

### Entity ID pattern

```
type_room_qualifier
```

Examples:

```
svetlo_obyvacka_strop
svetlo_obyvacka_lampa_gauc
zaluzia_spalna_vychod
senzor_kupelna_vlhkost
zasuvka_kuchyna_pracka
```

### Rules

- Language: Slovak names, no diacritics in entity IDs (`spalna`, `kupelna`). Diacritics only in friendly names.
- Entity IDs are never renamed once created (renaming breaks automations and history). Friendly names can change anytime.
- Friendly name = what the UI and voice assistant use (e.g. "Stropné svetlo"). Doesn't need to include the room.
- Qualifier = function or location, never hardware. ✅ `zaluzia_obyvacka_terasa` ❌ `zaluzia_shelly2pm_3`
- For multiple identical devices in a room, use cardinal directions or landmarks (`vychod`, `okno`, `dvere`), not numbers.
- Name devices at install time (Shelly web UI, Hue app) — HA inherits those names.
- Multi-channel devices: name each channel separately (`svetlo_kuchyna_linka`, `svetlo_kuchyna_strop`).

### Areas / Floors / Labels

- Assign every device to an Area (room) and a Floor.
- Properties like "outdoor", "critical", "christmas" belong in Labels, not in entity names.
- Target automations at areas instead of listing entities wherever possible.

### Helpers and automations

Automation pattern: `what_when/why`

```
input_boolean.rezim_dovolenka
input_boolean.hoste_doma
automation.zaluzie_tienenie_juh_leto
automation.zavlaha_preskocit_pri_dazdi
automation.pracka_notifikacia_dopranie
```
