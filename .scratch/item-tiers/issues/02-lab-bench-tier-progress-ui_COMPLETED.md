# 02 — Lab bench shows tier and progress bar

**What to build:** The Lab bench experiment UI shows each found item's current tier and a progress bar, and an experiment visibly adds progress on success / nothing on failure.

**Blocked by:** 01 — Tier state and progress-bar experiments.

**Relevant files:** lab bench screen(s) (find via `CODEMAP.md`, grep `Bench.refine`), `systems/bench.gd`, `tests/test_hq_lab_bench.gd`, `tests/test_lab_bench_confirm_modal.gd`, `docs/ui-vision.md`. Screens never mutate state.

**Status:** ready-for-agent

- [ ] Tier + bar rendered per item; updates after each experiment
- [ ] Confirm modal reflects new semantics (progress, not guaranteed tier)
- [ ] Existing lab bench tests updated and passing
- [ ] Human on-device check list in report (bar fill, tier-up feedback, max-tier state)
