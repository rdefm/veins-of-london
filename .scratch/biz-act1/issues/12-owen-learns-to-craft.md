# 12 — Owen learns to craft

**What to build:** Once Owen is cultivating level 2, James has joined, and the home has a Workshop, a one-time event has Owen start learning to craft, unlocking Production for him. The player can swap him between Cultivation and Production freely; the change takes effect at the next block end. While he crafts, his veins keep their assignment but go untended. Not required for Act 1.

**Blocked by:** 03 — Per-block staff step; 08 — Beats 4–5

**Relevant files:** `systems/contacts.gd`, `systems/rooms.gd`, `systems/events.gd`, `systems/time_system.gd` (rollover check), `data/events/`, `tests/test_contacts.gd`, `tests/test_rooms.gd`; spec §"Owen's crafting event".

**Status:** ready-for-agent

- [ ] Trigger: Owen `cultivatingSkill ≥ 2` AND James recruited AND `workshop` in `home.rooms`; checked at event completion and rollover; plays once
- [ ] Completion makes Production available to Owen
- [ ] Swap free and immediate (next block end); veins keep their list with no active cultivator while he crafts
- [ ] Owen's crafting capped at 3
- [ ] New prose flagged `PROSE-REVIEW:`; CODEMAP.md updated
