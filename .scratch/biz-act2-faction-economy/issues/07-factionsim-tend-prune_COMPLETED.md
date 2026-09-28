# 07 — FactionSim: tend + real prune

**What to build:** Faction veins produce real ore. A new FactionSim system (static funcs, pure state) runs daily from day 1. Each faction vein has a daily tend chance driven by the faction's `cultivateSkill`; on success growth rises by the player's cultivate gain at that skill. The old off-screen prune-back becomes a real prune: same threshold and chance rule, with a per-archetype depth, yielding ore by the player's prune-yield formula into faction holdings and crediting the faction's ore share. Producers (Collective, Firm) cultivate hard; the Guild barely. The vein cash trickle is removed. Collapse at zero growth remains the only death (ADR 0004).

Spec: §Vein tending and pruning, §Rollover order (steps 1–3).

**Blocked by:** 01 — Faction holdings + real shops; 04 — Shares core.

**Relevant files:**
- New `systems/faction_sim.gd`; `systems/sites.gd` (`roll_faction_vein_growth`, prune-back consts), `systems/factions.gd` (`apply_vein_income` removed)
- `systems/cultivating.gd` (`cultivate_gain`, `prune_yield`, `prune_resulting_growth`, `get_cult_chance`)
- `systems/time_system.gd` (⑤c / ⑤e), `data/factions.json` (`cultivateSkill`, prune depth)
- Tests: new `tests/test_faction_sim.gd`, `tests/test_factions.gd`, `tests/test_time_system.gd`
- REFERENCE.md §1.8, §3.1, §3.4; `docs/adr/` 0004; CODEMAP new row

**Status:** ready-for-agent

- [ ] A tended faction vein outlives the old ~14-day decay
- [ ] A prune adds ore to holdings and credits the faction's ore share
- [ ] Collapse at zero still deletes the vein
- [ ] Vein income step gone
- [ ] Seeded Rng for tend
- [ ] REFERENCE.md + CODEMAP updated
