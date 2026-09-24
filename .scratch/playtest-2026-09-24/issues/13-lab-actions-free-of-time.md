# 13 — Lab: crafting and experiments cost no time block

**What to build:** Probing, refining, and crafting at the lab bench no longer consume a time block. Ore costs and XP unchanged. Time-cost labels on those actions disappear or read as free, and the actions stay available when the day's blocks are spent.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/bench.gd` (`probe`, `refine`), `systems/crafting.gd`, `scenes/modals/lab_bench_recipe_book_modal.gd`, `scenes/modals/lab_bench_modal_helpers.gd`, `scenes/modals/lab_bench_probe_result_modal.gd`, `scenes/components/ui.gd`; REFERENCE §3.5, `docs/M3-CALC-DISCOVERY.md` §7.

**Status:** ready-for-agent

- [ ] Probe/refine/craft don't advance time
- [ ] Not blocked by exhausted time
- [ ] No time-cost label on those actions
- [ ] Specs updated to match
