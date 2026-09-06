# Authoring conventions

Read this before writing or editing any skill in this repo.

## The frontmatter is the whole discovery mechanism

```yaml
---
name: skill-name-in-hyphens
description: Use when <triggering conditions and symptoms>
---
```

Only `name` and `description` are required, and the block caps at 1024 characters. `name` takes
letters, numbers and hyphens only. Name by what the skill *does*, verb-first: `condition-based-waiting`
beats `async-test-helpers`; gerunds work well for processes.

**The description states when to reach for the skill, never what the skill does.** This is the rule
most easily got wrong and the one with the sharpest cost. A description that summarises the workflow
becomes a shortcut the agent takes *instead of* reading the body, and it will then perform the
summary rather than the skill. Put triggers, symptoms, error strings and synonyms in there so the
description is greppable; put the process in the body where it belongs.

```yaml
# wrong: summarises the workflow, so the body becomes optional
description: Use when executing plans - dispatch a subagent per task with review between tasks

# right: triggering conditions only
description: Use when executing implementation plans with independent tasks in the current session
```

## Write against an observed failure, not an imagined one

The rule worth keeping from superpowers: **if you did not watch an agent fail without the skill, you
do not know whether the skill teaches the right thing.** Before writing guidance, run the scenario
without it and record the actual behaviour, verbatim. That record is what the skill answers.

Then match the form to the failure, because the form that fixes one kind measurably backfires on another:

| The failure | The form that fixes it |
| --- | --- |
| Knows the rule, skips it under pressure | Prohibition, plus a table of the exact rationalisations, plus red flags to self-check against |
| Complies, but the output has the wrong shape | A positive recipe: state what the output *is*, its parts, in order. Not a list of don'ts. |
| Omits a required element from something it already produces | Structural: a REQUIRED slot in the template it fills in |
| Behaviour should depend on a condition | A conditional keyed to something observable, not an unconditional rule with exemptions |

No nuance clauses. "Don't do X unless it matters" reopens the negotiation and measurably degrades a
rule that otherwise held. Express a real exception as its own conditional on an observable predicate.

## Every skill is skimmable

A skill is read by an agent that is mid-task and under pressure. If the operational rules can only be
recovered by reading every paragraph, the skill is too dense, however well written the paragraphs are.
Anything past roughly 1000 words carries a `## Quick reference` near the top: the judgement calls in
one table, the invariants in another, each row a gist plus a link to the section holding the detail.

The quick reference is an index, not a replacement. Say so in the section itself, and keep every row
short enough that it cannot be mistaken for the rule in full.

## Keep it cheap

Frequently-loaded skills want to be under 200 words; everything else under 500 where the subject
allows. Cross-reference rather than restate (`**REQUIRED BACKGROUND:** use <skill-name>`), and never
use `@path` links, which force-load the file and burn the context you were trying to save. Point at
`--help` instead of documenting every flag. One excellent example beats the same pattern in five
languages.

## Flowcharts

Only for a decision where the agent might genuinely go wrong, or a loop it might exit too early.
Never for reference material (use a table), linear instructions (use a numbered list), or code
(use a code block). Labels carry meaning: no `step1`, `helper2`.

## Forks

A skill under `forks/` is someone else's work. Match the upstream house style rather than mine, even
where I would write it differently, so the diff stays reviewable and a patch can be sent back. Record
the source commit, the licence and every change in that fork's `UPSTREAM.md`. Check the upstream
conventions before editing: `mattpocock/skills`, for instance, uses no em dashes anywhere and no
markdown tables in any skill.

## Definition of done

- [ ] Failure observed without the skill, and recorded
- [ ] `name` is hyphenated, lowercase, verb-first
- [ ] `description` gives triggers only, in the third person, with no workflow summary
- [ ] Guidance form matches the failure type
- [ ] `## Quick reference` present if the skill is over ~1000 words
- [ ] Re-run the scenario with the skill: does the agent now comply?
- [ ] New rationalisations found in that run are answered explicitly
- [ ] No narrative storytelling ("in one session I found...")
