# 07 — Lab: select ore containers, tap an apparatus to experiment

**What to build:** On the lab bench, the player taps 1–2 ore containers to select them. Each selected container shows a clear visual cue. Tapping a selected container deselects it. While two are selected, tapping a third does nothing. With at least one selected, tapping an apparatus runs an experiment (probe) for that ore set and apparatus and shows the probe result. With none selected, tapping an apparatus shows a short hint to select an ore type first. None of this needs a notebook to be open first.

Playtest: tapping containers and apparatus did nothing. Suspected cause: `_run_apparatus` dispatches on `labBenchNav.mode`, so it is a no-op unless a notebook mode is active. Also check that the diorama region hit-testing (`_zone_at` vs the scaled/panned frame) actually hits the tapped container. `LabBenchNav.select_ore` currently replaces the oldest selection on a 3rd tap; the new rule is to ignore it.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` (`_on_diorama_gui_input`, `_zone_at`, `_on_zone_tapped`, `_run_apparatus`, `_label_ore_regions`, `_filter_and_label_apparatus_regions`)
- `systems/lab_bench_nav.gd` (`select_ore`, `tap_notebook`, modes/stops)
- `systems/bench.gd` (`can_probe`, `probe`, `probe_block_reason`)
- `scenes/components/hq_diorama.gd` (region rects, selection cue)
- `scenes/modals/lab_bench_probe_result_modal.gd`
- `data/hq_visuals.json` (`labBench` regions)
- `tests/test_lab_bench_nav.gd`, bench tests

**Status:** ready-for-agent

- [ ] Tapping an ore container selects it with a visible cue; tapping again deselects
- [ ] Maximum 2 selected; a 3rd tap is ignored (selection unchanged)
- [ ] Apparatus tap with 1–2 selected runs the probe when allowed and opens the result modal; if blocked, shows `probe_block_reason`
- [ ] Apparatus tap with 0 selected shows a hint to select an ore type first
- [ ] Works without first opening a notebook
- [ ] Tests cover select/deselect/cap rules and the zero-selection hint path; human on-device QA list in report
