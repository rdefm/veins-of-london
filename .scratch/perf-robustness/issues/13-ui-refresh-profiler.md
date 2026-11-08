# 13 — UI refresh profiler script

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** A permanent script boots the main scene, visits each screen, and prints per-listener ms for a `state_changed` emit and an end-of-day rollover, next to `profile_block_end.gd`. Used to confirm the gains from the batching and Map-cache tickets.

**Blocked by:** 03 (eventbus-mark-changed)

**Relevant files:** `scripts/profile_block_end.gd` (model), `scenes/Main.tscn`, `CODEMAP.md` (add the script row, under 400 chars); review §1.2, §5.4

**Status:** ready-for-agent

- [ ] Runs headless and prints a table for Map, Phone and HQ
- [ ] Before/after rollover numbers reported
- [ ] CODEMAP updated
