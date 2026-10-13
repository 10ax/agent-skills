# caveman (pinned upstream revision)

| | |
| --- | --- |
| Source | https://github.com/JuliusBrussee/caveman — `skills/caveman/SKILL.md` |
| Upstream commit | `880114a42067d045b91dffe6a553f6ab2cc399ad` (2026-09-08) |
| Licence | Apache-2.0, (c) 2026 Julius Brussee. The repo is Apache-2.0 from 3.0.0 onward; the skill was MIT before that and upstream keeps `LICENSE-MIT` for the MIT parts. |
| Pinned copy | `SKILL.md`, byte-identical to upstream at that commit |

```bash
sha256sum SKILL.md   # 0bf09a0a9a017d004a81d4b693e5a2d830e1a28230a5885df773e1ed9c0571cc
```

## Why this is under `forks/` when nothing in it was changed

It is a **pin**, not a patch. The skill is upstream verbatim, and it is kept here because it is
deliberately not the upstream revision running on the Claude Code side of this machine.

The Claude Code side follows the caveman marketplace (`~/.claude/plugins/marketplaces/caveman`),
currently 3.2.0. That release restructured the skill into nine numbered rules and moved the `ultra`
and `wenyan` levels out into sibling skills (`ultracave`, `megacave`) selected by a hook that reports
`Caveman mode: <mode>`. The OpenCode harness has no equivalent hook, so the pre-restructure revision —
the one where every level lives in this single file — is what OpenCode loads. A later upstream revision
would silently drop the level table.

## Changes

None to the skill. The OpenCode integration is a real port and lives in `10ax/dotfiles` as harness
config, not here, because it is plugin wiring rather than a skill:

- `~/.config/opencode/plugins/caveman.ts` — V2 rewrite of upstream's `src/plugins/opencode/plugin.js`,
  whose V1 hook keys (`chat.message`, `experimental.chat.system.transform`) OpenCode 2 refuses to run.
  The port maps them to `ctx.session.hook("prompt" | "context", ...)`.
- `~/.config/opencode/commands/caveman.md` — the `/caveman` command.
- `~/.config/opencode/.caveman-active` — runtime flag holding the active level, recreated on the first
  level switch.

## Re-check

On any upstream release: if 4.x puts the levels back into one file, or OpenCode gains hook parity with
the caveman marketplace, this should track upstream and the pin can be deleted.
