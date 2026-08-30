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

Other constants (`data/vein_growth.json`): `yieldPerPoint: 0.35`, `hardPruneBonus: 1.25`, `pruneLightDepth: 9`, `pruneHardDepth: 24`, `cultivateBase: 6`, `cultivatePerSkill: 2`, `cultivateMinGain: 1`, `collapseChancePerDay: 0.15`, `seedGrowth: 20`, `rampantSeedDays: 5`, `selfSeedGrowth: 60`, `wildCeilingBonus: 20`, `terroirYieldMult: { poor: 0.6, fair: 1.0, rich: 1.6, saturated: 2.4 }`.

**Cultivate** (`Cultivating.cultivate`): success roll unchanged (`cultChance = min(0.90, 0.30 + (skill-1)*0.12)`); on success, `growth += cultivate_gain(skill, growth, ceiling)` where `cultivate_gain = max(cultivateMinGain, round((cultivateBase + cultivatePerSkill*skill) * (1 - growth/ceiling)))` — diminishing toward the ceiling on purpose.

**Prune** (`Cultivating.prune(vein_id, depth)`, light -15 / hard -40): yield counts only growth points removed from above neutral — `points = max(0, growth_before-50) - max(0, growth_after-50)`, `yield = round(points * yieldPerPoint * terroir_yield_mult(vein) * hardBonus)` (hardBonus 1.25 for a hard prune, 1.0 for light), then `apply_yield_bonus`. Pruning at or below neutral always yields 0.

**Left wall**: `growth` pins at 0 (never negative); each daily tick, `chance(collapseChancePerDay)` removes the vein — a player vein's site reverts to unclaimed (re-seedable); a faction vein's site is deleted outright. This is the ONLY way a faction vein dies (bugfixes-73/adr/0004 removed the separate NPC-abandonment roll adr/0002 originally added — see §3.1's faction-vein-claim/growth bullet below).

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

`CRAFTING_XP_LEVELS = [0, 0, 80, 220, 500, 1000]`. `CONSUMABLE_PRICES` (ticket 80: all 14 craftable recipes are sellable) `= { timePearl: 120, enhancementPowder: 150, rewind: 210, healingSalve: 120, blast: 150, shield: 180, blackHole: 210, prophetsBreath: 180, beALady: 150, pansPrank: 180, healingBurst: 180, failsafe: 270, rejuvenation: 280, wormhole: 240 }`. **Needs balance sign-off** (ticket 80): the 12 new prices are `xpReward * 6` — the exact formula both pre-existing prices already satisfy (timePearl 20xp→120, enhancementPowder 25xp→150) — with one deliberate exception: `rejuvenation` (20xp, formula would give 120) is instead priced at 280, the highest of all 14, to honor its own flavor text ("Sells for more than anything else on this bench, which tells you who's buying it."). Flagging that override specifically, since it's the one price not derived from crafting cost/XP.

### 1.4 `data/dial.json`

**The Dial** (`.scratch/dial-device/spec.md`) is one rare, lifetime-owned instrument, seeded (not built on a progress bar) by a player with the narrative "gift" for orichalchum. It replaces the old single-slot device system outright (`data/devices.json`/`systems/devices.gd`/`DEVICE_XP_LEVELS`, deleted at dial-device ticket 07's cutover — a 3-entry table of `timeDevice`/`enhancementDevice`/`rewindDevice`, each mapping a `calcType`+`recipeKey` to a fixed `effect` of `freeze`/`motion`/`rewind`). Placeholder shape throughout, same undertuned-until-balance-pass status as every other number in this file.

**Seeding** (`Dial.attempt_seed(haftId)`) — single-roll risk model, same shape as `Sites.attempt_seed`: pay the full cost, roll once, fail = cost gone, no partial progress.

| field | value |
|---|---|
| seedCost | `{ time: 40, physics: 40, life: 80, fate: 40, emotion: 40 }` (mixed, life-weighted) |
| seedBaseSuccess | 0.30 (the craftChance-style term's `baseSuccess` stand-in — seeding has no recipeKey to draw one from) |
| baseMaxCharge | 20 (the charge-pool baseline `Dial._charge_stats_for()` starts from before applying the seated Movement's own bonus/downside curve) |
| baseRechargeRate | 2.0 |
| rechargeCombatRegenEveryTurns | 3 (tier-5 Recharge Movement's in-combat regen cadence, §3.5) |
| rechargeCombatRegenAmount | 1 |

`Dial.seed_success_chance() = clamp(((min(0.95, seedBaseSuccess + (craftingSkill−1)×0.13 + workshopBonus)) + Cultivating.get_cult_chance(cultivatingSkill)) / 2, 0.05, 0.95)` — the average of a craftChance-style term and the existing `cultChance` formula, per the PRD's "both skill investments matter" decision. Gated on `flags.dialGiftGranted` (set only by the Collective Act 2 quest, out of scope here); refused outright once `player.dial` is already non-null. Success seeds an inert Dial — level 1, zero charge/capacity-independent regen, no Movement — per §3.5; failure leaves `player.dial` null, cost still spent.

`hafts` — cosmetic-only display data (id → name), no stat fields, no code path reads one for anything but display (`PROSE-REVIEW`: display names are new, undrafted-by-a-human copy): Market Umbrella (`collective_brolly`), Service Baton (`firm_baton`), Malacca Cane (`guild_cane`), Monopod (`network_monopod`), Shepherd's Crook (`conclave_crook`), Scaffold Pole (`street_pole`). `Dial.set_haft()` writes `player.dial.haftId` with no validation beyond "haft exists".

**Movements** — one of four archetypes, crafted via `Dial.attempt_craft_movement(archetype, oreType)` through the same cost/chance/tier contract as `attemptCraft` (§3.5): ingredients (the chosen `oreType` alone) always spent, `Dial.movement_craft_chance()` gates success, tier = crafting skill at craft time (no refine step — Movements have no `data/recipes.json` entry). The chosen `oreType` becomes the crafted Movement's attunement, fixed for its lifetime regardless of which ore type is picked on a later re-craft.

| archetype | symbol | baseSuccess | ingredientBase | xpReward | bonus (tier 0–5) | downside (tier 0–5) | windingCostPerCharge (tier 0–5) |
|---|---|---|---|---|---|---|---|
| recharge | ↻ | 0.35 | 20 | 30 | [0, 0.2, 0.4, 0.7, 1.1, 1.6] | [0, 1, 2, 4, 6, 9] | [0, 8, 7, 6, 5, 4] |
| capacitor | ⏚ | 0.35 | 20 | 30 | [0, 4, 8, 14, 22, 32] | [0, 0, 0, 1, 2, 4] | [0, 5, 4, 3, 2, 1] |
| impact | ☠ | 0.35 | 20 | 30 | [0, 0.15, 0.3, 0.5, 0.8, 1.2] | [0, 2, 4, 7, 11, 16] | [0, 10, 9, 8, 7, 6] |
| spread | ✦ | 0.35 | 20 | 30 | [0, 1, 1, 2, 2, 3] | [0, 1, 2, 3, 4, 6] | [0, 9, 8, 7, 6, 5] |

`Dial.movement_calc_cost(archetype, skill) = max(1, round(ingredientBase − (skill−1)×0.8))` of the chosen `oreType`. Each archetype biases the charge pool or a cast's effect magnitude in one distinct, named direction (§3.5 has the exact formulas):

- **Recharge** — bonus raises `rechargeRate`, downside lowers `maxCharge`. Tier 5 additionally regenerates `rechargeCombatRegenAmount` charge every `rechargeCombatRegenEveryTurns` player combat turns (`Dial.combat_turn_tick()`), passive in-combat regen no other archetype has.
- **Capacitor** — bonus raises `maxCharge`, downside lowers `rechargeRate` (floored at 0; tier 5 guarantees exactly 0 outright, not merely a consequence of the curve's numbers).
- **Impact** — no charge-economy bonus (downside still lowers `maxCharge`); bonus is a multiplicative boost to a cast's raw power.
- **Spread** — no charge-economy bonus (downside still lowers `maxCharge`); bonus is an integer extra-target count on a cast, each landing at full, undiluted power (never strictly worse than Impact at the same charge cost).

**Attunement bonus** (`Dial.attunement_bonus(oreType)`) — a flat additive bonus to whichever chance formula the caller is about to roll (`cultChance`, `craftChance`, `Dial.seed_success_chance()`, and future discovery/refine chances), applied only when `oreType` matches the seated Movement's attunement, magnitude by the seated Movement's tier — driven exclusively by the seated Movement, never by loaded Complications (so there's no pre-action loadout swap to game). `attunementBonusByTier = [0, 0.02, 0.04, 0.07, 0.10, 0.15]` (index = tier).

**Complications** — loading (`Dial.load_complication(recipeKey, tier)`) moves one unit of any existing crafted consumable recipe out of `Crafting`'s tier-bucketed `player.inventory` (§2/§3.5) into `player.dial.loadedComplications`, unchanged in tier; unloading (`Dial.unload_complication(index)`) reverses it exactly — never duplicated or destroyed. Each loaded entry is `{ recipeKey, tier, capacityCost, detent }`: `capacityCost` is copied from the recipe's own fixed `data/recipes.json` field (§1.3) at load time, independent of the unit's crafted tier; `detent` is a cosmetic display-order position for the (out-of-scope) Collar UI, assigned as the entry's load-time index, read nowhere else. `Dial.capacity_used(dial)` (Σ loaded `capacityCost`) may never exceed `dial.capacityMax`.

`Dial.capacity_max(level) `: `capacityByLevel = [0, 4, 6, 9, 12, 16]` (index = Dial level) — grows only with Dial level, never with which Movement (if any) is seated, kept structurally independent of the loadout choice.

**Charge model** — persistent `currentCharge`/`maxCharge` on the Dial instance, carrying across days (not a daily allowance). Charge only exists while a Movement is seated: `Dial.seat_movement()` sizes `maxCharge`/`rechargeRate` from the newly-seated Movement's archetype/tier (§3.5) and zeroes `currentCharge`; `Dial.unseat_movement()` zeroes all three back to the inert, no-Movement shape. Natural regen (`Dial.daily_regen()`, §3.1 step ⑦) adds `rechargeRate` to `currentCharge` once per day, capped at `maxCharge`, guarded by `lastRegenDay` the same way the old device system guarded `lastResetDay`. **Winding** (`Dial.wind(amount)`) is an instant, calc-only action with no time-block cost: cost-per-charge is `winding_cost_per_charge(archetype, tier)` (the tier-indexed column above) — keyed only by the seated Movement's archetype/tier, never by Dial level or `maxCharge`, so levelling never makes winding worse. Calc type is always the seated Movement's attunement `oreType`.

**Leveling** — `Dial.cast_complication()` (§3.5) awards XP the same +10-per-cast, `Progression.award_xp()`-table way the old `Devices.activate()` did: `xpLevels = [0, 0, 50, 150, 400, 1000]`. `maxChargeBonusByLevel = [0, 0, 5, 12, 22, 35]` and `capacityByLevel` above are the primary per-level curves; `rechargeRateBonusByLevel = [0, 0, 0, 0, 0.5, 1.0]` is the deliberately sparser one. Both layer on top of the seated Movement's own archetype/tier charge stats (`_apply_level_charge_bonus`); Movements never modify capacity, and levelling never touches which Movement is seated or its attunement.

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

**Stackable guards past "guarded"** (72-stackable-guards-vein-defense): the 4-tier ladder above is no longer a hard cap. Once a vein reaches `guarded`, the vein sheet's security button becomes a repeatable **"+1 Guard"** purchase (same button, same handler — `Cultivating.upgrade_vein_security()`) that keeps installing on top of it, with no upper limit. Each vein tracks its count on `vein.extraGuards` (int, default 0; older vein dicts without the key read as 0 via `.get()`).

- **Cost** (`Cultivating.extra_guard_cost(extra_guards_owned)`, draft — needs balance sign-off): continues the base ladder's own delta progression. The ladder's per-tier deltas step up by +20 each rung (0→20→40→60 into basic/warded/guarded); the nth extra guard (n = 1, 2, 3, ...) keeps that same arithmetic-delta progression (+80, +100, +120, ...), giving the closed form `cost(n) = 10*(n+3)*(n+4)` — 200, 300, 420, 560, ... for `extra_guards_owned` = 0, 1, 2, 3.
- **Raid resistance** (`Cultivating.vein_raid_resist(vein)`, used everywhere a vein's `raidResist` is read instead of indexing `data/vein_security.json` directly): `base tier raidResist + extraGuards × 20`. The flat +20 per guard matches "guarded"'s own marginal contribution over "warded" (55−35). Unlike cost, this doesn't escalate — only cost does, per the ticket.
- Every raid-odds formula that reads a vein's defensive strength — `Raiding.stealth_success_chance()`, `Raiding.raid_success_chance()`, `Factions.rivalry_success_chance()` — divides `vein_raid_resist()` by the same 55.0 anchor (the base ladder's own top rung) it always has, then clamps the resulting chance to [0, 1]. That anchor is now a scaling reference point, not a hard ceiling: extra guards keep pushing the divided term (and the tilt it feeds) further, and the clamp — not a capped `raidResist` value — is what keeps the final chance in range.
- Faction-owned veins never buy extra guards (`Factions.apply_security_upgrades()`, the faction AI's own security spend, still stops at `guarded` — `Cultivating.next_security_tier_id("guarded")` is still `null`). Stacking is a player-only purchase via the vein sheet's UI button.

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

**Home Gym is dual-purpose (§3.7a):** beyond its existing one-time `+10 hpMax` build bonus above, once built it also unlocks a repeatable **Train** action on the HQ screen — see §3.7a for cost/reward.

### 1.8 `data/factions.json`
Five factions; copy `name`, `shortName`, `tagline`, `industries`, `description`, `colour` verbatim from HTML const `FACTIONS`. Mechanical fields:

| id | joinRelation | raidThreshold | conquerThreshold | raidStealth |
|---|---|---|---|---|
| collective | 20 | -40 | -40 | 0.35 |
| firm | 35 | 0 | 0 | 0.55 |
| guild | 40 | -30 | -30 | 0.30 |
| network | 30 | -20 | -20 | 0.80 |
| conclave | 60 | -20 | -20 | 0.65 |

**Raid/conquer eligibility thresholds** (71-per-faction-raid-claim-thresholds — human-confirmed): a faction only attempts a raid against a player vein (`Raiding.roll_raid_attempts()`, §3.12) when `state.factions[id].relation < raidThreshold`; at or above its own `raidThreshold`, zero raid attempts occur (loot or claim) for that faction. `conquerThreshold` is the same test (`relation < conquerThreshold`) gating the claim branch of ticket 70's claim/loot split (`Raiding.roll_raid_odds()`) — below it, a successful raid still rolls claim vs. loot by terroir tier as normal; at or above it (but still below `raidThreshold`, so a raid is happening at all), a successful raid is capped at loot regardless of terroir odds. Every faction's `conquerThreshold` equals its `raidThreshold`, so this adds no extra gate beyond ticket 70's own terroir odds. Firm's `raidThreshold` of `0` means they'll raid at any negative relation at all — the most trigger-happy of the five; Collective, at `-40`, is the most patient.

**`raidStealth`** (direction-b-stealth-and-anonymity — **draft only, needs balance sign-off**): each faction's baseline chance (0.0-1.0) of pulling off a raid against a player vein clean, before the target vein's own defenses are weighed in — see `Raiding.faction_stealth_chance()`, §3.12. Network (secretive information brokers) and Conclave (institutional, deniable operations) sit highest; Guild (crafting-focused, not a raiding outfit) and Collective (loosely organised, no tradecraft) sit lowest; Firm (professional but forceful, not clandestine) sits in the middle.

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

**Squad combat additions (§3.7a):** every template also carries a flat, authored `speed` (turn-order value, same units as the player's `GameData.COMBAT_SPEED_BY_LEVEL`, draft/needs balance sign-off). `data/enemies.json` also holds the Combat Skill curves as top-level tables — `combatXpLevels`, `combatAttackBonusByLevel`, `combatSpeedByLevel` — loaded into `GameData.COMBAT_XP_LEVELS`/`COMBAT_ATTACK_BONUS_BY_LEVEL`/`COMBAT_SPEED_BY_LEVEL`, the same "curve lives in the nearest relevant data file" precedent `dial.json` already sets for Dial's own tables. See §3.7a for how these are used.

### 1.11 Misc constants
`TIME_BLOCKS = ["Morning","Afternoon","Evening"]` · `ARCHIE_ORE_GOAL = 10` · contacts: archie {startRelation:10, unlocked:true, recruitThreshold:80, combatHpMax:50, combatAttackMin:4, combatAttackMax:9, combatStashMax:2, combatHealAmount:15, koCooldownDays:2, raidAssistThreshold:50}, james {startRelation:0, unlocked:false, recruitThreshold:100} · James job trust→qty bands: relation ≤1 → 1–3; ≤3 → 3–6; else 5–10; payPerItem = CONSUMABLE_PRICES[recipe].

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
  mapView: { everOpened: false, zoom: 0.85, scrollX: 0, scrollY: 0 },  # 53-map-auto-focus-and-zoom-persistence; Network map camera. Unlike mapNav above, DOES survive save/load (SaveManager._restore_int_types() restores scrollX/scrollY as ints; zoom stays float). everOpened false only until the map's first-ever open, which auto-focuses on the player's veins then marks it done; every later open restores zoom/scrollX/scrollY exactly.
  veinListNav: { districtId: null, bandFilter: null, originScreen: "map" },  # vein-growth-state ticket 09 (§6.2); vein list scope/filter/return-screen
  notifications: [],          # [{ id:String, text:String, seen:bool, day:int }] — capped at 50, oldest evicted; dismiss() only flips seen, never deletes (11-phone-os-shell ticket 04)
  bankLog: [],                # [{ id:String, amount:int, label:String, day:int }] — capped at 50 (Bank.LOG_CAP), oldest evicted; every direct player.cash mutation calls Bank.record() alongside itself (bugfixes-38, systems/bank.gd), same append-and-evict-from-front shape as `notifications` above. Display only, no dismiss.
  sellState: {},              # sell-menu qty selections, transient
  craftQty: {},                # bugfixes-57: Lab batch-craft qty selections, keyed by recipeKey, transient (not restored on load, same as sellState)
  marketplaceQty: {},          # bugfixes-66: faction marketplace row qty steppers, keyed "<factionId>_<kind>_<itemType>", transient (not restored on load, same as sellState/craftQty)
  event: null,                # M0-T13 event runner state: { eventId, cardIndex, snapshots:[] } | null

  player: {
    cash: 40,
    hp: 100, hpMax: 100,
    attackMin: 5, attackMax: 12,
    orichalchum: {},          # { oreType: int }
    veins: [],                # vein dicts, §2.1
    inventory: { timePearl: {}, enhancementPowder: {}, rewind: {} },  # bugfixes-64: { recipeKey: { "<tier>": count } } — tier-bucketed, not a flat count. Tier keys are stringified ints; tier "0" means "no known quality" (a migrated pre-64 save, a Guild purchase, or an event add_item grant — none crafted at a specific skill/refine tier). Crafting.inventory_qty/_add/_remove/_remove_from_tier are the only sanctioned readers/writers — see §3.5.
    shieldPool: 0,             # calc-effect-wiring-02: Shield's absorption pool, §3.7
    healingSalveDaysLeft: 0, healingSalveDailyAmount: 0,  # calc-effect-wiring-02: Healing Salve HoT, §3.1/§3.7
    equipment: { weapon: null },
    items: [],                # [{ id:String, type:String }]
    # dial-device ticket 07: replaces the old single-slot device system
    # (equipment.device, devicesInProgress, devicesCompleted — deleted
    # outright, along with systems/devices.gd and data/devices.json). null
    # until Dial.attempt_seed() succeeds; never a second one (Dial.attempt_seed()
    # refuses outright once this is non-null). Shape while seeded: { level,
    # xp, currentCharge, maxCharge, rechargeRate, lastRegenDay,
    # combatRegenTurnCounter, capacityMax, movement, loadedComplications,
    # haftId } — §1.4. A pre-Dial save's now-orphaned devicesInProgress/
    # devicesCompleted/equipment.device keys (if present) are left untouched
    # by SaveManager._backfill_new_player_keys, which only fills keys ABSENT
    # from a loaded save — they carry forward as harmless dead data.
    dial: null,
    # dial-device ticket 02: crafted-but-unseated Movements ({ archetype,
    # oreType, tier } — §1.4). A seated Movement (player.dial.movement) is
    # moved out of here on Dial.seat_movement() and back in on
    # Dial.unseat_movement(), never duplicated or destroyed.
    movementInventory: [],
    craftingSkill: 1, craftingXP: 0,
    cultivatingSkill: 1, cultivatingXP: 0,
    combatSkill: 1, combatXP: 0,   # §3.7a: attack bonus + turn-order speed, both level-indexed
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
    # combat* fields + koCooldownUntilDay (44-archie-combat-ally): a
    # generic ally-combat block every contact carries, not archie-only at
    # the schema level. A contact whose constants.json entry omits the
    # combat* constants (james, for now) gets combatHpMax 0 -- read by
    # Contacts.can_join_combat() as "no combat kit, never eligible".
    # raidAssistThreshold (45-archie-raid-assist): a second, higher relation
    # gate on top of recruitThreshold, checked only for the offensive
    # raid-assist ask (Contacts.can_assist_raid()), not for defend's
    # auto-join. Defaults to 0 for a contact whose constants.json entry omits
    # it (james, for now) -- harmless, since can_join_combat()'s own
    # combatHpMax gate already excludes them from ever joining a fight.
    archie: { relation:10, unlocked:true,  recruited:false, recruitThreshold:80,
              craftingSkill:1, craftingXP:0, cultivatingSkill:1, cultivatingXP:0, assignedRoom:null,
              combatHpMax:50, combatHp:50, combatAttackMin:4, combatAttackMax:9,
              combatStashMax:2, combatStash:2, combatHealAmount:15,
              koCooldownDays:2, koCooldownUntilDay:null, raidAssistThreshold:50 },
    james:  { relation:0,  unlocked:false, recruited:false, recruitThreshold:100,
              craftingSkill:1, craftingXP:0, cultivatingSkill:1, cultivatingXP:0, assignedRoom:null,
              combatHpMax:0, combatHp:0, combatAttackMin:0, combatAttackMax:0,
              combatStashMax:0, combatStash:0, combatHealAmount:0,
              koCooldownDays:0, koCooldownUntilDay:null, raidAssistThreshold:0 },
  },

  combat: { active:false, context:"raid", veinId:null, enemies:[], focusedEnemyIndex:0, log:[],
            outcome:null, frozenTurns:0, motionTurns:0, motionPower:0,
            evadeTurns:0, evadeChance:0.0, onWin:null, snapshots:[],
            allies:[] },  # 44-archie-combat-ally / §3.7a: see below

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
    archieBuyerSmsQueued: false,  # bugfixes-83: idempotency guard, ARCHIE_SMS_2's day>=2 queuing (TimeSystem)
    jamesMotionEventSeen: false, enhancementUnlocked: false,
    jamesJobActive: false, jamesJobAccepted: false,
    homeRaidEventPending: false, homeRaidEventSeen: false, homeRaidWon: false,
    archiePartnerSeen: false, homeUnlocked: false, securityContactUnlocked: false,
    dialGiftGranted: false,   # dial-device ticket 01: gates Dial.attempt_seed(); set only by the Collective Act 2 quest (out of scope for this PRD)
  },
}
```

`enemies` in combat (§3.7a — supersedes the old single `enemy` field): array of up to 3 `{ name, hp, hpMax, attackMin, attackMax, speed:int, weapon, ability, evadeChance, koed:bool }` — `veinId` moved up to sit directly on `combat` (one vein per fight regardless of guard count), not per-enemy; store `veinId`, not an object reference (state purity). `combat.focusedEnemyIndex` addresses the player's current single-target into this array — see §3.7a.

`allies` in combat (44-archie-combat-ally): array of `{ contactId, name, hp, hpMax, attackMin, attackMax, stash:int, healAmount:int, koed:bool }` — a snapshot of a contact's combat kit taken at join time (`Contacts.build_combat_ally()`), general-shaped for any future recruit, not archie-hardcoded. Populated two ways in M0: `defend_vein` combat auto-joins every recruited contact with `Contacts.can_join_combat()` true (`Combat._gather_defend_allies()`); raid combat (`Combat.start_raid()`, any context) instead only joins contacts the player explicitly chose at the Raid button, re-validated against `can_join_combat()` at combat-start time (`Combat._gather_raid_allies()`, 45-archie-raid-assist). `koed` allies stay in the array (so `contactId` is still there for the cooldown to key off) but are skipped by every turn/target/render loop — "removed from the fight" is this flag, not array removal.

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
M0 roster (original): `title, intro, home, veins, inventory, crafting, contacts, sms_archie, sms_archie_2, world, property, factions, barometer, stats, save, combat, event` (M0-T13 replaces the per-event screens with one generic `event` screen driven by `state.event`). Later M1 tickets (04 Map, 06 HQ, 07 Phone) redistribute their content into the D4 tabs below and retire the ones D4 says to delete. **Ticket 06 (HQ merge) is done:** `property` and `crafting` are deleted (no `SCREEN_SCRIPTS` entry, no remaining `Nav.go_to` call sites) — their functionality lives under `hq`. **Ticket 07 (Phone reskin + Ticker) is done:** `world`, `barometer`, `stats`, `save` are all deleted — `world`/`barometer` (the latter unreachable already; nothing linked to it once `world` was gone) live on as `phone`'s Ticker app, `stats`/`save` (also unreachable — no `Nav.go_to` call site) live on merged into `you`. `veins, contacts, factions` remain wired into the tutorial-era `home` flow (event `set_screen` effects still target `contacts`) and are still slated for retirement by ticket 10 (tutorial gating) — Phone's own contact list/faction directory (below) are new, parallel content for the post-tutorial nav shell, not a redirect of those screens' nav paths. (Ticket 11, phone-as-OS-shell, further retires `you`, `bag`, and `inventory` — see below.) **Bugfixes ticket 83 is done:** `sms_archie` and `sms_archie_2` are deleted (no `SCREEN_SCRIPTS` entry, no remaining `Nav.go_to` call sites, `data/sms.json` removed) — ARCHIE_SMS_1/2's content now lives in the generic `state.messages`/`state.pendingMessages` pipeline (§5.3), delivered via `push_message`/`queue_pending_message` effect ops from `buyer.json`'s and `TimeSystem`'s own triggers, and surfaced through Archie's Contacts card and the Phone Messages app like any other contact.

M1 D4, as amended by ticket 11 (phone-as-OS-shell), makes the nav bar a **3-slot dock** — `phone, map, hq` — which **supersedes** both the M0 bottom nav (`Home · Inventory · Craft · World · Contacts`) and the interim 5-tab bar ticket 07 shipped (`Map · HQ · Phone · Bag · You`). `map` is ticket 04's `MapScreen` (district list -> district panel -> site/vein sheet, `state.mapNav`-driven, per D4's "Map tab" section); `hq` is ticket 06's `HqScreen` — tier/security/rooms/stored-ore/tier-upgrade (old `property`), recipes/devices as "the workbench" (old `crafting`), a gym placeholder, and assigned-contact UI for the `lab`/`veinStation` rooms (`Contacts.assign_to_room`, previously unreachable from any screen). `phone` is ticket 07's `PhoneScreen`, promoted by ticket 11 into the game's **home screen**: `home` now resolves to the phone app grid rather than a separate screen id. The grid holds an icon+label tile per app — including locked ones, greyed with a padlock overlay, always in their permanent slot — and launches: Messages (contact list + SMS-thread/James-job triggers, reskinned from old `contacts`), Notes (`Todo.get_items()`), Factions (directory, reskinned from old `factions`), Ticker (D4.5 — three headline cards → axis detail with push/pull + greyed M4 influence actions, `state.phoneNav.selectedAxis`-driven, `data/barometer.json`'s per-state `headlines` array), plus three apps ticket 11 adds: **Profile** (HP/attack range, crafting/cultivating skill+XP, read-only equipped-weapon/device summary — cash/day and the ops-style veins-held/ore-in-stock summary are deliberately left off since the top bar and bag drawer already cover them), **Notifications** (full read-only log, newest first), and **Save/Load** (all three save slots — save/load/delete each — export, import, confirmation-gated New Game). bugfixes-38 adds an eighth app, **Reynard's** (`"bank"`) — a display-only cash balance + transaction log (`state.bankLog`, §2), read-only and newest-first like Notifications; no interest, loans, or transfers. `you`, `bag`, and `inventory` are retired screen ids: `you`'s content (HP/attack/cash/day, skills+XP, equipped-weapon/device summary, ops summary, save/load/export/import/new-game) splits across Profile/Notifications/Save-Load above, minus cash/day and the ops summary which are dropped rather than carried over; `bag`'s functionality (equip/unequip weapon and device, device start/build-attempt/abandon, plus the read-only ore/consumable/charge view) moves entirely into the global `BagDrawer` (D4.4), reachable from any screen with no dedicated tab; `inventory`, the screen script `bag` used to alias, is deleted once `BagDrawer` absorbs its management actions. `Nav.go_to("home")` resolves to the phone app grid, and the retired ids (`you`, `bag`, `inventory`, and any save with a stale `home`-era screen) all fall back to the app grid rather than `title`, so old saves never soft-lock.

The dock (`NavBar`, now 3 slots: Phone · Map · HQ) is hidden on `title, intro, event, combat` (unchanged from M0). Phone is a home button: tapping it returns to the app grid from any screen, and no-ops when already on the grid. A separate persistent top bar (`TopBar`, D4: cash · day/time-blocks · bag button) is shown on every screen except `title, intro` — it stays up through `event` and `combat` so the bag button keeps working there (D4.4). The bag button opens the global `BagDrawer` bottom sheet via `state.bagDrawerOpen` (`Bag.open()`/`Bag.close()`), independent of screen navigation and of `state.modal`.

---

## 3. FORMULAS & SYSTEM RULES

### 3.1 Time, rest, daily tick
- 3 blocks/day. `advanceTimeBlock()`: append current block to `timeBlocksDone`, increment `timeBlock`; if `timeBlock >= 3` → `day += 1`, `timeBlock = 0`, `timeBlocksDone = []`, run `daily_tick()`.
- `isTimeExhausted()` = `timeBlocksDone.size() >= 3`.
- **Rest:** consume all remaining blocks, roll to next day (runs daily_tick), then heal `round(hpMax * 0.2)` capped at hpMax. Notification: "Rested. Day N. +X HP."
- **daily_tick order (exact):** ① tick barometer ② roll home raid ③ living costs: `DAILY_COST = round(50 * (1 + fx.dailyCost))`, `cash = max(0, cash − DAILY_COST)`, notification (append " You are flat broke." if cash hits 0) ③b Healing Salve HoT (see §3.7) ③c passive HP regen (bugfixes-42): unconditional, always-on, independent of Rest and the Salve HoT (stacks with both) — `heal = round(hpMax * PASSIVE_REGEN_FRACTION)` (`PASSIVE_REGEN_FRACTION` = 0.05), capped at hpMax, skipped (no notification) if already at full HP; notification "You rest easy. +X HP." ④ vein growth drift (`Cultivating.drift_veins()`, vein-growth-state §2.3): for each player vein and each faction vein, `delta = band_drift(growth)`, `direction = +1 if growth>50, -1 if growth<50, 0 if dormant`, `growth = clamp(growth + delta*direction, 0, ceiling(vein))`; a vein pinned at 0 then rolls `collapseChancePerDay` (0.15) to be removed (site reverts to unclaimed for a player vein, deleted outright for a faction vein) ⑤ tutorial day-triggers (day ≥ 2 & stage "buyer_event" & !buyerEventSeen → queues ARCHIE_SMS_2's content as a real pendingMessages entry, once, guarded by `archieBuyerSmsQueued` — bugfixes-83, no separate notification; stage "archie_craft_chat" & day ≥ archieChatUnlockDay → notification "Archie wants to meet up. Check Contacts.") ⑤b NPC site-claiming ⑤c faction-vein prune-back ⑥ process lab room, then veinStation room, if installed ⑦ Dial charge regen (`Dial.daily_regen()`, dial-device ticket 07 — replaces the old device system's per-device charge reset; §1.4/§3.5). (This line predates the faction-economy/rivalry/raiding steps that now run between ⑤c and ⑥ — see `systems/time_system.gd`'s own daily_tick() doc comment for the full, current step list; not re-derived here to avoid a second copy drifting out of sync.)
- **NPC site-claiming** (`Sites.roll_npc_claims()`, step ⑤b, M1-LONDON.md D2/adr/0002): each unclaimed, non-barren site rolls `chance(npc_claim_chance(tier, ageDays))`, `npc_claim_chance = clamp(0.02 + 0.01×tierIndex + 0.005×ageDays, 0.0, 0.15)` (tierIndex: poor 0, fair 1, rich 2, saturated 3; ageDays = day − discoveredDay) — on hit, one of the 5 canonical factions (`Factions.pick_claimant()`) instantly claims it (a real vein at `growth = seedGrowth`, per §1.2/§3.4). **Retuned by bugfixes-73/adr/0004** (down from base 0.03 / tier-step 0.02 / age-step 0.01 / cap 0.25) alongside removing NPC-abandonment below, to roughly track the slower turnover that removal produces — needs balance sign-off once played.
- **NPC-abandonment — REMOVED** (bugfixes-73/adr/0004): adr/0002 originally paired the claim roll above with a second, independent daily kill roll for every faction-claimed site (`p = clamp(0.02 + 0.005×ageDaysSinceClaim, 0.0, 0.08)`, deleting the site outright on a hit). That mechanic no longer exists. A faction vein now only dies via the same growth-collapse-at-zero roll a player vein faces (§3.4's Left wall) — no second roll stacked on top.
- **Faction-vein growth prune-back** (`Sites.roll_faction_vein_growth()`, step ⑤c, faction-vein-ownership T02/vein-growth-state T04): once a faction vein's growth (drifting per §3.4/§1.2, same as any vein) reaches ≥85, each daily tick it stays there rolls `chance(0.40)` to reset `growth` to a fixed target — without this, a faction vein sitting at the ceiling (0 drift there) would park forever. **Target retuned from 55 to 40 by bugfixes-73/adr/0004**: 55 sits inside the "dormant" band (45–55, drift 0 — §1.2), which is *also* a permanent parking spot once NPC-abandonment (a faction vein's independent second death roll) is gone — a vein reset to 55 would never drift again, since direction only flips at neutral (50) and dormant's own drift is 0. 40 sits in "thinning" (30–44, drift 1 leftward), so a prune-backed vein resumes its walk toward 0 and eventually reaches the same collapse-at-zero fate as any other vein, which is what makes a steady faction-vein population possible at all now that abandonment is gone. Threshold (85) and chance (0.40) are unchanged — needs balance sign-off once played.

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
- **Prune(vein, depth):** 1 block. `depth` is `pruneLightDepth` (9) or `pruneHardDepth` (24). `points = max(0, growth_before−50) − max(0, growth_after−50)` where `growth_after = max(0, growth_before − depth)`; `yield = round(points * yieldPerPoint(0.35) * terroirYieldMult(vein.hospitability.tier) * hardBonus)` (hardBonus 1.25 for a hard prune, 1.0 for light), then `apply_yield_bonus`. Pruning at or below neutral (50) always yields 0. No cultivating XP awarded (matches the harvest schedule this replaces).
- **Left wall (collapse):** `growth` pins at 0. Each daily tick a vein sits at 0, `chance(collapseChancePerDay)` (0.15) removes it: a player vein's site reverts to unclaimed; a faction vein's site is deleted outright. Still cultivable at the maximum gain while pinned at 0. This is the only way a faction vein dies — see the NPC-claim/faction-vein-growth bullet in §3.1.
- **Right wall (rampant/self-seed):** `growth` clamps at `ceiling(vein)`. `rampantDays` increments each daily tick spent at the ceiling; at `rampantSeedDays` (5), claims an unclaimed site in the same district for a new player vein at `growth = selfSeedGrowth` (60) — see vein-growth-state ticket 02. Faction veins never self-seed.
- `value_tier(vein) = min(6, 1 + floor(growth/20))` — the 1–6 magnitude that replaces the old 1–5 `level` everywhere a vein's value/strength matters.
- XP level-up loop: while skill < 5 and XP ≥ table[skill+1] → skill += 1 (notification for cultivating).

### 3.5 Crafting & the Dial
- `craftChance(r) = min(0.95, r.baseSuccess + (skill−1) * 0.13 + workshopBonus)`.
- `calcCost(r) = { oreType: max(1, round(baseCalcCost − (skill−1) * 0.8)) for oreType, baseCalcCost in r.ingredients }` — computed independently per ingredient key.
- `effectPower(r) = r.effectPower[skill]`.
- **qualityTier(r, skill)** (bugfixes-64): the tier a craft at this moment would file its inventory unit under — mirrors `effectPower`'s own refine branch. A recipe refined past Bench tier 0 (`refineStep.field == "effectPower"` and `Bench.get_cell(...).refine > 0`) reports that refine tier; everything else reports `skill` itself. Not capped — a refine tier can climb past 5.
- **attemptCraft:** requires cost in each ingredient type; deduct ALL ingredients ALWAYS; success → `Crafting.inventory_add(recipeKey, qualityTier(r, skill))` (+1 unit filed under that tier's bucket, §2), full XP; fail → `floor(xp/3)`. Result modal.
- **Dial seeding:** `Dial.attempt_seed(haftId)` — refused with no `flags.dialGiftGranted`, an unknown haft, insufficient mixed calc, or a non-null `player.dial` already present. Otherwise: deduct `data/dial.json`'s `seedCost` in full across all five ore types regardless of outcome, then one roll at `Dial.seed_success_chance()` (§1.4). Success sets `player.dial` to `{level:1, xp:0, currentCharge:0, maxCharge:0, rechargeRate:0, lastRegenDay:day, combatRegenTurnCounter:0, capacityMax:capacity_max(1), movement:null, loadedComplications:[], haftId}` — fully inert (no attunement, no charge, no regen) until a Movement is seated, though `capacityMax` is real from level 1 on (capacity is independent of Movement/inertness). Failure leaves `player.dial` null, cost still spent.
- **Movement crafting, seating, attunement:** `Dial.attempt_craft_movement(archetype, oreType)` — same contract as `attemptCraft` above: cost (§1.4) always spent, `Dial.movement_craft_chance()` gates success, tier = crafting skill at craft time; success lands the Movement (unseated) in `player.movementInventory`, awarding full `xpReward` crafting XP (fail → `floor(xpReward/3)`). `Dial.seat_movement(inventoryIndex)`/`Dial.unseat_movement()` swap the seated Movement in and out of `player.dial.movement`, always returning the previous occupant (if any) to `movementInventory` intact — fully reversible, never destroyed. Seating/unseating re-derives `maxCharge`/`rechargeRate` from the incoming Movement's archetype/tier (§1.4) plus the Dial's own level bonus, and resets `currentCharge`/`combatRegenTurnCounter` to 0; unseating zeroes all three back to the inert shape above. `Dial.attunement_bonus(oreType)`/`Dial.apply_attunement(baseChance, oreType)` (§1.4) are added on top of `cultChance`/`craftChance`/`seedSuccessChance` by their own callers (`Cultivating.cultivate()`, `Crafting.attempt_craft()` per matching ingredient, `Dial.attempt_seed()`) — never baked into those formulas themselves, since NPC contacts also roll them and must never benefit from the player's Dial.
- **Complications — load/unload:** `Dial.load_complication(recipeKey, tier)` moves one unit out of `player.inventory`'s tier bucket (§2/above) into `player.dial.loadedComplications` at the recipe's fixed `capacityCost` (§1.3), refused once `Dial.capacity_used()` would exceed `capacityMax`; `Dial.unload_complication(index)` reverses it exactly, unit intact.
- **Casting a loaded Complication:** `Dial.cast_complication(index)` — refused with no Dial, no such loaded index, or `currentCharge < 1`. On success: spends exactly 1 charge (never touches `player.inventory` — unlike a direct throw, §3.8, which always draws from inventory and recomputes power from the player's *current* skill); base power = `effectPower(recipe, loadedTier)` at the tier the unit was *loaded* at, not the player's current skill; amplified per the seated Movement's archetype (Impact multiplies power by `1 + bonus[tier]`; Spread grants `1 + int(bonus[tier])` full-power targets, no dilution; Recharge/Capacitor apply no amplification, identical to no Movement seated); awards +10 Dial XP (`Progression.award_xp`, `xpLevels` §1.4 — level-ups grow `capacityMax` and, if a Movement is seated, re-derive `maxCharge`/`rechargeRate` from it plus the new level's bonus curves). `Dial.combat_turn_tick()` — called once per player combat turn (`Combat.player_attack()`) — is the tier-5 Recharge Movement's separate in-combat regen (§1.4); a silent no-op for every other case. Combat's own cast call site (`Combat.cast_complication(index)`) additionally refuses a loaded `rewind` unit (cast via `combat_rewind()`'s own fallback instead, §3.9) and any recipe with no defined combat effect, and runs each recipe's own "already active" guard (already frozen/already moving/shield already up) *before* spending a charge — a blocked cast never costs one. Every other loaded recipe (timePearl/enhancementPowder/blast/shield/blackHole/healingBurst/prophetsBreath/wormhole) applies the exact effect its §3.7 direct-use bullet describes, using the cast's amplified power/target count in place of a freshly-rolled effectPower — with only one enemy in the current combat model, "targets" multiplies the effect's own magnitude (full power per target, repeated) rather than spreading across multiple enemies.
- **Charge model:** `Dial.wind(amount)` — instant, no time-block cost, calc-only: cost-per-charge = `winding_cost_per_charge(archetype, tier)` (§1.4, keyed only by the seated Movement's archetype/tier, never by Dial level/`maxCharge`), calc type always the seated Movement's attunement `oreType`; `amount` silently clamps to headroom under `maxCharge` so no calc is spent on charge that would just be discarded at the cap. `Dial.daily_regen()` (daily_tick step ⑦ above) adds `rechargeRate` to `currentCharge` once per day, capped at `maxCharge`, guarded by `lastRegenDay` the same `< day` way the old device system guarded `lastResetDay`; a null Dial is a silent no-op.
- **Spending a consumable outside a sale** (combat item use, travel's Wormhole, event Rewind, a James craft-job fulfilment, a Guild sale) draws from the lowest tier bucket first, via `Crafting.inventory_remove` — every such use is indifferent to which specific unit it spends, since `effectPower` is recomputed from the *current* skill at use-time, not the tier the spent unit was crafted at. This keeps higher-quality stock on hand for a §3.6 sale, where tier does matter.

### 3.6 Selling (Archie lane)
- Sell menu covers ore (all 5 types, at effective price) and consumables at CONSUMABLE_PRICES (gated by `canSellConsumables`) — one sell row per (recipe, tier-in-stock) since ticket 64, not one row per recipe.
- **qualityPriceMultiplier(tier)** (bugfixes-64, human-confirmed curve, no prior REFERENCE.md precedent — see `.scratch/0-bugfixes/issues/64`): `1.0 + 0.25 * (max(tier, 1) − 1)`. Tier 1 → 1.0×, tier 5 → 2.0× (linear, doubling at the top skill tier); tier 0 (untiered/legacy stock) prices the same as tier 1 — no bonus, no penalty, since its quality is genuinely unknown.
- A sold consumable's `price = round_epsilon(CONSUMABLE_PRICES[recipeKey] * qualityPriceMultiplier(tier))`, then the existing `* (1 + priceMod)` district/omen modifiers apply on top. Selling draws down that exact tier's bucket (`Crafting.inventory_remove_from_tier`), not a generic lowest-first policy.
- `gross` = Σ price×qty; deduct goods; player cut = `floor(gross * cutRatio)`, where `cutRatio` is `Economy.get_archie_cut_ratio()` (collective1-01, human-confirmed curve): 0.60× at Archie relation ≤10, linear to 0.85× at relation ≥80, flat outside that range.
- Consumables-sold counter: first ever consumable sale (and !archieMotionEventSeen) → set `archieMotionPending = true` + queue a real Archie text ("good output. call me.", `Messages.queue_pending`, kind `archie_motion`) instead of a bare notification — bugfixes-83.
- Every completed sale (ore or consumable, mugged or not): archie relation +2 (`ARCHIE_SALE_RELATION_GAIN`, bugfixes-63) — smaller than James's +5/job since sales happen far more often. Awarded *before* the cut ratio below is computed, so it affects the same sale's own cut (unchanged since bugfixes-63). This flat award stays alongside, not instead of, the separate `tradeProgress` £-denominated relation accumulator (collective1-06, `.scratch/collective-act1/spec.md` §8.4) that also runs on every Archie-lane sale — that one is applied *after* the cut is computed, so it never affects the sale that fed it.
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
- **Ally combat** (44-archie-combat-ally, `defend_vein`; extended to raid combat by 45-archie-raid-assist): in `defend_vein`, every recruited contact with `Contacts.can_join_combat()` true joins `combat.allies` automatically when the fight starts (no offer/decline — defending a shared vein needs no relation threshold once recruited, just not currently KO'd). In raid combat (`Combat.start_raid()`), joining is opt-in instead: the raid-initiation UI (the faction-vein site sheet, `scenes/screens/map.gd`) offers a "Bring Archie" toggle once `Contacts.can_assist_raid(id)` passes (`relation >= raidAssistThreshold` on top of `can_join_combat()`'s own recruited/kit/cooldown gates), and the player's choice rides into the raid event's context (`Raiding.begin_raid()` → `Events.start_event()`'s `ally_ids` → `events.gd`'s `_start_raid_combat()` → `Combat.start_raid(..., ally_ids)`), re-validated against `can_join_combat()` again once combat actually starts (`Combat._gather_raid_allies()`) since a time block passes between the ask and the fight. Once joined, an ally behaves identically regardless of how they got there. Each player-attack turn, after the player's own attacks resolve (and can still win the fight outright), every non-KO'd ally acts once, in array order: if `hp < hpMax × 0.4` and `stash > 0` they spend one stash charge healing `healAmount` (capped at hpMax) instead of attacking; otherwise they roll `chance(enemy.evadeChance)` (miss, no damage) else `dmg = rand(attackMin, attackMax)` against the enemy, same as the player's own hit — this can also win the fight outright. The enemy's one attack per turn then targets a target chosen uniformly at random from {player} ∪ {non-KO'd allies} — a plain player-only fight (no allies) is unaffected. A hit on the player is unchanged from the player-only path (shield, HP, loss/failsafe). A hit on an ally has no shield/evade/failsafe: `ally.hp = max(0, hp − dmg)`; at 0, `ally.koed = true` (removed from all further turn/target logic this fight, not deleted from the array) and `Contacts.knock_out(contactId, today)` sets `koCooldownUntilDay = today + koCooldownDays` — the fight itself continues for the player regardless. On `exit_combat()`, `Contacts.replenish_after_combat(combat.allies)` resets every fought ally's persistent `combatHp`/`combatStash` back to their Max (the HP pool's stakes are within-fight only; `koCooldownUntilDay` is untouched by this and gates `can_join_combat()` on future fights until the day arrives).

### 3.7a Squad combat, turn order, and Combat Skill (2026-08-30 pass — extends/supersedes §3.7)

Supersedes the single-`enemy` framing in §3.7 wherever it conflicts: `combat.enemy` becomes `combat.enemies: Array` (up to 3 entries, per-entry shape per §2 above, plus `speed:int` and `koed:bool`), and `combat.focusedEnemyIndex: int` (default 0) is added. Every other §3.7 mechanic — attack ranges, shield/blast/time-pearl/black-hole, ally behaviour, onWin dispatch, Rewind — carries over unchanged except where noted below.

- **Combat Skill** (new player stat, `player.combatSkill`/`player.combatXP`, levels 1–5, mechanical name only — display/flavour name TBD): reuses the exact `[0, 0, 80, 220, 500, 1000]` XP curve crafting/cultivating skill already use (`GameData.COMBAT_XP_LEVELS`, same `Progression.award_xp()` mechanism). Two additive, level-indexed effects (curves in `data/enemies.json`, §1.10 — **both draft, need balance sign-off**):
  - **Attack bonus**, `COMBAT_ATTACK_BONUS_BY_LEVEL = [0, 0, 2, 4, 7, 11]`, added to both `attackMin`/`attackMax` in `Combat.get_attack_range()`, before the weapon bonus. Level 1 = today's baseline, unchanged.
  - **Speed**, `COMBAT_SPEED_BY_LEVEL = [0, 10, 12, 14, 17, 21]` — the player's turn-order value (below). Allies and enemies are not trainable: each carries its own flat, authored `speed` (ally: contact combat-kit constants, §1.11; enemy: per template, §1.10).
  - **XP sources:** `Combat.player_attack()` awards a flat `COMBAT_XP_PER_ATTACK_TURN = 5` once per player turn taken (mirrors `Dial.cast_complication()`'s flat +10 — taking a turn is the "attempt", no success/fail split). A new HQ action, **Train**, visible once `homeGym` is built: costs 1 time block (same currency every other block-consuming HQ action uses — Lab, veinStation, a James job fulfilment), awards a flat `COMBAT_XP_PER_GYM_SESSION = 30`, no separate cooldown — the 3-blocks/day economy is the only throttle. `homeGym`'s existing one-time `+10 hpMax` build bonus (§1.7) is unchanged and independent of this.

- **Turn order:** every combat round, build one queue: every non-koed combatant (player, living allies, living enemies) sorted by `speed` descending; ties break player > allies (array order) > enemies (array order) — deterministic, no RNG in the sort itself. Each queue entry resolves as one atomic turn (today's player-attack/ally-turn/enemy-turn bodies per §3.7, invoked once per queue entry instead of once per round). `frozenTurns` skips a combatant's entry in place (no-op + decrement, same log line as today) rather than removing it from the queue. `motionTurns`/`motionPower` (Enhancement Powder, or a loaded `enhancementPowder` Complication) changes from today's in-place 2×/3× attack loop inside one `player_attack()` call to **one extra queue entry inserted immediately after the boosted combatant's own slot**, for that round only — a visible second turn, not a hidden multiplier.

- **Targeting:** `combat.focusedEnemyIndex` is the player's current single-target (Attack, Blast, and any Complication except an AoE one) — set by swiping the turn-order strip (`docs/combat-animation-vision.md` §2.4), no separate tap-to-target step. Auto-clamps to the next living enemy if the focused one dies mid-round. Fight ends (win) once every entry in `combat.enemies` is `koed`. AoE (Black Hole; any future mass effect) ignores focus and hits every non-koed enemy at full, un-diluted power each — matches Spread Movement's existing no-per-target-dilution precedent (§1.4/§3.5). Enemy targeting is unchanged in shape from today's `Combat._pick_enemy_target()` (uniform-random over {player} ∪ {living allies}) — just rolled once per enemy's own queue turn instead of once per round, independently per enemy.

- **Roster generation** — spawning distinct enemies instead of one scaled blob: `Combat.generate_mugger()`'s `count` (1–3, unchanged roll) now spawns `count` distinct entries off the single "mugger" archetype's base stats (hp 28, atk 4–10), not one `hp × count` blob. `Combat.generate_raid_enemy()`'s `guard_count` (also capped at 3, the squad max) similarly spawns `guard_count` distinct entries, each slot independently rolling a template from `GameData.ENEMY_RAID_GUARDS` (mixed-archetype squads now possible — e.g. one Scrapper + one Vein Guard) unless a caller forces a specific `template_key`, in which case every slot uses that template. Every spawned entry — mugger or guard — gets independent stat variance: `hp`/`attackMin`/`attackMax` each rolled at `base × randf_range(1 − ENEMY_INSTANCE_VARIANCE, 1 + ENEMY_INSTANCE_VARIANCE)` (`Combat.ENEMY_INSTANCE_VARIANCE = 0.15`, **draft, needs balance sign-off**), rounded via `GameState.round_epsilon()` — same-archetype squadmates read as individuals, not clones. **This is a real difficulty increase over today's blob-scaling** (3 full-stat guards vs. one 3×-hp blob) — flagged, not silently absorbed; wants its own playtest pass before shipping to a live encounter.

- **Unchanged by this pass:** ally roster shape/behaviour (§3.7's "Ally combat" bullet) beyond adding `speed`; win/loss/flee outcome dispatch (§3.7's onWin table); Rewind/snapshot mechanics (§3.9) beyond snapshotting `enemies`/`focusedEnemyIndex` in place of the old single `enemy`.

### 3.8 Home-raid event chain
Trigger: `homeRaidEventPending` true → on next visit to HQ, launch. Flow: intro event (3 cards) → combat vs raider (hp 35, atk 6–14, context "home_raid") → debrief event (WIN or LOSS variant). Loss additionally: carried `orichalchum` halved (floor) — this used to also separately halve a `storedOre` pool, but that field was merged into `orichalchum` (§2's storedOre merge note), so there is only the one pool to lose now. Debrief completion (both variants): `homeRaidEventSeen = true`, `homeRaidWon` per outcome, `archiePartnerSeen = true`, `homeUnlocked = true`, `securityContactUnlocked = true`, archie relation +10, grant a vein (time-type, growth `seedGrowth` (20), rampantDays 0, security none, district "whitechapel", location "Whitechapel, behind the old brewery", claimedOnDay = today), notification "HQ's workbench is open now." (now that `homeUnlocked` is genuinely true), → home.

### 3.9 Snapshots & Rewind (engine foundation)
- `Snapshots.gd`: `push(stack_id, deep_copy_of_state_subset)`, bounded stacks.
- **Combat rewind:** snapshot at the start of every player attack turn: `{playerHp, enemyHp, log(copy), frozenTurns, motionTurns, motionPower, evadeTurns, evadeChance}`; keep max 2. Using Rewind (a `rewind` consumable, preferred, or — dial-device ticket 07 — a loaded `rewind` Complication with `currentCharge ≥ 1` as fallback, cast via `Dial.cast_complication()` for its charge/XP side effects only, ignoring its power/targets): consume; restore the OLDEST snapshot; clear stack; append log "⟲ Time unspools. The moment resets. Only you remember."; `outcome = null`; grant `evadeTurns = 2, evadeChance = 0.50`. The event-runner's own Rewind (`Events.rewind()`, card-frame snapshots, M0-T13) follows the same consumable-then-Complication fallback.
- **Event rewind:** the event runner snapshots full `state` before applying each card's effects; Rewind pops one card-frame (M0-T13).

### 3.10 Contacts, rooms, jobs
- `awardRelation(id, n)`. Recruit at threshold: sets recruited, notification, assignable to rooms (one contact per room; assigning vacates).
- **Ally combat eligibility** (44-archie-combat-ally): `Contacts.can_join_combat(id)` = recruited AND `combatHpMax > 0` (a combat kit is defined for this contact) AND not currently on KO cooldown (`koCooldownUntilDay == null` or `world.day >= koCooldownUntilDay`). No relation check — joining a defense fight is a lower bar than recruiting at all. See §3.7 for the fight itself.
- **Raid-assist eligibility** (45-archie-raid-assist): `Contacts.can_assist_raid(id)` = `relation >= raidAssistThreshold` (archie: 50) AND `can_join_combat(id)` — a higher, separate bar than defend's auto-join, since being asked along on an offensive raid is a bigger ask than defending shared ground. Gates the raid-initiation UI's "Bring Archie" toggle only; see §3.7 for how the choice reaches the fight itself.
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

### 3.12 Vein raiding: faction raid outcomes against a player vein (Direction B)
Before any of this runs, `Raiding.roll_raid_attempts()` gates whether the attacking faction attempts a raid at all, and `Raiding.roll_raid_odds()` gates whether it's willing to claim vs. loot-only — both per-faction `raidThreshold`/`conquerThreshold` relation checks, see §1.8.

`Raiding.resolve_raid_outcome()` (`systems/raiding.gd`), the resolution step for a faction raid that succeeds against a player-owned vein, rolls between two outcomes instead of an automatic takeover:
- **Claim** — full takeover, unchanged from before: the vein transfers into the attacking faction's `site.factionVein` (carrying `oreType`/`growth`/`security` unchanged), leaves `player.veins`, and queues a map `seed_claim` event. Notification: `"<Faction> raided your vein in <District>. It's theirs now."` (or, if the alarm window was missed: `"Too late — <Faction> took your vein in <District> while the alarm was still ringing."`). Always names the faction, regardless of the stealth roll below — a claim visibly changes the map, so there's nothing to hide.
- **Loot** — the common case: the vein stays player-owned, pruned by `RAID_LOOT_PRUNE_DEPTH` (9, matching `pruneLightDepth`, floored at 0 growth) and the player's own `orichalchum` stash of the vein's ore type docked `RAID_LOOT_ORE_QTY` (8, matching Direction A's own `LOOT_ORE_QTY`), clamped to whatever's actually on hand — it can never go negative. No relation hit, no map event (ownership never changes). Notification, caught: `"<Faction> raided your vein in <District>, pruning it and getting away with <N> units of ore. It's still yours."` (missed-alarm variant reads distinctly too). Notification, clean (stealth roll succeeded): identical shape, but the faction's name is swapped for the anonymous stand-in "Someone" (`Raiding.ANONYMOUS_RAIDER_LABEL`) — the player still learns what happened, just not who did it.

**Claim odds by terroir tier** (`Raiding.CLAIM_CHANCE_BY_TERROIR`, keyed off the vein's own `hospitability.tier` — **draft only, needs balance sign-off**, linear interpolation between the PRD's poor/saturated endpoints):

| tier | claim chance |
|---|---|
| poor | 5% |
| fair | 28% |
| rich | 52% |
| saturated | 75% |

The roll happens once, at `Raiding.roll_raid_odds()` time (alongside the existing success roll) — a successful attempt is annotated `outcomeType: "claim"|"loot"` via `Rng.chance(Raiding.claim_chance(vein))`, and that annotation rides unchanged through the alarm-defend queue/expiry machinery (`systems/raiding.gd`'s `_queue_defend_raid`/`_expire_pending_defend_raids`/`resolve_defend_outcome`) to `resolve_raid_outcome()`.

**Stealth/caught roll** (direction-b-stealth-and-anonymity, `Raiding.faction_stealth_chance()` — a second, independent roll, also taken at `roll_raid_odds()` time and annotated onto the same outcome dict as `caught: bool`): `Rng.chance()` against the attacking faction's own `raidStealth` (§1.8), trimmed by the target vein's `raidResist` normalised against the same 55.0 anchor every other raid-odds formula uses. A failure (i.e. the faction is *not* caught, a "clean" getaway) only changes anything on the loot branch above — the claim branch never reads it. It also rides through the alarm-defend queue: `_queue_defend_raid()`'s advance warning (`"Alarm's gone off — <Faction> are closing in on your vein in <District>. Get there today to defend it."`) is anonymized the same way when the queued outcome is already known to resolve as a clean loot (`"...someone's closing in..."`); a claim-bound or caught-loot-bound warning still names the faction, since its eventual notification will too. Neither branch of Direction B calls `Factions.adjust_player_relation()` either way — the player decides how (or whether) to react, this isn't an automated stat hit.

---

## 4. DESIGN TOKENS (Godot Theme)

--ink #1a1a1a · --paper #f0ece2 · --amber #c8873a · --slate #4a5568 · --muted #8a8a8a · --danger #9b2335 · --success #3a7a52 · --card-bg #faf8f3 · --border #d4cfc4. Body font: a bundled serif (e.g. Source Serif); UI font: a bundled sans (e.g. Inter). Layout: portrait, content column max 390 logical px, bottom nav bar fixed.

---

## 5. DEBUG START (title screen button)
£1,000,000; all flags of §2 set complete/true (stage "free"); 3 veins covering the growth model's distinct visual states — one `collapsed` (growth 0), one `dormant` (growth 50), one `rampant` (growth 100) — so every band is inspectable immediately without waiting out drift (vein-growth-state ticket 10 lands the exact values); 50 units of each of the 5 ore types; 5 timePearl, 3 enhancementPowder, 1 rewind, 2 healingSalve, 3 blast, 2 shield, 2 blackHole, 3 healingBurst; crafting skill 3, cultivating 5 (maxed — so `Sites.seed_success_chance`'s clamp, not the skill curve, is what caps prospecting odds in debug play); townhouse + workshop + homeGym + lock + cameras; archie relation 60, james relation 40 (both unlocked); guild joined, collective 25, firm 15; barometer economic=boom, social=stable, political=war; crowbar owned and equipped; `homeRaidEventPending = true`.

---

## 6. SAVE FORMAT
JSON of the whole `state` tree. `meta.saveVersion` is 2 (bumped from 1 by vein-growth-state — the vein dict shape changed, and save-breaking was accepted rather than writing a migrator). `SaveManager`: 3 manual slots + 3 rotating autosaves (written on: daily tick, combat exit, event completion, any purchase), plus export/import as a JSON string shown in a copyable text box. Loading checks `meta.saveVersion` against the current `SAVE_VERSION` and rejects a mismatch outright with a clear reason (no half-load, no migrator); a save with no `meta.saveVersion` at all is treated as the current version. A version match then validates required top-level keys and fills missing keys from defaults.

---

## 7. MIGRATION NOTES (old roster → new, applied at port time)
Everywhere in extracted prose or ported logic: `energy`→delete, `motion`→`physics`, `void`→`fate` (mechanics) — EXCEPT engineerCrisis's ore cost which is `emotion` (§1.9). `motionPowder`→`enhancementPowder` ("Enhancement Powder", life-type ingredient). `motionDevice`→`enhancementDevice`. Flag `motionPowderUnlocked`→`enhancementUnlocked`. In prose: "Motion calc, forty units" → "Physics calc, forty units"; "Motion powder. It's straightforward. Motion orichalchum," → "Enhancement powder. It's straightforward. Life orichalchum," (see CONTENT-GUIDE.md patch list). Combat state field names `motionTurns`/`motionPower` are retained as internal names.
