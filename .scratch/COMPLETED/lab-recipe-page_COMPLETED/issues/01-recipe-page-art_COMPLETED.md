# 01 — Recipe-page notebook art (edited copy of the side-tabs page)

**What to build:** a new blank recipe-page asset made by editing a **copy** of the existing side-tabs notebook art. Keep the rings, tabs, paper texture, slot 0's icon frame and its ruled lines (the header). Replace everything below the slot 0 divider (slots 1–3: icon frames, squiggles, dividers, stepped lines) with plain, evenly spaced ruled lines matching the existing line colour, thickness and paper texture down to the page bottom. The original art is not modified; list pages keep using it. Measure the new asset's ruled-line top edges and record them as a constant table for the recipe page (spec § Implementation Decisions › Art).

**Blocked by:** None — can start immediately

**Relevant files:**
- `assets/hq/recipe-book-side-tabs-blank.png` (source; copy it, don't edit it)
- `assets/hq/` (new recipe-page png beside it, plus its `.import`)
- `scenes/components/recipe_book_page.gd` (`PAGE_TEXTURE`; needs a way to load the alternate texture)
- `CODEMAP.md` (RecipeBookPage row: mention the second texture)

**Status:** ready-for-agent

- [ ] New png is 1024×1536, same palette, no visible seams or cloned-texture repeats
- [ ] Slot 0 header (frame, the lines at y 252/300/399/442 and the squiggle) is pixel-identical to the source
- [ ] Ruled lines below the header are evenly spaced, at roughly the header's 41–48 px line pitch
- [ ] RecipeBookPage can be built with either texture; line top edges recorded as a constant table
- [ ] Human visual check of the png before ticket 02 starts
