# 02 — Illustrated recipe pages with side ore tabs

**What to build:** Replace the Recipes notebook's card list with the brown ring-bound page. Five coloured side tabs select ore types; each page presents up to four found recipes, and tapping one uses ticket 01's craft overlay.

**Blocked by:** 01 — Tap a recipe to craft above the book.

**Status:** ready-for-agent

**Relevant files:** `assets/hq/recipe-book-side-tabs-blank.png` (**runtime page**), `assets/hq/recipe-book-side-tabs-draft.png` (**approved composition and pixel-lettering reference**), `assets/hq/lab-bench-with-equipment_portrait.png`, `scenes/screens/hq_lab_bench.gd`, `scenes/modals/lab_bench_recipe_book_modal.gd`, `scenes/components/modal_layer.gd`, `scenes/components/ore_glyphs.gd`, `scenes/components/item_icons.gd`, `systems/bench.gd`, `data/ore_types.json`, `data/recipes.json`, `docs/ui-vision.md` §7, `docs/ART-BIBLE.md` §§1–4, `docs/hq-diorama-vision.md` §5.2, `docs/REFERENCE.md` §1.3 and §3.5, `CODEMAP.md`. Add focused book-view tests under `tests/`.

- [ ] The Recipes notebook opens the **side-tab** page, not the top-tab asset or the placeholder-text draft. The blank asset is displayed without cropping its binding or tabs at supported portrait sizes; the book gets enough room for four readable entries and usable touch targets.
- [ ] Right-side tabs, top to bottom, map to time, physics, life, fate, emotion. Overlay a live ore glyph in each blank tab centre, expose a clear selected state, and make each tab tappable.
- [ ] Show found recipes only, filtered by ingredient ore. A two-ore recipe appears once in each matching ore tab. Render up to four recipes per page with live `ItemIcons` art, name and a shortened display of the existing description; page controls expose the rest without losing the selected tab. Empty ore tabs get a clear empty state. No new recipe mechanics or prose.
- [ ] Tapping any entry opens ticket 01's craft/refine overlay; returning preserves ore tab and page. All displayed facts update after crafting or refining.
- [ ] Bundle and apply a book-scoped pixel-style font visually matching the lettering in `recipe-book-side-tabs-draft.png`; live text stays live. The user's font override supersedes the shared-font restrictions **for this book only**. Record that exception in `docs/ui-vision.md` and `docs/ART-BIBLE.md`; preserve other screens' typography. Include the font's redistribution license in the repo if sourced externally.
- [ ] Headless tests cover ore filtering, two-ore placement, four-entry paging, empty state, selection/return, and asset/font loading. Touched GDScript passes immediate syntax checks and the full suite under the installed Godot 4.7 console binary. Update `CODEMAP.md` for any changed file responsibilities.

**On-device check:** At narrow and tall phone sizes, all five side tabs, glyphs, four entries, page controls and book lettering remain legible and tappable; the selected recipe overlay sits above the page.
