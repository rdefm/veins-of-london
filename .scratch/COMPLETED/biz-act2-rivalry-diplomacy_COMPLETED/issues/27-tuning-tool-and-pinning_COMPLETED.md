# 27 — Tuning tool + pin placeholders

**What to build:** Extend the headless faction-economy sim to print relation, stance, war, weariness and truce timelines. Use it to pin every *placeholder* in this feature's JSON and REFERENCE.md against the feel targets. Re-check sub-spec 2's share targets before pinning pressure weights. Feel targets:
- a player at 25% of the Firm's primary ore with no contracts gets a warning in ~2 weeks and a first market move in ~3
- wars end in truce more often than in collapse
- no faction reaches 0 veins in 120 days without player targeting

Add the no-obliteration check as a slow balance test if cheap.

**Blocked by:** 01–25.

**Relevant files:** `scripts/sim_faction_economy.gd`, `scripts/sim_faction_economy_impl.gd`, `data/constants.json`, `data/factions.json`, `data/barometer.json`, `docs/REFERENCE.md` (every section touched by this feature), `.scratch/biz-act2-rivalry-diplomacy/spec.md` §Testing Decisions (Tuning tool).

**Status:** ready-for-agent

- [ ] The sim prints per-day relation/stance/war/weariness/truce timelines for a seeded run.
- [ ] Every placeholder is pinned in JSON and REFERENCE.md. The *placeholder* markers are removed.
- [ ] The three feel targets are met, with sim output summarised in the report.
- [ ] The no-obliteration balance test is added, or the report says why not.
- [ ] Full suite + check_all are clean.
