# 04 — Migrate state_changed.emit() to mark_changed(): systems A–M

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** Every `state_changed.emit()` in `systems/` files whose name starts a–m (about 50 files) becomes `mark_changed()`. Tests that assert UI immediately after an action call `flush_now()`.

**Blocked by:** 03 (eventbus-mark-changed)

**Relevant files:** `systems/[a-m]*.gd` (find with `grep -rl "state_changed.emit" systems`), affected `tests/test_*.gd`; review §2.1

**Status:** ready-for-agent

- [ ] No `state_changed.emit()` left in `systems/[a-m]*.gd`
- [ ] Affected tests updated (`flush_now()` where UI is asserted) and pass
- [ ] `scripts/check_all.sh` clean
