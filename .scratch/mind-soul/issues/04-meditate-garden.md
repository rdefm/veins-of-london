# 04 — Meditate (Soul workout) + Garden room

**What to build:** A Meditate action at HQ: Study's Soul twin, awarding 10 XP or 30 with a Garden.

The Garden is a new home room:
- £1000, min tier townhouse, bonus `soul`;
- it does nothing beyond raising Meditate XP;
- it is unavailable in a flat.

It's a meditation space: no soil, digging or horticulture vocabulary.

**Blocked by:** 03 — Study + dual-purpose Library.

**Relevant files:**
- new Soul system file
- `systems/home.gd` (`set_room_use`, tier gate)
- `data/home.json`
- `data/floorplans.json` / `data/hq_visuals.json`, if a slot/zone is needed
- the HQ screen / modal from 03
- home tests
- CODEMAP.md
- REFERENCE.md home rooms table, §3.7a

**Status:** ready-for-agent

- [ ] Meditate: 10 Soul XP without a Garden, 30 with one; 1 block; refused when exhausted
- [ ] Garden purchase: refused below townhouse; refused without £1000; succeeds otherwise and deducts the cost
- [ ] PROSE-REVIEW: Garden name/description, Meditate notifications
- [ ] REFERENCE.md + CODEMAP.md updated
- [ ] On-device: Garden is buyable in a townhouse and Meditate is reachable
