# London Market: real stock and the Soho Marketplace

**Status:** ready-for-agent

## Problem Statement

London looks like a marketplace, but goods do not pass through it. When a faction sells, the goods disappear into a tally. When a faction buys, goods appear from nowhere. Stock snaps most of the way back to normal each day, so shelves refill themselves.

As a result, the player sees prices but not a real economy:

- One faction's surplus never reaches another faction.
- A faction can lose its whole production of a good, and buyers are not affected.
- Controlling production gives little power over price, while a single sale can move price noticeably.
- The player cannot go to the market itself. They can only sell through Archie, or trade with a faction's own holdings.
- Root Feed has no demand outside the Collective, so a good that could shape harvests goes unused.

## Solution

London becomes one central market with real stock, held by tier.

Factions sell surplus into it and buy what they need from it. A much larger crowd of nameless buyers makes up most of the demand, while factions and the player make up most of the production. One sale barely moves a price, but controlling a good's production over time moves it a lot.

The player reaches the market in two ways. Archie's sell lane stays as the early route. From the start of business Act 2, the Soho Marketplace opens as a map pin and shopfront for buying and selling directly. Soho's fees start slightly above Archie's and fall as an order gets bigger, and the top rungs can beat him. The trading screen always shows the current % fee and what it takes to reach the next rung.

Player and faction can still trade directly. Those trades bypass the market, and affect prices only through what happens next: a faction resells what it does not need, buys less, or has less to sell.

Factions use Root Feed on their veins according to how many they own, which helps their harvests and gives it real demand.

## User Stories

### Market as a real place

1. As a player, I want goods sold into London to actually sit in London's stock, so that the market feels like a real place.
2. As a player, I want goods bought from London to leave its stock, so that shortages can happen.
3. As a player, I want each good to have one London price that every route reads, so that the price of a good stays a single fact.
4. As a player, I want market stock to stay stable when nobody is trading heavily, so that prices aren't noise.
5. As a player, I want a dear good to attract fewer nameless buyers, so that prices correct themselves naturally.
6. As a player, I want a dear good to attract more nameless suppliers up to a limit, so that shortages ease but can still be sustained.
7. As a player, I want Conclave corrections to be real trades that visibly matter, so that the faction has an economic identity.
8. As a player, I want London to feel far bigger than the five factions, so that the city has a wider economy.
9. As a player, I want nameless corporations, organisations and individuals to make up most of the demand, so that factions represent production rather than every buy.
10. As a player, I want factions and the player to make up about 70% of item supply at rest, so that named producers shape the market.

### Prices and control

11. As a player, I want a single sale to have only a small effect on price, so that one deal doesn't crash a market.
12. As a player, I want sustained control of a good's production to move its price a lot, so that cornering is a real strategy.
13. As a player, I want a faction cutting supply of its speciality to raise that good's price over time, so that faction power is felt in the market.
14. As a player, I want flood, undercut and deny moves to act on real stock, so that market warfare has real effects.
15. As a player, I want to be able to corner a good myself, so that my growing empire has real market power.
16. As a player, I want Ticker effects and story demand to keep working, so that news still moves markets.

### Tiers

17. As a player, I want market stock held by tier, so that quality still exists once goods enter the market.
18. As a player, I want higher-tier items to cost more, so that quality is worth paying for.
19. As a player, I want to see how much of each tier is in stock, so that I can choose what to buy.
20. As a player, I want to choose which tier I buy, so that I can spend according to my need.
21. As a player, I want items I sell to enter stock at their own tier, so that my quality stays real.
22. As a player, I want better items to earn more when sold, so that crafting skill pays.
23. As a faction, I want to sell items at the tier I crafted, so that skilled crafters earn more.
24. As a faction, I want to buy the cheapest tier that meets my need, so that I spend sensibly.
25. As a player, I want scarcity of a good to affect its whole price, so that tiers stay easy to understand.

### Faction trade

26. As a faction, I want to sell surplus into London, so that I earn from my production.
27. As a faction, I want to buy needed goods from London stock, so that I can cover what I don't craft.
28. As a faction, I want another faction's sale to be available to me on the same day, so that goods flow through the market.
29. As a faction, I want buying limited to what is in stock, so that shortages are real.
30. As a faction, I want to pay only for what I actually received, so that my wallet stays correct.
31. As a player, I want no faction to always get first pick of a short shelf, so that shortages don't favour one faction forever.
32. As a player, I want an empty shelf to leave a faction short, so that I can see the consequences through existing shortfall behaviour.
33. As a player, I want a faction to run short when the only crafter of a good stops selling it, so that production matters.
34. As a player, I want factions to keep trading in London while at war, so that the market remains neutral ground.
35. As a player, I want Conclave arbitrage, stabilising and positions to be limited by real stock, so that it can't conjure goods.

### Direct trades

36. As a player, I want to keep trading directly with factions, so that relationships still pay off.
37. As a player, I want direct trades to skip market stock, so that those goods really went to that faction.
38. As a player, I want a large direct sale to lower London prices if the faction resells the goods, so that dumping has natural consequences.
39. As a player, I want a sale to a faction to reduce what it needs from London, so that demand falls naturally.
40. As a player, I want buying a faction's goods to reduce what it can put on the market, so that supply tightens naturally.
41. As a player, I want business calc purchases to behave like other direct trades, so that the rule stays consistent.

### Archie

42. As a player, I want to keep selling through Archie, so that I have a route before Soho opens.
43. As a player, I want Archie's sales to enter London stock, so that he is a real way into the market.
44. As a player, I want Archie's tag-along deals to stay available, so that he still arranges lucrative sales.
45. As a player, I want a reason to keep Archie after Soho opens, so that he doesn't become obsolete on small and early sales.

### Soho Marketplace

46. As a player, I want the Soho Marketplace to open at business Act 2, so that it arrives when my volumes justify it.
47. As a player, I want the event text to explain the split between Soho and Archie, so that I know when to use each.
48. As a player, I want a Soho pin on the map, so that I can find the market.
49. As a player, I want no Soho pin before it unlocks, so that the map stays honest about what I can use.
50. As a returning player already past that point, I want Soho unlocked in my save, so that I don't lose access.
51. As a player, I want to buy and sell ore in Soho, so that I can use the market directly.
52. As a player, I want to buy and sell items by tier in Soho, so that I get the quality I want.
53. As a player, I want to see stock and price for each good, so that I can judge the market.
54. As a player, I want purchases limited by stock and my cash, so that the market stays real.
55. As a player, I want Soho goods to reach my shared pool, so that my staff and I can use them.
56. As a player, I want sales taken only from my shared pool, so that stashed goods stay protected.
57. As a player, I want Soho to carry no mugging risk, so that safety is part of what I pay for.
58. As a player, I want empty goods shown as empty, so that I understand why I can't buy.

### Fees and rungs

59. As a player, I want Soho's fee at small volumes to be slightly above Archie's, so that small sales suit him.
60. As a player, I want fees to fall as my order grows, so that volume is rewarded.
61. As a player, I want the top rungs to be able to beat Archie, so that bulk trading has a home.
62. As a player, I want to see the % fee update as I scale volume up and down, so that I always know what I'm paying.
63. As a player, I want to see the £ fee and my net result, so that I know the real outcome before confirming.
64. As a player, I want to see the next rung and how much more volume reaches it, so that I can decide whether to scale up.
65. As a player, I want to see what fee the next rung gives, so that I know what scaling up is worth.
66. As a player, I want to see every rung at a glance, with my position on the ladder, so that the system is intuitive.
67. As a player, I want a clear signal when I cross a rung, so that I notice the change.
68. As a player, I want to see the best rate reached when I'm on the top rung, so that I stop looking for more.
69. As a player, I want to see how Soho compares with Archie for my current order, so that I can choose the better route.
70. As a player, I want the fee shown to be exactly what I'm charged, so that I can trust the screen.

### Root Feed

71. As a faction, I want a Root Feed want based on my veins, so that my demand fits my operation.
72. As a producer faction, I want a higher want than crafting factions, so that faction identity shows in what I buy.
73. As a faction, I want my want capped, so that I don't spend without limit.
74. As a faction, I want my want to stay steady as veins are fed, so that I don't sell and rebuy feed daily.
75. As a faction, I want to buy Root Feed from the market, so that I don't have to craft it.
76. As a faction, I want to keep feed up to my want, so that it isn't sold straight back.
77. As a faction, I want applying feed to raise vein growth, so that my harvests improve.
78. As a player, I want to see stronger harvests from fed faction veins, so that the good's value is real.
79. As a player, I want Root Feed supply to be able to meet faction demand, so that the market isn't permanently empty.
80. As a player who owns the base Root Feed rung, I want Root Feed sales offers, so that I can supply factions.
81. As a player, I want no Root Feed offers before I own the rung, so that offers match what I can make.
82. As a player, I want Root Feed offers weighted towards factions that want it, so that offers make sense.
83. As a player, I want Root Feed I sell to a faction to be used on its veins, so that my sale has an effect.

### Saves and determinism

84. As a returning player, I want my save to move to the new market without a price jump, so that the update doesn't disrupt my game.
85. As a player, I want Rewind to restore market stock by tier exactly, so that the flagship feature still works.
86. As a player, I want market results to be repeatable under the same seed, so that Rewind stays fair.

### Balance outcomes

87. As a designer, I want named producers at 65-75% of item supply at rest, so that the market matches its design.
88. As a designer, I want ore named share to stay close to today's, so that the ore economy isn't disrupted.
89. As a designer, I want no good pinned at minimum or maximum price at rest, so that the market stays healthy.
90. As a designer, I want no faction in permanent shortfall of something it needs, so that the sim stays stable.
91. As a designer, I want proof that withholding moves a price materially and a single sale doesn't, so that the central promise holds.
92. As a designer, I want turf, rivalry and diplomacy to stay healthy, so that the market doesn't break other systems.
93. As a designer, I want player income through Archie to stay comparable at a similar stage, so that progression holds.
94. As a designer, I want buying then reselling in Soho to lose money at every rung, so that the market can't be farmed.
95. As a designer, I want faction wallet growth reported, so that I can decide whether it needs action.

## Implementation Decisions

### Market module

- Each good keeps one quote. Items hold stock per tier, 1 to 5. Ore has no tiers.
- Stock is conserved. It changes only through recorded and nameless flows. Fixed reversion is removed, and the independents buy cover is replaced by supply elasticity.
- The price curve reads a good's total stock across tiers. There is one scarcity signal per good.
- A tier's price is the good's quote × the existing quality multiplier (+25% a tier above tier 1).
- `normalStock` rises to about 14 days of civilian demand, to damp single sales without raising flows.
- Nameless demand falls as price rises, with a floor. Independents supply rises as price rises, up to a cap. The cap keeps cornering meaningful.
- `independentsShare` stays at 0.3 and `independentsOreShare` at 0.4, which match the 70% target.
- Independents supply enters stock across tiers by a data-driven mix, weighted to low tiers.
- Nameless demand draws across tiers in proportion to stock, using deterministic whole units.
- Availability is a new public read per good and tier: stock plus today's supply, less today's demand, floored at 0.
- Items with no tier enter stock as tier 1. Multi-target items enter as their base item at their tier. Soho never sells multi-target items.

### Faction trade

- The daily trade has two passes: every faction sells, then every faction buys, so surplus reaches other factions the same day.
- When stock cannot cover everyone, the first faction served rotates by day, seeded stably for Rewind.
- All market moves are limited by availability: daily buys, deny, stabiliser, stock-up, arbitrage and positions.
- A faction sells at the tiers it holds, and is paid each tier's price.
- A faction buys the lowest available tier first. Goods reach holdings at that tier.
- An empty shelf feeds the existing shortfall path. No new AI is added. Cornering is emergent, through existing withhold, flood and deny moves.
- There is no war rule. The market is anonymous.

### Routes

| Route | Touches stock |
|---|---|
| Faction London trade | Yes |
| Archie sell lane | Yes |
| Sell-at-market event op | Yes |
| Soho Marketplace | Yes |
| Player-faction lanes | No |
| Business calc purchases | No |
| Contract deliveries | No |
| Archie tag-along deals | No |

Direct routes stop recording to Market tallies, so their price effect comes only from later faction behaviour.

### Root Feed

- Want = owned veins × `wantDays` × faction `wantMult`, capped. It uses owned veins rather than unfed veins, because an unfed count falls on feeding and would make the faction sell and rebuy.
- `wantMult` is highest for `producer` factions and lower for crafting factions.
- Want adds to the Root Feed reserve.
- Applying feed is the real consumption. No `consumes` entry is added, because that would burn stock with no harvest benefit.
- The "which factions consume this" read includes wanting factions, weighted by want, so offers and overlaps see them.
- Feeding skips tiers worth 0 days, so tier 0 feed cannot stop a faction using better feed.
- Root Feed crafting supply rises to meet want.
- Offers for Root Feed appear after the base rung. Sell lanes stay ungated. The Collective may buy like any other faction.

### Soho Marketplace

- A new Soho system owns trading, fee calculation and pure rows for the screen. Screens only read rows and call system functions.
- A new unlock flag is set by the business Act 1 closing event, and backfilled on load where that event is complete.
- Fees use rungs by order value, with separate sell and buy ladders held as data.
- Sell fee at the first rung = Archie's current fee + a small margin. Each rung takes off a data-driven reduction. High rungs can fall below Archie's fee, down to a data-driven floor.
- Buy markup follows its own falling ladder.
- A rung's rate applies to the whole order.
- Order value covers the whole cart, so rungs work across goods and tiers.
- The ladders must be set so that buying then reselling loses money at every rung and tier.
- No mugging, relation gain or Archie cut applies. Sales draw on the shared pool only. Purchases go to the shared pool at the tier bought.
- There is no daily buy cap. Depth and fees limit flipping. Balance watches this.

### Trading screen

- Soho extends the existing Trade view as a new mode rather than adding a separate screen.
- For the current order, the fee row returns the current rung and % rate, the £ fee, the net result, the next rung's threshold and rate, the £ and units still needed, the full ladder, and Archie's comparable fee.
- The screen shows a rung ladder with the player's position, and updates live as quantity moves up or down.
- It shows the next step in plain terms, such as how much more to sell to reach a lower %.
- It marks crossing a rung, and shows when the best rate is reached.
- Exact layout follows `docs/ui-vision.md` and is checked by human on-device QA.

### Schema

- Market good state gains per-tier item stock. All of it stays pure data for save, snapshot and Rewind.
- Old saves are migrated once: stock is rescaled to the new `normalStock` and split across tiers by the Independents mix, keeping prices steady.
- Market data gains elasticity, cap, tier mix, and Soho fee ladder values. All new numbers are placeholders for balance.
- Faction data gains `wantMult`. Vein growth data gains `wantDays` and the cap.
- REFERENCE.md §1.8, §3.4, §3.6, §3.13 and the daily order are updated. `CONTEXT.md` defines London market, Soho Marketplace and Guild Marketplace.

### Delivery order

1. Sim reports item flows, tier stock and named share, and records the baseline.
2. Conserved tiered stock with elastic flows.
3. Direct trades leave the market.
4. Faction trade uses real stock.
5. Root Feed wants, plus the offers work.
6. Soho trading system and fee ladders.
7. Soho pin and trading screen, with fee rung display.
8. Prose beat for Soho and Archie.
9. Final tickets: balance testing, checking the result against the user stories above, especially Balance outcomes. They report before and after tables for human sign-off.

## Testing Decisions

Good tests assert outcomes a player or author sees through a public seam. They do not assert private helpers or layout. They set state directly and cap every loop.

| Seam | Covers |
|---|---|
| Rollover and Market reads | Stock by tier, prices, availability, conservation, elasticity, supply cap, migration |
| FactionSim holdings and wallets after the daily trade | Two-pass trade, tiers, rotation, shortfall, Root Feed want and use, direct-trade consequences |
| Soho system results and fee rows | Unlock, buys, sells, fee rates, rungs, next-rung data, Archie comparison, flip protection |
| Faction economy sim | Balance outcomes across at least 3 seeds |

- Prior art: the existing market, faction sim, economy, shares, offers and map pin test files, and the headless faction economy sim.
- Sim runs use an isolated user data folder, so autosaves do not touch real saves.
- The trading screen gets human on-device QA. Its numbers are tested through the fee rows.
- Test that one tiered stock change round-trips through save and Rewind.

## Out of Scope

- Equipment, device components and recipe fragments in Soho.
- New FactionAI behaviour for cornering.
- War embargoes or market bans.
- Separate scarcity pricing per tier.
- Changing Archie's cut, sell lane or tag-along deals.
- Gating sell lanes by demand.
- Renaming the Guild Marketplace.
- Fixing faction wallet inflation, unless requested after balance reporting.

## Further Notes

- **Supersedes:** ticket 19 in the authoring and inventory pass, which adds direct Collective sales. Ticket 20 needs reworking to match this spec's Root Feed decisions.
- **Baseline (60-day sim, seed 1, days 31+):** named ore harvest is 1,699/day (74% of harvest). Independents add 606/day. Civilian plus derived ore demand is about 1,020/day. Crafting is 2,396 ore-equivalent/day, with Independents at 57-80% by ore, so named producers sit at about 20-43%.
- **Scale of change:** at 70%, named crafting needs about 1,680 ore/day. Total sinks reach about 2,700/day against about 2,330/day of supply, so harvest needs about 15-20% more, or sinks must fall. This is an estimate until item flows are measured.
- **Faction wallets:** these reach £78k-£742k by day 60, from £200-£1,200. Paying factions by tier and raising output may add to this.
- **Rung edges:** because a rate applies to the whole order, an order just past a buy rung can cost less than one just below it. This is accepted for clarity, and the screen can make use of it as a prompt.
- **Archie after Soho:** he keeps small and mid-size sales, relation gain and tag-along deals. Bulk trading moves to Soho, by design.
