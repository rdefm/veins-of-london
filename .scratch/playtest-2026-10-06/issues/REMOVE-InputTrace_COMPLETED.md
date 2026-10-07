# Remove InputTrace diagnostic (temporary)

Temporary on-device input tracer added to diagnose tickets 01–03 (double tap, scroll-release opens item, dead map hamburger). Remove once the real fix is in and verified on device.

## Steps

1. Delete `autoload/InputTrace.gd` (and `autoload/InputTrace.gd.uid` if Godot created one).
2. In `project.godot` `[autoload]`, delete the line:
   `InputTrace="*res://autoload/InputTrace.gd"`
3. In `scenes/components/tap_button.gd`, delete both `InputTrace.note(...)` lines:
   - first line of `_gui_input` (`InputTrace.note("  gui %s %s dev%d" ...)`)
   - the one just before `pressed.emit()` (`InputTrace.note("  >> PRESSED emit %s" ...)`)
3b. Also delete every `InputTrace.note(...)` line in `scenes/components/map_controls.gd` (`_set_open`), `systems/events.gd` (`advance`), `systems/cultivating.gd` (`upgrade_vein_security`); and in `scenes/components/tap_button.gd` the `pressed.connect(_trace_pressed)`, `button_down/up` trace connects, `_trace_pressed()`, and `_in_script_emit`. Keep `button_mask = 0` only if still needed for the real fix.
4. `grep -rn InputTrace .` — must return nothing outside this file.
5. Run `scripts/check_all.sh` and `scripts/run_tests.sh`; both clean.
6. Commit: `Remove InputTrace diagnostic`.

## Notes
- Not in CODEMAP (never added); nothing to update there.
- `user://input_trace.txt` on device is written by the tracer; vanishes with the removal (stale file on the phone is harmless).
