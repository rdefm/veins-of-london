# 12 — Combat: rebalance player stats

**What to build:** A level-1 player with no items fighting a weak enemy (e.g. Territorial Scrapper) faces a real risk, not a guaranteed win. Tune player base combat stats (and level scaling if needed) so fights stay challenging without items across progression. Use a headless sim to pick numbers: target 60–80% win rate, player usually ending under 40% HP. Enemies untouched unless the sim shows the target is unreachable otherwise — ask first.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/constants.json`, `data/enemies.json`, `systems/combat.gd`, `systems/progression.gd`, `systems/combat_prototype.gd` (possible sim harness); REFERENCE §3.7, §3.7a.

**Status:** ready-for-agent

- [x] Sim + before/after results (win rate, end HP) noted under `## Comments`
- [x] Level-1 itemless vs weak enemy lands in the target band
- [x] Spot-check higher levels vs matched enemies stay challenging
- [x] REFERENCE numbers updated to match data

## Comments

Sim: `godot --headless -s scripts/sim_combat_balance.gd -- n=2000` (itemless, no allies, always Attack, full HP start, seed 12345). End HP = % of hpMax among wins.

Human decisions (2026-09-26): Scrapper was ~half as dangerous as the other L1 guards, so Scrapper hpBase 20→30 alongside the player change; add a `combatHpBonusByLevel` curve.

Changes: player hp 100→40, atk 5–12→3–7; Scrapper hpBase 20→30; `combatHpBonusByLevel = [0,0,0,55,55,140]` (applied as a delta on level-up).

| Matchup | Before win / median end HP | After |
|---|---|---|
| L1 vs Scrapper t1 | 100% / 85% | 73% / 20% |
| L1 vs Vein Guard t1 | 100% / 79% | 58% / 18% |
| L1 vs Dealer t1 | 100% / 80% | 60% / 18% |
| L1 vs street mugging (1–3) | 64% / 64% | 12% / 13% |
| L2 vs 1 guard t2 | 100% / 77% | 72% / 20% |
| L3 vs 2 guards t2 | ~100% | 71% / 16% |
| L4 vs 2 guards t3 | 99.5% / 43% | 75% / 17% |
| L5 vs 3 guards t4 | 21% / 12% | 66% / 12% |

Open: an L1 street mugging (forced after trades) is now ~12% wins itemless; the home-raid raider (hp35, atk 6–14) wasn't simmed. Old saves keep their stored hpMax 100 (no migration).
