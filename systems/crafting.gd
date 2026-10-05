class_name Crafting
extends RefCounted

# Recipe crafting per R§3.5. Static funcs only. Crafting is not time-block
# gated (matches the HTML prototype: attemptCraft never calls
# advanceTimeBlock — only seed/cultivate/harvest are).

static func craft_chance(recipe_key: String, skill: int) -> float:
	return _craft_chance(recipe_key, skill, Home.get_workshop_bonus())


# The same curve with no workshop bonus -- the player's Home is not a
# faction's (FactionSim crafting, R§1.8 `craftSkill`).
static func faction_craft_chance(recipe_key: String, skill: int) -> float:
	return _craft_chance(recipe_key, skill, 0.0)


static func _craft_chance(recipe_key: String, skill: int, bonus: float) -> float:
	var r: Dictionary = GameData.RECIPES[recipe_key]
	return min(0.95, r["baseSuccess"] + (skill - 1) * 0.13 + bonus)


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
		costs[ingredient] = maxi(1, GameState.round_epsilon(base - (skill - 1) * GameData.CRAFT_COST_PER_SKILL))
	return costs


# Power at an item tier (1..5) -- indexes the recipe's effectPower array directly.
static func effect_power(recipe_key: String, tier: int) -> Variant:
	var powers: Array = GameData.RECIPES[recipe_key]["effectPower"]
	return powers[clampi(tier, 1, powers.size() - 1)]


# Direct personal use: removes one unit (lowest tier first) and returns its
# effect power at the unit's stored tier. No Dial amplification.
static func use_one(recipe_key: String) -> Variant:
	var taken: Array = inventory_remove(recipe_key, 1)
	var tier: int = int(taken[0]["tier"]) if not taken.is_empty() else 1
	return effect_power(recipe_key, clampi(tier, 1, GameData.RECIPES[recipe_key]["effectPower"].size() - 1))


# The quality tier a craft right now would produce -- the inventory bucket a
# successful craft files under, and what Economy scales sale price by.
static func quality_tier(recipe_key: String) -> int:
	return Bench.item_tier(recipe_key)


# player.inventory[recipe_key] is { "<tier>": count, ... }, keys stringified
# (JSON). Tiers run 1..5; inventory_add() floors any lower tier at 1.

# Multi-target units live under a parallel inventory key, same tier buckets.
# Only Loadout reads that key; every other consumer sees single-target stock.
const MULTI_SUFFIX := "_multi"


static func inventory_key(recipe_key: String, multi: bool) -> String:
	return recipe_key + MULTI_SUFFIX if multi else recipe_key


# Whether the player may pick multi-target when crafting recipe_key right now:
# craftable list, and the bench tier has reached the minimum.
static func multi_craft_available(recipe_key: String) -> bool:
	var cfg: Dictionary = GameData.LOADOUT["multiTarget"]
	return cfg["craftable"].has(recipe_key) and quality_tier(recipe_key) >= int(cfg["minTier"])


# The checkbox state, false whenever multi isn't available.
static func get_craft_multi(recipe_key: String) -> bool:
	return bool(GameState.state["craftMulti"].get(recipe_key, false)) and multi_craft_available(recipe_key)


static func set_craft_multi(recipe_key: String, multi: bool) -> void:
	GameState.state["craftMulti"][recipe_key] = multi
	EventBus.state_changed.emit()


# True for items that always hit every target (Black Hole): no checkbox.
static func is_always_multi(recipe_key: String) -> bool:
	return GameData.LOADOUT["multiTarget"]["always"].has(recipe_key)


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
	var key := str(maxi(tier, 1))
	buckets[key] = buckets.get(key, 0) + qty


# Removes lowest tier first -- keeps higher-quality stock for Economy's
# price-by-tier sale; other consumers recompute effect_power() from current
# skill regardless of tier. Assumes the caller already confirmed stock.
# Returns what came out as [{ tier:int, qty:int }, ...], lowest tier first.
static func inventory_remove(recipe_key: String, qty: int) -> Array:
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	var buckets: Dictionary = inventory.get(recipe_key, {})
	var remaining := qty
	var tier_keys: Array = buckets.keys()
	tier_keys.sort_custom(func(a, b): return int(a) < int(b))
	var taken: Array = []
	for tier_key in tier_keys:
		if remaining <= 0:
			break
		var have: int = buckets[tier_key]
		var take: int = mini(have, remaining)
		buckets[tier_key] = have - take
		remaining -= take
		if take > 0:
			taken.append({ "tier": int(tier_key), "qty": take })
	for tier_key in buckets.keys().duplicate():
		if buckets[tier_key] <= 0:
			buckets.erase(tier_key)
	return taken


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


static func attempt_craft(recipe_key: String, multi: bool = false) -> Dictionary:
	multi = multi and multi_craft_available(recipe_key)
	var reason := craft_block_reason(recipe_key)
	if reason != "":
		return { "ok": false, "reason": reason }

	var player: Dictionary = GameState.state["player"]
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var skill: int = player["craftingSkill"]
	var costs: Dictionary = calc_cost(recipe_key, skill)
	Contracts.note_player_supplied(recipe_key)

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
		var tier := quality_tier(recipe_key)
		var power = effect_power(recipe_key, tier)
		inventory_add(inventory_key(recipe_key, multi), tier)
		Shares.record_craft(Shares.PLAYER, costs)
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


# The largest batch the player's unstashed calc covers at current skill: the
# scarcest ingredient decides. 0 when not even one craft is affordable.
static func max_craftable_qty(recipe_key: String) -> int:
	var costs: Dictionary = calc_cost(recipe_key, GameState.state["player"]["craftingSkill"])
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	var most := -1
	for ingredient in costs:
		var affordable: int = floori(float(orichalchum.get(ingredient, 0)) / float(costs[ingredient]))
		most = affordable if most < 0 else mini(most, affordable)
	return maxi(most, 0)


# state.craftQty is keyed by recipeKey, transient like state.sellState. Read
# back clamped to 1..max_craftable_qty() so a batch picked before calc was
# spent never exceeds what's affordable now; int() guards a stored float
# since craftQty isn't restored across save/load.
static func get_craft_qty(recipe_key: String) -> int:
	return _clamp_qty(recipe_key, int(GameState.state["craftQty"].get(recipe_key, 1)))


static func set_craft_qty(recipe_key: String, qty: int) -> void:
	GameState.state["craftQty"][recipe_key] = _clamp_qty(recipe_key, qty)
	EventBus.state_changed.emit()


static func _clamp_qty(recipe_key: String, qty: int) -> int:
	return clampi(qty, 1, maxi(1, max_craftable_qty(recipe_key)))


# Loops attempt_craft() `quantity` times, each independently rolled and
# deducted. Stops early if can_craft() would refuse the next attempt, so
# running low on calc mid-batch just yields a short `attempts` list.
static func attempt_craft_batch(recipe_key: String, quantity: int, multi: bool = false) -> Dictionary:
	var attempts: Array[Dictionary] = []
	var successes := 0
	for i in range(quantity):
		var result := attempt_craft(recipe_key, multi)
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
