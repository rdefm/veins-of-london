# 07 — Cold Feet (guaranteed legIt + event exit option)

**What to build:** In combat, Cold Feet makes a guaranteed `legIt` for the whole squad. In events, an option flagged as a hidden exit shows only when the player holds Cold Feet, and spends it when taken (brainstorm §4). It stays player-only (`loadout.allyExcluded`).

**Blocked by:** 01

**Relevant files:** `systems/combat_rounds.gd`, `systems/events.gd`, `systems/event_items.gd`, `systems/loadout.gd`, `data/constants.json`, `scenes/screens/event.gd`, `tests/test_combat_rounds.gd`, `tests/test_events.gd`; REFERENCE §3.7b, §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] legIt always succeeds when Cold Feet is used
- [ ] Event exit-flag option is hidden without the item, and shown and spent with it (Dial payment works)
- [ ] REFERENCE §3.9a documents the exit flag
