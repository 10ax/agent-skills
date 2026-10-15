---
name: dotfiles-collect
description: Use when a task touches machine configuration recorded in ~/dotfiles — collect.sh, install.sh, hosts/atlas, hosts/elitebook, permissions.txt, ETC_REFERENCE, the drift check, the restore/drift/toolchain/systemd-guard suites — and when the work is phrased as "my dotfiles", "my config", "restore my machine", "set this up on the laptop too", "change my KDE/shell/ssh/systemd setup", or "the repo disagrees with the machine".
---

# The dotfiles repo: live is the truth, the repo is the record

`~/dotfiles` records the machine state of **atlas** and **elitebook**: shells, KDE, ssh, systemd, opencode config, memory notes, host scripts. `collect.sh` copies live → repo (redacting secrets, recording modes git cannot store). `install.sh` applies repo → live. Most of the repo is **generated**; a small part is hand-written.

## When to use

- Changing anything that lives in a shell rc, KDE config, ssh config, systemd unit, or the opencode config
- Running, fixing, or extending `collect.sh` / `install.sh`, or the test suites
- A machine and the repo disagree, or a config needs to move to the second machine

**When not to use:** homelab services, the odroid, AdGuard, the stacks, the inventory docs — that is `homelab-ops`.

## Which direction are you going?

| Intent | Direction | Commands |
|---|---|---|
| "change something on this machine" | edit **live**, then record it | edit live → `./collect.sh` → `./collect.sh --check` → suites → commit |
| "make the repo say something else / set up another machine" | edit **repo**, then apply | edit repo → `./install.sh` → verify live → `./collect.sh` (to prove parity) → commit |

Never edit a generated file and stop: the next `collect.sh` overwrites it. Find the live source, change that, and let the collector record it.

## Generated or hand-written?

| Path | Nature |
|---|---|
| `hosts/<host>/shell/`, `kde/`, `opencode/`, `ssh/`, `etc/`, `etc-reference/`, `system/`, `bin/`, `permissions.txt`, `toolchain/manifest.txt`, `NOT-COLLECTED.txt` | **generated** by `collect.sh` |
| `collect.sh`, `install.sh`, `lib/`, `bin/` (repo-level), `docs/`, `README.md`, `test/`, `.github/`, `SECRETS.md`, `skip/<host>.txt` | **hand-written** |
| `hosts/<host>/etc/systemd/...` and other `/etc` files | generated, but from a hand-made system change — if the live file was edited by hand, re-collect so the repo matches |

## The traps

| Trap | What happens | Do instead |
|---|---|---|
| Running `collect.sh` as root or via `runuser` | `systemctl --user` answers empty and the enabled-unit record is destroyed silently | run it as the user, over `ssh <user>@host` — the collector now fails loudly, but do not rely on the guard |
| A backup file inside `$HOME` | `collect.sh` collects it into the repo | put backups in `/tmp/opencode` |
| `sudo` in a tool shell | never works (no TTY) | `pkexec`, or do it over `ssh root@host` |
| `grep` on a config | it is `ugrep -I` here: binary files are skipped silently | `grep -a`, and never `cat` a file that holds a credential |
| Appending to a file with `printf >>` | glues the new line onto the previous one if it lacked a trailing newline | check the tail after appending; this has already happened once |
| Editing `hosts/<host>/shell/.zshrc` by hand | the next collect overwrites it | edit `~/.zshrc` live |
| Assuming a mode survived | git stores only 0644/0755; a 0600 file arrives world-readable | `permissions.txt` carries the rest — see `reference/collect-internals.md` |
| Assuming a package-owned `/etc` file is recorded | it is skipped unless listed in `ETC_REFERENCE` | add it there if it matters (e.g. `/etc/hosts`) |
| Running `test/vm/run.sh` | needs KVM | skip it; the other four suites are the gate |

## The gates

Run all of them before claiming a change is done:

| Suite | Covers | Note |
|---|---|---|
| `./collect.sh --check` | drift between live and repo (structural categories only) | KDE churn is excluded on purpose |
| `test/drift/run.sh` | the collector's own rules, redaction, the secret scan | operates on a copy; never touches the machine |
| `test/restore/run.sh` | `install.sh` restoring both hosts in a container | throwaway container, repo mounted read-only |
| `test/toolchain/run.sh` | `bin/restore-toolchain.sh` replays the recorded versions | stub managers only, never the real ones |
| `test/systemd-guard/run.sh` | the collector keeps the enabled-unit record without a user session | stub `systemctl` |
| CI | `shellcheck -S warning collect.sh install.sh lib/*.sh bin/*.sh test/*/*.sh` + the suites | `.github/workflows/restore-test.yml` |

A check that copies the **working tree** cannot see an untracked file: an untracked `permissions.txt` makes the restore suite green while a fresh clone still loses the modes. Verify what the fresh state does, not what the tree does.

## Committing

Two commits, not one: the tooling/tests/docs change, then the collected snapshot. `git status --short` must be empty afterwards, and the new files (`permissions.txt`, new suites, new memory notes) must be **added** — they are the ones a fresh clone needs.

## Common mistakes

| Mistake | What to do instead |
|---|---|
| Hand-editing a collected file | edit the live file, then `./collect.sh` |
| Running `collect.sh` without a user session | ssh as the user; the record is restored rather than clobbered, but the run fails |
| Leaving a backup or scratch file in `$HOME` | `/tmp/opencode` |
| Committing the snapshot without the new untracked files | `git status --short` before committing; `permissions.txt` and `test/*` are easy to miss |
| Reporting "in sync" without running the suites | the drift check sees structural categories only |

## Rationalisations

| Excuse | Reality |
|---|---|
| "It is quicker to edit the repo copy" | the next collect reverts it; you have fixed nothing |
| "The check is green" | the check copies the working tree; a fresh clone can still differ |
| "I will add the manifest later" | until it is tracked, `install.sh` silently skips every mode it carries |
| "The mode does not matter" | it does the moment a 0600 file arrives world-readable |

## Red flags: stop

- You are about to edit a file under `hosts/<host>/` by hand
- You are about to run `collect.sh` as root, over `ssh root@`, or through `runuser`
- You are about to `cat` a shell rc or a config that holds a token
- You are about to commit without `git status --short` being empty
- You are about to claim "in sync" without having run the suites

## Reference

- `reference/collect-internals.md` — what the collector reads and writes, the mode manifest, `ETC_REFERENCE`/`ETC_DENY`, the redaction and the scan, and the guards
