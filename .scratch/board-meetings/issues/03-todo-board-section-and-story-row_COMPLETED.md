# 03 — ToDo Board section + Today Story row

**What to build:** the chosen board goal shows up in the one existing tracker. The ToDo app gets a "Board" section listing the active goal's label, the tier reached so far and progress toward the next tier. `current_objective()` can return the board goal, and the Today card Story row shows it when no other questline step (Tutorial, Collective, …) outranks it.

**Blocked by:** 02 — Board core + Financial ladder (James)

**Relevant files:**
- `systems/todo.gd` — `get_questline_sections()`, `current_objective()`, `_display_text()`
- `systems/daily_brief.gd` — `_story_rows()`
- ToDo app screen (see `CODEMAP.md`), `data/daily_brief.json`
- `tests/test_todo.gd`, `tests/test_daily_brief.gd` (prior art)
- Spec: §"Modules" → Todo, DailyBrief

**Status:** ready-for-agent

- [ ] Board section lists the active goal with label, tier reached, progress to next tier
- [ ] Story row shows the board goal when no higher questline step is active; another questline's active step still wins
- [ ] No Board section/row when meetings aren't enabled or no goal is active
- [ ] Tests in the style of existing todo / daily brief tests
- [ ] On-device check block in report
