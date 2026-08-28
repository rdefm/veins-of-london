class_name Dial
extends RefCounted

# The Dial device mechanic. Static funcs only, same discipline as
# sites.gd/crafting.gd. Per .scratch/dial-device/spec.md:
# - ticket 01: state shape, gift gate, and seeding an inert Dial (no
#   Movement, no charge, no regen).
# - ticket 02: Movement crafting, seating/unseating, and the seated
#   Movement's attunement bonus. Charge/capacity/casting/leveling (tickets
#   03-06) still own everything the seeded/seated shape leaves at zero.
#
# systems/devices.gd and data/devices.json stay live and untouched until
# ticket 07's cutover -- this module doesn't call into them and they don't
# call into this one.


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
# both directions. Charge/regen fields are untouched here (ticket 01's
# inert-Dial shape stays inert on the seat/unseat step itself; ticket 04
# activates the charge pool from the newly-seated Movement's archetype/
# tier).
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

	EventBus.state_changed.emit()
	return { "ok": true }


# User story 9: the seated Movement (if any) goes back to inventory intact,
# not destroyed. A Dial with no Movement seated is a no-op refusal, not an
# error -- matches every other "nothing to do" refusal shape in this file.
static func unseat_movement() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return { "ok": false, "reason": "No Dial." }
	var dial: Dictionary = player["dial"]
	if dial["movement"] == null:
		return { "ok": false, "reason": "No Movement seated." }

	player["movementInventory"].append(dial["movement"])
	dial["movement"] = null

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
