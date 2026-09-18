class_name Rooms
extends RefCounted

# Daily processing for the lab and veinStation rooms per R§3.10. Static
# funcs only.

# R§1.3 has no unlockFlag column for recipes, but R§3.10 says the lab crafts
# each "unlocked recipe" -- mirrors the HTML's per-recipe checks with the
# R§7 ids applied (enhancementPowder/enhancementUnlocked).
const RECIPE_UNLOCK_FLAGS := {
	"timePearl": "craftingUnlocked",
	"enhancementPowder": "enhancementUnlocked",
	"rewind": "craftingUnlocked",
}


static func adjust_lab_threshold(recipe_key: String, delta: int) -> void:
	var thresholds: Dictionary = GameState.state["labThresholds"]
	thresholds[recipe_key] = maxi(0, thresholds.get(recipe_key, 0) + delta)
	EventBus.state_changed.emit()


# Per-item opt-in for Production to also craft toward accepted-contract
# need on top of the personal labThresholds target.
static func set_lab_cover_contracts(recipe_key: String, enabled: bool) -> void:
	GameState.state["labCoverContracts"][recipe_key] = enabled
	EventBus.state_changed.emit()


static func lab_covers_contracts(recipe_key: String) -> bool:
	return GameState.state["labCoverContracts"].get(recipe_key, false)


# business-spec.md "Production and Procurement": contract need counts only
# undelivered qty of active current periods -- a recurring contract's next
# period doesn't exist until settle() creates it, so summing remaining_qty
# already excludes any future period.
static func contract_need(recipe_key: String) -> int:
	var need := 0
	for contract in _matching_active_contracts(recipe_key):
		# A mixed contract may request this recipe alongside other
		# (unrelated-pool) types -- count only this recipe's own line, never
		# the contract's total remaining across every requested type.
		need += Contracts.remaining_qty(contract, recipe_key)
	return need


static func _matching_active_contracts(recipe_key: String) -> Array:
	var matches: Array = []
	for contract in Contracts.active_contracts():
		for line in Contracts.request_lines(contract["request"]):
			if line.get("kind", "") == "consumable" and line["type"] == recipe_key:
				matches.append(contract)
				break
	return matches


# Additive combination: personal target plus contract need, with the
# personal-target portion reserved. Toggled off, this is just the
# personal target.
static func effective_lab_target(recipe_key: String) -> int:
	var target: int = GameState.state["labThresholds"].get(recipe_key, 0)
	if lab_covers_contracts(recipe_key):
		target += contract_need(recipe_key)
	return target


# The personal-target portion of stock is a protected buffer Sales may never
# draw from -- see Contracts._shared_stock(). Only reserved while the item
# is toggled to cover contracts; otherwise Sales draws freely.
static func production_reserved_qty(recipe_key: String) -> int:
	if not lab_covers_contracts(recipe_key):
		return 0
	return int(GameState.state["labThresholds"].get(recipe_key, 0))


# "The contract-card priority order wins, then player-set inventory-target
# priority" for scarce shared ore. Recipes with covered, unmet contract need
# are ordered by the best rank of any matching active contract in
# sales.priorityOrder; everything else follows labThresholds' own
# key-insertion order (the player's de facto priority).
static func _production_order() -> Array:
	var threshold_keys: Array = GameState.state["labThresholds"].keys()
	var recipe_keys: Array = GameData.RECIPES.keys()
	var ranked: Array = []
	for i in recipe_keys.size():
		var recipe_key: String = recipe_keys[i]
		var threshold_rank: int = threshold_keys.find(recipe_key)
		if threshold_rank < 0:
			threshold_rank = threshold_keys.size()
		ranked.append({
			"key": recipe_key,
			"contractRank": _contract_priority_rank(recipe_key),
			"thresholdRank": threshold_rank,
			"originalIndex": i,
		})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["contractRank"] != b["contractRank"]:
			return a["contractRank"] < b["contractRank"]
		if a["thresholdRank"] != b["thresholdRank"]:
			return a["thresholdRank"] < b["thresholdRank"]
		return a["originalIndex"] < b["originalIndex"]
	)
	var order: Array = []
	for entry in ranked:
		order.append(entry["key"])
	return order


static func _contract_priority_rank(recipe_key: String) -> int:
	var priority_order: Array = GameState.state["sales"]["priorityOrder"]
	var unranked: int = priority_order.size() + 1
	if not lab_covers_contracts(recipe_key):
		return unranked
	var best := unranked
	for contract in _matching_active_contracts(recipe_key):
		if Contracts.remaining_qty(contract, recipe_key) <= 0:
			continue
		var idx: int = priority_order.find(contract["id"])
		if idx < 0:
			idx = priority_order.size()
		best = mini(best, idx)
	return best


# Default target on assignment.
const VEIN_STATION_DEFAULT_TARGET := 70

# The +/-5 dead zone around a vein's target inside which the assigned
# contact leaves it alone.
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


# Screens never mutate state.veinStationTargets directly. Clamped to the
# vein's own ceiling (100, or 120 with the wildCeiling bonus) since a
# target above it could never be reached.
static func set_vein_station_target(vein_id: String, target: int) -> void:
	var vein = Cultivating.find_vein(vein_id)
	if vein == null:
		return
	GameState.state["veinStationTargets"][vein_id] = clampi(target, 0, Cultivating.ceiling(vein))
	EventBus.state_changed.emit()


# The read-only "Vein Station target: N" summary shared by the map sheet's
# assignment row and the vein list -- null when the vein isn't assigned at
# all, so both callers can decide what to render without duplicating the
# veinStationVeins/veinStationTargets lookup.
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
	if not Payroll.is_paid_today("lab"):
		return

	var c: Dictionary = GameState.state["contacts"][contact_id]
	var player: Dictionary = GameState.state["player"]
	var flags: Dictionary = GameState.state["flags"]

	var total_attempts := 0
	var total_successes := 0

	for recipe_key in _production_order():
		var unlock_flag: String = RECIPE_UNLOCK_FLAGS.get(recipe_key, "")
		if unlock_flag != "" and not flags.get(unlock_flag, false):
			continue
		var target: int = effective_lab_target(recipe_key)
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
# "Hold-at-target": per assigned vein, a contact prunes toward target if
# growth drifted more than VEIN_STATION_HOLD_BAND above it, or rolls one
# cultivate attempt if drifted the same amount below. Drives Cultivating's
# prune-yield/cultivate-gain math directly rather than through
# Cultivating.prune()/cultivate(), which spend a time block and require
# Travel.ensure_district -- not applicable to a contact working from home.
static func process_vein_station() -> void:
	var contact_id = Contacts.get_contact_in_room("veinStation")
	if contact_id == null:
		return
	if not Payroll.is_paid_today("veinStation"):
		return

	var c: Dictionary = GameState.state["contacts"][contact_id]
	var targets: Dictionary = GameState.state["veinStationTargets"]
	var player: Dictionary = GameState.state["player"]

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
			if amount > 0:
				EventBus.shared_stock_increased.emit()
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
