---
name: editing-skills-here
description: Use when adding, editing, hiding or deleting an agent skill on atlas, when a skill stopped appearing in the skill list, when an edit was reverted after `npx skills update`, when a SKILL.md frontmatter silently stopped parsing, or when the always-on skill index needs measuring or trimming.
---

# Editing skills on atlas

Five sources own skills on this machine, and the source decides whether an edit
survives; an edit that stops parsing deletes a skill silently.

## When to use

- Adding or changing a skill, or undoing what `npx skills update` restored
- A skill stopped showing up in the list
- The preamble feels fat and you want to know which skills actually load

**When not to use:** writing the content — that is `~/Personal/code/agent-skills/AGENTS.md`.

## Where it lives decides whether the edit survives

| Path | An edit there survives |
| --- | --- |
| `~/Personal/code/agent-skills/skills/<id>`, symlinked in | anything — your own skills belong here |
| symlink in `~/.config/opencode/skills` | yes; a restore clones that repo and relinks |
| real dir in `~/.config/opencode/skills` | until the next manual reinstall: `collect.sh` excludes `skills/`, so a restore loses it |
| a directory registered from the `skills` array in `opencode.json` (`forks/pocock`, `forks/cursor-plugins`, the homelab repo) | yes, and it is not a symlink: edit the file where it lives in that repo, then commit it there. `install.sh` does not link it — the array is the registration |
| `~/.agents/skills/<id>` | nothing, and `npx skills update` does not even try: the directory is restored from `lib/agents-skills.tsv` in ~/dotfiles by `bin/restore-agents-skills.sh`, and `~/.agents/.skill-lock.json` was deleted on 2026-10-31 so the CLI has no keys to walk. `npx skills add` is the way back in, and it installs the whole pack |

Provenance for `~/.config/opencode/skills` is in
`~/dotfiles/hosts/atlas/opencode/skills.txt`, from `SKILL_SOURCES` in `lib/manifest.sh`;
a real directory missing from that list is recorded as `unknown` there.

## Stopping a skill from being advertised

| Mechanism | Survives an update | Loadable as `@id` |
| --- | --- | --- |
| `{"action":"skill","resource":"<id>","effect":"deny"}` in `opencode.json` | yes | no |
| `disable-model-invocation: true` in the SKILL.md frontmatter (OpenCode reads it; `metadata: {opencode/autoinvoke: false}` is the older spelling) | yes in a file you own or a fork; never in `~/.agents/skills` | yes |
| delete it, and its `SKILL_SOURCES` line | yes | no |

The flag is what the bundles use: 53 of the 54 skills in `forks/cursor-plugins` and
16 of the 25 in `forks/pocock` are hidden that way, and it costs nothing because a
fork is a file you own. The permission below is for third-party skills you do not
own and cannot edit; the `permissions` array is **empty since 2026-10-31**, when the
last rule left with the skill it named. Rules run in order and the last match wins,
so a broad `allow` must come first, and agent-level rules are applied after global ones.

## Verify the frontmatter after any edit

An unquoted `description:` containing `: ` is invalid YAML, and the skill then vanishes
from every list with nothing logged. Five Claude built-ins went that way on 2026-10-15,
surfacing only as "no longer available".

**REQUIRED: run a parser, never the eye.**

```sh
python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]).read().split('---')[1]))" <id>/SKILL.md
```

## What it costs, and what actually fires

Descriptions are advertised in every session and every project: sixty-odd skills is
~19 KB, ~5k tokens, before the first word; bodies load only on a match. Which skills
have ever loaded:

```sh
sqlite3 "file:$HOME/.local/share/opencode/opencode.db?mode=ro" "
select json_extract(j.value,'\$.state.input.id') id, count(*)
from session_message sm, json_each(sm.data,'\$.content') j
where sm.type='assistant' and json_extract(j.value,'\$.name')='skill'
group by 1 order by 2 desc;"
```

Read a never-firing description before deleting it: a vague one never fires because
nothing matches it.

## Permanent rules, and where they do not work

| Where | Applies |
| --- | --- |
| `~/.config/opencode/AGENTS.md` | every session, every project |
| a project `AGENTS.md` | that directory down |
| the `instructions` array in `opencode.json` | **nothing** — v2.0.24 never loads it (0 of 131 payloads) |
| a memory note | only if `MEMORY.md` points at it |

## Red flags: stop

- You opened a SKILL.md in `~/.config/opencode/skills` that is not a symlink into
  `agent-skills`, and you are about to edit it
- You are about to save a `description:` you have not parsed
- You are about to hide a skill by editing its file
