# Biz Act 2 — Sub-spec 3: Guard upkeep + business float

Status: ready-for-agent

> Sub-spec 3 of `.scratch/biz-empire-act2/spec.md` (macro vision). Near-independent of sub-specs 1 and 2. It reads faction cash (`resources`) and the faction vein value order from sub-spec 2 (`.scratch/COMPLETED/biz-act2-faction-economy_COMPLETED/spec.md`), which is built. Covers weekly guard wages for player veins, HQ (home) guards and faction veins, the short-pay menu and walk-offs, factions buying extra guards, the business float, and the BizBrief expense and guard-cost views. Numbers marked *placeholder* are feel targets. The tuning pass pins them in JSON and REFERENCE.md.

## Problem Statement

Guards are a one-off purchase. A player buys a Hired Guard and then stacks extra guards on a vein, or hires guards for HQ, and none of it ever costs anything again. Security never pressures cashflow, so there's no trade-off between guarding everything and paying for it. Factions don't feel it either: they harden their best veins until they're maxed out and never pay a penny to keep them that way. A rival that's being squeezed keeps its defences no matter how broke it gets.

The business pot has the opposite problem. It pays out everything at every payday: whatever is left after bills is split between the player and the partners. So a week with low contract income can't cover wages, and the player has no way to top the business up without the top-up being split away on Monday.

## Solution

- **Guards cost a wage.** Every guard on a vein — the Hired Guard tier guard and each extra guard — and every HQ guard costs a flat £500 a week, built up day by day while it's on duty (a guard on duty part of the week costs part of the wage). Wages are paid weekly on the Monday rollover, from day 1 of the game. Locks and ward runes stay one-off purchases.
- **Who pays.** Before the business pot exists, guard wages come from the player's cash every Monday. Once the pot is active, they're paid at payday: staff wages first, then guard wages. Each bill draws the pot first, then the float as backup.
- **Short on wages.** If guard wages can't be covered, the player gets a menu. It lists HQ and every guarded vein and lets them choose how many guards to keep at each, paying the difference from their own cash. Guards they don't keep walk off. The player has one grace day to decide. If they ignore it, guards are dropped automatically: extra guards on the least valuable veins go first, then tier guards, then HQ guards last. When a vein loses its last guard, it drops out of the Hired Guard tier.
- **Business float.** Once the pot is active, the player can donate cash into a reserve float and withdraw it at any time. Payday never splits the float. It only pays a bill (staff wages, guard wages, calc bought for Sales contracts) when the pot can't cover it.
- **Factions pay too.** Factions build up the same guard wages and pay them from faction cash every Monday. A faction that can't pay loses guards by the same drop order. Factions now also buy extra guards, not just the tier guard, but only when they can afford to keep them paid. A rival squeezed for cash loses its defences.
- **Visibility.**
  - Guard upkeep is shown wherever a guard is bought and on every vein's security row.
  - BizBrief breaks expenses down by kind (staff wages, guard wages, calc purchases).
  - Tapping guard wages opens a Guard Costs screen: guard cost over time for HQ and each vein, with a filter to show only chosen ones.

## User Stories

### Guard wages — player
1. As a player, I want every Hired Guard and extra guard to cost £500 a week, built up day by day, so that security is an ongoing commitment.
2. As a player, I want locks and ward runes to stay one-off purchases, so that basic security isn't a running cost.
3. As a player, I want all guards to cost the same flat £500 a week, so that I can work out my guard bill in my head.
4. As a player, I want a guard's wage to start the day I hire it, so that a guard bought midweek only costs the days it worked.
5. As a player, I want guard wages to add up daily and be paid once a week on Monday, so that they settle alongside my other weekly bills.
6. As a player, I want guard wages to apply from day 1, so that the cost of security is part of the game from the start.
7. As a player before the business pot exists, I want guard wages taken from my cash on Monday, so that they're paid without extra steps.
8. As a player with an active business pot, I want guard wages paid from the pot at payday, so that they sit with the other business costs.
9. As a player, I want staff wages paid before guard wages when the pot is short, so that my staff keep working.
10. As a player, I want the float to cover guard wages the pot can't, so that my donation protects my guards.
11. As a player, I want never to have my cash silently taken for guard wages once the pot exists, so that business and personal money stay apart unless I choose otherwise.
12. As a player, I want to see the weekly guard cost on each vein's security row, so that I know what each vein's protection costs.
13. As a player, I want to see the added weekly wage before I buy a guard, so that I'm not surprised on Monday.
14. As a player, I want the Monday notification to say what my guards were actually paid, so that I know where my money went.

### HQ guards
14a. As a player, I want HQ guards to cost the same £500 a week, paid with my vein guards, so that home security is an ongoing commitment too.
14b. As a player, I want HQ guards in the short-pay menu alongside my veins, so that I choose between protecting home and protecting veins.
14c. As a player who ignores the menu, I want HQ guards dropped only after every vein guard, so that the place I live is protected longest.
14d. As a player, I want the HQ security screen to show the weekly guard cost and the added wage before I hire another guard, so that I'm not surprised on Monday.
14e. As a player who moves to a tier below the HQ guard's minimum tier, I want the lost guards' unpaid days dropped with them, so that I'm not billed for guards I no longer have.

### Short-pay menu and walk-offs
15. As a player who can't cover guard wages on Monday, I want a menu listing each guarded vein and its guards, so that I can choose which veins to keep guarded.
16. As a player, I want to set how many guards to keep on each vein and see the cost as I adjust, so that I can prioritise my most important veins.
17. As a player, I want to pay the difference from my own cash in that menu, so that I can keep guards I care about.
18. As a player, I want guards I don't keep to walk off immediately when I confirm, so that the choice is clear and final.
19. As a player, I want a guard that walks to take its unpaid wage with it (I don't owe it), so that dropping a guard really does cut the bill.
20. As a player, I want a one-day grace period before unpaid guards walk, so that I can sort out the money.
21. As a player, I want unpaid guards still to defend my veins during the grace day, so that the warning isn't already a loss.
22. As a player who ignores the menu, I want guards dropped automatically, so that the game doesn't stall.
23. As a player, I want automatic drops to take extra guards from my least valuable veins first, then tier guards, so that my best veins keep their protection longest.
24. As a player, I want a vein to leave the Hired Guard tier when its last guard walks, so that its raid resistance honestly reflects that it's unguarded.
25. As a player, I want the vein to keep its lock and ward rune when its guards walk, so that I only lose what I stopped paying for.
26. As a player, I want to be able to rehire a walked guard at the normal purchase price, so that I can rebuild security when I can afford it.
27. As a player, I want the menu reachable from BizBrief and from the morning notification, so that I can find it during the grace day.
28. As a player, I want a clear notice naming the veins that lost guards, so that I know which veins are now exposed.
29. As a player who sells or loses a vein, I want its guards and their wages to go with it, so that I'm not billed for a vein I no longer own.

### Business float
30. As a player with an active business pot, I want a button to donate cash into a reserve float, so that bills get paid even when contract income is thin.
31. As a player, I want payday never to split the float, so that my donation isn't handed to my partners.
32. As a player, I want bills to use pot income first and the float only when the pot can't cover them, so that the float lasts as long as possible.
33. As a player, I want the float to back up staff wages, guard wages and Sales calc purchases, so that it protects every part of the business.
34. As a player, I want to withdraw any unspent float at any time, so that the donation isn't a trap.
35. As a player, I want to see the float balance next to the pot in BizBrief, so that I know how much reserve I have.
36. As a player, I want donations and withdrawals recorded in my bank history, so that my personal money is accounted for.
37. As a player, I want the float not to count as business revenue, so that my stats show what the business actually earned.

### Faction guard upkeep
38. As a player, I want factions to pay guard wages from their own cash each week, so that security costs them too.
39. As a player, I want a faction that can't pay to lose guards — extra guards on its least valuable veins first, then tier guards — so that squeezing a rival strips its defences.
40. As a player, I want factions to buy extra guards on their valuable veins, so that a well-funded rival's best veins are hard to raid.
41. As a player, I want factions to buy a guard only when they can afford to keep it paid for a while, so that they don't hire guards they'll lose next Monday.
42. As a player, I want a faction vein that loses its last guard to drop out of the Hired Guard tier, so that raid odds reflect the loss.
43. As a player, I want faction guard wages to be part of how a faction's cash is spent, so that a faction's wealth shows in its defences.

### Visibility
44. As a player, I want BizBrief to break expenses down into staff wages, guard wages and calc purchases, so that I can see where the business's money goes.
45. As a player, I want to tap guard wages in that breakdown to open a Guard Costs screen, so that I can dig into security spending.
46. As a player, I want the Guard Costs screen to chart guard cost over time for each vein, so that I can see which veins are expensive to protect.
47. As a player, I want to filter the Guard Costs screen to specific veins, so that I can compare the veins I care about.
48. As a player, I want the Guard Costs screen to show this week's total guard bill so far, so that I know what Monday will cost.
49. As a player, I want to open the Guard Costs screen from a vein's security row, so that I can check it before the pot exists.

### Save and rewind
50. As a player with an old save, I want existing guards to start building wages from the day I load, not charged backwards, so that updating doesn't hit me with a surprise bill.
51. As a player, I want Rewind to restore guard wages, pending menus and the float exactly, so that time travel stays consistent.

## Implementation Decisions

### Guard counting
- **HQ:** guard count = `home.guardCount`. HQ guards all stack as one kind; drops remove the newest first. HQ has no tier to lose — `guardCount` just falls, and `home.security` is unchanged. A tier move that loses HQ guards (below the guard's `minTier`) also drops their unpaid days.
- A vein's guard count = 1 if its security tier is `guarded` (the Hired Guard tier guard), plus `extraGuards`. Applies to player veins and faction veins alike.
- Guard slots on a vein are ordered: tier guard first, then extras in hire order. Every drop removes the last slot — newest extra first, tier guard last. So a vein only ever loses its tier guard once it has no extras left. Removing the tier guard sets the security tier from `guarded` to `warded`. Lock (`basic`) and ward rune (`warded`) are never lost to unpaid wages.
- Rehiring after a walk-off uses the existing security purchase at the existing price: the `guarded` tier price if the tier dropped, otherwise the next extra guard's price. There's no rehire discount.

### Wage accrual
- A flat `weeklyWage` per guard, the same for tier, extra and HQ guards: **£500** (pinned, not a placeholder). It lives in JSON, never in code.
- Each rollover adds one day to every on-duty guard slot on every player vein, HQ and every faction vein. Each vein records its days worked this week, one entry per guard slot. A guard hired today starts at 0 and begins adding from the next rollover.
- A guard's wage for the week = `round(weeklyWage × days worked / 7)`, the same proration as staff wages (`Business.prorated_wage`), so a full week is exactly £500. A vein's bill = the sum over its slots.
- When a vein leaves its owner (sold, lost to a raid, collapsed, bought out), its guards and their unpaid days go with it. Nothing is billed.
- Guards already on veins or at HQ when an old save loads start with 0 days worked.
- HQ guards use the same `weeklyWage` as vein guards. Their bill is part of the player's weekly guard bill, paid by the same source (cash before the pot, pot then float after).

### Player guard payday (Monday rollover)
- **Pot not active:** the week's guard bill is taken from player cash (bank record "Guard wages") if cash covers it in full. Otherwise nothing is taken yet and the short-pay flow starts, with player cash as the only source.
- **Pot active:** inside the payday, after staff wages and before the partner split:
  - Staff wages are paid as today, but a staff wage the pot can't cover draws on the float before becoming owed. It's still paid in full or not at all per contact, and the existing owed-wage prompt is unchanged.
  - Then the guard bill draws the pot, then the float. If both together cover it, it's paid. If not, all the pot and float money available for guards is set aside as a guard wage reserve (not split, not left in the float), and the short-pay flow starts.
  - The partner split runs on whatever pot remains.
- Guard wages are business expenses (kind `guard`, with the vein id) in the week's expense list, the ledger record and BusinessStats.
- Days worked reset to 0 for the new week for all kept guards. Guards in the short-pay flow keep building days for the new week as normal.

### Short-pay flow (player)
- **State:** a pending guard shortfall record holds the payday day, the grace deadline (next rollover), each vein's bill per guard slot, and the reserve (£ set aside from pot + float; 0 before the pot).
- **Menu:** reachable from the Monday morning notification and a BizBrief Brief attention row. For HQ and each guarded vein, the player sets guards to keep (0..N). Cost of keeping `k` = the wages of its first `k` slots. The menu shows the total cost, the reserve, and the cash needed on top.
- **Confirm** (a system function; screens only call it): kept guards are paid from the reserve first, then player cash. Unkept guards walk now, following the slot drop rule. Leftover reserve goes into the float, or to player cash before the pot exists. Refused if cash can't cover the difference.
- **Grace:** while the shortfall is pending, all its guards stay on duty and count for raid resist and repel.
- **Auto-resolve** at the grace rollover if unconfirmed: keep guards in priority order, using only the reserve (pot era) or player cash (pre-pot). The keep order is the reverse of the drop order. Drops take extras from the least valuable vein first, then the next least valuable, and so on; then tier guards, again least valuable vein first. HQ guards are dropped last, after every vein guard (newest HQ guard first). Unfunded guards walk. Leftover reserve goes as on confirm.
- **Vein value order:** the same order sub-spec 2 uses for faction kit allocation (combined magnitude, ties by site id). Player and faction veins use one shared helper.
- Only one shortfall can be pending at a time. The grace deadline is always the next rollover, so it clears before the next Monday.

### Business float
- `business.float` is an int £ ≥ 0, separate from `pot`. It only exists while the pot is active: donate is refused before then.
- `Business.donate(amount)`: moves cash to the float (1 ≤ amount ≤ cash), with a bank record. Not revenue.
- `Business.withdraw(amount)`: moves float to cash (1 ≤ amount ≤ float), with a bank record.
- Payday never touches the float in the split. The float only drains through backup draws:
  - staff wages
  - guard wages (including the guard wage reserve)
  - Sales calc purchases, which now take pot + float, still in full or not at all
- The float is shown beside the pot in the BizBrief Brief bank block, with Donate and Withdraw controls.

### Faction guard upkeep and extra guards
- **Weekly pay.** On the Monday rollover, each faction's total guard bill is paid from `resources`, as much as it can cover. Guards are kept in the same priority order and unfunded guards walk immediately. There's no grace or menu, and `resources` never goes negative.
- **Extra guards.** The faction daily security spend now continues past `guarded` into extra-guard purchases at the player's extra-guard price. It's capped per vein (`maxExtraGuardsPerVein`, *placeholder* 3). A purchase needs `resources ≥ cost + wageReserveWeeks × the faction's weekly guard bill after the purchase` (*placeholder* 2 weeks). It keeps the existing one upgrade per faction per tick and highest-value-vein-first targeting.
- **Rollover position.** Faction guard pay runs after faction industry income and before faction security upgrades. The security spend then sees post-wage cash and never buys a guard it just failed to pay.

### Rollover order
- The daily guard-day accrual (player + factions) runs once per rollover, before any Monday pay step, so Monday's bill includes Sunday's day.
- Faction guard pay (Monday only) comes before faction security upgrades.
- Player guard pay (Monday only) runs in the business payday step when the pot is active. Otherwise it runs in the same step-⑥ slot on its own.
- The pending shortfall's grace auto-resolve runs early in the rollover, before accrual, so walked guards don't build another day.
- The ticket fixes the exact step letters in REFERENCE §3.1.

### Visibility
- **Vein security row** (vein detail panel, vein list): the current weekly guard cost (guard count × `weeklyWage`) next to the security label. It taps through to Guard Costs.
- **Guard purchase button:** shows the added weekly wage beside the purchase price (vein +1 Guard and HQ guard alike).
- **HQ security screen:** the current weekly HQ guard cost next to the guard count, tapping through to Guard Costs.
- **BizBrief expenses breakdown** (Stats tab, pot active): expenses per day split by kind — staff wages, guard wages, calc purchases — over the existing stats window. The guard wages series taps through to Guard Costs.
- **Guard Costs screen:**
  - Guard cost over time for HQ and each player vein. Each day's value = that vein's guard cost incurred that day (guards on duty × `weeklyWage` / 7, rounded for display).
  - A filter over HQ and veins (multi-select, default all).
  - A header with this week's bill so far and the pending shortfall, if any.
  - History is a bounded per-day, per-vein record kept from day 1 whether or not the pot exists (`guardCostHistoryDays`, *placeholder* 28). It's pure data in state.
- **Communication.** The Monday paid line and the shortfall warning (veins at risk and the grace deadline) go in notifications and the morning account, and walk-offs get a notice naming each vein that lost guards. All new prose is flagged PROSE-REVIEW.

### Data (JSON, none in code)
- `guardUpkeep`:
  - `weeklyWage` (500)
  - `graceDays` (1)
  - `guardCostHistoryDays`
  - `faction.maxExtraGuardsPerVein`
  - `faction.wageReserveWeeks`

### State (pure data — save, snapshot and Rewind keep working)
- Each vein (player and faction) and `home`: `guardDays` — an int per guard slot, days worked this week.
- `business.float` — int.
- `guardUpkeep.pendingShortfall` — record or null.
- `guardUpkeep.history` — bounded per-day, per-vein guard cost.
- `businessStats` daily tally: expenses split by kind.
- SaveManager backfills all of these for old saves: `guardDays` zeroed to match the current guard count, float 0, no pending shortfall, empty history.

### REFERENCE.md updates
- §1.6 vein security: wage, drop rule, tier loss.
- Home security (HQ guard): wage, drop order last.
- §1.8 faction data: extra-guard cap, wage reserve.
- §2 state schema.
- §3.1 rollover steps.
- §3.10 business pot and payday: float, payday order, guard expense kind.
- §3.12 raiding: faction extra guards feed raid resist.

## Testing Decisions

- Good tests assert external behaviour only. Seed `GameState.state`, drive a public entry point, and assert the resulting state: cash, pot, float, `resources`, security tier, `extraGuards`, `guardDays`, the pending shortfall, ledger/expense lines, notifications. Never assert helper calls.
- **Primary seam: the day rollover** (the time system's daily tick). Examples:
  - A guard hired Wednesday is billed for its days on Monday.
  - Pre-pot cash pays guards on Monday.
  - With the pot active, staff are paid before guards, then the float covers the rest, and the float isn't split.
  - A short Monday creates a shortfall, guards still defend during grace, and an ignored shortfall auto-drops extras from the least valuable vein first, then tier guards (`guarded` → `warded`).
  - Leftover reserve goes to the float.
  - HQ guards are billed with vein guards and auto-dropped only after every vein guard.
  - A tier move below the guard's `minTier` drops HQ guards and their days, with no bill.
  - A broke faction loses guards by the same order.
  - A faction buys extra guards only with the wage reserve and within the cap.
  - An old save's guards start at 0 days.
- **Secondary seams:**
  - `Business.donate` / `withdraw`: bounds, bank records, not revenue.
  - The shortfall confirm function: keep counts, reserve-then-cash payment, refusal when cash is short, immediate walk-offs.
  - `Cultivating.upgrade_vein_security`: a new guard starts at 0 days.
  - `Business.pay_calc_purchase`: falls back to the float.
- Rng is seeded wherever a tick step is probabilistic.
- Save round-trip: the new keys survive save/load and backfill on an old save.
- Prior art:
  - time-system rollover tests (Monday home bill, arrears weeks)
  - business tests (payday split, owed wages, calc purchase)
  - payroll tests (Monday room wages)
  - faction tests (security spend, kit allocation value order)
  - raiding tests (guard repel)
- Suite discipline: one targeted run per change, and one full suite + check_all at the end.

## Out of Scope

- Pressure AI reacting to guard strength or to a rival's lost guards (sub-spec 4a).
- Stockpile guards or stockpile raids (sub-spec 4b).
- Act 2 questline beats mentioning upkeep or the float (sub-spec 5). Upkeep and the float work without any quest flag.
- Guard wage numbers beyond placeholders. The tuning pass pins them.
- Guard wages scaling with vein value, or a rising wage per extra guard.
- A rehire discount for walked guards.

## Further Notes

- **Differences from the macro spec (agreed; the macro has been updated to match):**
  - Wages build up daily but are paid weekly (Monday), not charged daily.
  - Upkeep starts on day 1, not at Act 2.
  - Bills draw the pot first, with the float as backup (not float first).
  - When wages are short, a choose-who-to-pay menu plus one grace day, then automatic drops — not one guard walking per vein per day.
  - Factions also buy extra guards.
  - BizBrief gets an expense breakdown and a Guard Costs screen.
- The float being available from pot activation (Act 1 Beat 3) rather than from an Act 2 unlock follows from wages starting on day 1. Sub-spec 5 may add a quest moment that points at it, but it doesn't gate it.
- A squeezed faction losing guards feeds later sub-specs: 4a escalation reads a weakened rival, and 4b raids hit softer veins.
- Canonical vocabulary: vein (not site) for guard ownership, `cash`, `resources` for faction cash, security tiers `none`/`basic`/`warded`/`guarded`.
