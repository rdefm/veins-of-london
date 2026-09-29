# 08 — Faction Monday guard bill

**What to build:** On the rollover into a Monday, each faction pays `weeklyWage` per guard on its veins from `resources`, as much as it can cover.

- Guards are kept in priority order (the reverse of the shared drop order).
- Unfunded guards walk immediately: extras on the least valuable veins first, then tier guards (`guarded` → `warded`).
- There's no grace and no menu, and `resources` never goes negative.
- Faction veins claimed at `guarded` pay nothing on the claim day; they're billed from the next Monday.
- In old saves, faction guards are first billed on the next Monday.
- **Order:** the bill runs after faction industry income and before faction security upgrades, so the security spend sees post-wage cash.

**Blocked by:** 01 — Guard upkeep prefactor.

**Relevant files:**
- `systems/guard_upkeep.gd` (or `systems/factions.gd`), `systems/time_system.gd` (faction steps: industry income, `Factions.apply_security_upgrades`)
- `systems/factions.gd`, `systems/faction_sim.gd` (industry income), shared drop + value-order helpers from 01
- `tests/test_factions.gd`, `tests/test_time_system.gd`
- CODEMAP.md
- Spec §Faction guard upkeep (Monday bill), §Rollover order; REFERENCE.md §1.8, §3.1

**Status:** ready-for-agent

- [ ] A funded faction's `resources` drop by 500 × its guards, on Mondays only
- [ ] A broke faction loses extras from its least valuable veins first, then tier guards; `resources` stays ≥ 0
- [ ] The bill runs after industry income and before security upgrades
- [ ] A newly claimed `guarded` vein isn't billed on its claim day
- [ ] REFERENCE §1.8 and §3.1 updated
