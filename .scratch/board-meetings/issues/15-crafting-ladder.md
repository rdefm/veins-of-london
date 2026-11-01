# 15 — Crafting ladder (James)

**What to build:** James's **Crafting** ladder (crafting share of an item → new recipe tier → quality streak → signature item), with the condition types and premise checks it needs (crafting share, recipe tier, quality streak), plus any new reward kinds it introduces (e.g. recipe knowledge). Tier numbers are placeholders in data.

**Blocked by:** 05 — Monday meeting event + rollover + Act 1 hand-off; slice 1 (01–14) playtested and tuned

**Relevant files:**
- `systems/crafting.gd`, `systems/recipe_knowledge.gd`, `systems/shares.gd` (`record_craft`)
- `systems/objectives.gd`, `systems/board_meetings.gd`, `data/board.json`, `data/recipes.json`
- `tests/test_board_meetings.gd`, `tests/test_objectives.gd`
- Spec: stories 52, 73, §"Slicing"

**Status:** needs-triage

- [ ] New condition types with threshold tests
- [ ] Rungs open from real state; met rungs skipped
- [ ] Tiers and rewards in data; REFERENCE.md Board section updated
