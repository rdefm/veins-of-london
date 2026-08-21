# VEIN — Canonical Reference (data · schemas · formulas)

This file is the single source of truth for every number and rule. The HTML prototype is prose-only reference; where it differs from this file, this file wins. All tables below ship as JSON files in `data/` with exactly these keys and values.

Notation: `rand(a,b)` = uniform integer a..b inclusive. `chance(p)` = true with probability p. All probabilities are 0–1 floats. All cash is integer £.

---

## 1. DATA TABLES

### 1.1 `data/ore_types.json`
The new five-type roster (replaces old time/energy/life/void/motion — see §7 migration notes).

| key | name | symbol | colour | basePrice | flavorText |
|---|---|---|---|---|---|
| time | Time Orichalchum | ⧖ | #7b68ee | 60 | Smells faintly of burnt clocks. |
| physics | Physics Orichalchum | ↯ | #2a8fc4 | 55 | Vibrates faintly in your pocket. |
| life | Life Orichalchum | ✦ | #3a7a52 | 70 | Warm to the touch. Not unpleasantly. |
| fate | Fate Orichalchum | ⚄ | #b08d2e | 90 | Feels lucky in the hand. Statistically, it isn't. |
| emotion | Emotion Orichalchum | ❋ | #9b4a7a | 65 | Holding it, you feel briefly understood. It wears off. |

### 1.2 `data/vein_growth.json`
vein-growth-state PRD: a vein has one signed axis, `growth: int` (0..ceiling, default ceiling 100, neutral 50), replacing the old `devBar`/`level`/`charged`/`chargeBlocks` quartet entirely. Left alone, growth drifts daily toward whichever wall it was last left leaning, accelerating with distance from neutral; the player pushes it back with Cultivate (right) or Prune (left).

Bands (symmetric around neutral; `drift` is the daily movement while a vein sits in that band):

| band id | growth range | label | drift/day |
|---|---|---|---|
| collapsed | 0 | Spent | 0 (pinned; see below) |
| barren | 1–14 | Barren | 3 (leftward) |
| sparse | 15–29 | Sparse | 2 (leftward) |
| thinning | 30–44 | Thinning | 1 (leftward) |
| dormant | 45–55 | Dormant | 0 |
| taking | 56–70 | Taking | 1 (rightward) |
| lush | 71–85 | Lush | 2 (rightward) |
| wild | 86–99 | Wild | 3 (rightward) |
| rampant | 100 (ceiling) | Rampant | 0 (clamped) |

Other constants (`data/vein_growth.json`): `yieldPerPoint: 0.35`, `hardPruneBonus: 1.25`, `pruneLightDepth: 15`, `pruneHardDepth: 40`, `cultivateBase: 10`, `cultivatePerSkill: 4`, `cultivateMinGain: 2`, `collapseChancePerDay: 0.15`, `seedGrowth: 20`, `rampantSeedDays: 5`, `selfSeedGrowth: 60`, `wildCeilingBonus: 20`, `terroirYieldMult: { poor: 0.6, fair: 1.0, rich: 1.6, saturated: 2.4 }`.

**Cultivate** (`Cultivating.cultivate`): success roll unchanged (`cultChance = min(0.90, 0.30 + (skill-1)*0.12)`); on success, `growth += cultivate_gain(skill, growth, ceiling)` where `cultivate_gain = max(cultivateMinGain, round((cultivateBase + cultivatePerSkill*skill) * (1 - growth/ceiling)))` — diminishing toward the ceiling on purpose.

**Prune** (`Cultivating.prune(vein_id, depth)`, light -15 / hard -40): yield counts only growth points removed from above neutral — `points = max(0, growth_before-50) - max(0, growth_after-50)`, `yield = round(points * yieldPerPoint * terroir_yield_mult(vein) * hardBonus)` (hardBonus 1.25 for a hard prune, 1.0 for light), then `apply_yield_bonus`. Pruning at or below neutral always yields 0.

**Left wall**: `growth` pins at 0 (never negative); each daily tick, `chance(collapseChancePerDay)` removes the vein — a player vein's site reverts to unclaimed (re-seedable); a faction vein's site is deleted outright, matching NPC-abandonment semantics.

**Right wall**: `growth` clamps at `ceiling(vein)` (100, or 120 with the `wildCeiling` hospitability bonus). A vein sitting at the ceiling accrues `rampantDays` and self-seeds a new vein nearby after `rampantSeedDays` (5) days at the ceiling — see vein-growth-state ticket 02.

**Value tier** (`Cultivating.value_tier(vein)`, 1..6, `= min(6, 1 + floor(growth/20))`) is the single seam that replaces the old 1–5 `level` everywhere magnitude mattered (raid stealth odds, faction raid targeting, faction vein income, rivalry weighting, combat scaling, the map's Strength filter).

There is NO vein lifespan/expiry mechanic beyond the collapse roll above.

Other cultivating constants (also `data/vein_growth.json`, colocated since their old home `vein_levels.json` no longer exists): `SEED_ORE_COST = 40`. `CULTIVATING_XP_LEVELS = [0, 0, 80, 220, 500, 1000]` (index = cultivating skill level).

### 1.3 `data/recipes.json`

Each recipe's `ingredients` field is a dict of `{oreType: baseCalcCost}` — one key per required ore type, cost computed per-key (§3.5). Existing recipes are all single-ingredient (one-key dicts); nothing in the schema requires that.

| key | name | symbol | ingredients (oreType: baseCalcCost) | baseSuccess | effectPower (index=skill 0–5) | xpReward | eventUsable |
|---|---|---|---|---|---|---|---|
| timePearl | Time Pearl | ⧖ | {time: 5} | 0.40 | [0,1,1,2,2,3] (frozen turns) | 20 | false |
| enhancementPowder | Enhancement Powder | ↯ | {life: 6} | 0.35 | [0,1,1,2,2,3] (see combat §3.8) | 25 | false |
| rewind | Rewind | ⟲ | {time: 6} | 0.40 | [0,2,2,2,2,2] (turns rewound) | 35 | true |
| healingSalve | Healing Salve | ♥ | {life: 5} | 0.45 | [0,3,4,5,6,8] | 20 | false |
| blast | Blast | ☄ | {physics: 5} | 0.40 | [0,6,8,10,12,15] | 25 | false |
| shield | Shield | ⛨ | {physics: 6} | 0.30 | [0,4,5,6,8,10] | 30 | false |
| blackHole | Black Hole | ⊙ | {physics: 7} | 0.20 | [0,8,10,13,16,20] | 35 | false |
| prophetsBreath | Prophet's Breath | ≋ | {time: 5} | 0.30 | [0,1,1,2,2,3] | 30 | true |
| beALady | Be a Lady | ☘ | {fate: 6} | 0.35 | [0,1,1,1,2,2] | 25 | true |
| pansPrank | Pan's Prank | ☻ | {emotion: 6} | 0.25 | [0,2,3,4,5,6] | 30 | true |
| healingBurst | Healing Burst | ✚ | {time: 4, life: 4} | 0.30 | [0,8,10,12,15,18] | 30 | false |
| failsafe | Failsafe | ⚑ | {time: 6, life: 6} | 0.12 | [0,1,1,2,2,2] | 45 | true |
| rejuvenation | Rejuvenation | ❀ | {time: 5, life: 5} | 0.35 | [0,0,0,0,0,0] (no gameplay effect — sale good only) | 20 | false |
| wormhole | Wormhole | ⊗ | {time: 5, physics: 5} | 0.18 | [0,1,1,1,1,1] | 40 | true |

calc-discovery ticket 10 also added a `discovery: {types, approach}` field (the Lab cell each recipe is found in), an optional `refineStep: {field, add}` field, and an optional `taughtBy` marker (set on timePearl/enhancementPowder/rewind — grants the effect pre-found on a fresh save) to every recipe above. These three fields, and the discovery-chance/refine-chance formulas and cell-state model that consume them, are calc-discovery mechanics per `docs/M3-CALC-DISCOVERY.md` (still a vision document, not yet promoted to spec) — not documented further here until that doc is specced, matching how `systems/bench.gd`'s own formulas are treated. The one exception: `effectPower` at a refine tier > 0 stacks `refineStep.add * tier` on top of the row above (`systems/crafting.gd`'s `effect_power()`) — tier 0 (unrefined) matches the row exactly.

Descriptions (verbatim):
- timePearl: "Throw at your feet. Freezes enemy for N turns. Elegant, if you ignore what it actually is."
- enhancementPowder: "Rub on skin before a fight. Life-type acceleration — you act faster than anyone can track."
- rewind: "Shaped like an hourglass. Briefly unspools time — only you remember what happened. Difficult and expensive to produce."

`CRAFTING_XP_LEVELS = [0, 0, 80, 220, 500, 1000]`. `CONSUMABLE_PRICES = { timePearl: 120, enhancementPowder: 150 }` (rewind is not sellable).

### 1.4 `data/devices.json`
`DEVICE_XP_LEVELS = [0, 0, 50, 150, 400, 1000]` (level up = +1 charge/day).

| key | name | symbol | calcType | recipeKey | effect | unlockFlag | eventUsable |
|---|---|---|---|---|---|---|---|
| timeDevice | Time Device | ⧖ | time | timePearl | freeze | craftingUnlocked | false |
| enhancementDevice | Enhancement Device | ↯ | life | enhancementPowder | motion | enhancementUnlocked | false |
| rewindDevice | Rewind Device | ⟲ | time | rewind | rewind | craftingUnlocked | true |

### 1.5 `data/items.json` (equippables)

| key | name | slot | attackBonus | description |
|---|---|---|---|---|
| crowbar | Crowbar | weapon | {min:4, max:8} | "A 60cm steel crowbar. Heavy enough to matter. Also useful for doors, if you have legitimate reasons to open them." |

### 1.6 `data/vein_security.json` (per-vein security tiers)

| id | label | raidResist | cost |
|---|---|---|---|
| none | Unsecured | 0 | 0 |
| basic | Basic Lock | 15 | 20 |
| warded | Ward Rune | 35 | 60 |
| guarded | Hired Guard | 55 | 120 |

### 1.7 `data/home.json`

**Tiers** (order matters — it is the upgrade ladder). `maxSecuritySlots` no longer exists — security is gated by each upgrade's `minTier` instead (below), not by a count cap:

| id | name | tier | upgradeCost | dailyCost | raidBaseChance | maxRooms |
|---|---|---|---|---|---|---|
| bedsit | Bedsit | 1 | 0 | 50 | 0.08 | 0 |
| flat | Flat | 2 | 1200 | 80 | 0.06 | 1 |
| townhouse | Townhouse | 3 | 4000 | 150 | 0.04 | 3 |
| safehouse | Safehouse | 4 | 12000 | 300 | 0.02 | 5 |
| compound | Compound | 5 | 40000 | 600 | 0.01 | 8 |
| mansion | Mansion & Grounds | 6 | 150000 | 1500 | 0.005 | 12 |

Tier descriptions: extract verbatim from HTML const `HOME_TIERS`.

**Security upgrades** (each installable once, gated by `minTier` — not a count cap: a player who has reached the required tier and can afford it may install it regardless of how many others are already installed; cost ×0.7 rounded when flag `securityContactUnlocked` is true):

| id | name | cost | raidReduction | minTier |
|---|---|---|---|---|
| lock | Reinforced Lock | 80 | 0.02 | bedsit |
| cameras | CCTV | 250 | 0.03 | flat |
| alarm | Alarm System | 400 | 0.03 | flat |
| reinforcedDoor | Reinforced Door | 600 | 0.04 | townhouse |
| ward | Orichalchum Ward | 2000 | 0.06 | safehouse |
| guard | Hired Guard | 1200 | 0.05 | compound |

**Rooms:**

| id | name | cost | minTier | bonus | bonusValue |
|---|---|---|---|---|---|
| workshop | Workshop | 800 | flat | crafting | 0.08 |
| homeGym | Home Gym | 600 | flat | body | 10 |
| library | Library | 1200 | townhouse | crafting | 0.08 |
| safeRoom | Safe Room | 2000 | townhouse | storage | 0.5 |
| ops | Operations Room | 5000 | safehouse | faction | 1 |
| veinStation | Vein Cultivation Station | 8000 | safehouse | passive | 1 |
| lab | Improved Lab | 15000 | compound | crafting | 0.12 |

Descriptions: extract verbatim from HTML consts `HOME_SECURITY` / `HOME_ROOMS`.

### 1.8 `data/factions.json`
Five factions; copy `name`, `shortName`, `tagline`, `industries`, `description`, `colour` verbatim from HTML const `FACTIONS`. Mechanical fields:

| id | joinRelation |
|---|---|
| collective | 20 |
| firm | 35 |
| guild | 40 |
| network | 30 |
| conclave | 60 |

**Faction barometer preferences** (`FACTION_BAROMETER_PREFS`, daily nudges — see §3.2):

- collective: push economic/stable str 3; push social/stable str 3
- firm: push economic/boom str 4; push social/crime str 3; pull political/regulation str 3
- guild: push economic/stable str 3; push political/stable str 3; pull social/unrest str 2
- network: push economic/inflation str 3; push social/unrest str 3; push political/election str 3
- conclave: push political/regulation str 4; push political/war str 3; push economic/crisis str 3

### 1.9 `data/barometer.json`
Three sections. `effects` keys and meanings: `orePrice` (multiplier delta on all ore), `mugChance` (additive), `dailyCost` (multiplier delta), `raidChance` (vein raids, M1+), `homeRaid` (additive), `searchFind` (reserved, unused post-port), `effectMod` (reserved), `<type>Premium` (additive multiplier delta for one ore type).

economic: stable {} · boom {orePrice:+0.25, mugChance:−0.05} · recession {orePrice:−0.20, mugChance:+0.05} · crisis {orePrice:−0.35, mugChance:+0.12, fatePremium:+0.5} · inflation {dailyCost:+0.30, orePrice:+0.10}

social: stable {} · unrest {mugChance:+0.08, raidChance:+0.10} · lockdown {searchFind:−0.15, dailyCost:+0.10} · festival {physicsPremium:+0.40, searchFind:+0.05} · crime {mugChance:+0.15, homeRaid:+0.05}

political: stable {} · war {timePremium:+0.6, physicsPremium:+0.4, mugChance:+0.05} · austerity {dailyCost:−0.15, mugChance:+0.06} · regulation {mugChance:+0.10, orePrice:+0.15} · election {effectMod:−0.3}

Labels/descriptions: extract verbatim from HTML const `BAROMETER_STATES`, renaming "Motion ore" → "Physics ore", "Time and energy ore" → "Time and physics ore".

**Influence actions** (data only until M4; render greyed with costs):

| id | label | section | cost | requireFaction |
|---|---|---|---|---|
| lobbyConclave | Lobby the Conclave | political | {cash:5000, fate:20} | conclave |
| floodMarket | Flood the market | economic | {cash:2000, ore:50} | null |
| spreadRumours | Spread rumours | social | {cash:500} | network |
| engineerCrisis | Engineer a crisis | economic | {cash:10000, emotion:40} | conclave |

### 1.10 `data/enemies.json`

Vein-raid guard templates: Territorial Scrapper {hpBase:20, atk 3–8} · Vein Guard {hpBase:30, atk 4–10} · Orichalchum Dealer {hpBase:25, atk 5–12}.
Home-raid raider (fixed): hp 35, atk 6–14, name "The raider".
Muggers: generated, see §3.7.

**Enemy capability surface** (calc-effect-wiring-01): every template may optionally carry `weapon: {min, max}` (an attack-bonus range added to attackMin/attackMax) and `ability: <string id>` (wrapped at construction into `{id, lockedTurns}` — `lockedTurns > 0` means the ability is locked out). Every template also carries `evadeChance` (0.0–1.0), rolled per hit against the player's attack — `Combat._enemy_capabilities_from_template()` is the single place these are assembled from a raw template dict. All templates above are pre-capability-surface and set `evadeChance: 0` explicitly to preserve existing combat math. **Default for any newly-authored template that omits `evadeChance`: 20%.** `Combat.disarm_enemy(enemy, turns)` strips `weapon` outright and sets `ability.lockedTurns = turns`; the lock ticks down once per player-attack turn (§3.7).

### 1.11 Misc constants
`TIME_BLOCKS = ["Morning","Afternoon","Evening"]` · `ARCHIE_ORE_GOAL = 10` · contacts: archie {startRelation:10, unlocked:true, recruitThreshold:80}, james {startRelation:0, unlocked:false, recruitThreshold:100} · James job trust→qty bands: relation ≤1 → 1–3; ≤3 → 3–6; else 5–10; payPerItem = CONSUMABLE_PRICES[recipe].

**James job daily offer roll** (bugfixes-30, human-confirmed): on the daily tick, when no James job is active, roll sequentially — type-1 first, type-2 only if type-1 misses:
- **Type-1 (flat pay):** `{recipeKey/qty}`-less job, pay `£300` flat for spending one time block. Offer chance = 100% if `player.cash <= 100`, else a 15% baseline.
- **Type-2 (craft):** if type-1's roll misses, roll again at a flat 15% baseline (not cash-scaled). On hit, `Jobs.generate_james_job()` as before, plus `byDay = day + qty * 2` (2 days per unit ordered).
- Missing a type-2 job's `byDay` deadline (checked in `daily_tick()`): job expires (jamesJobActive/jamesJob/jamesJobAccepted clear), james relation −5, Notify. Declining a job explicitly never costs relation — only a missed deadline does.

---

## 2. STATE SCHEMA

`GameState.state` is exactly this tree (a Dictionary of Dictionaries/Arrays/primitives; no objects). Defaults shown are new-game values.

```
state = {
  meta: { saveVersion: 1 },
  currentScreen: "title",     # see screen list below
  modal: null,                # { type: String, data: Dictionary } | null
  bagDrawerOpen: false,        # M1 D4.4; the global BagDrawer bottom sheet, independent of `modal`
  inventoryTab: "ore",
  mapNav: { selectedDistrict: null, selectedSiteId: null },  # M1 D4; Map tab drill-down (list -> district panel -> site/vein sheet)
  veinListNav: { districtId: null, bandFilter: null, originScreen: "map" },  # vein-growth-state ticket 09 (§6.2); vein list scope/filter/return-screen
  notifications: [],          # [{ id:String, text:String, seen:bool, day:int }] — capped at 50, oldest evicted; dismiss() only flips seen, never deletes (11-phone-os-shell ticket 04)
  bankLog: [],                # [{ id:String, amount:int, label:String, day:int }] — capped at 50 (Bank.LOG_CAP), oldest evicted; every direct player.cash mutation calls Bank.record() alongside itself (bugfixes-38, systems/bank.gd), same append-and-evict-from-front shape as `notifications` above. Display only, no dismiss.
  sellState: {},              # sell-menu qty selections, transient
  event: null,                # M0-T13 event runner state: { eventId, cardIndex, snapshots:[] } | null

  player: {
    cash: 40,
    hp: 100, hpMax: 100,
    attackMin: 5, attackMax: 12,
    orichalchum: {},          # { oreType: int }
    veins: [],                # vein dicts, §2.1
    inventory: { timePearl: 0, enhancementPowder: 0, rewind: 0 },
    shieldPool: 0,             # calc-effect-wiring-02: Shield's absorption pool, §3.7
    healingSalveDaysLeft: 0, healingSalveDailyAmount: 0,  # calc-effect-wiring-02: Healing Salve HoT, §3.1/§3.7
    equipment: { weapon: null, device: null },
    items: [],                # [{ id:String, type:String }]
    devicesInProgress: [],    # [{ id, type, progress:float }]
    devicesCompleted: [],     # [{ id, type, level, xp, chargesPerDay, chargesUsedToday, lastResetDay }]
    craftingSkill: 1, craftingXP: 0,
    cultivatingSkill: 1, cultivatingXP: 0,
  },

  world: {
    day: 1, timeBlock: 0, timeBlocksDone: [],
    archieChatUnlockDay: null,
    currentDistrict: "shoreditch",   # M1; harmless in M0
  },

  home: { tier: "bedsit", security: [], rooms: [], lastRaidDay: 0 },
  # M1-LONDON-T06: storedOre was merged into player.orichalchum — there was
  # never a deposit/withdraw mechanic, so it was always an empty or
  # unreachable second pool. Carried ore is what a home raid now risks and
  # loses (§3.3, §3.8) — there is only one ore pool.

  factions: { collective: {relation:0, joined:false}, firm: {...}, guild: {...},
              network: {...}, conclave: {...} },   # same shape each

  barometer: {
    economic: "stable", social: "stable", political: "stable",
    progress: {},        # per §3.2, initialised lazily
    cooldowns: {},       # per §3.2
  },

  contacts: {
    archie: { relation:10, unlocked:true,  recruited:false, recruitThreshold:80,
              craftingSkill:1, craftingXP:0, cultivatingSkill:1, cultivatingXP:0, assignedRoom:null },
    james:  { relation:0,  unlocked:false, recruited:false, recruitThreshold:100,
              craftingSkill:1, craftingXP:0, cultivatingSkill:1, cultivatingXP:0, assignedRoom:null },
  },

  combat: { active:false, context:"raid", veinId:null, enemy:null, log:[],
            outcome:null, frozenTurns:0, motionTurns:0, motionPower:0,
            evadeTurns:0, evadeChance:0.0, onWin:null, snapshots:[] },

  jamesJob: null,             # { type:"craft", recipeKey, recipeName, symbol, qty, payPerItem, totalPay, byDay } | { type:"flatPay", pay } | null
  pendingSaleCut: 0,
  labThresholds: {},          # { recipeKey: int }
  veinStationVeins: [],       # [veinId]
  veinStationTargets: {},     # { veinId: int growth target }, default 70 on assignment

  flags: {
    tutorialStage: "intro",   # intro|buyer_event|sms_archie|meet_james|archie_craft_chat|free
    metArchie: false, metJames: false, buyerEventSeen: false,
    craftingUnlocked: false, archieCraftChatSeen: false,
    canSellConsumables: false, consSoldCount: 0,
    archieMotionPending: false, archieMotionEventSeen: false,
    jamesMotionEventSeen: false, enhancementUnlocked: false,
    jamesJobActive: false, jamesJobAccepted: false,
    homeRaidEventPending: false, homeRaidEventSeen: false, homeRaidWon: false,
    archiePartnerSeen: false, homeUnlocked: false, securityContactUnlocked: false,
  },
}
```

`enemy` in combat: `{ name, hp, hpMax, attackMin, attackMax, veinId:String|null, isMugging:bool }` — note: store `veinId`, not an object reference (state purity).

**Note on the prototype's `onWin`:** the HTML stored a global function name and called `window[c.onWin]()`. In Godot, `onWin` is a String enum (`"muggingWon"`, `"raidWon"`, `null`) dispatched by a `match` inside `combat.gd`. Never store Callables in state.

### 2.1 Vein dict
```
{ id, oreType, growth:int, security:"none", alarmUpgrades:[String],
  location:String, claimedOnDay:int,
  district:String,
  hospitability: {tier:String, bonuses:[String]},   # M1; M0 default {tier:"fair", bonuses:[]}
  rampantDays:int }                 # vein-growth-state; consecutive daily ticks spent at the ceiling
```
`growth` (0..ceiling(vein), neutral 50) replaces the old `devBar`/`level`/`levelLabel`/`charged`/`chargeBlocks` quartet entirely — see §1.2. A faction vein (`site.factionVein`) carries the same fields plus `factionId`.

### 2.2 Screens
M0 roster (original): `title, intro, home, veins, inventory, crafting, contacts, sms_archie, sms_archie_2, world, property, factions, barometer, stats, save, combat, event` (M0-T13 replaces the per-event screens with one generic `event` screen driven by `state.event`). Later M1 tickets (04 Map, 06 HQ, 07 Phone) redistribute their content into the D4 tabs below and retire the ones D4 says to delete. **Ticket 06 (HQ merge) is done:** `property` and `crafting` are deleted (no `SCREEN_SCRIPTS` entry, no remaining `Nav.go_to` call sites) — their functionality lives under `hq`. **Ticket 07 (Phone reskin + Ticker) is done:** `world`, `barometer`, `stats`, `save` are all deleted — `world`/`barometer` (the latter unreachable already; nothing linked to it once `world` was gone) live on as `phone`'s Ticker app, `stats`/`save` (also unreachable — no `Nav.go_to` call site) live on merged into `you`. `veins, contacts, factions` remain wired into the tutorial-era `home` flow (event `set_screen` effects still target `contacts`) and are still slated for retirement by ticket 10 (tutorial gating) — Phone's own contact list/faction directory (below) are new, parallel content for the post-tutorial nav shell, not a redirect of those screens' nav paths. (Ticket 11, phone-as-OS-shell, further retires `you`, `bag`, and `inventory` — see below.)

M1 D4, as amended by ticket 11 (phone-as-OS-shell), makes the nav bar a **3-slot dock** — `phone, map, hq` — which **supersedes** both the M0 bottom nav (`Home · Inventory · Craft · World · Contacts`) and the interim 5-tab bar ticket 07 shipped (`Map · HQ · Phone · Bag · You`). `map` is ticket 04's `MapScreen` (district list -> district panel -> site/vein sheet, `state.mapNav`-driven, per D4's "Map tab" section); `hq` is ticket 06's `HqScreen` — tier/security/rooms/stored-ore/tier-upgrade (old `property`), recipes/devices as "the workbench" (old `crafting`), a gym placeholder, and assigned-contact UI for the `lab`/`veinStation` rooms (`Contacts.assign_to_room`, previously unreachable from any screen). `phone` is ticket 07's `PhoneScreen`, promoted by ticket 11 into the game's **home screen**: `home` now resolves to the phone app grid rather than a separate screen id. The grid holds an icon+label tile per app — including locked ones, greyed with a padlock overlay, always in their permanent slot — and launches: Messages (contact list + SMS-thread/James-job triggers, reskinned from old `contacts`), Notes (`Todo.get_items()`), Factions (directory, reskinned from old `factions`), Ticker (D4.5 — three headline cards → axis detail with push/pull + greyed M4 influence actions, `state.phoneNav.selectedAxis`-driven, `data/barometer.json`'s per-state `headlines` array), plus three apps ticket 11 adds: **Profile** (HP/attack range, crafting/cultivating skill+XP, read-only equipped-weapon/device summary — cash/day and the ops-style veins-held/ore-in-stock summary are deliberately left off since the top bar and bag drawer already cover them), **Notifications** (full read-only log, newest first), and **Save/Load** (all three save slots — save/load/delete each — export, import, confirmation-gated New Game). bugfixes-38 adds an eighth app, **Reynard's** (`"bank"`) — a display-only cash balance + transaction log (`state.bankLog`, §2), read-only and newest-first like Notifications; no interest, loans, or transfers. `you`, `bag`, and `inventory` are retired screen ids: `you`'s content (HP/attack/cash/day, skills+XP, equipped-weapon/device summary, ops summary, save/load/export/import/new-game) splits across Profile/Notifications/Save-Load above, minus cash/day and the ops summary which are dropped rather than carried over; `bag`'s functionality (equip/unequip weapon and device, device start/build-attempt/abandon, plus the read-only ore/consumable/charge view) moves entirely into the global `BagDrawer` (D4.4), reachable from any screen with no dedicated tab; `inventory`, the screen script `bag` used to alias, is deleted once `BagDrawer` absorbs its management actions. `Nav.go_to("home")` resolves to the phone app grid, and the retired ids (`you`, `bag`, `inventory`, and any save with a stale `home`-era screen) all fall back to the app grid rather than `title`, so old saves never soft-lock.

The dock (`NavBar`, now 3 slots: Phone · Map · HQ) is hidden on `title, intro, event, combat` (unchanged from M0). Phone is a home button: tapping it returns to the app grid from any screen, and no-ops when already on the grid. A separate persistent top bar (`TopBar`, D4: cash · day/time-blocks · bag button) is shown on every screen except `title, intro` — it stays up through `event` and `combat` so the bag button keeps working there (D4.4). The bag button opens the global `BagDrawer` bottom sheet via `state.bagDrawerOpen` (`Bag.open()`/`Bag.close()`), independent of screen navigation and of `state.modal`.

---

## 3. FORMULAS & SYSTEM RULES

### 3.1 Time, rest, daily tick
- 3 blocks/day. `advanceTimeBlock()`: append current block to `timeBlocksDone`, increment `timeBlock`; if `timeBlock >= 3` → `day += 1`, `timeBlock = 0`, `timeBlocksDone = []`, run `daily_tick()`.
- `isTimeExhausted()` = `timeBlocksDone.size() >= 3`.
- **Rest:** consume all remaining blocks, roll to next day (runs daily_tick), then heal `round(hpMax * 0.2)` capped at hpMax. Notification: "Rested. Day N. +X HP."
- **daily_tick order (exact):** ① tick barometer ② roll home raid ③ living costs: `DAILY_COST = round(50 * (1 + fx.dailyCost))`, `cash = max(0, cash − DAILY_COST)`, notification (append " You are flat broke." if cash hits 0) ④ vein growth drift (`Cultivating.drift_veins()`, vein-growth-state §2.3): for each player vein and each faction vein, `delta = band_drift(growth)`, `direction = +1 if growth>50, -1 if growth<50, 0 if dormant`, `growth = clamp(growth + delta*direction, 0, ceiling(vein))`; a vein pinned at 0 then rolls `collapseChancePerDay` (0.15) to be removed (site reverts to unclaimed for a player vein, deleted outright for a faction vein) ⑤ tutorial day-triggers (day ≥ 2 & stage "buyer_event" & !buyerEventSeen → notification "Archie texted. He's lined up the new buyer. Check Contacts."; stage "archie_craft_chat" & day ≥ archieChatUnlockDay → notification "Archie wants to meet up. Check Contacts.") ⑥ process lab room, then veinStation room, if installed ⑦ reset device charges (chargesUsedToday = 0 where lastResetDay < day).

### 3.2 Barometer
- Progress model: per section, per state, an integer 0–100. Init: active state = 100, others 0. Cooldowns: per section+state, `{push:day, pull:day}`.
- **Daily faction nudges:** for every faction (regardless of membership), each pref adds (`push`) or subtracts (`pull`) `strength` to that state's progress, clamped 0–100.
- **Organic drift:** each non-active state, `chance(0.20)` → +1 progress (cap 99).
- **Resolution (per section, after nudges and after drift):** clamp all to 0–100; if any non-active state ≥ 100 → old active drops to 0, that state becomes active at 100, notification "<Section> shift: <Label>. <description>".
- **Manual push/pull (already functional in M0):** costs £2000; per-state per-direction cooldown of 1/day (blocked if `day <= cooldown value`); push adds +20 then resolves; pull subtracts 20 (no resolve).
- **Merged effects:** sum `effects` dicts of the three active states. `getEffectiveMugChance(base) = clamp(base + fx.mugChance, 0, 0.8)`. `getEffectiveOrePrice(type, base) = round(base * max(0.1, 1 + fx.orePrice + fx.<type>Premium))`.

### 3.3 Home
- `getHomeRaidChance() = max(0.002, tier.raidBaseChance + fx.homeRaid − Σ installed raidReduction + totalCarriedOre * 0.001)`, where `totalCarriedOre` is the sum of `player.orichalchum` (see storedOre merge note in §2).
- Raid roll (in daily tick): skip if `day − lastRaidDay < 3`; on hit set `lastRaidDay = day`; if carried ore total is 0, nothing; else lose `floor(qty * ratio)` per type from `player.orichalchum`, ratio 0.50 (0.25 with safeRoom). Notification with units lost.
- Upgrades/rooms: enforce cash, slot caps, minTier by tier order. Room `body` bonus applies immediately: `hpMax += 10`, `hp = min(hp + 10, hpMax)`. `workshopBonus` = Σ bonusValue of installed rooms with bonus == "crafting".

### 3.4 Cultivating & pruning
- `cultChance = min(0.90, 0.30 + (skill−1) * 0.12)` (unchanged by vein-growth-state).
- **Seed(siteId):** requires ore ≥ 40 (of the site's ore type) and time not exhausted. Spend 1 block, deduct 40 ore ALWAYS. `chance(seedSuccessChance)` → new vein at `growth = seedGrowth` (20), security none, random location, claimedOnDay = today, district = currentDistrict) + 30 XP; fail → 5 XP. Result modal either way. A `hasNaturalVein` site's claim instantly grants a second free vein of the site's ore type, also at `growth = 20`.
- **Cultivate(vein):** 1 block. `chance(cultChance)` → success: `growth += cultivate_gain(skill, growth, ceiling(vein))` where `cultivate_gain = max(2, round((10 + 4*skill) * (1 − growth/ceiling)))`, clamped to `[0, ceiling(vein)]`, +20 XP. Fail → no change, +8 XP. Result modal either way.
- **Prune(vein, depth):** 1 block. `depth` is `pruneLightDepth` (15) or `pruneHardDepth` (40). `points = max(0, growth_before−50) − max(0, growth_after−50)` where `growth_after = max(0, growth_before − depth)`; `yield = round(points * yieldPerPoint(0.35) * terroirYieldMult(vein.hospitability.tier) * hardBonus)` (hardBonus 1.25 for a hard prune, 1.0 for light), then `apply_yield_bonus`. Pruning at or below neutral (50) always yields 0. No cultivating XP awarded (matches the harvest schedule this replaces).
- **Left wall (collapse):** `growth` pins at 0. Each daily tick a vein sits at 0, `chance(collapseChancePerDay)` (0.15) removes it: a player vein's site reverts to unclaimed; a faction vein's site is deleted outright (matches NPC abandonment). Still cultivable at the maximum gain while pinned at 0.
- **Right wall (rampant/self-seed):** `growth` clamps at `ceiling(vein)`. `rampantDays` increments each daily tick spent at the ceiling; at `rampantSeedDays` (5), claims an unclaimed site in the same district for a new player vein at `growth = selfSeedGrowth` (60) — see vein-growth-state ticket 02. Faction veins never self-seed.
- `value_tier(vein) = min(6, 1 + floor(growth/20))` — the 1–6 magnitude that replaces the old 1–5 `level` everywhere a vein's value/strength matters.
- XP level-up loop: while skill < 5 and XP ≥ table[skill+1] → skill += 1 (notification for cultivating).

### 3.5 Crafting & devices
- `craftChance(r) = min(0.95, r.baseSuccess + (skill−1) * 0.13 + workshopBonus)`.
- `calcCost(r) = { oreType: max(1, round(baseCalcCost − (skill−1) * 0.8)) for oreType, baseCalcCost in r.ingredients }` — computed independently per ingredient key.
- `effectPower(r) = r.effectPower[skill]`.
- **attemptCraft:** requires cost in each ingredient type; deduct ALL ingredients ALWAYS; success → +1 item, full XP; fail → `floor(xp/3)`. Result modal.
- **Devices:** build cost per attempt = `2 × calcCost(recipe)[device.calcType]` — the device's calcType selects one entry from the recipe's per-ingredient cost dict. Start at progress 10. Each attempt: deduct cost, award `floor(recipeXP/2)` crafting XP, then success (same craftChance) → progress +5 (at ≥100: completed instance `{level:1, xp:0, chargesPerDay:1, chargesUsedToday:0, lastResetDay:day}`); fail → progress −2.5 (at ≤0: device breaks, notification). Device XP: +10 per activation; level-ups per DEVICE_XP_LEVELS grant +1 chargesPerDay.
- **Device activation in combat:** freeze → `frozenTurns += effectPower(timePearl at player skill)`; motion → `motionTurns += 2`, `motionPower = effectPower(enhancementPowder)`; rewind → per §3.9.

### 3.6 Selling (Archie lane)
- Sell menu covers ore (all 5 types, at effective price) and consumables at CONSUMABLE_PRICES (gated by `canSellConsumables`).
- `gross` = Σ price×qty; deduct goods; player cut = `floor(gross * 0.5)`.
- Consumables-sold counter: first ever consumable sale (and !archieMotionEventSeen) → set `archieMotionPending = true` + notification "Archie texted. Check Contacts."
- Mugging roll: `chance(getEffectiveMugChance(0.20))` → stash cut in `pendingSaleCut`, start mugging combat; on win, pay out cut and show sale result (mugged:true). No mug → pay immediately, sale result modal.

### 3.7 Combat (M0 port — pre-intent system)
- Muggers: `count = rand(1,3)`; hp `28 × count`; atk `4 + 2(count−1)` to `10 + 3(count−1)`; name "A mugger" / "N muggers".
- Vein-raid enemy (attacking an NPC-claimed vein): template scaled `hp = round(hpBase × (1 + (veinLevel−1)×0.3) × guards)`, atkMax `+ (veinLevel−1)`. (Reachable in M0 only via debug; keep functions.)
- `getAttackRange()` = player atk + equipped weapon bonus.
- **Player attack turn:** push combat snapshot first (§3.9). Attacks this turn: 1, or with motionTurns > 0: `motionPower ≥ 3 ? 3 : 2` (log line). Each hit: first `chance(enemy.evadeChance)` (§1.10) → enemy dodges, no damage, log, next hit; else `dmg = rand(atkMin, atkMax)`; enemy hp −= dmg; log "You attack — X damage. Enemy: h/H HP." Enemy at 0 → outcome "win", dispatch onWin. After attacks: motionTurns −= 1 if active (log expiry at 0); enemy.ability.lockedTurns −= 1 if locked (log at 0, "back online" — see `Combat.disarm_enemy`, §1.10); frozenTurns > 0 → −1 (log expiry at 0) and enemy skips; else enemy attacks.
- **Enemy attack:** if evadeTurns > 0: decrement; `chance(evadeChance)` → miss (log), return. Else `dmg = rand(enemy atk range)`, where enemy atk range is atkMin/atkMax plus the enemy's equipped `weapon` bonus if any (§1.10); if `player.shieldPool > 0` (calc-effect-wiring-02), absorb 1:1 first (`absorbed = min(dmg, shieldPool)`, `shieldPool -= absorbed`, `dmg -= absorbed`) before applying the remainder; player hp −= dmg; at 0 → outcome "loss", log, revive `hp = round(hpMax * 0.3)`.
- **Flee:** `chance(0.65)` → outcome "fled"; else enemy gets a free attack. calc-effect-wiring-02: Blast's flee boost (below) raises this to `chance(0.90)` for exactly one attempt, then clears regardless of outcome.
- **Use Time Pearl:** blocked if frozenTurns > 0 ("Already frozen. Save the pearl."); consume; `frozenTurns = effectPower`.
- **Use Enhancement Powder:** blocked if motionTurns > 0; consume; `motionPower = effectPower`; `motionTurns = power ≥ 3 ? 2 : 1`.
- **Use Blast** (calc-effect-wiring-02): consume; deal `effectPower(skill)` damage to the enemy immediately (can win the fight outright); grant a one-use flee boost (see Flee, above); 15% chance to call `Combat.disarm_enemy(enemy, 2)` (§1.10).
- **Use Shield** (calc-effect-wiring-02): blocked if `player.shieldPool > 0` ("Shield's already up. Save it."); consume; `player.shieldPool = effectPower(skill)` — no turn cap, drained by enemy attacks above.
- **Use Black Hole** (calc-effect-wiring-02): consume; deal `effectPower(skill)` damage to the enemy immediately (can win the fight outright); `frozenTurns += 1 + floor(effectPower(skill) / 8)` — always additive, no reuse guard, stacks with Time Pearl or a prior Black Hole.
- **Use Healing Burst** (`Consumables.use_healing_burst()`, calc-effect-wiring-02): usable in or out of combat; consume; `hp = min(hp + effectPower(skill), hpMax)`; result line goes to the combat log if a fight is active, else a Notify push.
- **Use Healing Salve** (`Consumables.use_healing_salve()`, calc-effect-wiring-02, out-of-combat only): consume; `healingSalveDaysLeft = 2`, `healingSalveDailyAmount = effectPower(skill)` — reusing while already active refreshes both rather than stacking. Ticked in `TimeSystem.daily_tick()` (§3.1): while `daysLeft > 0`, heal `dailyAmount` HP (capped at hpMax) and decrement `daysLeft`.
- **onWin dispatch:** "muggingWon" → pay `pendingSaleCut`, sale result modal. "raidWon" → transfer vein to player. Exit combat: mugging-win keeps the sale modal; context "home_raid" → debrief flow; else → inventory (raid win) / home.

### 3.8 Home-raid event chain
Trigger: `homeRaidEventPending` true → on next visit to HQ, launch. Flow: intro event (3 cards) → combat vs raider (hp 35, atk 6–14, context "home_raid") → debrief event (WIN or LOSS variant). Loss additionally: carried `orichalchum` halved (floor) — this used to also separately halve a `storedOre` pool, but that field was merged into `orichalchum` (§2's storedOre merge note), so there is only the one pool to lose now. Debrief completion (both variants): `homeRaidEventSeen = true`, `homeRaidWon` per outcome, `archiePartnerSeen = true`, `homeUnlocked = true`, `securityContactUnlocked = true`, archie relation +10, grant a vein (time-type, Lv1, devBar 0, uncharged, security none, district "whitechapel", location "Whitechapel, behind the old brewery", claimedOnDay = today), notification "HQ's workbench is open now." (now that `homeUnlocked` is genuinely true), → home.

### 3.9 Snapshots & Rewind (engine foundation)
- `Snapshots.gd`: `push(stack_id, deep_copy_of_state_subset)`, bounded stacks.
- **Combat rewind:** snapshot at the start of every player attack turn: `{playerHp, enemyHp, log(copy), frozenTurns, motionTurns, motionPower, evadeTurns, evadeChance}`; keep max 2. Using Rewind (consumable, or equipped rewind device with charges): consume; restore the OLDEST snapshot; clear stack; append log "⟲ Time unspools. The moment resets. Only you remember."; `outcome = null`; grant `evadeTurns = 2, evadeChance = 0.50`.
- **Event rewind:** the event runner snapshots full `state` before applying each card's effects; Rewind pops one card-frame (M0-T13).

### 3.10 Contacts, rooms, jobs
- `awardRelation(id, n)`. Recruit at threshold: sets recruited, notification, assignable to rooms (one contact per room; assigning vacates).
- **Lab (daily):** contact in lab crafts each unlocked recipe up to `labThresholds[recipe]` inventory target, using the CONTACT's skill in the §3.5 formulas (workshopBonus included), consuming player ore, awarding contact XP (full/⅓).
- **veinStation (daily, hold-at-target — vein-growth-state §6.1):** each vein in `veinStationVeins` holds a companion target in `veinStationTargets[veinId]` (default 70 on assignment). Per marked vein: if `growth > target + 5` → contact prunes down to the target (§2.4 yield formula, ore into player ore, +15 contact cultivating XP); if `growth < target - 5` → one cultivate roll at the contact's own skill (success +20 XP, fail +8 XP); otherwise no-op. Summary notification.
- **James jobs** (unlocked by jamesMotionEventSeen): one active at a time, offered proactively by the daily-tick roll (§1.11) rather than player-requested — no "ask for work" action exists. Type-1 (flatPay): accept, then fulfil consumes one time block and pays `pay` flat, james relation +5. Type-2 (craft, recipe pool: timePearl, + enhancementPowder if unlocked, per §1.11's trust bands): fulfil requires qty in inventory; deduct, pay totalPay, james relation +5, clear job. Both: `jamesJobAccepted` tracks accept vs. still-just-offered, separately from `jamesJobActive`.

### 3.11 Tutorial flow (as actually implemented — the merged flow)
1. **Intro event** (INTRO_CARDS). Complete → `metArchie = true`, stage "buyer_event", → home.
2. Day ≥ 2 daily tick fires the buyer notification. Contacts screen shows the buyer action → **SMS thread 2** (`sms_archie_2`, ARCHIE_SMS_2, staged message reveal) → **Buyer event** (BUYER_CARDS). Complete → cash +40, `buyerEventSeen`, stage "sms_archie".
3. **SMS thread 1** (ARCHIE_SMS_1) → **James meeting event** (JAMES_CARDS — this event includes the crafting lesson). Complete → inventory.timePearl += 2, `metJames`, `craftingUnlocked`, james unlocked, james relation +10, stage "archie_craft_chat", `archieChatUnlockDay = day + 1`, → home. No notification and no navigation to the crafting/HQ screen here — `homeUnlocked` (the HQ screen's own gate) isn't true yet at this point in the tutorial, so the HQ nudge waits for the home-raid debrief (§3.8) instead.
   *(The HTML's separate `JAMES_CRAFT_CARDS` array is dead/unreachable content. DO NOT PORT.)*
4. Next day: notification → **Archie falafel chat** (ARCHIE_CRAFT_CHAT_CARDS). Complete → `archieCraftChatSeen`, `canSellConsumables`, stage "free", archie relation +5, +20 time ore, `homeRaidEventPending = true`.
5. **Home raid chain** per §3.8. Then free play.
6. Post-tutorial: first consumable sale → `archieMotionPending` → **Archie motion event** (ARCHIE_MOTION_CARDS; sets archieMotionEventSeen) → **James motion event** (JAMES_MOTION_CARDS; sets jamesMotionEventSeen, `enhancementUnlocked`, james relation +1). James jobs then available on the contacts screen.
- Home-screen to-do list: port `getTodoItems()` logic verbatim (flag-driven checklist, show last 4).

---

## 4. DESIGN TOKENS (Godot Theme)

--ink #1a1a1a · --paper #f0ece2 · --amber #c8873a · --slate #4a5568 · --muted #8a8a8a · --danger #9b2335 · --success #3a7a52 · --card-bg #faf8f3 · --border #d4cfc4. Body font: a bundled serif (e.g. Source Serif); UI font: a bundled sans (e.g. Inter). Layout: portrait, content column max 390 logical px, bottom nav bar fixed.

---

## 5. DEBUG START (title screen button)
£1,000,000; all flags of §2 set complete/true (stage "free"); 3 veins covering the growth model's distinct visual states — one `collapsed` (growth 0), one `dormant` (growth 50), one `rampant` (growth 100) — so every band is inspectable immediately without waiting out drift (vein-growth-state ticket 10 lands the exact values); 20 units of each of the 5 ore types; 5 timePearl, 3 enhancementPowder, 1 rewind; crafting skill 3, cultivating 2; townhouse + workshop + homeGym + lock + cameras; archie relation 60, james relation 40 (both unlocked); guild joined, collective 25, firm 15; barometer economic=boom, social=stable, political=war; crowbar owned and equipped; `homeRaidEventPending = true`.

---

## 6. SAVE FORMAT
JSON of the whole `state` tree. `meta.saveVersion` is 2 (bumped from 1 by vein-growth-state — the vein dict shape changed, and save-breaking was accepted rather than writing a migrator). `SaveManager`: 3 manual slots + 3 rotating autosaves (written on: daily tick, combat exit, event completion, any purchase), plus export/import as a JSON string shown in a copyable text box. Loading checks `meta.saveVersion` against the current `SAVE_VERSION` and rejects a mismatch outright with a clear reason (no half-load, no migrator); a save with no `meta.saveVersion` at all is treated as the current version. A version match then validates required top-level keys and fills missing keys from defaults.

---

## 7. MIGRATION NOTES (old roster → new, applied at port time)
Everywhere in extracted prose or ported logic: `energy`→delete, `motion`→`physics`, `void`→`fate` (mechanics) — EXCEPT engineerCrisis's ore cost which is `emotion` (§1.9). `motionPowder`→`enhancementPowder` ("Enhancement Powder", life-type ingredient). `motionDevice`→`enhancementDevice`. Flag `motionPowderUnlocked`→`enhancementUnlocked`. In prose: "Motion calc, forty units" → "Physics calc, forty units"; "Motion powder. It's straightforward. Motion orichalchum," → "Enhancement powder. It's straightforward. Life orichalchum," (see CONTENT-GUIDE.md patch list). Combat state field names `motionTurns`/`motionPower` are retained as internal names.
