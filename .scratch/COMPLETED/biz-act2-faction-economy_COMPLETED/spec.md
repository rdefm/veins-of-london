# Biz Act 2 — Sub-spec 2: Faction economy

Status: ready-for-agent

> Sub-spec 2 of `.scratch/biz-empire-act2/spec.md` (macro vision). Builds on sub-spec 1 (`.scratch/biz-act2-market-sim/spec.md`, built). Covers FactionSim (real faction cultivation, crafting, consumption, buying and selling), faction cash, faction marketplace stock from real holdings, raid item kits and per-vein kit allocation, shares (ore, crafting, supplier), stockpile location state, the retirement of sub-spec 1's stand-in supply, and the Factions app / BizBrief reads. Numbers marked *placeholder* are feel targets; the implementing ticket pins them in JSON and REFERENCE.md.

## Problem Statement

London's market (sub-spec 1) moves on real player trades, but everything else in it is fake: a fixed stand-in supply and demand per good. Factions own veins that produce nothing but an abstract cash trickle. They don't craft or consume anything, and their shops are a random reroll (and only the Collective's is real at all). There is no way to tell who produces what. The player can't be "the main supplier" to anyone, can't see a rival's grip on an ore type, and can't starve a faction of the ore it needs. A war on the Ticker is just a demand number, not factions visibly burning through shields and blasts. Later Act 2 systems (pressure, escalation, intel, stockpile raids) have no real faction economy to read or hit.

## Solution

Factions become real economic actors in the same London market as the player.

- **Veins produce.** Each faction tends its veins and prunes them for real ore, using the player's own growth and yield formulas. Producer factions tend harder; the Guild barely mines.
- **Factions craft.** Each faction crafts its specialist items toward a target holding, with a per-faction crafting skill. Failures burn ore, and items carry a quality tier.
- **Factions consume.** Items are used weekly, and every raid or rivalry attempt burns an item kit from both sides. Item stock is assigned out to each vein's guards, so a faction short of shields has specific veins without them.
- **Factions trade.** They buy their shortfall from London (but won't pay silly prices) and sell spare stock (but won't sell into a crash). The Conclave also buys cheap and sells dear. Faction shops sell what the faction actually holds.
- **Faction cash is real.** A faction's wallet is filled by sales and non-calc industry income and spent on buying and security. It can't go negative, so a faction that runs dry buys and crafts less.
- **Shares.** Over a rolling week, London tracks who harvested each ore type and who crafted with it: the player, each faction, and a steady "Independents" slice. Contract deliveries feed a separate supplier share: how much of each faction's intake the player provides.
- **Stockpiles.** Each faction keeps its goods at a hidden spot in one of its home districts. Who has discovered it is recorded, ready for intel and raids later.
- **Real supply replaces stand-ins.** Faction sales and player sales are the supply. Civilian demand for items and ore stays, shaped by the Ticker. A tunable Independents slice keeps prices steady while the economy is balanced; the end goal is to remove it.
- **Reads.** The Factions app shows each faction's archetype and shares, plus a London overview table. BizBrief shows the player's own shares and their trend.

## User Stories

### Faction veins produce real ore
1. As a player, I want faction veins to produce real ore, so that faction output and market share are genuine.
2. As a player, I want faction veins to follow the same growth and yield rules as mine, so that I can compare their production with my own.
3. As a player, I want factions to tend their veins, so that faction veins don't simply decay and die within two weeks.
4. As a player, I want factions to prune their veins for ore when growth runs high, so that a well-kept faction vein is a productive one.
5. As a player, I want each faction to have a cultivating skill, so that producer factions out-mine crafter factions.
6. As a player, I want a faction vein to still die only by collapsing at zero growth, so that the vein lifecycle I already know stays the same.
7. As a player, I want producer factions (Collective, Firm) to focus on ore output, so that they compete with me on production.
8. As a player, I want the Guild to have small own production, so that it's the obvious customer for a supplier.
9. As a player, I want factions to prefer claiming sites of their primary and secondary ores, so that their identity shows on the map.

### Faction crafting
10. As a player, I want factions to craft their specialist items from their ore, so that item supply comes from somewhere real.
11. As a player, I want each faction to have a crafting skill, so that the Guild's items are better and more reliable than a token crafter's.
12. As a player, I want faction crafts to succeed or fail on the same odds rule as mine, so that faction output is believable.
13. As a player, I want failed faction crafts to burn ore, so that crafter factions are big ore sinks.
14. As a player, I want faction items to carry a quality tier set by the faction's skill, so that buying from the Guild versus the Network means something.
15. As a player, I want factions to craft toward a target holding rather than without limit, so that their output is steady and readable.

### Faction consumption
16. As a player, I want factions to use items every week (e.g. the Firm burns attack and healing items), so that item demand has a real floor.
17. As a player, I want weekly consumption to scale with the Ticker's item demand, so that a war makes factions burn more.
18. As a player, I want every raid and rivalry attempt to burn an item kit from both attacker and defender, so that conflict visibly drains stock.
19. As a player, I want a faction that burned its kit to re-buy it, so that a war raises item prices.
20. As a player, I want a faction's item stock assigned out to its vein guards, so that a shortage lands on specific veins.
21. As a player, I want a faction short of an item to run out vein by vein in a set order, so that shortages are predictable and later revealable by intel.

### Faction trading
22. As a player, I want factions to buy the ore and items they're short of from London, so that crafter factions are big demand sinks I can supply.
23. As a player, I want factions to refuse to buy above a price ceiling, so that cornering an ore really starves a crafter.
24. As a player, I want a faction that can't afford its shortfall to buy and craft less, so that a squeezed faction visibly weakens.
25. As a player, I want factions to sell spare ore and items into London, so that their output affects prices.
26. As a player, I want factions to keep what they'll need for crafting, consumption and raid kits before selling, so that they don't sell themselves short.
27. As a player, I want factions to sell spare stock gradually, so that they don't crash the market in one day.
28. As a player, I want factions to hold stock when prices are crashed, so that the market recovers instead of being dumped on further.
29. As a player, I want the Conclave to buy under-priced goods and sell over-priced ones, so that the market self-dampens and my monopoly faces resistance.
30. As a player, I want big faction buys and sells annotated on the price chart with the faction's name, so that I know why a price moved.

### Faction shops
31. As a player, I want every faction's shop stock to be what that faction actually holds, so that buying from a faction draws down something real.
32. As a player, I want every faction's shop to sell both ore and items, so that I can source goods from any faction.
33. As a player, I want the random shop restock gone, so that shop stock tracks the faction's economy.
34. As a player, I want relation-based buy and sell spreads to still apply at faction shops, so that relations keep mattering at the counter.
35. As a player mid-Collective questline, I want the Collective's buy lane to keep working, so that the questline stays completable.

### Faction cash
36. As a player, I want each faction's money to be real £ earned from selling and spent on buying, so that a faction's wealth reflects its business.
37. As a player, I want factions to keep a smaller non-calc industry income, so that one bad week doesn't bankrupt a crafter.
38. As a player, I want the Conclave to have a high non-calc income, so that it can afford to act as London's stabiliser.
39. As a player, I want faction cash never to go negative, so that a broke faction is limited rather than in debt.
40. As a player, I want faction security upgrades to be paid from the same real cash, so that a faction that's losing money stops hardening its veins.

### Contract deliveries
41. As a player, I want my contract deliveries to land in the buyer faction's stock, so that it needs to buy less from London.
42. As a player, I want my deliveries to count toward a supplier share with that faction, so that my role as their supplier is measured.
43. As a player, I want deliveries not to count toward production share a second time, so that shares aren't double-counted.

### Shares
44. As a player, I want ore share per type measured from ore harvested over a rolling 7 days, so that hoarding still counts as owning production.
45. As a player, I want my staff cultivators' harvests to count as mine, so that my business's output is one row.
46. As a player, I want crafting share per type measured from ore used in successful crafts over a rolling 7 days, so that failed crafts don't inflate it.
47. As a player, I want mixed-ingredient crafts to count toward each ingredient's type by weight, so that a failsafe counts toward both time and life.
48. As a player, I want an Independents row in the share tables, so that shares add up to 100% and I can see how much of London nobody controls.
49. As a player, I want to see each faction's ore and crafting shares in the Factions app, so that I know who dominates what.
50. As a player, I want a London overview table of shares per ore type with myself as a row, so that I see the whole market at a glance.
51. As a player, I want to toggle the overview between ore and crafting shares, so that I can read both kinds of dominance.
52. As a player, I want my own shares and their week-on-week trend in BizBrief, so that I track my progress toward dominance.
53. As a player, I want exact faction holdings kept hidden, so that knowing a rival's stock stays something intel can sell.

### Stockpiles
54. As a player, I want each faction to keep its stock at a hidden spot in one of its home districts, so that stock is a physical place later intel and raids can reach.
55. As a player, I want the game to remember who has discovered each stockpile, so that discovering one is a lasting gain.

### Market continuity
56. As a player, I want London prices to stay sane and steady once factions replace the stand-ins, so that the market still feels like the one I learned.
57. As a player at the end of Act 1, I want my main ore type share to sit around 10–15%, so that reaching a quarter of the market is a real goal.
58. As a player, I want civilian item and ore demand to remain and respond to the Ticker, so that factions aren't the only consumers in London.
59. As a player loading an older save, I want factions to start with sensible stock and all new fields filled in, so that the save carries on cleanly.

## Implementation Decisions

### Module layout
- **FactionSim (new system).** Static funcs over the pure state tree, touching no Nodes. It owns:
  - daily faction vein tending and pruning;
  - crafting toward targets and consumption;
  - raid-kit burn and per-vein kit allocation;
  - shortfall buying and surplus selling, plus Conclave arbitrage;
  - holdings, and stockpile location state.
  - Faction trades go through Market's existing `record_supply` / `record_demand` with the faction id as `source`.
- **Shares.** A small system (or a Market-side module; the ticket decides) holding rolling daily tallies and pure share reads.
- **Factions.** The random ore restock is removed. The vein cash trickle is removed. Passive industry income stays with retuned values. Security upgrades spend real cash. The NPC claim roll is weighted toward the claimant's primary and secondary ores.
- **Economy (faction lanes).** Shop stock, buyable quantity and draw-down read FactionSim holdings for all five factions, for ore and items. Pricing is unchanged: quote plus relation spread.
- **Contracts.** Contract deliveries are already recorded by `note_contract_delivery`. Each delivery now adds to the counterparty's holdings and to the player's supplier share. It records no supply and no production share.
- **Raiding / rivalry.** Each faction-vs-faction rivalry attempt and each faction raid on the player burns the attacker's kit, and the faction defender's kit where there is one, from holdings. Kit contents are per faction in data. Whether a missing kit weakens a fight is in this sub-spec only if the ticket finds it cheap; otherwise it belongs to 4a.
- **Market.** Stand-in supply is retired: supply is recorded real activity plus an Independents slice. Civilian demand stays, renamed from stand-in so it reads as permanent, and remains Ticker-scaled. Every good's `normalStock` is retuned to the share targets.
- **Screens.** The Factions app and BizBrief read state, Shares and FactionSim reads only, and mutate nothing.

### Faction data (JSON)
- New per-faction fields:
  - `cultivateSkill` and `craftSkill`, with archetype-shaped defaults: producers high cultivate; the Guild high craft; Network and Conclave low craft.
  - Target holding per crafted item, split into a consumption part and a sell quota.
  - Weekly consumption per consumed item (sub-spec 1's `consumes` field).
  - Raid kit contents for attacking and for defending.
  - Home districts eligible for the stockpile.
- Industry income values are retuned smaller. The Conclave's non-calc income is set high.

### Vein tending and pruning (per faction vein, daily)
*Revised 2026-09-28 in ticket 07 (human decision): action budget + per-faction approach replace the flat daily chance and the 40% prune roll. Rules live in REFERENCE.md §1.8 `cultivateSkill` + `fieldwork`.*
- Each faction has a daily action budget (`actionsPerBlock` × 3 blocks), at most one action per vein. Cultivating is not a common skill.
- Factions aim to keep their veins alive. Tends come first, to veins at/under the faction's `tendAtOrBelow`, lowest growth first. Each tend rolls the player's cult chance at `cultivateSkill`; on success growth rises by the player's cultivate gain at that skill.
- Leftover actions prune veins at 85+, highest first. Depth = `cultivate_max_gain(cultivateSkill)` × `pruneDepthMult`, never below the faction's `pruneFloor`. Yield uses the player's prune yield formula, goes into holdings, and credits ore share.
- Per-faction approach knobs: e.g. the Firm prunes below neutral and only tends veins at 30 or lower.
- Collapse at zero growth stays the only way a faction vein dies (ADR 0004, amended).
- **Deferred to 4a:** the Firm deliberately raiding/stealing to make up its ore shortfall (an escalation/stance behaviour, not a fieldwork knob).

### Crafting (per faction, per crafted item, daily)
- Target holding = the next week's consumption of that item + expected raid-kit use + the sell quota.
- When holdings are below target, the faction attempts crafts up to the gap, limited by ore on hand.
- Each attempt uses the player's craft chance at `craftSkill` (seeded Rng). A failure burns its ingredients. A success adds one item, stored per quality tier at the faction's skill, and credits crafting share by ingredient weight.

### Consumption
- Weekly consumption per item is drawn a seventh per day, scaled by the Ticker's `demandAll` / `itemDemand` multipliers for that item.
- Each raid or rivalry attempt also burns its kit from holdings.
- Anything the faction lacks becomes shortfall for tomorrow's buying.

### Per-vein kit allocation
- After consumption, each faction's defensive item holdings are allocated across its veins in a fixed order.
- When stock is short, veins go without in a fixed order: least valuable vein first (tie-break by site id).
- Each faction vein stores which kit items it currently has. This is pure state, readable later by intel (4b) and combat (4a).

### Buying and selling (per faction, daily)
- **Reserve** = the next few days' craft ingredient needs + target item holdings + expected kit use. *Placeholder*: a few days.
- **Buy:**
  - Shortfall below reserve is bought at the London quote while quote ≤ `maxBuyMult` × base (*placeholder* 2×) and the faction has cash.
  - Purchases are recorded as demand. Partial buys are allowed.
- **Sell:**
  - Holdings above reserve sell at `sellFraction` per day (*placeholder* 50%) at the quote, and are recorded as supply.
  - A faction holds when quote < `minSellMult` × base (*placeholder* 0.8×), unless holdings exceed a hard cap.
- **Conclave arbitrage:**
  - It buys goods under `arbBuyMult` × base (*placeholder* 0.7×) and sells what it holds over `arbSellMult` × base (*placeholder* 1.3×).
  - It is capped by cash and by a daily volume limit.
  - No other faction arbitrages. The Conclave's stability and anti-aggressor goals are 4a.
- **London is abstract:** faction buys aren't limited by Market stock.
- All multipliers, fractions and caps are in JSON, per archetype where needed.

### Faction cash
- `resources` is the faction's £ wallet. The field name is kept and documented as £.
  - **In:** sales to London, sales to the player through its shop, industry income.
  - **Out:** London buys, player sales to its shop, security upgrades.
- It is floored at £0. Anything that would overspend is scaled down or skipped.
- Rivalry odds continue to read `resources`.

### Shares
- **Storage:** daily buckets per producer per ore type, 14 days deep (7 for the share, 14 for the week-on-week trend).
  - Producers: `player`, the five faction ids, `independents`.
  - Three tallies: ore harvested; ore used in successful crafts, split by ingredient weight; contract deliveries per buyer faction for supplier share.
- **Crediting:**
  - Player ore share: player prunes and harvests, plus staff cultivator output.
  - Player crafting share: player and staff producer successful crafts.
  - Faction shares: FactionSim prunes and crafts.
  - Independents share: the Independents slice of supply.
- **Pure reads:**
  - ore share and crafting share per producer per ore type (current week and prior week);
  - the London overview table;
  - the player's supplier share per faction.

### Independents slice
- One JSON knob `independentsShare` sets the fraction of London volume that is steady independent supply, balanced by matching civilian demand.
- It appears as the Independents row in the share tables.
- Setting it to 0 removes the slice and hides the row. The target end state is 0, reached once the faction economy is balanced.

### Stockpile location
- Each faction stores one stockpile: a district id from its home districts plus a place name from data, picked once per save with seeded Rng. It also stores `revealedTo`, a list of observer ids, empty at start.
- Holdings are faction-wide numbers held at that stockpile. Relocation and raids are 4b.

### Annotations
- A faction's single-day sell or buy of a good above the existing dump threshold is annotated with the faction's name. Anonymity and unmasking are 4a/4b.

### Rollover order
Within the faction block of the daily tick:
1. Vein drift and collapse (existing).
2. NPC claims (with ore bias).
3. Faction tend and prune.
4. Craft.
5. Consume, including kits from today's rivalry and raid attempts.
6. Kit allocation.
7. Buy and sell, plus Conclave arbitrage.
8. Industry income.
9. Security upgrades.

Shares update before Market reprice, and reprice stays last among trading steps. The ticket sets exact step letters against REFERENCE.md §3.1. The random-restock and vein-income steps are removed.

### Sim start
- FactionSim runs from day 1 regardless of the switch, so faction shops always hold real stock.
- Market's existing single `simStart` switch still gates only price movement.

### State (pure data only)
- **Per faction:** holdings (ore per type; items per recipe per quality tier), `stockpile` `{district, place, revealedTo[]}`, today's shortfall, and the list of today's kit burns.
- **Per faction vein:** its kit (items on hand for defence).
- **Shares:** daily buckets as above.
- The old `oreStock` is migrated into holdings.
- **SaveManager backfill for old saves:** faction holdings at targets, stockpile picked, vein kits allocated, share buckets empty. Faction cash is unchanged.

### UI reads
- **Factions app:**
  - Per-faction card: archetype, primary/secondary ore, crafted items, and ore- and crafting-share bars.
  - A London overview table: rows are the player, 5 factions and Independents; columns are the 5 ore types; with an ore/crafting toggle.
- **BizBrief:** the player's ore and crafting share per type, with ▲/▼ versus last week, and supplier share per faction.
- **Hidden:** exact faction holdings and vein kits.
- New strings are flagged `PROSE-REVIEW:` in their tickets.

### Tuning tool
- A headless 60-day simulation script (a dev tool, not a test) runs the rollover from a fresh start and prints per-good prices and per-producer shares.
- It is used to hit the targets:
  - each producer faction ~30–40% of its primary ore;
  - Guild ~50%+ of crafting for its items;
  - Independents ~20–25%;
  - player at the end of Act 1 ~10–15% of their main ore;
  - idle London prices within sub-spec 1's feel targets.

### Docs
- REFERENCE.md is updated in the same change: §1.8 (faction fields), the Market section (stand-in retirement, civilian demand, Independents), §3.1 (rollover steps), §3.6 (faction shop stock), §3.10 (delivery effects), and the raiding/rivalry section (kit burn).
- CODEMAP gets FactionSim, Shares, and the changed Factions, Economy and screens rows.

## Testing Decisions

- Good tests assert external behaviour only: seed `GameState.state`, drive a public entry point, and assert the resulting state (holdings, cash, shares, prices, vein growth, vein kits, annotations, flags). Never assert internal helper calls or intermediate values.
- **Primary seam: the day rollover** (`TimeSystem.daily_tick`). Seed, advance N rollovers, assert. Cases:
  - **Tending:**
    - A tended faction vein outlives the old ~14-day decay.
    - A prune adds ore to faction holdings and credits the faction's ore share.
    - Collapse at zero still deletes the vein.
  - **Crafting:**
    - Holdings below target lead to craft attempts.
    - A failure burns ore and adds no crafting share.
    - A success adds the item at the faction's quality tier and credits crafting share split by ingredient weight.
  - **Consumption:**
    - Weekly consumption draws holdings down.
    - A Ticker item-demand effect raises consumption.
    - A rivalry attempt burns both kits, and the faction re-buys them next day.
  - **Kit allocation:** a short faction leaves its least valuable veins without kit first.
  - **Buying and selling:**
    - A faction buys its shortfall and the quote rises.
    - It refuses to buy above the ceiling and crafts less.
    - It can't overspend cash.
    - It sells above reserve gradually.
    - It holds when the quote is under the floor.
    - Conclave arbitrage buys a crashed good and sells a spiked one.
  - **Faction cash** never goes negative, and security upgrades stop when cash runs out.
  - **Independents:** `independentsShare` of 0 removes the row and the slice; above 0, shares across all producers sum to 100%.
  - **Deliveries:** a contract delivery lands in the buyer's holdings, reduces its next buy, and credits supplier share but not ore share.
  - **Staff:** staff cultivator harvest credits the player's ore share.
  - **Share trend:** after 14 days, current and prior week both report.
  - **Claim bias:** over a seeded run, claims skew to each faction's primary and secondary ores.
- **Share reads (pure):** tested directly for empty buckets, a single producer, mixed-recipe weighting, and the 7/14-day window edges.
- **Existing public entry points:**
  - A faction shop buy draws down that faction's holdings for ore and items across all five factions.
  - A player sale to a shop adds to holdings and costs the faction cash.
  - The Collective questline buy lane still completes.
  - Contract delivery effects as above.
- **SaveManager round-trip:** holdings, stockpile, vein kits and share buckets survive save/load. An old save migrates `oreStock` and backfills everything else.
- Seeded Rng for every probabilistic step (tend, craft, stockpile pick, claim bias).
- Prior art:
  - sub-spec 1's Market rollover and quote tests;
  - faction tests (rivalry, claims, security upgrades, passive income);
  - economy lane tests;
  - contracts/offers delivery tests;
  - Collective questline tests;
  - SaveManager backfill tests.
- Suite discipline: one targeted run per change, one full suite + check_all at the end. The 60-day tuning script is not part of the suite.

## Out of Scope

- Stances, threat/dependence/pressure, relation and stance drift, and escalation actions: 4a.
- Smart reserve forecasting (stockpiling ahead of a planned raid, hoarding on Ticker hints, withholding to squeeze the player): 4a.
- Conclave positioned Ticker pushes and its stabiliser/anti-aggressor objectives: 4a (recorded in the macro spec).
- Missing-kit combat or odds penalties, if not cheap here: 4a.
- Raid bias toward specialist ores: 4a.
- Firm raiding/stealing to make up the ore it doesn't cultivate (pairs with its deep-prune, low-tend `fieldwork`): 4a.
- Anonymous actors and unmasking: 4a/4b.
- Network intel products (including revealing stockpiles and running-dry vein kits), stockpile raids and relocation, and weakening floors: 4b.
- Faction guard wages and walk-off: sub-spec 3 (with the player's guard upkeep).
- Vassals: sub-spec 6.
- Margin-seeking crafting (crafting whatever is most profitable today).
- Player non-calc businesses (see Further Notes).
- Ticker evolution.

## Ticketing decisions (2026-09-28)

- **Shops:** Firm, Network and Conclave get trade lanes plus a shop pin in their home district, gated by per-faction unlock flags that only Debug Start sets for now; quests will unlock them later.
- **Fight order:** rivalry and faction raid resolution move to right after NPC claims, so a fight's kits burn in the same day's consume step. Rivalry therefore reads end-of-yesterday cash.
- **Raid kits:** a raid on the player that resolves without a played fight (no alarm, left undefended or expired, repelled by guards) burns the attacker's full attack kit. In a raid the player defends, the raiders spawn with the attack kit (capped by holdings) and use items in combat. Only the items they used are deducted. This adds enemy item use in combat, which is in scope here.
- **Item tier:** faction craft tier = `craftSkill`, the same fixed rule as the player's. Shop buys give the held tier, highest first.

## Further Notes

- **Independents is scaffolding.** The design goal is a London supplied entirely by factions and the player. `independentsShare` exists to keep prices steady while the faction economy is tuned. Remove it (set it to 0) once balance holds without it.
- **Kit allocation → intel.** The per-vein kit state is built here so 4b's Network intel can sell lines like "the Firm is running low on shields, and these vein sites have run out", making those veins easier to hit. Ticket this so the vein kit is readable per site.
- **Player non-calc businesses (future sub-spec candidate).** Factions earn non-calc industry income. Add avenues for the player to build non-calc income too. This is not designed here.
- **Skills as levers for 4a.** `cultivateSkill` and `craftSkill` let 4a shift a faction's focus between cultivating and crafting.
- Share targets (above) are the anchor for 4a's pressure weights and sub-spec 5's ~25% share objective. Re-check them after playtesting before writing 4a.
- PROSE-REVIEW: new UI strings (share labels, overview table headers, Independents, supplier share, annotation text naming a faction) are flagged in their tickets.
- Canonical vocabulary: site vs vein, faction-claimed, growth/prune, the five ore types, `cash` (player) vs faction `resources` (£), consumable ids, Ticker, calc.
