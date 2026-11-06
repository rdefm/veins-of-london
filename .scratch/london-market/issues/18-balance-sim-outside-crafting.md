# 18 — Balance sim: tune outside crafting

**What to build:** Run the 3-seed faction economy sim, then tune the outside-craft numbers (x, y, daily cap, skill/tier penalty, wallet floor) until the targets hold. Check whether outside buyers starve specialists of ore; if so add a per-ore specialist reserve. Optional cleanup if the human agrees: rename `independentsOreShare`, a supply multiplier that now sits at 1.5, to a name that says so (for example `independentsOreSupplyMult`), with data, code, validator, tests and REFERENCE.md updated.

**Blocked by:** 17.

**Relevant files:** `scripts/sim_faction_economy.gd` and `scripts/sim_faction_economy_impl.gd`, `data/market.json`, `data/factions.json`, `.scratch/london-market/balance-report.md` (ticket 14 section is the baseline), REFERENCE.md §3.13.

**Status:** ready-for-agent

- [ ] No good pinned at min or max price for 5 or more days across 3 seeds (Keystone excluded)
- [ ] Item named share stays 65-75% across 3 seeds
- [ ] Conclave and Network shortfalls are not permanent
- [ ] Turf, rivalry and diplomacy stay healthy (no zero-turf faction, no runaway leader)
- [ ] Wallet growth reported, not fixed
- [ ] Before and after tables appended to `balance-report.md`
- [ ] Rename question put to the human before any rename is done
