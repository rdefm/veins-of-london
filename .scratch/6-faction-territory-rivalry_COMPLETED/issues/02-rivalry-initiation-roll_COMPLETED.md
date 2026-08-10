# 02 — Rivalry initiation roll (industry-biased attacker/target selection)

**What to build:** A new standalone function (e.g. `Factions.roll_rivalry_attempts()`) that, given current state, decides which factions initiate a rivalry attempt this tick and against which target — a vein currently owned by a *different* faction (`site.factionVein.factionId`). Attacker selection is biased by the faction's `industries` (`data/factions.json`) — a faction with a raiding-flavoured industry (the Firm) initiates far more often than factions without one, who mostly get targeted rather than targeting others. Reuse a lookup-table pattern like `factions.gd`'s existing `INDUSTRY_INCOME` const, but as a distinct aggression-weighting table — no new per-faction stat is added to data or state, per the PRD. A faction with no rival-held vein to target is never eligible to attack that tick. This function is not wired into `daily_tick()` yet and performs no state mutation — it only returns a list of attempt records (e.g. `{attackerId, defenderId, veinSiteId}`). Odds/success resolution (ticket 03) and ownership transfer (ticket 04) come later. Target-vein selection heuristic among a faction's eligible rivals' veins (e.g. weighted by value, or uniform) is the implementer's call — document it in code.

**Blocked by:** None — can start immediately (does not depend on ticket 01's relation matrix; industry bias alone drives initiation)

**Status:** ready-for-agent

- [ ] New standalone function computes, from current state, a list of rivalry attempt records for the tick (attacker, defender, target vein) — pure computation, no state mutation, not yet called from `daily_tick()`
- [ ] Attacker selection is biased by `industries` (raiding-flavoured factions attempt markedly more often), reusing `data/factions.json`'s existing field — no new per-faction aggression stat added anywhere
- [ ] A faction with no rival-held vein to target never appears as an attacker that tick
- [ ] Target-vein selection heuristic among eligible rival-held veins is documented in code
- [ ] Tests cover: a raiding-industry faction (Firm) initiates attempts markedly more often than a non-raiding faction across many simulated rolls; a faction with no eligible target never initiates; attempt records only ever reference real rival-owned veins
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes
