# 06 — HQ Lab bench: table fills screen width

**What to build:** `scenes/screens/hq_lab_bench.gd::_refresh()` sizes its
clipping `frame` (and the `HqDiorama` inside it) to a hardcoded
`stop_width × plate_height` (currently 306×408, derived from the 390-wide
design baseline) and positions it at `Vector2.ZERO` — it never anchors or
scales to the actual runtime viewport the way most other screens do via
`UI.anchor_full_rect`/`UI.anchor_top_wide`. Confirmed by report: the table
image reads as noticeably smaller than the screen rather than filling it.
Make the frame scale/anchor to the real available width so the table plate
reads as full-width on-device, keeping the existing stop-panning behaviour
(`LabBenchNav`/`_pan_diorama_to()`) intact.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Lab bench table plate visually fills the screen's actual width at runtime, not just the 390px design baseline
- [ ] Stop-to-stop panning (arrow buttons, `_pan_diorama_to()`) still works correctly at the new scale
- [ ] Region tap-hit-testing (`region_rects()` / `_on_diorama_gui_input()`) still lines up with the rendered (scaled) regions
- [ ] No regression to `hq_floorplan.gd`/`hq_door.gd` or other `HqDiorama` consumers, which are out of scope for this ticket
