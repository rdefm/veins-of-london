# 08 — Prototype on the lab plate + known-recipe book

**What to build:** The Debug app launches the bench prototype on the live lab bench art instead of the card list.

- **Plate.** It is the same portrait `labBench` plate as the real Lab zone, scaled and banded the same way.
  - The jar count badges show the prototype's calc pool, not the player's real orichalchum.
  - All four apparatus are shown, whatever the player actually knows.
  - A back/exit control leaves the prototype as today.
- **Book.** Tapping the recipe-notebook zone opens a recipe book that looks like the real lab recipe book.
  - It lists **known recipes only**.
  - "Known" is new prototype state, with one recipe (`healingSalve`) known at start.
- **Recipe page.** Tapping a known recipe opens its page, showing:
  - the current best rank;
  - a quantity slider and an auto-craft button at best rank, with the cost per craft shown as today. Auto-craft is disabled until a rank exists or when the batch is unaffordable;
  - a "Craft manually" button, present but disabled (ticket 09 wires it).
- **Debug back page.** The book has a back page holding every debug control:
  - skill slider and "use real skill";
  - bonus type;
  - per-recipe hint level toggles;
  - per-recipe known/unknown toggles;
  - refill pool;
  - Rewind;
  - the ledger.

Manual runs are knowingly unavailable between this ticket and 09. The old run card and plan editor are removed here, not kept behind a chip.

Still fully sandboxed: no real inventory, XP, recipe tiers or `labBenchNav` state is touched.

**Blocked by:** 07 — Remove chart slice

**Relevant files:**
- `scenes/screens/bench_prototype.gd` (rebuilt around the plate)
- `scenes/screens/hq_lab_bench.gd` (plate layout, bands, badges, zone tap handling: the pattern to follow)
- `HqDiorama` component (`build`, `zone_at`, `region_rect`)
- `data/hq_visuals.json` (`labBench` plate, regions `notebookRecipes`, `ore_*`, apparatus regions)
- `systems/lab_bench_nav.gd` (region prefixes)
- `scenes/modals/lab_bench_recipe_book_modal.gd`, `scenes/modals/lab_bench_recipe_detail_modal.gd`, `scenes/modals/lab_bench_modal_helpers.gd` (look to reuse, not logic)
- `scenes/modals/modal_registry.gd` (register any new prototype modals)
- `systems/bench_prototype.gd` (known-recipe state + setters, `batch`)
- `data/bench_prototype.json` (initial known list)
- `tests/test_bench_prototype.gd`
- `CODEMAP.md`
- docs/ui-vision.md (book/card look)

**Status:** ready-for-agent

- [ ] Opening the prototype from the Debug app shows the lab plate with pool-count jar badges
- [ ] The book lists only known recipes. Toggling a recipe known/unknown on the debug page adds it to or removes it from the list
- [ ] The recipe page shows best rank, slider + auto-craft with cost per craft, and a disabled "Craft manually"
- [ ] Auto-craft logs to the ledger and spends pool as before
- [ ] Debug page: skill, bonus type, hints, known toggles, refill, Rewind and ledger all work
- [ ] Tests cover known-recipe state (default, toggle, the list helper filters correctly)
- [ ] The screen holds no logic; all state changes go through system funcs
- [ ] CODEMAP updated; check_all + full suite green
- [ ] On-device checklist in the report (plate scale, badge legibility, book look, back page reachable)
