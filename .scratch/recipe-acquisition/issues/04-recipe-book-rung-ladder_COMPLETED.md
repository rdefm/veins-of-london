# 04 — Recipe book rung ladder

**What to build:** The live lab recipe book's reserved, empty ladder region on each recipe page now shows the recipe's knowledge ladder: base / Hint I / Hint II / Master. Each rung shows its state and the rank ceiling it gives. Owned rungs are marked vague or exact. Locked rungs show where they come from and what gates them ("sold by Wren", "needs Guild Partner", "James — relation N"). The master rung shows its cryptic pointer, or "???" when unassigned.

Spec: `.scratch/recipe-acquisition/spec.md` § Implementation Decisions — "Recipe book"; § User Stories 31–33; prereq P4 rule 20.

**Blocked by:** 02 — Sellers, gates, prices and buying knowledge.

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` (recipe page; empty ladder region)
- `scenes/components/recipe_book_page.gd` (art-space rects, book font)
- `systems/recipe_knowledge.gd` (rung status, `seller_of`, `gate_met`, master table) — add a pure read helper giving per-rung display rows if that keeps logic out of the screen
- `data/recipe_knowledge.json` (lock-reason / source strings, master pointers)
- `tests/test_recipe_knowledge.gd` (display-row helper, if added)
- `CODEMAP.md` (hq_lab_bench row)

**Status:** ready-for-agent

- [ ] Every known recipe page renders four rungs with state, ceiling and source/lock reason. The master rung shows its pointer or "???".
- [ ] Buying, granting or experimenting a rung updates the page on the next `state_changed`, with no re-open needed.
- [ ] All strings come from data. Any per-rung logic lives in a system helper (tested), not the screen.
- [ ] PROSE-REVIEW: lock-reason strings, master pointers.
- [ ] On-device QA block in report.
