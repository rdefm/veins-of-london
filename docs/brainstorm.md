# Vein: new craftable items (brainstorm)

> **Status:** design brainstorm only. Nothing here is spec. All numbers are placeholders shaped like `docs/REFERENCE.md` §1.3. They need a balance pass and human sign-off before anything reaches `data/recipes.json`. All descriptions are **PROSE-REVIEW** drafts written against the CONTENT-GUIDE §3 tone bible.

---

## 1. Where the roster stands today

| Ore | Single-ore recipes | Count | In cross-ore recipes |
|---|---|---|---|
| **fate** | beALady | **1** | none |
| **life** | enhancementPowder, healingSalve | **2** | healingBurst, failsafe, rejuvenation |
| **time** | timePearl, rewind, prophetsBreath | **3** | healingBurst, failsafe, rejuvenation, wormhole |
| **physics** | blast, shield, blackHole | **3** | wormhole |
| emotion | panic, panger, pandemonium, pansRapture | 4 | none |

**Ore pairs already used:** time+life (×3) and time+physics (×1).
**Ore pairs never used:** fate+time, fate+life, fate+physics, fate+emotion, emotion+time, emotion+life, emotion+physics, life+physics.

### What the gaps cost the game
- **Fate is the most expensive ore (base £113) and has almost nothing to make.** Fate veins are valued as stock, not as crafting input. Conclave and Network both list fate as a primary or secondary ore and have almost nothing to spend it on.
- **Emotion is a silo.** Its four items are variations on one idea (crowd control through a status) and never mix with another ore.
- **Most of the economy has no item sinks.** Cultivating, prospecting, travel, grudges, wards, contacts and HQ defence are all deep systems with no items that touch them. Every current item is either for combat or for events.
- **Rejuvenation is the only lore-only item,** yet it is the best-priced good on the bench. The pattern works and deserves siblings.

---

## 2. Design pillars for new items

1. **One verb per item.** Each item does one legible thing. Tier (1–5) scales magnitude, never adds new behaviour.
2. **Hook an existing system.** Prefer items that call into a system that already exists (`Cultivating`, `Travel`, `Grudges`, `Observation`, `Contacts`, `Combat` statuses, `Events.apply_item_effect`) over items that need a new one.
3. **Three effect classes, kept roughly in balance:**
   - **[C] Combat:** loadout, guard kit, Dial Complication.
   - **[S] Systemic:** out-of-combat effects on the economy or the world (activeEffects blocks, vein state, relations, time).
   - **[L] Lore:** a sale good with a buyer and a story, like Rejuvenation. **Lore goods may also have light event-only uses** (for example, Patina passing a forgery check). They have no combat or systemic effect.
4. **Cross-ore items should read as their chemistry.** Fate+physics means "the thing that physically happens is the lucky one". Emotion+time means "feelings about the past". If the description doesn't explain why it takes two ores, it shouldn't.
5. **Faction fit.** Every new item has an obvious crafter and consumer among the five factions. This gives the faction economy (§1.8 `crafts` and `consumes`) somewhere to put it.
6. **State purity holds.** Every effect below can be stored as plain data (a counter, a day number, a flag, or a `{recipeKey: tier}` entry). None needs object references.
7. **No near-duplicates of Be a Lady.** Fate items must not be another flat luck or roll boost; give each one a distinct verb.

---

## 3. Single-ore items (the thin ores)

Legend: **[C]** combat · **[S]** systemic · **[L]** lore · 🔒 needs a new mechanic (see §6)

### 3.1 Fate (1 → 5)

| key | Name | Sym | Ingr. | baseSucc | effectPower (t1–5) | xp | Class |
|---|---|---|---|---|---|---|---|
| nearMiss | Near Miss | ⚐ | {fate: 5} | 0.35 | [0,1,1,2,2,3] attacks dodged | 25 | C |
| sodsLaw | Sod's Law | ⚇ | {fate: 6} | 0.30 | [0,1,2,2,3,4] enemy actions at min roll | 30 | C |
| happyAccident | Happy Accident | ✧ | {fate: 6} | 0.30 | [0,1,1,1,2,2] observation tiers; [0,0.02,0.03,0.04,0.05,0.06] craft success | 30 | S |
| introduction | Introduction | ⚭ | {fate: 4} | 0.45 | [0,0,0,0,0,0] | 20 | L |

- **Near Miss.** *"The bullet had somewhere else to be. You will not get an explanation, and neither will it."*
  The next N attacks aimed at you miss outright. This is the evasion counterpart to Shield's absorption. Belongs in the guard kit and suits a Dial Complication.
- **Sod's Law.** *"Whatever can go wrong for them now does, in order of inconvenience."*
  A status on one enemy: for N of its actions, attack damage rolls at the bottom of its range. It hits the enemy's rolls, not yours, which keeps it clear of Be a Lady.
- **Happy Accident.** *"You trip on exactly the right paving stone."*
  An activeEffect: the next prospecting read (`Observation.read`) adds +N to its tier modifiers, and while the effect is active, crafts get a small success bonus (+X to craft chance, alongside the Lab's `benchBonus`). This is the first item that serves the Sense skill.
- **Introduction.** *"Arranges for two people to be in the same queue at the same time. What happens next is not covered."* **[L]**
  A sale good, bought by the Network and by a private-client market (matchmakers, headhunters). Fate's answer to Rejuvenation.

### 3.2 Life (2 → 5)

| key | Name | Sym | Ingr. | baseSucc | effectPower | xp | Class |
|---|---|---|---|---|---|---|---|
| smellingSalts | Smelling Salts | ⚕ | {life: 5} | 0.40 | [0,5,8,12,16,20] HP on revive | 25 | C/S |
| rootFeed | Root Feed | ❦ | {life: 7} | 0.30 | [0,1,1,2,2,3] growth days | 30 | S |
| bloom | Bloom | ✿ | {life: 3} | 0.55 | [0,0,0,0,0,0] | 15 | L |

- **Smelling Salts.** *"Wakes anyone who is still technically in there. Ask them how they feel later."*
  In combat, revives a KO'd ally at X HP. Out of combat, from the Bag, it clears one contact's `koCooldownDays`. This gives KO a counter-play for the first time. Good guard kit item.
- **Root Feed.** *"Life calc, worked into the seam like bone meal. The vein grows, and resents it slightly."*
  Used on one owned vein (from the Vein list): +1 growth step per day for N days, through `Cultivating`. This is the first item that interacts with Soul and cultivating, and it gives life farmers a reason to sell to producers.
- **Bloom.** *"Keeps cut flowers fresh for a month. Covent Garden buys it by the crate and nobody asks why."* **[L]**
  A low-tier, fast, cheap sale good: the bread and butter for an early crafter. The Collective consumes it (its primary ore is life).

### 3.3 Time (3 → 5)

| key | Name | Sym | Ingr. | baseSucc | effectPower | xp | Class |
|---|---|---|---|---|---|---|---|
| borrowedTime | Borrowed Time | ◷ | {time: 8} | 0.15 | [0,1,1,1,1,1] blocks | 45 | S 🔒 |
| patina | Patina | ⌛ | {time: 4} | 0.45 | [0,0,0,0,0,0] | 20 | L |

- **Borrowed Time.** *"Gives you back an afternoon. The afternoon will want it back."*
  Adds +1 time block today and costs −1 block tomorrow, because it is a loan rather than a gift. Higher tiers reduce the debt (for example, at t5 the debt is waived). A time-block loan is approved in principle (§8 Q3); the details still need a spec. See §6.
- **Patina.** *"Ages anything about a century overnight. The Bermondsey antiques trade's best-kept open secret."* **[L]**
  A sale good. Light event use: passes a forgery check. Other hooks: a dealer who overpays, a Conclave inspector who notices.

### 3.4 Physics (3 → 7)

| key | Name | Sym | Ingr. | baseSucc | effectPower | xp | Class |
|---|---|---|---|---|---|---|---|
| ricochet | Ricochet | ↺ | {physics: 6} | 0.30 | [0,3,5,7,9,12] dmg reflected | 30 | C |
| deadweight | Deadweight | ⬛ | {physics: 7} | 0.25 | [0,10,15,20,25,35] % raid loss cut | 35 | S |
| signalFailure | Signal Failure | ⧗ | {physics: 5} | 0.35 | [0,1,1,2,2,3] rounds delayed | 25 | C |
| trueLevel | True Level | ⊥ | {physics: 4} | 0.45 | [0,0,0,0,0,0] | 20 | L |

- **Ricochet.** *"The next thing that hits you keeps going, back the way it came."*
  The next hit taken returns X damage to the attacker. It is the offensive sibling of Shield. Guard kit eligible.
- **Deadweight.** *"Makes a safe weigh four tonnes for anyone who isn't you."*
  Applied to HQ or a vein stockpile for N days: raid ore loss is cut by X%. This makes item spending part of passive defence, alongside guards and security tiers.
- **Signal Failure.** *"The target's reinforcements are held at a red signal. They are not told why."*
  Delays the arrival of enemy reinforcements (§3.7a) by N rounds: a points failure, a stuck barrier, a jammed door. It is a squad-level tactical item, unlike Time Pearl's single-target freeze.
- **True Level.** *"Makes a crooked house straight on a survey. The house stays crooked. Surveyors pay well."* **[L]**
  A sale good, bought by the Firm (physics primary). Event hooks: a housing scandal, or a building that is now officially fine.

---

## 4. Cross-ore items (new pairs)

| key | Name | Sym | Ingredients | baseSucc | effectPower | xp | Class | Natural crafter |
|---|---|---|---|---|---|---|---|---|
| dejaVu | Déjà Vu | ⟳ | {fate: 5, time: 5} | 0.20 | [0,1,1,1,2,2] checks revealed | 40 | Event 🔒 | Conclave |
| skeletonKey | Skeleton Key | ⚿ | {fate: 4, physics: 6} | 0.20 | [0,1,1,2,2,3] ward tiers ignored | 40 | C/Event | Firm |
| goodYear | Good Year | ❧ | {fate: 5, life: 5} | 0.20 | [0,2,3,4,5,7] days | 40 | S | Collective |
| secondImpression | Second Impression | ♢ | {fate: 4, emotion: 5} | 0.30 | [0,10,15,20,25,35] % relation gain; [0,1,1,2,2,3] days active | 30 | S/Event | Network |
| stiffUpperLip | Stiff Upper Lip | ☗ | {emotion: 4, life: 5} | 0.30 | [0,2,3,4,5,6] turns immune; [0,10,15,20,25,30] % incoming damage cut | 30 | C | Collective |
| heavyMetal | Heavy Metal | ♫ | {emotion: 5, physics: 5} | 0.20 | [0,3,4,6,8,10] AoE dmg | 40 | C | Network/Firm |
| coldFeet | Cold Feet | ❄ | {emotion: 4, time: 4} | 0.35 | [0,1,1,1,1,1] | 30 | C/Event | Guild |
| nostalgia | Nostalgia | ☙ | {emotion: 5, time: 5} | 0.30 | [0,0,0,0,0,0] | 25 | L | Network |
| navvysDraught | Navvy's Draught | ⚒ | {life: 5, physics: 5} | 0.30 | [0,5,8,12,16,20] +HP max | 30 | C | Firm |

**Notes and prose**

- **Déjà Vu** (fate+time). *"You have done this before. It went differently. You remember how."*
  An event item toggle: before you commit, it reveals the actual d100 roll for one check option (`roll` and `needed` already exist as display data). Rewind lets you retry after a failure; Déjà Vu lets you see the outcome first. It costs the same ores as the Conclave's profile (fate primary, time secondary), which is a good fit.
- **Skeleton Key** (fate+physics). *"Not a key. A strong opinion about which way a lock should be."*
  During a raid, cancels up to N ward triggers (`data/wards.json` `counters` already provides a counter slot). In events, it unlocks a `requires: {item}` door. Raiders now have a reason to buy fate.
- **Good Year** (fate+life). *"Not more ore. Better ore, which is worse news for the people buying it."*
  On one vein for N days, prune and harvest yields roll as if the terroir tier were one higher. Combined with Root Feed, this gives a cultivation item pair.
- **Second Impression** (fate+emotion). *"Nobody remembers the first one. You've made sure of it."*
  While active, every relation gain (contacts and key members, through gifts, favours, jobs and events) is boosted by N%. Higher tiers give a bigger boost and last longer. It may also help persuasion choices in events; how is undecided (grill ticket `issues/02-grill-second-impression-persuasion.md`). Network fit: emotion primary, fate secondary.
- **Stiff Upper Lip** (emotion+life). *"Fear is noted and filed for later. Much later."*
  For N turns, you and your allies are immune to Panic, Panger, Pandemonium and Pan's Rapture, and it cleanses any of them already active. For the same turns, you and your allies take X% less incoming damage in a fight. This is the hard counter to Network raid kits and gives the emotion pool a defensive item.
- **Heavy Metal** (emotion+physics). *"Every enemy in range hears it. Most of them wish they hadn't."*
  Deals X damage to every enemy, and the lowest-HP enemy rolls a Panic-style bolt check. This is the game's first area-of-effect damage that isn't Black Hole. The name nods to Black Sabbath and Birmingham, and physics calc is literally heavy metal.
- **Cold Feet** (emotion+time). *"Regret, applied in advance."*
  In combat, a guaranteed `legIt` for the whole squad. In events, it shows a hidden "leave now" exit option on a card, so you get out before it goes wrong. It's an escape valve worth its price on the wrong night.
- **Nostalgia** (emotion+time). *"A bottled afternoon from 1987. People pay to cry at it."* **[L]**
  A premium sale good, priced like Rejuvenation as a vanity product. Its buyers are lonely and rich, and that is a quest hook.
- **Navvy's Draught** (life+physics). *"What the men who dug the Underground drank, allegedly. +Constitution, −table manners."*
  +X max HP and current HP for one fight, which means it can be used from the Bag before combat. Firm fit: physics primary, life secondary.

### 4.1 Three-ore and capstone (stretch)

| key | Name | Ingredients | Class | Idea |
|---|---|---|---|---|
| cleanSlate | Clean Slate | {fate: 5, time: 5, emotion: 5} | S | Clears one active faction **grudge** (§3.1c) and its revenge window. *"Everyone involved remembers it differently, and slightly in your favour."* Expensive and rare; the Conclave sells it at a markup. |
| keystone | Keystone | one of each ore, {×4} | L | No effect. A masterwork object that a Collective quest or the Dial gift storyline could ask for. It proves you can work all five ores, and it's the obvious "hire me" item for LodedInnit. |

---

## 5. Coverage after the proposal

| Ore | Singles now → proposed | Cross-ore appearances now → proposed |
|---|---|---|
| fate | 1 → **5** | 0 → **4** (+cleanSlate, keystone) |
| life | 2 → **5** | 3 → **6** |
| time | 3 → **5** | 4 → **7** |
| physics | 3 → **7** | 1 → **4** |
| emotion | 4 → 4 | 0 → **5** |

Class mix across the 24 new items: **Combat 9 · Systemic 8 · Lore 7** (counting dual-class items once, by their primary use).

### Proposed faction economy additions (`crafts` / `consumes`)

| Faction | + crafts | + consumes |
|---|---|---|
| collective (life/emotion) | bloom, smellingSalts, stiffUpperLip, goodYear | rootFeed |
| firm (physics/life) | ricochet, navvysDraught, skeletonKey, trueLevel | smellingSalts, navvysDraught |
| guild (time/physics) | signalFailure, patina, coldFeet, deadweight | borrowedTime |
| network (emotion/fate) | secondImpression, heavyMetal, nostalgia, introduction | dejaVu |
| conclave (fate/time) | dejaVu, nearMiss, sodsLaw, cleanSlate | patina, introduction |

### Recipe sellers

Under the existing `recipe_knowledge.json` seller rule ("first seller whose ores hold every ingredient, else `defaultSeller`"), James (time/life) sells Smelling Salts, Root Feed, Bloom, Patina and Borrowed Time. **Everything else, including all fate and emotion recipes, goes to Wren in the Guild for now** (§8 Q1). Wren is already `defaultSeller`, so this needs no rule change. A Network or Conclave shop can take them over later.

---

## 6. Architect notes: what each item costs to build

### Tier A: data only, or reuses existing effect plumbing
`introduction`, `bloom`, `trueLevel`, `nostalgia`, `keystone` (lore goods: a recipe row, a `CONSUMABLE_PRICES` entry and an icon).
`patina` (lore good plus one event `requires: {item}` option).
`navvysDraught`, `ricochet`, `nearMiss`, `sodsLaw` (each is one new case in the §3.7b item table, shaped like existing statuses).

### Tier B: a new hook in an existing system
| Item | Touches | New data |
|---|---|---|
| smellingSalts | `Combat` (revive), `Contacts` (KO cooldown) | none |
| signalFailure | reinforcement scheduler (§3.7a) | `combat.reinforcementDelay` int |
| stiffUpperLip | combat status resolver; damage intake | `immuneEmotion` turns and `damageCut` on combatant |
| heavyMetal | §3.7b item table, multi-target | none |
| coldFeet | `legIt` resolution; event `exit` option | flag on option |
| happyAccident | `Observation.read` mods; craft chance | activeEffect |
| secondImpression | `RelationAccrual` (all gains); event persuasion (TBD, grill ticket 02) | activeEffect `{until, pct}` |
| rootFeed / goodYear | `Cultivating` daily tick | `vein.boosts = {rootFeed: {until, power}}` |
| deadweight | `Home` / §3.12 raid loss | `home.deadweightUntil`, per-vein equivalent |
| skeletonKey | ward trigger path (`counters`) | none |
| cleanSlate | `Grudges` | none |
| dejaVu | `Events.apply_item_effect`, new kind `reveal` | `state.event.revealed[i]` |

### Tier C: needs a spec decision first 🔒
- **Borrowed Time.** A block loan is approved in principle, but `TIME_BLOCKS` paces the whole game, so the spec has to answer: Can it stack? Does it interact with Rest? What happens to the debt if the day rolls over during an event? I recommend writing a small spec and running a sim before committing.
- **Déjà Vu.** Showing a roll in advance turns every check into a certainty. It needs a cap (one check per event) and a decision on whether it interacts with Rewind's best-of-two.
- **Item placement on veins and HQ** (`rootFeed`, `goodYear`, `deadweight`). Whether this gets one shared "use on a place" UI pattern or stays in the Bag is undecided; see grill ticket `issues/01-grill-use-on-a-place.md`.

### Lists and constants to update when implementing
`CONSUMABLE_PRICES` (keep the `xpReward × 6` rule; let lore goods break it the way Rejuvenation does, and document each exception), `loadout.items`, `loadout.allyExcluded` (exclude coldFeet so it stays player-only like Wormhole), `guardKit.items` plus `repelTier` (growing the allowlist is approved, §8 Q5), `activeEffects.items`, the eventUsable column, `recipe_knowledge.json` (master sources; sellers need no change), `factions.json` `crafts`/`consumes`/`craftTargets`, and barometer `itemDemand` hooks (for example, a crisis raises Stiff Upper Lip, and a boom raises Nostalgia and Introduction).

---

## 7. Recommended first wave (8 items)

The aim is to fix the fate and emotion silo, open three systems that have no items yet, and keep the build cheap:

1. **Near Miss** (fate, C): fills the evasion gap; tier A.
2. **Happy Accident** (fate, S): gives fate an everyday use and helps crafters; tier B.
3. **Introduction** (fate, L): a fate sale good; tier A.
4. **Smelling Salts** (life, C/S): gives KO a counter-play; tier B.
5. **Root Feed** (life, S): first cultivation item; tier B. Its targeting UI waits on grill ticket 01.
6. **Stiff Upper Lip** (emotion+life, C): the counter to Network kits; tier B.
7. **Sod's Law** (fate, C): a satisfying offensive item; tier A.
8. **Nostalgia** (emotion+time, L): a premium lore good; tier A.

The second wave would be Déjà Vu, Skeleton Key, Cold Feet, Second Impression, Good Year, Deadweight and Signal Failure. Borrowed Time and Clean Slate should wait for their own specs.

---

## 8. Decisions

1. **Who sells fate and emotion recipes?** Wren, in the Guild, for now (already `defaultSeller`).
2. **Can lore goods have event-only uses?** Yes. Lore goods are "lore plus light event" (pillar 3).
3. **Is a time-block loan (Borrowed Time) acceptable?** Yes, in principle. Details still need a spec (§6 Tier C).
4. **One shared "use on a place" UI pattern, or keep everything in the Bag?** Undecided. Grill ticket: `issues/01-grill-use-on-a-place.md`.
5. **Is the guard kit allowlist growing OK?** Yes.
6. **How does Second Impression help persuasion choices in events?** Undecided. Grill ticket: `issues/02-grill-second-impression-persuasion.md`.

## 9. Still open

- Fate+physics lost Loaded Dice (too close to Be a Lady); Skeleton Key is now its only item. Add another only if it has a distinct verb.
