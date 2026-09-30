# Biz Act 2 — Sub-spec 4: Rivalry, diplomacy & intel

Status: ready-for-agent

> Sub-spec 4 (4a + 4b combined) of `.scratch/biz-empire-act2/spec.md` (macro vision). Builds on sub-spec 1 (market sim), sub-spec 2 (faction economy) and sub-spec 3 (guard upkeep + float), all built. Covers stances, threat / dependence / pressure, relation and stance drift, archetype escalation menus, war, war weariness, truces and negotiated peace, the Conclave as London's stabiliser, relation levers (favours, gifts to key members), partners, the Network intel economy and intel meters, stockpile raids, the weakening floor, the Collective–Firm hold, and the items sub-spec 2 deferred here (raid bias to specialist ores, Firm shortfall stealing, smart reserves, Conclave Ticker pushes). One spec, split into tickets along the 4a/4b line (or finer) at ticketing time. Numbers marked *placeholder* are feel targets; the implementing ticket pins them in JSON and REFERENCE.md against the tuning tool.

## Problem Statement

After sub-specs 1–3 London has a real market, real faction production and real guard costs, but factions still don't *react* to anyone. The player can take 40% of the Firm's primary ore and the Firm does nothing about it. Faction-vs-faction conflict is a flat daily dice roll weighted by an "industries" number, unrelated to who is eating whose lunch. Relation is an unbounded counter that only moves through scripted quest beats, trade meters and raid penalties. Once two sides are fighting there's no way to stop: no ceasefire, no peace terms, no one pushing for calm. The Network sells one kind of timed site intel to the Collective questline and nothing else, and nobody can know anything about anyone. Stockpiles exist as a location nobody can find or hit. The player has no reason to court a faction, no way to soften a rival, no ally who will help, and no picture of the politics.

## Solution

Every faction constantly weighs how much each other actor (the player and every other faction) threatens it against how much it depends on them. The difference moves relation a little each day. Relation sets a **stance** (Partner, Neutral, Business rival, Hostile). Stance and relation bands open up an **archetype-specific menu** of moves: warnings, then market moves (floods, undercuts, contract poaching, outbidding for sites, lowball buyouts, withholding), then raids. Nothing is anonymous. Every move against the player comes with a message from a named person and shows up in BizBrief, the Factions-app activity log and price-chart annotations. Big faction-vs-faction moves make the Ticker.

When Hostile sides keep hitting each other they are **at war**. War builds **weariness** from losses, cash drain, extra fronts and time. The **Conclave**, London's invisible hand, leans on long-running markets and wars: it squeezes each warring side in proportion to its weariness so that wars end at the table rather than in obliteration. Weariness decides when a side will accept peace and when it will offer it. Peace is agreed directly between the two sides through a **negotiation** (truce length, vein swaps, one-off or weekly payments), with scored counter-offers. A truce is a ceasefire plus a daily relation boost for its duration. Breaking a truce damages the breaker's relation with every faction.

The player's own weariness is tracked too. Archie and James warn as it climbs, and at the extreme they force the player to take a deal.

The player builds relation through **favours** (faction requests), **gifts** to each faction's named **key members**, and supplier contracts. At **Partner** stance, allies exchange price favours and shield the player from pressure from their own allies. At very high relation they also warn of plans and send help in a defence.

The **Network** sells an intel economy. Each actor holds an **intel meter** (0–100) on every other actor. Levels reveal vein security, holdings, the stockpile location, stockpile security and, at the top, the stash inside the stockpile. A top-level stockpile raid can wipe a faction's stores. The Network also sells intel on the player to the player's rivals. The player can pay the Network to keep quiet, to feed rivals false intel, or to lower what a rival knows. Factions can buy the same.

## User Stories

### Stances
1. As a player, I want every faction pair and my relationship with each faction to have a stance (Partner, Neutral, Business rival, Hostile), so that London's politics are readable at a glance.
2. As a player, I want stance to follow relation, so that I understand how to change it.
3. As a player, I want "Business rival" to apply only where the two parties actually compete (overlapping ores or items), so that a faction with nothing in common with me is never my rival.
4. As a player, I want a stance to change only after relation has stayed in the new band for a few days, so that stances don't flicker.
5. As a player, I want a stance change involving me to be announced (message + activity log), so that I notice the political map shifting.
6. As a player, I want faction-vs-faction stance changes shown in the Factions app, and big ones in the Ticker, so that I can follow London's politics.
7. As a player, I want the canonical starting stances (Collective–Firm Hostile, Guild–Conclave and Network–Conclave Business rival, Collective–Guild Partner, others Neutral), so that London starts with a shape.
8. As a player, I want relation limited to −100..+100, so that relation values stay meaningful and a relation hole can be climbed out of.

### Threat, dependence, pressure
9. As a player, I want a faction to feel threatened by my share of its primary and secondary ores, so that muscling in on its specialty is noticed.
10. As a player, I want a faction to feel threatened by my crafting share of the items it crafts, so that competing with a crafter is noticed.
11. As a player, I want a faction to feel threatened by my veins in its home districts, so that territory matters.
12. As a player, I want a faction to feel mildly threatened by my overall size, so that a big player attracts general attention.
13. As a player, I want a faction to depend on me in proportion to my supplier share to it and my active contracts with it, so that being useful protects me.
14. As a player, I want the daily relation change to be dependence minus threat (capped per day), so that a useful competitor can stay on good terms and a pure competitor slowly loses them.
15. As a player supplying faction A, I want A's Hostile enemies to feel strong extra threat from me and A's Business rivals a weak extra threat, so that picking a customer has political cost.
16. As a player Partnered with faction A, I want A's Partners to feel less threat from me, so that alliances shield me.
17. As a player, I want a pressure label per faction (Calm / Watching / Annoyed / Moving against you), so that I don't need raw numbers.
18. As a player, I want the same threat/dependence model to run between every pair of factions, so that factions compete with each other for the same reasons they compete with me.
19. As a player, I want each faction's aggression personality (from its old "industries" weighting) to scale how hard it reacts to threat, so that the Firm feels touchier than the Guild.

### Escalation menus
20. As a player, I want each archetype to have its own menu of moves, so that each faction fights like itself.
21. As a player, I want a producer (Collective, Firm) to flood my ore type, outbid me for sites and raid, so that producers fight over production.
22. As a player, I want a crafter (Guild) to poach my contract buyers, withhold items I need, and lowball-buy my veins, so that the Guild fights with commerce.
23. As a player, I want the Network to sell intel on me to my rivals and inflate its prices to me, so that crossing the Network is quietly dangerous.
24. As a player, I want the Conclave to undercut my sales and deny me goods, so that the manipulator fights with the market.
25. As a player, I want relation bands to gate which rungs are open (warning first, then market moves, raids only when Hostile or below the faction's raid threshold), so that high relation buys time.
26. As a player, I want a warning message before a faction's first move in a new band, so that I have a chance to respond.
27. As a player, I want a faction to pick the move that hurts me most and that it can afford, so that its choices feel deliberate.
28. As a player, I want a cooldown between one faction's moves against the same target, so that escalation is paced.
29. As a player, I want a flood to cost the flooding faction (selling below its value), so that floods only happen under real pressure.
30. As a player, I want a poach to appear as a rival undercutting the renewal of one of my contracts, so that I must defend my buyers.
31. As a player, I want an outbid to mean a rival claims a site I'm prospecting or eyeing before I can, so that expansion is contested.
32. As a player short of cash or who has just lost a vein, I want to receive lowball buyout offers for my veins, so that a squeeze has a tempting exit.
33. As a player, I want factions to bias raid targets toward veins of their specialist ores, so that their identity shows in whom they hit.
34. As a player, I want the Firm to raid and steal to cover the ore it doesn't cultivate enough of, even when not Hostile, so that the Firm is a predator by nature.
35. As a player, I want factions to stockpile ahead of a planned flood or raid, to hoard on Ticker hints, and to withhold supply to squeeze a target, so that faction stock is used as a weapon.

### Communication
36. As a player, I want every move against me delivered as a message from that faction's key member (or explained by Archie), so that each hit has a face.
37. As a player, I want every move against me listed in BizBrief and in that faction's activity log in the Factions app, so that I can review what happened.
38. As a player, I want market moves annotated on the price chart with the actor's name, so that I know why the line moved.
39. As a player, I want every action named (no anonymous actors), so that I'm never confused about who hit me.
40. As a player, I want big faction-vs-faction moves (a flood, a vein taken, a war declared, a truce signed) to appear as Ticker headlines, so that London's conflicts are news.
41. As a player, I want Archie to explain a move type the first time I suffer it, so that I learn the counters.

### War & weariness
42. As a player, I want two parties to be "at war" when their stance is Hostile and they've traded a hostile act (raid, flood, stockpile raid) recently, so that civil business rivalry is not war.
43. As a player, I want a war to end on a truce or after a quiet spell, so that wars don't linger forever.
44. As a player, I want each side at war to build weariness from losses and cash drain (most), extra fronts (next) and days at war (least), so that grinding wars wear sides down.
45. As a player, I want weariness to ease when not at war, so that a side recovers.
46. As a player, I want each faction to have two weariness thresholds (willing to accept peace; will offer peace), so that peace arrives at believable moments.
47. As a player, I want my own business to have a weariness meter shown in BizBrief, so that I see the cost of my wars.
48. As a player, I want Archie and James to message me as my weariness rises, so that I get advice before it's a crisis.
49. As a player at extreme weariness, I want the next peace offer from my enemy to bind (I can negotiate terms but can't walk away), so that a disastrous war ends.
50. As a player at extreme weariness, I want to keep raiding my enemy until the peace is signed, so that I keep agency.

### Peace & negotiation
51. As a player, I want a faction at its "offer" weariness to message me a peace proposal, so that peace can come to me.
52. As a player, I want to propose peace to a faction I'm at war with via its key member, and have it accepted only if the faction's weariness is at least its "accept" threshold, so that timing matters.
53. As a player, I want a negotiation menu where I can set truce length, vein swaps, and one-off or weekly payments either way, so that peace has real terms.
54. As a player, I want the faction to score my proposal and either accept or counter once per round with the nearest acceptable tweak, so that negotiation feels responsive.
55. As a player, I want negotiation capped at three rounds, with a failed or abandoned negotiation costing a little relation and starting a cooldown, so that haggling has limits.
56. As a player, I want a faction's acceptance bar to fall as its weariness rises, so that a battered enemy gives better terms.
57. As a player, I want a signed truce to stop raids and market moves between the two sides for its duration, so that a ceasefire means something.
58. As a player, I want a truce to reset relation to just above the Hostile band and add a daily relation bonus for its duration, so that peace can grow into something better.
59. As a player, I want weekly payments agreed in a truce to be collected on Mondays like other bills, so that terms are enforced by the systems I know.
60. As a player, I want vein swaps agreed in a truce to transfer on signing, so that terms are immediate.
61. As a player, I want breaking a truce (raiding or moving against the other side during it) to tank my relation with every faction, so that my word matters.
62. As a player, I want factions to negotiate peace with each other using the same scorer (terms picked automatically), and to be punished the same way for breaking a truce, so that London's wars end too.

### The Conclave
63. As a player, I want the Conclave to lean against a good whose price has stayed beyond a band from normal for a run of days (buying the crash, selling into the spike, at a cost to itself), so that London's market self-stabilises.
64. As a player, I want the Conclave to squeeze each side of a long war in proportion to its weariness (denying war goods, undercutting sales), so that wars end at the table.
65. As a player, I want the Conclave never to offer or broker peace itself, so that it stays the invisible hand.
66. As a player, I want the Conclave's pressure to stop a strong faction from obliterating a weak one, so that London stays plural.
67. As a player, I want the Conclave to take a market position and then push the Ticker in its favour, so that manipulation has a mechanism.
68. As a player, I want Ticker headlines to hint at big positions ("someone's buying up physics"), so that I can read and ride the Conclave.

### Relation levers
69. As a player, I want factions to message me favour requests (deliver goods by a day, guard a vein, sit out a raid, sell to them below market), so that I can earn goodwill.
70. As a player, I want completing a favour to raise relation, ignoring one to cost nothing, and failing an accepted one to cost a little, so that accepting is a commitment.
71. As a player, I want each faction to have named key members, so that relationships have faces.
72. As a player, I want to gift cash or items to a key member, raising that member's and the faction's relation, with diminishing returns and a weekly cooldown per member, so that I can soften a rival quickly but not infinitely.
73. As a player, I want each key member to like certain items more, so that thoughtful gifts go further.
74. As a player, I want supplier contracts to raise dependence (and relation via existing trade meters), so that commerce builds alliances.
75. As a player, I want two sample favours and two sample gift preferences per faction, so that the system ships with content.

### Partners
76. As a player at Partner stance, I want to ask the partner for a better price at a relation cost, so that alliances pay at the counter.
77. As a player at Partner stance, I want a partner in trouble to ask me for a better price, with acceptance raising relation, so that alliances are two-way.
78. As a player at Partner stance, I want my partner's allies to feel less threat from me, so that alliances shield me.
79. As a player at very high relation with a partner, I want it to warn me of another faction's planned move against me, but only if the partner itself has good relation with that faction, so that the warning has a believable source.
80. As a player at very high relation with a partner, I want it to sometimes send help into a vein defence, so that allies fight beside me.
81. As a player, I want factions that are Partners to do the same for each other, so that alliances shape faction wars.

### Intel
82. As a player, I want an intel meter (0–100) on each faction, so that my knowledge of a rival is a resource.
83. As a player, I want intel levels that unlock in order (vein security → holdings → stockpile location → stockpile security → stash detail), so that deeper intel reveals more.
84. As a player, I want intel filled mainly by Network purchases, and also by scouting/raiding that faction, favours and partner leaks, so that there are several routes.
85. As a player, I want intel to decay slowly, and to drop below the location level when a stockpile relocates, so that intel must be maintained.
86. As a player, I want a priced intel menu from the Network's handler (raid intel, counter-raid warnings, market intel, stockpile intel, intel-level boosts), so that information is buyable.
87. As a player, I want Network prices to scale slightly with relation and certain products to be locked behind relation, so that the Network relationship matters without being a paywall.
88. As a player, I want the Network to sell intel on me to my rivals, raising their intel meter on me, so that I have a reason to care.
89. As a player, I want to pay the Network to keep quiet about me for a period, so that I can protect myself.
90. As a player, I want to pay the Network to feed a rival disinformation (they target my strongest veins, or overestimate my strength and raid less), so that I can deceive.
91. As a player, I want to pay the Network to lower a rival's intel meter on me, so that I can undo a leak.
92. As a player, I want factions to buy the same products (intel, privacy, disinformation, intel reduction) against me and each other, so that the intel economy is real.
93. As a player, I want a faction's intel on its target to improve its target choice and raid odds, so that intel has teeth.

### Stockpile raids
94. As a player with enough intel on a faction, I want its stockpile to appear as a raid target in its district, so that finding it is a mission.
95. As a player, I want to raid a stockpile using the existing raid flow, against stockpile guards (paid upkeep like vein guards) and kit, so that it feels like a raid.
96. As a player, I want a successful raid to steal a share of holdings (capped by what I can carry), so that raids are profitable.
97. As a player with top-level intel, I want a successful stockpile raid to be able to wipe the faction's stores, so that a well-prepared strike can neutralise a flood.
98. As a player, I want a stockpile raid to cause a big relation hit and start a war clock, so that it's a serious act.
99. As a player, I want a raided stockpile to relocate, so that the next raid needs fresh intel.
100. As a player, I want factions to raid each other's stockpiles, so that London's market reacts to its own conflicts.

### Weakening floor
101. As a player, I want factions to be weakenable (lose share, veins, stock, guards, cash), so that winning is possible.
102. As a player, I want a broke faction's moves limited to what it can afford, so that crushing a rival pays off.
103. As a player, I want every faction's non-calc income to be protected, so that no faction is ever truly dead.
104. As a player, I want a faction that has lost its veins to keep prospecting and seeding new ones, so that it can recover.
105. As a player, I want veins that a questline depends on to stay protected, so that stories never break.
106. As a player, I want a last-resort production bonus for a severely weakened faction, so that London's roster recovers.

### Collective–Firm hold
107. As a player mid-Collective questline, I want the Collective–Firm pair skipped by the pressure AI, so that the questline stays in charge.
108. As a player who has finished the Collective questline, I want the pair to join the AI at Hostile, so that their conflict continues with economic motives.

## Implementation Decisions

### Modules
- **FactionAI (new system)** owns stances, threat/dependence/pressure, relation drift, the escalation menus and move choice, war state, weariness, truces, negotiation scoring, partner behaviour, and the Conclave's stabiliser/squeeze/Ticker-push decisions. It runs in the daily rollover. It never touches Nodes. Its public entry points are the daily steps plus the player actions: propose/counter/accept/abandon a negotiation, answer a peace offer, ask/answer a partner price favour.
- **Diplomacy levers** (new small system, or part of FactionAI; the ticket decides): favour requests (issue, accept, complete, fail) and gifts (give, with preferences, cooldowns, diminishing returns). Favours reuse the existing offers/contracts and objectives plumbing for "deliver X by day N" rather than a new tracker.
- **Intel (new system, or an expansion of the Network handler)**: intel meters for every observer→target pair, their decay, level reads, purchase products, privacy/disinformation/reduction effects, and faction purchases. The existing timed per-site Network intel (Collective questline) stays working. The ticket decides whether it becomes one product of the new menu or stays a separate path.
- **Factions**: the relation clamp is applied in both the player and faction-pair adjusters. The old daily rivalry initiation roll is removed. Faction-vs-faction attacks come only from FactionAI's menu, and the existing rivalry resolution/odds are reused as the "raid" move's resolver. The industry aggression weighting becomes a personality multiplier on threat.
- **Raiding**: the player-raid gate becomes FactionAI's decision (the raid rung is open when Hostile or relation < the faction's `raidThreshold`, which stays as data). The old worst-relation fallback attacker pick is replaced by the menu. Stockpile raids reuse the vein-raid flow and resolution. Raid target choice reads the attacker's intel on the defender (and any disinformation) and biases toward the attacker's specialist ores.
- **FactionSim**: reserve targets become dynamic (stockpile before a planned flood/raid, hoard on Ticker hints, withhold to squeeze). It exposes a sell-at-loss "flood" and targeted buy/deny actions for FactionAI to invoke. The weak-faction production bonus is added. Factions keep prospecting and claiming new sites even with zero veins, and the existing NPC claim path is checked to allow this.
- **Market**: floods, undercuts, Conclave rebalancing and denial all go through the existing supply/demand recording, so prices respond normally. The existing named annotations cover every faction market move.
- **Contracts / Offers**: poaching is a rival's cheaper counter-offer attached to one of the player's pending renewals. The buyer takes the rival unless the player matches. Truce weekly payments settle on Mondays alongside other bills; the ticket decides whether through the contract machinery or a dedicated obligation list.
- **VeinTrade**: lowball buyouts are faction offers priced below the vein's current quote, sent as a message with an accept action that calls the existing sell-to-faction path. Truce vein swaps reuse the existing transfer paths.
- **Barometer (Ticker)**: gains headlines for big faction-vs-faction moves and position hints. It gains a Conclave push hook, a small nudge toward a Ticker state the Conclave holds a position in, which reuses faction barometer prefs as the mechanism.
- **Messages / Contacts**: new key-member contacts for the Firm, Guild and Conclave. The Collective uses Des, Nadia and Hakim; the Network uses the handler. Warnings, peace offers, favour requests, partner warnings, poach and buyout notices come from key members. Archie and James send weariness nags and first-time explainers. Actionable messages use the existing pending-message mechanism.
- **Screens** (read + call systems only): Factions app gets stance, pressure label, activity log, intel level and what it reveals, gift/favour/negotiate/intel-menu entry points per faction, and a stance matrix view of London. BizBrief gets moves against me, weariness meter, and war/truce status. Negotiation sheet. Network intel menu. Stockpile pins on the map when revealed.

### Stance model
- Stance is derived from relation bands with hysteresis: relation must sit in a new band for *N days (placeholder 3)* before the stored stance flips.
- Bands (*placeholders*): Partner ≥ +50; Hostile ≤ −40; otherwise Business rival if the pair overlaps (shares a primary/secondary ore, or one crafts what the other crafts), else Neutral. Overlap for the player = the player holds ≥ *5%* ore or crafting share in one of the faction's ores/items.
- Stance is stored in state for each faction pair and for the player with each faction. The pair is symmetric; player→faction uses the faction's player relation.
- Starting stances are data. Starting pair relations are set inside their stance band. The Collective's player stance follows its questline state.

### Pressure
- Threat(observer → target), each *placeholder weight* in JSON: target's ore share in observer's primary ore (heavy), secondary ore (medium), crafting share in observer's crafted items (medium), veins in observer's home districts (medium), overall size (light), jealousy term (target supplies observer's Hostile enemies: strong; Business rivals: weak; scaled by that supplier share), partner-shield term (target is Partner with observer's Partner: negative).
- Dependence(observer → target): supplier share target → observer, plus active contracts count/value with target.
- Daily relation delta = clamp(personality × (dependence − threat), −cap, +cap) (*cap placeholder 3*). Relation is clamped to −100..+100 everywhere.
- The pressure label is read from the delta and the current band (Calm / Watching / Annoyed / Moving against you).
- FactionAI reads the rolling shares sub-spec 2 built. Pressure weights are anchored on the share targets (producer 30–40% of its primary; player end of Act 1 10–15%).
- Faction vein valuation and raid-strength scaling in AI scoring move from base price to the Market quote.

### Escalation menus (per archetype; *placeholder bands*)
| Archetype | Warning (< +20) | Market moves (< 0) | Raid rung (Hostile or < raidThreshold) |
|---|---|---|---|
| producer (Collective, Firm) | yes | flood target's ore, outbid for sites, withhold | vein raid, stockpile raid |
| crafter (Guild) | yes | poach contracts, withhold items, lowball buyout | stockpile raid (hired) |
| info broker (Network) | yes | sell intel on target to its enemies, price-gouge target, leak disinformation about target | stockpile raid |
| manipulator (Conclave) | yes | undercut target's sales, deny goods, Ticker push against target | none of its own |
- A faction picks the affordable move with the highest expected damage to the target. It spends one move per target per cooldown (*placeholder 5 days*). Before the first move in a new band it always sends a warning.
- The Firm's "shortfall steal" is a raid move open at any stance except Partner. It triggers when its holdings of an ore it consumes stay under target for a run of days. It prefers veins of that ore.
- Poach and outbid have no faction-vs-faction equivalent (faction contracts don't exist) and are skipped between factions.
- Moves are blocked between truce parties and for the Collective–Firm pair while the Collective questline is incomplete.

### War, weariness, truce
- At war(A,B) = stance Hostile AND a hostile act (raid, flood, stockpile raid, shortfall steal) between them within *N days (placeholder 7)*. War ends on truce or after that many quiet days.
- Weariness (0–100 per party per war) rises daily from, in descending weight: losses (vein value lost, stock stolen, guards lost, fights lost), cash drain above peacetime baseline (guard/kit spend, flood losses), multiple fronts (multiplier per extra war), days at war (small). It decays when not at war.
- Faction thresholds are data per faction: `acceptPeace` (lower) and `offerPeace` (higher).
- Player thresholds: `nag` (Archie/James messages, escalating) and `extreme`. At extreme, the next peace offer from any enemy binds. The player can counter inside the negotiation but can't abandon it. Raids by the player stay allowed until signing.
- Negotiation: a proposal is {truce days, vein transfers each way, one-off cash each way, weekly cash each way for the truce duration}. The faction scores it (payments and veins at market value, truce days weighted by its weariness) against an acceptance bar that falls as weariness rises. Result: accept, or one counter per round (the nearest acceptable tweak). Max 3 rounds. Failed or abandoned: small relation hit plus a cooldown before re-proposing. Faction–faction peace uses the same scorer with auto-picked terms.
- Truce: ceasefire (no moves between the parties), relation set to just above the Hostile band, and a daily relation bonus for the truce duration on top of normal drift. Weekly payments collected on Mondays, vein swaps on signing. Breaking a truce: large relation loss with every faction.

### Conclave
- Stabiliser: a good whose price stays beyond ±*X%* of normal for *N days* gets a Conclave counter-trade. Its size is larger than plain arbitrage, it accepts a loss, and it is funded by the high non-calc income.
- War squeeze: a war older than *N days* gets Conclave pressure on each side proportional to that side's weariness (deny its war goods and ore, undercut its sales). This never pushes toward one side's destruction. It also holds back a side from wiping out a much weaker one, which is checked by a balance test.
- Ticker push: the Conclave takes a position, then nudges the Ticker toward the state that pays it. It is capped and has a cooldown. A hint headline fires when a position is large.
- The Conclave never brokers or offers peace.

### Partners
- Partner stance: price-favour ask (player → partner: discount for a relation cost). Partner in trouble (low holdings or cash) asks the player for a discount, and accepting raises relation. Pressure shield (above).
- Very high relation (*placeholder ≥ +80*): partner warnings, only when the partner's relation with the aggressor is ≥ Neutral band (the partner explains how it knows). Occasional defence help via the existing vein-defence ally path.

### Intel
- A meter for each observer → target pair (player → each faction; each faction → player and each other faction), 0–100. Levels at *20/40/60/80/100*: vein security → holdings (ore/items) → stockpile location → stockpile security → stash detail (enables a wipe on a successful raid).
- Sources: Network purchases (main), scouting/raiding the target, favours for the target's enemies, partner leaks. Slow daily decay. A stockpile relocation drops the observer below the location level.
- Network menu (player via handler; factions via FactionAI): raid intel (planned moves against you, next 7 days), counter-raid warning subscription, market intel (planned big buys/dumps), intel boost on a target, privacy (Network won't sell on you for N days), disinformation on a rival (inverted target choice, or strength overestimate lowering its raid chance, for N days), intel reduction (lower a rival's meter on you). Prices have a small relation modifier. Some products are locked behind relation bands.
- Faction intel on its target feeds its target choice and raid odds.

### Stockpile raids
- A stockpile is raidable once the observer's intel ≥ the location level. It shows as a pin in its district. The raid uses the existing raid flow with stockpile guards (faction pays upkeep as for vein guards) and faction kit.
- Success steals a share of holdings, capped by carry. With stash-level intel, a success can wipe the holdings.
- Consequences: large relation hit, counts as a hostile act (war clock), the stockpile relocates.
- Factions raid each other's stockpiles through the same resolution.

### Floor
- Non-calc income is never reduced below its floor. Quest-locked veins stay protected (existing mechanism). There is no general vein floor.
- A faction with zero veins keeps prospecting and claiming.
- Last-resort production bonus while a faction is under a weakness threshold.
- A broke faction's menu is filtered to affordable moves.

### Collective–Firm hold
- FactionAI skips the pair (no drift, no moves, no war) while the Collective questline is incomplete. On completion the pair joins at Hostile.

### State (pure data; SaveManager backfills all)
- Stance matrix (pairs + player), with pending-flip day counters.
- Per observer→target: last threat/dependence/delta snapshot, move cooldown, band-warning sent flag.
- Wars: list of {parties, startDay, lastHostileDay, weariness per party}.
- Truces: list of {parties, endDay, dailyBonus, weekly payment terms}.
- Negotiation in progress: {counterparty, round, proposal, lastCounter, binding}.
- Player weariness + nag level.
- Intel meters matrix. Privacy/disinformation timers.
- Favour requests (pending/accepted), gift cooldowns and diminishing-return counters per key member.
- Activity log per faction (bounded).
- Conclave positions and stabiliser run counters.

### Rollover placement
The steps slot after today's trading and before the Market reprice, so the moves made today are priced into tomorrow. In order: FactionAI pressure + relation drift + stance update → war/weariness/truce update → Conclave stabiliser/squeeze/push → escalation moves (and their messages/annotations/headlines) → faction intel purchases and decay → favour issue/expiry. Faction raid moves are queued for the existing raid resolution step on the next rollover, so today's decision resolves tomorrow morning. The tickets fix exact step numbers in REFERENCE.md §3.1.

### Data
- Per faction: aggression personality, weariness thresholds, key members, gift preferences, sample favours.
- Global: stance bands and hysteresis, pressure weights, daily cap, menus per archetype, move costs and cooldowns, war window, weariness weights and decay, truce defaults, negotiation scorer constants, Conclave thresholds, intel levels, product prices and gates, decay, stockpile raid loot shares.
- All in JSON.

### Prose
- Key member intros, warnings per archetype, peace offers, negotiation lines, favour requests, gift reactions, partner warnings, Archie/James weariness nags and explainers, and Ticker headlines are all new prose, written against CONTENT-GUIDE and flagged `PROSE-REVIEW:` in their tickets.

## Testing Decisions

- Good tests assert external behaviour only: seed `GameState.state`, drive a public entry point, and assert resulting state (relation, stance, war/truce records, weariness, intel meters, holdings, prices/annotations, messages/pending messages, veins, cash). Never assert helper calls or intermediate scores.
- **Primary seam: the daily rollover.** Examples:
  - High player share in the Firm's primary ore erodes Firm relation daily.
  - A supplier contract offsets it.
  - Relation in a new band flips stance only after the hysteresis days.
  - A warning precedes the first move.
  - A flood records supply and a named annotation and costs the Firm cash.
  - Supplying the Collective raises Firm threat.
  - Hostile + raid starts a war.
  - Weariness climbs and triggers an offer message.
  - A truce blocks moves and adds the daily bonus.
  - Breaking a truce drops every faction's relation.
  - The Conclave counter-trades a long spike and squeezes both sides of a long war.
  - Intel decays.
  - The Collective–Firm pair is skipped until the questline completes, then starts Hostile.
  - The Firm shortfall-steals when short.
  - Partner warnings fire only with the right relation web.
- **Secondary seams (player actions):**
  - negotiation propose/counter/accept/abandon, including binding at extreme weariness;
  - gift (cooldown, diminishing returns, preferences);
  - favour accept/complete/fail;
  - Network product purchases (meter, privacy, disinformation, reduction; relation gates);
  - partner price favour both ways;
  - stockpile raid via the existing raid flow (steal, wipe with stash intel, relocation, relation hit);
  - lowball buyout accept via the existing vein-trade path;
  - poached renewal matched or lost.
- FactionAI's internal scorers are tested only through these seams.
- The Rng is seeded for every probabilistic step.
- Save round-trip: all new keys survive save/load and backfill on an old save.
- **Tuning tool:** the existing headless faction-economy sim is extended to print relation/stance/war/weariness/truce timelines. It is used to pin placeholders against feel targets, for example:
  - a player at 25% of the Firm's primary ore with no contracts gets a warning in about 2 weeks and a first market move in about 3;
  - wars end in a truce more often than in collapse;
  - no faction reaches 0 veins in 120 days without player targeting.
  - It is a dev tool, not a test, but the no-obliteration check becomes a slow balance test if cheap.
- Prior art:
  - faction rivalry/raid tests;
  - faction-economy (FactionSim) rollover tests;
  - contracts/offers tests (renewal, counterparty relation);
  - network handler tests;
  - raiding tests;
  - collective questline tests (pending messages, flags);
  - savemanager backfill tests.
- Suite discipline: one targeted run per change; one full suite + check_all at the end.

## Out of Scope

- Vassals (sub-spec 6).
- Act 2 questline beats (sub-spec 5). This spec only exposes the reads it needs: stance reached, share threshold, first rival move.
- Anonymous actors and unmasking (dropped: nothing is anonymous).
- Missing-kit combat penalties.
- The Conclave brokering or offering peace.
- Player-brokered faction–faction peace.
- A general minimum-vein floor.
- Ticker evolution beyond the headline additions and the Conclave push hook.
- Bulk favour/gift/flavour-quest content beyond two samples per faction. Flavour quests are a hook only (they raise relation through the existing event op).

## Further Notes

- Ticket along the 4a/4b line. Suggested dependency order:
  1. relation clamp + stances;
  2. pressure + drift;
  3. menus + communication, replacing the rivalry roll and the raid gate;
  4. war/weariness/truce/negotiation;
  5. Conclave;
  6. intel meters + Network menu;
  7. stockpile raids;
  8. levers + partners;
  9. deferred items (raid bias, Firm steal, smart reserves, Ticker push);
  10. floor;
  11. UI reads.
- Re-check sub-spec 2's share targets in the tuning tool before pinning pressure weights.
- Removing the old rivalry roll and raid gate changes Collective questline pacing. Tickets must run the collective-act2 tests and keep scripted Collective–Firm behaviour untouched.
- Canonical vocabulary: site vs vein, faction-claimed, the five ore types, `cash`, consumable ids.
- REFERENCE.md updates land with each ticket: §1.8 (faction fields), §1.9 (headlines, Conclave push), §3.1 (rollover steps), §3.6a (shop pricing via partner favours / Network gouge), §3.10 (contacts/key members, favours), and the raiding section (gate, stockpile raids, target bias).
- CONTEXT.md gains terms: stance, pressure, war, weariness, truce, intel level, key member.
