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
		var cost: int = Crafting.calc_cost(recipe_key, skill)
		var ingredient: String = r["ingredient"]

		while player["inventory"].get(recipe_key, 0) < target:
			var have: int = player["orichalchum"].get(ingredient, 0)
			if have < cost:
				break
			player["orichalchum"][ingredient] = have - cost
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
static func process_vein_station() -> void:
	var contact_id = Contacts.get_contact_in_room("veinStation")
	if contact_id == null:
		return

	var c: Dictionary = GameState.state["contacts"][contact_id]
	var vein_ids: Array = GameState.state["veinStationVeins"]
	var player: Dictionary = GameState.state["player"]

	var total_harvested := 0
	var total_cultivated := 0
	var harvest_breakdown: Dictionary = {}

	for vein_id in vein_ids:
		var vein = Cultivating.find_vein(vein_id)
		if vein == null:
			continue
		var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]

		if vein["charged"]:
			var yield_range: Array = level_data["yieldCautious"]
			var yld: int = Rng.randi_range(yield_range[0], yield_range[1])
			var ore_type: String = vein["oreType"]
			player["orichalchum"][ore_type] = player["orichalchum"].get(ore_type, 0) + yld
			vein["charged"] = false
			vein["chargeBlocks"] = 0
			total_harvested += yld
			harvest_breakdown[ore_type] = harvest_breakdown.get(ore_type, 0) + yld
			Contacts.award_contact_xp(contact_id, "cultivating", 15)
		else:
			var skill: int = c.get("cultivatingSkill", 1)
			var chance: float = min(0.90, 0.30 + (skill - 1) * 0.12)
			if Rng.chance(chance):
				vein["devBar"] = vein["devBar"] + (1 + skill)
				if vein["devBar"] >= level_data["devBarMax"] and vein["level"] < 5:
					Cultivating.level_up_vein(vein)
				Contacts.award_contact_xp(contact_id, "cultivating", 20)
				total_cultivated += 1
			else:
				Contacts.award_contact_xp(contact_id, "cultivating", 8)

	if total_harvested > 0 or total_cultivated > 0:
		var msgs: Array[String] = []
		if total_harvested > 0:
			var parts: Array[String] = []
			for ore_type in harvest_breakdown.keys():
				parts.append("%d %s" % [harvest_breakdown[ore_type], GameData.ORE_TYPES[ore_type]["name"]])
			msgs.append("harvested %s" % ", ".join(parts))
		if total_cultivated > 0:
			var plural: String = "" if total_cultivated == 1 else "s"
			msgs.append("cultivated %d vein%s" % [total_cultivated, plural])
		Notify.push("Vein Station (%s): %s." % [Contacts.display_name(contact_id), "; ".join(msgs)])
