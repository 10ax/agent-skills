# pocock (bundle)

| | |
| --- | --- |
| Source | https://github.com/mattpocock/skills |
| Upstream commit | `a496f5513d4a4cf889bc48e189e579f4b0bdf6aa` (2026-10-29) |
| Licence | MIT, (c) 2026 Matt Pocock. See `LICENSE` in the source repo. |
| Installed | 2026-10-31 |

25 of the 27 promoted skills: the whole of `skills/engineering` and
`skills/productivity` minus the two listed under "Not here". Registered from
the `skills` array in `~/.config/opencode/opencode.json`, not by symlink, for
the same reason as `forks/cursor-plugins`: a nested bundle does not fit
`agent-skills/install.sh`, which only looks two levels deep.

## The upstream split, which is what keeps this cheap

Upstream marks 16 of the 27 `disable-model-invocation: true`. OpenCode reads
that key natively (see the pstack port), so those 16 stay loadable by id and out
of the session index; only 9 of the 25 here are advertised: `code-review`,
`codebase-design`, `diagnosing-bugs`, `domain-modeling`, `pr`, `prototype`,
`research`, `tdd`, `wizard`, `grilling`, `writing-for-agents`.
Nothing to add on our side.

## Changes

Exactly one, mechanical, across 8 files and 20 occurrences:

**`the Skill tool` → ``the `skill` tool``.** Upstream targets harnesses that ship
a tool literally named `Skill`; OpenCode's is `skill`, and several bodies do
nothing else but dispatch (`grill-me` is one line: "Call the Skill tool with
'grilling'"). Left unrenamed it reads as a tool call to something that does not
exist.

```bash
grep -rn "Skill tool" skills/ | wc -l   # 0
```

## Not here, on purpose

| Excluded | Why |
| --- | --- |
| `engineering/wayfinder` | already forked at `forks/wayfinder` for its two table rewrites; two skills with one id is a silent collision |
| `productivity/teach` | id collides with the hidden `teach` in the pstack bundle, which is a different thing: pstack's explains one change through `how` and `why`; upstream's is a multi-session teaching workspace |
| `*/agents/openai.yaml` | OpenAI-runtime metadata (display name, short description); nothing in OpenCode reads it |
| `skills/in-progress/*` | 7 unpublished skills upstream has not promoted |
| `skills/misc/*` | 3 one-offs tied to other repos (shoehorn migration, pre-commit setup, exercise scaffolding) |
| `skills/deprecated/*` | retired by upstream |

## One TDD, one id

Before this bundle arrived the machine had two: superpowers'
`test-driven-development`, advertised and loaded four times in the month before,
and a hidden `tdd` inside pstack. With a third one here that is three skills
answering "write the test first", two of them under the same id. The one that
stays is upstream's: it is the `tdd` that `implement` and `implement-spec` call
by name, and retiring the other two is recorded in
`forks/cursor-plugins/UPSTREAM.md`.

## Two skills conflict with the house rules

`grilling` (`grill-me`, `grill-with-docs`, `triage`, `wayfinder`) and
`to-questionnaire` all assume the interview happens **in chat**. The global
`AGENTS.md` requires every question to go through the `question` tool, batched,
recommended option first. The global rule wins: the skills still hold their
analysis discipline, but they may not end a turn with a prose question list.
Same conflict already existed for the removed `interview-me`.

## Updating

```bash
git clone --depth 1 https://github.com/mattpocock/skills.git /tmp/pocock
diff -r /tmp/pocock/skills/engineering skills/ | grep -v 'Skill tool'
```

Re-apply the rename to any file the diff touches, refresh the commit line above,
and re-check that upstream has not started shipping its own tables in `SKILL.md`
(the house style is no tables in skills; `forks/wayfinder/UPSTREAM.md` has the
long version of why that matters here).
