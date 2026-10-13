---
name: gen4-ou
description: Use when playing, teambuilding, coaching, or analyzing replays for Pokemon Showdown [Gen 4] OU (DPP OU). Covers Gen 4 mechanics that differ from modern generations, the current post-sleep-ban metagame, and vetted teams. Load BEFORE giving any DPP OU advice — modern-generation instincts are wrong here in specific, game-losing ways.
---

# Gen 4 OU (DPP OU)

## Rule zero: do not reason from modern Pokémon knowledge

Gen 4 differs from Gen 6+ in ways that silently invalidate modern instincts. Every item in this
table has produced a wrong answer in real coaching. Check it before asserting anything.

| Trap | Modern assumption | Gen 4 reality |
|---|---|---|
| **Steel typing** | Steel is neutral to Dark and Ghost | Steel **resists Dark and Ghost**. Jirachi/Scizor/Bronzong/Metagross wall Pursuit and Shadow Ball. |
| **Psychic typing** | — | **Psychic resists Fighting** (0.5×). Latias/Starmie/Jirachi take Close Combat at half. |
| **Sturdy** | Survives a KO at 1 HP | **Only blocks OHKO moves** (Fissure etc.). Donphan dies from full HP like anything else. |
| **Choice lock** | Persists after the item is removed | Removing/negating the item (Knock Off, Trick) **restores free move selection**. |
| **Knock Off** | 65 BP, removes the item | **20 BP**, only makes the item *unusable*. |
| **Explosion** | 250 BP, no Defence drop | 250 BP **and halves the target's Defence**. Far stronger — hence its ubiquity. |
| **Critical hits** | 1.5× damage | **2× damage**, and they **ignore the attacker's negative stat stages** and screens. |
| **Wish** | Heals half the *wisher's* max HP | Heals half the **recipient's** max HP. |
| **Weather** | 5 turns from an ability | **Permanent** from Sand Stream/Snow Warning/Drizzle/Drought. |
| **Paralysis** | Speed ×0.5; Electrics immune | Speed **×0.25**; **Electric-types CAN be paralyzed**. |
| **Hidden Power** | Fixed 60 BP | **Variable 30–70 BP** from IVs; needs an explicit IV line. |
| **Team preview** | You see their six | **No team preview.** You go in blind. |

There is no Fairy type, no Mega Evolution, no Terastal. Gen 4 is where the physical/special split
was introduced, so moves are individually physical or special.

Full detail: `references/mechanics.md`.

## Before giving advice, verify these three things

1. **Type effectiveness** — check the actual Gen 4 chart, especially Steel and Psychic defensively.
2. **Whether the answer holds against *both* the physical and special variant** of a threat.
   "Gliscor checks Infernape" is true for Close Combat and false for Fire Blast — Gliscor has no
   special bulk. Name the *set*, not the species.
3. **Sample-team rosters** — fetch the pokepaste directly. Web-page summarizers hallucinate
   Pokémon into DPP teams (they have produced "Dialga" and "Mr. Mime" in OU). Pastes are the
   only trustworthy source.

## Current metagame (as of August 2026)

Two tiering actions define the tier. Both are recent enough that most written resources are stale:

- **Sleep banned — 5 January 2026** (22/36 council votes). Spore, Sleep Powder, Hypnosis, Sing,
  Yawn, Lovely Kiss, Grass Whistle are all illegal. **Rest and Sleep Talk remain legal** — the
  clause only covers opponent-targeting sleep.
- **Machamp banned — January 2025** (No Guard + Dynamic Punch).

The sleep ban is described in the metagame thread as the most impactful action since Salamence's.
It gutted Breloom (from a top-tier threat to ~4.5% usage) and pushed the tier hard toward
Clefable-centred balance and semi-stall.

**Anything written before January 2026 must be read with the sleep ban in mind** — including the
[Viability Rankings](https://www.smogon.com/forums/threads/dpp-ou-viability-ranking-updated-may-2025.3683332/),
which are from May 2025 and still rank Breloom A1.

Usage, current threats, and archetypes: `references/metagame.md`.

## Teams

Two maintained teams with full pastes, role breakdowns, and piloting rules: `references/teams.md`.

- **Team 1 — Double Ground Mag Balance** (crayon pop, SPL 11). Tournament-vetted. The default
  recommendation; its Hippowdon/Gliscor/Clefable/Latias backbone matches where the tier has moved.
- **Team 6 — Donphan + Magnezone Trap Balance**. A custom build, since corrected. Its history is
  instructive and is documented in that file.

## Coaching this player (FTenace)

Recurring errors observed across four games, in order of how much they cost:

1. **Does not use recovery moves.** In one 24-turn game they used *zero* — despite Slack Off,
   Roost, Soft-Boiled and Recover being on four of six members. Everything died to chip damage.
2. **Over-switches into hazards.** 17 voluntary switches in 41 turns with Rocks + Spikes down and
   no spinner; two Pokémon fainted on entry without being attacked.
3. **Does not check immunities before clicking.** Earthquake into Skarmory, Toxic into Jirachi.
   Showdown greys these with a `×` — point at it.
4. **Loses the Fighting-resist, then gets swept.** Three of three losses ended with Infernape or
   Lucario cleaning up 4+ Pokémon after Gliscor/Latias had been chipped to death.

They play **rated ladder** and have chosen to be coached live during rated games. That was flagged
once as ghosting; they reaffirmed. Do not re-litigate it — advise and move on.

## Live coaching protocol

- Read the battle log with `get_page_text` on the Showdown tab. Do not screenshot — the log is text.
- **Never click their moves.** Advise; they execute. Two people driving one mouse causes misclicks.
- Showdown's default timer is ~150s/turn. Lead with the call, then the reasoning — they may be
  reading under time pressure.
- Track revealed information explicitly: their six, items knocked off, hazard layers on each side,
  and what is already paralyzed or poisoned.
