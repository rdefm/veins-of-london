# 12 — Define guard repel on faction-held veins

**Type:** grilling

**Question:** How should guards on a faction-held vein get a chance to repel a raid, in the way the player's guards do? Right now only raids on the player's own veins roll repel.

Ticket 09 said "Faction extras feed raid resist and guard repel the same way the player's do". Raid resist works: `Cultivating.vein_raid_resist` counts faction extras, so rivalry odds and player stealth odds already drop. Repel doesn't, because faction veins have no raid path with a repel step:
- **Player raids** (`Raiding.stealth_success_chance`, `begin_raid` event → stealth roll → combat if caught) — never rolls repel.
- **Faction-vs-faction rivalry** (`Factions.rivalry_success_chance` / `roll_rivalry_odds`) — a single odds roll, no repel.
- Player-side repel lives in `Raiding._guards_repel_defend_raid` (vein, missed defend window) and `Home._guards_repel_pending_raid` (HQ). It uses `Raiding.guard_repel_chance(guard_count)`, which reads `guardRepel` in `data/constants.json`. The vein path counts `extraGuards` only, not the tier guard.

**Steps:**
1. Explore the raid flows above and write up the concrete options, with trade-offs, for where a repel roll could go: rivalry, player raids (before stealth? after being caught? instead of combat?), or both.
2. Grill the human on those options. Open questions include:
   - which raid paths get repel
   - where in each flow it rolls
   - whether the tier guard counts, or extras only (the player vein path counts extras only)
   - whether it stacks with the raid-resist tilt or replaces part of it
   - what the player sees and reads on a repelled raid, with prose flagged PROSE-REVIEW
   - kit burns on a repelled raid
   - Rng seeding
3. Record the decisions in `.scratch/biz-act2-guard-upkeep/spec.md` (§Faction guard upkeep) under a `## Comments` / decisions note.
4. **Final step:** create a fresh implementation ticket, `NN-faction-vein-guard-repel.md` in this `issues/` dir. Give it the standard fields: What to build, Blocked by, Relevant files, Status `ready-for-agent`, and acceptance checkboxes including REFERENCE §1.6/§1.8/§3.12 updates. Then mark this ticket `_COMPLETED`.

Don't implement any mechanics in this ticket. CLAUDE.md says: don't invent mechanics, ask.

**Blocked by:** 09 — Factions hire extra guards (done).

**Relevant files:**
- `systems/raiding.gd` (`guard_repel_chance`, `_guards_repel_defend_raid`, `stealth_success_chance`, `begin_raid`), `systems/home.gd` (`guard_repel_chance`, `_guards_repel_pending_raid`)
- `systems/factions.gd` (`rivalry_success_chance`, `roll_rivalry_odds`, `apply_rivalry_resolution`)
- `systems/cultivating.gd` (`vein_raid_resist`, `vein_guard_count`)
- `data/constants.json` (`guardRepel`)
- `tests/test_raiding.gd`, `tests/test_factions.gd`
- REFERENCE.md §1.6 (Raid resistance), §1.8 (Faction guard hiring), §3.12 (Faction extra guards), §3.12 "Raid kit burns"

**Status:** ready-for-human
