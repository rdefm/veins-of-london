# Borrowed Time — spec (approved)

Sim: scratchpad `bt_sim.py` (3 blocks/day, debt floor so a day keeps >=1 block).

## Tier table (human-chosen)
| Lv | Charges gained | Debt booked per charge spent |
|---|---|---|
| 1 | +1 | 2 |
| 2 | +1 | 1 |
| 3 | +1 | 0 |
| 4 | +1, +1 more at 50% | 0 |
| 5 | +2 | 0 |
Data lives in `data/` (effectPower-style table), not in code.

## Model
- Use → `world.borrowedCharges += gained`. The next clock advance (`advance_time_block`) consumes a charge instead of moving the clock: staff block still runs once, `timeBlock`/`timeBlocksDone` unchanged. No 4th named slot; `TIME_BLOCKS`, events, staff index untouched.
- Debt booked when a charge is **spent**: `world.blockDebt += debt_for_tier` (tier recorded at use: `world.borrowedDebtPer`).
- Rollover (one shared path used by `advance_time_block` and `do_rest`): day starts with `blockDebt` blocks already elapsed (staff block runs for each, so staff still get 3 actions/day), `timeBlock = debt`, `timeBlocksDone` pre-filled, then `blockDebt = 0`.

## Q1 Stacking
Unlimited charges. Debt capped at `BLOCKS_PER_DAY - 1` (day keeps >=1 block). Lv1-2 chains just shift blocks between days (sim: net 0 sustained). Lv3+ are real net gain per use — accepted, gated by 8 time ore + recipe.

## Q2 Rest
Rest consumes remaining blocks, rolls over. Unspent charges are lost, no debt. Spent charges' debt applies normally. Rest never repays debt.

## Q3 Rollover during an event
Debt is state, applied only inside the rollover, never in event code. `advance_to_block` never crosses rollover. Rewind snapshot carries the ints.

## Visibility
Day header chip: "+N borrowed" / "−N tomorrow" from `borrowedCharges` / `blockDebt`.
