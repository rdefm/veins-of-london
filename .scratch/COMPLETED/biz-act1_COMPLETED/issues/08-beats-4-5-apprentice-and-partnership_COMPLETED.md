# 08 — Beats 4–5: apprentice and partnership

**What to build:** Beat 4 asks for Owen at cultivating level 2 and a Workshop in the player's home — both live checks, shown as ToDo checklist items (an existing Workshop counts; losing it un-meets the goal). Meeting it unlocks the partnership scene: James joins fully, becomes recruited (idempotent if already recruited), his crafting skill is set to 5 (data value) and Production becomes available to him.

**Blocked by:** 07 — Beat 3: Owen arrives

**Relevant files:** `systems/objectives.gd`, `systems/todo.gd`, `systems/contacts.gd` (`recruit`), `systems/home.gd` (`home.rooms`), `data/objectives.json`, `data/constants.json`, `data/events/`, `tests/test_objectives.gd`, `tests/test_todo.gd`; spec §"Questline and objectives" (Beats 4–5).

**Status:** ready-for-agent

- [ ] Beat 4 evaluator: Owen `cultivatingSkill ≥ 2` AND `workshop` in `home.rooms`, both live
- [ ] ToDo shows Owen's level and Workshop as checklist items
- [ ] Beat 4 met → partnership scene
- [ ] Scene: James recruited, `craftingSkill` = data value (5), Production available to him; no double effects if already recruited
- [ ] Tests: prior Workshop satisfies Beat 4; tier move wiping Workshop un-meets; James pre-recruited → scene plays cleanly
- [ ] New prose flagged `PROSE-REVIEW:`; CODEMAP.md updated
