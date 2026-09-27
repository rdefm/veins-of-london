# 144 — Quantity slider, used for crafting

**What to build:** A reusable quantity slider component replaces the +/− stepper for crafting batch size, on the lab bench confirm and in the recipe book. It starts at 1 and maxes at the largest batch the player's current (unstashed) calc allows — the limiting ingredient decides. With nothing craftable, the slider/confirm is disabled with the existing reason. Screens still set quantity through the crafting system, never state directly.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/map_card_style.gd` (`stepper` ~L235 — new slider sits beside it), `scenes/modals/lab_bench_confirm_modal.gd` (~L46-56), `scenes/modals/lab_bench_recipe_book_modal.gd` (~L35), `systems/crafting.gd` (`get_craft_qty`, `adjust_craft_qty` — add a set/max helper); REFERENCE.md §3.5 "Crafting & the Dial"; `docs/ui-vision.md` for styling.

**Status:** ready-for-agent

- [ ] System helper returns max craftable batch for a recipe from current ore; tested incl. 0 and multi-ingredient limits
- [ ] Setting qty clamps to 1..max; tested
- [ ] Lab confirm and recipe book use the slider, default 1; total cost label follows it
- [ ] Human on-device: drag the slider — max equals what your ore allows, total updates live, Confirm crafts that many
