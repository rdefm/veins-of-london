class_name Rooms
extends RefCounted

# Daily processing for the lab and veinStation rooms per R§3.10. Static
# funcs only.

# R§1.3 has no unlockFlag column for recipes (unlike devices), but R§3.10
# says the lab crafts each "unlocked recipe" — this mirrors the HTML's
# per-recipe checks with the R§7 rename applied (motionPowder ->
# enhancementPowder, motionPowderUnlocked -> enhancementUnlocked).
const RECIPE_UNLOCK_FLAGS := {
	"timePearl": "craftingUnlocked",
	"enhancementPowder": "enhancementUnlocked",
	"rewind": "craftingUnlocked",
}


static func adjust_lab_threshold(recipe_key: String, delta: int) -> void:
	var thresholds: Dictionary = GameState.state["labThresholds"]
	thresholds[recipe_key] = maxi(0, thresholds.get(recipe_key, 0) + delta)
	EventBus.state_changed.emit()


static func toggle_vein_station_vein(vein_id: String) -> void:
	var list: Array = GameState.state["veinStationVeins"]
	var idx: int = list.find(vein_id)
	if idx >= 0:
		list.remove_at(idx)
	else:
		list.append(vein_id)
	EventBus.state_changed.emit()


# Called from time_system.gd's daily_tick, step ⑥ (lab half).
static func process_lab() -> void:
	var contact_id = Contacts.get_contact_in_room("lab")
	if contact_id == null:
		return

	var c: Dictionary = GameState.state["contacts"][contact_id]
	var thresholds: Dictionary = GameState.state["labThresholds"]
	var player: Dictionary = GameState.state["player"]
	var flags: Dictionary = GameState.state["flags"]

	var total_attempts := 0
	var total_successes := 0

	for recipe_key in GameData.RECIPES.keys():
		var unlock_flag: String = RECIPE_UNLOCK_FLAGS.get(recipe_key, "")
		if unlock_flag != "" and not flags.get(unlock_flag, false):
			continue
		var target: int = thresholds.get(recipe_key, 0)
		if target <= 0:
			continue

		var r: Dictionary = GameData.RECIPES[recipe_key]
		var skill: int = c.get("craftingSkill", 1)
		var costs: Dictionary = Crafting.calc_cost(recipe_key, skill)

		while player["inventory"].get(recipe_key, 0) < target:
			var can_afford := true
			for ingredient in costs:
				if player["orichalchum"].get(ingredient, 0) < costs[ingredient]:
					can_afford = false
					break
			if not can_afford:
				break
			for ingredient in costs:
				player["orichalchum"][ingredient] = player["orichalchum"].get(ingredient, 0) - costs[ingredient]
			var success: bool = Rng.chance(Crafting.craft_chance(recipe_key, skill))
			if success:
				player["inventory"][recipe_key] = player["inventory"].get(recipe_key, 0) + 1
				Contacts.award_contact_xp(contact_id, "crafting", r["xpReward"])
				total_successes += 1
			else:
				Contacts.award_contact_xp(contact_id, "crafting", int(floor(float(r["xpReward"]) / 3.0)))
			total_attempts += 1

	if total_attempts > 0:
		var plural: String = "" if total_attempts == 1 else "s"
		Notify.push("Lab (%s): %d crafted from %d attempt%s." % [Contacts.display_name(contact_id), total_successes, total_attempts, plural])


# Called from time_system.gd's daily_tick, step ⑥ (veinStation half).
#
# vein-growth-state ticket 06 rebuilds this room's assigned-contact
# behaviour around a per-vein growth target ("hold-at-target": prune down
# toward the target above it, cultivate up toward it below it). The old
# "harvest if charged, else cultivate" behaviour above no longer has
# meaning under the growth model (no charged/devBar left on a vein), so
# it's removed rather than patched — assigned veins are inert until ticket
# 06 lands state.veinStationTargets and the real hold-at-target pass.
static func process_vein_station() -> void:
	pass
