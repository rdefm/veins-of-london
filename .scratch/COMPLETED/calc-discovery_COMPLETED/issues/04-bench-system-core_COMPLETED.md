# 04 — systems/bench.gd core: keys, cell state, census, probe roll, pity

**What to build:** The full discovery engine as pure, static, headlessly-testable logic — no screens yet. Running a probe against a pairing+approach cell must correctly resolve to inert/hot/found, deduct ore regardless of outcome, accumulate pity on repeated misses, and reveal the pairing's total effect census (including effects behind unlearned approaches) on the pairing's first-ever probe.

**Blocked by:** 03 — player.bench state shape + Rewind round-trip.

**Status:** ready-for-agent

- [ ] `systems/bench.gd` created (static funcs only, mirrors `systems/crafting.gd`'s shape).
- [ ] Canonical type-set key helper: types sorted alphabetically, joined with `+` (e.g. `"life+time"`, never `"time+life"`); every cell/census/notes lookup goes through this one helper.
- [ ] Cell-state resolution: `untried` (default/absent) → `inert` (empty, probed) / `hot` (occupied, failed at least once) / `found` (discovered). `inert` is permanent — no probe or refinement mechanism can ever move a cell out of `inert`.
- [ ] Census: first probe of any type pairing permanently reveals the pairing's total effect count, counting effects behind approaches not yet learned. Exact numeric count is available via a queryable function.
- [ ] Probe roll: discovery-chance formula and pity application per vision-doc §7 (provisional constants, implemented as specified), reusing `Home.get_workshop_bonus()` unchanged for the odds — no new bonus channel. Ore is deducted on every probe attempt regardless of outcome (miss, hit, or reveal-only). XP awarded on attempt. On miss: cell → `hot`, `misses` incremented, pity applied to next attempt's odds. On hit: cell → `found`, effect becomes an immediately craftable recipe. A note entry (enum outcome, not prose) appended per attempt, capped at ~20 per pairing, oldest dropped.
- [ ] `tests/test_bench.gd` created (mirrors `tests/test_crafting.gd`): cell-state transitions (`untried` → `inert`/`hot`/`found`); the inert-is-permanent-and-unrollable invariant; pity accumulation and its effect on subsequent odds; census correctness including approaches not yet learned; ore-always-deducted on every outcome; the type-set key helper (alphabetical sort, `+`-joined, both input orders normalize identically).
- [ ] Syntax check clean on all touched `.gd` files.
