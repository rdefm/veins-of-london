# 12 — Conclave war squeeze + anti-obliteration

**What to build:** A war older than N days draws Conclave pressure on each side in proportion to that side's weariness. The Conclave denies that side's war goods and ore, and undercuts its sales, reusing the ticket 07 actions. The squeeze never pushes toward one side's destruction, and it holds back a side that would wipe out a much weaker one. The Conclave never offers or brokers peace.

**Blocked by:** 07 — Conclave targeted moves; 08 — War + weariness.

**Relevant files:** `systems/faction_ai.gd`, `systems/faction_sim.gd`, `systems/market.gd`, `data/constants.json`, `tests/test_faction_ai.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 64–66, §Conclave. REFERENCE.md §3.1.

**Status:** ready-for-agent

- [ ] Rollover test: a long war gets Conclave deny/undercut on both sides, scaled by each side's weariness.
- [ ] Rollover test: when one side is far weaker, the stronger side takes the heavier squeeze.
- [ ] The Conclave never creates a peace offer or truce.
- [ ] Constants in JSON. REFERENCE and CODEMAP updated.
