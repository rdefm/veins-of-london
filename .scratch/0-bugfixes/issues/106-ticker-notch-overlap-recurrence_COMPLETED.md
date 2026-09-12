# 106 — Status ticker still overlaps phone camera/notch after prior fix

**What to build:** The top status ticker was reported overlapping the phone's front camera/notch. A prior fix (commit `54e8cd7`) made the top bar re-derive its safe-area offset on every refresh, but the user is still seeing the overlap on a build from after that fix landed — this is a recurrence, not a stale-build report. Because the safe-area inset value can't be verified headless, the first step is on-device diagnosis: confirm what inset value is actually being applied on the affected device, and where it diverges from what's needed to clear the notch, before changing code.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [x] Actual safe-area inset value logged/verified on the affected device (not assumed from simulator/desktop, which returns 0).
- [x] Root cause identified for why the ticker still overlaps despite the top bar re-deriving its offset every refresh.
- [x] Fix applied so the ticker's content clears the notch/camera area on the affected device.
- [x] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file.
- [x] Manual check noted for the human: on the affected device, confirm the ticker text no longer sits under the camera/notch.

## Done

Added a "Safe area" diagnostic card to the phone Debug app (`UI.safe_area_debug_text()` in `scenes/components/ui.gd`, card in `scenes/screens/phone.gd::_build_debug_safe_area_card()`) so the on-device inset could actually be read rather than assumed.

**Reported on-device dump** (human, current build):
```
window 1080x2400
canvas 390x866
raw safe-area pos (0,118) size 1080x2282
insets top=42.6 bottom=0.0 left=0.0 right=0.0
```
Checks out: `118 * (866/2400) = 42.58 ≈ 42.6` — `UI.safe_area_insets()`'s scaling math is correct, and TopBar's `offset_top` (42.6) sits exactly on the raw safe-area boundary, with the 40px bar body running from canvas y=42.6 to y=82.6, entirely below it.

Human confirmed on-device: the ticker does **not** overlap the notch on this build — "it seems to be fixed already". No code change to the offset math was needed or made.

**Root cause of the "recurrence" report:** not conclusively identified — could not be reproduced against this build once the actual on-device value was available. The top bar's own `_apply_safe_area_offsets()`/`_refresh()` already compute correctly against the reported inset (see the check above), so commit `54e8cd7`'s every-refresh re-derive is doing its job here. Two candidate explanations remain, neither confirmed: (a) the original recurrence report was against a build predating that commit, or (b) the narrow boot-time race already flagged in `top_bar.gd`'s own comment (the OS inset not yet settled at TopBar's very first `_ready()` frame, with no `EventBus.state_changed` firing before the player reaches a screen that shows the bar) — this would self-correct on the first state change and wouldn't reproduce on demand, consistent with not reproducing here. No speculative fix added for (b) without a reproduction — the diagnostic card stays in the Debug app if this needs re-investigating on a future report.

**Manual check for the human:** confirmed above — ticker clear of the notch on the affected device.
