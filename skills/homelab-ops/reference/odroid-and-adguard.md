# The odroid and AdGuard: safe procedures

Depth for `homelab-ops`. Facts here were verified live on 2026-10-15 unless a date says otherwise.

## The host

| | |
|---|---|
| Address | 192.168.1.7 on the LAN; `100.119.32.100` on the tailnet |
| Access | `ssh root@192.168.1.7`, or the aliases `dietpi` / `dietpi-ts` (tailnet) and `dietpi-lan` / `odroid` (LAN), key `~/.ssh/id_ed25519_dietpi` |
| OS | DietPi (Debian 13), Cortex-A55 ×4, 3.7 GB RAM |
| Storage | 16 GB microSD as root; 233 GB SATA as `/mnt/dietpi_userdata` |
| Role | the services the house notices when they stop: DNS, DHCP, the download client, the media server |

The three rules that break silently (one `/data` root for hardlinks, nothing SQLite on the microSD, nothing memory-hungry on 3.7 GB) are in `~/Homelab/homelab-backup/README.md`. Read them there; they are not repeated here.

## AdGuard: it is native now, and it rewrites its own config

Since 2026-07-28 AdGuard runs as a native systemd service, not a container. The Docker-era directory `/root/docker/adguard-home` was deleted 2026-10-14.

| | |
|---|---|
| Binary and config | `/opt/AdGuardHome/AdGuardHome.yaml` |
| Admin UI | `http://192.168.1.7:3001` |
| Units | `AdGuardHome.service`, `adguard-healthcheck.service` + `.timer` (every 5 min) |
| Health script | `/usr/local/sbin/check-adguard-health.sh` (30-minute cooldown, fires after 3 consecutive failures) |

**The healthcheck is the trap.** Its check can restart DNS and DHCP for the entire house while you are mid-change. Before any AdGuard work:

```bash
systemctl is-enabled adguard-healthcheck.timer; systemctl is-active adguard-healthcheck.timer   # record both
systemctl stop adguard-healthcheck.timer && systemctl disable adguard-healthcheck.timer
# ... do the work ...
systemctl enable adguard-healthcheck.timer && systemctl start adguard-healthcheck.timer
```

**Reload semantics — the app does not re-read the file on reload.** The unit has no `ExecReload`, and `SIGHUP` only reloads ARP state and TLS. The house recipe is **stop → edit → start**. `systemctl restart` on a running instance is fine; a `reload` is not a config reload.

**The config is re-serialised at every start.** AdGuard v0.107.54 writes `clients.persistent` back from memory with no `omitempty`, so:

- deleting a per-client field does not stick — it comes back
- hand-editing client blocks is pointless unless you also stop the service
- unknown keys are dropped

**Per-client settings are inert while `use_global_settings: true`.** That is true for every client in this house. The real per-device exceptions are `user_rules` with `$client='<ip>'` (the LG TV's exception is written that way). See memory `adguard-per-client-settings-inert`.

**The query log is off limits.** The user has declined having the query log read (memory `adguard-querylog-ask-first`). Ask before doing anything that would read it.

### The procedure for any AdGuard config change

```bash
# 1. park the healthcheck (above), then back up with the house convention
cp -a /opt/AdGuardHome/AdGuardHome.yaml /opt/AdGuardHome/AdGuardHome.yaml.bak-$(date +%F-%H%M%S)
sha256sum /opt/AdGuardHome/AdGuardHome.yaml          # record it
# 2. stop, edit, validate YAML (the odroid has no PyYAML: copy it to atlas to validate)
systemctl stop AdGuardHome
# ... edit ...
systemctl start AdGuardHome
# 3. verify it actually serves: resolution, filtering, and that the admin password still works
dig +short @127.0.0.1 example.com
dig +short @127.0.0.1 doubleclick.net                # expect 0.0.0.0 (blocked)
curl -s -o /dev/null -w '%{http_code}\n' -u "admin:$(cat /root/adguard-admin-password-*.txt)" http://127.0.0.1:3001/control/status
# 4. restore the timer exactly as recorded
```

An empty answer from `dig` in the first seconds after a start means it has not bound yet — wait and re-check before concluding it is broken.

## The client naming generator

`/root/adguard-naming/`: `inventory.py` (the source of truth for names and MACs), `gen_clients.py` (rewrites the client block), `check_inventory.py`, `fix_leases.py` (purges **leases** only — it never touches clients), `BATCH-RECIPE.md`, `backup.sh`.

`gen_clients.py` **merges**: it rewrites only the clients it emits and preserves any existing client it cannot account for by name, deterministic uid, or any id (MAC/IP), printing the preserved ones. Consequences to remember:

- it can never remove a client; removing one is a deliberate manual edit of the `clients.persistent:` region in the config, followed by a restart
- a rename **and** a MAC change in the same batch leaves the old entry behind as a phantom — remove it by hand
- the batch count in `BATCH-RECIPE.md` is *emitted + preserved* (16 on 2026-10-15), not just the inventory count

## DHCP, DNS, and the chain

AGH serves DHCP as well as DNS (the FritzBox's DHCP is off; it announces AGH as DNSv6). Leases live in `data/leases.json`; `/usr/local/sbin/adguard-disable-dhcp.sh` exists for handing DHCP back.

Resolution chain: LAN clients → AGH (192.168.1.7) → tailnet names forwarded to MagicDNS `100.100.100.100` via the split upstream `[/tail57bbb.ts.net/]` → public resolvers. On dietpi, `/etc/resolv.conf` is a real file, not a symlink. A bare tailnet name does **not** resolve (no search domain) — use the FQDN or the pinned aliases. Memory: `lan-dns-magicdns-chain`, `home-network-fritzbox`.

## Backups, pruning, and the SD card

| | |
|---|---|
| Backups | `/mnt/dietpi_userdata/backups/` (SATA, durable) — tar archives named with the date |
| Pruning | `prune-backups.timer` + `/usr/local/sbin/prune-backups.sh` |
| SD guard | `sd-space-guard.timer` + `/usr/local/sbin/sd-space-guard.sh`, alerts at 85 % of the root fs |

A full microSD is not a slow-machine problem: it crash-looped AGH and left the house without DNS (2026-08). Anything you leave behind on the root fs is a liability. Backups holding credentials are `chmod 600` (the AdGuard archive contains the admin hash).

`/tmp` on the odroid is **tmpfs** — a tar left there dies on reboot. Move it to `backups/` when it is the only copy.

## The rest of the stack, and where each one bites

| Service | Where | The trap |
|---|---|---|
| Nginx Proxy Manager | `/root/docker/nginx-proxy-manager`, UI `http://192.168.1.7:81` | `*.tenax-casa.duckdns.org` is a line in the `map $host $svc_target` of `custom/http.conf`; a missing line gives a 404 "no such service". Never a proxy host. Memory `odroid-npm-duckdns-map` |
| Dockge | `http://192.168.1.7:5001` | account lives in `/mnt/dietpi_userdata/appdata/dockge/dockge.db` (sqlite, `user` table). The password is bcrypt — unrecoverable. Reset: stop the container, `delete from user`, start, then create the account in the browser. Stacks live under `/opt/stacks` |
| Homepage | `http://192.168.1.7:3000`, config in `appdata/homepage` | the widgets do work (verified 2026-10-15); "Please wait" for the first seconds is the loading state, not a fault. The atlas Glances widget cannot be added while Glances binds 127.0.0.1 |
| Home Assistant | **atlas**, `~/docker/home-assistant/config/` | the odroid copy is the retired duplicate. YAML mode: automations reload from the GUI, the YAML dashboard needs a container restart. No long-lived token exists, so a reload is a GUI action. After any edit check the log for `invalid config`. The container-count alert is `sensor.office_odroid_containers_active` (Glances) with the threshold hardcoded in **eight** places across `automations.yaml` and `dashboards/homelab.yaml` |
| Glances | both hosts, REST on 61208, feeding HA | atlas's binds `127.0.0.1`, so nothing on the odroid can scrape it |
| qBittorrent | odroid, native | DHT bootstraps over the wrong interface when Tailscale's IPv6 ULA is in play — bind it to eth0/192.168.1.7. Memory `odroid-qbittorrent-dht-tailscale` |
| Jellyfin, the \*arr stack | odroid | imports hardlink through the single `/data` root; `recyclarr` syncs TRaSH profiles; the dual-language ITA+ENG setup is a Prowlarr YAML + a Sonarr custom format. Memory `odroid-arr-stack`, `odroid-dual-language-ita-eng` |

## The odroid repo (`/root/docker`)

Public at `10ax/docker`. Compose files, stack docs, the retired leftovers. It has a git repo of its own with a `main` branch; the odroid has **no push credentials**, so a push is done from atlas against a clone (`git@github-10ax:10ax/docker.git`).

Two traps learned the hard way (2026-10-15):

- `git add -A` would have replaced 25 tracked `home-assistant/config/**` files with the appdata symlink. Stage paths, never `-A`.
- the history held the AdGuard admin hash; it was purged with `git filter-repo` before the first push. See `secrets-and-history.md`.
