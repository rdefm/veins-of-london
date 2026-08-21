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
A site a named faction (`collective`/`firm`/`guild`/`network`/`conclave`) has taken (`factionVein != null`, a real vein object); `claimed` stays `false`. Untouchable by the player in M1 — not seedable, not reroll-eligible. Can only leave this state via NPC abandonment (deleted outright, not reverted) or, in M2+, player reclaim-by-combat. Formerly an anonymous `npcClaimed` boolean with no identity or vein — retired by faction-vein-ownership T01 (`.scratch/faction-vein-ownership/`); every non-player claim now names a real faction end to end.
_Avoid_: "unclaimed" (see above), "NPC-claimed" (retired term), "lost" as a state name (it's a UI/flavour word, not the field name)

**siteCap**:
Per-district hard cap on total sites — unclaimed + player-claimed + faction-claimed, all counted together. When prospecting would exceed it, no new site is created; instead the district's worst *unclaimed* site is deleted and re-rolled.

**Vein**:
A cultivable orichalchum source the player or a faction has grown on a claimed site. Carries one signed axis, `growth` (0..ceiling, neutral 50) — see [[Growth]] — rather than a permanent level; a vein never permanently improves, only its terroir (see [[Terroir]]) does. A faction vein lives embedded on its site (`site.factionVein`), carries a `factionId`, and is otherwise the same shape as a player vein (see `systems/cultivating.gd`'s `make_vein()`). Distinct from the site itself — see [[Site]].

**Growth**:
A vein's one state axis (`vein.growth`, 0..ceiling, neutral 50), from the vein-growth-state PRD (`.scratch/vein-growth-state/`). Replaces the old `devBar`/`level`/`charged`/`chargeBlocks` quartet entirely. Left alone, it drifts daily toward whichever wall (0 or the ceiling) it was last left leaning, accelerating with distance from neutral; the player pushes it back with Cultivate (toward the ceiling) or Prune (toward 0). See [[Band]], [[Prune]], [[Rampant]].
_Avoid_: "charge"/"charged", "dev bar"/"devBar", "vein level" — all retired terms; a vein's magnitude is now [[Growth]] read through its [[Band]], and where a 1–6 scalar is needed (raid targeting, faction income, combat scaling) it's `Cultivating.value_tier(vein)`, not "level."

**Band**:
The named range a vein's [[Growth]] currently falls in (`collapsed`/`barren`/`sparse`/`thinning`/`dormant`/`taking`/`lush`/`wild`/`rampant`), each with its own daily drift rate — symmetric around neutral. `dormant` (45–55) is the deliberate "safe to leave alone" band: zero drift, zero yield, the player's answer to holding more veins than they have blocks.

**Prune**:
The player action that pushes a vein's [[Growth]] left (toward 0), converting growth points above neutral into ore. Comes in light (-15) and hard (-40, at a yield bonus) depths. Replaces the old "harvest" action — pruning at or below neutral always yields nothing, so cutting depth is a real decision, not a formality.

**Rampant**:
The band at a vein's growth ceiling (100, or 120 with the `wildCeiling` terroir bonus) — stable, maximally productive, and the game's highest-value raid target. A vein that stays rampant long enough self-seeds a new player vein nearby (vein-growth-state ticket 02).

**Terroir**:
The land itself — a site's tier (`poor`/`fair`/`rich`/`saturated`, driving `terroirYieldMult` directly) and its discovery bonuses — carries all of a vein's long-term progression now that growth is never permanent. Which sites you hold matters far more than any one vein's history. `Cultivating.ceiling(vein)` already checks a hospitability bonus named `wildCeiling` (+20 to the growth ceiling), per vein-growth-state ticket 01; `data/sites.json`'s `discoveryBonusPool` itself still lists the pre-growth-model names (`recharge`, `maxLevel`, `yield`) until terroir-amplification ticket 05 lands the `recharge`→`vigour`/`maxLevel`→`wildCeiling` rename and the drift/ceiling effects those bonuses actually grant.

**The Network**:
In-fiction name for the game's map screen (a Beck-style transit diagram). Never call it "the tube map," "the Underground," or "London Underground" in player-facing text — see `plans/M1-LONDON.md` D4.1 for the legal rationale.
