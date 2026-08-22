# 58 — Device builds never lose progress

**What to build:** `Devices.attempt_device_build()` (`systems/devices.gd:35-66`) currently has a failure branch that *decreases* progress (`device["progress"] = max(0.0, device["progress"] - 2.5)`, `:59-63`) and can destroy the device outright if progress hits 0 (`_break_device()`). Per the human's explicit direction: a failed build attempt should have zero effect on progress — never decrease it. Only a successful attempt moves progress forward (existing success branch, `:54-58`, unchanged). Since progress can no longer decrease, it can never reach 0 via a failed attempt, so the progress-triggered `_break_device()` path becomes unreachable through normal play — remove that trigger (or confirm/document any other legitimate way a device can still break, if one exists elsewhere).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Failure branch of `attempt_device_build()` no longer decreases `progress` — a failed attempt leaves progress unchanged.
- [ ] `_break_device()`'s progress-hits-0 trigger removed from the failure path (confirm whether `_break_device()` has any other caller/trigger worth keeping; if none, remove the function too).
- [ ] `docs/REFERENCE.md` device-building formulas updated to drop the progress-loss-on-failure rule.
- [ ] Existing device-build tests updated to reflect failure-has-no-effect; add a test confirming repeated failed attempts never move progress backward or break the device.
- [ ] Manual check noted for the human: fail several build attempts in a row on a device, confirm progress never drops and the device is never destroyed by failure alone.
