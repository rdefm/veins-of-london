# 13 — Conclave positions + Ticker push + hint headlines

**What to build:** The Conclave takes market positions and then nudges the Ticker toward the state that pays them. The nudge is capped and has a cooldown, and it reuses faction barometer prefs as the mechanism. When a position is large, a hint headline fires ("someone's buying up physics"), so the player can read and ride the Conclave. The Conclave also gets "Ticker push against target" as a market-rung move.

**Blocked by:** 11 — Conclave stabiliser; 11b — Conclave stabiliser stockpile.

**Relevant files:** `systems/barometer.gd` (push hook, headlines, faction prefs), `data/barometer.json`, `systems/faction_ai.gd`, `systems/faction_sim.gd`, `SaveManager` (positions), `tests/test_barometer.gd`, `tests/test_faction_ai.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 67–68, §Conclave, §Barometer. REFERENCE.md §1.9, §3.2.

**Status:** ready-for-agent

- [ ] Rollover test (seeded Rng): with a Conclave position held, the Ticker's odds shift toward the paying state, within the cap. The cooldown blocks a repeat.
- [ ] Rollover test: a position over the size threshold emits a hint headline.
- [ ] Positions are saved and backfilled. REFERENCE §1.9/§3.2 and CODEMAP updated. `PROSE-REVIEW:` for hint headlines.
