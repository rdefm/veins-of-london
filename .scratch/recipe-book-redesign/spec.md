# Recipe book: illustrated ore tabs

From HQ → Lab table → Recipes notebook, show an open page matching the brown ring-bound book on the bench. Use `assets/hq/recipe-book-side-tabs-blank.png` as the runtime page. `assets/hq/recipe-book-side-tabs-draft.png` is the approved layout and lettering reference; its placeholder words must not appear in-game.

Five coloured tabs protrude from the **right side**, top to bottom: time, physics, life, fate, emotion. Put a live ore glyph on each tab. Tapping a tab shows only found recipes using that ore. A two-ore recipe appears under both of its ore tabs. Four recipes fit per page; provide page navigation when a tab has more than four. Each entry has a live item icon, name and a short view of the existing recipe description. Tapping an entry opens an overlay above the book with batch quantity slider and Craft action. Keep Refine accessible for found recipes. Closing the overlay or craft result returns to the same book tab and page.

Book lettering uses a bundled pixel-style font visually matching the `ITEM NAME` and `Short description` placeholders in the draft. **Explicit user override:** this book-specific font is permitted despite `docs/ui-vision.md` §7's shared-font limit and ART-BIBLE's existing pixel-font scope. The implementation ticket records this exception in the relevant visual docs. Other screens retain their current fonts.

Keep all recipe data, discovery, crafting, refinement, costs, chances, state purity and time rules unchanged. No placeholder recipe copy becomes game content.
