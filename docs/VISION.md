# VEIN
## Game Vision & Development Plan — v1.1
*July 2026 — supersedes v1.0 and the React Native handoff doc*
*v1.1 changes: tone rebalanced (Jacka × Adams, 50/50 menace/comedy); ancient-world spine (Critias canon, Conclave identity); hybrid progression system (§3b, Fieldcraft, threat tiers, squad combat).*

---

# PART ONE — THE VISION

## 1. One-Paragraph Pitch

**Vein** is a mobile-first economy game about running an underground magical resource operation in contemporary London. Orichalchum — a magical ore in five types — occurs naturally beneath the city's streets, and nobody finds this as remarkable as they should. The player prospects districts, seeds and cultivates veins, crafts consumables and devices, dodges muggers, raiders and rival factions, and climbs from a Brick Lane bedsit to controlling the trade — all through a stylish, text-forward, menu-driven interface layered over a hand-drawn map of London. The player grows from someone a mugging could kill into the operator mercenaries get warned about — not by levelling up, but by getting rich, prepared, and known. Beneath it all runs something older: orichalchum is the metal of Plato's *Critias*, and London was built where it was for a reason. Tone: Benedict Jacka's London (Alex Verus, Inheritance of Magic) narrated with Douglas Adams' dryness — real menace, coping humour, ancient secrets kept via filing.

## 2. Design Pillars

Every feature decision gets tested against these four, in priority order. With the feature list growing, the pillars are now the scope filter — anything that fails them waits for post-1.0.

1. **The Business Is the Game.** Every system feeds the economy loop: prospect → seed → cultivate → prune → craft → sell → upgrade. Combat, story, and exploration exist to make the economy tastier, never to compete with it. If a feature doesn't create an economic decision, it doesn't ship.
2. **London Is a Place, Not a Label — and an Old One.** The map is the connective tissue. Veins have addresses, districts have character and ore biases, travel costs time, so geography creates routing decisions. The player should develop opinions about Camden. And the past is under the pavement: the trade predates the Tube, the Romans, and possibly the Thames — ancient secrets surface through prospecting oddities, Conclave ledgers, and the fact that there is genuinely a Temple of Mithras under a bank's headquarters.
3. **Everything Is Priced.** Time blocks, cash, ore, relations, information, even your own biology (affinities) — all currencies, all scarce. Violence has an invoice: every fight opens with pay, talk, or intimidate. The mugger has an hourly rate.
4. **Menace and Comedy, Equal Partners.** Danger is sincere — violence has consequences, and the player should sometimes be genuinely worried. The humour is dry, observational coping, never whimsy: the narrator jokes the way Londoners joke at a delayed funeral. Magic is a mundane trade commodity with VAT implications; the people enforcing its oldest rules are quietly terrifying. If a line winks at the camera, it dies; if a threat can't hurt you, it doesn't ship.

## 3. Player Fantasy & Core Loops

**The fantasy:** a small-time operator becoming a kingpin in a trade nobody admits exists. Ranked priorities: (1) running the business, (2) discovering hidden London, (3) tactical use of crafted consumables, (4) story and characters.

- **Session loop (5–15 min):** check notifications → spend the day's 3 time blocks (travel, cultivate, prune, craft, prospect, trade, socialise) → handle the day's event or threat → end day → daily tick (costs, vein drift, raids, barometer, market refresh).
- **Mid loop (hours):** level veins and skills, discover recipes and combinations, upgrade home, build faction relations, expand districts, build devices.
- **Macro loop (full game):** bedsit → mansion; one borrowed vein → a district-spanning operation; nobody → the person the factions call first. Culminates in the Deep Vein endgame (§15). Threaded through all of it: the growth arc (§3b).

## 3b. Progression: Prey → Operator → Problem

The player must *feel* the climb from "can I survive this mugging?" to "a squad of trained mercenaries? Yeah, I can take them." That feeling is delivered as a hybrid: **mostly preparation, lightly stats** — because pillar 1 says power is something you buy, build, learn, and know, not a number that inflates.

**Preparation (~70% of power):**
- **Arsenal** — consumables and devices are the real power curve; a coat full of answers (§10) beats any stat.
- **Equipment** — weapons and wearables raise attack, defence, and negotiation presence.
- **Allies** — recruited muscle joins fights as intent-cancellers; a faction at your back changes openers before a word is said.
- **Information** — enemy affinity profiles, site intel, outcome previews. Knowing the enforcer is emotion-resistant *is* damage.
- **Reputation** — fights avoided are fights won; at high rep, low-tier threats simply don't initiate.

**Light stats (~30% of power):**
- **Fieldcraft** — a third skill alongside crafting and cultivating. XP from combat, negotiation, and escapes. Grants small permanent bonuses to hit, evade, and intimidate, and unlocks combat maneuvers at level thresholds (e.g. *Read* — peek two intents ahead; *Press* — bonus damage vs Braced enemies). Bonuses capped in ±15% territory — never doubling curves.
- **Conditioning** — max HP grows modestly via the home gym and life-regimen items. A late-game player is tougher, not spongy.
- **Reputation (0–100)** — the stat that is also a story (§11).

**Threat tiers — enemies scale with geography and visibility, never with player level:**

| Tier | Examples | When they appear |
|---|---|---|
| T1 | muggers, chancers | always, in dangerous districts |
| T2 | organised thieves, junkie crews | when you visibly carry value |
| T3 | faction enforcers | faction friction, vein raids |
| T4 | professional crews, duo fights | mid-game, contested districts |
| T5 | mercenary squads, Conclave agents | endgame chain |

Because enemies never scale *to* the player, early threats stay objectively weak — which is what makes growth legible. **The Mugging Revisited** (scripted callback, M6): the opening-beat mugging recurs late-game, and the player feels exactly how far they've come — talk him down on reputation alone, scare him off with a look, or dismantle him in one telegraphed turn. He remembers you. You barely remember him.

## 4. Platform & Commercial Strategy

- **Engine: Godot 4.x.** One codebase → Android, iOS, Steam (Win/Mac/Linux), web (demo/playtests).
- **Primary target: mobile, portrait, one-handed.** All UI at 390px-equivalent first. Steam build is the same game in a phone-proportioned window or two-column desktop layout — decide at M7, design for it never earlier.
- **Monetisation recommendation: premium, everywhere.** An economy game with IAP reads pay-to-win and poisons the design. Suggested: mobile £4–6, Steam £10–12. Free web demo through the home-raid tutorial beat as marketing. **Decision gate: Milestone 7.**
- The React Native plan is dead; the prototype's architectural discipline ports to Godot nearly 1:1 (§17).

---

# PART TWO — THE DESIGN

## 5. Orichalchum: The Five Types

Final roster (replaces the old time/energy/life/void/motion set — **void is dropped**, energy and motion merge into **physics**):

| Type | Domain | Personality |
|---|---|---|
| **Time** | duration, sequence, foresight | The connoisseur's ore. Expensive, dangerous, Greenwich smells of it. |
| **Physics** | force, momentum, mass | Blunt-instrument ore. Blasts, shields, and one deeply irresponsible black-hole application. |
| **Life** | biology, healing, enhancement | The respectable face of the trade. GPs would prescribe it if they could invoice it. |
| **Fate** | probability, fortune | Statistically inadvisable. The City runs on it and calls it "alpha". |
| **Emotion** | mood, crowd psychology | The one everyone pretends not to buy. Soaked into Whitechapel's brick. |

Each type keeps: `name`, `symbol`, `colour`, `flavorText`, `basePrice`. **Migration:** `energy` + `motion` → `physics`; `void` removed (black hole re-homed under physics); old `motionPowder` becomes Enhancement Powder (speed variant).

**Canon note:** orichalchum is the metal of Plato's *Critias* — the Atlantean alloy, second in value only to gold, described in the one dialogue Plato conspicuously never finished. This is not flavour; it is the endgame's spine (§15), the Conclave's founding charter (§14), and the reason James will not shut up about Plato.

### 5b. Affinities — fixed at birth

At new game the player gets an **affinity profile**: a stance on each of the 5 types, chosen from preset profiles or randomly rolled ("see what the midwife says").

| Stance | Effect |
|---|---|
| **Attuned** | +10% crafting success with this type; effects of this type on you amplified ~+25%; devices using it cost −10% ore fuel. |
| **Neutral** | Baseline. |
| **Resistant** | Effects of this type on you dampened ~−50% — hostile *and* beneficial, always both ways. Emotion-resistant shrugs off Pan's Prank; time-resistant gets less from Time Pearls but laughs at enemy time tricks. |
| **Allergic** | Cannot consume this type; direct effects deal damage instead. Cultivating and selling it is fine — you just can't *use* it. |

Default profile shape: 1 Attuned, 1 Resistant, 3 Neutral. Allergy appears only via random roll (rare, compensated with bonus starting cash) — and canonically explains **Archie**, who is time-allergic, which is why he's been sitting on a time vein he can't touch since the tutorial. **NPCs and enemies have profiles too**, discoverable via relation or intel — a tactical layer ("don't waste Pan's Prank on the Conclave enforcer, she's emotion-resistant").

Implementation: one `affinities: {time:'neutral', ...}` object on `player` (and on NPC/enemy templates), read by crafting success, effect resolution, and device fuel functions.

## 6. World Structure: Districts & the Map

London divides into **9 districts** on one stylised hand-drawn map — an occult A-Z, ink on paper, amber vein-glow beneath the streets. One illustration + icon set = the entire exploration art budget. Commission it early (M1); it's the game's face.

| District | Ore bias | Character |
|---|---|---|
| **Shoreditch** | balanced | Home base. Starting bedsit, Archie's turf, the Wetherspoons. |
| **The City** | fate | Institutionalised gambling with better tailoring. Best prices, worst people. |
| **Greenwich** | time | The meridian runs through it. Nobody at the Observatory has noticed. |
| **Camden** | physics | Loud, kinetic, high mugging rate, cheap sites. |
| **King's Cross** | time / physics | Transit hub. Extra drift district-wide (the vigour bonus, for free). |
| **Battersea** | physics | The power station hums at a frequency estate agents don't mention. |
| **Hampstead** | life | The Heath is basically a life-ore farm with dog walkers. |
| **Whitechapel** | emotion | Old grief soaked into the brick. Rich sites, high raid risk. |
| **Soho** | — | The **marketplace** district (§13). Buyers, faction fronts, premium prices, no veins. |

**`DISTRICTS` table:** `oreBias`, `siteQualityMod`, `dangerMod`, `priceMod`, `siteCap`, `flavor[]`, `factionPresence`.

### Travel — one rule

**Acting in a district you're not currently in costs +1 time block** (the travel), then the action costs its normal block. You always wake at home; returning to rest is free. That single rule generates the daily routing puzzle — *"prune Greenwich then trek to Camden, or stay east and craft?"* — with no pathfinding, no adjacency graph, no travel screen. Barometer states and faction control render visibly on the map (police icons, market stalls, faction tags).

## 7. Prospecting & Sites

Seeding no longer happens into thin air. Pipeline: **prospect a district → discover a site → seed the site → the site's hospitability becomes the vein's permanent terroir.**

**Prospecting:** 1 time block (plus travel). Rolls a site whose tier is weighted by district `siteQualityMod` and **cultivating skill** (that skill's second job). The site appears on the map.

```js
SITE = { id, district, tier, oreBias, discoveredDay, claimed: false }
```

| Tier | Seed success | Permanent vein bonuses | Notes |
|---|---|---|---|
| **Barren** | — | — | Can't seed. "It's a Pret." |
| **Poor** | −15% | none | Cheap fallback. |
| **Fair** | baseline | none | Current-game equivalent. |
| **Rich** | +20% | ONE of: vigour (+1 rightward/−1 leftward drift) · wildCeiling (+20 growth ceiling) · +15% yield | Bonus rolled at discovery, visible before seeding. |
| **Saturated** | +35% | ALL THREE | ~5% of Saturated discoveries contain a **natural vein at `growth = seedGrowth`**, free and already alive. |

**Pressure valves:** unclaimed sites can be NPC-claimed in the daily tick (chance scales with quality and age); each district caps concurrent sites (2–4); prospecting a full district re-rolls its worst unclaimed site. Site quality is visible *before* paying the 40-ore seed cost — prospecting is buying information, which is the point.

**Vein object change:** add `hospitability: {tier, bonuses[]}`, read as modifiers by the existing seed/cultivate/prune/drift functions.

## 8. Veins, Cultivating & Raids

Core loop unchanged (it works): seed → cultivate to push growth up → prune (light or hard) to pull calc out → left alone, growth drifts back toward whichever wall it was leaning on, and a vein spent to 0 for too long can collapse and vanish (vein-growth-state PRD). Additions:

- Veins live at **sites** with map positions and district-derived properties; drift rate modified by hospitability and district.
- **A tutorial event teaching cultivation** joins the tutorial chain — slotted right after the Archie falafel chat, using Archie's transferred time vein as the teaching prop.
- **NPC raids on player veins** (M2): daily roll per vein vs its security tier; success steals stored ore proportional to security resistance and pings a map notification. This creates the demand side of vein-security spending.
- **Home raids** (exists; formalised M2): daily roll vs home tier + installed security; raiders trigger the intent-combat system; losses hit `storedOre`, mitigated by safeRoom/storage rooms.
- **Passive cultivating** (M5): a recruited contact assigned to the `veinStation` room auto-spends blocks on your lowest-dev vein.

## 9. Crafting, Discovery & Devices

### 9a. Recipes & combination crafting

Recipes now span **single-type** and **combination** (two-type) crafts. Combinations require both ore types in stock and a higher skill floor, and they're where the most interesting effects live (Healing Burst, Failsafe). Each recipe keeps: ore cost(s), base success %, skill scaling, effect definition.

**Discovery** replaces "recipes appear when taught" as the only channel. Three routes:
1. **Taught** — James scenes, faction storyline rewards (guaranteed, story-paced).
2. **Experimentation** — the crafting screen gains a *Discover* action: pick a type (or a type-pair), spend ore + a time block, roll vs crafting skill for a hint or a full unlock. Failed experiments produce flavour text and occasionally Minor Incidents.
3. **Bought** — recipe fragments in the Soho marketplace, priced painfully.

**Crafting menu UI:** a horizontal row of the 5 type icons; selecting a type lists your unlocked recipes for it; **between each pair of adjacent icons sits a link icon** — selecting a link shows recipes requiring both types (drag one icon onto another as the gesture alternative). Undiscovered-but-hinted recipes show as silhouettes with their ore cost visible, discovered ones in full. This UI ships in M3 and gets a dedicated usability pass — it is the game's most novel interface element and must be tested on-device early.

### 9b. Devices

**Devices** are crafted permanent tools that consume orichalchum as fuel per use (or per day, for passive ones). They require high crafting skill to build; **higher skill = stronger effect and lower fuel cost** (skill re-checked at build time and baked into the device instance). Player affinity to the fuel type further modifies fuel cost.

```js
DEVICE = { id, type, fuelType, fuelPerUse, effectPower, builtAtSkill, condition }
```

Launch set (M3, player tools):
| Device | Fuel | Effect |
|---|---|---|
| **Assay Glass** | fate | Reveals a district's best undiscovered site tier before prospecting. Information, priced. |
| **Ward Stone** | physics | Passive home security device; daily fuel drain, big raid-chance reduction. Stacks with security upgrades. |
| **Cultivator's Still** | life | Passive: +1 dev-bar tick to one chosen vein per day. |
| **Ocular Lathe** (cataract healer) | life | The flagship civilian device. Player-use: cures a rare "strained eyes" debuff. Its real purpose arrives in M5. |

**Phase 2 (M5): the device market.** Contacts and faction fronts start commissioning devices for civilians — the cataract healer, joint menders, insomnia boxes. Fixed-price commissions like James jobs but higher-margin, gated on crafting skill 4+, with a reputational wrinkle: selling magical medical devices to the public draws faction attention and barometer consequences. A whole income lane that is also a story lane.

## 10. Consumables & Effects Catalogue (1.0 target)

Every consumable answers a question combat or an event asks — that's the design rubric. Affinities modify all self-targeted magnitudes.

| Item | Type(s) | Combat effect | Event/world effect | Notes |
|---|---|---|---|---|
| **Time Pearl** | time | Freeze enemy 1–3 turns | — | Existing; counters *Heavy*. |
| **Enhancement Powder** | life | Strength: +damage. Speed: extra attack/turn, +flee | Speed: beat foot-chase checks | Replaces motionPowder; counters *Grab* (kill it before it lands). |
| **Blast** | physics | Direct kinetic damage, **ignores Brace** | Open a locked thing, loudly | The subtlety-free option. |
| **Shield** | physics | Absorbs next 1–2 incoming hits; negates *Heavy*/*Grab* contact | Survive one Bad Outcome card | Momentum simply declines to arrive. |
| **Healing Salve** | life | — | Faster overnight HP recovery | Out-of-combat regen. |
| **Healing Burst** | time + life | In-combat heal (accelerated recovery) | Clear light-wound debuffs instantly | First combination recipe; faster than salve because time does the queuing. |
| **Prophet's Breath** | time | +evade 1–2 turns (sees the punch coming) | Previews one choice's outcome hint | Inhaler. Introduces the evade stat. |
| **Pan's Prank** | emotion | Choose: *Panic* (forces enemy Bolt), *Rage* (enemy attacks recklessly, −accuracy), *Confidence* (self: +negotiation) | Shifts an event NPC's disposition | Skill scales how many targets. Mass versions are endgame/barometer material. |
| **Luck Be a Lady** | fate | One turn: guaranteed max damage, +hit, +evade | Massively boosts one check/decision | Fate, made briefly reliable. |
| **Black Hole** | physics | Heavy AoE, pulls enemies in — cancels *Bolt* and *Call* | Do not use indoors | High skill. HR would call it a violation. |
| **Rewind** | time | **Undo 1–2 combat turns**; +evade for 1–2 turns after | **Rewind one event card** | Hourglass. Only the user remembers. Very expensive; requires snapshot engine (§17). |
| **Failsafe** | time + life | On death: auto-rewind 1–2 turns | On event death: restart the event | Passive while carried. Endgame craft; insurance, in the most literal sense London has ever produced. |

## 11. Combat 2.0 — Negotiation + Intents

Menu-based, turn-based, short (3–6 turns), rare. A spice. Two layers:

### Layer 1 — The Opener (negotiation)

Every hostile encounter starts at a standoff:

| Option | Cost / check | Success | Failure |
|---|---|---|---|
| **Talk** | free; vs `reputation` + relevant faction relation | Walk away; sometimes info or relation | Enemy demands a bribe or attacks with first strike |
| **Bribe** | cash; threshold = enemy `greed` × what you're visibly carrying | Walk away, cash gone | Takes the money *and* attacks (rare, low-`nerve` enemies only) |
| **Intimidate** | attack range + weapon + `reputation` vs enemy `nerve` | Enemy flees; +reputation | Enemy attacks enraged (+damage) |
| **Fight** | — | → Layer 2 | — |

Items hook the opener: *Confidence* Pan's Prank buffs Talk/Intimidate; Luck Be a Lady can carry a doomed bluff.

**New stat: `reputation` (0–100)** — earned by wins, faction work, successful intimidation; decays slowly; feeds openers and faction storylines. One integer, big mileage.

### Layer 2 — Intent-Telegraph Combat

Each enemy turn shows its **next move** as an icon + one dry line; the player's turn is about answering it. Consumables become *answers*, not stat food — which is how combat feeds the economy.

| Intent | Effect next turn | Best answers |
|---|---|---|
| **Swing** | normal attack | attack through it |
| **Heavy** | 2–2.5× damage, telegraphed | Time Pearl, Shield, or accept and race |
| **Grab** | on hit, steals ore/cash mid-fight | Speed Powder burst, Shield |
| **Brace** | halves incoming damage | don't waste big hits — Blast ignores it |
| **Call** | backup arrives in 2 turns | end it now; Black Hole cancels |
| **Bolt** | flees next turn **with anything grabbed** | last chance to drop them; Black Hole cancels |

New resolution stats: **evade** (from Prophet's Breath, Rewind afterglow) and **hit/crit modifiers** (Luck). Enemy affinity profiles apply (§5b).

```js
ENEMY = {
  id:'shoreditch_mugger', name:'Mugger',
  hpRange:[25,35], attackRange:[4,9],
  intents:[ {type:'swing',w:50},{type:'heavy',w:20,mult:2.2},
            {type:'grab',w:20},{type:'bolt',w:10} ],
  greed:30, nerve:25,
  affinities:{}, loot:{cash:[10,40]},
  flavor:['He has the air of a man whose gym membership just lapsed.']
}
```

Enemy variety = new intent mixes + greed/nerve/affinity profiles, not new mechanics. Faction enforcers Brace and Call; junkies Grab and Bolt; Conclave agents get bespoke late-game intents (M6). Recruited muscle (e.g. Archie) can join as a once-per-fight intent-canceller.

**Fieldcraft** (§3b) applies its small permanent hit/evade/intimidate bonuses here and unlocks maneuvers — the light-stat half of the growth arc.

**Multi-enemy fights:** the combat data model is enemy-count-agnostic from M2 (an array of combatants, each with its own intent row), but content ships 1v1 through M4. Squad fights (2–3 enemies) arrive in M5 with faction enforcer pairs — giving Black Hole and mass Pan's Prank real targets — and the T5 mercenary squad is the endgame's combat crescendo. Threat tiers per §3b: encounters scale with district danger and what you visibly carry, never with player level.

## 12. Events & Event Cards (engine feature)

All story content migrates to a **data-driven event framework** — the hardcoded tutorial chains (intro, buyer, James, falafel, raid debriefs) become entries in an `EVENTS` table:

```js
EVENT = { id, trigger, cards:[{ speaker, text, choices:[{label, checks, effects, goto}], itemHooks }], flags }
```

- **Item use during events:** any card with `itemHooks` offers a *Use item* action. Luck boosts the next check; Prophet's Breath reveals a choice's outcome hint; Pan's Prank shifts the NPC's disposition (re-weights their responses); Shield absorbs one Bad Outcome; **Rewind pops the card stack back one card** (snapshot per card); Failsafe restarts the event on death.
- **Event cards as content:** beyond story chains, a deck of small **district events** (weighted by district, barometer, and flags) fires on travel/prospect actions — the texture of hidden London, and the main delivery vehicle for exploration flavour.
- The known event-card **scroll bug dies with the port**: Godot's VBoxContainer inside a bottom-anchored ScrollContainer gives push-up card stacking natively.

## 13. Economy: Selling, Marketplace, Barometer, Jobs

- **Selling lanes**, in order of unlock: Archie (50/50 split, mugging risk on the walk) → **Soho marketplace** (M4: better splits, fees, relation gates) → faction fronts (M5: best prices for members) → device commissions (M5).
- **The Soho Marketplace** (new screen, M4): daily-refreshed stock — buy ore at markup (patches supply gaps), consumables, equipment, device components, and overpriced recipe fragments. Sell anything without Archie's split but with market fees. All prices run through barometer effects, displayed as **effective vs base price with the reason** ("Fate: £82 ↑ — *the City's nervous*").
- **Barometer:** existing 3-axis machine stays; the 4 influence actions become functional in M4 with real costs and cooldowns — and **`spreadRumours` and `engineerCrisis` cost emotion ore** (they are, canonically, industrial-scale Pan's Pranks). Late-game: manipulate states you've positioned for — crash a market you've stockpiled against.
- **James jobs:** fixed-pay crafting contracts, no mugging risk — the safe-but-capped lane. M4 adds tiers and deadlines.
- **Equipment:** 5–7 weapons/wearables from raids, marketplace, crafting. Wearables grant negotiation bonuses — a good coat is +intimidate; this is London.

## 14. Contacts, Factions & Storylines

**Contacts** (Archie, James, +1–2 new by 1.0 — deliberately exceeded by the Collective's Act 1, collective1-07: Des, Nadia and Hakim are three real contacts because the Collective *is* its people and its trading lane runs through all three, `.scratch/collective-act1/spec.md` §3.5) keep the relation → recruit arc, except where a contact's own storyline says otherwise: Des and Hakim are never recruitable, and Nadia only becomes so after Act 3. Recruited contacts become assignable assets: home rooms, passive cultivating, combat muscle, device sales channels.

**Factions (5):** collective, firm, guild, network, conclave. Each gets by 1.0:
- **Map presence** — 1–2 districts tagged theirs; price/danger modifiers there scale with your relation.
- **A 3-event storyline** at relation thresholds (25/50/80), each delivering a unique mechanical reward: a recipe, security discount, district intel, a buyer front, or a barometer-influence discount.
- **A stance in the endgame.**

Joining one faction locks its rivals' storylines at event 2 — a real choice with a visible cost.

**The Conclave is different.** It is the ancient layer made flesh: an order that has managed the orichalchum trade since before London had a name — Mithraists, then guild masters, now a discreet livery company in the City with exceptional lawyers and a two-thousand-year filing system. Conclave events are the game's lore channel: Plato's *Critias* wasn't allegory, it was a leaked minute, and the dialogue is unfinished because someone finished the author first (they deny this; they deny it very calmly). Their storyline threads directly into the endgame (§15), their agents are the T5 threat tier, and their tone is liveried understatement — the politest frightening people in the game.

## 15. Endgame: The Deep Vein

Rumours accumulate through faction storylines and prospecting oddities — Roman brick where no Roman brick should be, a Mithraeum inventory listing one item too many, Conclave ledgers older than English. The truth underneath: London was founded *on purpose*, on top of a **Saturated mega-site** — a surviving node of the ancient network the Atlantean trade ran on, the deep vein the city has been quietly feeding on for two thousand years. The Conclave has been its custodian since Londinium, which is why London has never once been allowed to fail. Title drop, earned.

**Unlock:** any faction storyline complete + townhouse or better + cultivating skill 4+. A 5-event chain where the factions converge and the player's alignment (or independence) shapes the route in. The finale combines every system: a prospecting puzzle (reading the map's vein-glow), a negotiation gauntlet (three factions, three openers), one hard multi-enemy intent-combat against a T5 squad (where Rewind, Failsafe, and everything §3b built earn their price tags), and a closing economic decision:

- **Claim it** — become the supply. Kingpin ending, faction-flavoured.
- **Broker it** — sell access to all five factions. The Switzerland of orichalchum.
- **Cap it** — seal it, crash the market, retire on your stockpile. The Conclave sends a thank-you card that has been two thousand years in the drafting.

Three endings, one chain, faction-flavoured epilogues: medium scope, maximum payoff-per-word.

## 16. Home, Property & Time

Largely as built: 6 home tiers, security upgrades, rooms with bonuses, daily raid rolls, 3 time blocks/day. Additions: Ward Stone device slot; home tier gates endgame; `ops` room enables faction passives (M5); the mansion gets one indulgent bespoke scene, because the player earned it.

## 17. Tone Bible (revised, enforced)

**The blend:** Benedict Jacka's London (Alex Verus, Inheritance of Magic) supplies the chassis — a hidden magical economy run like a business, sincere danger, a pragmatic protagonist who survives on preparation and wit. Douglas Adams and The Office supply the narration — dry, observational, administrative. The ratio is 50/50: menace and comedy are equal partners, and each makes the other land harder.

- **Danger is sincere.** Violence has consequences, T3+ enemies should genuinely worry the player, and nobody monologues. A threat that can't hurt you doesn't ship.
- **Humour is coping, not whimsy.** One dry line per threat, not three. The joke sits next to something that could actually hurt you.
- **The ancient is administrated.** Two-thousand-year-old secrets are kept via filing systems, livery companies, and quiet men with lanyards. Wonder leaks through the mundane; it is never announced.
- **Archie:** cockney, blunt, bitingly funny. Magic is stock to shift. Time-allergic, permanently annoyed about it.
- **James:** 60s, brilliant, bitter. Helping people is structurally embarrassing. Quotes Plato constantly — and is, on the record, *right*, which makes it worse for everyone.
- **The Conclave:** liveried understatement. The politest frightening people in the game. The oldest firm in London, in every sense.
- **Rule of thumb:** if a line would work as an Alex Verus aside or a Fallen London snippet, it ships. If it winks, it dies.

---

# PART THREE — TECHNICAL ARCHITECTURE

## 18. Godot Project Structure

```
res://
  autoload/
    GameState.gd      # the gameState object, near-verbatim from the prototype
    EventBus.gd       # signals: state_changed, screen_changed, day_ticked
    SaveManager.gd    # JSON serialise; manual slots + autosave rotation
    Snapshots.gd      # state snapshot stack (see 19)
  data/               # JSON: ore_types, districts, recipes, devices, vein_levels,
                      # enemies, events, factions, home, barometer, consumables
  systems/            # cultivating.gd, prospecting.gd, crafting.gd, devices.gd,
                      # combat.gd, negotiation.gd, economy.gd, market.gd,
                      # events.gd, affinities.gd, time_system.gd
                      # → static funcs; read/write GameState; emit signals; NO UI
  scenes/
    Main.tscn         # ScreenManager: swaps screens on GameState.current_screen
    screens/          # Home, Map, Veins, Inventory, Crafting, Market, Combat,
                      # Contacts, World, Property, Factions, Stats, Save, Event
    components/       # VeinCard, SiteMarker, IntentIcon, StatBar, TypeLinkPicker,
                      # NotificationToast, ModalLayer, EventCardStack
  theme/main_theme.tres   # ink/paper/amber tokens as a Godot Theme resource
  map/                # London illustration + district hotspots
```

**The one-way data flow rule, enforced by convention from day one:** screens never mutate state. Buttons call system functions → systems mutate GameState and emit `state_changed` → screens redraw from state. This is the prototype's React discipline, and Godot will not enforce it for you — code review yourself weekly.

## 19. Engine Foundations (must land in M0, cheap now, brutal later)

1. **State snapshots.** `Snapshots.gd` keeps a bounded stack of deep-copied GameState (per combat turn; per event card). Rewind pops N frames; Failsafe pops on death; event-card rewind pops one card-frame. Requires GameState to stay a pure data tree — no node references, no closures. The prototype already obeys this; keep it sacred.
2. **Autosave.** Rotation of 3 autosave slots, written on: daily tick, combat exit, event completion, screen-level purchases. Manual slots + export/import (JSON string) retained from the prototype. Save format versioned from v1 with a migration function table — the ore-roster change is migration #1 and proves the pipeline.
3. **Data-driven events.** The EVENTS framework (§12) is engine work; tutorial content migrates onto it in M1.
4. **Effect resolution pipeline.** One function resolves any effect: `resolve(effect, source, target)` — applying magnitude → affinity modifiers → resistances → output. Consumables, devices, and enemy attacks all route through it, so affinities are written once.

---

# PART FOUR — MILESTONES

Each milestone ends in a **playable build** with explicit exit criteria. Estimates assume solo development at roughly 15–20 focused hours/week and should be treated as ±50% until M0 calibrates them. Playtest at the end of every milestone; rebalance before moving on.

## M0 — The Port & Foundations *(4–6 weeks)*
Port the HTML prototype to Godot at feature parity, plus the four engine foundations (§19).
**Scope:** GameState autoload; all DATA → JSON; all systems ported; all screens rebuilt with Godot Controls + theme; save/load + autosave; snapshot stack (tested via a debug "undo turn" button); event framework built (tutorial still hardcoded is acceptable); mobile export running on a real phone.
**Playable result:** the current game, in Godot, on your phone, autosaving.
**Exit criteria:** full tutorial-to-freeplay run without touching the old HTML; save from HTML prototype importable (nice-to-have); debug undo works in combat.

## M1 — London Exists *(4–6 weeks)*
**Scope:** ore roster migration (5 new types, save migration #1); map screen + 9 districts; travel rule; prospecting + sites + hospitability; seeding revamp; NPC site-claiming; district event-card deck (small, ~15 cards); cultivating tutorial event; tutorial chain migrated onto the event framework; commission the map illustration this milestone.
**Playable result:** the full economy loop played across a living map.
**Exit criteria:** a new player can prospect → seed → cultivate → prune → sell entirely via the map; routing decisions demonstrably matter (playtesters mention travel trade-offs unprompted).

## M2 — Everything Wants Your Ore *(4–5 weeks)*
**Scope:** negotiation opener (talk/bribe/intimidate + reputation stat); intent-telegraph combat, **built enemy-count-agnostic** (content ships 1v1); enemy template system + 6–8 enemy types across threat tiers T1–T3; **Fieldcraft skill** (XP from fights/negotiations/escapes, capped bonuses, first maneuver unlock); conditioning (HP growth via gym); NPC raids on veins; home raids formalised onto the new combat; first consumable wave (Blast, Enhancement Powder ×2, Shield, Healing Salve, Healing Burst); evade stat.
**Playable result:** threat is real, and crafted goods are the answer to it.
**Exit criteria:** every intent has at least one consumable answer; a fight can be fully avoided with cash or talk; players voluntarily spend money on vein security.

## M3 — The Craft *(5–7 weeks)*
**Scope:** combination crafting + the type-link discovery UI (on-device usability pass mandatory); discovery-by-experimentation; affinity system (profiles at new game, effect pipeline hookup, NPC profiles); devices phase 1 (Assay Glass, Ward Stone, Cultivator's Still, Ocular Lathe); Prophet's Breath, Pan's Prank, Luck Be a Lady; Rewind (proves the snapshot engine in anger).
**Playable result:** crafting becomes the game's deep system — discovery, combination, biology, and machines.
**Exit criteria:** a discovery moment lands ("I *found* this recipe") in playtests; the link-icon UI navigable one-handed; Rewind undoes turns and event cards without state corruption across 50 test uses.

## M4 — The Market *(4–6 weeks)*
**Scope:** Soho marketplace screen (daily stock, buy/sell, recipe fragments); effective-vs-base price display everywhere; barometer influence actions functional (emotion-ore costs); James job tiers + deadlines; equipment expansion (negotiation wearables); event item-hooks completed (Luck/Prophet's/Pan's/Shield/Rewind usable in events); stock/portfolio screen.
**Playable result:** a full trading game — multiple income lanes, price manipulation, information brokering.
**Exit criteria:** at least three viable economic strategies observed in playtests (cultivate-heavy, craft-heavy, trade-heavy); a player has profitably manipulated the barometer on purpose.

## M5 — Society *(5–7 weeks)*
**Scope:** faction map presence + 3-event storylines ×5 (the content-heaviest milestone — write ruthlessly); joining/locking; faction fronts as selling lanes; ops room passives; passive cultivating via assigned contacts; 1–2 new contacts; devices phase 2 (civilian commissions + reputational consequences); recruitment combat-assist; **squad combat** (2–3 enemies, per-enemy intent rows, AoE targeting for Black Hole and mass Pan's Prank) with T4 enemy content.
**Playable result:** London has politics, and the player is now a participant in them.
**Exit criteria:** each faction storyline completable with its reward; joining a faction visibly closes doors; device commissions form a competitive income lane.

## M6 — The Deep Vein *(4–6 weeks)*
**Scope:** endgame unlock logic; the 5-event Deep Vein chain (the ancient reveal: Critias canon, Conclave custodianship); the three endings + faction-flavoured epilogues; Black Hole + Failsafe; **T5 content** — mercenary squads + Conclave agents with bespoke intents; **The Mugging Revisited** callback event; mansion-tier content; full-game balance pass (economy curves, skill XP, prices, the §3b power curve).
**Playable result:** the complete game, start to any of three finishes.
**Exit criteria:** three full playthroughs reaching different endings; endgame reachable in a target 12–20 hours; no dominant degenerate money strategy survives the balance pass.

## M7 — Ship It *(6–8 weeks)*
**Scope:** tutorial gating for all systems (everything currently debug-open gets progression-locked); onboarding polish; juice pass (tweens, particles, haptics, sfx — the economy must *feel* liquid); music/ambience; accessibility (text size, colour-blind ore symbols); performance on low-end Android; Steam layout decision + build if green-lit; **monetisation decision gate**; store assets; closed beta → fix → launch.
**Playable result:** the released game.
**Exit criteria:** a cold new player completes the tutorial unaided; crash-free rate >99.5% in beta; store approvals passed.

**Indicative total: ~9–12 months part-time.** M0 is the calibration milestone — re-forecast everything after it.

---

# PART FIVE — RISKS & OPEN QUESTIONS

## Risks
1. **Scope creep** — the feature set doubled in one design week. Mitigation: pillars as filter; anything new post-M1 goes to a post-1.0 list by default.
2. **M5 content weight** — 15+ faction events plus device commissions is a writing mountain. Mitigation: fixed word budgets per event; cut to 2-event storylines if slipping.
3. **Snapshot fragility** — Rewind/Failsafe touch everything. Mitigation: land in M0, test continuously, keep GameState a pure data tree.
4. **Ore-roster migration** — touches every table and save. Mitigation: it's migration #1 in a versioned save pipeline; do it early (M1), never again.
5. **Solo art bottleneck** — the map illustration is the game's face and a single point of failure. Mitigation: commission at M1 start with a placeholder pipeline; icons from a consistent purchased set restyled to the palette.
6. **Combat outgrowing its rank / stat creep** — combat is priority #3; intents + affinities + Fieldcraft + squads + 12 consumables could seduce development time, and light stats have a habit of becoming heavy ones. Mitigation: enemy variety comes from data (intent mixes), never new mechanics after M5's squad layer; Fieldcraft bonuses hard-capped (±15% class); the power fantasy is delivered by preparation and recontextualised encounters (The Mugging Revisited), never by curves. If a playtester says "I need to grind Fieldcraft", the tuning is wrong.
7. **Tone drift** — 50/50 menace/comedy is a knife-edge; solo writing drifts toward whichever mode is easier that week. Mitigation: the tone bible's rules are checkable per-line; audit every event batch against them before it merges.

## Open Questions (park until their milestone)
- Steam desktop layout: letterboxed portrait vs true two-column (M7).
- Final price points and demo cut length (M7).
- Whether the random affinity roll offers a "hard mode" allergy start (M3).
- Title check: is **Vein** clear of conflicts on the stores? (Do this one early — a rename late is misery.)
