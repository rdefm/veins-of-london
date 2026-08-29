# 88 — Map: fix recurring pinch-zoom drift (4th attempt)

**What to build:** Pinch-to-zoom on the Network map currently jumps around multiple times per second while pinching — reported 2026-08-28, against a build that already includes the most recent fix (#76, "anchor once per pinch segment", 2026-08-26). This is the fourth report of this exact symptom, after #23 ("fix pinch zoom anchor point"), #48 ("fix erratic pinch zoom"), and #76. Since three prior manual fixes haven't held, the priority this time is finding out *why* the existing tests didn't catch the regression, not just patching the symptom again.

**Where:** `systems/map_zoom.gd` (pure zoom math — `clamp_zoom`, `to_logical`, `scroll_target`), `scenes/components/map_canvas.gd` (pinch handling — `_update_pinch` and whatever anchors it per pinch segment per #76's fix), `tests/test_map_zoom.gd`, `tests/test_map_canvas.gd`.

**Blocked by:** None — can start immediately. Touches the same zoom system as #89 (new +/- buttons) — coordinate if worked in parallel, but neither blocks the other.

**Status:** ready-for-agent

- [ ] Re-read #23/#48/#76's diagnoses and confirm what each actually shipped is still present on current code (don't assume — verify).
- [ ] Reproduce the drift (pinch gesture jumping/jittering multiple times per second) and identify the actual mechanism causing it on current code — it may not be the same root cause #76 fixed.
- [ ] Fix the drift so a pinch gesture tracks smoothly and predictably to the anchor point under the fingers, matching #23's original intent.
- [ ] Add a regression test that actually exercises the failure mode found (not just a repeat of whatever #76's existing tests already cover, since those evidently didn't catch this) — simulate a multi-frame pinch sequence and assert zoom/scroll stay monotonic/stable rather than jumping.
- [ ] Manual check noted for the human: pinch-zoom in and out repeatedly and rapidly on a touch device and confirm the map tracks smoothly with no visible jumps.
