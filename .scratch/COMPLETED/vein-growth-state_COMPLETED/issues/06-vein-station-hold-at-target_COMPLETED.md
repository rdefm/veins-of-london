# 06 — Vein Station hold-at-target

**What to build:** the Vein Station room's assigned-contact behaviour, currently "harvest if charged else cultivate" (meaningless under the growth model), becomes "hold this vein at a target growth I set" — the player's answer to holding more veins than they have blocks, with an explicit per-vein risk posture.

**Blocked by:** 01 (needs `growth`, `prune`, `cultivate`, `days_to_wall` in place).

**Status:** ready-for-agent

- [ ] `state.veinStationTargets: { veinId: int }` added alongside existing `state.veinStationVeins` — plain dict of primitives, purity-safe. Default target on assignment: 70 (`lush`).
- [ ] `systems/rooms.gd` daily pass, per assigned vein: if `growth > target + 5`, contact prunes down toward target (ore into player's `orichalchum`, same §2.4 yield formula); if `growth < target - 5`, contact rolls a cultivate attempt at their own `cultivatingSkill`; otherwise no-op.
- [ ] Contact XP awards keep current magnitudes (15 on a harvest/prune, 20 on cultivate success, 8 on failure).
- [ ] Summary notification as today, updated for prune/cultivate language instead of harvest/cultivate.
- [ ] UI for setting a vein's target (wherever assignment currently happens) — read-modify via a system function, screen never mutates `state.veinStationTargets` directly.
- [ ] `test_rooms.gd` rewritten. New coverage per spec §11 item 10: a vein at 95 with target 70 is pruned down; one at 40 with target 70 is cultivated up; one at 70 is left alone.
- [ ] `godot --headless -s scripts/check_runner.gd -- <file>` clean; `scripts/run_tests.sh` green.
