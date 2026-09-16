# 02 — Faction vein daily growth (virtual cultivate roll)

**What to build:** Faction veins grow over time without player involvement. Each daily tick, every faction-owned vein rolls a virtual cultivate attempt — the same success-chance and devBar-gain formulas the player's own `cultivate()` action uses, evaluated at skill floor 1 (factions have no skill stat). On success, `devBar` advances and the vein levels up per `vein_levels.json`'s existing thresholds, exactly like a player vein would. On failure, nothing happens that day. This is an explicit placeholder pace per the PRD — the real cultivator-staffing growth model is Chunk 1b, not this ticket.

**Blocked by:** 01 (needs real faction vein objects to exist)

**Status:** completed

- [ ] New daily-tick step rolls one virtual cultivate attempt per faction vein, using `get_cult_chance(1)` / `get_bar_gain(1)` (skill-1 floor) — no new balancing table, reuses `vein_levels.json` thresholds directly.
- [ ] Success advances `devBar` and triggers level-up (including level-cap/hospitability-bonus handling) exactly as the player path does; failure is a no-op.
- [ ] Tick step is ordered sensibly alongside the existing daily-tick claim/abandonment steps (doesn't double-grow a vein claimed earlier the same tick, doesn't grow a vein that gets abandoned the same tick — pick and document one consistent ordering).
- [ ] Tests cover: success path advances devBar/levels correctly, failure path is a no-op, a vein at max level/devBarMax doesn't overflow or error.
- [ ] `godot --headless --check-only` clean on every touched file; `scripts/run_tests.sh` passes.

Demoable by advancing the game clock several days in a test/debug save and observing a faction vein's level increase without any player action.

