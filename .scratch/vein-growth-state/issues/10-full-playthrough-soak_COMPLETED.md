# 10 — Full playthrough soak and final integration

**What to build:** end-to-end proof the whole feature holds together — extended playthrough test, debug-start sample data covering every visual state, and a final sweep for any stale `level`/`charge` reference left anywhere in code or docs.

**Blocked by:** 01, 02, 03, 04, 05, 06, 07, 08, 09 — every other ticket in this feature.

**Status:** ready-for-agent

- [ ] `test_playthrough.gd` extended: prospect → seed → cultivate → prune across ≥3 districts, plus a neglect arm verifying a vein left alone bottoms out, is eventually removed by the collapse roll, and leaves a seedable site behind (spec §11 item 11).
- [ ] `systems/debug_start.gd`'s three debug veins get growth values instead of levels/charge: recommend one at 0 (`collapsed`), one dormant, one at the ceiling, so every distinct visual state is inspectable immediately without waiting out drift. `test_debug_start.gd` updated.
- [ ] Grep sweep: no remaining reference to `devBar`, `charged`, `chargeBlocks`, `level`/`levelLabel` on a vein dict, `harvest_cautious`, `harvest_full`, or `vein_levels.json` anywhere in `systems/`, `scenes/`, `data/`, `docs/`, or `tests/`.
- [ ] `docs/REFERENCE.md`, `docs/M1-LONDON.md`, `docs/M1.5-NETWORK-MAP.md`, `CONTEXT.md` cross-checked against the landed code for drift (each ticket already updates its own section — this is the consistency pass, not new writing).
- [ ] Full `scripts/run_tests.sh` green, `scripts/check_all.sh` clean.

**Human to check on-device:** play a save from a fresh start through at least one full drift cycle in each direction; confirm the debug-start save shows all three visual states immediately on load.
