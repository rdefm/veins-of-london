class_name Crafting
extends RefCounted

# Recipe crafting per R§3.5. Static funcs only. Crafting is not time-block
# gated (matches the HTML prototype: attemptCraft never calls
# advanceTimeBlock — only seed/cultivate/harvest are).


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


static func effect_power(recipe_key: String, skill: int) -> Variant:
	var r: Dictionary = GameData.RECIPES[recipe_key]
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


# No skill-up notification here — matches the HTML prototype, where
# awardCraftingXP (unlike awardCultivatingXP) never calls pushNotification.
static func award_crafting_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	Progression.award_xp(player, "craftingXP", "craftingSkill", GameData.CRAFTING_XP_LEVELS, amount)
