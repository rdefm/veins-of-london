# 08 — Recipe book paging + close

**What to build:** In the HQ Lab, the recipe book can page through every recipe of the selected calc type. Next/previous page buttons show only when there's another page in that direction. A close button shuts the recipe book and returns to the default lab bench view.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/hq_lab_bench.gd` (recipe book by ore tab, `notebookRecipes` zone), `scenes/components/recipe_book_page.gd` (art-space rects, Pixelify font), `assets/hq/recipe-book-side-tabs-blank.png`, `tests/test_hq_lab_bench.gd`.

**Status:** ready-for-agent

- [ ] An ore tab with more recipes than fit on one page shows a next-page button; later pages show a previous-page button
- [ ] No page buttons when everything fits on one page
- [ ] Switching ore tab resets to page 1
- [ ] Close button returns to the default bench view
- [ ] Headless test: paging reveals recipes beyond page 1; close restores the bench view
