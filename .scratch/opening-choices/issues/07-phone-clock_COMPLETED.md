# 07 — Phone clock follows the game

**What to build:** The phone shell's status-bar time and date widget show the game's current day (via the calendar) and a fixed representative clock time per block (e.g. Morning 08:xx, Afternoon 14:xx, Evening 20:xx; values in data), replacing the fixed "Tue, 14 May 08:14". Weather and tagline stay presentation-only.

**Blocked by:** None — can start immediately (reads whatever start weekday 06 sets).

**Relevant files:** `scenes/components/phone_device_shell.gd`, `data/phone_home.json`, `systems/calendar.gd` (`format_day`), `tests/test_phone_device_shell.gd`, `CODEMAP.md` (phone_home.json row currently says no GameState data — update).

**Status:** ready-for-agent

- [ ] Status time and date widget derive from `world.day` + current block; per-block times in data.
- [ ] Updates on block/day change without reopening the phone.
- [ ] Test asserts rendered strings for two day/block states.
