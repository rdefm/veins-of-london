# 04 — Batch, multi-target gate and bench Rewind

**What to build:** Once a recipe has been performed by hand, the player can batch it ×N at their best rank for base calc × N, with no performance and no failures. The multi-target variant unlocks at best rank 3. A botched run can be Rewound by spending a Rewind item or a loaded Dial Rewind complication, restoring everything to just before the run's first jar tap. Spec: `.scratch/lab-port/spec.md` § Batch, § Rewind.

**Blocked by:** 02

**Relevant files:**
- `systems/bench_prototype.gd` (source: `batch`, `_push_snapshot`, `rewind`)
- `systems/lab.gd`, `systems/crafting.gd` (`multi_craft_available`, `inventory_key`, `craftMulti`), `tests/test_lab.gd`, `tests/test_multi_target.gd`
- `autoload/Snapshots.gd`, `systems/dial.gd` (loaded complications), `systems/events.gd` + combat rewind (contract prior art)

**Status:** ready-for-agent

- [ ] Batch refused unless recipe in `performedOnce`; crafts at best rank; costs base calc × N; never fails; XP = `xpReward` per item; items filed through the Crafting entry point
- [ ] Batch never fires the manual-run hook
- [ ] Multi variant available only at best rank ≥ 3; `craftMulti` and `_multi` key kept
- [ ] Rewind point taken at the run's first jar tap
- [ ] Rewind refused with no item and no loaded complication; consumes exactly one
- [ ] Rewind restores `lab`, `player.orichalchum` and active-effect state to the snapshot
