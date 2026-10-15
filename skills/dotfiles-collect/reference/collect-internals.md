# collect.sh internals

Depth for `dotfiles-collect`. Verified against the script on 2026-10-15; the script is the authority if this drifts.

## Re-verify before trusting

| Claim | Check it with |
|---|---|
| the suites exist and what they report | run them: `./test/drift/run.sh`, `./test/restore/run.sh`, `./test/toolchain/run.sh`, `./test/systemd-guard/run.sh` |
| the CI gate's exact command | `grep -n shellcheck ~/dotfiles/.github/workflows/restore-test.yml` |
| `ETC_REFERENCE` / `ETC_DENY` contents | `sed -n '/ETC_REFERENCE=(/,/^)/p' ~/dotfiles/lib/manifest.sh` |
| which categories `--check` compares | `grep -n -A6 DRIFT_CATEGORIES ~/dotfiles/lib/manifest.sh` |
| the guard names and what they gate | `grep -n 'INCOMPLETE' ~/dotfiles/collect.sh \| head` |
| the umask pin and the scan's excludes | `grep -n 'umask\|--exclude=' ~/dotfiles/collect.sh` |
| which hosts are recorded | `ls ~/dotfiles/hosts/` |
| the mode manifest still has entries | `wc -l ~/dotfiles/hosts/*/permissions.txt` |
| the ssh key names | `ls ~/.ssh/id_ed25519_*` |

## What it writes

`collect.sh` runs on the machine being collected (`$(hostname)` → `hosts/<host>/`). It writes:

| Category | Source | Applied back by `install.sh`? |
|---|---|---|
| `shell/` | `~/.zshrc`, `.zprofile`, `.bashrc`, `.bash_profile`, `.profile` | yes, over `$HOME` |
| `kde/` | selected KDE config files (modes recorded separately) | yes |
| `opencode/` | `~/.config/opencode/`, excluding `telegram.env`, `service.json`, `.caveman-active`, `skills/*`, `*.bak*` | yes |
| `ssh/config` | `~/.ssh/config` only — never the keys | yes |
| `etc/` | `/etc` files no package owns, minus the denylists | yes, with `sudo` |
| `etc-reference/` | package-owned `/etc` files worth recording | **no** — "for a human, never applied" |
| `system/` | enabled and masked unit lists | no |
| `bin/` | host-specific scripts | yes |
| `packages`, `toolchain/manifest.txt` | installed packages and tool versions | `bin/restore-toolchain.sh` replays the versions |
| `permissions.txt` | modes git cannot store | yes |
| `NOT-COLLECTED.txt` | files it could not read unprivileged | no |

## Redaction and the secret scan

Shell files are copied through a redactor: a line whose value looks like a credential becomes `# VAR=<redacted-by-collect.sh-see-SECRETS.md>`. Then a scan runs over the whole tree and **must report `clean`** — a hit aborts the collect. The scan's hex rule excludes the two root-level generated lists (`permissions.txt`, `NOT-COLLECTED.txt`), which are written before it runs and would otherwise match themselves.

Never rely on the redactor for a *new* shape of secret: `SECRETS.md` records what is deliberately excluded, and a token that is not on the redactor's list reaches the repo. If you add a credential to a shell rc, run `collect.sh` and check the repo copy shows a redaction marker, not a value.

## The mode manifest

`permissions.txt` holds one line per file whose live mode is not what git would reproduce:

```
600	kde/kwinrc
600	opencode/cli.json
```

git stores only 0644 and 0755, so 0600 files would arrive world-readable from a fresh clone. `install.sh` applies the manifest through a `mode_target()` mapping (category → install destination), reporting any entry it cannot map or whose target is missing.

Limits worth knowing:

- it records only modes git **cannot** carry; it cannot express a disagreement between the live mode and the git index
- the restore suite copies the **working tree**, so an untracked `permissions.txt` gives a green run while a fresh clone still loses the modes — the file must be committed
- under a different umask the generated content used to change; the script now pins `umask 022` and skips the two root-level lists

## The denylists

| List | Meaning |
|---|---|
| `ETC_DENY` | never collected (volatile or secret-bearing) |
| `ETC_REFERENCE` | recorded for a human, never applied — currently `/etc/hosts`, `fstab`, `crypttab`, `hostname`, `default/grub`, `mkinitcpio.conf`, `mkinitcpio.d/linux.preset` |
| `ETC_OWNED_BUT_MINE` | package-owned but ours to record |
| `NOT-COLLECTED.txt` | what the collector could not read unprivileged (elitebook's `/etc/crypttab`) |

A package-owned `/etc` file that matters is skipped unless it is in `ETC_REFERENCE`. That is the fix when a config you care about keeps disappearing from the repo.

## The guards

Two failure modes were found by using the thing, and both are now loud:

| Guard | Triggers on | Behaviour |
|---|---|---|
| toolchain (`TOOLCHAIN_INCOMPLETE`) | `pipx list` non-zero, empty output on a host known to have pipx packages, or pipx missing there | warning on stderr, non-zero exit, `--check` reports `DRIFT in toolchain` |
| systemd user (`SYSTEMD_USER_INCOMPLETE`) | `systemctl --user` non-zero, or an empty answer while the repo records a list | keeps the recorded `systemd/enabled.txt` instead of clobbering it, fails loudly; `--check` compares that file |

The escape hatch for a genuinely emptied unit list is to empty `hosts/<host>/systemd/enabled.txt` by hand and commit it.

## What `--check` compares

Structural categories only: `packages`, `system`, `etc`, `etc-reference`, `toolchain`. KDE, opencode, shell and the reference snapshots churn constantly and are deliberately not compared — that churn is why the collector exists, not what the check is for. "In sync" therefore means "nothing structural drifted", not "the repo equals the machine".

## The suites and their isolation

| Suite | Isolated how |
|---|---|
| `test/drift/run.sh` | tar copy in a temp dir; the machine is read-only |
| `test/restore/run.sh` | throwaway Arch container, repo bind-mounted read-only, both hosts |
| `test/toolchain/run.sh` | stub managers pinned on `PATH`; asserts each stub resolves before running |
| `test/systemd-guard/run.sh` | stub `systemctl`; refuses to run if the stub does not shadow the real one |
| `test/vm/run.sh` | needs KVM — not run in CI |

CI (`.github/workflows/restore-test.yml`) runs `shellcheck -S warning` over the scripts and then the suites in order.

## ssh keys and the host layout

One key per purpose, never shared: `id_ed25519_did69` (work GitHub), `id_ed25519_10ax` (personal GitHub), `id_ed25519_dietpi` (the odroid). `~/.ssh/config` is collected; the keys are not. Host aliases are pinned by `HostName` where a name would otherwise depend on DNS.

`skip/<host>.txt` lists apps deliberately not carried to a host.

Memory notes under `~/.config/opencode/memory/` are collected on purpose: editing a note is a repo change, so it needs the same collect-and-commit as any other live edit.
