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

### 1.2 `data/vein_levels.json`
Keys are strings "1".."6". Level 6 exists ONLY via the M1 Rich/Saturated "+1 max level" hospitability bonus; normal cap is 5.

| lvl | label | yieldCautious | yieldFull | rechargeBlocks | devBarMax | devBarHarvestCost |
|---|---|---|---|---|---|---|
| 1 | Trace | [1,2] | [3,5] | 4 | 8 | 2 |
| 2 | Minor | [2,4] | [6,10] | 3 | 16 | 3 |
| 3 | Moderate | [4,7] | [10,16] | 3 | 24 | 4 |
| 4 | Rich | [7,12] | [16,24] | 2 | 36 | 5 |
| 5 | Lode | [12,20] | [24,40] | 2 | 9999 | 6 |
| 6 | Deep | [18,28] | [36,60] | 1 | 9999 | 8 |

There is NO vein lifespan/expiry mechanic. (The prototype referenced `lifespanDays` but never defined it; it never fired. Officially dropped — veins die only via dev-bar decay, §3.4.)

Other cultivating constants: `SEED_ORE_COST = 40`. `CULTIVATING_XP_LEVELS = [0, 0, 80, 220, 500, 1000]` (index = level; max level 5).

### 1.3 `data/recipes.json`

| key | name | symbol | ingredient | baseSuccess | baseCalcCost | effectPower (index=skill 0–5) | xpReward | eventUsable |
|---|---|---|---|---|---|---|---|---|
| timePearl | Time Pearl | ⧖ | time | 0.40 | 5 | [0,1,1,2,2,3] (frozen turns) | 20 | false |
| enhancementPowder | Enhancement Powder | ↯ | life | 0.35 | 6 | [0,1,1,2,2,3] (see combat §3.8) | 25 | false |
| rewind | Rewind | ⟲ | time | 0.40 | 6 | [0,2,2,2,2,2] (turns rewound) | 35 | true |

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

**Tiers** (order matters — it is the upgrade ladder):

| id | name | tier | upgradeCost | dailyCost | raidBaseChance | maxSecuritySlots | maxRooms |
|---|---|---|---|---|---|---|---|
| bedsit | Bedsit | 1 | 0 | 50 | 0.08 | 1 | 0 |
| flat | Flat | 2 | 1200 | 80 | 0.06 | 2 | 1 |
| townhouse | Townhouse | 3 | 4000 | 150 | 0.04 | 3 | 3 |
| safehouse | Safehouse | 4 | 12000 | 300 | 0.02 | 4 | 5 |
| compound | Compound | 5 | 40000 | 600 | 0.01 | 5 | 8 |
| mansion | Mansion & Grounds | 6 | 150000 | 1500 | 0.005 | 6 | 12 |

Tier descriptions: extract verbatim from HTML const `HOME_TIERS`.

**Security upgrades** (each installable once; cost ×0.7 rounded when flag `securityContactUnlocked` is true):

| id | name | cost | raidReduction |
|---|---|---|---|
| lock | Reinforced Lock | 80 | 0.02 |
| cameras | CCTV | 250 | 0.03 |
| reinforcedDoor | Reinforced Door | 600 | 0.04 |
| alarm | Alarm System | 400 | 0.03 |
| guard | Hired Guard | 1200 | 0.05 |
| ward | Orichalchum Ward | 2000 | 0.06 |

**Rooms:**

| id | name | cost | minTier | bonus | bonusValue |
|---|---|---|---|---|---|
| workshop | Workshop | 800 | flat | crafting | 0.08 |
| homeGym | Home Gym | 600 | flat | body | 10 |
| library | Library | 1200 | townhouse | crafting | 0.08 |
| safeRoom | Safe Room | 2000 | townhouse | storage | 0.5 |
| ops | Operations Room | 5000 | safehouse | faction | 1 |
| veinStation | Vein Cultivation Station | 8000 | safehouse | passive | 1 |
| lab | Lab | 15000 | compound | crafting | 0.12 |

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

### 1.11 Misc constants
`TIME_BLOCKS = ["Morning","Afternoon","Evening"]` · `ARCHIE_ORE_GOAL = 10` · contacts: archie {startRelation:10, unlocked:true, recruitThreshold:80}, james {startRelation:0, unlocked:false, recruitThreshold:100} · James job trust→qty bands: relation ≤1 → 1–3; ≤3 → 3–6; else 5–10; payPerItem = CONSUMABLE_PRICES[recipe].

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
  notifications: [],          # [{ id:String, text:String }]
  sellState: {},              # sell-menu qty selections, transient
  event: null,                # M0-T13 event runner state: { eventId, cardIndex, snapshots:[] } | null

  player: {
    cash: 40,
    hp: 100, hpMax: 100,
    attackMin: 5, attackMax: 12,
    orichalchum: {},          # { oreType: int }
    veins: [],                # vein dicts, §2.1
    inventory: { timePearl: 0, enhancementPowder: 0, rewind: 0 },
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

  jamesJob: null,             # { recipeKey, recipeName, symbol, qty, payPerItem, totalPay } | null
  pendingSaleCut: 0,
  labThresholds: {},          # { recipeKey: int }
  veinStationVeins: [],       # [veinId]

  flags: {
    tutorialStage: "intro",   # intro|buyer_event|sms_archie|meet_james|archie_craft_chat|free
    metArchie: false, metJames: false, buyerEventSeen: false,
    craftingUnlocked: false, archieCraftChatSeen: false,
    canSellConsumables: false, consSoldCount: 0,
    archieMotionPending: false, archieMotionEventSeen: false,
    jamesMotionEventSeen: false, enhancementUnlocked: false,
    jamesJobActive: false,
    homeRaidEventPending: false, homeRaidEventSeen: false, homeRaidWon: false,
    archiePartnerSeen: false, homeUnlocked: false, securityContactUnlocked: false,
  },
}
```

`enemy` in combat: `{ name, hp, hpMax, attackMin, attackMax, veinId:String|null, isMugging:bool }` — note: store `veinId`, not an object reference (state purity).

**Note on the prototype's `onWin`:** the HTML stored a global function name and called `window[c.onWin]()`. In Godot, `onWin` is a String enum (`"muggingWon"`, `"raidWon"`, `null`) dispatched by a `match` inside `combat.gd`. Never store Callables in state.

### 2.1 Vein dict
```
{ id, oreType, level:int, levelLabel, devBar:int, charged:bool, chargeBlocks:int,
  security:"none", location:String, claimedOnDay:int,
  district:String,                  # M1
  hospitability: {tier:String, bonuses:[String]} }   # M1; M0 default {tier:"fair", bonuses:[]}
```

### 2.2 Screens
M0 roster (original): `title, intro, home, veins, inventory, crafting, contacts, sms_archie, sms_archie_2, world, property, factions, barometer, stats, save, combat, event` (M0-T13 replaces the per-event screens with one generic `event` screen driven by `state.event`). Later M1 tickets (04 Map, 06 HQ, 07 Phone) redistribute their content into the D4 tabs below and retire the ones D4 says to delete. **Ticket 06 (HQ merge) is done:** `property` and `crafting` are deleted (no `SCREEN_SCRIPTS` entry, no remaining `Nav.go_to` call sites) — their functionality lives under `hq`. `veins, world, factions, barometer` remain wired but are still slated for retirement by tickets 04/07.

M1 D4 adds 5 nav-tab screen ids — `map, hq, phone, bag, you` — which **supersede the M0 bottom nav** (`Home · Inventory · Craft · World · Contacts` → `Map · HQ · Phone · Bag · You`). `phone, you` are still stub screens (`PlaceholderScreen`) until ticket 07 builds them out; `map` is ticket 04's `MapScreen` (district list -> district panel -> site/vein sheet, `state.mapNav`-driven, per D4's "Map tab" section); `hq` is ticket 06's `HqScreen` — tier/security/rooms/stored-ore/tier-upgrade (old `property`), recipes/devices as "the workbench" (old `crafting`), a gym placeholder, and assigned-contact UI for the `lab`/`veinStation` rooms (`Contacts.assign_to_room`, previously unreachable from any screen); `bag` is fully functional — it's the existing `inventory` screen (ore/consumables/equipment/devices) registered under a second screen id, per D4's "Bag — full inventory management." The M0 `inventory` screen id is unchanged and still used by its existing call sites (raid-win routing, `home`'s Inventory button) — `bag` and `inventory` are two ids pointing at the same screen script, not a rename.

Tab bar (`NavBar`) hidden on `title, intro, event, combat` (unchanged from M0). A separate persistent top bar (`TopBar`, D4: cash · day/time-blocks · bag button) is shown on every screen except `title, intro` — it stays up through `event` and `combat` so the bag button keeps working there (D4.4). The bag button opens the global `BagDrawer` bottom sheet via `state.bagDrawerOpen` (`Bag.open()`/`Bag.close()`), independent of screen navigation and of `state.modal`.

---

## 3. FORMULAS & SYSTEM RULES

### 3.1 Time, rest, daily tick
- 3 blocks/day. `advanceTimeBlock()`: append current block to `timeBlocksDone`, increment `timeBlock`; if `timeBlock >= 3` → `day += 1`, `timeBlock = 0`, `timeBlocksDone = []`, run `daily_tick()`.
- `isTimeExhausted()` = `timeBlocksDone.size() >= 3`.
- **Rest:** consume all remaining blocks, roll to next day (runs daily_tick), then heal `round(hpMax * 0.2)` capped at hpMax. Notification: "Rested. Day N. +X HP."
- **daily_tick order (exact):** ① tick barometer ② roll home raid ③ living costs: `DAILY_COST = round(50 * (1 + fx.dailyCost))`, `cash = max(0, cash − DAILY_COST)`, notification (append " You are flat broke." if cash hits 0) ④ vein recharge: for each vein, if `chargeBlocks < rechargeBlocks(level)` then `chargeBlocks += 1`; if `chargeBlocks >= rechargeBlocks` then `charged = true` ⑤ tutorial day-triggers (day ≥ 2 & stage "buyer_event" & !buyerEventSeen → notification "Archie texted. He's lined up the new buyer. Check Contacts."; stage "archie_craft_chat" & day ≥ archieChatUnlockDay → notification "Archie wants to meet up. Check Contacts.") ⑥ process lab room, then veinStation room, if installed ⑦ reset device charges (chargesUsedToday = 0 where lastResetDay < day).

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

### 3.4 Cultivating & harvest
- `cultChance = min(0.90, 0.30 + (skill−1) * 0.12)` · `barGain = 1 + skill`.
- **Seed(oreType):** requires ore ≥ 40 and time not exhausted. Spend 1 block, deduct 40 ore ALWAYS. `chance(cultChance)` → new Lv1 vein (devBar = barGain, uncharged, security none, random location, claimedOnDay = today, district = currentDistrict) + 30 XP; fail → 5 XP. Result modal either way.
- **Cultivate(vein):** 1 block. Success → devBar += barGain, +20 XP; if level < cap and devBar ≥ devBarMax → level up (level+1, devBar = 0). Fail → +8 XP. (Level cap is 5, or 6 if hospitability bonuses include "maxLevel" — M1.)
- **Level down:** at Lv1 → vein removed, notification "…collapsed and disappeared."; else level −1, `devBar = floor(newLevel.devBarMax * 0.8)`, notification.
- **Harvest cautious:** requires charged; 1 block; gain `rand(yieldCautious)`; `charged=false, chargeBlocks=0`.
- **Harvest full:** as above with `yieldFull`, then `devBar −= devBarHarvestCost`; if devBar ≤ 0 → level down.
- XP level-up loop: while skill < 5 and XP ≥ table[skill+1] → skill += 1 (notification for cultivating).

### 3.5 Crafting & devices
- `craftChance(r) = min(0.95, r.baseSuccess + (skill−1) * 0.13 + workshopBonus)`.
- `calcCost(r) = max(1, round(r.baseCalcCost − (skill−1) * 0.8))`.
- `effectPower(r) = r.effectPower[skill]`.
- **attemptCraft:** requires cost in the ingredient type; deduct ALWAYS; success → +1 item, full XP; fail → `floor(xp/3)`. Result modal.
- **Devices:** build cost per attempt = `2 × calcCost(recipe)` of the device's calcType. Start at progress 10. Each attempt: deduct cost, award `floor(recipeXP/2)` crafting XP, then success (same craftChance) → progress +5 (at ≥100: completed instance `{level:1, xp:0, chargesPerDay:1, chargesUsedToday:0, lastResetDay:day}`); fail → progress −2.5 (at ≤0: device breaks, notification). Device XP: +10 per activation; level-ups per DEVICE_XP_LEVELS grant +1 chargesPerDay.
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
- **Player attack turn:** push combat snapshot first (§3.9). Attacks this turn: 1, or with motionTurns > 0: `motionPower ≥ 3 ? 3 : 2` (log line). Each hit: `dmg = rand(atkMin, atkMax)`; enemy hp −= dmg; log "You attack — X damage. Enemy: h/H HP." Enemy at 0 → outcome "win", dispatch onWin. After attacks: motionTurns −= 1 if active (log expiry at 0); frozenTurns > 0 → −1 (log expiry at 0) and enemy skips; else enemy attacks.
- **Enemy attack:** if evadeTurns > 0: decrement; `chance(evadeChance)` → miss (log), return. Else `dmg = rand(enemy atk)`; player hp −= dmg; at 0 → outcome "loss", log, revive `hp = round(hpMax * 0.3)`.
- **Flee:** `chance(0.65)` → outcome "fled"; else enemy gets a free attack.
- **Use Time Pearl:** blocked if frozenTurns > 0 ("Already frozen. Save the pearl."); consume; `frozenTurns = effectPower`.
- **Use Enhancement Powder:** blocked if motionTurns > 0; consume; `motionPower = effectPower`; `motionTurns = power ≥ 3 ? 2 : 1`.
- **onWin dispatch:** "muggingWon" → pay `pendingSaleCut`, sale result modal. "raidWon" → transfer vein to player. Exit combat: mugging-win keeps the sale modal; context "home_raid" → debrief flow; else → inventory (raid win) / home.

### 3.8 Home-raid event chain
Trigger: `homeRaidEventPending` true → on next visit to home screen, launch. Flow: intro event (3 cards) → combat vs raider (hp 35, atk 6–14, context "home_raid") → debrief event (WIN or LOSS variant). Loss additionally: carried `orichalchum` halved (floor) — this used to also separately halve a `storedOre` pool, but that field was merged into `orichalchum` (§2's storedOre merge note), so there is only the one pool to lose now. Debrief completion (both variants): `homeRaidEventSeen = true`, `homeRaidWon` per outcome, `archiePartnerSeen = true`, `homeUnlocked = true`, `securityContactUnlocked = true`, archie relation +10, and grant a vein: time-type, Lv1, devBar 0, uncharged, security none, district "whitechapel", location "Whitechapel, behind the old brewery", claimedOnDay = today.

### 3.9 Snapshots & Rewind (engine foundation)
- `Snapshots.gd`: `push(stack_id, deep_copy_of_state_subset)`, bounded stacks.
- **Combat rewind:** snapshot at the start of every player attack turn: `{playerHp, enemyHp, log(copy), frozenTurns, motionTurns, motionPower, evadeTurns, evadeChance}`; keep max 2. Using Rewind (consumable, or equipped rewind device with charges): consume; restore the OLDEST snapshot; clear stack; append log "⟲ Time unspools. The moment resets. Only you remember."; `outcome = null`; grant `evadeTurns = 2, evadeChance = 0.50`.
- **Event rewind:** the event runner snapshots full `state` before applying each card's effects; Rewind pops one card-frame (M0-T13).

### 3.10 Contacts, rooms, jobs
- `awardRelation(id, n)`. Recruit at threshold: sets recruited, notification, assignable to rooms (one contact per room; assigning vacates).
- **Lab (daily):** contact in lab crafts each unlocked recipe up to `labThresholds[recipe]` inventory target, using the CONTACT's skill in the §3.5 formulas (workshopBonus included), consuming player ore, awarding contact XP (full/⅓).
- **veinStation (daily):** for each marked vein: if charged → cautious harvest into player ore, +15 contact cultivating XP; else cultivate roll with contact skill (success devBar += 1+skill, level-up check, +20 XP; fail +8 XP). Summary notification.
- **James jobs** (unlocked by jamesMotionEventSeen): one active at a time. Generate per §1.11 (recipe pool: timePearl, + enhancementPowder if unlocked). Fulfil: requires qty in inventory; deduct, pay totalPay, james relation +5, clear job.

### 3.11 Tutorial flow (as actually implemented — the merged flow)
1. **Intro event** (INTRO_CARDS). Complete → `metArchie = true`, stage "buyer_event", → home.
2. Day ≥ 2 daily tick fires the buyer notification. Contacts screen shows the buyer action → **SMS thread 2** (`sms_archie_2`, ARCHIE_SMS_2, staged message reveal) → **Buyer event** (BUYER_CARDS). Complete → cash +40, `buyerEventSeen`, stage "sms_archie".
3. **SMS thread 1** (ARCHIE_SMS_1) → **James meeting event** (JAMES_CARDS — this event includes the crafting lesson). Complete → inventory.timePearl += 2, `metJames`, `craftingUnlocked`, james unlocked, james relation +10, stage "archie_craft_chat", `archieChatUnlockDay = day + 1`, notification "Crafting unlocked. Try the Craft tab.", → crafting screen.
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
£1,000,000; all flags of §2 set complete/true (stage "free"); 3 veins: time Lv3, physics Lv1, life Lv5, devBars at 50% of level max, all charged; 20 units of each of the 5 ore types; 5 timePearl, 3 enhancementPowder, 1 rewind; crafting skill 3, cultivating 2; townhouse + workshop + homeGym + lock + cameras; archie relation 60, james relation 40 (both unlocked); guild joined, collective 25, firm 15; barometer economic=boom, social=stable, political=war; crowbar owned and equipped; `homeRaidEventPending = true`.

---

## 6. SAVE FORMAT
JSON of the whole `state` tree. `meta.saveVersion` starts at 1 (this project starts on the new ore roster — there is no migration #1). `SaveManager`: 3 manual slots + 3 rotating autosaves (written on: daily tick, combat exit, event completion, any purchase), plus export/import as a JSON string shown in a copyable text box. Loading runs `migrate(save)` — a version-keyed function table, currently identity for v1 — then validates required top-level keys and fills missing keys from defaults.

---

## 7. MIGRATION NOTES (old roster → new, applied at port time)
Everywhere in extracted prose or ported logic: `energy`→delete, `motion`→`physics`, `void`→`fate` (mechanics) — EXCEPT engineerCrisis's ore cost which is `emotion` (§1.9). `motionPowder`→`enhancementPowder` ("Enhancement Powder", life-type ingredient). `motionDevice`→`enhancementDevice`. Flag `motionPowderUnlocked`→`enhancementUnlocked`. In prose: "Motion calc, forty units" → "Physics calc, forty units"; "Motion powder. It's straightforward. Motion orichalchum," → "Enhancement powder. It's straightforward. Life orichalchum," (see CONTENT-GUIDE.md patch list). Combat state field names `motionTurns`/`motionPower` are retained as internal names.
