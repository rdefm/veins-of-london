# Vein

A mobile-first, menu-driven London urban-fantasy economy game (Godot 4.4 port). See `CLAUDE.md` for the project constitution and `docs/REFERENCE.md` for canonical mechanics.

## Language

**Site**:
A prospected plot in a district (`state.world.sites`) with fixed tier/ore/bonuses, visible before it's claimed. A site is not a vein — it's the *land*; a vein is what grows on it once seeded.
_Avoid_: plot, spot, location (as a synonym for site — "location" is the vein's flavour-text address string)

**Unclaimed** (site state):
A site with `claimed == false AND factionVein == null`. Only unclaimed sites are eligible for the player to seed, and only unclaimed sites are eligible for the prospect re-roll when a district's `siteCap` is full.
_Avoid_: using "unclaimed" loosely to also mean faction-claimed — they are a distinct third state, not a variant of unclaimed.

**Faction-claimed** (site state):
A site a named faction (`collective`/`firm`/`guild`/`network`/`conclave`) has taken (`factionVein != null`, a real vein object); `claimed` stays `false`. Untouchable by the player in M1 — not seedable, not reroll-eligible. Can only leave this state via the faction vein's own growth-collapse-at-zero (deleted outright, not reverted — same roll a player vein's site faces, see `Cultivating.collapse_vein()`) or, in M2+, player reclaim-by-combat. (A separate independent daily-kill roll, NPC-abandonment, existed here until bugfixes-73/adr/0004 removed it — collapse-at-zero is now the only way in.) Formerly an anonymous `npcClaimed` boolean with no identity or vein — retired by faction-vein-ownership T01 (`.scratch/faction-vein-ownership/`); every non-player claim now names a real faction end to end.
_Avoid_: "unclaimed" (see above), "NPC-claimed" (retired term), "lost" as a state name (it's a UI/flavour word, not the field name)

**siteCap**:
Per-district hard cap on total sites — unclaimed + player-claimed + faction-claimed, all counted together. When prospecting would exceed it, no new site is created; instead the district's worst *unclaimed* site is deleted and re-rolled.

**Vein**:
A cultivable orichalchum source the player or a faction has grown on a claimed site. Carries one signed axis, `growth` (0..ceiling, neutral 50) — see [[Growth]] — rather than a permanent level; a vein never permanently improves, only its terroir (see [[Terroir]]) does. A faction vein lives embedded on its site (`site.factionVein`), carries a `factionId`, and is otherwise the same shape as a player vein (see `systems/cultivating.gd`'s `make_vein()`). Distinct from the site itself — see [[Site]].

**Growth**:
A vein's one state axis (`vein.growth`, 0..ceiling, neutral 50), from the vein-growth-state PRD (`.scratch/vein-growth-state/`). Replaces the old `devBar`/`level`/`charged`/`chargeBlocks` quartet entirely. Left alone, it drifts daily toward whichever wall (0 or the ceiling) it was last left leaning, accelerating with distance from neutral; the player pushes it back with Cultivate (toward the ceiling) or Prune (toward 0). See [[Band]], [[Prune]], [[Rampant]].
_Avoid_: "charge"/"charged", "dev bar"/"devBar" — retired terms; a vein's magnitude is now [[Growth]] read through its [[Band]]. Where a scalar is needed (raid targeting, faction income, combat scaling) it's `Cultivating.combined_magnitude(vein)` (`value_tier(vein) + (level - 1)`, cultivation-refining ticket 02), not raw `value_tier()` or "level" alone.

**Band**:
The named range a vein's [[Growth]] currently falls in (`collapsed`/`barren`/`sparse`/`thinning`/`dormant`/`taking`/`lush`/`wild`/`rampant`), each with its own daily drift rate — symmetric around neutral. `dormant` (45–55) is the deliberate "safe to leave alone" band: zero drift, zero yield, the player's answer to holding more veins than they have blocks.

**Prune**:
The player action that pushes a vein's [[Growth]] left (toward 0), converting growth points above neutral into ore. Comes in light (-15) and hard (-40, at a yield bonus) depths. Replaces the old "harvest" action — pruning at or below neutral always yields nothing, so cutting depth is a real decision, not a formality.

**Rampant**:
The band at a vein's growth ceiling (100, or 120 with the `wildCeiling` terroir bonus) — stable, maximally productive, and the game's highest-value raid target. A vein that stays rampant long enough self-seeds a new player vein nearby (vein-growth-state ticket 02).

**Terroir**:
The land itself — a site's tier (`poor`/`fair`/`rich`/`saturated`, driving `terroirYieldMult` directly, and capping how far a vein's earned `level` can rise — see below) and its discovery bonuses — carries much of a vein's long-term progression, alongside the vein's own earned level; growth (condition) itself is never permanent. Which sites you hold matters far more than any one vein's condition history. `data/sites.json`'s `discoveryBonusPool` is `["vigour", "wildCeiling", "yield"]`: `wildCeiling` raises `Cultivating.ceiling(vein)` from 100 to 120; `yield` boosts the rolled prune amount. `vigour` no longer affects drift as of cultivation-refining ticket 01 (which replaced the old band-based drift table with a level-driven formula) — currently unused pending a later ticket. Landed in vein-growth-state tickets 01 (ceiling plumbing) and 05 (the rename and the effects themselves).

Every vein also carries a persistent `level: int` (1..`Cultivating.level_cap_for_tier(tier)`: poor 2 / fair 3 / rich 4 / saturated 5), seeded at 1 on creation and unrelated to `growth`/`value_tier()`. It scales nightly drift magnitude (`level + rand(1,5)`, R§1.2/§8.3) and, via `Cultivating.combined_magnitude(vein)` (cultivation-refining ticket 02), blends into every value_tier consumer (raid stealth odds, faction targeting/income, combat scaling, the map's growth ring). Ways to raise or lose it land in later cultivation-refining tickets (05/06/07).

**The Network**:
In-fiction name for the game's map screen (a Beck-style transit diagram). Never call it "the tube map," "the Underground," or "London Underground" in player-facing text — see `plans/M1-LONDON.md` D4.1 for the legal rationale.

**Turn occurrence** _(draft, ticket 01 combat-refining, 2026-09-19)_:
One entry in a combat round's turn queue (`combat.turnCursor.queue`, `Combat.build_turn_queue()`) — not a synonym for [[Combatant]]. The same combatant produces more than one occurrence in a round with a Motion-inserted extra turn, and a fresh occurrence every round it survives into. The turn-order strip (`docs/combat-animation-vision.md` §2.4) renders one card per occurrence, not one per combatant — a combatant with two live occurrences this round shows two cards.
_Avoid_: "turn" alone when a distinction from "combatant" matters — "turn" is ambiguous between the occurrence and the atomic action it resolves into.

**Combatant** _(draft, ticket 01 combat-refining, 2026-09-19)_:
A single fighting entity in `combat` — the player, one `combat.allies[]` entry, or one `combat.enemies[]` entry. Has one persistent identity for the fight's duration (HP, KO state) even though it may own several [[Turn occurrence]]s across a round or the fight.

**Selection** _(draft, ticket 01 combat-refining, 2026-09-19)_:
`combat.selection: {type, index}` — the player's current single-target for Attack/Blast/an eligible Complication, addressable at the player, an ally or an enemy (`type`). Distinct from a turn occurrence and from scroll position in the turn-order strip: scrolling to inspect an upcoming occurrence never changes `selection`, only tapping a card or a combatant sprite does.
