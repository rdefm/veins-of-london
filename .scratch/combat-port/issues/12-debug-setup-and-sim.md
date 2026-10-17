# 12 — Debug setup and balance sim on the live engine

**What to build:** The Debug combat setup launches live fights with everything the prototype setup offered: player level override, enemy archetype/count/level, 0–2 allies with levels, sandbox loadout picks and backdrop/location. Live fights launched this way leave real state as the debug launcher does today.

The balance sim is rewritten to drive live `Combat` headless: seeded, naive vs reader policy, fog on/off, over a matchup grid, printing rounds mean/p90, win %, HP left %.

**Blocked by:** 05

**Relevant files:** `scenes/modals/combat_setup_modal.gd`; `scenes/phone_apps/debug_app.gd`; `systems/combat.gd` (`start_debug_combat`); `scenes/screens/combat_prototype.gd` (setup to lift); `scripts/sim_combat_balance.gd`; `scripts/sim_combat_balance_impl.gd`; `scripts/sim_combat_prototype_impl.gd`; `CODEMAP.md`; REFERENCE §3.7b

**Status:** ready-for-agent

- [ ] Debug setup covers every prototype setup option and launches a live fight
- [ ] The sim runs headless to completion on live `Combat` and reader beats naive in matched fights
- [ ] CODEMAP updated
