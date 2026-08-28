class_name Crafting
extends RefCounted

# Recipe crafting per R§3.5. Static funcs only. Crafting is not time-block
# gated (matches the HTML prototype: attemptCraft never calls
# advanceTimeBlock — only seed/cultivate/harvest are).

# bugfixes-57: the Lab's batch-craft quantity picker is a UI convenience,
# not a game balance knob -- capped generously just to keep the state
# tree and the +/- stepper sane, same reasoning as Economy.adjust_sell_qty's
# max_qty clamp.
const MAX_BATCH_QTY := 99


static func craft_chance(recipe_key: String, skill: int) -> float:
	var r: Dictionary = GameData.RECIPES[recipe_key]
	return min(0.95, r["baseSuccess"] + (skill - 1) * 0.13 + Home.get_workshop_bonus())


# dial-device ticket 02: a recipe can have more than one ingredient ore
# type (healingBurst/failsafe both spend time+life) -- these are "the
# action's ore type(s)" Dial.attunement_bonus() matches a seated Movement's
# attunement against; attempt_craft() below checks every one of them, not
# just the first.
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


# calc-discovery ticket 10: a Lab-discovered recipe refined past tier 0
# stacks its refineStep bonus on top of the normal skill-indexed value --
# only for a refineStep that actually targets effectPower (the schema
# tolerates other target fields for effects with no live consumer yet, and
# those aren't effect_power()'s concern). Bench.get_cell() is the single
# source of truth for a cell's tier; nothing here ever mutates GameData.
#
# Shared by effect_power() and quality_tier() below -- returns the active
# Bench refine tier if `recipe_key` has been refined past 0, else -1 (not
# a refine-eligible recipe, or still at tier 0).
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


# ticket 64: the quality tier a craft at this moment would produce -- the
# bucket attempt_craft() files a successful craft's inventory unit under,
# and what Economy scales a consumable's sale price by. Mirrors effect_
# power()'s own branch: a recipe refined past Bench tier 0 reports that
# refine tier (uncapped -- refining keeps climbing past 5), everything
# else reports the crafting skill index effectPower is keyed by (1-5 in
# practice, since player/contact craftingSkill never starts below 1).
static func quality_tier(recipe_key: String, skill: int) -> int:
	var refine_tier := _active_refine_tier(recipe_key)
	return refine_tier if refine_tier > 0 else skill


# ── Inventory (ticket 64: tier-bucketed, not a flat count) ──────────────
# player.inventory[recipe_key] is { "<tier>": count, ... } -- tier keys
# stringified since JSON object keys are always strings. Tier "0" means
# "no known quality": a legacy pre-ticket-64 save's migrated flat count
# (SaveManager._migrate_inventory), or stock that entered inventory some
# way other than a player/contact craft (Guild purchase, event add_item
# grant) -- neither was crafted at a specific skill/refine tier.

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


# Removes `qty` from `recipe_key`'s stock, lowest tier first -- keeps
# higher-quality stock on hand for Economy's price-by-tier sale, since
# every non-sale consumer (combat/travel item use, James craft jobs) is
# indifferent to which specific unit it spends: effect_power() already
# recomputes a used item's magnitude from the *current* skill, not the
# tier it was crafted at. Callers are expected to have already confirmed
# enough stock exists (same precondition every call site had pre-ticket-
# 64) -- this clamps to whatever's on hand rather than erroring.
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


# Sale-specific counterpart to inventory_remove() above: removes `qty`
# from ONE specific tier bucket, since Economy.execute_sale needs to
# charge the price that exact tier's stock earns, not whichever bucket a
# generic lowest-first policy would have picked.
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


static func can_craft(recipe_key: String) -> bool:
	var skill: int = GameState.state["player"]["craftingSkill"]
	var costs: Dictionary = calc_cost(recipe_key, skill)
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	for ingredient in costs:
		if orichalchum.get(ingredient, 0) < costs[ingredient]:
			return false
	return true


static func attempt_craft(recipe_key: String) -> Dictionary:
	if not can_craft(recipe_key):
		return { "ok": false, "reason": "Not enough calc." }

	var player: Dictionary = GameState.state["player"]
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var skill: int = player["craftingSkill"]
	var costs: Dictionary = calc_cost(recipe_key, skill)

	# Deducted regardless of outcome.
	for ingredient in costs:
		player["orichalchum"][ingredient] = maxi(0, player["orichalchum"].get(ingredient, 0) - costs[ingredient])

	# dial-device ticket 02: the player's own craft gets the seated
	# Movement's attunement bonus when its ore type matches any one of this
	# recipe's ingredients (at most one ever can, since a Movement has
	# exactly one attunement); craft_chance() itself stays untouched since
	# Rooms.process_lab() also calls it for contact crafting, which must
	# never see the player's own Dial.
	var attunement := 0.0
	for ingredient_ore in recipe_ore_types(recipe_key):
		attunement = maxf(attunement, Dial.attunement_bonus(ingredient_ore))
	var chance: float = min(0.95, craft_chance(recipe_key, skill) + attunement)
	var success: bool = Rng.chance(chance)
	if success:
		var power = effect_power(recipe_key, skill)
		inventory_add(recipe_key, quality_tier(recipe_key, skill))
		award_crafting_xp(r["xpReward"])
		Modal.open("craft_result", { "success": true, "recipeKey": recipe_key, "power": power })
		return { "ok": true, "success": true, "recipeKey": recipe_key, "power": power }
	else:
		award_crafting_xp(int(floor(float(r["xpReward"]) / 3.0)))
		Modal.open("craft_result", { "success": false, "recipeKey": recipe_key, "power": 0 })
		return { "ok": true, "success": false, "recipeKey": recipe_key, "power": 0 }


# bugfixes-57: state.craftQty is keyed by recipeKey, transient like
# state.sellState (GameState.gd). int() guards against a stored float --
# craftQty is never restored across a save/load round trip (matching
# sellState's own precedent), so a raw JSON int would otherwise come back
# as a float and break range() in attempt_craft_batch below.
static func get_craft_qty(recipe_key: String) -> int:
	return int(GameState.state["craftQty"].get(recipe_key, 1))


static func adjust_craft_qty(recipe_key: String, delta: int) -> void:
	var current: int = get_craft_qty(recipe_key)
	GameState.state["craftQty"][recipe_key] = clampi(current + delta, 1, MAX_BATCH_QTY)
	EventBus.state_changed.emit()


# Ticket 57: loops attempt_craft() `quantity` times -- no change to
# attempt_craft() itself, so each attempt is still independently rolled
# and deducted (not one pooled success chance). Stops early rather than
# erroring the moment can_craft() would refuse the next attempt (attempt_
# craft's own { ok: false } refusal), so running out of calc partway
# through a batch just yields a short `attempts` list. Overwrites the
# last attempt's single-result modal with one batch-shaped modal carrying
# the full per-attempt breakdown.
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
