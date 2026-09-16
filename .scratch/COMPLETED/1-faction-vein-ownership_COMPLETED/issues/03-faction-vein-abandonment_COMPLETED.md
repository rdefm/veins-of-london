# 03 — Faction vein abandonment / ageing-out

**What to build:** The existing age-based NPC-abandonment roll (ticket 05, `systems/sites.gd`, `adr/0002`) now also applies to faction claims — no new mechanic, the existing formula (`p = 0.05 + 0.01 × ageDays`, capped 0.15, flat across tiers) just runs against faction-claimed sites too. On a hit, the site and its faction vein are deleted outright together (matching `adr/0002`'s actual behavior — freeing the `siteCap` slot for a fresh prospect — not "reverted to unclaimed").

**Blocked by:** 01 (needs faction claims/veins and their claim-day timestamp to exist)

**Status:** completed — no-op. T01's `npcClaimed` → `factionVein` refactor already moved the abandonment roll (`Sites.roll_npc_abandonment`, `systems/sites.gd:350-364`) onto faction veins directly, and its tests (`tests/test_sites.gd:492-520`) already cover joint site+vein deletion, the shared age curve, and player-site exclusion. Notify copy ("the outfit running...") already reads fine without naming the faction. Nothing left to build.

- [ ] Faction-claimed sites are eligible for the existing daily-tick abandonment roll, using the same age curve as today's NPC-claim abandonment (age since the site was claimed by the faction).
- [ ] On a hit, both the site and its faction vein are removed from state together — no orphaned vein left referencing a deleted site.
- [ ] Player-claimed sites are unaffected (unchanged behavior).
- [ ] Notification copy on abandonment still reads sensibly now that the claimant has a real faction identity (reuse/adapt the existing notify string, PROSE-REVIEW if reworded).
- [ ] Tests cover: faction vein abandonment deletes both site and vein, age curve matches the existing NPC formula, player sites are never touched by this roll.
- [ ] `godot --headless --check-only` clean on every touched file; `scripts/run_tests.sh` passes.
