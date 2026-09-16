# 04 — Rivalry resolution: ownership transfer, relation feedback, daily-tick wiring

**What to build:** Wire tickets 02 and 03 into a new `daily_tick()` step in `systems/time_system.gd`, slotting after the existing faction-economy chain (⑤e/⑤f/⑤g in `data/factions.json`-driven order) — document the new step letter and ordering rationale in the existing step-order comment block, same convention as ⑤b-⑤g. Each tick: call `Factions.roll_rivalry_attempts()` (ticket 02), then resolve each attempt via `Factions.roll_rivalry_odds()` (ticket 03). A successful attempt reassigns the target vein's `factionVein.factionId` from defender to attacker — `oreType`/`level`/`security` carry over unchanged, not reset, matching Chunk 1's existing ownership-change shape (same field Chunk 1's claim/growth code already writes). It also worsens the defender's relation toward the attacker in ticket 01's matrix by a documented magnitude (the PRD leaves the exact feedback formula open). A failed attempt leaves all state untouched. **Silent** — no `Notify`/Ticker push on either outcome, per the PRD (the player discovers changes only by looking at the map — see ticket 05).

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] New daily-tick step (documented step letter, e.g. ⑤h) runs `Factions.roll_rivalry_attempts()` then resolves each attempt via ticket 03's odds function, wired into `systems/time_system.gd`'s `daily_tick()` alongside the existing ⑤b-⑤g chain, with ordering rationale documented in the step-order comment block
- [ ] A successful attempt reassigns the target vein's `factionVein.factionId` from defender to attacker; `oreType`/`level`/`security` carry over unchanged
- [ ] A successful attempt worsens the defender's relation toward the attacker in the ticket 01 matrix by a documented magnitude; a failed attempt leaves the matrix untouched
- [ ] No `Notify`/Ticker push on any outcome (success or failure)
- [ ] Tests cover: a successful attempt transfers ownership and worsens relation; a failed attempt changes nothing; multiple attempts resolving in the same tick don't double-process a vein that already changed hands earlier that same tick
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes

Demoable by advancing the game clock many days in a debug save and observing faction-owned veins change hands over time, with the Firm initiating noticeably more often than non-raiding factions, and relation values drifting downward for factions that keep losing territory to the same rival.
