# 01 — One tap fires twice

**What to build:** Since build 26-10-05, a single physical tap on device triggers its action twice, on every screen — e.g. tapping one protection on a vein buys both lock and ward, and tapping "continue" once in an event advances two cards so multiple text blocks appear at once. One tap must trigger exactly one action everywhere. Leading hypothesis: Playtest-11 moved most buttons to the shared tap-vs-drag button, which handles both the real touch event and Godot's touch-emulated mouse twin (`device == -1`) — the same root cause ticket 109 diagnosed in the lab bench. Confirm the cause, then fix it once in the shared input path rather than per screen.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/tap_button.gd`, `scenes/components/ui.gd` (button factories), `scenes/screens/hq_lab_bench.gd` (existing emulated-mouse guard, ticket 109), `scenes/components/touch_scroll_container.gd`, other touch handlers listed by grepping `InputEventScreenTouch` under `scenes/`, `tests/support/ui_sim.gd`, `project.godot` (`input_devices/pointing/emulate_mouse_from_touch`), `.scratch/0-bugfixes/issues/COMPLETED/109-diagnose-experiment-ore-apparatus-tap-noop_COMPLETED.md`, `.scratch/playtest-2026-10-04/issues/11-scroll-tap-vs-drag-cards_COMPLETED.md`

**Status:** ready-for-agent

- [ ] Root cause confirmed and noted in the commit/ticket
- [ ] A touch press/release followed by its emulated-mouse twin fires `pressed` once (test simulating both events)
- [ ] Real mouse clicks (desktop/editor) still work
- [ ] Other custom touch handlers that accept both touch and mouse audited for the same double-fire
- [ ] Human checks on device: buying one vein protection buys only that one; event "continue" advances one card per tap
