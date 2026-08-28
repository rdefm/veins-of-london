class_name Dial
extends RefCounted

# The Dial device mechanic. Static funcs only, same discipline as
# sites.gd/crafting.gd. Per .scratch/dial-device/spec.md:
# - ticket 01: state shape, gift gate, and seeding an inert Dial (no
#   Movement, no charge, no regen).
# - ticket 02: Movement crafting, seating/unseating, and the seated
#   Movement's attunement bonus.
# - ticket 03: Complications -- load, unload, and the Dial-level capacity
#   budget.
# - ticket 04: the charge pool itself -- seating/unseating now activate/
#   deactivate it, winding spends calc to fill it, and daily_regen() ticks
#   it once a day.
# - ticket 05: casting a loaded Complication -- spends one charge (not the
#   item), computes the base effect from Crafting.effect_power() at the
#   loaded unit's tier, and amplifies it per the seated Movement's
#   archetype. combat_turn_tick() gives a tier-5 Recharge Movement its
#   in-combat regen.
# - ticket 06: Dial XP and leveling -- casting a loaded Complication awards
#   XP (Progression.award_xp(), same table mechanism as the old
#   DEVICE_XP_LEVELS). maxCharge and capacityMax grow every level (the
#   primary curves); rechargeRate grows on a deliberately sparser curve.
#   Movements never modify capacity, and levelling never touches which
#   Movement is seated or its attunement.
# - ticket 07 (cutover): systems/devices.gd and data/devices.json are
#   deleted outright. combat.gd's player_attack() calls combat_turn_tick()
#   once per player turn; combat.gd's cast_complication() and combat_rewind()
#   call cast_complication() above; time_system.gd's daily_tick calls
#   daily_regen() in place of the old Devices.reset_daily_charges().


static func seed_success_chance() -> float:
	var player: Dictionary = GameState.state["player"]
	# The "craftChance-style term": same shape as Crafting.craft_chance()
	# (baseSuccess + skill ramp + workshop bonus), but seeding has no
	# recipeKey to key a baseSuccess off of, so GameData.DIAL_SEED_BASE_
	# SUCCESS stands in for r.baseSuccess.
	var craft_term: float = min(0.95, GameData.DIAL_SEED_BASE_SUCCESS + (player["craftingSkill"] - 1) * 0.13 + Home.get_workshop_bonus())
	# The "cultChance-style term": Cultivating's own existing formula,
	# called directly -- reused, not reimplemented.
	var cult_term: float = Cultivating.get_cult_chance(player["cultivatingSkill"])
	return clampf((craft_term + cult_term) / 2.0, 0.05, 0.95)


# Single-roll risk model, same shape as Sites.attempt_seed: pay the full
# mixed five-ore-type cost, roll once, fail = cost gone, no partial state.
# Refused outright once player.dial is already non-null (no second Dial,
# ever) or the gift flag isn't set.
static func attempt_seed(haft_id: String) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] != null:
		return { "ok": false, "reason": "You already have a Dial." }
	if not GameState.state["flags"].get("dialGiftGranted", false):
		return { "ok": false, "reason": "You don't have the gift." }
	if not GameData.DIAL_HAFTS.has(haft_id):
		return { "ok": false, "reason": "Unknown haft." }

	var cost: Dictionary = GameData.DIAL_SEED_COST
	var orichalchum: Dictionary = player["orichalchum"]
	for ore_type in cost:
		if orichalchum.get(ore_type, 0) < cost[ore_type]:
			return { "ok": false, "reason": "Not enough calc." }

	# Deducted regardless of outcome -- the risk is real.
	for ore_type in cost:
		orichalchum[ore_type] = orichalchum.get(ore_type, 0) - cost[ore_type]

	var success: bool = Rng.chance(seed_success_chance())
	if success:
		player["dial"] = _new_dial(haft_id)

	EventBus.state_changed.emit()
	return { "ok": true, "success": success }


# Implementation Decisions, "Hafts": a trivial field write, no validation
# beyond "haft exists" -- there is no minimum-barrel-length check to
# implement (every whitelisted haft satisfies it by construction).
static func set_haft(haft_id: String) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return { "ok": false, "reason": "No Dial." }
	if not GameData.DIAL_HAFTS.has(haft_id):
		return { "ok": false, "reason": "Unknown haft." }

	player["dial"]["haftId"] = haft_id
	EventBus.state_changed.emit()
	return { "ok": true }


# dial-device ticket 07: shared by hq.gd and bag_drawer.gd's Dial cards --
# both rendered this same lookup independently before this ticket's cutover
# gave the Dial its first UI surfaces.
static func haft_name(dial: Dictionary) -> String:
	return GameData.DIAL_HAFTS.get(dial["haftId"], {}).get("name", dial["haftId"])


# dial-device ticket 07: shared by combat.gd's combat_rewind() and events.gd's
# rewind() -- a loaded "rewind" Complication with at least one charge stands
# in for the old equipped rewind device fallback (consumable is still
# preferred by both callers when available). Returns -1 if none.
static func find_loaded_rewind_complication_index() -> int:
	var dial: Variant = GameState.state["player"]["dial"]
	if dial == null or dial["currentCharge"] < 1:
		return -1
	var loaded: Array = dial["loadedComplications"]
	for i in range(loaded.size()):
		if loaded[i]["recipeKey"] == "rewind":
			return i
	return -1


# Fully inert on the charge side: no Movement seated, zero charge/regen
# (ticket 02 seats a Movement and gives the charge economy its real numbers;
# 06 gives level/xp their real growth curve). Complication capacity is NOT
# part of that inertness -- ticket 03's PRD decision is that capacity comes
# from the Dial-level lookup table alone, so a freshly-seeded level-1 Dial
# already has a real capacityMax and can load/unload Complications with no
# Movement seated at all.
static func _new_dial(haft_id: String) -> Dictionary:
	return {
		"level": 1,
		"xp": 0,
		"currentCharge": 0,
		"maxCharge": 0,
		"rechargeRate": 0,
		# dial-device ticket 05: Dial.combat_turn_tick()'s player-turn counter
		# toward the tier-5 Recharge Movement's in-combat regen tick --
		# reset alongside the rest of the charge pool on every (re)seat/
		# unseat, same as currentCharge below.
		"combatRegenTurnCounter": 0,
		# dial-device ticket 04: guards Dial.daily_regen() the same
		# lastResetDay way Devices.reset_daily_charges() guards
		# devicesCompleted -- set to the seeding day so a Dial seeded partway
		# through today doesn't regen again before tomorrow.
		"lastRegenDay": GameState.state["world"]["day"],
		"capacityMax": capacity_max(1),
		"movement": null,
		"loadedComplications": [],
		"haftId": haft_id,
	}


# ── ticket 02: Movement crafting, seating, and attunement ──────────────
#
# Movements are a Dial-only craftable, deliberately NOT folded into
# data/recipes.json/GameData.RECIPES (unlike Complications, ticket 03,
# which load *existing* consumable recipes as-is). Recipes are Economy-
# sellable, Lab-listed, contact-craftable (Rooms.process_lab) content;
# Movements are none of those things, so they get their own small data
# table (data/dial.json's "movements") and their own parallel crafting
# function here rather than leaking archetype entries into the consumable
# pipeline. The *contract* still matches the recipe pipeline exactly per
# the PRD: ingredients always spent, a craftChance-style roll gates
# success, tier = quality_tier() at craft time.


const MOVEMENT_ARCHETYPES: Array[String] = GameData.CANONICAL_MOVEMENT_ARCHETYPES


static func movement_craft_chance(archetype: String, skill: int) -> float:
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	# Same shape as Crafting.craft_chance() -- m["baseSuccess"] stands in
	# for a recipe's r["baseSuccess"], same as seed_success_chance()'s
	# craft_term above.
	return min(0.95, m["baseSuccess"] + (skill - 1) * 0.13 + Home.get_workshop_bonus())


# Same shape as Crafting.calc_cost(), but a Movement has exactly one
# ingredient -- the ore type the player chose as attunement -- rather than
# a recipe's fixed ingredients dict.
static func movement_calc_cost(archetype: String, skill: int) -> int:
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	return maxi(1, GameState.round_epsilon(m["ingredientBase"] - (skill - 1) * 0.8))


static func can_craft_movement(archetype: String, ore_type: String) -> bool:
	if not MOVEMENT_ARCHETYPES.has(archetype):
		return false
	if not GameData.ORE_TYPES.has(ore_type):
		return false
	var skill: int = GameState.state["player"]["craftingSkill"]
	var cost: int = movement_calc_cost(archetype, skill)
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	return orichalchum.get(ore_type, 0) >= cost


# User story 7/8/10: the player picks the archetype AND the ore type;
# ingredients are spent regardless of outcome (deducted before the roll,
# same as Crafting.attempt_craft()); on success the crafted Movement lands
# in player.movementInventory (unseated -- User story 6 keeps a freshly
# crafted Movement from auto-seating itself) with the chosen ore type
# recorded as its attunement and its tier set at craft time.
static func attempt_craft_movement(archetype: String, ore_type: String) -> Dictionary:
	if not MOVEMENT_ARCHETYPES.has(archetype):
		return { "ok": false, "reason": "Unknown Movement archetype." }
	if not GameData.ORE_TYPES.has(ore_type):
		return { "ok": false, "reason": "Unknown ore type." }
	if not can_craft_movement(archetype, ore_type):
		return { "ok": false, "reason": "Not enough calc." }

	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var cost: int = movement_calc_cost(archetype, skill)
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]

	# Deducted regardless of outcome -- Crafting.attempt_craft()'s contract.
	player["orichalchum"][ore_type] = maxi(0, player["orichalchum"].get(ore_type, 0) - cost)

	var success: bool = Rng.chance(movement_craft_chance(archetype, skill))
	if success:
		# Movements have no refine/discovery step (that's a Bench/recipe
		# mechanic -- see Crafting._active_refine_tier()), so tier is always
		# just the crafting skill at craft time: Crafting.quality_tier()'s
		# own non-refined branch, restated here since a Movement archetype
		# has no GameData.RECIPES entry for that function to key off of.
		var tier: int = skill
		var movement := _new_movement(archetype, ore_type, tier)
		player["movementInventory"].append(movement)
		Crafting.award_crafting_xp(m["xpReward"])
		EventBus.state_changed.emit()
		return { "ok": true, "success": true, "archetype": archetype, "oreType": ore_type, "tier": tier }
	else:
		Crafting.award_crafting_xp(int(floor(float(m["xpReward"]) / 3.0)))
		EventBus.state_changed.emit()
		return { "ok": true, "success": false }


static func _new_movement(archetype: String, ore_type: String, tier: int) -> Dictionary:
	return { "archetype": archetype, "oreType": ore_type, "tier": tier }


# User story 7/9: seats the Movement at `inventory_index`, swapping out
# (never destroying) whatever was seated before -- fully reversible in
# both directions. Ticket 04's _activate_charge_pool() (below) sizes
# maxCharge/rechargeRate from the newly-seated Movement's archetype/tier
# and resets currentCharge to 0 -- a reseat is a different physical
# mechanism, so it never inherits whatever reserve the previous one held.
static func seat_movement(inventory_index: int) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return { "ok": false, "reason": "No Dial." }
	var inventory: Array = player["movementInventory"]
	if inventory_index < 0 or inventory_index >= inventory.size():
		return { "ok": false, "reason": "No such Movement." }

	var incoming: Dictionary = inventory[inventory_index]
	var dial: Dictionary = player["dial"]
	var previous: Variant = dial["movement"]

	inventory.remove_at(inventory_index)
	if previous != null:
		inventory.append(previous)
	dial["movement"] = incoming
	_activate_charge_pool(dial)

	EventBus.state_changed.emit()
	return { "ok": true }


# User story 9: the seated Movement (if any) goes back to inventory intact,
# not destroyed. A Dial with no Movement seated is a no-op refusal, not an
# error -- matches every other "nothing to do" refusal shape in this file.
# Ticket 04's _deactivate_charge_pool() (below) zeroes the charge pool back
# to ticket 01's inert-Dial shape -- no attunement, no charge, no regen.
static func unseat_movement() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return { "ok": false, "reason": "No Dial." }
	var dial: Dictionary = player["dial"]
	if dial["movement"] == null:
		return { "ok": false, "reason": "No Movement seated." }

	player["movementInventory"].append(dial["movement"])
	dial["movement"] = null
	_deactivate_charge_pool(dial)

	EventBus.state_changed.emit()
	return { "ok": true }


# User story 17/18: a flat additive bonus to whichever chance formula the
# caller is about to roll, driven exclusively by the seated Movement (never
# by player.dial.loadedComplications, which doesn't even exist yet --
# ticket 03) and only when `ore_type` matches its attunement. Magnitude
# scales with the seated Movement's tier, per data/dial.json's
# attunementBonusByTier -- shared across all four archetypes, since the
# PRD ties it to tier only, not to archetype identity. Callers
# (Cultivating.cultivate(), Crafting.attempt_craft(), Sites.attempt_seed())
# add this directly onto their own existing chance formula; it is never
# baked into craft_chance()/get_cult_chance()/seed_success_chance()
# themselves, since those are also rolled for NPC contacts (Rooms.
# process_lab/process_vein_station), who don't have -- and must never
# benefit from -- the player's own Dial.
static func attunement_bonus(ore_type: String) -> float:
	var dial: Variant = GameState.state["player"]["dial"]
	if dial == null:
		return 0.0
	var movement: Variant = dial["movement"]
	if movement == null:
		return 0.0
	if movement["oreType"] != ore_type:
		return 0.0
	var curve: Array = GameData.DIAL_ATTUNEMENT_BONUS_BY_TIER
	var tier: int = clampi(movement["tier"], 0, curve.size() - 1)
	return curve[tier]


# Shared by every single-ore-type player action that rolls a chance formula
# and wants the seated Movement's attunement bonus added on top (Cultivating.
# cultivate(), Sites.attempt_seed()) -- clamps the same 0.95 ceiling every
# one of those formulas' own base chance already uses. Crafting.
# attempt_craft() doesn't call this directly: a recipe can spend more than
# one ore type (healingBurst/failsafe both spend time+life), so it checks
# attunement_bonus() against each of the recipe's ingredient ore types
# itself before clamping.
static func apply_attunement(base_chance: float, ore_type: String) -> float:
	return min(0.95, base_chance + attunement_bonus(ore_type))


# ── ticket 03: Complications -- load, unload, and capacity budget ──────
#
# No new item category: loading moves one unit out of Crafting's existing
# tier-bucketed player.inventory (systems/crafting.gd's "Inventory" section)
# into player.dial.loadedComplications, unchanged in tier; unloading reverses
# it exactly. Each loaded entry is { recipeKey, tier, capacityCost, detent }
# -- capacityCost is copied from the recipe's fixed data/recipes.json field
# at load time (independent of crafted tier, so a better-tier craft of
# something already loaded is never a footprint downside); detent is a
# cosmetic display-order position for the (out-of-scope) Collar UI, assigned
# as the entry's index at load time -- no code here or elsewhere reads it
# for anything but display, same as haftId.


# User story 25: capacity comes from a Dial-level lookup table only, per
# data/dial.json's capacityByLevel -- never from which Movement (if any) is
# seated. Mirrors attunement_bonus()'s tier-indexed curve read.
static func capacity_max(level: int) -> int:
	var curve: Array = GameData.DIAL_CAPACITY_BY_LEVEL
	var idx: int = clampi(level, 0, curve.size() - 1)
	return curve[idx]


static func capacity_used(dial: Dictionary) -> int:
	var total := 0
	for entry in dial["loadedComplications"]:
		total += entry["capacityCost"]
	return total


# User story 19/20/21: moves one unit of `recipe_key` at `tier` out of the
# regular tiered inventory and appends it to loadedComplications at the
# recipe's fixed capacity cost. Refused once it would push capacityUsed past
# the Dial's stored capacityMax (User story 24) -- that field is populated
# from capacity_max() at seed time (_new_dial()) and never touched by
# seat_movement()/unseat_movement() above, so this works identically with no
# Movement seated (User story 6/25).
static func load_complication(recipe_key: String, tier: int) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return { "ok": false, "reason": "No Dial." }
	if not GameData.RECIPES.has(recipe_key):
		return { "ok": false, "reason": "Unknown recipe." }

	var buckets: Dictionary = player["inventory"].get(recipe_key, {})
	var tier_key := str(tier)
	if buckets.get(tier_key, 0) <= 0:
		return { "ok": false, "reason": "Nothing to load." }

	var dial: Dictionary = player["dial"]
	var cost: int = GameData.RECIPES[recipe_key]["capacityCost"]
	if capacity_used(dial) + cost > dial["capacityMax"]:
		return { "ok": false, "reason": "Not enough capacity." }

	Crafting.inventory_remove_from_tier(recipe_key, tier, 1)
	var loaded: Array = dial["loadedComplications"]
	loaded.append({ "recipeKey": recipe_key, "tier": tier, "capacityCost": cost, "detent": loaded.size() })

	EventBus.state_changed.emit()
	return { "ok": true }


# Reverses load_complication() exactly: the unit returns to the same tier
# bucket it came from (Crafting.inventory_add(), tier-keyed exactly like
# inventory_remove_from_tier() removed it), not duplicated or destroyed.
# `index` addresses loadedComplications directly (mirrors seat_movement()'s
# inventory_index) since two loaded units can share the same recipeKey/tier.
static func unload_complication(index: int) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return { "ok": false, "reason": "No Dial." }
	var loaded: Array = player["dial"]["loadedComplications"]
	if index < 0 or index >= loaded.size():
		return { "ok": false, "reason": "No such Complication." }

	var entry: Dictionary = loaded[index]
	loaded.remove_at(index)
	Crafting.inventory_add(entry["recipeKey"], entry["tier"], 1)

	EventBus.state_changed.emit()
	return { "ok": true }


# ── ticket 04: charge pool lifecycle, winding, and daily regen ─────────
#
# Charge only exists while a Movement is seated: seat_movement() above
# calls _activate_charge_pool() to size maxCharge/rechargeRate from the
# newly-seated Movement's archetype/tier (and starts currentCharge at 0);
# unseat_movement() calls _deactivate_charge_pool() to zero all three back
# to ticket 01's inert-Dial shape. Once seated, maxCharge/rechargeRate are
# fixed until the next reseat -- winding and daily_regen() below only ever
# move currentCharge between 0 and maxCharge, never those two stats.
#
# Per the design doc's "biases X up, Y down" framing (docs/device-plan-
# spec.md's Movement archetypes section), each archetype's ticket-02
# bonus/downside curve feeds exactly one charge-economy stat each: Recharge's
# bonus raises rechargeRate, its downside lowers maxCharge; Capacitor's
# bonus raises maxCharge, its downside lowers rechargeRate (floored at 0 --
# User story 15 makes tier 5 an explicit, guaranteed zero, not merely a
# numeric consequence of the curve, since a human could retune the curve
# later without noticing it stopped reaching zero). Impact and Spread have
# no charge-economy bonus at all -- their "bonus" curve is ticket 05's
# effect-magnitude/extra-target territory -- so only their downside applies,
# and only to maxCharge (the shared charge-economy cost of the "amplify
# pair", per the design doc).


static func _charge_stats_for(archetype: String, tier: int) -> Dictionary:
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	var t: int = clampi(tier, 0, m["bonus"].size() - 1)
	var bonus: float = m["bonus"][t]
	var downside: float = m["downside"][t]

	var max_charge: float = GameData.DIAL_BASE_MAX_CHARGE
	var recharge_rate: float = GameData.DIAL_BASE_RECHARGE_RATE
	match archetype:
		"recharge":
			recharge_rate += bonus
			max_charge -= downside
		"capacitor":
			max_charge += bonus
			recharge_rate -= downside
		_:
			max_charge -= downside

	recharge_rate = maxf(0.0, recharge_rate)
	if archetype == "capacitor" and t == 5:
		recharge_rate = 0.0  # User story 15: tier-5 Capacitor's defining trait -- guaranteed, not just a consequence of the downside curve's numbers.

	# maxCharge is the Collar's countable power-reserve pips (design doc
	# §Charge model) -- an integer, unlike rechargeRate, which the PRD calls
	# out as "possibly fractional". currentCharge (wind()/daily_regen(),
	# below) is left free to hold that same fractional remainder between
	# whole charges -- it's the pips filled, not the pip count -- so a
	# fractional rechargeRate accumulates smoothly across days instead of
	# being truncated away each tick.
	return { "maxCharge": maxi(1, GameState.round_epsilon(max_charge)), "rechargeRate": recharge_rate }


# ── ticket 06: Dial XP and leveling ─────────────────────────────────────
#
# maxCharge/rechargeRate stay Movement-sized (_charge_stats_for() above) as
# their base -- levelling adds an extra layer on top, read from these two
# level-indexed curves (data/dial.json's "maxChargeBonusByLevel"/
# "rechargeRateBonusByLevel", index=level 0..5, same shape as
# capacityByLevel). maxCharge's curve grows every level (the PRD's "primary"
# curve); rechargeRate's is deliberately sparser -- most entries 0, so most
# level-ups leave it untouched. Both curves are 0 at level 1, so a
# freshly-seeded/freshly-seated level-1 Dial is numerically identical to the
# pre-ticket-06 Movement-only stats -- ticket 04's own tests all fix a
# level-1 dial and stay green unmodified.


static func max_charge_level_bonus(level: int) -> float:
	var curve: Array = GameData.DIAL_MAX_CHARGE_BONUS_BY_LEVEL
	var idx: int = clampi(level, 0, curve.size() - 1)
	return curve[idx]


static func recharge_rate_level_bonus(level: int) -> float:
	var curve: Array = GameData.DIAL_RECHARGE_RATE_BONUS_BY_LEVEL
	var idx: int = clampi(level, 0, curve.size() - 1)
	return curve[idx]


# Shared by _activate_charge_pool() (a reseat) and cast_complication()'s
# on-level-up callback (a level-up with the same Movement still seated) --
# both need maxCharge/rechargeRate recomputed from (seated Movement,
# dial.level), just with different side effects around the call (a reseat
# also zeroes currentCharge/combatRegenTurnCounter; a level-up touches
# neither). A null dial["movement"] is a silent no-op -- an unseated Dial
# stays inert regardless of level, matching ticket 01/04's inertness story.
static func _apply_level_charge_bonus(dial: Dictionary) -> void:
	var movement: Variant = dial["movement"]
	if movement == null:
		return
	var stats: Dictionary = _charge_stats_for(movement["archetype"], movement["tier"])
	var level: int = dial["level"]
	dial["maxCharge"] = maxi(1, GameState.round_epsilon(float(stats["maxCharge"]) + max_charge_level_bonus(level)))
	var recharge_rate: float = stats["rechargeRate"] + recharge_rate_level_bonus(level)
	# User story 15's guaranteed-zero trait is re-asserted here, not just
	# inherited from _charge_stats_for()'s own clamp -- otherwise Dial
	# levelling's rechargeRate bonus would quietly undo tier-5 Capacitor's
	# defining "must actively wind" commitment.
	if movement["archetype"] == "capacitor" and movement["tier"] >= 5:
		recharge_rate = 0.0
	dial["rechargeRate"] = recharge_rate


static func _activate_charge_pool(dial: Dictionary) -> void:
	_apply_level_charge_bonus(dial)
	dial["currentCharge"] = 0
	dial["combatRegenTurnCounter"] = 0


static func _deactivate_charge_pool(dial: Dictionary) -> void:
	dial["maxCharge"] = 0
	dial["rechargeRate"] = 0
	dial["currentCharge"] = 0
	dial["combatRegenTurnCounter"] = 0


# User story 30: a lookup keyed only by (archetype, tier) -- never by
# dial.level or dial.maxCharge -- so levelling the Dial never makes winding
# worse. Pure data read, no state access, same shape as
# movement_craft_chance()/movement_calc_cost() above.
static func winding_cost_per_charge(archetype: String, tier: int) -> int:
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	var t: int = clampi(tier, 0, m["windingCostPerCharge"].size() - 1)
	return m["windingCostPerCharge"][t]


# User story 29: instant, no time-block cost, calc-only -- winding never
# competes with the game's 3-blocks/day resource. `amount` (default 1) is
# silently clamped to however much headroom is left under maxCharge, so a
# request for more charge than the pool can hold never overspends calc for
# charge that would just be discarded at the cap. Calc type is always the
# seated Movement's attunement (User story 29); cost-per-charge comes only
# from winding_cost_per_charge() above (User story 30).
static func wind(amount: int = 1) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return { "ok": false, "reason": "No Dial." }
	var dial: Dictionary = player["dial"]
	if dial["movement"] == null:
		return { "ok": false, "reason": "No Movement seated." }
	if amount <= 0:
		return { "ok": false, "reason": "Nothing to wind." }
	if dial["currentCharge"] >= dial["maxCharge"]:
		return { "ok": false, "reason": "Charge is already full." }

	var headroom: int = int(ceil(dial["maxCharge"] - dial["currentCharge"]))
	var actual_amount: int = mini(amount, headroom)

	var movement: Dictionary = dial["movement"]
	var cost_per_charge: int = winding_cost_per_charge(movement["archetype"], movement["tier"])
	var total_cost: int = cost_per_charge * actual_amount
	var ore_type: String = movement["oreType"]
	var orichalchum: Dictionary = player["orichalchum"]
	if orichalchum.get(ore_type, 0) < total_cost:
		return { "ok": false, "reason": "Not enough calc." }

	orichalchum[ore_type] -= total_cost
	dial["currentCharge"] = minf(dial["maxCharge"], dial["currentCharge"] + actual_amount)

	EventBus.state_changed.emit()
	return { "ok": true, "chargeAdded": actual_amount, "calcSpent": total_cost }


# User story 28: natural regen ticks once per day as part of the existing
# daily cycle. Called from time_system.gd's daily_tick (dial-device ticket
# 07, replacing the old Devices.reset_daily_charges() step). Guarded the
# same lastRegenDay way the old reset_daily_charges() guarded each device's
# lastResetDay, so calling this more than once on the same day is a
# no-op -- including the unconditional trailing emit, which mirrors that
# old function's own unconditional emit exactly, not a mutation-gated one.
# A null dial (no Dial seeded yet) is a silent no-op, not an error.
static func daily_regen() -> void:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return
	var dial: Dictionary = player["dial"]
	var day: int = GameState.state["world"]["day"]
	if dial["lastRegenDay"] < day:
		dial["currentCharge"] = minf(dial["maxCharge"], dial["currentCharge"] + dial["rechargeRate"])
		dial["lastRegenDay"] = day
	EventBus.state_changed.emit()


# ── ticket 05: casting a loaded Complication ────────────────────────────
#
# Casting spends one charge from the pool ticket 04 built rather than
# destroying the loaded unit -- loaded units already left the regular
# tiered inventory at load time (ticket 03), so this never touches
# player.inventory at all. Base effect is Crafting.effect_power() at the
# tier the unit was *loaded* at (recorded on the loadedComplications entry,
# ticket 03) -- deliberately not the player's *current* crafting skill,
# unlike the direct-throw use_*() functions in combat.gd, which always
# recompute from current skill. That divergence is the point: a
# Complication is a specific crafted unit sitting in a specific detent, and
# its effect shouldn't drift just because the player's skill moved on.
#
# Amplification reuses ticket 02's per-archetype "bonus" tier-indexed array
# -- ticket 04 already claimed that array for Recharge/Capacitor's charge
# economy, so per the PRD only Impact (a multiplicative boost to raw
# power) and Spread (extra full-power targets, no dilution) read it here;
# Recharge/Capacitor seated leaves power/targets at their unamplified
# defaults, same as no Movement seated at all. Directly-thrown consumables
# (combat.gd's use_blast()/use_time_pearl()/etc.) never call this function
# and never amplify -- untouched regression surface, per the PRD.
static func cast_complication(index: int) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return { "ok": false, "reason": "No Dial." }
	var dial: Dictionary = player["dial"]
	var loaded: Array = dial["loadedComplications"]
	if index < 0 or index >= loaded.size():
		return { "ok": false, "reason": "No such Complication." }
	if dial["currentCharge"] < 1:
		return { "ok": false, "reason": "Not enough charge." }

	var entry: Dictionary = loaded[index]
	var recipe_key: String = entry["recipeKey"]
	var base_power = Crafting.effect_power(recipe_key, entry["tier"])
	var amplified := _amplify_cast(base_power, dial["movement"])

	dial["currentCharge"] -= 1

	# ticket 06: mirrors Devices.activate()'s old device-activation XP award
	# (same +10 amount, same Progression.award_xp() table mechanism) --
	# levelling up grows capacityMax (ticket 03's level lookup, unconditional)
	# and, if a Movement is currently seated, re-derives maxCharge/
	# rechargeRate from that Movement's stats plus the new level's bonus
	# curves (_apply_level_charge_bonus()). An unseated Dial just banks the
	# level/capacity growth and stays inert on the charge side, same as
	# ticket 01/04's inertness story.
	var on_level_up := func():
		dial["capacityMax"] = capacity_max(dial["level"])
		_apply_level_charge_bonus(dial)
		Notify.push("Your Dial has levelled up — now level %d." % dial["level"], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(dial, "xp", "level", GameData.DIAL_XP_LEVELS, 10, on_level_up)

	EventBus.state_changed.emit()
	return { "ok": true, "recipeKey": recipe_key, "power": amplified["power"], "targets": amplified["targets"] }


# Split out of cast_complication() so the archetype-specific math is a pure
# function of (base_power, movement) -- easy to unit-test in isolation from
# the charge-spend/refusal plumbing above.
static func _amplify_cast(base_power: Variant, movement: Variant) -> Dictionary:
	if movement == null:
		return { "power": base_power, "targets": 1 }

	var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
	var t: int = clampi(movement["tier"], 0, m["bonus"].size() - 1)
	match movement["archetype"]:
		"impact":
			# User story 26: a multiplicative boost to the crafted base
			# power -- e.g. tier 5's bonus of 1.2 more than doubles it.
			return { "power": GameState.round_epsilon(float(base_power) * (1.0 + m["bonus"][t])), "targets": 1 }
		"spread":
			# User story 16: every target gets the untouched base_power --
			# the archetype's whole point is no per-target dilution -- and
			# the tier-indexed bonus is an integer extra-target count on
			# top of the normal single target.
			return { "power": base_power, "targets": 1 + int(m["bonus"][t]) }
		_:
			# Recharge/Capacitor: their "bonus" array is ticket 04's charge
			# economy, not effect magnitude -- casting under either is
			# identical to casting with no Movement seated at all.
			return { "power": base_power, "targets": 1 }


# ── ticket 05: tier-5 Recharge Movement's in-combat regen ──────────────
#
# The only archetype whose top tier changes *when* charge regenerates
# (design doc §Movement archetypes): every other Movement only recharges
# between fights (daily_regen()) or via winding. Called once per player
# combat turn from combat.gd's player_attack() (dial-device ticket 07). A
# null dial, no Movement, or anything other than a tier-5 Recharge Movement
# seated is a silent no-op with no state change and no emit, since there is
# nothing to tick.
static func combat_turn_tick() -> void:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return
	var dial: Dictionary = player["dial"]
	var movement: Variant = dial["movement"]
	if movement == null or movement["archetype"] != "recharge" or movement["tier"] < 5:
		return

	dial["combatRegenTurnCounter"] = dial.get("combatRegenTurnCounter", 0) + 1
	if dial["combatRegenTurnCounter"] >= GameData.DIAL_RECHARGE_COMBAT_REGEN_TURNS:
		dial["combatRegenTurnCounter"] = 0
		dial["currentCharge"] = minf(dial["maxCharge"], dial["currentCharge"] + GameData.DIAL_RECHARGE_COMBAT_REGEN_AMOUNT)

	EventBus.state_changed.emit()
