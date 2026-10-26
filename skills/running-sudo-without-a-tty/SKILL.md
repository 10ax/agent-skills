---
name: running-sudo-without-a-tty
description: Use when sudo fails with a terminal is required to read the password, when an agent needs root from a tool shell, when a GUI password dialog appears for sudo or you cannot tell whether it is polkit, when choosing between pkexec and sudo -A, or when a password prompt looks like an SSH passphrase prompt.
---

# Running sudo without a TTY

A tool shell has no controlling terminal. `sudo` either dies ("a terminal is
required to read the password") or, with an askpass helper, opens a GUI dialog.
Picking the helper is where this goes wrong: the desktop session exports
`SSH_ASKPASS`/`GIT_ASKPASS=/usr/bin/ksshaskpass`, and borrowing that for sudo
makes the root prompt look like an SSH passphrase prompt and hides the command.

## Pick the mechanism

| Situation | Use |
|---|---|
| Caller is in the graphical logind session (seat, not ssh/tty) | `pkexec <cmd>` |
| Sudo is needed and the caller can reach the display | `SUDO_ASKPASS=$HOME/.local/bin/sudo-askpass sudo -A <cmd>` |
| A NOPASSWD rule exists for that exact command | `sudo -n <cmd>` |
| Headless, sshd, CI, or the helper is missing | write the command out; the user runs it in a real terminal |

Check before trusting pkexec:

```sh
loginctl show-session "$(loginctl session-status | head -1 | cut -d' ' -f1)" -p Remote -p Service -p Type
```

`Remote=yes`, `Service=sshd` or `Type=tty` means polkit cannot reach the seat
agent; pkexec falls back to a textual agent and fails without a terminal.

## Never

| Temptation | What breaks |
|---|---|
| `SUDO_ASKPASS=/usr/bin/ksshaskpass` | ksshaskpass titles the window with sudo's prompt, so the dialog is indistinguishable from an SSH key passphrase prompt and never names the command |
| `ssh-askpass`, `ksshaskpass` or `GIT_ASKPASS` for sudo | they are SSH helpers; same failure |
| Typing the SSH key passphrase in a sudo dialog | sudo wants the account password; PAM logs `auth could not identify password for [user]` |
| `sudo -v` to prime the cache | no TTY, and on Arch tickets are per-tty (`tty_tickets`), so the tool shell never sees it |

## The helper

`~/.local/bin/sudo-askpass` (dotfiles `hosts/atlas/bin/sudo-askpass`) is a
`kdialog --password` wrapper. sudo calls it with its PAM prompt as `$1`; it
reads sudo's argv from `/proc/$PPID/cmdline` and prints it under the prompt
(600-character cap). It defaults `DISPLAY=:0` when no display variable is set
and exits with kdialog's status, so Cancel aborts sudo.

```sh
env DISPLAY=:0 WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000 \
  SUDO_ASKPASS="$HOME/.local/bin/sudo-askpass" sudo -A sh -c '...'
```

Use the absolute path when handing the command to another session whose `HOME`
may differ. The helper is installed on atlas only: guard with
`[ -x "$HOME/.local/bin/sudo-askpass" ]` elsewhere.

## Verify

- `sudo -n true` exits non-zero with no ticket; never pipe it into `head`,
  which hides the status.
- Cancel must make sudo fail; a helper that exits 0 on cancel is broken.
- The dialog must show the command. If it only shows
  `[sudo] password for tenax:`, the wrong helper is in use.
