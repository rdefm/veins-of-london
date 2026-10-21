# 09 — Manual craft notebook step panel

**What to build:** During a manual craft, the lab plate moves up slightly. The top jars must stay fully visible. The freed space goes to the recipe-step panel at the bottom. That panel uses the top strip of the blank recipe-book page art, with the step written in the same font as the recipe book. Next/previous arrows on the notebook browse the recipe's steps; the current step stays marked as the active one.

**Blocked by:** 08 — Recipe book paging + close (same screen; reuse its page-button look).

**Relevant files:** `scenes/screens/hq_lab_bench.gd` (Craft manually docks the book; plate layout), `scenes/components/recipe_book_page.gd` (font loader), `assets/hq/recipe-book-page-blank.png`, `assets/hq/lab-bench-with-equipment_portrait.png`, `systems/lab.gd` (`pending_step`, `known_procedure`), `tests/test_hq_lab_bench.gd`.

**Status:** ready-for-agent

- [ ] Plate shifted up; top jars fully on screen at phone width
- [ ] Step panel uses the top of recipe-book-page-blank art and the book font
- [ ] Arrows browse procedure steps; the active (pending) step is visually distinct, and browsing never changes it
- [ ] Arrows hidden/disabled at the first and last step
- [ ] Headless test: arrows change the displayed step without altering `pending_step`
