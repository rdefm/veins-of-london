# 08 — Atomic saves + .bak fallback

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** Saves write to a temp file with open/close error checks, rename the old main to `.bak`, then rename temp over main. Failures return `{ok:false, reason}`. Load falls back to `.bak` when the main fails to parse and tells the player.

**Blocked by:** None — can start immediately

**Relevant files:** `autoload/SaveManager.gd` (`_write_json`, ~line 141; load path), `tests/test_savemanager.gd`, `tests/test_phone_saveload.gd`; review §4.1

**Status:** ready-for-agent

- [ ] Failed or interrupted write leaves the previous main file intact (tested)
- [ ] Truncated/corrupt main loads from `.bak` with a player-visible message (tested)
- [ ] Autosave rotation and manual slots still work; existing tests pass
