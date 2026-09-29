# 01 — Long-horizon faction-balance simulation harness

**What to build:** A repeatable simulation that drives `TimeSystem.
daily_tick()` (or equivalent) for 100-150 simulated in-game days across
multiple RNG seeds — extending the daily-tick-driving pattern `tests/
test_playthrough.gd` already uses, and/or `scripts/soak.sh`'s repeated-run
approach — and reports each of the 5 factions' vein count/share over time
(not just a final snapshot). Usable standalone: running it against today's
constants should visibly show the reported collapse/runaway behavior, giving
a concrete before/after baseline for ticket 02.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Simulation runs headless, drives at least 100-150 simulated days,
      across multiple seeds (not a single run).
- [ ] Reports per-faction vein count/share at regular intervals across the
      run (not just start/end).
- [ ] Running it against current (un-retuned) constants demonstrates the
      reported problem — at least one faction trending to zero veins and/or
      one faction trending toward dominating vein share — giving a concrete
      baseline.
- [ ] Harness is reusable (not a one-off script) — ticket 02 should be able
      to re-run it against changed constants without rewriting it.
