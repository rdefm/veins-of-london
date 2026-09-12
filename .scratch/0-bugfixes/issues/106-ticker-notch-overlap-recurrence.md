# 106 — Status ticker still overlaps phone camera/notch after prior fix

**What to build:** The top status ticker was reported overlapping the phone's front camera/notch. A prior fix (commit `54e8cd7`) made the top bar re-derive its safe-area offset on every refresh, but the user is still seeing the overlap on a build from after that fix landed — this is a recurrence, not a stale-build report. Because the safe-area inset value can't be verified headless, the first step is on-device diagnosis: confirm what inset value is actually being applied on the affected device, and where it diverges from what's needed to clear the notch, before changing code.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Actual safe-area inset value logged/verified on the affected device (not assumed from simulator/desktop, which returns 0).
- [ ] Root cause identified for why the ticker still overlaps despite the top bar re-deriving its offset every refresh.
- [ ] Fix applied so the ticker's content clears the notch/camera area on the affected device.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file.
- [ ] Manual check noted for the human: on the affected device, confirm the ticker text no longer sits under the camera/notch.
