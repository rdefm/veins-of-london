class_name Rooms
extends RefCounted

# Daily processing for the lab and veinStation rooms per R§3.10. Static
# funcs only.

# R§1.3 has no unlockFlag column for recipes, but R§3.10
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


# vein-growth-state spec §6.1: default target on assignment is 70.
const VEIN_STATION_DEFAULT_TARGET := 70

# spec §6.1: the +/-5 dead zone around a vein's target inside which the
# assigned contact leaves it alone.
const VEIN_STATION_HOLD_BAND := 5


static func toggle_vein_station_vein(vein_id: String) -> void:
	var list: Array = GameState.state["veinStationVeins"]
	var targets: Dictionary = GameState.state["veinStationTargets"]
	var idx: int = list.find(vein_id)
	if idx >= 0:
		list.remove_at(idx)
		targets.erase(vein_id)
	else:
		list.append(vein_id)
		targets[vein_id] = VEIN_STATION_DEFAULT_TARGET
	EventBus.state_changed.emit()


# Read-modify via a system function per spec §6.1/ticket 06 -- screens never
# mutate state.veinStationTargets directly. Clamped to the vein's own
# ceiling (100, or 120 with the wildCeiling bonus) since a target above it
# could never be reached.
static func set_vein_station_target(vein_id: String, target: int) -> void:
	var vein = Cultivating.find_vein(vein_id)
	if vein == null:
		return
	GameState.state["veinStationTargets"][vein_id] = clampi(target, 0, Cultivating.ceiling(vein))
	EventBus.state_changed.emit()


# vein-growth-state ticket 09: the read-only "Vein Station target: N" summary
# shared by the map sheet's own assignment row (scenes/screens/map.gd) and
# the vein list (scenes/screens/vein_list.gd) -- null when the vein isn't
# assigned at all, so both callers can decide what (if anything) to render
# without duplicating the veinStationVeins/veinStationTargets lookup.
static func vein_station_target_text(vein_id: String) -> Variant:
	if not GameState.state["veinStationVeins"].has(vein_id):
		return null
	var target: int = GameState.state["veinStationTargets"].get(vein_id, VEIN_STATION_DEFAULT_TARGET)
	return "Vein Station target: %d" % target


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

		while Crafting.inventory_qty(recipe_key) < target:
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
				Crafting.inventory_add(recipe_key, Crafting.quality_tier(recipe_key, skill))
				Contacts.award_contact_xp(contact_id, "crafting", r["xpReward"])
				total_successes += 1
			else:
				Contacts.award_contact_xp(contact_id, "crafting", int(floor(float(r["xpReward"]) / 3.0)))
			total_attempts += 1

	if total_attempts > 0:
		var plural: String = "" if total_attempts == 1 else "s"
		Notify.push("Lab (%s): %d crafted from %d attempt%s." % [Contacts.display_name(contact_id), total_successes, total_attempts, plural], Notify.CATEGORY_SUCCESS)


# Called from time_system.gd's daily_tick, step ⑥ (veinStation half).
#
# vein-growth-state spec §6.1, "hold-at-target": per assigned vein, a
# contact prunes down toward the target if growth has drifted more than
# VEIN_STATION_HOLD_BAND above it, or rolls one cultivate attempt at their
# own cultivatingSkill if it's drifted the same amount below it. Otherwise
# left alone. Mirrors process_lab()'s shape (assigned-contact lookup, ore
# straight into player.orichalchum, one summary notification) but drives
# Cultivating's prune-yield/cultivate-gain math directly rather than
# routing through Cultivating.prune()/cultivate() -- those spend a time
# block and require Travel.ensure_district, neither of which applies to a
# contact working from home on a daily tick.
static func process_vein_station() -> void:
	var contact_id = Contacts.get_contact_in_room("veinStation")
	if contact_id == null:
		return

	var c: Dictionary = GameState.state["contacts"][contact_id]
	var targets: Dictionary = GameState.state["veinStationTargets"]
	var player: Dictionary = GameState.state["player"]

	# Same notification shape the pre-growth-model version of this function
	# used (ore-type breakdown for the yield clause, a plain count for the
	# cultivate clause, failures tracked for XP only and never surfaced in
	# the message) -- ticket 06 asks for "as today", just with prune/
	# cultivate language replacing harvest/cultivate.
	var prune_breakdown: Dictionary = {}
	var total_cultivated := 0

	for vein_id in GameState.state["veinStationVeins"]:
		var vein = Cultivating.find_vein(vein_id)
		if vein == null:
			continue

		var target: int = targets.get(vein_id, VEIN_STATION_DEFAULT_TARGET)
		var growth: int = vein["growth"]

		if growth > target + VEIN_STATION_HOLD_BAND:
			var depth: int = growth - target
			var amount: int = Cultivating.prune_yield(vein, depth)
			vein["growth"] = maxi(0, growth - depth)
			vein["rampantDays"] = 0
			var ore_type: String = vein["oreType"]
			player["orichalchum"][ore_type] = player["orichalchum"].get(ore_type, 0) + amount
			prune_breakdown[ore_type] = prune_breakdown.get(ore_type, 0) + amount
			Contacts.award_contact_xp(contact_id, "cultivating", 15)
		elif growth < target - VEIN_STATION_HOLD_BAND:
			var skill: int = c.get("cultivatingSkill", 1)
			var success: bool = Rng.chance(Cultivating.get_cult_chance(skill))
			if success:
				var vein_ceiling: int = Cultivating.ceiling(vein)
				var gain: int = Cultivating.cultivate_gain(skill, growth, vein_ceiling)
				vein["growth"] = clampi(growth + gain, 0, vein_ceiling)
				if vein["growth"] < vein_ceiling:
					vein["rampantDays"] = 0
				Contacts.award_contact_xp(contact_id, "cultivating", 20)
				total_cultivated += 1
			else:
				Contacts.award_contact_xp(contact_id, "cultivating", 8)

	var msgs: Array = []
	if not prune_breakdown.is_empty():
		var parts: Array = []
		for ore_type in prune_breakdown:
			parts.append("%d %s" % [prune_breakdown[ore_type], GameData.ORE_TYPES[ore_type]["name"]])
		msgs.append("pruned %s" % ", ".join(parts))
	if total_cultivated > 0:
		var plural: String = "" if total_cultivated == 1 else "s"
		msgs.append("cultivated %d vein%s" % [total_cultivated, plural])
	if not msgs.is_empty():
		Notify.push("Vein Station (%s): %s." % [Contacts.display_name(contact_id), "; ".join(msgs)], Notify.CATEGORY_SUCCESS)
