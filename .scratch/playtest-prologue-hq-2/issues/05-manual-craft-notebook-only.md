# 05 — Manual-craft notebook: the notebook alone, bigger, side-tabs art

**What to build:** During a manual craft, the recipe-step notebook is shown on its own. It isn't set inside a white menu or modal, and it's bigger than it is now. It uses the real notebook art, `recipe-book-side-tabs-blank.png`, not the page with tabs across the top. The step text, the prev/next step arrows and the active-step marking from playtest-prologue-hq 09 all stay. The top jars on the plate must stay fully visible.

**Blocked by:** 04 — Recipe book paging and close don't work on device (same screen; reuse its page-button look).

**Relevant files:** `scenes/screens/hq_lab_bench.gd` (Craft manually docks the book; step panel; plate layout), `scenes/components/recipe_book_page.gd` (font, art-space rects), `assets/hq/recipe-book-side-tabs-blank.png`, `assets/hq/recipe-book-page-blank.png` (current art, to replace here), `systems/lab.gd` (`pending_step`, `known_procedure`), `tests/test_hq_lab_bench.gd`.

**Status:** ready-for-agent

- [ ] Step panel draws `recipe-book-side-tabs-blank.png`, with no white panel or modal around it
- [ ] Notebook visibly larger than now; text in the book font fits at phone width
- [ ] Top jars still fully on screen
- [ ] Step arrows and active-step marking still work; browsing never changes `pending_step`
- [ ] Headless test: step panel uses the side-tabs texture and has no modal backdrop
