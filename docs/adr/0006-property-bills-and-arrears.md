# Property bills, tenure and arrears

Decision record for `day-rhythm-business-and-combat` spec decision 2
(Bills). **Approved 2026-09-23.** Tenure-aware daily bill, rent/buy moves,
arrears, interest, forced downgrade and morning-account visibility
implemented.

## Current behaviour (at decision time)

- `TimeSystem._apply_living_costs()` charges hard-coded `DAILY_COST_BASE =
  50` × `(1 + fx.dailyCost)` and floors cash at 0. The unpaid part is
  forgiven: no arrears and no consequence.
- `data/home.json` tier `dailyCost` (50/80/150/300/600/1500) is shown in
  the Property app but never charged.
- Tier moves are purchases only (`upgradeCost` 1200/4000/12000/40000/150000).
  Rooms carry over.
- The notification shows the nominal cost even when less was actually taken.
  The morning account has no shortfall exception.
- Recovery: James' £300 flat job, offered at 100% chance when `cash ≤ 100`.

## Approved rules

**Tenure.** `home.tenure` is `"rented"` or `"owned"`. The bedsit is rent-only.
From the flat upward each tier can be rented or bought.

| Tier | Rent/day (= `dailyCost`) | Buy price | Owned utilities/day |
|---|---|---|---|
| bedsit | 50 | — (rent only) | — |
| flat | 80 | 200,000 | 58 |
| townhouse | 150 | 500,000 | 65 |
| safehouse | 300 | 800,000 | 80 |
| compound | 600 | 2,000,000 | 110 |
| mansion | 1500 | 4,000,000 | 200 |

- Utilities = `50 + round(0.10 × dailyCost)`.
- The buy price replaces `upgradeCost`. Renting has no up-front cost.
- **Buy-out:** a player renting the current tier may buy it at the full buy
  price. The tier doesn't change and rooms are kept.
- **Any tier change clears all installed rooms without refund.** This covers
  upgrades, downgrades, and both rent and buy. Security upgrades are kept.
- **Today's bill** = `round_epsilon(base × (1 + fx.dailyCost))`, where `base`
  is the rent (rented) or the utilities (owned). The barometer scales only
  today's bill, never arrears or interest.
- **Data.** The rent-only flag, buy prices, the utilities formula constants
  (50, 0.10), the interest rate (0.05) and the thresholds (5, 10) all live in
  `data/home.json`. None are hard-coded.
- **State.** `home.tenure`, `home.arrears` (int £ ≥ 0) and `home.arrearsDays`
  (int ≥ 0) are plain serializable fields covered by snapshot/Rewind.

## Daily ordering (replaces §3.1 step ③; payroll ⑥ unchanged)

1. **Interest.** If `arrears > 0` and `arrearsDays ≥ 5`: `arrears +=
   round_epsilon(arrears × 0.05)`, compounding. It first applies on the 6th
   consecutive rollover in arrears.
2. **Pay arrears.** `paid = min(cash, arrears)`. This is taken from cash and
   bank-logged.
3. **Pay today's bill.** `paid = min(cash, bill)`. The remainder is added to
   `arrears`.
4. **Clock.** If `arrears == 0`, set `arrearsDays = 0`. Otherwise
   `arrearsDays += 1`. Partial payments never reset the clock; only clearing
   the debt to £0 does.
5. **Forced downgrade.** If `arrearsDays ≥ 10` and the tier is not the bedsit:
   - Drop one tier. The new tier is always `rented`, and all rooms are cleared.
   - If the lost tier was **owned**, set `arrears = 0`.
   - If it was **rented**, arrears are kept and keep accruing.
   - Set `arrearsDays = 0` either way, so another 10 days are needed before
     the next drop.
6. **Bedsit floor.** At the bedsit, arrears and interest keep accruing and
   nothing further happens.
7. Wages (⑥) are paid from whatever cash is left, as today.

**Affordability boundary.** Cash exactly equal to arrears + bill clears
everything (`arrears 0`, `arrearsDays 0`, `cash 0`). Cash never goes
negative, so the `cash ≥ 0` invariant holds.

**Recovery.** No new routes. James' £300 job (100% at `cash ≤ 100`) stays
the only one. Its trigger stays cash-based, not arrears-based.

## Migration

- Existing saves: `tenure = "owned"` (they paid `upgradeCost`), `arrears =
  0`, `arrearsDays = 0`. The bill becomes that tier's utilities rate.
- Bedsit saves become `rented`.
- New games start at a rented bedsit.

## Morning account and notifications

- `expenses` = cash actually paid (arrears payment + today's bill).
- `exceptions` gains entries for: shortfall added to arrears (amount, new
  balance); interest charged (amount); forced downgrade (from/to tier, rooms
  lost, arrears cleared or kept).
- As arrears approach a threshold, the account shows days remaining until
  interest starts or the downgrade happens.
- The daily notification states the amount actually paid, never the nominal
  cost.
- Wording is written in the implementation ticket against CONTENT-GUIDE.md and
  flagged PROSE-REVIEW.

## Worked examples (fx = 0 unless noted)

**Sufficient cash.**
- Rented flat, cash 500 → pays 80 → cash 420, arrears 0.
- Owned townhouse, cash 500 → pays 65 → 435.
- Rented flat under inflation (+0.30) → bill `round(80 × 1.3)` = 104.

**Zero / partial cash.**
- Rented bedsit, cash 0 → arrears 50, days 1.
- Cash 30 → pays 30 → arrears 20, days 1.
- Arrears 100 at days 3, cash 60 → no interest → pays 60 toward arrears
  (40 left) → bill 50 unpaid → arrears 90, days 4. The clock is not reset.

**Repeated shortfall, rented flat, cash 0 every day:**

| Rollover | Interest | Arrears after | Days |
|---|---|---|---|
| 1–5 | — | 80, 160, 240, 320, 400 | 1–5 |
| 6 | 20 | 500 | 6 |
| 7 | 25 | 605 | 7 |
| 8 | 30 | 715 | 8 |
| 9 | 36 | 831 | 9 |
| 10 | 42 | 953 | 10 → downgrade |

Result: rented bedsit, rooms cleared, arrears 953 kept, days 0. Interest
resumes from rollover 6 of the new count, and there are no further drops.

**Repeated shortfall, owned flat (utilities 58), cash 0:**
- Rollovers 1–5: arrears 58, 116, 174, 232, 290.
- Rollovers 6–10: interest 15, 18, 22, 26, 30, giving arrears 363, 439, 519,
  603, 691.
- Result: downgrade to rented bedsit, arrears cleared to 0, days 0.

**Recovery.**
- Rented bedsit, arrears 400, days 5, cash 0.
- The James job pays £300. At rollover: interest 20 → arrears 420 → pays 300
  (120 left) → bill 50 unpaid → arrears 170, days 6. The player is still in
  arrears.
- With cash 600 instead: interest 20 → pays 420 → bill 50 → cash 130, arrears
  0, days 0. Wages are then paid from 130.

## Follow-up decisions (2026-09-23)

- **Voluntary downgrade is allowed.** The player may move down one tier by
  choice. They choose rent or buy (buying is not possible for the bedsit).
  The same room wipe applies.
- **Security moves with the player.** On any downgrade, each security
  upgrade whose `minTier` is above the new tier is lost without refund.
  Upgrades still available at the new tier are kept.
- **Room wipe unassigns staff.** Staff assigned to a wiped room are
  unassigned automatically. Nothing else happens to them.
- **Wiping the Home Gym reverts its bonus.** `hpMax −= bonusValue` and `hp`
  is clamped to the new max. Building the gym again re-grants the bonus.
