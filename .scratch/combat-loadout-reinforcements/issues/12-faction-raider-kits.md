# 12 — Faction raider kits from real stock

**What to build:** Raider kits remain a shared squad pool, capped at two units × every raider in the full roster (not just the first three active), within the faction's authored kit recipe quantities and actual held tier buckets. Units are chosen highest tier first, ties broken by the seeded RNG. Each used unit applies its actual tier's power and leaves faction stock immediately, before the daily stock update; unused units stay in stock. Non-fought faction raid-kit accounting is unchanged unless needed to prevent double spending.

**Blocked by:** 02

**Relevant files:** `systems/faction_sim.gd` (`raider_kit`, kit allocation), `systems/raiding.gd`, `systems/combat.gd`, `data/factions.json` (`raidKits`), `tests/test_faction_sim.gd`, `tests/test_raiding.gd`, `tests/test_combat.gd`. Update REFERENCE §3.7a and the faction-sim section with the change.

**Status:** ready-for-agent

- [ ] Kit size ≤ 2 × full roster and ≤ authored quantities
- [ ] Highest tier first; seeded tie-break reproducible
- [ ] Used units leave faction stock at once; no double spend with the daily kit burn
- [ ] Unit power reflects its tier
