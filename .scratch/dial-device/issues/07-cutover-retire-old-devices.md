# 07 — Cutover: retire old devices, rewire call sites, amend REFERENCE.md

**What to build:** With the Dial system now at full feature parity with the
old single-device system, delete `systems/devices.gd` and `data/
devices.json` outright (not kept alongside, per the design doc's "old
devices retired outright" decision). Update `systems/combat.gd`'s
device-casting call site and `systems/time_system.gd`'s daily_tick
device-reset step to call into `dial.gd` instead, mirroring exactly how they
call into `devices.gd` today (same integration shape, new target — combat's
cast call site now calls the ticket 05 cast function, and time_system's
daily_tick calls `Dial.daily_regen()` from ticket 04 instead of
`Devices.reset_daily_charges()`). Amend `docs/REFERENCE.md` §1.4 and §2's
`devicesInProgress`/`devicesCompleted`/`equipment.device` rows and §3.5's
"Devices:" and "Device activation in combat" bullets to describe the Dial
instead, per the project constitution rule that the winning document amends
the one it supersedes in the same ticket that lands the change.

**Blocked by:** 06 (every old-system behaviour needs a Dial equivalent
already built and tested before the old system can be safely deleted).

**Status:** ready-for-agent

- [ ] `systems/devices.gd` and `data/devices.json` are deleted; nothing in
      the codebase references them
- [ ] `combat.gd`'s device-casting call site calls into `dial.gd`
- [ ] `time_system.gd`'s daily_tick calls `Dial.daily_regen()` in place of
      `Devices.reset_daily_charges()`
- [ ] Full test suite (including ticket 01-06 Dial tests and the existing
      combat/time_system tests) passes with no reference to the old device
      system left anywhere
- [ ] `docs/REFERENCE.md` §1.4, §2, and §3.5's device rows/bullets are
      rewritten to describe the Dial's state shape and mechanics
