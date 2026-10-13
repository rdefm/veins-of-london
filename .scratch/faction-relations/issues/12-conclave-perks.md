# 12 — Conclave perks

**What to build:** Friendly: legal cover, reducing barometer/police danger in Conclave turf. Partner: Conclave lawyers recover one vein lost in a raid, once, without a fight. Sworn: a barometer nudge action plus the Deep Vein lore flag.

**Blocked by:** 07 — Perks core

**Relevant files:** `systems/perks.gd`, `data/faction_perks.json`, turf modifier query in `systems/districts.gd`, `systems/barometer.gd`, `systems/vein_trade.gd` (no-price handover), `systems/raiding.gd` (record raid-lost veins), tests: barometer, raiding, `test_perks`. REFERENCE.md Perks §.

**Status:** ready-for-agent

- [ ] Danger reduction applies in Conclave control/foothold
- [ ] Lawyer recovery: player picks a raid-lost vein still held by the raider; it returns; one-time use recorded in state
- [ ] Sworn: nudge action (cost/cooldown in data) moves the barometer; Deep Vein flag set
- [ ] Tests through public functions
