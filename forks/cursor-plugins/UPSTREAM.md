# cursor-plugins (forked for OpenCode)

| | |
| --- | --- |
| Source | https://github.com/cursor/plugins |
| Components | `pstack` (v0.15.25), `cursor-team-kit` |
| Upstream commit | `f713f14203cd6420cec13cd7c55c32d598dbab68` |
| Licence | MIT, (c) Cursor. `LICENSE` is kept in each component directory. |
| Author | Lauren Tan ([@poteto](https://x.com/poteto)) |

## Why this is a fork and not a pin

caveman next door is a pin: verbatim upstream, kept because it is deliberately an
older revision. This one is a genuine fork, because upstream is written for
Cursor and this machine runs OpenCode. The skill bodies survive the move almost
intact — OpenCode reads the same Agent Skills format and understands
`disable-model-invocation` natively — but the harness mechanics had to be
rewritten, which is a real patch.

The one structural change: **in Cursor a subagent's model is a spawn parameter,
so pstack carries a role-to-slug table and juggles slugs and effort tokens at
every spawn. In OpenCode the model belongs to the agent.** So a role became an
agent name, and the role table moved from a Cursor rule to a record of which
agent carries which model.

`HARNESS.md` is the companion document: every Cursor feature with no OpenCode
equivalent, and what to do instead. Read it before concluding an instruction here
is broken.

## What is not here

| Component | Why |
| --- | --- |
| `pstack/automations/benny` | A dormant Cursor automation pack. Excluded, with `docs/` and `assets/` |
| `pstack/skills/make-bot-ui` | Deleted. It targets Cursor's `api2.cursor.sh` automation webhook and is unusable without Cursor |
| 16 of cursor-team-kit's 18 skills | Only `thermo-nuclear-code-quality-review` and `deslop` are imported. The rest are CI, PR and shipping skills that duplicate what is already installed here |
| cursor-team-kit's `ci-watcher` agent | Same reason as the 16 skills |
| cursor-team-kit's `.mdc` rules | OpenCode has no rules mechanism. The two rules are generic TypeScript preferences |
| `pstack/skills/tdd` | Deleted on 2026-10-31, when `mattpocock/skills` arrived with a `tdd` of its own. One id cannot mean two things: upstream's is the model-invoked reference that `implement` and `implement-spec` call by name, so the id now points there. `poteto-help`'s table lost its row; the two playbooks that mention `/tdd` still resolve |

## The ported files

The live runtime pieces are **not** in this directory. They are harness config,
symlink-free, and live where OpenCode reads them:

| Piece | Path | Derived from |
| --- | --- | --- |
| Agents | `~/.config/opencode/agents/poteto-agent.md` | `pstack/agents/poteto-agent.md` |
| | `~/.config/opencode/agents/comment-sicko.md` | `pstack/agents/comment-sicko.md` |
| | `~/.config/opencode/agents/thermo-nuclear.md` | `cursor-team-kit/agents/thermo-nuclear-code-quality-review.md` |
| | `~/.config/opencode/agents/poteto-judge.md` | new: one agent per model family, so panels stay diverse |
| | `~/.config/opencode/agents/poteto-reviewer.md` | new, as above |
| Commands | `~/.config/opencode/commands/<skill-id>.md` | one thin loader per skill, generated |
| Role map | `~/.config/opencode/pstack-models.md` | `pstack/skills/setup-pstack` |

The agent bodies under this directory are **pristine upstream**, kept beside the
skills so the diff stays reviewable. The adapted versions are the live files
above. That is deliberate: a half-adapted copy in two places would drift.

## Changes to the skill trees

43 files changed under `pstack/skills`, 2 under `cursor-team-kit/skills`, 1
deleted. Grouped by what the change does:

### 1. Model selection: per spawn becomes per agent

Files: `poteto-mode/SKILL.md`, `setup-pstack/SKILL.md`, `how`, `why`, `interrogate`,
`arena`, `architect`, `swarm`, `reflect`, `no-comments`, `recall`,
`show-me-your-work`, `poteto-help/SKILL.md`, and the playbooks
`feature`, `refactoring`, `bug-fix`, `perf-issue`, `hillclimb`, `multi-phase-plan`,
`eval`, `autonomous-run`, `orchestrate`, `worktree-cleanup`, `runtime-forensics`,
`trace-forensics`, `session-pickup`, `autoplay-full`, `shipping`, `opening-a-pr`,
`authoring-a-skill`.

- `Set model to that line's value …` becomes a statement that the role's agent
  carries the model.
- Slugs become agent names: `grok-4.7-xhigh-fast` becomes `poteto-agent` (or
  `poteto-reviewer`, where the seat is read-only) and `claude-opus-5-5-xhigh`
  becomes `poteto-judge`.
- `~/.cursor/rules/pstack-models.mdc` becomes `~/.config/opencode/pstack-models.md`.
- The `inherit-parent` and `auto` aliases are gone: they existed to run a role on
  the parent's model, which in OpenCode is simply an agent with no `model:` line
  (only `comment-sicko` uses that today).
- `Pick each subagent's reasoning level and fast or standard speed` (18 files)
  becomes `Pick the agent for the role`. Effort is a `#variant` on the agent's
  model and cannot be varied per spawn.
- `setup-pstack` is rewritten: it now detects models, confirms a budget, writes
  the agent `model:` lines and `pstack-models.md`, and validates that each role
  has an agent.

### 2. Transcripts

Cursor writes one JSONL transcript per chat under
`~/.cursor/projects/<slug>/agent-transcripts/`. OpenCode keeps sessions in its
service database. Files: `recall`, `reflect`, `show-me-your-work`, `automate-me`,
`eval`, `session-pickup`, and `poteto-mode/scripts/worktree-audit.sh`.

All of them now read the markdown mirror that `second-brain-transcripts.sh`
writes at `~/Documents/SecondBrain/900-Archivio/transcripts/opencode/`, scoped to
a workspace by its `cartella:` frontmatter field rather than by directory. The
"do not cross workspace boundaries" guard is preserved, restated against the
mirror. `opencode session export <id>` is named as the raw record.

### 3. Cursor-only mechanics, dropped or redirected

| Upstream | Now |
| --- | --- |
| `Task` tool, `subagent_type`, `readonly: true\|false`, `run_in_background: true` | The `subagent` tool, `agent: "<name>"`, an edit-denied agent, `background: true` |
| `AskQuestion` | The question tool, in verb form |
| `environment: "cloud"` and cloud agents | Removed. Every subagent is local |
| `/loop` | Removed where it was a mechanism. A recurring wake, pointed at `HARNESS.md` |
| Custom Modes and opt/alt+enter | Removed. Start each task with `/poteto-mode` |
| `create-skill` (a Cursor built-in) | `writing-skills` |
| The `mcps/` directory Cursor writes | `opencode mcp list` or the `mcp.servers` block |
| `control-cli` and `control-ui` | The `browser` agent, or `ydotool`/`wtype` for a desktop GUI |
| `.cursor/skills/` | `.opencode/skills/` |
| `cursor.com/docs/skills` | `opencode.ai/v2/docs/skills` |
| `agent-transcripts/` code fences | A mirror-scoped `rg -l` on the `cartella:` field |

### 4. `worktree-audit.sh`

Bash, and the only script in the tree that got a real port. The transcript scan
moved to the mirror, and two BSD-isms became GNU because atlas is Linux:
`stat -f '%m %N'` to `stat -c '%Y %n'`, and `date -r <epoch>` to `date -d @<epoch>`.
Its `LAST_CHAT` column is approximate: the mirror is scoped by frontmatter, not by
directory, so a path match can span sessions from other projects.

### 5. Deletions

`pstack/skills/make-bot-ui` is gone, because it drives Cursor's `api2.cursor.sh`
automation webhook and nothing it describes can work here.

### 6. Frontmatter names

`poteto-mode/SKILL.md` kept upstream's `name: Poteto Mode` even though every other
skill in this tree names itself with its directory, which is the id OpenCode
resolves a skill by. The field now reads `poteto-mode` like all the others.

### 7. Not changed, deliberately

- **`pstack/skills/typescript-best-practices/`** and the other skills with no
  harness coupling are byte-identical. They were not opened.
- **`pstack/skills/poteto-mode/scripts/watch-pr/` and `scripts/orch/`** are
  unported TypeScript with a `bun.lock`, including a package name that says
  `@cursor-skill/...`. The built entry point the playbooks call is not committed
  upstream either. Left alone rather than half-translated.
- **`pstack/README.md`** and **`cursor-team-kit/README.md`** are upstream's,
  unedited apart from a note at the top. They describe the Cursor plugin, which
  is the honest thing for a vendored README to do.

## Re-check

On any upstream release:

1. Diff `pstack/skills` against this directory to see whether upstream changed a
   file this fork also changed. Those are the conflicts.
2. If upstream drops `disable-model-invocation` or OpenCode gains per-spawn model
   selection, the whole of group 1 above becomes unnecessary and this fork shrinks
   back toward a pin.
3. If upstream starts publishing a built `scripts/` tree, port group 6.
4. `poteto-help/SKILL.md` is the map of pstack's own surface. It is the first file
   to read after a bump, and the one most likely to need the Cursor-to-OpenCode
   translation again.
