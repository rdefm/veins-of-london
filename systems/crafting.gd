class_name Crafting
extends RefCounted

# Recipe crafting per R§3.5: inventory, tier buckets, effect power, XP and
# filing crafted items (the Lab and staff craft through here). Static funcs
# only. Crafting is not time-block gated.

# Lab staff's per-attempt success chance (Rooms production).
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


# player.inventory[recipe_key] is { "<tier>": count, ... }, keys stringified
# (JSON). Tiers run 1..5; inventory_add() floors any lower tier at 1.

# Multi-target units live under a parallel inventory key, same tier buckets.
# Only Loadout reads that key; every other consumer sees single-target stock.
const MULTI_SUFFIX := "_multi"


static func inventory_key(recipe_key: String, multi: bool) -> String:
	return recipe_key + MULTI_SUFFIX if multi else recipe_key


# Whether the player may pick multi-target when crafting recipe_key right now:
# craftable list, and the recipe's Lab best rank has reached the minimum.
static func multi_craft_available(recipe_key: String) -> bool:
	var cfg: Dictionary = GameData.LOADOUT["multiTarget"]
	var best := int(GameState.state["lab"]["bestRanks"].get(recipe_key, 0))
	return cfg["craftable"].has(recipe_key) and best >= int(cfg["minTier"])


# The checkbox state, false whenever multi isn't available.
static func get_craft_multi(recipe_key: String) -> bool:
	return bool(GameState.state["craftMulti"].get(recipe_key, false)) and multi_craft_available(recipe_key)


static func set_craft_multi(recipe_key: String, multi: bool) -> void:
	GameState.state["craftMulti"][recipe_key] = multi
	EventBus.state_changed.emit()


# True for items that always hit every target (Black Hole): no checkbox.
static func is_always_multi(recipe_key: String) -> bool:
	return GameData.LOADOUT["multiTarget"]["always"].has(recipe_key)


# Units held at min_tier or above (every tier by default).
static func inventory_qty(recipe_key: String, min_tier: int = 0) -> int:
	var buckets: Dictionary = GameState.state["player"]["inventory"].get(recipe_key, {})
	var total := 0
	for tier_key in buckets:
		if int(tier_key) >= min_tier:
			total += int(buckets[tier_key])
	return total


# The highest tier with stock, 0 when none is held.
static func highest_tier(recipe_key: String) -> int:
	var best := 0
	for tier_key in GameState.state["player"]["inventory"].get(recipe_key, {}):
		if int(GameState.state["player"]["inventory"][recipe_key][tier_key]) > 0:
			best = maxi(best, int(tier_key))
	return best


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
# Tiers below min_tier are never touched (an assay commission's rank floor).
# Returns what came out as [{ tier:int, qty:int }, ...], lowest tier first.
static func inventory_remove(recipe_key: String, qty: int, min_tier: int = 0) -> Array:
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	var buckets: Dictionary = inventory.get(recipe_key, {})
	var remaining := qty
	var tier_keys: Array = buckets.keys()
	tier_keys.sort_custom(func(a, b): return int(a) < int(b))
	var taken: Array = []
	for tier_key in tier_keys:
		if remaining <= 0:
			break
		if int(tier_key) < min_tier:
			continue
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


# The one entry point for filing items the player made (a Lab run or
# batch): qty units at tier into inventory, each item's calc
# (costs_per_item) credited to the player's craft share, craftedCounts, xp
# crafting XP, then the Contracts, Objectives and Collective side effects.
static func file_crafted(recipe_key: String, tier: int, qty: int, multi: bool, costs_per_item: Dictionary, xp: int) -> void:
	if qty <= 0:
		return
	inventory_add(inventory_key(recipe_key, multi), tier, qty)
	var per_share := {}
	for ore_type in costs_per_item:
		per_share[ore_type] = int(costs_per_item[ore_type]) * qty
	Shares.record_craft(Shares.PLAYER, per_share)
	var counts: Dictionary = GameState.state["player"]["craftedCounts"]
	counts[recipe_key] = int(counts.get(recipe_key, 0)) + qty
	award_crafting_xp(xp)
	Contracts.note_player_supplied(recipe_key)
	Objectives.refresh()
	Collective.award_a2_missions()
	Collective.maybe_trigger_a2_nadia_defend_brief()
	EventBus.state_changed.emit()


# No skill-up notification here — matches the HTML prototype, where
# awardCraftingXP (unlike awardCultivatingXP) never calls pushNotification.
static func award_crafting_xp(amount: int, soul_action: bool = false) -> void:
	var player: Dictionary = GameState.state["player"]
	var bucket_mult: float = Mind.craft_xp_mult(false) * Soul.level_xp_mult() if soul_action else Mind.craft_xp_mult()
	amount = int(round(float(amount) * Perks.craft_xp_mult() * bucket_mult))
	Progression.award_xp(player, "craftingXP", "craftingSkill", GameData.CRAFTING_XP_LEVELS, amount)
	Progression.award_bucket_share("mind", amount)
