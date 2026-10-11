# 05 — Story row, tutorial Rest pointer, ToDo agreement

**What to build:** The first active objective from the ToDo questline sections appears as one Story row with exactly ToDo's wording. Its action goes to the relevant place (contact thread, Map, unit) or to ToDo when there's no better target. Tutorial objectives that need time to pass get a data-driven action pointing at HQ Rest with an explanation ("Rest at HQ to wait for Archie's text"). ToDo's "nothing pressing" state and the Story tier always agree.

**Blocked by:** 01 — Tracer: DailyBrief projection + Today card.

**Relevant files:** `systems/todo.gd` (`get_questline_sections`, `_display_text`), `systems/objectives.gd`, `data/objectives.json`, `scenes/phone_apps/todo_app.gd`, `systems/time_system.gd`, HQ zone navigation, `systems/daily_brief.gd`, `data/daily_brief.json`, `tests/test_daily_brief.gd`, `tests/test_todo.gd`, `tests/test_objectives.gd`. REFERENCE.md §3.11 "Tutorial flow", §3.1.

**Status:** ready-for-agent

- [ ] Story row text equals ToDo's active objective text
- [ ] Per-objective action target in data; fallback is ToDo
- [ ] Wait-for-time tutorial objectives point to HQ Rest with explanatory consequence
- [ ] Test: ToDo "nothing pressing" ⇔ no Story row
- [ ] Story counts toward `badge_count()`
