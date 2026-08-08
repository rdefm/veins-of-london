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
A site a named faction (`collective`/`firm`/`guild`/`network`/`conclave`) has taken (`factionVein != null`, a real Lv1+ vein object); `claimed` stays `false`. Untouchable by the player in M1 — not seedable, not reroll-eligible. Can only leave this state via NPC abandonment (deleted outright, not reverted) or, in M2+, player reclaim-by-combat. Formerly an anonymous `npcClaimed` boolean with no identity or vein — retired by faction-vein-ownership T01 (`.scratch/faction-vein-ownership/`); every non-player claim now names a real faction end to end.
_Avoid_: "unclaimed" (see above), "NPC-claimed" (retired term), "lost" as a state name (it's a UI/flavour word, not the field name)

**siteCap**:
Per-district hard cap on total sites — unclaimed + player-claimed + faction-claimed, all counted together. When prospecting would exceed it, no new site is created; instead the district's worst *unclaimed* site is deleted and re-rolled.

**Vein**:
A cultivable orichalchum source the player or a faction has grown on a claimed site. A faction vein lives embedded on its site (`site.factionVein`), carries a `factionId`, and is otherwise the same shape as a player vein (see `systems/cultivating.gd`'s `make_vein()`). Distinct from the site itself — see [[Site]].

**The Network**:
In-fiction name for the game's map screen (a Beck-style transit diagram). Never call it "the tube map," "the Underground," or "London Underground" in player-facing text — see `plans/M1-LONDON.md` D4.1 for the legal rationale.
