---
name: homelab-ops
description: Use when a task touches the homelab services — AdGuard DNS/DHCP, the *arr stack, Jellyfin, qBittorrent, Nginx Proxy Manager, Home Assistant, Glance/Glances dashboards, Dockge stacks, the compose files under /root/docker, or the records in ~/Homelab/homelab-backup — and when anything is phrased as "the odroid", "the box", "the stack", "the reverse proxy", "the dashboard", "the inventory", "DNS is not resolving", or "the house is down".
---

# Homelab operations

Two machines run the services: **odroid** (192.168.1.7, DietPi, 24/7, 16 GB microSD + 233 GB SATA) and **atlas** (192.168.1.9, Arch, workstation). The odroid runs what the house notices when it stops — DNS and DHCP first. The repos are the record; this skill is the routing and the blast radius, not a second copy of the docs.

## When to use

- Any change to a service on the odroid or to its compose stacks
- AdGuard, DNS, DHCP, the reverse proxy, the dashboards, the inventory docs
- "Why is X not resolving / not loading / not discovered"
- Deciding *where* something should run, or *which* copy of a config is the real one

**When not to use:** machine configuration that is not a homelab service — KDE, shells, ssh, systemd units, zram, dotfiles — is `dotfiles-collect`. A single container's application bug is ordinary debugging; reach for `systematic-debugging`.

## Read before you act

| The task mentions | Read first | Because |
|---|---|---|
| the machines, what runs where | `~/Homelab/homelab-backup/README.md` | machines table + the three rules that break silently |
| any service, port, path, "what is this" | `~/Homelab/homelab-backup/docs/homelab-inventory.md` | the canonical 232 KB inventory — it is the record |
| AdGuard, DNS, DHCP, filters, clients | `reference/odroid-and-adguard.md` | the config is rewritten by the app; the healthcheck can take the house down |
| *arr, hardlinks, downloads, imports | `docs/arr-stack-setup-guide.md`, `odroid/arr-stack/` | one `/data` root or imports copy instead of hardlinking |
| reverse proxy, `*.tenax-casa.duckdns.org` | `odroid/npm/`, memory `odroid-npm-duckdns-map.md` | a new name is a line in a `map`, not a proxy host |
| Home Assistant automations, dashboards | `atlas/home-assistant/config/` (live on atlas) | the odroid's copy is the **retired** duplicate |
| Jellyfin, the music library, tagging | `docs/music-library-repair.md`, `docs/aggiungere-una-serie.md` | repair runbooks, not guesses |
| the odroid's boot, SATA, RTC | `docs/odroid-hc4-boot-notes.md` | three fixes are manual and revert on upgrade |
| the network, ISP, router | `docs/ehiweb-network-config.md`, `docs/isp-switch-network-config.md`, memory `lan-dns-magicdns-chain.md` | AGH is DHCP; the FritzBox announces it as DNSv6 |
| what is open, and why it matters | `~/Documents/SecondBrain/300-Aree/homelab-backup.md`, `600-Backlog/homelab.md` | the vault holds what memory does not |

Memory notes worth loading by name (`~/.config/opencode/memory/home-tenax*/`): `odroid-arr-stack`, `odroid-sd-write-wear`, `odroid-sd-full-agh-crashloop`, `odroid-adguard-healthcheck-fragility`, `odroid-npm-duckdns-map`, `odroid-qbittorrent-dht-tailscale`, `odroid-dual-language-ita-eng`, `adguard-per-client-settings-inert`, `adguard-querylog-ask-first`, `home-network-fritzbox`.

## Blast radius: the odroid is the house's DNS and DHCP

| Action | Trap | Do this instead |
|---|---|---|
| Stop/reload AdGuard | `adguard-healthcheck.timer` runs every 5 min; its check can restart DNS+DHCP for the whole house mid-work | `systemctl stop adguard-healthcheck.timer` **first**, record its state, re-enable it at the end — never leave it off |
| Edit `AdGuardHome.yaml` by hand | other automation writes it too, and AdGuard **rewrites it from memory at every start** — unknown keys are dropped, client blocks are re-serialised | stop → edit → validate YAML → start; change only what you mean; keep a timestamped `.bak-<date>` beside it |
| Change per-client settings | with `use_global_settings: true` every per-client field is inert, and the app re-adds fields you delete | see `reference/odroid-and-adguard.md`; the house's real per-device exceptions are `$client=` user rules |
| Add a client with the naming tool | `gen_clients.py` merges and never removes; a rename + MAC change leaves a phantom, and the tool will not delete it for you | follow its documented manual removal, and check the batch count against the live config |
| Run anything heavy on the odroid | 3.7 GB RAM; a browser/JVM/transcoder there invoked the global OOM killer once and took DNS down with it | it belongs on atlas (that is why Tdarr and FlareSolverr live there) |
| Let an app write SQLite to the root fs | the root is a 16 GB microSD that wears out; a full card crash-looped AGH and left the house without DNS | app config goes under `/mnt/dietpi_userdata/appdata/` on the SATA disk |
| Split `/data` into `/downloads` + `/media` | imports then copy instead of hardlinking, doubling disk use | one bind-mount root: `/mnt/dietpi_userdata/data` |
| Reboot the odroid | it takes DNS, DHCP and the download client down; SATA/PCIe is fragile at boot and the RTC is not trustworthy | prefer `systemctl restart <unit>`; if you must reboot, say so and check `sd-space-guard` first |
| Re-point a reverse proxy | NPM resolves `*.tenax-casa.duckdns.org` through a `map $host $svc_target`; a missing line gives a 404 "no such service" | add the line, not a proxy host |
| Edit an HA automation | the live instance is on **atlas**; the odroid copy is retired. The YAML dashboard needs a restart, automations need a reload | edit the atlas copy, then reload/restart and check the log for `invalid config` |

## Generated artifacts: find the source

| Artifact | Generated by | Refresh with |
|---|---|---|
| `docs/homelab-inventory.md`, the docs' `Last updated` | `collect.sh` in this repo (its own, different from the dotfiles one) + the `.githooks` pre-commit stamp | `./collect.sh` in `~/Homelab/homelab-backup` |
| `atlas/`, `odroid/` service configs | the same `collect.sh` | as above |
| the odroid compose stacks | hand-written under `/root/docker` (public repo) | edit, then commit |
| AdGuard's client block | `gen_clients.py` in `/root/adguard-naming/` | `python3 gen_clients.py <mode>` — never hand-edit the block |
| autodoc blocks in repo docs elsewhere | the autobuild `improve`/`document` lanes | fix the brief in `~/autobuild/backlog/`, then re-run the lane (stop the daemon first) |

Never hand-edit a generated file and call it done: the next run overwrites it, and the reviewer will find the source was never fixed.

## Secrets

`10ax/docker` is **public**. Nothing secret may ever enter it — no config with a password, no hash, no key, no session database. See `reference/secrets-and-history.md` for what is excluded, how to rotate, and how to purge a leak from history. Never print a secret value into a transcript; pass paths, and use `grep -q` when you only need existence.

## Verifying a homelab change

1. **Check the live thing first.** A backlog line, a doc, or a memory note is a claim about the past; `systemctl`, `dig`, `docker ps`, `git log` are claims about now. Today 5 of 22 backlog items were already done and only a live check caught it.
2. **Keep the record true.** After changing anything on a machine, refresh the record (`./collect.sh` here; `dotfiles-collect` for machine state) so the repo does not keep asserting the old value.
3. **Then the generic gates** — `verification-before-completion` before claiming success, and a fresh reviewer for anything with a blast radius.

## Common mistakes

| Mistake | What to do instead |
|---|---|
| Implementing a backlog item without checking whether it still exists | grep the live system and the git log first; close stale items instead |
| Editing the live file and stopping there | refresh the repo record, or the next reader restores the old value |
| Asserting a number from a doc | measure it (swap totals, container counts, unit lists); today's docs said 22.9 GiB where the truth was 23.02 |
| Trusting "identical to the other host" | compare the two files; the two hosts diverged on purpose |
| Running `collect.sh` over `ssh root@host` or `runuser` | run it as the user: without a session `systemctl --user` answers empty and the record is destroyed |
| `git add -A` in the odroid repo | it sweeps unrelated deletions and symlinks into your commit; stage paths |
| Reading the AdGuard query log | the user has declined that; ask first |

## Rationalisations

| Excuse | Reality |
|---|---|
| "The backlog says it is broken, so it is" | Five items today were already fixed; the backlog is a memory of a symptom, not a state |
| "It is only a comment / only a doc" | The repo is the record; a stale comment is what the next agent acts on |
| "I redacted it in my report" | Printing it at all put it in the transcript; two agents did exactly this today |
| "The check passed, so the change is safe" | A check that copies the working tree cannot see an untracked file; verify what the *fresh* state does |
| "I will push now and purge later" | Pushing bakes the secret into the remote history; rotate, purge, then push |

## Red flags: stop

- You are about to restart or reload AdGuard without having stopped `adguard-healthcheck.timer`
- You are about to hand-edit a file that a generator or the application itself rewrites
- You are about to put a config, hash, or database into `10ax/docker`
- You are about to push a repo you have not checked for secrets in its **history**
- You are about to report a value you have not measured
- You are about to act on a homelab doc without opening the live system once

## Reference

- `reference/odroid-and-adguard.md` — the safe procedures: AdGuard config and reloads, the naming generator, backups and pruning, the SD guard, the DNS chain
- `reference/repos-and-hosts.md` — which repo and host owns what, and where the depth lives
- `reference/secrets-and-history.md` — the public-repo rule, rotation, and purging a leak
