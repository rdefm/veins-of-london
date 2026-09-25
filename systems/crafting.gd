class_name Crafting
extends RefCounted

# Recipe crafting per R§3.5. Static funcs only. Crafting is not time-block
# gated (matches the HTML prototype: attemptCraft never calls
# advanceTimeBlock — only seed/cultivate/harvest are).

# The Lab's batch-craft quantity picker is a UI convenience, not a balance
# knob -- capped generously to keep the state tree and stepper sane.
const MAX_BATCH_QTY := 99


static func craft_chance(recipe_key: String, skill: int) -> float:
	var r: Dictionary = GameData.RECIPES[recipe_key]
	return min(0.95, r["baseSuccess"] + (skill - 1) * 0.13 + Home.get_workshop_bonus())


# A recipe can have more than one ingredient ore type -- these are what
# Dial.attunement_bonus() matches a seated Movement's attunement against.
static func recipe_ore_types(recipe_key: String) -> Array:
	var r: Dictionary = GameData.RECIPES[recipe_key]
	return r["ingredients"].keys()


static func calc_cost(recipe_key: String, skill: int) -> Dictionary:
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var costs := {}
	for ingredient in r["ingredients"]:
		var base: int = r["ingredients"][ingredient]
		costs[ingredient] = maxi(1, GameState.round_epsilon(base - (skill - 1) * 0.8))
	return costs


# Shared by effect_power()/quality_tier(): returns the active Bench refine
# tier if refined past 0 and refineStep targets effectPower, else -1.
static func _active_refine_tier(recipe_key: String) -> int:
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var discovery: Dictionary = r.get("discovery", {})
	var refine_step: Dictionary = r.get("refineStep", {})
	if discovery.is_empty() or refine_step.get("field") != "effectPower":
		return -1
	var tier: int = Bench.get_cell(discovery["types"], discovery["approach"])["refine"]
	return tier if tier > 0 else -1


static func effect_power(recipe_key: String, skill: int) -> Variant:
	var refine_tier := _active_refine_tier(recipe_key)
	if refine_tier > 0:
		var r: Dictionary = GameData.RECIPES[recipe_key]
		var discovery: Dictionary = r["discovery"]
		return Bench.refined_value(recipe_key, discovery["types"], discovery["approach"], skill)
	var powers: Array = GameData.RECIPES[recipe_key]["effectPower"]
	return powers[skill]


# The quality tier a craft right now would produce -- the inventory bucket a
# successful craft files under, and what Economy scales sale price by.
static func quality_tier(recipe_key: String, skill: int) -> int:
	var refine_tier := _active_refine_tier(recipe_key)
	return refine_tier if refine_tier > 0 else skill


# player.inventory[recipe_key] is { "<tier>": count, ... }, keys stringified
# (JSON). Tier "0" means "no known quality" -- migrated (SaveManager.
# _migrate_inventory) or added outside crafting (purchase/grant).

static func inventory_qty(recipe_key: String) -> int:
	var buckets: Dictionary = GameState.state["player"]["inventory"].get(recipe_key, {})
	var total := 0
	for tier_key in buckets:
		total += int(buckets[tier_key])
	return total


static func inventory_add(recipe_key: String, tier: int, qty: int = 1) -> void:
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	if not (inventory.get(recipe_key) is Dictionary):
		inventory[recipe_key] = {}
	var buckets: Dictionary = inventory[recipe_key]
	var key := str(tier)
	buckets[key] = buckets.get(key, 0) + qty
	if qty > 0:
		EventBus.shared_stock_increased.emit()


# Removes lowest tier first -- keeps higher-quality stock for Economy's
# price-by-tier sale; other consumers recompute effect_power() from current
# skill regardless of tier. Assumes the caller already confirmed stock.
static func inventory_remove(recipe_key: String, qty: int) -> void:
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	var buckets: Dictionary = inventory.get(recipe_key, {})
	var remaining := qty
	var tier_keys: Array = buckets.keys()
	tier_keys.sort_custom(func(a, b): return int(a) < int(b))
	for tier_key in tier_keys:
		if remaining <= 0:
			break
		var have: int = buckets[tier_key]
		var take: int = mini(have, remaining)
		buckets[tier_key] = have - take
		remaining -= take
	for tier_key in buckets.keys().duplicate():
		if buckets[tier_key] <= 0:
			buckets.erase(tier_key)


# Removes `qty` from one specific tier -- Economy.execute_sale needs to
# charge that exact tier's price, not lowest-first like inventory_remove().
static func inventory_remove_from_tier(recipe_key: String, tier: int, qty: int) -> void:
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	var buckets: Dictionary = inventory.get(recipe_key, {})
	var key := str(tier)
	var have: int = buckets.get(key, 0)
	var new_qty: int = maxi(0, have - qty)
	if new_qty <= 0:
		buckets.erase(key)
	else:
		buckets[key] = new_qty


# Why a craft of recipe_key would be refused right now, or "" if it wouldn't
# -- the one string a disabled Craft button shows and attempt_craft() returns.
static func craft_block_reason(recipe_key: String) -> String:
	var skill: int = GameState.state["player"]["craftingSkill"]
	var costs: Dictionary = calc_cost(recipe_key, skill)
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	for ingredient in costs:
		if orichalchum.get(ingredient, 0) < costs[ingredient]:
			return "Not enough calc."
	return ""


static func can_craft(recipe_key: String) -> bool:
	return craft_block_reason(recipe_key) == ""


static func attempt_craft(recipe_key: String) -> Dictionary:
	var reason := craft_block_reason(recipe_key)
	if reason != "":
		return { "ok": false, "reason": reason }

	var player: Dictionary = GameState.state["player"]
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var skill: int = player["craftingSkill"]
	var costs: Dictionary = calc_cost(recipe_key, skill)

	# Deducted regardless of outcome.
	for ingredient in costs:
		player["orichalchum"][ingredient] = maxi(0, player["orichalchum"].get(ingredient, 0) - costs[ingredient])

	# The player's own craft gets the seated Movement's attunement bonus when
	# its ore type matches an ingredient; craft_chance() stays untouched since
	# Rooms._producer_act() also calls it for contact crafting (no Dial there).
	var attunement := 0.0
	for ingredient_ore in recipe_ore_types(recipe_key):
		attunement = maxf(attunement, Dial.attunement_bonus(ingredient_ore))
	var chance: float = min(0.95, craft_chance(recipe_key, skill) + attunement)
	var success: bool = Rng.chance(chance)
	if success:
		var power = effect_power(recipe_key, skill)
		inventory_add(recipe_key, quality_tier(recipe_key, skill))
		var counts: Dictionary = player["craftedCounts"]
		counts[recipe_key] = int(counts.get(recipe_key, 0)) + 1
		award_crafting_xp(r["xpReward"])
		Objectives.refresh()
		Collective.award_a2_missions()
		Collective.maybe_trigger_a2_nadia_defend_brief()
		Modal.open("craft_result", { "success": true, "recipeKey": recipe_key, "power": power })
		return { "ok": true, "success": true, "recipeKey": recipe_key, "power": power }
	else:
		award_crafting_xp(int(floor(float(r["xpReward"]) / 3.0)))
		Modal.open("craft_result", { "success": false, "recipeKey": recipe_key, "power": 0 })
		return { "ok": true, "success": false, "recipeKey": recipe_key, "power": 0 }


# state.craftQty is keyed by recipeKey, transient like state.sellState. int()
# guards a stored float since craftQty isn't restored across save/load.
static func get_craft_qty(recipe_key: String) -> int:
	return int(GameState.state["craftQty"].get(recipe_key, 1))


static func adjust_craft_qty(recipe_key: String, delta: int) -> void:
	var current: int = get_craft_qty(recipe_key)
	GameState.state["craftQty"][recipe_key] = clampi(current + delta, 1, MAX_BATCH_QTY)
	EventBus.state_changed.emit()


# Loops attempt_craft() `quantity` times, each independently rolled and
# deducted. Stops early if can_craft() would refuse the next attempt, so
# running low on calc mid-batch just yields a short `attempts` list.
static func attempt_craft_batch(recipe_key: String, quantity: int) -> Dictionary:
	var attempts: Array[Dictionary] = []
	var successes := 0
	for i in range(quantity):
		var result := attempt_craft(recipe_key)
		if not result["ok"]:
			break
		attempts.append(result)
		if result["success"]:
			successes += 1

	var batch := {
		"ok": true,
		"recipeKey": recipe_key,
		"requested": quantity,
		"completed": attempts.size(),
		"successes": successes,
		"attempts": attempts,
	}
	Modal.open("craft_batch_result", batch)
	return batch


# No skill-up notification here — matches the HTML prototype, where
# awardCraftingXP (unlike awardCultivatingXP) never calls pushNotification.
static func award_crafting_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	Progression.award_xp(player, "craftingXP", "craftingSkill", GameData.CRAFTING_XP_LEVELS, amount)
