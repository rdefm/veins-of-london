# 16 — Faction intel use + Network menu moves

**What to build:** Factions use the intel economy. They buy the same Network products (intel, privacy, disinformation, reduction) against the player and each other. A faction's intel on its target improves its target choice and raid odds, and disinformation distorts them. The Network's own market-rung menu goes live: it sells intel on a target to the target's enemies (raising their meters, with messages to the player when the target is them unless privacy is active), price-gouges the target, and leaks disinformation about it.

**Blocked by:** 15 — Network intel menu (player).

**Relevant files:** `systems/faction_ai.gd`, `systems/intel.gd`, `systems/network_handler.gd`, `systems/raiding.gd` (`raid_success_chance`, target pick), `systems/factions.gd` (`_pick_target_vein`, `rivalry_success_chance`), `systems/faction_sim.gd` / shop pricing (gouge), `tests/test_intel.gd`, `tests/test_faction_ai.gd`, `tests/test_raiding.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 23, 88, 92–93. REFERENCE.md §3.6a, §3.12.

**Status:** ready-for-agent

- [ ] Rollover test: the Network selling on the player raises a rival's meter on the player, but not while privacy is active.
- [ ] Test (seeded): higher attacker intel raises raid odds and picks higher-value targets. Disinformation inverts or lowers them.
- [ ] Rollover test: factions buy products under a budget, and the purchases show in meters and timers.
- [ ] A price-gouge raises Network prices to the target only.
- [ ] Faction intel purchases and decay sit in the rollover step order. REFERENCE and CODEMAP updated.
