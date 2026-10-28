# 04 — Lab notebook: step section only, controls above the book

**What to build:** In a docked manual Lab run, the notebook shows only its first section — step header, step box, step text and band track. Everything that currently sits lower on the page moves out:

- **Prev / Next / Finish** become standard card buttons (the shared map-card button look, not ink-on-page) in the freed gap between the Press and the book. Same rules as now: Prev/Next only when a step exists in that direction; Finish disabled in the same lesson case.
- **"Use <item>"** bench-effect buttons (and their "· N left" running status) sit in the same gap with the nav buttons.
- **Run notice / lesson status lines** show as a notice line in that same gap, not on the page.
- The shorter book still never sits under the nav bar; the after-Finish result card is unchanged.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` (`_STEP_*` geometry ~l.43–55, `_dock()`/docked layout ~l.672–725, `_build_notebook()` ~l.754, `_effect_buttons()` ~l.929, `_ink_button()`)
- `scenes/components/recipe_book_page.gd` (strip crop / art-space rects)
- `scenes/components/map_card_style.gd` (card buttons, footer)
- `systems/lab.gd`, `systems/lesson_session.gd` — read only
- `docs/ui-vision.md` (card button family)
- `CODEMAP.md` rows for touched files

**Status:** ready-for-agent

- [ ] Docked notebook crop ends after the step band; no buttons or status drawn on the page
- [ ] Prev/Next/Finish as card buttons above the book, same visibility/disabled rules as before
- [ ] Use-item buttons (and running-effect status) above the book
- [ ] Run notice / lesson status shown as a notice line above the book
- [ ] Book never under the nav bar; result view after Finish unchanged
- [ ] Existing Lab/lesson tests still pass; syntax check clean; CODEMAP updated
- [ ] Human on-device check: book height, button placement in the gap, notice legibility, lesson run
