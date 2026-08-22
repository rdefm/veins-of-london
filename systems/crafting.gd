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
static func effect_power(recipe_key: String, skill: int) -> Variant:
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var discovery: Dictionary = r.get("discovery", {})
	var refine_step: Dictionary = r.get("refineStep", {})
	if not discovery.is_empty() and refine_step.get("field") == "effectPower":
		var tier: int = Bench.get_cell(discovery["types"], discovery["approach"])["refine"]
		if tier > 0:
			return Bench.refined_value(recipe_key, discovery["types"], discovery["approach"], skill)
	var powers: Array = r["effectPower"]
	return powers[skill]


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

	var success: bool = Rng.chance(craft_chance(recipe_key, skill))
	if success:
		var power = effect_power(recipe_key, skill)
		player["inventory"][recipe_key] = player["inventory"].get(recipe_key, 0) + 1
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
