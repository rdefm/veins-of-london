# Biz Act 2 — Sub-spec 3: Guard upkeep + business float

Status: ready-for-agent

> Sub-spec 3 of `.scratch/biz-empire-act2/spec.md` (macro vision). Near-independent of sub-specs 1 and 2. It reads faction cash (`resources`) and the faction vein value order from sub-spec 2 (`.scratch/COMPLETED/biz-act2-faction-economy_COMPLETED/spec.md`), which is built. Covers weekly guard wages paid in advance for player veins, HQ (home) guards and faction veins; the short-pay menu and walk-offs; factions hiring extra guards; the business float; and the BizBrief expense and guard-cost views. Numbers marked *placeholder* are feel targets. The tuning pass pins them in JSON and REFERENCE.md.

## Problem Statement

Guards are a one-off purchase. A player buys a Hired Guard and then stacks extra guards on a vein, or hires guards for HQ, and none of it ever costs anything again. Security never pressures cashflow, so there's no trade-off between guarding everything and paying for it. Factions don't feel it either: they harden their best veins until they're maxed out and never pay a penny to keep them that way. A rival that's being squeezed keeps its defences no matter how broke it gets.

The business pot has the opposite problem. It pays out everything at every payday: whatever is left after bills is split between the player and the partners. So a week with low contract income can't cover wages, and the player has no way to top the business up without the top-up being split away on Monday.

## Solution

- **Guards are hired, not bought.** Guards have no purchase price. Every guard — the Hired Guard tier guard on a vein, each extra guard, and each HQ guard — costs a flat **£500 a week, paid in advance**:
  - **Hiring** pays up front for the rest of the current week (Monday to Sunday), prorated: a guard hired on a Monday costs £500, one hired on Wednesday costs £357 to cover Wednesday to Sunday.
  - **Every Monday** after that, each guard costs £500 in advance for the week ahead.
  - This applies from day 1 of the game.
  - Locks and ward runes stay one-off purchases.
- **Who pays.**
  - Hiring is paid from the player's cash.
  - Before the business pot exists, the Monday bill comes from the player's cash.
  - Once the pot is active, the Monday bill is paid at payday: staff wages first, then guard wages. Each bill draws the pot first, then the float as backup.
- **Short on wages.**
  - If Monday's guard bill can't be covered, the player gets a menu. It lists HQ and every guarded vein and lets them choose how many guards to keep at each, paying the difference from their own cash. Guards they don't keep walk off.
  - The player has one grace day to decide. Unpaid guards stay on duty during it.
  - If they ignore it, guards are dropped automatically: extra guards on the least valuable veins first, then tier guards, then HQ guards last.
  - When a vein loses its last guard, it drops out of the Hired Guard tier.
- **Business float.** Once the pot is active, the player can donate cash into a reserve float and withdraw it at any time. Payday never splits the float. It only pays a bill (staff wages, guard wages, calc bought for Sales contracts) when the pot can't cover it.
- **Factions pay too.** Factions hire guards the same way, paying the prorated advance and then £500 per guard every Monday from faction cash. A faction that can't pay loses guards by the same drop order. Factions now also hire extra guards, not just the tier guard, but only when they can afford to keep them for a while. A rival squeezed for cash loses its defences.
- **Visibility.**
  - The weekly cost is shown wherever a guard is hired and on every vein's and HQ's security row.
  - BizBrief breaks expenses down by kind (staff wages, guard wages, calc purchases).
  - Tapping guard wages opens a Guard Costs screen: guard cost over time for HQ and each vein, with a filter to show only chosen ones.

## User Stories

### Guard wages — player
1. As a player, I want every Hired Guard and extra guard to cost £500 a week with no purchase price, so that security is an ongoing commitment rather than a one-off buy.
2. As a player, I want locks and ward runes to stay one-off purchases, so that basic security isn't a running cost.
3. As a player, I want all guards to cost the same flat £500 a week, so that I can work out my guard bill in my head.
4. As a player, I want to pay for a guard in advance when I hire it, so that hiring has an immediate, honest cost.
5. As a player hiring midweek, I want to pay only for the days left until Monday, so that a guard hired on Saturday doesn't cost a full week.
6. As a player, I want every guard's next week paid in advance each Monday, so that guard wages settle alongside my other weekly bills.
7. As a player, I want guard wages to apply from day 1, so that the cost of security is part of the game from the start.
8. As a player before the business pot exists, I want the Monday guard bill taken from my cash, so that it's paid without extra steps.
9. As a player with an active business pot, I want the Monday guard bill paid from the pot at payday, so that it sits with the other business costs.
10. As a player, I want staff wages paid before guard wages when the pot is short, so that my staff keep working.
11. As a player, I want the float to cover guard wages the pot can't, so that my donation protects my guards.
12. As a player, I want never to have my cash silently taken for the Monday guard bill once the pot exists, so that business and personal money stay apart unless I choose otherwise.
13. As a player, I want to see the weekly guard cost on each vein's security row, so that I know what each vein's protection costs.
14. As a player, I want to see the up-front cost and the weekly wage before I hire a guard, so that I'm not surprised.
15. As a player, I want the Monday notification to say what my guards were actually paid, so that I know where my money went.

### HQ guards
16. As a player, I want HQ guards to cost the same £500 a week with no purchase price, paid with my vein guards, so that home security is an ongoing commitment too.
17. As a player, I want HQ guards in the short-pay menu alongside my veins, so that I choose between protecting home and protecting veins.
18. As a player who ignores the menu, I want HQ guards dropped only after every vein guard, so that the place I live is protected longest.
19. As a player, I want the HQ security screen to show the weekly guard cost and the up-front cost before I hire another guard, so that I'm not surprised.
20. As a player who moves to a tier below the HQ guard's minimum tier, I want those guards to leave and never be billed again, so that I don't pay for guards I no longer have.

### Short-pay menu and walk-offs
21. As a player who can't cover Monday's guard bill, I want a menu listing HQ and each guarded vein with its guards, so that I can choose where to keep guards.
22. As a player, I want to set how many guards to keep at each place and see the cost as I adjust, so that I can prioritise my most important veins.
23. As a player, I want to pay the difference from my own cash in that menu, so that I can keep guards I care about.
24. As a player, I want guards I don't keep to walk off immediately when I confirm, so that the choice is clear and final.
25. As a player, I want a dropped guard to cost nothing, so that dropping a guard really does cut the bill.
26. As a player, I want a one-day grace period before unpaid guards walk, so that I can sort out the money.
27. As a player, I want unpaid guards still to defend my veins during the grace day, so that the warning isn't already a loss.
28. As a player who ignores the menu, I want guards dropped automatically, so that the game doesn't stall.
29. As a player, I want automatic drops to take extra guards from my least valuable veins first, then tier guards, then HQ guards, so that my best veins and my home keep their protection longest.
30. As a player, I want a vein to leave the Hired Guard tier when its last guard walks, so that its raid resistance honestly reflects that it's unguarded.
31. As a player, I want the vein to keep its lock and ward rune when its guards walk, so that I only lose what I stopped paying for.
32. As a player, I want to rehire a walked guard the normal way (prorated advance, no purchase price), so that I can rebuild security when I can afford it.
33. As a player, I want the menu reachable from BizBrief and from the morning notification, so that I can find it during the grace day.
34. As a player, I want a clear notice naming the veins that lost guards, so that I know which veins are now exposed.
35. As a player who sells or loses a vein, I want its guards to go with it and never be billed again, so that I'm not paying for a vein I no longer own.

### Business float
36. As a player with an active business pot, I want a button to donate cash into a reserve float, so that bills get paid even when contract income is thin.
37. As a player, I want payday never to split the float, so that my donation isn't handed to my partners.
38. As a player, I want bills to use pot income first and the float only when the pot can't cover them, so that the float lasts as long as possible.
39. As a player, I want the float to back up staff wages, guard wages and Sales calc purchases, so that it protects every part of the business.
40. As a player, I want to withdraw any unspent float at any time, so that the donation isn't a trap.
41. As a player, I want to see the float balance next to the pot in BizBrief, so that I know how much reserve I have.
42. As a player, I want donations and withdrawals recorded in my bank history, so that my personal money is accounted for.
43. As a player, I want the float not to count as business revenue, so that my stats show what the business actually earned.

### Faction guard upkeep
44. As a player, I want factions to hire guards the same way I do and pay them each Monday from their own cash, so that security costs them too.
45. As a player, I want a faction that can't pay to lose guards — extra guards on its least valuable veins first, then tier guards — so that squeezing a rival strips its defences.
46. As a player, I want factions to hire extra guards on their valuable veins, so that a well-funded rival's best veins are hard to raid.
47. As a player, I want factions to hire a guard only when they can afford to keep it for a while, so that they don't hire guards they'll lose next Monday.
48. As a player, I want a faction vein that loses its last guard to drop out of the Hired Guard tier, so that raid odds reflect the loss.
49. As a player, I want faction guard wages to be part of how a faction's cash is spent, so that a faction's wealth shows in its defences.

### Visibility
50. As a player, I want BizBrief to break expenses down into staff wages, guard wages and calc purchases, so that I can see where the business's money goes.
51. As a player, I want to tap guard wages in that breakdown to open a Guard Costs screen, so that I can dig into security spending.
52. As a player, I want the Guard Costs screen to chart guard cost over time for HQ and each vein, so that I can see which are expensive to protect.
53. As a player, I want to filter the Guard Costs screen to HQ or specific veins, so that I can compare the ones I care about.
54. As a player, I want the Guard Costs screen to show next Monday's guard bill, so that I know what's coming.
55. As a player, I want to open the Guard Costs screen from a vein's or HQ's security row, so that I can check it before the pot exists.

### Save and rewind
56. As a player with an old save, I want my existing guards to count as paid up until the next Monday, so that updating doesn't hit me with a surprise bill.
57. As a player, I want Rewind to restore guard counts, pending menus and the float exactly, so that time travel stays consistent.

## Implementation Decisions

### Guard counting
- **Veins:** guard count = 1 if the security tier is `guarded` (the Hired Guard tier guard), plus `extraGuards`. The same for player and faction veins.
- **Vein guard slots** are ordered: tier guard first, then extras in hire order.
  - Every drop removes the last slot — newest extra first, tier guard last — so a vein only loses its tier guard once it has no extras left.
  - Removing the tier guard sets the security tier from `guarded` to `warded`.
  - Lock (`basic`) and ward rune (`warded`) are never lost to unpaid wages.
- **HQ:** guard count = `home.guardCount`.
  - HQ guards all stack as one kind, and drops remove the newest first.
  - HQ has no tier to lose: `guardCount` just falls, and `home.security` is unchanged.
  - A tier move that loses HQ guards (below the guard's `minTier`) removes them with no refund and no further bill.

### Hiring: no purchase price, prorated advance
- **Vein prices removed.** The `guarded` tier price and the escalating extra-guard price curve are gone. Hiring the tier guard or an extra guard costs only the advance.
- **HQ price removed.** The HQ guard's purchase price is gone. Hiring costs only the advance; `minTier` still applies.
- **Advance amount:** `round(weeklyWage × daysLeft / 7)`, the same proration as staff wages (`Business.prorated_wage`). `daysLeft` = days from today through Sunday inclusive: 7 on a Monday, 1 on a Sunday.
- **Paying:** the player pays the advance from cash (bank record "Guard hire"). It's recorded as a guard expense for that vein or HQ in BusinessStats. If cash is short, hiring is refused.
- **Faction hires** pay the same advance from `resources`.
- No refund when a guard walks, its vein leaves its owner (sold, lost to a raid, collapsed, bought out) or an HQ tier move removes it. Its paid week is simply forfeited.

### Weekly wage (Monday, in advance)
- `weeklyWage` per guard, the same for tier, extra and HQ guards: **£500** (pinned, not a placeholder). It lives in JSON, never in code.
- On the rollover into a Monday, each guard on duty costs `weeklyWage` in advance for the week ahead.
- The player's bill = £500 × (all vein guards + HQ guards).
- Nothing builds up between Mondays, so there's no per-guard day counter in state.
- **Faction veins claimed at the `guarded` tier:** the tier guard costs nothing on the claim day. The faction pays for it from the next Monday.
- **Old saves:** existing guards (player, HQ, faction) count as paid through the coming Sunday. The first bill is the next Monday.

### Player Monday bill
- **Pot not active:** the bill is taken from player cash (bank record "Guard wages") if cash covers it in full. Otherwise nothing is taken yet and the short-pay flow starts, with player cash as the only source.
- **Pot active:** inside the payday, after staff wages and before the partner split:
  - Staff wages are paid as today. A staff wage the pot can't cover draws on the float before becoming owed. It's still paid in full or not at all per contact, and the existing owed-wage prompt is unchanged.
  - Then the guard bill draws the pot, then the float. If both together cover it, it's paid.
  - If not, all the pot and float money available for guards is set aside as a guard wage reserve (not split, not left in the float), and the short-pay flow starts.
  - The partner split runs on whatever pot remains.
- Guard wages are business expenses (kind `guard`, with the vein id or `home`) in the week's expense list, the ledger record and BusinessStats.

### Short-pay flow (player)
- **State:** a pending guard shortfall record holds the payday day, the grace deadline (next rollover), each place's guard count, and the reserve (£ set aside from pot + float; 0 before the pot).
- **Menu:** reachable from the Monday morning notification and a BizBrief Brief attention row. For HQ and each guarded vein, the player sets guards to keep (0..N). Keeping `k` guards costs `k × weeklyWage`. The menu shows the total cost, the reserve, and the cash needed on top.
- **Confirm** (a system function; screens only call it):
  - Kept guards are paid £500 each for the week (the grace day counts as part of it), from the reserve first, then player cash.
  - Unkept guards walk now, following the drop rule.
  - Leftover reserve goes into the float, or to player cash before the pot exists.
  - Refused if cash can't cover the difference.
- **Grace:** while the shortfall is pending, all its guards stay on duty and count for raid resist and repel.
- **Auto-resolve** at the grace rollover if unconfirmed:
  - Guards are kept in priority order, funded only by the reserve (pot era) or player cash (pre-pot). The keep order is the reverse of the drop order.
  - Drop order: extras first, least valuable vein first; then tier guards, least valuable vein first; then HQ guards last, newest first.
  - Kept guards are paid £500 each. Unfunded guards walk. Leftover reserve goes as on confirm.
- **Vein value order:** the same order sub-spec 2 uses for faction kit allocation (combined magnitude, ties by site id). Player and faction veins use one shared helper.
- Only one shortfall can be pending at a time. The grace deadline is always the next rollover, so it clears well before the next Monday.

### Business float
- `business.float` is an int £ ≥ 0, separate from `pot`. It only exists while the pot is active: donate is refused before then.
- `Business.donate(amount)`: moves cash to the float (1 ≤ amount ≤ cash), with a bank record. Not revenue.
- `Business.withdraw(amount)`: moves float to cash (1 ≤ amount ≤ float), with a bank record.
- Payday never touches the float in the split. The float only drains through backup draws:
  - staff wages
  - the Monday guard bill (including the guard wage reserve)
  - Sales calc purchases, which now take pot + float, still in full or not at all
- The float is shown beside the pot in the BizBrief Brief bank block, with Donate and Withdraw controls.

### Faction guard upkeep and extra guards
- **Monday bill.** Each faction pays £500 per guard from `resources`, as much as it can cover. Guards are kept in the same priority order and unfunded guards walk immediately. There's no grace or menu, and `resources` never goes negative.
- **Hiring.**
  - The faction daily security spend continues past `guarded` into hiring extra guards, capped per vein (`maxExtraGuardsPerVein`, *placeholder* 3).
  - Moving up to `guarded` and each extra guard cost only the prorated advance.
  - A hire needs `resources ≥ advance + wageReserveWeeks × the faction's weekly guard bill after the hire` (*placeholder* 2 weeks).
  - It keeps the existing one upgrade per faction per tick and highest-value-vein-first targeting.
- **Rollover position.** The faction Monday bill runs after faction industry income and before faction security upgrades. The security spend then sees post-wage cash and never hires a guard it just failed to pay.

### Rollover order
- The pending shortfall's grace auto-resolve runs early in the rollover.
- Faction Monday bill (Monday only) comes before faction security upgrades.
- Player Monday bill runs in the business payday step when the pot is active. Otherwise it runs in the same step-⑥ slot on its own.
- The ticket fixes the exact step letters in REFERENCE §3.1.

### Visibility
- **Vein security row** (vein detail panel, vein list): the current weekly guard cost (guard count × `weeklyWage`) next to the security label. It taps through to Guard Costs.
- **Guard hire button** (vein Hired Guard / +1 Guard, HQ guard): shows today's advance and "then £500/week" instead of a purchase price.
- **HQ security screen:** the current weekly HQ guard cost next to the guard count, tapping through to Guard Costs.
- **BizBrief expenses breakdown** (Stats tab, pot active): expenses per day split by kind — staff wages, guard wages (hire advances + Monday bills), calc purchases — over the existing stats window. The guard wages series taps through to Guard Costs.
- **Guard Costs screen:**
  - Guard cost over time for HQ and each player vein: the actual payments (hire advances and Monday bills) per day.
  - A filter over HQ and veins (multi-select, default all).
  - A header with next Monday's bill and the pending shortfall, if any.
  - History is a bounded per-day, per-place record kept from day 1 whether or not the pot exists (`guardCostHistoryDays`, *placeholder* 28). It's pure data in state.
- **Communication.**
  - Notifications and the morning account carry the Monday paid line and the shortfall warning (places at risk and the grace deadline).
  - Walk-offs get a notice naming each place that lost guards.
  - All new prose is flagged PROSE-REVIEW.

### Data (JSON, none in code)
- `guardUpkeep`:
  - `weeklyWage` (500)
  - `graceDays` (1)
  - `guardCostHistoryDays`
  - `faction.maxExtraGuardsPerVein`
  - `faction.wageReserveWeeks`
- The `guarded` tier `cost` in the vein security data and the HQ guard `cost` in the home data are removed, or set to 0, per the ticket's choice. The extra-guard cost curve is deleted.

### State (pure data — save, snapshot and Rewind keep working)
- `business.float` — int.
- `guardUpkeep.pendingShortfall` — record or null.
- `guardUpkeep.history` — bounded per-day, per-place guard cost.
- `businessStats` daily tally: expenses split by kind.
- No new per-guard state: guard counts stay in the existing security tier, `extraGuards` and `home.guardCount`.
- SaveManager backfills all of these for old saves: float 0, no pending shortfall, empty history.

### REFERENCE.md updates
- §1.6 vein security: no guard purchase price; advance and weekly wage; drop rule; tier loss.
- Home security (HQ guard): no purchase price; wage; drop order last.
- §1.8 faction data: extra-guard cap, wage reserve.
- §2 state schema.
- §3.1 rollover steps.
- §3.10 business pot and payday: float, payday order, guard expense kind.
- §3.12 raiding: faction extra guards feed raid resist.

## Testing Decisions

- Good tests assert external behaviour only. Seed `GameState.state`, drive a public entry point, and assert the resulting state: cash, pot, float, `resources`, security tier, `extraGuards`, `guardCount`, the pending shortfall, ledger/expense lines, notifications. Never assert helper calls.
- **Primary seam: the day rollover** (the time system's daily tick). Examples:
  - Every guard costs £500 on the Monday rollover.
  - Pre-pot, cash pays the Monday bill.
  - With the pot active, staff are paid before guards, then the float covers the rest, and the float isn't split.
  - A short Monday creates a shortfall, and guards still defend during grace.
  - An ignored shortfall auto-drops extras from the least valuable vein first, then tier guards (`guarded` → `warded`), then HQ guards.
  - Leftover reserve goes to the float.
  - A broke faction loses guards by the same order.
  - A faction hires extra guards only with the wage reserve and within the cap, paying the prorated advance.
  - An old save's guards aren't billed until the next Monday.
- **Secondary seams:**
  - Vein guard hire (`Cultivating.upgrade_vein_security`) and HQ guard hire: the prorated advance by weekday (Monday £500, Wednesday £357, Sunday £71), no purchase price, refused when cash is short.
  - `Business.donate` / `withdraw`: bounds, bank records, not revenue.
  - The shortfall confirm function: keep counts, reserve-then-cash payment, refusal when cash is short, immediate walk-offs.
  - `Business.pay_calc_purchase`: falls back to the float.
  - HQ tier move below `minTier`: guards removed, no refund, not billed next Monday.
- Rng is seeded wherever a tick step is probabilistic.
- Save round-trip: the new keys survive save/load and backfill on an old save.
- Prior art:
  - time-system rollover tests (Monday home bill, arrears weeks)
  - business tests (payday split, owed wages, calc purchase, prorated wage)
  - payroll tests (Monday room wages, first part-week proration)
  - faction tests (security spend, kit allocation value order)
  - raiding tests (guard repel)
  - home tests (guard purchase, tier-move guard loss)
- Suite discipline: one targeted run per change, and one full suite + check_all at the end.

## Out of Scope

- Pressure AI reacting to guard strength or to a rival's lost guards (sub-spec 4a).
- Stockpile guards or stockpile raids (sub-spec 4b).
- Act 2 questline beats mentioning upkeep or the float (sub-spec 5). Upkeep and the float work without any quest flag.
- Voluntarily dismissing a guard outside the short-pay menu.
- Refunds for unused paid days.
- Guard wages scaling with vein value, or a rising wage per extra guard.

## Further Notes

- **Differences from the macro spec (agreed; the macro has been updated to match):**
  - Guards have no purchase price: £500 a week, paid in advance (prorated to Monday on hire, then every Monday). Not a daily charge.
  - Upkeep starts on day 1, not at Act 2.
  - Bills draw the pot first, with the float as backup (not float first).
  - When wages are short, a choose-who-to-pay menu plus one grace day, then automatic drops — not one guard walking per vein per day.
  - HQ guards follow the same rules.
  - Factions also hire extra guards.
  - BizBrief gets an expense breakdown and a Guard Costs screen.
- The float being available from pot activation (Act 1 Beat 3) rather than from an Act 2 unlock follows from wages starting on day 1. Sub-spec 5 may add a quest moment that points at it, but it doesn't gate it.
- £500 a week per guard is steep next to early-game income. Guards become a mid-game commitment, and factions will run leaner guard rosters than today. Worth watching in playtest and with the tuning tool.
- A squeezed faction losing guards feeds later sub-specs: 4a escalation reads a weakened rival, and 4b raids hit softer veins.
- Canonical vocabulary: vein (not site) for guard ownership, `cash`, `resources` for faction cash, security tiers `none`/`basic`/`warded`/`guarded`.
