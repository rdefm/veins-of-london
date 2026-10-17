# 04 — Batch, multi-target gate and bench Rewind

**What to build:** Once a recipe has been performed by hand, the player can batch it ×N at their best rank for base calc × N, with no performance and no failures. The multi-target variant unlocks at best rank 3. A botched run can be Rewound by spending a Rewind item or a loaded Dial Rewind complication, restoring everything to just before the run's first jar tap. Spec: `.scratch/lab-port/spec.md` § Batch, § Rewind.

**Blocked by:** 02

**Relevant files:**
- `systems/bench_prototype.gd` (source: `batch`, `_push_snapshot`, `rewind`)
- `systems/lab.gd`, `systems/crafting.gd` (`multi_craft_available`, `inventory_key`, `craftMulti`), `tests/test_lab.gd`, `tests/test_multi_target.gd`
- `autoload/Snapshots.gd`, `systems/dial.gd` (loaded complications), `systems/events.gd` + combat rewind (contract prior art)

**Status:** ready-for-agent

- [x] Batch refused unless recipe in `performedOnce`; crafts at best rank; costs base calc × N; never fails; XP = `xpReward` per item; items filed through the Crafting entry point
- [x] Batch never fires the manual-run hook
- [x] Multi variant available only at best rank ≥ 3; `craftMulti` and `_multi` key kept
- [x] Rewind point taken at the run's first jar tap
- [x] Rewind refused with no item and no loaded complication; consumes exactly one
- [x] Rewind restores calc, items filed, mid-run effect items and active-effect state; keeps XP + Lab knowledge (design revised with the human, spec § Rewind)
- [x] Time-block Rewind (`Rewind.rewind_to_block_start`): keeps XP, Lab knowledge, loadout, Dial; never saved
