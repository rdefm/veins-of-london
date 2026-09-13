# 109 — Diagnose: tapping ore container / apparatus during Experiments does nothing

**What to build:** New recipe discovery in the lab bench is currently unreachable: tapping an ore container and/or an apparatus during an experiment does nothing, with no feedback and no state change. This ticket is diagnosis only — identify the root cause and report back (what's broken, why, and what a fix would involve). Do not implement a fix as part of this ticket; the fix will be scoped separately (either folded into this ticket or spun off as a new one) once the cause is known.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [x] Root cause identified for why tapping an ore container during an active experiment attempt produces no visible effect.
- [x] Root cause identified for why tapping an apparatus during an active experiment attempt produces no visible effect (may be the same cause as the ore-container case, or distinct — confirm which).
- [x] Findings written up in this ticket's comments: what's broken, why, and a rough sketch of what fixing it would involve.
- [x] No code changes required for this ticket beyond what's needed to observe/confirm the cause (e.g. temporary logging), unless the fix is trivial enough to include — use judgement and note the decision in the writeup.

## Comments

### Diagnosis — 2026-09-13

Root cause: `scenes/screens/hq_lab_bench.gd::_on_diorama_gui_input()` accepts both
`InputEventScreenTouch` and left `InputEventMouseButton`, but does not ignore
Godot's touch-emulated mouse events (`device == -1`). With
`input_devices/pointing/emulate_mouse_from_touch` enabled, one physical press is
handled twice.

Ore-container effect: the first press calls `LabBenchNav.select_ore()` and
selects the ore; the emulated twin immediately calls it again and toggles the
same ore off. Final state and label therefore look unchanged.

Apparatus effect: no separate apparatus defect found. The doubled ore press
leaves `selectedOre` empty, so `_run_apparatus()` returns at its explicit empty-
selection guard. A pre-armed apparatus tap successfully spent ore and opened
`lab_bench_probe_result`; the apparent apparatus no-op is downstream of the ore
double-toggle.

Deterministic diagnostic harness results:

- touch press alone: ore selected;
- emulated mouse press alone: ore selected;
- touch + emulated mouse presses: ore selected then deselected;
- full paired ore/apparatus sequence: ore unchanged, no result modal;
- pre-armed apparatus: probe succeeds.

Fix sketch: ignore emulated mouse events before they can mutate `_press_zone` or
call `_on_zone_tapped()`, matching `MapCanvas._gui_input()`'s existing
`event.device != -1` guard. Keep real mouse input for desktop. Add regression
coverage for touch + emulated-mouse ordering and the full experiment sequence.
Also cover release/drag ordering so the filter cannot leave stale `_press_zone`.

Decision: diagnosis-only scope retained. Temporary diagnostic test/runner were
removed; no production code changed.
