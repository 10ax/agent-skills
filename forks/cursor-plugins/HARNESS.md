# What Cursor does that OpenCode does not

Upstream pstack and cursor-team-kit are written for Cursor. Most of the skill
bodies port unchanged, because OpenCode reads the same Agent Skills format and
understands `disable-model-invocation` natively. This file records the harness
features that have **no** OpenCode equivalent, so a skill that names one is not
mistaken for working behaviour.

Read it before concluding that a pstack instruction is broken.

## Where the live wiring is

| Piece | Path |
| --- | --- |
| Skill trees | this directory (`pstack/skills`, `cursor-team-kit/skills`), registered in `opencode.json`'s `skills` array |
| Agents | `~/.config/opencode/agents/{poteto-agent,poteto-judge,poteto-reviewer,comment-sicko,thermo-nuclear}.md` |
| Slash commands | `~/.config/opencode/commands/<skill-id>.md`, one per skill |
| Role to agent map | `~/.config/opencode/pstack-models.md` |

The agents are real files under `~/.config/opencode/agents/`, not symlinks into
this directory, because OpenCode needs `model` and `permissions` in frontmatter
and the upstream bodies have neither. Upstream's own agent files stay here beside
the skills for diff review.

## Features with no equivalent

| Cursor feature | In OpenCode | What to do instead |
| --- | --- | --- |
| Model chosen per spawn, with an effort level and a `-fast` speed token | The model belongs to the **agent**. There is no per-spawn model, and no speed token at all | Pick the agent for the role. Change a role's model by editing that agent's `model:` line, then update `pstack-models.md` |
| `readonly: true` on a spawn *, which strips MCP access | Read-only is an agent property (`edit` denied). MCP tools stay available | Spawn `poteto-judge` or `poteto-reviewer`, which are edit-denied |
| `run_in_background: true` | Same idea, `background: true` on the subagent tool | Works unchanged |
| Cloud agents, `environment: "cloud"`, cloud VMs per lane | None. Every subagent is a local child session on atlas | A worker that needs this machine is just a worker. Ignore lane-VM language |
| `/loop` (a built-in wake command) | None | Re-invoke the session, keep a background subagent running, or schedule `opencode run` from a systemd user timer |
| Custom Modes (`opt`/`alt`+enter) | None. A skill attaches to one message and fades | Start each task with `/poteto-mode`, or put what must survive into `AGENTS.md` |
| `~/.cursor/rules/pstack-models.mdc` with `alwaysApply: true` | No rules system, and the `instructions` array in `opencode.json` never loads on this build | `~/.config/opencode/pstack-models.md` is read by a skill when that skill needs it. It is **not** always in context |
| `create-skill` (a Cursor built-in) | The local skill-authoring skills | Use `writing-skills` or `skill-creator` |
| `agent-transcripts/<uuid>.jsonl` per workspace | OpenCode keeps sessions in its service database | `opencode session export <id>`, or the markdown mirror at `~/Documents/SecondBrain/900-Archivio/transcripts/opencode/`, scoped by its `cartella:` frontmatter field |
| The `mcps/` directory Cursor writes | None | `opencode mcp list`, or the `mcp.servers` block in `~/.config/opencode/opencode.json` |
| `control-ui` and `control-cli` (cursor-team-kit) | Not imported | Drive a browser with the `browser` agent. Drive a desktop GUI with `ydotool` or `wtype` through the shell tool. Build a CLI harness yourself if you need one |
| The rest of cursor-team-kit (CI, PR, review, ship skills) | Not imported | They overlap with skills already installed here. See `UPSTREAM.md` for the list |
| `make-bot-ui` | Deleted | It targets Cursor's `api2.cursor.sh` automation webhook. Unusable without Cursor |
| `automations/benny` | Not imported | A dormant Cursor automation pack. Excluded with `docs/` and `assets/` |
| `icon:` and `color:` skill frontmatter | Ignored and removed | Cosmetic, Cursor menu only |
| The cursor-team-kit `.mdc` rules | Not imported | No rules mechanism. `typescript-exhaustive-switch` and `no-inline-imports` are generic TypeScript preferences; put them in a project `AGENTS.md` if you want them |

## Known rough edges

- **`pstack/skills/poteto-mode/scripts/` is unported.** `watch-pr` and `orch` are
  TypeScript with a `bun.lock`, and the built entry point the playbooks call
  (`scripts/watch-pr/watch-pr`) is not committed. Building them is a `bun install`
  away, but nothing verifies that here. `worktree-audit.sh` is bash and was
  adjusted for Linux (GNU `stat -c`, `date -d`) and for the transcript mirror, so
  its `LAST_CHAT` column is approximate.
- **Reasoning-level tuning is gone.** Upstream raises and lowers effort per spawn.
  With the model on the agent, effort is fixed per agent, so a panel can only
  differ by family (`poteto-judge` against `poteto-reviewer`).
- **`/setup-pstack` writes agent models, not a rule.** Re-run it after editing an
  agent by hand, or the record in `pstack-models.md` goes stale.
- **Simulator guidance is macOS.** `worktree-cleanup` and the mobile lanes in
  `multi-phase-plan` assume `xcrun simctl` and Xcode paths. atlas is Linux.
