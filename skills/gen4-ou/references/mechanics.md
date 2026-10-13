# Gen 4 (DPP) mechanics reference

Verified against Bulbapedia and Smogon, August 2026. Every entry here differs from at least one
later generation, or is a common source of error.

## Type chart

Gen 4 has **17 types** — no Fairy. The chart is identical to Gen 2–5. Two matchups changed in
Gen 6, and both matter enormously in DPP:

- **Dark → Steel: 0.5×** (became 1× in Gen 6)
- **Ghost → Steel: 0.5×** (became 1× in Gen 6)

### Steel's full defensive profile (Gen 4)

Resists (0.5×): **Normal, Flying, Rock, Bug, Steel, Grass, Psychic, Ice, Dragon, Dark, Ghost**
Immune (0×): **Poison**
Weak (2×): Fire, Fighting, Ground

This is why Jirachi, Scizor, Metagross and Bronzong are so central: they wall Pursuit, Shadow Ball,
Draco Meteor and Ice Beam simultaneously.

### Defensive matchups that are routinely misremembered

| Defender | Attacker | Multiplier |
|---|---|---|
| Psychic | Fighting | **0.5×** |
| Steel | Dark, Ghost | **0.5×** |
| Ghost | Normal, Fighting | **0×** |
| Dark | Psychic | **0×** |
| Ground | Electric | **0×** |
| Flying | Ground | **0×** |
| Dragon | Fire, Water, Grass, Electric | 0.5× |

Worked examples for common DPP Pokémon:

- **Latias** (Dragon/Psychic) resists Fire, Water, Grass, Electric, **Fighting**. Weak to Ice,
  Dragon, Bug, Ghost, Dark. → resists everything mixed Infernape has except U-turn.
- **Gliscor** (Ground/Flying) resists Fighting (0.5×), Bug (0.25×); immune to Ground and Electric;
  **4× weak to Ice**; takes 2× Stealth Rock.
- **Tyranitar** (Rock/Dark) is **4× weak to Fighting**, immune to Psychic.
- **Magneton/Magnezone** (Electric/Steel) is **4× weak to Ground**, 2× to Fire/Fighting.
- **Rotom formes** (Electric/**Ghost** in Gen 4 — the Water/Fire/etc. typings arrived in Gen 5)
  are immune to Normal, Fighting and (via Levitate) Ground.

## Physical/special split

Introduced in Gen 4. Moves are individually physical or special rather than determined by type.
This is why Gen 3 knowledge does not transfer, and why sets like mixed Infernape (physical Close
Combat + special Fire Blast) exist.

## Abilities

| Ability | Gen 4 behaviour |
|---|---|
| **Sturdy** | Blocks **only** OHKO moves (Fissure, Horn Drill, Sheer Cold, Guillotine). No survive-at-1-HP — that arrived in Gen 5. |
| **Sand Stream / Snow Warning / Drizzle / Drought** | Weather is **permanent** until replaced. Gen 6 cut it to 5 turns. |
| **Magnet Pull** | Traps Steel-types (blocks voluntary switching). Does **not** stop Roar/Whirlwind phazing, U-turn, or Baton Pass. |
| **Levitate** | Immune to Ground moves, **Spikes**, **Toxic Spikes**, Arena Trap. **Not** immune to Stealth Rock. |
| **Magic Guard** | Immune to all indirect damage: hazards, weather, poison, burn, Life Orb recoil, confusion. Clefable's defining trait. |
| **Serene Grace** | Doubles secondary-effect chances. Jirachi's Iron Head = 60% flinch; Body Slam = 60% paralysis. |
| **Natural Cure** | Cures status on switch out (Starmie, Blissey, Celebi). |
| **Solid Rock / Filter** | Super-effective damage ×0.75. |
| **Intimidate** | −1 Attack on switch-in (Gyarados). |
| **Flash Fire** | Fire immunity + 1.5× own Fire moves (Heatran). |
| **Pressure** | Doubles the opponent's PP consumption. |

**Banned abilities in DPP OU:** Arena Trap, Sand Veil, Snow Cloak.

## Weather

- **Sandstorm**: 1/16 max HP per turn to everything except Rock, Ground and Steel types.
  Also gives **Rock-types a 1.5× Special Defence boost**.
- Permanent from Sand Stream. In practice most DPP games are played in sand — build accordingly.
- Magic Guard ignores the chip entirely.

## Status conditions

| Status | Gen 4 behaviour |
|---|---|
| **Paralysis** | Speed drops to **25%** (Gen 7 changed this to 50%). 25% chance per turn of full paralysis. |
| **Thunder Wave** | Does not affect **Ground**-types (Electric immunity). **Electric-types CAN be paralyzed** — the Electric immunity to paralysis arrived in Gen 6. Thunder Wave hits Zapdos, Rotom, Magnezone, Jolteon. |
| **Body Slam** | Normal-type, so it **paralyzes Ground-types** that Thunder Wave cannot touch. This is why Jirachi runs Body Slam. |
| **Burn** | Halves Attack; 1/8 max HP per turn. |
| **Poison / Toxic** | Regular poison 1/8 per turn. Toxic increments 1/16, 2/16, 3/16… and **resets when the Pokémon switches out**. |
| **Rest** | **Legal** under Sleep Moves Clause (self-targeting). Sleeps 2 turns, full heal. RestTalk sets still function. |
| **Freeze** | 20% thaw chance per turn. Freeze Clause Mod: only one foe frozen at a time. |

## Critical hits

- Base rate **1/16** (6.25%).
- **2× damage** (Gen 6 reduced this to 1.5×).
- A crit **ignores the attacker's negative stat stages, the defender's positive stat stages, and
  Reflect/Light Screen.**

That last clause is a real DPP trap: a Latias at −4 Sp. Atk from repeated Draco Meteor still hits
at full power on a crit. Repeatedly clicking Draco Meteor is not "safe because it's weakened."

## Move mechanics

### Items and Choice

- **Knock Off** — **20 BP**. Makes the target's item *unusable*; the item is not removed and
  remains visible. The target then **cannot gain or lose an item** for the rest of the battle
  (Trick, Thief and Covet all fail against it).
- **Choice lock** — tied to *holding a usable Choice item*. If Knock Off or Trick negates it, the
  Pokémon **regains free move selection**. The "lock persists after negation" glitch exists only
  in Gens 5–7, not Gen 4. Confirmed in play: a Scarf Tyranitar switched from Pursuit to Superpower
  the turn after its Scarf was knocked off.

### Damage moves with Gen 4-specific behaviour

- **Explosion (250 BP) / Self-Destruct (200 BP)** — **halve the target's Defence** during damage
  calculation. Removed in Gen 5. This makes Gen 4 Explosion roughly twice as strong as later
  versions and explains why it appears on so many DPP sets (Metagross, Gengar, Azelf, Bronzong).
- **Pursuit** — 40 BP; **doubles to 80 and strikes before the switch** if the target flees.
  Super effective on Psychic and Ghost. The single biggest constraint on Latias, Gengar and
  Starmie. If a Pursuit user is on the field, those Pokémon cannot switch out safely.
- **Hidden Power** — **variable 30–70 BP**, type and power both derived from IVs. Fixed at 60 from
  Gen 6. Requires an explicit IV line in the paste. Verified 70-BP spreads:
  - **HP Ice**: `IVs: 2 Atk / 30 Def` (31 elsewhere)
  - **HP Fire**: `IVs: 30 Def / 30 SpA / 30 Spe`, or `IVs: 2 Atk / 30 SpA / 30 Spe` when you also
    want minimum Attack
- **Draco Meteor / Overheat / Leaf Storm** — −2 Sp. Atk after use. See the crit caveat above.
- **Wish** — heals **half the recipient's maximum HP** in Gen 4. Gen 5 changed it to the *user's*
  max HP. So Jirachi's Wish onto a bulky recipient heals more than Jirachi's own half.
- **Taunt** — lasts **3–5 turns (random)** in Gen 4. Gen 5 made it deterministic.
- **Rapid Spin** — 20 BP; clears Stealth Rock, Spikes, Toxic Spikes and Leech Seed from the user's
  side. **Blocked entirely by Ghost-types** (spinblocking).
- **Roar / Whirlwind** — negative priority; force a switch and **erase the target's stat boosts**.
  The correct answer to a Swords Dance or Dragon Dance in front of a wall. Fail against Suction
  Cups and Ingrain.

### Entry hazards

| Hazard | Damage | Who is exempt |
|---|---|---|
| **Stealth Rock** | 12.5% × Rock effectiveness → **3.125% / 6.25% / 12.5% / 25% / 50%** | Only Magic Guard. Flying and Levitate do **not** help. |
| **Spikes** | 1 layer 12.5%, 2 layers 16.67%, 3 layers 25% | Flying-types, Levitate, Magnet Rise, Magic Guard |
| **Toxic Spikes** | 1 layer poisons, 2 layers badly poisons | Flying, Levitate, Magnet Rise, Steel (poison-immune). **Grounded Poison-types absorb the layers** on switch-in. |

Stealth Rock hitting Flying-types for 2× is the defining hazard interaction in DPP: it is why
Gliscor pays 25% per switch and why Skarmory-based teams still fear it.

## Items

- **Life Orb** — 1.3× damage, 10% max HP recoil (ignored by Magic Guard).
- **Leftovers** — 1/16 per turn.
- **Focus Sash** — survives one KO at 1 HP, from full HP only.
- **Choice Band / Specs / Scarf** — 1.5× Atk / SpA / Speed, locked into one move while held.
- **Type-resist berries** — halve one super-effective hit, then are consumed. Common in DPP:
  Yache (Ice), Occa (Fire), Chople (Fighting), Colbur (Dark), Wacan (Electric), Shuca (Ground),
  Babiri (Steel), Passho (Water), Haban (Dragon).
- **Banned items in DPP OU:** Quick Claw, Soul Dew, and all evasion items.

## No team preview

Gen 5 introduced team preview; **Gen 4 does not have it**. You start the game knowing nothing about
the opponent's five unrevealed Pokémon. Consequences:

- Lead choice is a real decision made blind.
- Scouting moves (U-turn, Baton Pass) and switching to gather information have genuine value.
- You cannot plan a win condition on turn 1; you build the plan as information arrives.
- Track revealed information explicitly during a game — it is the main resource you accumulate.

## Format rules (Showdown `[Gen 4] OU`)

Standard clauses: Sleep Moves Clause, Species Clause, OHKO Clause, Evasion Moves/Items/Abilities
Clause, Endless Battle Clause, Freeze Clause Mod, HP Percentage Mod, Baton Pass Stat Trap Clause.

**Banned Pokémon:** Arceus (all formes), Darkrai, Deoxys (all formes), Dialga, Garchomp, Giratina
(both formes), Groudon, Ho-Oh, Kyogre, Latios, Lugia, **Machamp**, Manaphy, Mew, Mewtwo, Palkia,
Rayquaza, Shaymin-Sky, Wobbuffet, Wynaut.

**Banned moves:** all sleep-inducing moves (since 5 Jan 2026), Swagger, OHKO moves, evasion moves.

Note that **Latias is OU** while Latios is Uber, and **Salamence and Garchomp are Uber** in DPP.
