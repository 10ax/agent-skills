# Secrets and git history

Depth for `homelab-ops`. The rule is short; the procedures are not.

## The rule

**`10ax/docker` is public.** So are `telegram-photo-vault`, `autobuild`, `10ax.github.io` and several forks. Nothing secret may ever enter them: no key, no token, no password or password hash, no session database, no private TLS key, no `.env` with a real value.

The private repos (`dotfiles`, `homelab-config`, `agent-skills`, `second-brain`) are not a licence either — the convention is that secrets live on the machines and in the password manager, never in git. `SECRETS.md` in each of `homelab-config` and `dotfiles` records what is deliberately excluded and how to restore it.

## Where the values actually live

| Kind | Lives in | Recorded as |
|---|---|---|
| Service credentials (AdGuard admin, Jellyfin API, NPM) | the service's own config on the machine, the password manager | a hash or a `.env` that is gitignored; never the value |
| Shell exports (tokens for CLIs) | `~/.zshrc` / `~/.bashrc` | collected into `dotfiles` **redacted** by `collect.sh` — check the repo copy shows a `<redacted-by-collect.sh>` marker, never a value |
| CI secrets | the GitLab/GitHub project's CI variables | read at run time (`FILE_CONFIG` in the sde repos), never exported in a shell |
| TLS private keys, the internal CA key | on the host, `/mnt/dietpi_userdata/appdata/internal-ca` | only the **public** `homelab-ca.crt` is published |
| Session databases | the app's `appdata/` | gitignored, and never tracked |

If a value is in git, treat it as public and act: rotate first, purge second.

## Rotating, in this house

| Credential | How to rotate |
|---|---|
| AdGuard admin password | stop the healthcheck timer, stop AdGuard, replace the `password:` hash in `/opt/AdGuardHome/AdGuardHome.yaml` with a fresh bcrypt hash, start, verify `curl -u admin:<pw> .../control/status` returns 200. Keep the new password out of the transcript — write it to a `chmod 600` file on the host for the user to collect, then delete it |
| GitHub PAT | revoke it on the account it belongs to. Check *whose* it is before revoking — `gh auth status` lists the configured accounts, and the token itself names its owner: `curl -H "Authorization: token $TOK" https://api.github.com/user` → `login` |
| `gh`'s own login | separate from any PAT: it is an OAuth token in `~/.config/gh/hosts.yml` (or the keyring). Revoking a PAT does not log `gh` out |
| Sonar token | regenerate in the Sonar instance the CI variable `SONAR_URL` points at, then update the CI variable |
| Tailscale | the tailnet admin console; per-host keys expire on their own schedule |

## Purging a leaked blob from history

Order matters: **rotate, then purge, then push.** Pushing first bakes the secret into the remote's history, where it stays even after a later force-push.

```bash
# on the machine that holds the repo (the odroid has no push credentials)
cd /root/docker
git rm --cached <path>                    # if it is still tracked
git commit -m "chore: stop tracking <path>"
apt-get install -y git-filter-repo
git-filter-repo --force --invert-paths --path <path> [--path <path2>]
# filter-repo removes the remotes on purpose; re-add before pushing
git remote add origin <url>

# push from atlas (which has the ssh key), against a clone of the rewritten repo
git clone <machine>:<path> /tmp/opencode/push && cd /tmp/opencode/push
git remote add origin git@github-10ax:10ax/docker.git
git push --force origin main

# verify from a FRESH clone of the remote, not from the working copy
git clone git@github-10ax:10ax/docker.git /tmp/opencode/verify
git -C /tmp/opencode/verify rev-list --all --objects | grep -c '<filename>'   # expect 0
```

`git-filter-repo` refuses to run on a dirty working tree: commit or stage away everything first, and check `git status --short` is clean before you start.

## Worked example (2026-10-15)

`10ax/docker` — a **public** repo — carried the AdGuard admin bcrypt hash in `adguard-home/conf/AdGuardHome.yaml` across five commits, and tracked `home-assistant/adguard-home/work/data/sessions.db`. The directory had been deleted from `HEAD` in an earlier commit, which is the trap: **deleting a file does not delete its history.**

What was done: the password was rotated first (so the leaked hash became worthless), then the paths were untracked and committed, then `git filter-repo --invert-paths` removed both blobs from all 12 commits, the remote was re-added, and the rewritten history was force-pushed from atlas. A fresh clone of the remote reported 0 references to either file.

## The transcript rule

Agents put secrets into transcripts twice in one session while "redacting" — a `grep` that printed the line before it was redacted. There is no cleanup for that; the transcript is stored.

- Never `cat` a config that holds a credential. Read the field you need by name, or `grep -q` for existence.
- Pass **paths** to subagents, not values.
- Never write a credential into a file inside a collected tree: it is collected into a repo and ends up in a transcript later.
- If a value does reach a transcript, say so plainly and rotate it. Do not silently continue.
