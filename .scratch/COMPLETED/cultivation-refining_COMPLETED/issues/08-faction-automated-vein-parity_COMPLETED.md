# 08 — Faction & automated vein parity

**What to build:** Faction-owned veins and staff-automated player veins (tended via the vein station) get the full leveling/development/depletion mechanic from tickets 01-07 — same terroir caps, same drift, same eligibility/streak tracking, same level-up odds, same depletion/collapse rules — fully auto-resolved with no UI. There is no separate simplified path for NPC/automated veins; they run through the exact same per-vein pipeline in `Cultivating.drift_veins()` that player-manual veins do.

**Blocked by:** 01, 03, 04, 05, 06, 07 (verifies/extends the complete mechanic to a second category of veins once it exists).

**Relevant files:**
- `systems/cultivating.gd` (`drift_veins()` already loops over player + faction veins together — confirm the new pipeline applies uniformly, no player-only gating)
- `systems/factions.gd` (faction vein income/rivalry — confirm it reads post-pipeline state correctly)
- `systems/rooms.gd` (`process_vein_station()` — staff-tended player veins; confirm automated cultivation targets interact correctly with the new gain/eligibility rules rather than the old growth-target logic)

**Status:** ready-for-agent

- [ ] Faction veins earn levels, develop, and deplete identically to player veins, with no code path exempting them
- [ ] Staff-automated vein-station cultivation applies the same gain/eligibility rules as manual cultivation (no separate automated formula)
- [ ] Test: a faction vein held at ≥90 across several simulated nights levels up per the same probability schedule as a player vein
- [ ] Test: a faction vein at level>1 depleting to 0 loses a level and resets to 50 identically to a player vein
