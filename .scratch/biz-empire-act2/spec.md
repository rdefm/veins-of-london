# Biz Empire Act 2 — Market, Monopolies & Faction Rivalry (macro vision spec)

Status: ready-for-agent

> Macro vision. Not ticketed directly — split first into five sub-specs (see Further Notes), each of which is then ticketed. All numbers here are placeholders or omitted; sub-specs set them.

## Problem Statement

Act 1 of the Business Empire questline ends with a working business: veins, staff, contracts, a weekly payday. After that, nothing about London's economy responds to the player. Ore and item prices are fixed base prices nudged by the Ticker; factions own veins but produce only an abstract cash number; faction marketplace stock is a random restock; faction relation only gates raids and trade spread. Growing the business has no strategic texture: there is no reason to specialise, no market to corner, no rival who notices you're eating their lunch, and no ally whose interests align with yours. Guards are a one-off purchase, so security never pressures cashflow. The player has no "why" for conflict and no economic levers beyond "sell more".

## Solution

London gets a living two-tier market and factions with real economic identities that react to the player's growth.

- **Dynamic market.** One London price per ore type and per crafted item, recalculated daily from supply and demand. Item demand has a baseline shaped by the Ticker plus faction consumption; ore demand derives from item demand via recipe ingredients. Selling floods supply; holding starves it. Prices move with a one-day lag, so the player can sell a hoard once at a high price, but repeated dumping crashes it.
- **Real faction production.** Faction veins yield real ore; factions craft their specialist items, consume what they need, buy their shortfall, and sell surplus — all into the same market. Faction marketplace stock is what they actually hold.
- **Shares.** London ore share (harvested) and crafting share (successful crafts) per ore type, per producer, over a rolling week — visible in the Factions app and BizBrief. Owning a big slice of an ore type is leverage.
- **Faction identity and stances.** Each faction has an archetype (producer, crafter, manipulator, information broker), ore and item specialisations, and consumption needs. Faction pairs (and the player with each faction) hold a stance — Partner, Neutral, Business rival, Hostile — with canonical starting stances that drift with relation.
- **Pressure.** Each faction weighs how much the player threatens it (shares in its ores/items, presence in its districts, overall size) against how much it depends on the player (supplier contracts, relation). Net pressure erodes relation daily; as relation falls, the faction escalates — warning, market moves (flood, undercut, poach contracts, outbid sites, lowball buyouts), buying intel on the player, and finally raids. High relation buys time, so a player can corner a market while keeping a rival sweet until it's too late for them.
- **Relation levers and partners.** Favours, gifts to key faction members, flavour quests and supplier contracts raise relation. Partners trade price favours in both directions.
- **Stockpiles.** Each faction keeps its stock at a hidden stockpile location that intel can reveal and a raid can hit — the counter to a flood.
- **Guard upkeep + business float.** Hired guards cost a daily wage from the business pot; unpaid guards walk. The player can donate cash into a reserve float that payday never splits, to bridge the gap while passive income builds.
- **Act 2 questline.** Archie and James frame the new game: pick an ore type to dominate (without over-relying on it), find a crafter faction to be main supplier to, weather or soften a rival's first move, reach Partner, debrief.

## User Stories

### Market — prices
1. As a player, I want each ore type to have one London market price that every lane reads, so that I understand "the price of time ore" as a single fact.
2. As a player, I want each crafted item to have one London market price, so that crafting decisions weigh real value.
3. As a player, I want ore prices to rise when little of that ore is being sold, so that holding stock is a real strategy.
4. As a player, I want ore prices to fall when lots of it is sold, so that dumping has a cost.
5. As a player, I want my sale today to execute at today's price and only move tomorrow's, so that I can cash a hoard once at a high price.
6. As a player, I want repeated big sales to crash the price over following days, so that I can't infinitely exploit a spike.
7. As a player, I want prices to be clamped and smoothed, so that the market never produces absurd numbers or whiplash.
8. As a player, I want item demand to respond to the Ticker (e.g. war raises shield and blast demand), so that world events create opportunities.
9. As a player, I want ore demand to follow the demand for items made from it, so that a war spikes physics ore if nobody is crafting more shields.
10. As a player, I want faction spreads and relation-based pricing to still apply on top of the London price, so that relations keep mattering at the counter.
11. As a player, I want vein valuations (selling a vein, buyouts) to track current ore prices, so that a vein's worth reflects the market.
12. As a player, I want a price chart per ore type and item in BizBrief, so that I can see trends and time my sales.
13. As a player, I want price chart annotations for notable market events (a flood, a spike), so that I know why the line moved.

### Market — contracts
14. As a player, I want contract prices locked at signing (market price ± a negotiated premium), so that I can lock in good prices.
15. As a player, I want contracts to run a fixed term (default 4 weeks) then expire, so that deals are periodically renegotiated.
16. As a player, I want a renewal offer at the then-current market price when a contract expires, so that I can choose to continue.
17. As a player, I want contract deliveries not to count as open-market supply, so that supplying a buyer doesn't crash my own price.
18. As a player, I want contract deliveries to count toward my production share, so that supplier relationships reflect my real output.
19. As a player, I want my deliveries to reduce the buyer faction's market demand, so that being their supplier has a visible market effect.
20. As a player with an open-ended recurring contract from before Act 2, I want it to become a fixed-term contract at its next renewal, so that old saves join the new system cleanly.
20a. As a player, I want every contract offer and active contract to clearly show who it's with (a faction or named contact), so that I know whose relationship each deal touches.
20b. As a player who cancels an accepted contract, I want the relationship hit to land on that contract's counterparty, so that walking away has a sensible, targeted cost.

### Faction simulation
21. As a player, I want faction veins to produce real ore, so that faction output and market share are genuine.
22. As a player, I want factions to craft their specialist items from their ore, so that item supply comes from somewhere real.
23. As a player, I want factions to buy their ore shortfall on the market, so that crafter factions are big demand sinks I can supply.
24. As a player, I want factions to sell surplus ore and items into London, so that their output affects prices.
25. As a player, I want factions to consume items weekly (e.g. the Firm burns attack and healing items), so that demand has a real floor.
26. As a player, I want faction consumption to scale with their activity and the Ticker, so that a raiding faction or a war visibly eats more.
27. As a player, I want faction marketplace stock to be what they actually hold, so that buying from a faction draws down something real.
28. As a player, I want producer factions (Collective, Firm) to focus on ore output, so that they compete with me on production.
29. As a player, I want the Guild to have small own production and buy most of its ore, so that it's the obvious customer for a supplier.
30. As a player, I want the Conclave to earn by positioned Ticker pushes and arbitrage, so that the market has a manipulator I can read and ride.
31. As a player, I want manipulators to buy under-priced goods and sell over-priced ones, so that the market self-dampens and my monopoly faces resistance.
32. As a player, I want the Network to be an information broker selling raid intel, counter-raid warnings and market intel, so that information is a tradable asset.
33. As a player, I want the Network to sell intel about me to my rivals, so that a bad Network relation is quietly dangerous.
34. As a player, I want Ticker headlines or intel to hint at big faction positions ("someone's buying up physics"), so that I can anticipate manipulation.
35. As a player, I want the market sim to run from day 1 silently, so that the world is consistent when Act 2 reveals it.

### Shares
36. As a player, I want ore share per type measured from ore harvested over a rolling 7 days, so that hoarding still counts as owning production.
37. As a player, I want crafting share per type measured from ore consumed in successful crafts over a rolling 7 days, so that failed crafts don't inflate it.
38. As a player, I want mixed-ingredient crafts to count toward each ingredient's type by weight, so that a failsafe counts toward both time and life.
39. As a player, I want to see each faction's ore and crafting shares in the Factions app, so that I know who dominates what.
40. As a player, I want a London overview table of shares per ore type with myself as a row, so that I see the whole market at a glance.
41. As a player, I want my own shares and week-on-week trend in BizBrief, so that I track my progress toward dominance.

### Faction identity & stances
42. As a player, I want each faction to have a primary and secondary ore, crafted items and consumed items, so that rivalries follow from overlap.
43. As a player, I want factions to bias claims and raids toward their specialist ores, so that their identity shows on the map.
44. As a player, I want faction pairs to have stances (Partner, Neutral, Business rival, Hostile), so that not every overlap is a war.
45. As a player, I want business rivals to fight with market tools only unless relation collapses, so that competition feels civil until it doesn't.
46. As a player, I want canonical starting stances (Collective–Firm Hostile, Guild–Conclave rivals, Network–Conclave rivals, Collective–Guild partners, others Neutral), so that London has a pre-existing political shape.
47. As a player, I want stances to drift with relation over time, so that the political map changes.
48. As a player, I want my own stance with each faction, so that I can become a partner or an enemy.

### Pressure & escalation
49. As a player, I want each faction to weigh my threat to it (my share of its ores, my share of its items, my presence in its home districts, my overall size), so that growth has consequences.
50. As a player, I want each faction to weigh its dependence on me (my supply to it, our relation), so that being useful protects me.
51. As a player, I want net pressure to erode relation daily, so that consequences arrive gradually.
52. As a player, I want escalation to read off relation, so that high relation buys time even while I dominate their ore.
53. As a player, I want a readable pressure label per faction (e.g. Calm / Watching / Annoyed / Moving against you), so that I don't need raw numbers.
54. As a player, I want a warning text before a faction acts, so that I have a chance to respond.
55. As a player, I want a rival to be able to flood my ore type, so that a monopoly can be attacked economically.
56. As a player, I want a flood to cost the rival (selling at a loss), so that they only do it when pressure is high and they can afford it.
57. As a player, I want rivals to poach my contract buyers with cheaper renewals, so that I must defend key relationships.
58. As a player, I want rivals to outbid me for sites, so that expansion is contested.
59. As a player, I want a struggling me to receive lowball buyout offers for my veins, so that a squeeze has a tempting exit.
60. As a player, I want rivals to buy Network intel on me before moving, so that information matters.
61. As a player, I want raids to happen only when a faction is Hostile or below its raid threshold, so that raids stay the last resort.
62. As a player, I want the same pressure AI to run faction vs faction, so that London's factions fight each other too.
63. As a player, I want every action taken against me to be clearly surfaced (faction-contact text, BizBrief line, Factions-app activity log, price-chart annotation), so that I always understand what's happening.
64. As a player, I want anonymous actions to still show their effect credited to "someone", so that stealth doesn't mean confusion.
65. As a player, I want Network intel to be able to unmask anonymous actors, so that secrecy has a counter.

### Relation levers & partners
66. As a player, I want to raise relation via favours or jobs for a faction, so that I can buy goodwill.
67. As a player, I want to give gifts to key faction members, so that I can soften a rival quickly.
68. As a player, I want flavour quests for factions, so that relationships have story.
69. As a player, I want supplier contracts to raise both dependence and relation, so that commerce builds alliances.
70. As a player with a Partner, I want to ask for a better price at a relation cost, so that alliances have tangible value.
71. As a player with a Partner in trouble, I want them to ask me for a better price and my acceptance to raise relation, so that alliances are two-way.
72. As a player, I want partners to warn me of others' plans or defend me, so that I'm not fighting rivals alone.

### Stockpiles
73. As a player, I want each faction to keep its stock at a hidden stockpile location, so that stock is a physical, raidable asset.
74. As a player, I want intel (e.g. from the Network) to reveal a stockpile location, so that discovery is a mission.
75. As a player, I want to raid a revealed stockpile and steal ore/items, so that I can neutralise a rival's ability to flood.
76. As a player, I want factions to raid each other's stockpiles too, so that the market reacts to London's own conflicts.

### Weakening & vassals
77. As a player, I want factions to be weakenable (lose share, veins, resources, guards), so that winning is possible.
78. As a player, I want a broke faction's retaliation limited by what it can afford, so that crushing a rival pays off.
79. As a player, I want factions never eliminated (a floor of veins and income), so that the world and questlines never break.
80. As a player, I want a severely weakened faction to be able to become a vassal of a protector, with the protector getting cheaper access to the vassal's produced ore or crafted items, so that dominance has a diplomatic endgame.

### Guard upkeep & float
81. As a player, I want Hired Guard and extra guards to cost a daily wage, so that security is an ongoing commitment.
82. As a player, I want locks and ward runes to stay one-off purchases, so that basic security isn't a running cost.
83. As a player, I want guard wages paid from the business pot, falling back to cash, so that they sit with other staff costs.
84. As a player, I want guard wages shown in BizBrief expenses, so that I see what security costs me.
85. As a player, I want a one-day grace warning before unpaid guards walk, so that I can fix it.
86. As a player, I want unpaid guards to walk one per vein per day, least valuable vein first, so that the loss is gradual and predictable.
87. As a player, I want factions to pay guard upkeep too, so that squeezing a rival can strip their defences.
88. As a player, I want a button to donate cash into the business pot as a reserve float, so that I can keep guards paid while passive income builds.
89. As a player, I want payday never to split the float, so that my donation isn't handed to my partners.
90. As a player, I want expenses to draw the float first, so that the float does its job.
91. As a player, I want to withdraw unspent float anytime, so that the donation isn't a trap.
92. As a player, I want guard upkeep to start at Act 2, so that early play isn't punished.

### Act 2 questline
93. As a player, I want Act 2 to trigger after Act 1 completes and the next payday passes, so that Act 1's ending breathes.
94. As a player, I want a meeting scene with Archie and James framing the market, shares and supplier strategy, so that I understand the new game.
95. As a player, I want James to advise dominating one ore type without over-relying on it and becoming main supplier to a crafter faction, so that I have a clear plan.
96. As a player, I want the meeting to unlock the market reads, share/pressure reads, the donate button and guard upkeep, so that systems arrive with context.
97. As a player, I want an objective to reach a target share (~25%) in one ore type, with James tipping which types are contested, so that I pick my lane.
98. As a player, I want an objective to sign a 4-week supplier contract with a faction that crafts with that ore, so that I learn dependence.
99. As a player, I want the rival for my ore to make its first visible move once I pass the threshold, with a text explaining relation levers, so that I learn escalation and counters.
100. As a player, I want to choose to weather that move (keep guards paid, lose no vein for N days) or soften it (spend on a relation action with the rival), so that I play my own way.
101. As a player, I want an objective to reach Partner stance with my buyer faction and see them help me, so that alliance pays off.
102. As a player, I want a closing debrief that marks Act 2 complete while the sandbox carries on, so that the systems outlive the quest.
103. As a player, I want the crafting-share route to exist as a system even though the quest steers me to ore, so that I can choose a different empire.
104. As a player, I want Act 2 beats shown in the ToDo app like Act 1, so that I always know my next step.

### Collective questline interaction
105. As a player mid-Collective questline, I want Collective–Firm conflict to stay under the questline's scripted control, so that the story isn't hijacked by the AI.
106. As a player who has finished the Collective questline, I want the Collective–Firm pair to hand over to the pressure AI starting Hostile, so that the conflict continues with economic motives.

## Implementation Decisions

### Module layout (new systems follow the one-way data flow: static-func systems over the pure state tree)
- **Market** (new system): owns the London price per ore type and per item, supply/demand tallies for the day, price history for charts, and annotations. Exposes a pure quote (kind, type → current price) that every lane uses instead of reading base price + barometer directly, and a daily update (called from the rollover) that recomputes tomorrow's prices from today's tallies with clamp + smoothing. Records supply when anything is sold into London (player lanes and faction sales); contract deliveries are excluded from supply.
- **FactionSim** (new system): daily faction production, crafting, consumption, shortfall buying, surplus selling, stockpile holdings, arbitrage (manipulators), guard upkeep. Faction veins need an abstract tend/prune cadence so they yield real ore instead of decaying (faction veins currently only drift; see ADR 0004 for the lifecycle this must respect).
- **FactionAI** (new system): threat, dependence, pressure, relation drift, stance drift, escalation choice, faction-vs-faction application, partner favour requests. Emits communication (messages, notifications, activity-log entries, chart annotations) for every action against the player.
- **Shares**: rolling 7-day tallies of harvested ore (player veins, staff cultivators, faction veins) and successful-craft ore consumption (player, staff producers, factions), per producer per ore type. May live in Market or its own small system; sub-spec decides.
- **Economy**: faction lanes and the Archie lane price through Market's quote; sales report supply to Market. Faction marketplace stock reads FactionSim holdings; the random ore restock goes away.
- **Contracts / Offers**: price locked at signing from Market's quote ± premium; fixed term with an expiry and a renewal offer; deliveries feed shares and reduce the buyer's demand. Open-ended recurring contracts migrate to fixed term at their next renewal. Every contract records its counterparty (faction or contact), shown on offer and active cards; cancelling an accepted contract applies a small relation hit to that counterparty (the cancel flow itself — confirm pop-up, immediate cancel — ships earlier, before counterparties exist).
- **Business**: reserve float (donate, withdraw, float-first expense draw, payday excludes float from the split); guard wages become a pot expense line.
- **Cultivating / Raiding**: guard wage per Hired Guard and extra guard; walk-off when unpaid; stockpile raid resolution alongside vein raids; factions bias claims/raids to their specialist ores.
- **Barometer (Ticker)**: feeds item demand. The current flat orePrice/typePremium effects are superseded by item-demand effects — exact mechanics belong to the separate Ticker-evolution doc; this spec only assumes a per-item demand multiplier the Ticker can drive. Faction barometer prefs stay as personality bias; manipulators add position-driven pushes.
- **Network handler**: expands to intel products — raid intel, counter-raid warnings, market intel (positions and planned dumps), stockpile locations, unmasking, and intel sold about the player to rivals.
- **Factions app / BizBrief**: new reads (shares bars, London overview, stance, pressure label, activity log, price charts, float controls, guard expense). Screens read state and call system functions only.
- **BusinessQuest / objectives / events**: Act 2 beats with new flags (`bizA2*` family, `bizA2Complete` at the close) and new objective kinds as needed (share threshold, contract-with-faction, stance reached, weather-or-soften).

### Data
- Faction data gains: archetype, primary ore, secondary ore, crafted items, consumed items (with base weekly quantities), and canonical starting stances per pair. Draft identity table:

| Faction | Archetype | Ore (primary / secondary) | Crafts | Consumes |
|---|---|---|---|---|
| Collective | producer | life / emotion | healingSalve, enhancementPowder | healingSalve |
| Firm | producer | physics / life | blast, shield, healingBurst | blast, shield, healingBurst, enhancementPowder |
| Guild | crafter | time / physics | timePearl, rewind, wormhole, prophetsBreath, rejuvenation | little |
| Network | information broker | emotion / fate | pansPrank (token) | prophetsBreath |
| Conclave | manipulator | fate / time | failsafe (token) | failsafe, rejuvenation |

- Starting stances: Collective–Firm Hostile; Guild–Conclave Business rival; Network–Conclave Business rival; Collective–Guild Partner; all other pairs and player-vs-each-faction Neutral (Collective per its questline).
- New data: item baseline demand per item; market clamp/smoothing constants; contract default term (4 weeks); guard daily wage; pressure weights; escalation thresholds; share-objective threshold (~25%). All in JSON, none in code.
- A single config switch sets when the market sim starts (`day1` default, or `bizA2`), read in one place so it can be flipped after playtesting without scattered gating.

### State (pure data only — no references, so save/snapshot/Rewind keep working)
- Market: current prices, today's supply/demand tallies, bounded price history, annotations.
- Factions: holdings (ore/items stockpile), stockpile location (+ revealed flag per observer), consumption tallies, stance matrix (pair + player), pressure/threat/dependence snapshots, activity log (bounded), vassal link (nullable).
- Shares: rolling 7-day per-producer tallies.
- Business: float amount.
- Veins: guard wage state (days unpaid) alongside existing extraGuards.
- Contracts: signed price, start day, term, expiry day.
- SaveManager backfills every new key for old saves.

### Rollover order (sub-spec fixes exact step letters)
Faction production and crafting → faction consumption → faction buy/sell (supply/demand tallies) → shares update → Market reprice for tomorrow → guard wages (player + factions) → FactionAI pressure/relation/stance → escalation actions and communication → Act 2 beat checks.

### Collective–Firm hold
FactionAI skips the Collective–Firm pair while the Collective questline is incomplete; scripted questline behaviour stays in charge. On questline completion the pair joins FactionAI at Hostile.

### Vassal (explore in sub-spec)
A severely weakened faction may take a protector; the protector gets cheaper access to the vassal's produced ore or crafted items (e.g. the Guild vassal to the Collective gives the Collective cheap Guild items). Trigger, terms and exit to be designed.

## Testing Decisions

- Good tests assert external behaviour only: seed `GameState.state`, drive a public entry point, assert the resulting state (prices, holdings, shares, relation/stance, guard counts, float, queued messages/notifications, flags). Never assert internal helper calls or intermediate variables.
- **Primary seam: the day rollover.** Most behaviour is daily: seed state, advance N rollovers through the existing time-system daily tick, assert outcomes. Examples: holding stock raises tomorrow's price; a big sale crashes the following days; war raises shield demand and then physics price; unpaid guards walk after grace; pressure erodes relation and triggers a warning then a flood; Collective–Firm is skipped until the questline completes.
- **Secondary seams (existing public entry points):** Economy sale lanes (sale executes at today's price, supply recorded); Contracts sign/settle/expire (price lock, term, renewal, deliveries excluded from supply, shares credited); Business donate/withdraw/payday (float never split); Raiding stockpile raid; objectives/event runner for Act 2 beats.
- New internal modules (Market, FactionSim, FactionAI) are tested through the rollover, not method-by-method — except Market's pure quote, which gets direct edge-case tests (clamps, smoothing, zero supply).
- Rng is seeded for any probabilistic step, as existing tests do.
- Save round-trip test: new state keys survive save/load and backfill on an old save.
- Prior art: time-system rollover tests, faction tests (rivalry/raid rolls), economy tests (lane pricing, faction purchases), contracts/business tests (settlement, payday split), Business Empire Act 1 questline tests (beat flags, pending texts, ToDo rows).
- Follow the suite discipline: one targeted run per change, one full suite + check_all at the end.

## Out of Scope

- Ticker evolution (new states, how Ticker states map to item demand in detail) — separate doc; this spec only assumes a per-item demand multiplier.
- All balance numbers — set in the sub-specs.
- Detailed design of relation-builder content (specific favours, gift items, flavour quests) — sub-spec ④.
- Vassal mechanics beyond the intent above — explored in sub-spec ④.
- Collective–Firm under FactionAI before the Collective questline is complete.
- Quest routing for the crafting-share route (system exists; no questline steers to it).
- Prose — every new line of dialogue/notification goes through CONTENT-GUIDE and is flagged PROSE-REVIEW in its ticket.

## Further Notes

- **Split into five sub-specs before ticketing**, in dependency order:
  1. Market sim (two-tier prices, contracts lock/term, sim-start switch)
  2. Faction economic identity (FactionSim, archetypes, shares, stockpiles, Factions-app/BizBrief reads)
  3. Guard upkeep + business float
  4. Relations & pressure AI (stances, pressure, escalation, relation levers, partners, Network intel products, communication rule, weakening floor, vassal exploration, Collective–Firm hold)
  5. Act 2 questline
- Framing: the Collective questline introduces the *how* of faction conflict; Biz Act 2 introduces the *why*.
- Canonical vocabulary applies throughout: site vs vein, faction-claimed, growth/prune, the five ore types, `cash`, consumable ids.
- REFERENCE.md must be updated as each sub-spec lands (faction data table §1.8, barometer effects §1.9, selling §3.6, raiding §3.12, Business Empire questline §3.10).
