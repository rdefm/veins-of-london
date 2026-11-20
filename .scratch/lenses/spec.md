# Lenses — spec (DRAFT)

Status: ready-for-agent — signed off 2026-11-20. All numbers are placeholders (balance pass later). Tickets: `issues/`.

Source: design conversation 2026-11-20. Canonical mechanics on conflict: `docs/REFERENCE.md` (this spec extends §1.4, §3.5, §3.7b, §3.9a, §3.9d, §3.1d, sites/prospecting once signed off).

## Goals

1. Give the player a way to influence and improve observation rolls.
2. Put power on the character (Sense), not only on items, without making items redundant.
3. Do it with as few new player-facing concepts as possible.

Player-facing model, one sentence: **Movement powers the Dial, Lenses see, Complications cast.**

## Core model

- **The Sight is the player's.** Sense level (1–5) decides *which kinds* of lens effect are switched on. Ore-agnostic: no Sense level is ever wasted on the "wrong" ore.
- **The lens tunes it.** A lens is a Dial component with one ore and a tier. It decides *which ore* and *how strong*. A lens does nothing without the Dial.
- **No lock-out.** Every lens ore is always craftable. Specialising costs calc, tiers and slots — never a permanent choice.
- Lenses arrive with the Dial (mid-game); none exist before it.

## Dial changes

### Lens slots
- `lensSlotsByLevel = [0, 1, 1, 2, 2, 3]` (index = Dial level). Separate from Complication capacity.
- Lenses load/unload through the Dial loadout menu, outside events and combat (same rule as Complications).
- One lens per ore at a time per Dial (no stacking two of the same ore).

### Contact Dials
- Contact Dials (James) get lens slots by the same `lensSlotsByLevel`, managed in the same menu.
- James's granted Dial (`Dial.build_granted_dial`, level 2) starts with a tier-1 **time** lens loaded, so his winding costs time calc as today.
- A contact has no Sense. A contact's lens sets its winding ore and gives that contact the lens's **combat** effect where it applies: Physics flat damage on that ally; Time fog cut on that ally's AI reads; Fate light bonus on that ally's crit rolls. Life, Emotion and all world sight do nothing on a contact Dial.

### First lens
- Seeding a Dial (`Dial.attempt_seed`) now also asks the player to choose a lens ore. On success the Dial is seeded with a lens of that ore loaded in slot 1 (tier = crafting skill at seed, as Movements). On failure nothing is gained, as today.

### Crafting lenses
- `Dial.attempt_craft_lens(ore)`: gift-gated, Movement-style craft (ingredients always spent, chance-gated, tier = crafting skill at craft time, no refine). Ingredient = calc of the lens ore.

### Movements lose their ore
- Movements no longer have `oreType` or attunement. Ore focus in the Dial comes **only** from lenses.
- Movement crafting ingredients: a small amount of **all five** ores (e.g. `movement_calc_cost` split evenly — 4 of each at base; placeholder).
- **Winding** costs calc of a loaded lens's ore. With more than one lens loaded, the player picks which loaded lens's ore to pay with. Cost per charge unchanged (Movement archetype/tier table).
- **Attunement** (`Dial.attunement_bonus`) moves to lenses: the bonus applies when the ore matches *any loaded lens*, magnitude by that lens's tier (reuse `attunementBonusByTier`).

### Saves
- Old saves lose their Dials (no migration, no refund). Save version bump.

## Lens effects

Magnitudes scale with **lens tier**. Sense level gates which columns are live.

| Lens | Always (loaded) | Sense L2 — world | Sense L3 — combat |
|---|---|---|---|
| **Time** | Ore-roll bonus (time) | Ambush forewarning | Fewer unread enemy intents |
| **Physics** | Ore-roll bonus (physics) | Raid site sheet shows guard kit + ward; +1 intel level on vein security | Flat +damage dealt / −damage taken |
| **Life** | Ore-roll bonus (life) | Prospect weights shift to higher site tiers; vein drift forecast | Enemy HP shown as numbers |
| **Fate** | Light bonus to **all** rolls | Event check rolls shown as a range; gut feeling on notable market moves (market `!`) | Pre-rolled enemy crits flagged on intents |
| **Emotion** | Ore-roll bonus (emotion) | Exact faction Threat + grudge countdown; exact contact relation | Shows each enemy action's target |

### "Always" — ore-roll bonus
- Applies to rolls of the lens's ore: **observation** blocks of that ore, **crafting** (recipe uses that ore), **cultivating** (vein of that ore — gain multiplier, as attunement today, since cultivate has no chance roll), **seeding** (site of that ore). This is the old Movement attunement, now per lens.
- **Fate:** the normal fate-ore bonus (fate observation blocks, fate recipes, fate veins, fate sites) **plus** a lighter bonus to *all* player rolls: event checks, cover rolls, observation (every ore), crafting, seeding, prospecting, combat crit and Leg it. `fateAllRollsBonusByTier` placeholder `[0, 0.01, 0.02, 0.03, 0.04, 0.05]`. Applied before each roll's own clamp; on a fate roll both bonuses stack.
- Not gated by Sense, so moving attunement off Movements loses nothing players had.

### Sense L2 — world sight
Each one shows something the sim already computes, leads to a decision, and appears on a screen the player already visits.
- **Time — ambush forewarning.** A morning notification naming the district where an ambush is due today. Requires the ambush roll to be made at day start for every district *whether or not a lens is loaded*, so the lens changes knowledge, not the RNG stream (§3.1d).
- **Physics — security read.** Raid site sheet shows the vein's guard kit and ward type before committing. Implemented as +1 intel level on the vein-security track (does not bypass the intel meter).
- **Life — prospect + drift.** `Sites.prospect` site-tier weights shift toward higher tiers (`lifeProspectShiftByTier`, placeholder); stacks with Be A Lady's best-of-two. Vein sheet shows tonight's drift range / collapse risk.
- **Fate — roll range.** A shown check option's `?` modal and button show the d100 as a band, e.g. "Roll 40–60 · need 55+". The band always contains the real roll at a seeded offset (`Rng.stable_unit`, not centred). Width by tier, placeholder `[0, 40, 30, 20, 15, 10]`. Recomputed live from `check_roll(i)` like `revealed_roll` (toggles shift it). Dejà Vu stays the exact reveal. Market: a gut-feeling source in the market row `!` (08a, REFERENCE §3.13 Insight) — notable projected moves only (≥ 5%), direction only: held goods "sell soon"/"hold on", plus the N biggest unheld moves by tier (`fateMarketReadsByTier`). Lucky buyer (08b, REFERENCE §3.13 Lucky price): one roll per Trade-menu trade (Soho, Archie, faction shop/contact), chance `fateLuckyPrice.chanceByTier` placeholder `[0, 0.05, 0.08, 0.11, 0.14, 0.18]` + all-rolls bonus; hit = sale +5% / buy −5%. Not contracts, fixed-price offers or auto-sell.
- **Emotion — standing.** Exact Threat toward the player and grudge window remaining on the faction screens; exact contact relation number in contact cards.

### Sense L3 — combat sight
All shown on the existing intent strip; no new combat UI concepts.
- **Time:** enemy `unreadChance` multiplied by `(1 − timeFogCutByTier[tier])` (placeholder `[0, 0.2, 0.3, 0.4, 0.5, 0.6]`).
- **Physics:** player's damage dealt +N, damage taken −N (`physicsFlatByTier`, placeholder `[0, 1, 2, 3, 4, 5]`). Order: after crit and anger scaling, before Shield; damage taken floored at 1 (chip still lands). Stacks with Body attack bonus and Stiff Upper Lip.
- **Life:** enemy HP shown as `hp/hpMax`.
- **Fate:** enemy crits are rolled when the plan is rolled (in every fight, lens or not — same determinism rule as ambush); with a Fate lens, a critting intent is flagged. Never lies; an unread intent stays unread.
- **Emotion:** an enemy action's target is shown even when the action is otherwise unread.

### Sense L4 / L5
- **L4 Glimpse:** once per event / fight, free. Event: re-roll one observation read of a loaded lens's ore (keep better). Combat: fully reveal one enemy's plan this round.
- **L5 Peripheral sight:** owned but unloaded lenses give half their "Always" bonus.
Sense's existing flat `observation.sensePerLevel` bonus stays.

## Dial menu

One layout everywhere (Profile card, HQ Dial view, combat-prep Change loadout), three labelled socket rows, one interaction model:

```
┌ Level 3 Dial · Malacca Cane ─────────┐
│ MOVEMENT   powers it                 │
│ [↻ T3]   Charge ▓▓▓▓▓░░ 14/22  [Wind]│
│                                      │
│ LENSES     what you see              │
│ [◷ T2] [ + ]                         │
│                                      │
│ COMPLICATIONS   what you cast        │
│ [Pearl T3] [Burst T2] [ + ]          │
│                                      │
│              [Craft component]       │
└──────────────────────────────────────┘
```

- **Every socket behaves the same.** Empty `+` → picker of held components of that kind, each with a one-line effect. Filled socket → Details / Swap / Remove. Replaces the separate Unseat, Swap and "Unload X" buttons; `movement_swap` and `dial_load_complication` modals become one socket picker.
- **Wind** opens an ore choice only when more than one lens is loaded.
- **Lens Details** lists its effects grouped by Sense level; locked ones greyed with the level needed ("Sense 3: see who they're targeting"). Doubles as the Sense progression teaser.
- **Craft component** → existing craft modal with Movement | Lens.
- **HQ diorama:** lens sockets as eyepieces on the Dial's crown; Complications stay as flanking sockets. Same tap behaviour.
- **Combat Dial page:** unchanged (lenses are passive; Glimpse, if kept, adds one row).
- **Dial seeding screen:** adds the first-lens ore choice.

## Overlaps with existing systems

| Overlap | Resolution |
|---|---|
| Movement attunement | Moved onto lenses (above) |
| Prophet's Breath sight vs Time combat lens | Fine: Breath = total and temporary; lens = partial and permanent |
| Dejà Vu vs Fate roll range | Fine: Fate = permanent band; Dejà Vu = exact, paid |
| Physics security read vs intel meter | Adjusted: +1 intel level, not a bypass |
| Be A Lady (all-ore obs, prospect best-of-two) vs Fate / Life | Fine: stacks |
| Body attack / Stiff Upper Lip vs Physics flat | Fine: stacks |

## Docs to update on sign-off

REFERENCE §1.4 (Dial: slots, Movement ore removal, winding, seed, attunement), §3.5, §3.7b (fog, crit pre-roll, Physics flat), §3.9a (Fate range, all-roll bonus), §3.9d (Σmods), §3.1d (ambush pre-roll), prospecting/sites; `CONTEXT.md` (add **Lens**); `data/skill_feats.json` Sense feats; save format §6; CODEMAP when files land.
