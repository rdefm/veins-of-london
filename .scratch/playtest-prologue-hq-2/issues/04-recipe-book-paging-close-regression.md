# 04 — Recipe book paging and close don't work on device (regression)

**What to build:** playtest-prologue-hq 08 was meant to add these, but on the latest build the player still can't turn to a second page of recipes for a calc type, and there is no way to close the recipe book. Find out why the shipped change isn't reaching the player, then make it work:
- Next/previous page buttons show only when there's another page in that direction.
- A close button returns to the default lab table view.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/hq_lab_bench.gd` (recipe book by ore tab, `notebookRecipes` zone), `scenes/components/recipe_book_page.gd`, `assets/hq/recipe-book-side-tabs-blank.png`, `tests/test_hq_lab_bench.gd`; commit `2cf9d895` (ticket 08 implementation).

**Status:** ready-for-agent

- [ ] Root cause of the on-device failure stated in the report (e.g. buttons off-screen, hidden behind art, hit area blocked, wrong page size)
- [ ] An ore tab with more than one page shows a working next-page button; later pages show previous
- [ ] Close button visible and returns to the default bench view
- [ ] Headless test covers the failure mode found (not only the logic ticket 08 already tested)
