# 07 — Debug app: learn recipes

**What to build:** A "Learn recipes" section in the Debug app with:
1. A "Learn all at max" button: every recipe known, at the top rung and max rank.
2. A recipe picker plus a rank/level picker plus a "Learn" button that grants that recipe at that level.

Granting must go through the existing knowledge systems (grant rungs/knowledge as the real paths do), so the lab, recipe book, sellers, crafting and Production all see a consistent state.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/phone_apps/debug_app.gd`, `systems/debug_tools.gd`, `systems/recipe_knowledge.gd` (`grant_rung`, `rank_ceiling`), `systems/lab.gd` (`grant_*`), `systems/debug_start.gd`

**Status:** ready-for-agent

- [ ] Learn-all grants every recipe at max; tested
- [ ] Pick + level + Learn grants exactly that; tested
- [ ] Recipe book and crafting reflect the grant immediately
