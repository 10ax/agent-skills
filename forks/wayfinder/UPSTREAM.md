# wayfinder (fork)

| | |
| --- | --- |
| Source | https://github.com/mattpocock/skills/blob/main/skills/engineering/wayfinder/SKILL.md |
| Upstream commit | `321658273cb1d20b76026717d027d505790106d4` (2026-08-19T10:03:37Z) |
| Licence | MIT, (c) Matt Pocock. See LICENSE at the repo root of the source. |
| Pristine copy | `SKILL.upstream.md`, kept verbatim so the fork diff stays readable |

Diff the fork against the pristine copy at any time:

```bash
diff -u SKILL.upstream.md SKILL.md
```

## Changes

**Added a `## Quick reference` section** after the intro, before `## Plan, don't do`. Two tables:
the judgement calls (ticket vs fog vs out of scope, which of the four ticket types, what to do when
charting surfaces no fog, what the pull to start building means) and the invariants that hold every
session (one ticket per session, claim before work, refer by name, decisions not deliverables, the
map gists and links, create-then-wire, never answer the human's side of a HITL ticket, load low-res
then zoom).

Every row is a gist plus a link to the section that holds the detail, which is the skill's own
"the map is an index, not a store" principle applied to itself. The section opens by saying it does
not replace reading the prose.

**Why:** upstream is 2000 words of prose with nothing scannable, so an agent mid-session has to read
all of it to recover the operational rules. The fork is 2447 words, so this trades 22% more total
length for a skeleton readable in the first 450.

## Not sent upstream

Deliberately kept local. No skill in `mattpocock/skills` contains a markdown table, and the repo has
a changeset removing em dashes repo-wide, so prose-first looks like a considered house style rather
than an oversight. A table-shaped patch would likely be rejected on style grounds even if the content
is right.

## Untested

The patch has not been baseline-tested: no scenario was run with and without the quick reference to
see whether an agent actually behaves differently. It is additive reference formatting, which is the
weakest case for that discipline, but the honest position is that this is doctrine rather than
measurement. Re-check on any upstream change to the sections the table links to, since a heading
rename silently breaks the anchors.
