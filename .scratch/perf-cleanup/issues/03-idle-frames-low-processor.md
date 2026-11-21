# 03 — Idle frames cost nothing (low-processor mode)

**What to build:** While the player is reading a menu and nothing is animating, the game stops redrawing and stops running per-frame code, saving battery and heat on phones. Three parts:

1. Turn on `application/run/low_processor_mode` in project settings (Godot then redraws only when something changes; tweens, `_process` animations and `queue_redraw` still work).
2. The alarm presentation and time-transition components currently run `_process` every frame forever just to notice the game session was replaced (`is_same(session, GameState.state)`). Add an EventBus signal emitted when the state tree is replaced (new game/reset, save load, import) and have both components resync on it, keeping `_process` off whenever they have nothing pending/active.
3. Map charge halos (`queue_redraw` every frame per halo) stop processing while the Map is not visible, and resume when it is.

Source: code review 2026-11-21 item 10 (`.scratch/code-review/recommendations.md`). Zero gameplay change: presentation timing only; the alarm hold delay and time-transition duration must behave exactly as today.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `project.godot` (`[application]`)
- `autoload/EventBus.gd` (new signal, primitives only)
- `autoload/GameState.gd` (`reset()`), `autoload/SaveManager.gd` (every path that assigns `GameState.state`, e.g. ~line 240, import)
- `scenes/components/alarm_presentation.gd` (`_sync_session` ~26, `_process` ~66)
- `scenes/components/time_transition.gd` (`_sync_session` ~41, `_process` ~63)
- `scenes/components/map_halos.gd` (`ChargeHalo` ~147–160)
- `tests/` existing alarm/time-transition tests (they may drive `_process`/`advance` directly — keep them valid)

**Status:** ready-for-agent

- [ ] Low-processor mode enabled in `project.godot`
- [ ] New "state replaced" signal emitted from every place the whole state tree is swapped; covered by a test
- [ ] Alarm presentation and time transition: `_process` is off when idle, on while an alarm is pending or a transition is active; session resync driven by the signal; existing tests pass, plus a test that a state swap resets them as before
- [ ] Charge halos don't process while the Map is hidden
- [ ] Syntax check clean on touched files; full suite passes
- [ ] Report lists on-device checks: end a block and a day (time transition plays fully, overnight variant included); trigger a vein alarm (auto-opens after the usual hold); Map halos pulse; ticker, status icons, dot-matrix board, lab gauges, touch-scroll fling and combat animations all still animate smoothly; load a save mid-session (no stale alarm/transition)
