---
name: editing-skills-here
description: Use when adding, editing, hiding or deleting an agent skill on atlas, when a skill stopped appearing in the skill list, when an edit was reverted after `npx skills update`, when a SKILL.md frontmatter silently stopped parsing, or when the always-on skill index needs measuring or trimming.
---

# Editing skills on atlas

Four sources own skills on this machine, and the source decides whether an edit
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
| `~/.agents/skills/<id>` | nothing. `npx skills update` rewrites the file; remove the `~/.agents/.skill-lock.json` entry too or it returns |

Provenance for `~/.config/opencode/skills` is in
`~/dotfiles/hosts/atlas/opencode/skills.txt`, from `SKILL_SOURCES` in `lib/manifest.sh`;
a real directory missing from that list is recorded as `unknown` there.

## Stopping a skill from being advertised

| Mechanism | Survives an update | Loadable as `@id` |
| --- | --- | --- |
| `{"action":"skill","resource":"<id>","effect":"deny"}` in `opencode.json` | yes | no |
| `metadata: {opencode/autoinvoke: false}` in the SKILL.md | only in a skill you own | yes |
| delete it, and its `SKILL_SOURCES` line | yes | no |

Prefer the permission: dotfiles tracks it, it never touches a file an updater owns, and
deleting the rules undoes it. Rules run in order and the last match wins, so a broad
`allow` must come first, and agent-level rules are applied after global ones.

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
