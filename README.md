# agent-skills

Private home for the agent skills I write, plus my modified forks of other people's.

A **skill** is a folder with a `SKILL.md` inside: YAML frontmatter (`name`, `description`) followed by
markdown instructions that get loaded into an agent's context when the description matches the task.
The format is cross-runtime and specified at <https://agentskills.io/specification>.

## Layout

| Path | Holds |
| --- | --- |
| `skills/<name>/SKILL.md` | Skills I wrote. One folder per skill, flat namespace, no nesting by category. |
| `forks/<name>/SKILL.md` | Third-party skills I have modified. Each carries an `UPSTREAM.md` recording the source, its licence, and what I changed. |
| `templates/SKILL.md` | Skeleton for a new skill. Copy it, do not start from blank. |
| `AGENTS.md` | Authoring conventions. Read before writing or editing a skill in here. |
| `install.sh` | Symlinks every skill into the runtime's skills directory. |

Supporting files (heavy reference, scripts, examples) live beside the `SKILL.md` that uses them.
Anything over ~100 lines that is reference material belongs in its own file, linked from `SKILL.md`
rather than inlined, so it only costs context when it is actually needed.

## Install

```bash
./install.sh              # symlink into ~/.claude/skills (Claude Code)
./install.sh ~/.agents/skills   # or the cross-runtime alias Codex/Copilot/Gemini also read
```

Symlinks, not copies: edit a skill in this repo and the change is live in the next session with no
reinstall step. This deliberately differs from how `10ax/dotfiles` works (collect-and-install there),
because skills are edited far more often than dotfiles and the copy step is pure friction.

Run `./install.sh --list` to see what is linked and what is stale.

## Where skills come from

Two upstream sets worth reading before writing anything, both MIT:

- [`obra/superpowers`](https://github.com/obra/superpowers) (vendored into Claude Code as the
  `superpowers` plugin) for the authoring methodology: baseline the failure first, then write the
  guidance that fixes it. `AGENTS.md` distils the parts I follow.
- [`mattpocock/skills`](https://github.com/mattpocock/skills) for a prose-first house style and for
  workflow skills that persist their state outside the context window.
