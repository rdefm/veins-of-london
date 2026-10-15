# Faction Relations Overhaul — Spec

Status: ready-for-agent

Source: design session 2026-10-12 (human-approved proposal). Builds on the existing faction stack — Stance, Pressure, Escalation, War, Weariness, Truce, Intel, Key members, Favours, Gifts, Partners (CONTEXT.md; REFERENCE.md §1.8, §1.11, §3.1, §3.10). Numbers marked **TBD** are placeholders for the tuning pass (sim + human), not decisions.

## Problem Statement

The faction simulation is deep but the player has little reason to care about it. Good relations pay out a generic 15% discount, warnings and a coin-flip of raid help — identical for every faction. Going hostile earns nothing beyond "they hit me first". Favours are the same four kinds from every faction, so relation work is repetitive. District `factionPresence` is a fixed string: holding ground changes nothing, the map never shifts, and the player can't see what a faction would do for them. Four of five factions have almost no authored content. The result: factions feel like weather, not people you deal with.

## Solution

Make faction relations a set of concrete, faction-specific stakes the player can read and act on:

- **Turf.** District control is recomputed daily from vein counts. The controller (a faction or the player) colours the district on the map, sets district modifiers, and decides which faction's perks or harassment apply to your veins there. Tap a district to see ownership shares, your active benefits/modifiers, and — per faction — what you'd unlock by improving relations.
- **Tiered perks.** Each faction offers three perk tiers (Friendly / Partner / Sworn-joined), unique to its identity, some global and some turf-scoped. They replace the generic Partner benefits.
- **Harassment.** Before raiding, hostile factions wear you down with faction-flavoured attrition — tampered locks, council noise complaints, injunctions, decertified batches, rumours — each an authored event card with incident-specific responses (pay, spend a block, ignore, and others).
- **Grudges, warmongering, and aid.** Unanswered raids make you look soft; answering can be violent, defensive, or non-violent (your own complaints, tip-offs, leaks). Too much violence makes the other factions close ranks. Good relations let you call factions into your wars.
- **Ambush squads.** Hostile factions field unique enemy squads; ambush odds depend on who controls the district you act in.
- **Varied favours and multi-card incidents.** Faction-specific favour kinds and sim-triggered incidents, with branching, chance-based options — all authored by the human as event cards; this spec provides the systems and hooks.
- **Key members as people.** Two members per faction (Speaker and Lieutenant, hawk vs dove) with personal relations, wants, and hidden standing — leading to succession, inside men, defection and betrayal. Collective Act 3 is reworked so Nadia and Des are the two contenders for leadership.
- **Storylines (D1)** are captured as a draft for human review only. **Vulture window** is split out pending simulation work.

## User Stories

### Turf — control
1. As a player, I want each district's controller worked out from who holds the most veins there, so that territory reflects what's actually on the ground.
2. As a player, I want control to require leading second place by at least 2 veins, so that a one-vein edge doesn't flip a district back and forth.
3. As a player, I want to count as a contender for control, so that building a district-spanning operation makes me a territorial power.
4. As a player, I want a Foothold tier for any contender holding at least a set share of a district's veins without controlling it, so that a strong minority presence still matters (at reduced strength).
5. As a player, I want a district with no qualifying controller to read as Contested, so that I can see flashpoints.
6. As a player, I want control recomputed once per day at rollover, so that the map is stable within a day and changes are legible.
7. As a player, I want a turf flip to appear as a Ticker headline and a map event, so that I notice shifts in the balance of power.
8. As a player, I want the district's map zone tinted in the controller's colour (neutral tint when contested, my colour when I control it), so that I can read London's political map at a glance.
9. As a player, I want new faction claims to be weighted by live control rather than the fixed heritage presence, so that strong factions consolidate where they rule.
10. As a player, I want the old fixed presence to only seed starting turf and stockpile home districts, so that a new game starts from the familiar London.
11. As a player, I want Soho to be an unowned district with real sites leaning towards emotion and time ore, so that the marketplace district is also contestable ground.
12. As a player, I want Hampstead's site cap raised, so that its control isn't decided by a trivial 2–0.

### Turf — effects
13. As a player, I want district danger and price modifiers to shift with my relation to the controller, so that friendly ground is safer and better for business and hostile ground is the opposite.
14. As a player, I want a Foothold faction's effects at reduced strength, so that minority presence is felt but not dominant.
15. As a player controlling a district, I want lower danger and a raid penalty against my veins there, so that holding territory pays off.
16. As a player controlling a district, I want every faction's pressure on me to rise, so that becoming a territorial power has a political cost.

### Turf — district info panel
17. As a player, I want to tap a district and see each contender's share of its veins as a percentage, so that I understand who owns it and by how much.
18. As a player, I want the panel to show the control tier (Control / Foothold / Contested) and the vein margin to flip it, so that I know what it would take to change hands.
19. As a player, I want the panel to list the benefits and modifiers I currently get in that district, and which faction each comes from, so that I understand why my veins there behave as they do.
20. As a player, I want to see active harassment and penalties affecting me in that district, so that I can see the cost of my hostile relations.
21. As a player, I want to tap any faction in the panel and see which perks I'd unlock with it at each higher relation tier, so that I know what improving that relationship is worth.
22. As a player, I want that faction view to show my current relation tier with them, so that the gap to the next perk is clear.

### Tiered perks
23. As a player, I want each faction to offer three perk tiers (Friendly, Partner, Sworn/joined) built on its identity, so that befriending different factions feels different.
24. As a player, I want each perk marked global or turf-scoped, so that I know whether it applies everywhere or only where that faction holds ground.
25. As a player, I want turf-scoped perks to apply to my veins in districts where the faction has Control (full) or Foothold (reduced), so that alliances and territory reinforce each other.
26. As a player Friendly with the Collective, I want Neighbourhood watch on my veins in Collective turf, so that they are less likely to be raided.
27. As a player Partnered with the Collective, I want members to tend my veins in Collective turf on days I skip them, so that my operation there is looked after.
28. As a player Sworn to the Collective, I want a one-off whip-round bailout when I'm about to lose my home, so that the community has my back.
29. As a player Friendly with the Firm, I want a protection racket (weekly fee; the Firm won't raid me and deters others), so that I can pay for peace.
30. As a player Partnered with the Firm, I want to hire Firm muscle for my raids, so that my raids hit harder.
31. As a player Sworn to the Firm, I want Firm-controlled districts to count as mine for danger, so that their turf is safe ground.
32. As a player Friendly with the Guild, I want bonus craft XP, so that my crafting improves faster.
33. As a player Partnered with the Guild, I want to join their internship programme, getting free bonus cultivation actions and a bonus craft attempt on my veins in Guild turf, so that Guild ground boosts my production.
34. As a player Sworn to the Guild, I want access to high-margin commission crafting, so that the Guild becomes an income lane.
35. As a player Friendly with the Network, I want passive intel on one faction of my choosing, so that I can watch an enemy without scouting.
36. As a player Partnered with the Network, I want forewarnings of raids from all factions, so that I can prepare.
37. As a player Sworn to the Network, I want to have them run a disinformation or price-gouge move against a rival for me, so that information is a weapon I can wield.
38. As a player Friendly with the Conclave, I want legal cover in Conclave turf (barometer/police danger reduced), so that the authorities look away.
39. As a player Partnered with the Conclave, I want their lawyers to recover one vein I lost in a raid without a fight, so that I have a legal remedy.
40. As a player Sworn to the Conclave, I want barometer influence and access to the Deep Vein lore route, so that I share in the ancient order's power.
41. As a player, I want these perks to replace the generic Partner benefits (price favour, passive raid/defence help), so that every faction relationship is distinct rather than stacked on a generic layer.

### Harassment
42. As a player hostile with a faction, I want it to harass me before it raids, so that conflict escalates in stages I can respond to.
43. As a player, I want harassment to target my veins in that faction's turf, so that where I operate determines my exposure.
44. As a player, I want each harassment to be an authored event card with responses specific to that incident (pay, spend a block, ignore, or incident-specific options), so that each one is a small decision rather than a fixed tax.
45. As a player, I want ignored harassment to persist or worsen, so that ignoring has a real cost.
46. As a player, I want Firm harassment to tamper with my vein security (locks/cameras) so the security tier is degraded until I pay to repair it, so that the Firm's pressure feels physical.
47. As a player, I want Collective harassment to be vandalism, council noise complaints (e.g. a temporary ban on evening work at a vein) and hearings, so that the Collective is hostile in a neighbourly, bureaucratic way.
48. As a player, I want Conclave harassment to be legal — planning notices, injunctions freezing a vein, hearings that cost a block or a fine — so that the Conclave hurts through the system.
49. As a player, I want Guild harassment to decertify my batches (lower crafted-item sell prices) and bar me from their shop, so that the Guild hits my craft economy.
50. As a player, I want Network harassment to spread rumours (lower sell prices) and leak intel on me to others, so that information works against me.
51. As a player, I want the Collective and the Guild to have much lower raid thresholds than the others, so that they harass for a long time before ever raiding.

### Grudges and non-violent pressure
52. As a player who has been raided, I want a "score to settle" grudge marker against the raider, so that I'm prompted to respond.
53. As a player, I want answering a grudge within a window to give bonus odds on the site they took and a reputation gain, so that revenge is rewarded.
54. As a player, I want unanswered grudges to make me look soft (a small pressure increase from every faction), so that passivity has a cost.
55. As a player, I want raising security on the raided district's veins to count as answering, so that a defensive player isn't forced into violence.
56. As a player, I want my own non-violent pressure moves against a faction (file complaints, tip off police, leak to the Ticker) costing £ or blocks and gated by intel, so that I can fight back without raiding.
57. As a player, I want non-violent moves to count as answering a grudge, so that every play style can clear it.

### Warmonger and alliances
58. As a player, I want a warmonger meter tracking my violent hostile acts over a rolling window, so that sustained aggression is tracked.
59. As a player, I want non-violent pressure to not count towards the warmonger meter, so that bureaucratic warfare stays a lower-temperature option.
60. As a player with a high warmonger meter, I want other factions to grow more pressured against me and friendlier with each other, so that London closes ranks against a menace.
61. As a player at the top of the warmonger meter, I want factions to coordinate against me (joint raids, shared intel), so that unchecked aggression becomes dangerous.
62. As a player at war, I want to ask another faction to join my war, so that alliances matter in conflict.
63. As a player, I want the chance they accept to depend on my relation with them, their relation with my enemy, their weariness and my warmonger meter, so that being a good partner pays off.
64. As a player whose ally joined my war, I want to owe them a favour, so that aid has a price.

### Ambush squads
65. As a player hostile with a faction, I want to face ambushes by that faction's own enemy squad, so that each faction's enforcers feel distinct.
66. As a player, I want ambush odds when I act in a district to depend on who controls it and how hostile they are to me, so that tending a vein in hostile turf is risky.
67. As a player, I want low or no ambush risk in friendly or my own turf, so that safe ground feels safe.
68. As a player, I want ambushes to use the existing squad combat, so that they play like real fights.

### Favours and incidents
69. As a player, I want each faction to offer its own favour kinds on top of the shared four, so that working for different factions feels different.
70. As a player, I want favours to be authored event cards with premise variants, mid-favour complications and branching chance-based options, so that repeating a favour kind doesn't repeat the experience.
71. As a player, I want favour outcomes to move my relation with the asker, their rivals, and my personal relation with the asking member, so that how I handle a favour matters.
72. As a player, I want dilemma favours that harm a third faction, so that I have to pick sides.
73. As a player, I want sim-triggered incidents (revenge offer after a raid, both sides courting me in a war, truce renewal, turf flip fallout) that can span several cards, so that the simulation produces stories.

### Key members
74. As a player, I want each faction to have two key members, a Speaker and a Lieutenant with opposing hawk/dove outlooks, so that factions have internal politics.
75. As a player, I want a personal relation with each key member separate from the faction relation, so that I can be friends with a person inside a hostile faction.
76. As a player, I want each key member to have a personal want with a short questline, so that I can earn a member's trust personally.
77. As a player, I want my favours and quests for a member to raise their hidden standing in the faction, so that I can influence who leads it.
78. As a player, I want a succession event when standing tips, changing the faction's leader, aggression and baseline relation with me, so that backing the right person reshapes a faction.
79. As a player with a close member in a hostile faction, I want them to act as an inside man (warnings, intel, back-channel truce, quiet discounts), so that personal relationships cut across faction lines.
80. As a player, I want a very close member of a weak or losing faction to be able to defect to me, bringing a vein, recipe or know-how, so that people are prizes too.
81. As a player, I want a neglected member to be able to betray me (raid timing, stockpile location), so that relationships need upkeep.
82. As a player of the Collective arc, I want Act 3 to turn on whether Nadia or Des leads the Collective, so that the first faction I meet shows off the leadership system.

### Storylines and vulture window (deferred)
83. As the designer, I want the For/Against storyline structure written up as a draft for my review, so that nothing is built until I'm convinced.
84. As the designer, I want the vulture window split into its own simulation-tested effort, so that no faction gets wiped out by accident.

### Data and saves
85. As a player with an existing save, I want turf, warmonger, grudges and member standing backfilled on load, so that my save keeps working.
86. As a player, I want all new state to survive save, load and Rewind, so that the flagship feature keeps working.

## Implementation Decisions

### General
- Respect the one-way architecture: all new numbers and strings in data JSON; all new state is pure data on `GameState.state`; new logic in static-func systems; screens only read state and call systems.
- All harassment, favour, incident and ambush-intro prose is authored by the human as event cards. Agents build systems, data schema, event actions and at most one clearly marked placeholder card per hook for tests (`PROSE-REVIEW`), never final content.
- Every new number is a data field marked **TBD** in REFERENCE.md until the tuning pass pins it.

### Turf (new system)
- New `Turf` system with pure queries: per-district contender vein counts and shares, controller, tier for a contender in a district (`control` / `foothold` / `none`), and contested status.
- Contenders: the five factions and the player. Count = faction veins on sites in the district, player veins in the district.
- **Control rule:** the top contender controls iff its count ≥ second-place count + `controlMargin` (2). Otherwise the district is contested.
- **Foothold rule:** a non-controller whose share of the district's claimed veins ≥ `footholdShare` (**TBD**, ~25%). Share = contender veins / all claimed veins in the district.
- Stored result recomputed once per daily tick (a new step after claims, raids, rivalry and transfers resolve), kept as `state.turf = { districtId: { controller, shares, tiers } }`, so the panel and the map read a stable value. Flips detected against the previous stored value queue a Ticker headline and a map event.
- The district heritage field `factionPresence` stays in `districts.json` but is now used only to seed starting turf and stockpile home districts. The claim roll's `presence` weight now applies to the live controller (heritage weight dropped). Pressure's `homeVeins` uses live controlled districts.
- **District modifier shift:** effective danger and price mods = district base + controller-relation adjustment (per relation band, **TBD** table), halved at foothold strength. Exposed as one query used by all existing readers of `dangerMod`/`priceMod`.
- **Player control:** danger reduction and a raid-odds penalty against player veins there (**TBD**); every faction gets a pressure term per player-controlled district (**TBD** weight in `factionPressure.weights`).
- **Data changes:** Soho gets a non-zero `siteCap` (**TBD**), an `oreBias` towards emotion and time, and an empty `factionPresence`; its marketplace role is unchanged. Hampstead's `siteCap` is raised (**TBD**, ~5–6). Map layout must give both enough stop slots (≥ `siteCap × 2`, M1.5 rule). VISION §13's "Soho: no veins" is amended.

### Map and district panel
- Zone fill reads the stored controller instead of the static presence: controller colour at full fill alpha, foothold not drawn, contested gets a neutral/striped treatment, player control uses the player line colour. Must hold the dark-map contrast rules (M1.5).
- The district panel gains a Turf section: contender shares (%), control tier, flip margin, the player's active benefits and modifiers in that district (each with its source faction), and active harassment/penalties.
- Tapping a faction in that section opens a per-faction preview: the player's current tier and the perks at every tier, marking which are turf-scoped. Backed by a pure decision layer (like the existing district bubble layer) so it is testable headless.

### Perks (new system)
- `data/faction_perks.json`: per faction, three tiers (`friendly`, `partner`, `sworn`), each with perk entries `{ id, scope: global|turf, effect params, label, description }` (labels/descriptions `PROSE-REVIEW`).
- Tier mapping: Friendly and Partner from the player's stance/relation band with the faction; Sworn = joined. **TBD:** exact relation cut for Friendly.
- One query layer: active perks for the player (global), active perks applying to a given vein/district (turf, scaled by control/foothold), and the full per-tier list for the preview. Every effect hook reads from it; no effect is hard-coded per faction elsewhere.
- Effect hooks (into existing systems):
  - Collective: Neighbourhood watch → raid-odds reduction on turf veins; Partner tending → a daily tend on skipped turf veins (reuses the existing tend path); Sworn whip-round → a one-off bailout before a forced home downgrade.
  - Firm: protection racket → a weekly fee charged with the Monday bills, Firm raid rung suppressed, deterrence term on other factions' raid odds; Partner muscle → raid-odds bonus plus a combat ally on player raids; Sworn → Firm-controlled districts treated as player-controlled for danger.
  - Guild: Friendly → craft XP multiplier; Partner internship → free bonus cultivation actions and one bonus craft attempt per day for turf veins (both: **TBD** quantities); Sworn → commission-crafting offers through the existing offers/contracts path.
  - Network: Friendly → daily intel gain on one player-chosen faction; Partner → raid forewarnings from all factions (reuses the partner warning path); Sworn → player-commissioned Network market move (sellIntel/priceGouge/disinformation) against a chosen target.
  - Conclave: Friendly → danger reduction in Conclave turf; Partner → one-time recovery of a raid-lost vein; Sworn → a barometer nudge action and the Deep Vein lore flag.
- **Removed:** the generic Partner price favour and passive `defenceHelp`/`raidHelp`. Partner trouble asks and warnings stay (they are favours and the Network perk respectively). REFERENCE.md §3.10 "Partners" updated.

### Harassment (escalation extension)
- New escalation rung `harass` between warning and market lines. Per-faction `harassAboveRaid` offset (**TBD**) in `factionEscalation`.
- `menus` gains `harass: [harassmentId]` per faction. A harassment entry in data = `{ id, factionId, eventId, cost, target: vein|player, requires }`; picking one queues the authored event, targeting one of the player's veins in that faction's turf (control or foothold). With no eligible vein, the move is skipped.
- Harassment respects the existing cooldown, warn-first and one-move-per-target rules.
- Persistent harassment effects live in state as `state.harassment.active = [{ id, factionId, veinId?, kind, params, sinceDay, untilDay?, escalation }]`. Ignored effects increase `escalation` per day or week (**TBD**).
- New event actions for authored cards (registered in the Events action runner and the action whitelist), e.g.: degrade a vein's security tier until repaired, mark a repair, apply/clear a vein work ban for a block of the day, freeze a vein (injunction), apply a sell-price penalty for item or ore classes, bar from a faction shop, raise every faction's intel on the player, fine, spend a time block (hearing). The exact action list is settled in the first harassment ticket and documented in REFERENCE.md §3.9a-adjacent.
- **Raid thresholds:** the Collective and Guild `raidThreshold`/`conquerThreshold` move much lower (**TBD**, ~−60 / −50). Their market/warning lines move with them via the existing offsets.

### Grudges and player non-violent moves
- A successful faction raid on the player (vein, stockpile, shortfall steal) records `state.grudges[factionId] = { sinceDay, siteId?, district }`.
- **Answered** by any of: a player raid on that faction, a security upgrade on a vein in the grudge district, or a player non-violent move against that faction within `grudgeWindowDays` (**TBD**). Answering gives a raid-odds bonus on the lost site (**TBD**) and a reputation gain.
- **Looks soft:** each unanswered expired grudge adds a decaying pressure term against the player for every faction (**TBD**).
- **Player non-violent moves** (new, in Diplomacy or a sibling system): file complaint, police tip-off, Ticker leak. Each costs £ and/or a block and is gated by an intel level on the target. Effects reuse faction-side harassment effects where possible (e.g. a security freeze on a target vein, a price penalty on its goods, a Ticker push). They count as hostile acts for relation and the Truce break rule, but not for warmonger.

### Warmonger and call for aid
- `state.warmonger = { score, log }`: a rolling sum of violent hostile acts (raids, stockpile raids, ambush-initiated fights won as aggressor) over `warmonger.windowDays` (**TBD**), weights per act (**TBD**).
- Thresholds: above `coalitionAt`, add a pressure term against the player for all factions and a daily pair-relation drift upward among the factions not at war with the player; above `coordinateAt`, factions share intel on the player and may queue joint raids (two factions' raid moves on the same day get an odds bonus) — **TBD** values.
- **Call for aid:** `Diplomacy.ask_aid(factionId, enemyId)`. Accept chance from player relation, the asked faction's pair relation with the enemy, its weariness, and the warmonger score (**TBD** formula). Accepted: the faction enters war with the enemy (existing war rules), and the player gets an owed-favour entry; refusing that owed favour later costs relation. Cooldown per faction.

### Ambush squads
- Per-faction squad definitions in the enemies data: `factionSquads = { factionId: [{ weight, enemies: [...] }] }` built on the existing squad combat model (REFERENCE §3.7a).
- `Turf.ambush_chance(district)`: from the controller's (and foothold factions') relation with the player — zero at or above a relation line, rising with hostility, scaled by control vs foothold (**TBD**).
- Rolled from the existing district action hook when the player spends a block acting in a district (tend, prune, prospect, seed, etc.). On a hit, an authored ambush intro event fires with a new event action that starts a faction-ambush combat using that faction's squad. Outcomes feed grudge, warmonger (only if the player initiates) and relation the same way as other fights.

### Favours and incidents
- `sampleFavours` gains faction-specific kinds alongside the shared four. A favour entry can point to an `eventId` for its authored multi-card flow; the existing accept/settle/fail tracking stays the outcome ledger, settled from event actions (`favour_kept`, `favour_failed`, with relation, rival-relation and personal-relation deltas as action params).
- Branches and chance options use the existing event choice-check system (REFERENCE §3.9a); no new event-engine features unless a ticket proves one is needed.
- **Incidents:** a data table `faction_incidents.json` of `{ id, trigger, eventId, cooldownDays, conditions }`. Triggers fired from the daily tick: `raidedByFaction`, `warBetween` (both sides court the player), `truceExpiring`, `turfFlip`. Each queues its event (multi-card allowed). The trigger list is extensible.

### Key members
- `keyMembers` per faction gains a second member: roles `speaker` and `lieutenant`, each with `outlook: hawk|dove`, a `want` (questline id), and an `aggressionMult`/`relationBaseline` used when they lead. Collective: Nadia and Des are the leadership contenders; Hakim stays a non-contender member. New member names, wants and intros for the other four are human-authored (`PROSE-REVIEW` placeholders only).
- State per member: personal relation (existing contact `relation`), `standing` (0–100, hidden), and per faction a `leader` id.
- Standing moves from: favours kept for that member, their personal questline steps, player actions matching their outlook (aggression helps hawks, peace deals help doves), and faction outcomes (losing a war hurts the leader). **TBD** weights.
- **Succession:** when the non-leader's standing exceeds the leader's by `successionMargin` (**TBD**) for N days, a succession incident fires (authored event) and the leader changes; the faction's effective `aggressionPersonality` and pull-back relation baseline become the new leader's. The Speaker role (who messages the player) follows the leader.
- **Inside man:** personal relation ≥ `insideManAt` (**TBD**) while the faction relation is in or below the Annoyed band → that member sends warnings of their own faction's planned moves (reusing the partner warning plumbing), offers a back-channel truce negotiation, and gives a shop discount.
- **Defection:** personal relation ≥ `defectAt` and the faction is weak or at war with the player and losing → a defection incident; on acceptance the member becomes a player contact and brings one of a vein, recipe or skill boost (**TBD** per member), and the faction takes a relation hit and loses one perk tier effect or `craftSkill`.
- **Betrayal:** personal relation ≤ `betrayAt` → the member may leak the player's stockpile location or raid timing to a rival (raises that rival's intel on the player).
- **Collective Act 3** is reworked so its futures route through the Nadia/Des leadership contest. That rework is a separate content ticket with the human; the plan doc gets an amendment, not a rewrite by an agent.

### Storylines (D1) — review draft only
- Write `.scratch/faction-relations/d1-storylines-draft.md` covering: For track (chapters at relation thresholds, branched, unique reward, final chapter = invitation to join), Against track (offered by a patron from a rival faction, escalating spy → sabotage → expose/decapitate, rewards = lasting weakening of the target plus patron pay), lock rules (joining locks rival For tracks at chapter 2; Against tracks stay open), chapter count (3 vs 2), and the open question **fixed vs dynamic patron**. Status `needs-info` until the human approves. No D1 code or content until then.

### Vulture window — split out
- Its own spec/effort, with simulation tests first (faction-economy sim script) proving no faction can be eliminated. Not built here.

### Save and docs
- `SaveManager` backfill for `turf`, `harassment`, `grudges`, `warmonger`, key member `standing`/`leader`, and new key members, defaulting to a neutral state; turf is computed on load.
- REFERENCE.md: new §§ for Turf, Perks, Harassment, Grudges, Warmonger/aid, Ambush; amend §1.8 (thresholds, keyMembers, sampleFavours), §1.11 (escalation, partners), §3.1 daily tick order, §3.10 Partners. CONTEXT.md: add Turf, Control, Foothold, Contested, Harassment, Grudge, Warmonger, Standing, Leader. CODEMAP rows for new systems/data files.

## Testing Decisions

- A good test drives the public surface and checks observable state — counts, tiers, queued events, relation/pressure values, combat start — never private helpers or call order. Seed RNG through the existing `Rng` so chance rolls are deterministic.
- **Seams (agreed with the human):**
  1. `Turf` queries plus the daily recompute in the tick: build a state with given vein distributions and assert controller/tier/share/contested and flip headlines.
  2. The Perks query: active perks per vein/district/faction and the per-tier preview list; effect hooks checked via their own existing systems' public functions (raid odds, tend, craft XP, Monday bills).
  3. The faction AI escalation step: harassment/favour/incident moves queue the data-defined event; new event actions tested through the Events action runner.
  4. The ambush-chance function, plus the district action hook starting a faction-squad combat.
  5. Warmonger and call-for-aid via FactionAI pressure and Diplomacy.
  6. KeyMembers standing/succession step.
  7. Whole-game balance via the existing faction-economy sim script: turf spread over time, no faction reduced to zero turf permanently, no runaway snowball.
- Pure decision layer for the district panel turf section and faction preview (headless-testable), following the district bubble prior art.
- **Prior art:** `test_factions`, `test_faction_ai`, `test_faction_sim`, `test_faction_war`, `test_partners`, `test_diplomacy`, `test_intel`, `test_raiding`, `test_district_bubble`, `test_map_palette`/`test_map_style` (zone fills), `test_combat` (squad start), and `scripts/sim_faction_economy.gd`.
- Respect the suite-health notes: one targeted run per change, one full suite and `check_all.sh` at the end.

## Out of Scope

- All final prose: harassment, favour, incident, ambush and succession cards; key member names, wants and intros for the Firm, Guild, Network and Conclave. Human-authored.
- D1 storylines beyond the review draft.
- Vulture window (buyouts and carve-ups of weak factions).
- Collective Act 3 content rewrite (system hooks only here).
- Final tuning of every **TBD** number (later sim plus human pass).
- Faction-to-faction harassment (harassment only targets the player in this spec).
- Pixel art for faction squads (use existing enemy art or placeholders).

## Further Notes

- **Snowball risk:** live-control claim weighting plus turf-scoped perks reinforce whoever leads. The sim pass must check that turf changes hands over a long run and that the weakening floor still holds.
- **Partner benefit removal** is a player-facing nerf for existing saves at Partner stance; the perk tiers must land in the same release.
- **Collective identity:** the Collective harasses rather than raids in practice (very low raid threshold). Whether it still raids other factions is unchanged by this spec.
- **Ticket order suggestion:** Turf core → map fill and panel → Perks → harassment rung and actions → grudges and non-violent moves → ambush → warmonger/aid → favour/incident hooks → key members/succession → D1 draft → balance sim pass.
