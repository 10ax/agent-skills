---
name: reflect
description: Spawn three parallel review subagents over the active transcript, surface learnings, and route each to a concrete edit on an existing skill. Use when the user says reflect.
disable-model-invocation: true
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits.

Invoke when the user says "reflect" or "/reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## 1. Locate the active transcript

Before fanning out, find this conversation's transcript in the markdown mirror at `~/Documents/SecondBrain/900-Archivio/transcripts/opencode/`, scoped by its `cartella:` frontmatter field. Do not glob across the whole mirror: that crosses workspace boundaries and reads private chats from unrelated projects.

```bash
rg -l '^cartella: <workspace>' ~/Documents/SecondBrain/900-Archivio/transcripts/opencode/*.md | xargs ls -t 2>/dev/null | head -10
```

That covers the legacy flat (`<id>.jsonl`), current nested (`<id>/<id>.jsonl`), and subagent (`<parent>/subagents/<child>.jsonl`) layouts. For each candidate, read the first JSONL line. Take the file whose `message.content[0].text` contains the conversation's opening user prompt. If none matches, pass a tight digest of the session instead.

## 2. Spawn three reviewers in parallel

One message, three `subagent` calls, one each on `poteto-reviewer` and `poteto-judge` for the `reflect tooling`, `reflect judgment`, and `reflect divergent` roles. Reviewers need MCP access to look up the tickets, chat threads, and observability traces the transcript references, and an edit-denied subagent keeps its MCP tools.

Each reviewer and the synthesizer name a role carried by an agent. In OpenCode the model is an agent property, so a role's model is chosen by picking its agent, never by setting `model` on a spawn. `~/.config/opencode/pstack-models.md` records the mapping.

| Lens | Role line | Default agent | Prompt template |
|---|---|---|---|
| Judgment | `reflect judgment, divergent, synthesizer` | `poteto-judge` | `references/judgment-reviewer.md` |
| Tooling | `reflect tooling` | `poteto-reviewer` | `references/tooling-reviewer.md` |
| Divergent | `reflect judgment, divergent, synthesizer` | `poteto-judge` | `references/divergent-reviewer.md` |

Pass each template verbatim, substituting the transcript path or digest where marked. Reviewers return findings in the `subagent` response body.

## 3. Synthesize

One `subagent` call on `poteto-judge`, the agent for the `reflect judgment, divergent, synthesizer` role. It spot-verifies citations through MCP, and an edit-denied subagent keeps its MCP tools. Pass `references/synthesizer.md` verbatim, with each reviewer's full output inlined where marked. It returns an Accepted / Rejected / Backlog list.

## 4. Structural enforcement check

Move any Accepted item that a lint rule, script, metadata flag, or runtime check would enforce more reliably to Backlog. See the **encode-lessons-in-structure** principle skill.

## 5. Apply

Present the synthesizer's full Accepted / Rejected / Backlog output and wait for explicit approval before applying any Accepted edit. The user picks the subset and may redirect routings. Skill changes affect every future agent in the org. Do not auto-apply.

File each Backlog item to your team's devex or backlog tracker without waiting. Only the Accepted list waits for approval.

Follow each approved row's Routing exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): the parent does it directly.
- Substantive existing-skill edit (a new section, a new pattern table, more than ~10 lines): hand to the local `writing-skills` skill and run its draft / test / iterate loop.
- `tune description: <skill path>` (the skill exists but didn't trigger when it should have): hand to `writing-skills` and run its description-optimization loop.
- `new skill via writing-skills: <kebab-name>`: hand creation to `writing-skills`. Do not invent the shape ad hoc.

If your environment ships a SKILL.md validator, run it on every touched skill before declaring done.

## 6. Summarize for the user

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog filed to the devex tracker: `<issue title>` (`<tags>`). One line each.
- Dropped: one line per rejected finding + reason from the synthesizer.
