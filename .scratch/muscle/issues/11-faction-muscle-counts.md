# 11 — Faction muscle counts

**What to build:** Factions run the same muscle economy in counts by level. Faction veins and stockpiles hold `guards: [n1..n5]`; each faction has a muscle Reserve (counts by level) and an injured list. `factions.json` gains per-faction `muscleOdds` (hire level odds) and `reserveGuards` (Reserve target). Daily security buy order: lock → ward → fill vein posts to cap 4 (highest vein value first) → stockpile to `stockpileGuards` → Reserve to `reserveGuards`; each hire rolls `muscleOdds` and needs the existing wage reserve. Wages use the same level table; unpaid walk-off goes lowest level first across vein posts → stockpile → Reserve. Faction resist/repel use count-by-level weights (no officer). No faction XP or training.

Removed: faction `extraGuards`, `maxExtraGuardsPerVein` (replaced by post cap 4), and the faction `guarded` tier.

**Blocked by:** 05 — Weighted resist/repel and Security score.

**Relevant files:**
- `systems/muscle.gd` (`faction_guards_at`, `faction_reserve`, `faction_hire`)
- `systems/factions.gd` (`apply_security_upgrades`, `_hire_stockpile_guard`, `_hire_extra_guard`), `systems/faction_sim.gd` (`stockpile_guard_target`, `stockpile_guards`, `set_stockpile_guards`), `systems/guard_upkeep.gd` (`faction_max_extra_guards`, `faction_guard_count`, `faction_can_hire`, `pay_faction_monday_bills`), `systems/cultivating.gd` (faction branch of `vein_guard_count` / `vein_raid_resist`)
- `data/factions.json`, `data/vein_security.json`
- `systems/network_handler.gd`, `systems/combat_prep.gd`, `autoload/GameState.gd` (grep consumers / initial faction state)
- Tests: `tests/test_factions.gd`, `tests/test_faction_sim.gd`, `tests/test_guard_upkeep.gd`, `tests/test_network_handler.gd`
- REFERENCE.md §1.8 (faction guard hiring/wages); CODEMAP.md

**Status:** ready-for-agent

- [ ] Faction vein/stockpile guard count = Σ level counts; no `extraGuards` / faction `guarded` tier / `maxExtraGuardsPerVein` left in code or data
- [ ] Buy order honoured, post cap 4, highest-value vein filled first, Reserve fills to `reserveGuards`
- [ ] Hire level distribution follows `muscleOdds` over a seeded run
- [ ] Faction bill = Σ counts × level wage; walk-off lowest level first in the specified place order
- [ ] All-L1 faction parity with today's resist/repel
