# wayfinder (fork)

| | |
| --- | --- |
| Source | https://github.com/mattpocock/skills/blob/main/skills/engineering/wayfinder/SKILL.md |
| Upstream commit | `321658273cb1d20b76026717d027d505790106d4` (2026-08-19) |
| Licence | MIT, (c) Matt Pocock. See LICENSE at the root of the source repo. |
| Pristine copy | `SKILL.upstream.md`, kept verbatim so the fork diff stays readable |

```bash
diff -u SKILL.upstream.md SKILL.md
```

## Changes

Two branch-points converted from prose bullets into tables, in place. Nothing added, nothing
summarised, no new section. 2000 to 2070 words.

**`## Ticket Types`**: the four prose bullets become a `Type | Mode | Reach for it when | Resolved by`
table. Shape lifted from upstream's own docs page for this skill, which already presents the four
types exactly this way, so it is the author's own choice of form.

**`## Fog of war`**: the two `Ticket when` / `Not yet specified when` bullets become a three-row
table, re-axed onto scope first and sharpness second. The bullets tested sharpness only, so work
sitting beyond the destination that you also cannot phrase sharply matched "not sharp yet" and landed
in the fog. The section on out of scope says the opposite: "Fog only ever gathers _toward_ the
destination" and "Scope, not sharpness, lands it here". The lead sentence now says to check scope
first, and the table's first row is the out-of-scope case.

**Why:** the two places a reader actually branches were paragraphs, and upstream's own
`.agents/writing-docs.md` says "Branches go in a table or a list, never in a paragraph."

## The approach that was tried first and rejected

A standalone `## Quick reference` section near the top of the file: two tables gisting the judgement
calls and the session invariants, each row linking to the section holding the detail. Reviewed and
thrown out. Kept here because the failure is instructive.

- **It amplified the skill's most-reported failure.** The upstream docs page records "my agent
  started writing production code in the middle of a wayfinder session" as the top field failure, with
  a real hole behind it: the "plan, don't do" default can be overridden in the map's Notes, but the
  Notes are written by the agent, so the constraint and its exemption live in the same file the
  constrained party owns. The summary row ended on that exemption as a trailing "unless" clause, in
  the first scannable block of the file. The `task` row dropped the "earns its place by unblocking a
  decision, not by delivering the destination" guardrail, which is the remediation that same page
  prescribes. Both rows kept the permissive half of their sentence.
- **A summary is a shortcut, and a disclaimer does not close it.** superpowers' `writing-skills`
  documents the trap one level up: a description that summarises the workflow gets followed *instead
  of* the body. "Nothing here replaces reading them" is itself a nuance clause, is unobservable, and
  is least likely to hold in the one situation the section was written for, an agent under pressure.
- **~380 words of restated meaning.** Upstream's `writing-for-agents` names duplication directly:
  "Keep each meaning in a single source of truth… Duplication costs maintenance and tokens, and
  inflates a meaning's prominence on the ladder past its real rank." The section also displaced
  `## Plan, don't do`, the rule the docs page says agents break most often, from first position.

Tables in place have none of these properties: the table *is* the section, so there is no second
copy to drift, nothing ranked above the rules, and nothing an agent can read instead of the skill.

## On sending this upstream

An earlier note here claimed a table-shaped patch would be rejected on style grounds, because no
`SKILL.md` in that repo contains a table. That was the wrong read. Checked across all 25 promoted
skills: zero tables in `SKILL.md` files, but tables are used in `docs/` pages (where `writing-docs.md`
mandates them for branches) and in disclosed reference files inside promoted skills
(`ask-matt/PHASE-BOUNDARIES.md`, `setup-matt-pocock-skills/triage-labels.md`). The form is house
sanctioned; what is absent from skills is a *summary section*, which is what the rejected approach
built. So this version is plausibly PR-able. It would need a changeset, since `.changeset/` is that
repo's release mechanism.

## Untested

No scenario was run with and without the tables. The in-place form cannot introduce a shortcut or
restate a rule, which is why it was chosen over a summary section, but that is reasoning, not
measurement. Re-check on any upstream edit to `## Ticket Types` or `## Fog of war`.
