# 13 — Retire stand-in supply; civilian demand; Independents slice

**What to build:** Market supply becomes real: recorded player and faction activity plus an Independents slice. `standInSupply` is removed. Stand-in demand is renamed civilian demand (permanent, still Ticker-scaled for items). One knob `independentsShare` sets the fraction of London volume that is steady independent supply, balanced by matching civilian demand, and credits the `independents` producer in Shares. At 0, the slice and the Independents row vanish. `normalStock` and the dump threshold get placeholder retunes (final pinning in 17).

Spec: §Independents slice, §Module layout (Market), Further Notes.

**Blocked by:** 11 — Faction buying/selling + real cash; 04 — Shares core.

**Relevant files:**
- `systems/market.gd` (`_stand_in`, `daily_reprice`, `resting_stock`, `_annotate_day`), `data/market.json`
- `systems/shares.gd`, `scenes/phone_apps/ticker_app.gd` (demand-driver labels)
- Tests: `tests/test_market.gd`, `tests/test_shares.gd`
- REFERENCE.md §3.13

**Status:** ready-for-agent

- [ ] No `standInSupply` in code or data; civilian demand named as such
- [ ] `independentsShare` 0 removes slice and row
- [ ] Above 0, shares across all producers sum to 100%
- [ ] Idle London prices stay sane over a seeded multi-day run
- [ ] REFERENCE.md + CODEMAP updated
