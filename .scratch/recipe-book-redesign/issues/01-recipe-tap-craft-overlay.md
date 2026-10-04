# 01 — Tap a recipe to craft above the book

**What to build:** From HQ → Lab table → Recipes notebook, tapping any found recipe opens a detail overlay above the still-visible book. The player chooses batch size and crafts there, then returns to the book. This works with the current found-recipe list before the illustrated page lands.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `scenes/modals/lab_bench_recipe_book_modal.gd`, `scenes/modals/lab_bench_confirm_modal.gd`, `scenes/modals/lab_bench_modal_helpers.gd`, `scenes/modals/craft_batch_result_modal.gd`, `scenes/modals/modal_registry.gd`, `scenes/components/modal_layer.gd`, `systems/bench.gd`, `systems/crafting.gd`, `tests/test_lab_bench_confirm_modal.gd`, `tests/test_modal_layer.gd`, `docs/hq-diorama-vision.md` §§5.2–5.6, `docs/REFERENCE.md` §1.3 and §3.5. The later page uses `assets/hq/recipe-book-side-tabs-blank.png`; `assets/hq/recipe-book-side-tabs-draft.png` is its layout reference. Design the overlay so ticket 02 can place it over that page.

- [ ] Each found recipe row is tappable. Its overlay shows the selected recipe's live icon/name, full description, ingredient costs and stock, success chance, effect, and current inventory count. Unfound recipes remain absent.
- [ ] Batch slider uses existing `Crafting` quantity/cost limits, updates quantity and total live, and disables Craft with the existing reason when unaffordable. Craft calls the existing batch action exactly once; no formula, ore, XP or time-rule change.
- [ ] Refine remains reachable for a found recipe, with existing costs, chance, blocked reason and outcome.
- [ ] Cancel/close and completion/result dismissal return to the book without losing its current position; the bench's gear-tap probe/craft flow still works.
- [ ] Headless tests cover selection, quantity changes, blocked crafting, batch result and return, plus refine access. Touched GDScript passes immediate syntax checks and the full suite under the installed Godot 4.7 console binary. If files under `scenes/` change ownership or new ones appear, update `CODEMAP.md`.

**On-device check:** A found recipe opens above the book; slider, Craft, result, close and Refine work without a jump back to the bench.
