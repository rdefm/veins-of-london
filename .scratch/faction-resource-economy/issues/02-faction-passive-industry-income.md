# 02 — Daily passive/industry income

**What to build:** Each daily tick, every faction's resource balance (ticket 01) grows by a fixed passive amount reflecting its `industries` (`data/factions.json`) — e.g. the Conclave's institutional influence or the Guild's crafting contracts generate income independent of how many veins the faction currently holds. This is one of the two income sources the PRD calls for (the other, vein-derived income, is ticket 03 and lands after this one so the daily-tick income step exists first for it to extend).

Exact per-faction/per-industry income values are left to the implementer, documented in code — the acceptance bar is that richer-reading factions (Conclave, Guild) accrue passive income faster than scrappier ones (Collective), consistent with ticket 01's baseline differentiation, and that no faction's passive income is zero or negative.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] New daily-tick step adds passive income to every faction's balance, derived from that faction's `industries` list — factions with richer-reading industries (per `factions.json` flavour text) accrue more than scrappier ones.
- [ ] Tick step is ordered sensibly alongside the existing daily-tick steps (claim roll, abandonment, faction-vein growth) — document the chosen ordering and why it doesn't conflict with them.
- [ ] Passive income applies to every faction every day regardless of vein count (a faction with zero held veins still earns something) — this is what distinguishes it from vein-derived income (ticket 03).
- [ ] Tests cover: balances increase after a tick, the increase differs sensibly across factions per their industries, a faction with no veins still earns passive income.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes.

Demoable by advancing the game clock several days in a test/debug save and observing faction balances climb even for factions holding no veins.
