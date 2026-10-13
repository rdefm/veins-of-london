# 08 — Collective perks

**What to build:** Collective relations pay off in Collective turf. Friendly: Neighbourhood watch lowers raid odds on the player's turf veins. Partner: on days the player skips them, members tend those turf veins (through the existing tend path). Sworn: a one-off whip-round bailout fires before a forced home downgrade.

**Blocked by:** 07 — Perks core

**Relevant files:** `systems/perks.gd`, `data/faction_perks.json`, `systems/raiding.gd` (raid odds), `systems/cultivating.gd` (tend path), `systems/time_system.gd` (daily step for skipped-vein tending), `systems/home.gd` (`change_tier` / arrears downgrade), `tests/test_raiding.gd`, `tests/test_perks.gd`, home tests. REFERENCE.md Perks §.

**Status:** ready-for-agent

- [ ] Watch reduces raid odds on veins in Collective control (full) / foothold (reduced); no effect elsewhere
- [ ] Partner tending tends skipped turf veins once per day through the existing tend function
- [ ] Whip-round fires once per game before a forced downgrade and is recorded in state
- [ ] Tests go through the raid-odds, tend and home public functions
