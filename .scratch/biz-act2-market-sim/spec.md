# Biz Act 2 — Sub-spec 1: Market sim

Status: ready-for-agent

> Sub-spec 1 of `.scratch/biz-empire-act2/spec.md` (macro vision). Covers the London market (two-tier prices), contract price lock / fixed term / faction counterparty, the interim Ticker → item-demand mapping, the Ticker app's Stock Market tab, and the seams sub-spec 2 (faction economic identity) plugs into. Numbers marked *placeholder* are feel targets; the implementing ticket pins them in JSON and REFERENCE.md.

## Problem Statement

Ore and crafted-item prices are fixed base prices nudged directly by the Ticker. Selling ten units or ten thousand makes no difference to tomorrow's price, holding stock never pays, and the Ticker's effects snap prices instantly with no sense of a market reacting. Contracts pay a price frozen when the offer was generated (possibly two weeks stale), recurring contracts run forever, and no contract is *with* anyone — cancelling one costs nothing and supplying one builds no relationship. The player has no market to read, time, or corner, and later Act 2 systems (faction production, shares, rivalry) have no market to plug into.

## Solution

London gets a living market. Every ore type and every crafted item has one London price, recalculated each day from a hidden London stock that the player's sales fill and demand drains, with the rest of London pulling it back toward normal. Selling a hoard gets today's price but depresses the next few days; holding lets prices climb a little. The Ticker now moves *item demand* rather than prices, and ore demand follows item shortages through recipes — so a war raises shield demand, and physics ore climbs unless someone crafts more shields. Every £ figure the player sees reads the London price.

Contracts become deals with a named faction: price live while pending and locked on accept, recurring contracts run a fixed 4-week term then offer renewal at the then-current price, and cancelling hurts relation with that faction.

The Ticker app splits into News (current headlines and push/pull) and a new Stock Market tab with prices, day-on-day movement, per-good charts with annotations, and the active demand modifiers. The sim runs from day 1.

## User Stories

### London prices
1. As a player, I want each ore type to have one London price that every lane reads, so that "the price of time ore" is a single fact.
2. As a player, I want each crafted item to have one London price, so that crafting decisions weigh real value.
3. As a player, I want a sale to execute at today's price, so that I can cash a hoard once at a good price.
4. As a player, I want my sales to lower the following days' price in proportion to how much I sold versus London's volume, so that dumping has a cost.
5. As a player, I want a dumped market to resettle within 2–4 days, so that one big sale is a short hangover rather than a ruined week.
6. As a player, I want prices to drift a little above base when I'm not selling, so that holding stock is a real (modest) strategy.
7. As a player selling at a normal pace, I want prices to sit near base, so that early-game income isn't disrupted by the market arriving.
8. As a player, I want prices clamped between 0.2× and 4× base, so that the market can swing hard but never produces absurd numbers.
9. As a player, I want prices smoothed day to day, so that the market never whiplashes.
10. As a player, I want repeated large dumps to push a price toward its floor, so that I can't infinitely exploit a spike.
11. As a player, I want my small early sales to barely move prices, so that the market feels bigger than me until I grow.
12. As a player at the end of Act 1, I want my main ore type to be roughly 10–15% of London's volume, so that my sales visibly matter and dominance is a reachable next step.
13. As a player, I want buying from a faction to count as London demand, so that my purchases firm up prices too.
14. As a player, I want the contract "buy missing calc" purchases to count as demand, so that automated buying behaves like manual buying.
15. As a player who gets mugged during a sale, I want the goods to still count as sold into London, so that the market reflects what actually changed hands.

### Item and ore demand
16. As a player, I want the Ticker to change demand for specific items (e.g. war raises shield and blast demand), so that world events create opportunities.
17. As a player, I want boom/recession-style Ticker states to lift or lower demand across all items, so that the economic mood shows in the market.
18. As a player, I want ore demand to rise when items made from it are in short supply, so that a war spikes physics ore if nobody crafts more shields.
19. As a player, I want crafting and selling the in-demand item to cool the ore price, so that crafting versus selling raw is a real choice.
20. As a player, I want mixed-ingredient items to push demand onto each ingredient's ore type by weight, so that a healing burst shortage lifts both time and life.
21. As a player, I want a strong Ticker state to move the affected ore roughly +50–100% over a few days if nobody fills the gap, so that a war is worth pivoting for.
22. As a player, I want Ticker effects to build over a few days rather than jump instantly, so that the market feels like it's reacting.

### Lanes
23. As a player, I want the Archie sell lane to price ore and items at the London price (then quality, district and cut as before), so that selling to Archie follows the market.
24. As a player, I want faction buy and sell lanes to price at the London price with their spread and relation pricing on top, so that relations still matter at the counter.
25. As a player, I want James's craft-job pay to follow the London item price, so that commissions track value.
26. As a player, I want Archie's tag-along deals priced at London prices but not moving them, so that a deal I merely tag along on can't crash my own market.
27. As a player, I want contract deliveries not to count as London supply, so that supplying a buyer doesn't crash my own price.
28. As a player, I want vein valuations (vein sale, buyouts) to use a 2-day average of the ore's price, so that a vein's worth tracks the market without single-day spikes being trivially gamed.
29. As a player, I want faction AI's vein-targeting and raid-strength scoring to stay stable, so that faction behaviour doesn't swing with daily prices.

### Contracts — price and term
30. As a player, I want a pending offer's price to follow the market each day, so that I can see what I'd lock in today.
31. As a player, I want accepting an offer to lock its price for the whole contract, so that I can lock in good prices.
32. As a player, I want the existing premium stack (contract multiplier, mixed-type bonus, Sales-level bonus) applied on top of the market price, so that contracts still pay better than the counter.
33. As a player, I want recurring contracts to run a fixed 4-week term and then expire, so that deals are periodically renegotiated.
34. As a player, I want a renewal offer — same request, same counterparty, priced at the then-current market — when a recurring contract expires, so that I can continue a good relationship.
35. As a player, I want a renewal offer to appear even when my pending list is full, so that I never silently lose a renewal.
36. As a player, I want a renewal offer to expire after a few days if ignored, so that my list doesn't clog.
37. As a player, I want declining or ignoring a renewal to cost no relation, so that ending a deal cleanly is always free.
38. As a player with an open-ended recurring contract from an older save, I want it to gain a 4-week term at its next weekly renewal, so that old saves join the new system cleanly.
39. As a player in Act 1, I want the Act 1 recurring contracts to follow the same term rule without breaking the questline, so that the proof beats stay completable.
40. As a player, I want one-off contracts to keep their existing deadline model, so that short jobs stay simple.

### Contracts — counterparty
41. As a player, I want every offer and active contract to show which faction it's with, so that I know whose relationship each deal touches.
42. As a player taking small early contracts, I want them to come from the Collective or the Firm, so that the first factions I deal with are the street-level ones.
43. As a player, I want small offers to go to whichever of Collective/Firm fits the good (life/emotion to the Collective, physics to the Firm), falling back to the one I'm on better terms with, so that counterparties feel sensible.
44. As a player taking larger contracts, I want any of the five factions as a possible counterparty, weighted by who'd want that good, so that the Guild buys time ore and the Firm buys blasts.
45. As a player, I want scripted offers (including the Act 1 starters and recurring ones) to name their faction, so that quest contracts have a fixed, authored counterparty.
46. As a player who cancels an accepted contract, I want a small relation hit with that contract's counterparty, so that walking away has a targeted cost.
47. As a player taking a Firm contract mid-Collective-questline, I want no cross-faction relation hit, so that rival jealousy waits for the pressure AI.

### Stock Market tab (Ticker app)
48. As a player, I want the Ticker app split into News and Stock Market tabs, so that headlines and prices each have a home.
49. As a player, I want the News tab to keep the current headlines and push/pull controls, so that nothing I rely on disappears.
50. As a player, I want the Stock Market tab to list every ore type and item with its current price and ▲/▼ versus yesterday, so that I can read the market at a glance.
51. As a player, I want to open a price chart per good covering the last few weeks, so that I can see trends and time my sales.
52. As a player, I want chart annotations when the Ticker shifts, when I dump heavily, and when a price spikes or crashes, so that I know why the line moved.
53. As a player, I want to see the active Ticker demand modifiers per item, so that I know which goods the news is pushing.
54. As a player, I want the Stock Market tab available from day 1, so that the market that's already running is readable.
55. As a player, I want sell rows in every lane to show ▲/▼ versus yesterday, so that I notice prices move even without opening the Ticker.

### Continuity
56. As a player, I want the market state saved and restored with my game, so that prices persist across sessions.
57. As a player using Rewind, I want prices and market stock to rewind with everything else, so that Rewind stays exact.
58. As a player loading an old save, I want the market initialised to sane resting prices, so that the save isn't disrupted.

## Implementation Decisions

### Market (new system)
- New static-func system over the pure state tree; no Nodes, no references. Owns per-good London stock, current price, bounded price history, annotations, and today's supply/demand tallies. A "good" is `(kind, type)` where kind is `ore` (the five ore types) or `consumable` (every recipe key).
- **Quote:** a pure `quote(kind, type) → int` returning today's London price. Every player-facing money read goes through it in place of `basePrice` / consumable price + Barometer ore price. A second pure read returns the 2-day average for vein valuations.
- **Recording:** `record_supply(kind, type, qty, source)` and `record_demand(kind, type, qty, source)`. `source` identifies the actor (player lane, or later a faction) and is kept for annotations and for sub-spec 2's shares. Sales execute at today's quote; recording only affects tomorrow.
- **Daily reprice** (called from the rollover), per good:
  1. `stock += supply − demand` (demand = stand-in baseline × Ticker multipliers + recorded demand; supply = stand-in baseline + recorded supply), floored at 0.
  2. Rest-of-London reversion pulls stock toward `normalStock` by a fixed fraction.
  3. Target price = `base × f(stock / normalStock)`: stock below normal → above base, above normal → below base; clamped to [0.2×, 4×] base.
  4. Price moves a fixed fraction of the way from current to target (smoothing); integer £.
  5. Append to history (bounded, ~28 days); clear tallies.
- **Ore demand derives from item shortages:** each ore's daily demand = its own stand-in baseline + Σ over recipes `max(0, normalStock − itemStock) × ingredient qty × conversion rate`, split per ingredient by weight. Items reprice before ores within the same tick so ore demand reads today's shortages.
- **Feel targets (placeholder, ticket pins):**
  - Idle equilibrium ~1.1–1.2× base (stand-in demand slightly exceeds stand-in supply; the player is the marginal supplier). Normal player pace ≈ base.
  - A big dump (≈ a week of a player's output in one type) resettles in 2–4 days; depth is emergent from dump size versus London volume. Reversion and smoothing are tuned together to hit the 2–4 day window.
  - London volume sized so a player at the end of Act 1 is ~10–15% of their main ore type.
  - A strong Ticker item-demand effect with no one filling the gap moves the affected ore +50–100% over a few days.
- **Base prices:** ore `basePrice` stays in ore_types data; the consumable price table stays as each item's base. Both become the reference points the market moves around, not the prices charged.
- **Annotations** (bounded list, per good): Ticker state shift affecting that good; player single-day supply above a threshold × normal volume ("dump"); day move beyond a threshold ("spike"/"crash"). Each carries day, good, kind, and source/actor.
- **Sim-start switch:** one config value (`day1` default, or `bizA2`) read in one place. Before start, quote returns base and reprice is a no-op. The Act 2 flag doesn't exist yet; `bizA2` is reserved for sub-spec 5.

### Stand-in London (replaced in sub-spec 2)
- Per good: `normalStock`, stand-in daily supply, stand-in daily demand — all JSON. This provider is a single read point so FactionSim can replace it by recording real faction supply/demand through the same `record_*` calls.

### Barometer / Ticker (interim mapping)
- Ticker state effects drop `orePrice` and every `<type>Premium` key. New keys: `demandAll` (fractional multiplier on every item's demand) and `itemDemand` (`{recipeKey: fraction}`). No direct ore-demand key: the Ticker moves item demand only; ore follows via shortages.
- Hand-authored interim table per state in barometer data (e.g. war → shield, blast, healingBurst, blackHole up; festival's old physics bump → physics items; crisis's old fate bump → fate items; boom/recession/inflation/regulation → `demandAll`). The old ore-price read on Barometer is removed; its callers move to Market.
- Election's `effectMod` continues to scale merged effects, now including the new keys.
- Ticker influence actions (incl. `floodMarket`) are unchanged — reworked in the Ticker-evolution doc.

### Lanes (Economy, Offers, VeinTrade, Jobs, ArchieDeals)
- Archie sell lane: ore and consumables at quote, then quality multiplier (consumables), district `priceMod`, Archie cut — all as today. Records supply (mugged or not).
- Faction lanes: effective price = quote (+ district mod where configured), then buy/sell spread by relation as today. Player sells record supply; player buys record demand. Faction marketplace stock (random restock) unchanged until sub-spec 2.
- Contracts "buy missing calc": priced via the faction lane as today; records demand.
- Offers' per-unit value: quote. James craft jobs `payPerItem`: quote. Archie tag-along deals: priced at quote, record nothing.
- Vein sale / buyout valuation: 2-day average quote.
- Faction AI vein scoring and raid-strength scaling keep `basePrice` (revisit in 4a).
- Sell rows expose yesterday's price so screens can render ▲/▼.

### Contracts / Offers
- **Price:** a pending offer's quote is recomputed from today's market (Offers exposes the live quote; screens re-read it). `accept_offer` freezes the quote onto the contract as the signed price; all settlement reads the signed price. Premium = existing multiplier stack, no haggling UI.
- **Term:** recurring contracts gain `startDay`, `termWeeks` (default 4, JSON), `expiryDay` (a Monday). On the due-day tick where `dueDay ≥ expiryDay`, the final period settles as usual and the contract moves to history as expired instead of renewing; a renewal offer is issued.
- **Renewal offer:** same request lines and counterparty, `source: "renewal"`, fresh live quote, short expiry (placeholder 3 days, JSON), bypasses `PENDING_CAP`. Accepting starts a new term. Declining/expiring: no relation change. Templates keep their existing reissue hooks, so Act 1 recurring templates can't softlock (Act 1 proof needs 2 qualified periods, well inside 4 weeks).
- **Migration:** an active recurring contract with no `expiryDay` gets one at its next weekly renewal (`renewal day + 4 weeks`). SaveManager backfill leaves the field absent so this rule can apply.
- **Counterparty:** every offer and contract carries `counterparty` (a faction id), shown on offer and active cards.
  - Scripted templates (incl. `biz_starter_*`, `biz_recurring_*`, `scripted_*`) declare `counterparty` in offers data.
  - Random offers: if offer value (live payment) is under a size threshold (JSON), counterparty ∈ {collective, firm} by identity fit (life/emotion goods → collective; physics goods → firm; otherwise higher player relation, ties random via seeded Rng). Above the threshold: weighted across all five factions — ore goods weighted to factions that craft with that ore; item goods weighted to factions that consume it; goods with no weight fall back to the small-offer rule.
  - Existing saves: offers/contracts without a counterparty are backfilled by the same rule (scripted templates from data).
- **Cancel:** `Contracts.cancel` applies a small flat relation loss (JSON) to the counterparty via the existing player-relation adjuster. No other faction reacts.
- **Delivery hook:** each delivery calls a Market-side hook `note_contract_delivery(counterparty, kind, type, qty)` that records the delivery (bounded, for sub-spec 2) with no price effect and no supply record.

### Faction identity data
- Faction data gains `archetype`, `primaryOre`, `secondaryOre`, `crafts` (recipe keys), `consumes` (recipe keys → base weekly qty, placeholder). Used in sub-spec 1 only for counterparty weighting; FactionSim consumes it in sub-spec 2. Draft table (from the macro spec):

| Faction | Archetype | Ore (primary / secondary) | Crafts | Consumes |
|---|---|---|---|---|
| Collective | producer | life / emotion | healingSalve, enhancementPowder | healingSalve |
| Firm | producer | physics / life | blast, shield, healingBurst | blast, shield, healingBurst, enhancementPowder |
| Guild | crafter | time / physics | timePearl, rewind, wormhole, prophetsBreath, rejuvenation | little |
| Network | information broker | emotion / fate | pansPrank | prophetsBreath |
| Conclave | manipulator | fate / time | failsafe | failsafe, rejuvenation |

- Stances and pressure are **not** in this sub-spec.

### Ticker app (screen)
- Two tabs: **News** (existing headlines and axis push/pull/influence actions, unchanged) and **Stock Market**.
- Stock Market: rows per ore type then per item — symbol, name, price, ▲/▼ + delta versus yesterday. Tap → chart of history with annotation markers, and the item's active Ticker demand modifier (or, for an ore, the items currently driving its demand). A list of active demand modifiers sits on the tab.
- Visible from day 1. Screen reads state and Market reads only; mutates nothing.

### Rollover placement
- Market reprice runs after every step that sells or buys in the tick (after contracts/business/offers steps) and after Barometer so today's Ticker state feeds today's reprice. Exact step letter set by the ticket against REFERENCE.md §3.1.

### State (pure data)
- `market`: per good `{stock, price, prevPrice, history[]}`, today's `supply`/`demand` tallies per good (+ source breakdown), `annotations[]` (bounded), `deliveries[]` (bounded), `startedDay`.
- Contracts: `signedQuote`, `startDay`, `termWeeks`, `expiryDay`, `counterparty`. Offers: `counterparty`, `source` may be `renewal`.
- SaveManager backfills `market` at resting prices (stock = equilibrium) for old saves.

### Data (all JSON, none in code)
- Market constants: clamp min/max, smoothing fraction, reversion fraction, curve shape, history length, annotation thresholds, sim-start switch.
- Per good: `normalStock`, stand-in supply, stand-in demand; ore→item conversion rate.
- Barometer: `demandAll` / `itemDemand` per state (old price keys removed).
- Offers: `counterparty` per scripted template; small-offer threshold; renewal expiry days; default term weeks; cancel relation hit.
- Factions: identity fields above.

### Docs
- REFERENCE.md updated in the same change: §1.8 (faction fields), §1.9 (barometer effects), §3.2 (merged effects — remove ore-price formula), §3.6 (selling reads London price), §3.10 (contract term, renewal, counterparty, cancel hit), §3.1 (rollover step), plus a new Market section with the formulas. CODEMAP gets the new system and the Ticker app change.

## Testing Decisions

- Good tests assert external behaviour only: seed `GameState.state`, drive a public entry point, assert resulting state (prices, stock, history, annotations, contracts/offers, relation). Never assert internal helper calls or intermediate values.
- **Primary seam — the day rollover** (`TimeSystem.daily_tick`): seed, advance N rollovers, assert.
  - No player sales → price drifts to the idle premium and holds.
  - Normal pace → price near base.
  - Big dump → today's sale at today's price; next day lower; back near equilibrium within 2–4 days.
  - Repeated dumps → approach but never pass the floor; forced shortage never passes the ceiling.
  - Ticker item-demand effect → that item's price rises; its ingredient ores rise over following days; recording player item supply dampens the ore rise; mixed recipe lifts both ores.
  - Recurring contract reaches `expiryDay` → final period settles, contract in history as expired, renewal offer pending (even with a full list), renewal expiry clean with no relation change.
  - Old open-ended contract → gains `expiryDay` at next renewal.
  - Sim-start switch `bizA2` → prices stay at base, reprice no-op.
- **Market quote (pure) direct tests:** clamps at both ends, zero stock, stock exactly normal, 2-day average with and without history.
- **Existing public entry points:**
  - Economy Archie sell lane and faction lanes: price equals quote-derived price; supply/demand recorded; mugged sale still records supply; Archie deal records nothing.
  - Offers: pending live quote changes after a reprice; accept freezes it; settlement pays the signed price after further reprices; counterparty assignment for small (Collective/Firm by fit, relation fallback) and large offers; scripted templates carry their authored counterparty.
  - Contracts: cancel applies the relation hit to the counterparty only; deliveries don't record supply but do record the delivery hook.
- **SaveManager round-trip:** market, contract and offer fields survive save/load; old save backfills market at resting prices and counterparties.
- Seeded Rng for any probabilistic step (random offer counterparty picks).
- Prior art: time-system rollover tests, barometer tests, economy lane pricing tests, offers/contracts tests (quote, settlement, renewal, cancel), Business Empire Act 1 quest tests (recurring templates still complete the proof), savemanager tests.
- Suite discipline: one targeted run per change, one full suite + check_all at the end.

## Out of Scope

- FactionSim (real faction production/crafting/consumption, faction market selling/buying, faction stock as marketplace stock), shares, stockpiles — sub-spec 2.
- Faction demand reduced by contract deliveries — hook only here; effect in sub-spec 2.
- Stances, pressure, escalation, cross-faction jealousy over contracts — sub-spec 4a.
- Ticker evolution: turning headlines into news stories, new Ticker states, reworking influence actions (incl. `floodMarket` feeding supply) — separate Ticker-evolution doc.
- Haggling / negotiated premiums UI.
- Guard upkeep and business float — sub-spec 3.
- Act 2 questline and moving any gate to the Act 2 meeting — sub-spec 5.
- Faction AI scoring on live prices.

## Further Notes

- **Sub-spec 2 interface sketch** (what this sub-spec exposes; sub-spec 2 fills it):
  - `Market.record_supply / record_demand(kind, type, qty, source)` — FactionSim's sells/buys use the same calls as player lanes, with a faction id as `source`.
  - The stand-in London provider is one read point per good; FactionSim replaces stand-in supply/demand with real recorded faction activity (normalStock retuned so the player-at-Act-1-end ≈ 10–15% target still holds).
  - `note_contract_delivery(counterparty, kind, type, qty)` — recorded here; sub-spec 2 uses it to reduce the buyer faction's demand and credit the player's production share.
  - Faction identity fields already in faction data.
  - `source` on supply tallies lets sub-spec 2 derive shares and credit annotations ("someone" vs a named actor).
- Existing Ticker effect callers on ore price (Archie lane, faction lanes, offers, vein trade, Archie deals) all move to Market; nothing should read Barometer for prices afterwards.
- PROSE-REVIEW: any new UI strings (tab labels, annotation labels, renewal offer copy, counterparty line on cards) get flagged in the implementing tickets.
- Canonical vocabulary: Ticker (barometer), calc, the five ore types, consumable ids, `cash`.
