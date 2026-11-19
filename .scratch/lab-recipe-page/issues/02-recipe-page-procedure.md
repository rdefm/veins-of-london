# 02 — Recipe page 1 on the notebook + bottom bar (nav, Craft manually, Rewind)

**What to build:** tapping a recipe in the book opens its page on the RecipeBookPage component (ticket 01 art) instead of the dark MapCardStyle card.

- **Page 1:**
  - Header repeating the list entry: icon in the frame, then name, cost, stock and best rank on the header lines.
  - Each known step written on the ruled lines ("1. Press · time ×5 · ≈ 50–98"). Insight steps show "?". Breath and talk-through tags are kept.
  - Ranges may use the existing band gauge for now; ticket 03 restyles them.
- **Ore tabs** stay visible and tappable.
- **Bottom bar on a recipe page:**
  - Row 1: ‹ Book · page counter · Prev/Next · Rewind.
  - Row 2: **Craft manually**.
- **Removals and interim:**
  - Remove the old dark recipe card.
  - Page 2 can be a stub until ticket 04 fills it, but the ladder region must stay reachable so the existing tests keep passing.
  - The batch controls move in ticket 05. Until then keep them reachable, e.g. on the page 2 stub.

**Blocked by:** 01

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` (`_build_recipe_card`, `_add_known_step`, `_step_text`, `_build_book` bottom bar, `_open_recipe`, `_dock`, `_add_rewind_controls`)
- `scenes/components/recipe_book_page.gd` (`place_on_line`)
- `systems/lab.gd` (`known_procedure`, `step_region`; read-only)
- `tests/test_lab_screen.gd`, `tests/test_hq_lab_bench.gd`
- `docs/hq-diorama-vision.md` §5.2 The two notebooks
- `CODEMAP.md` (lab bench row)

**Status:** ready-for-agent

- [ ] Recipe page draws on the notebook art; all text baselines sit on ruled lines at phone and tablet sizes
- [ ] Every recipe's procedure fits page 1 without scrolling (check the recipe with the most steps)
- [ ] ‹ Book returns to the same list page and tab; tabs jump to that ore's list
- [ ] Craft manually docks as today; Rewind opens the existing choice, is disabled when nothing can be paid, and is hidden in a lesson
- [ ] Recipe page holds its own page index (0/1), reset on opening a recipe
- [ ] Lab screen tests updated and passing; on-device check list in the report
