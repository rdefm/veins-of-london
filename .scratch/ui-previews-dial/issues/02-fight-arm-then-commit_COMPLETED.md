# 02 — Fight: arm-then-commit action buttons

**What to build:** Every combat action row (moves e.g. Strike/Guard, loadout/kit item rows, Dial casts, Leg it) becomes two-tap. First tap **arms** the row: it highlights, nothing is committed. While armed, tapping a target on the stage retargets the armed action. Tapping the armed row again **commits** it — exactly what today's single tap does. Tapping a different row re-arms that row instead; tapping empty space (stage background, transcript) disarms. Disabled rows (red `!` block reason) can't be armed and behave as now. The `?` tooltip and long-press peek keep working. Arm state is screen-local, never in `state.combat`.

This ticket delivers only the arm/commit interaction and highlight; HP-bar previews (03–05) hook onto the armed action this ticket exposes.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/components/combat_command_dock.gd` (rows, `?`, `!`, long-press peek, panels)
- `scenes/screens/combat_rounds.gd` (row handlers → `Combat.choose_move()`/`choose_item()`, Dial casts, block reasons)
- `scenes/components/combat_stage.gd` (tap targets)
- `scenes/components/dial_widget.gd` (Dial casts)
- `scenes/components/combat_director.gd` (commands locked during playback — arming blocked/cleared then too)
- `systems/combat.gd` (`choose_move`, `choose_item`)
- REFERENCE §3.7b Open/Guarded round combat
- tests: `tests/test_combat_rounds.gd`, `tests/test_dial_widget.gd`

**Status:** ready-for-agent

- [ ] First tap on any enabled action row arms + highlights it; no state change
- [ ] Second tap on same row commits identically to the old single tap
- [ ] Tapping a target while armed retargets; row stays armed
- [ ] Tapping another row re-arms it; tapping empty space disarms
- [ ] Arm cleared on commit, beat playback start, Rewind, panel switch
- [ ] Works for moves, kit/loadout items, Dial casts, Leg it, multi-target units
- [ ] Demo/scripted/coach-mark fights still advance (scripted locks respected)
- [ ] Tests: arm → commit, and arm → re-arm → disarm without mutating state
