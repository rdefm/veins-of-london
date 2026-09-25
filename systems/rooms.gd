class_name Rooms
extends RefCounted

# Production targets, cultivator vein lists, and the per-block staff step
# per R§3.10. Static funcs only.

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


# Every cultivator (R§3.10 "Staff roles") holds their own uncapped list in
# state.cultivatorVeins { contactId: [veinId] }; a vein sits on at most one
# list. Screens never mutate cultivatorVeins/veinStationTargets directly.
static func cultivator_veins(contact_id: String) -> Array:
	return GameState.state["cultivatorVeins"].get(contact_id, [])


# The contact whose list holds the vein, or null.
static func cultivator_of(vein_id: String) -> Variant:
	var lists: Dictionary = GameState.state["cultivatorVeins"]
	for contact_id in lists.keys():
		if lists[contact_id].has(vein_id):
			return contact_id
	return null


# Adds the vein to the cultivator's list, moving it off any other list. A
# moved vein keeps its target; a fresh assignment gets the default.
static func assign_vein(contact_id: String, vein_id: String) -> Dictionary:
	if Contacts.role_of(contact_id) != "cultivation":
		return { "ok": false, "reason": "Not a cultivator." }
	if Cultivating.find_vein(vein_id) == null:
		return { "ok": false, "reason": "No such vein." }
	var previous: Variant = cultivator_of(vein_id)
	if previous == contact_id:
		return { "ok": true }
	var lists: Dictionary = GameState.state["cultivatorVeins"]
	if previous != null:
		lists[previous].erase(vein_id)
	if not lists.has(contact_id):
		lists[contact_id] = []
	lists[contact_id].append(vein_id)
	var targets: Dictionary = GameState.state["veinStationTargets"]
	if not targets.has(vein_id):
		targets[vein_id] = VEIN_STATION_DEFAULT_TARGET
	EventBus.state_changed.emit()
	return { "ok": true }


static func unassign_vein(vein_id: String) -> void:
	var previous: Variant = cultivator_of(vein_id)
	if previous == null:
		return
	GameState.state["cultivatorVeins"][previous].erase(vein_id)
	GameState.state["veinStationTargets"].erase(vein_id)
	EventBus.state_changed.emit()


# Clamped to the vein's own ceiling (100, or 120 with the wildCeiling bonus)
# since a target above it could never be reached.
static func set_vein_station_target(vein_id: String, target: int) -> void:
	var vein = Cultivating.find_vein(vein_id)
	if vein == null:
		return
	GameState.state["veinStationTargets"][vein_id] = clampi(target, 0, Cultivating.ceiling(vein))
	EventBus.state_changed.emit()


static func vein_station_target(vein_id: String) -> int:
	return GameState.state["veinStationTargets"].get(vein_id, VEIN_STATION_DEFAULT_TARGET)


# The read-only "Cultivated by X · target N" summary shared by Procurement
# and the vein list -- null when no cultivator holds the vein.
static func vein_station_target_text(vein_id: String) -> Variant:
	var contact_id: Variant = cultivator_of(vein_id)
	if contact_id == null:
		return null
	return "Cultivated by %s · target %d" % [Contacts.display_name(contact_id), vein_station_target(vein_id)]


# The staff block step (R§3.10 "Staff block step"), run by TimeSystem at
# the end of every player time block: each working cultivator takes one
# action, then each working producer makes one craft attempt, then Sales
# re-checks delegated contracts if shared stock grew. Returns the block's
# output { "ore": {oreType: qty}, "items": {recipeKey: qty} } for the
# Morning Brief.
static func process_staff_block() -> Dictionary:
	var output := { "ore": {}, "items": {} }
	for contact_id in Contacts.contacts_in_role("cultivation"):
		if Payroll.is_working(contact_id):
			_cultivator_act(contact_id, output["ore"])
	for contact_id in Contacts.contacts_in_role("production"):
		if Payroll.is_working(contact_id):
			_producer_act(contact_id, output["items"])
	if not output["ore"].is_empty() or not output["items"].is_empty():
		EventBus.shared_stock_increased.emit()
	return output


# The assigned vein furthest outside its target ±VEIN_STATION_HOLD_BAND,
# ties to the earliest in assignment order; null when every vein is in band.
static func pick_vein(contact_id: String) -> Variant:
	var best: Variant = null
	var best_distance := 0
	for vein_id in cultivator_veins(contact_id):
		var vein = Cultivating.find_vein(vein_id)
		if vein == null:
			continue
		var target := vein_station_target(vein_id)
		var growth: int = vein["growth"]
		var distance: int = maxi(growth - (target + VEIN_STATION_HOLD_BAND), (target - VEIN_STATION_HOLD_BAND) - growth)
		if distance > best_distance:
			best = vein_id
			best_distance = distance
	return best


# Above the band: prune down to target, yield into shared stock. Below: one
# cultivate roll at the contact's skill. Drives Cultivating's prune-yield/
# cultivate-gain math directly rather than through Cultivating.prune()/
# cultivate(), which spend a time block and require Travel.ensure_district.
static func _cultivator_act(contact_id: String, ore_out: Dictionary) -> void:
	var vein_id: Variant = pick_vein(contact_id)
	if vein_id == null:
		return
	var vein: Dictionary = Cultivating.find_vein(vein_id)
	var target := vein_station_target(vein_id)
	var growth: int = vein["growth"]
	if growth > target:
		var depth: int = growth - target
		var amount: int = Cultivating.prune_yield(vein, depth)
		vein["growth"] = maxi(0, growth - depth)
		vein["rampantDays"] = 0
		Cultivating.apply_growth_change(vein, growth)
		var ore_type: String = vein["oreType"]
		var ore: Dictionary = GameState.state["player"]["orichalchum"]
		ore[ore_type] = ore.get(ore_type, 0) + amount
		if amount > 0:
			ore_out[ore_type] = ore_out.get(ore_type, 0) + amount
	else:
		var skill: int = GameState.state["contacts"][contact_id].get("cultivatingSkill", 1)
		if Rng.chance(Cultivating.get_cult_chance(skill)):
			var vein_ceiling: int = Cultivating.ceiling(vein)
			var gain: int = Cultivating.cultivate_gain(skill, growth, vein_ceiling)
			vein["growth"] = clampi(growth + gain, 0, vein_ceiling)
			if vein["growth"] < vein_ceiling:
				vein["rampantDays"] = 0
			Cultivating.apply_growth_change(vein, growth)
	Contacts.award_contact_xp(contact_id, "cultivating", GameData.CULTIVATOR_ACTION_XP)


# One craft attempt at the first recipe in _production_order() that is
# unlocked, below its effective target, and affordable from shared stock.
static func _producer_act(contact_id: String, items_out: Dictionary) -> void:
	var flags: Dictionary = GameState.state["flags"]
	var ore: Dictionary = GameState.state["player"]["orichalchum"]
	var skill: int = GameState.state["contacts"][contact_id].get("craftingSkill", 1)
	for recipe_key in _production_order():
		var unlock_flag: String = RECIPE_UNLOCK_FLAGS.get(recipe_key, "")
		if unlock_flag != "" and not flags.get(unlock_flag, false):
			continue
		if Crafting.inventory_qty(recipe_key) >= effective_lab_target(recipe_key):
			continue
		var costs: Dictionary = Crafting.calc_cost(recipe_key, skill)
		var can_afford := true
		for ingredient in costs:
			if ore.get(ingredient, 0) < costs[ingredient]:
				can_afford = false
				break
		if not can_afford:
			continue
		for ingredient in costs:
			ore[ingredient] = ore.get(ingredient, 0) - costs[ingredient]
		var xp_reward: int = GameData.RECIPES[recipe_key]["xpReward"]
		if Rng.chance(Crafting.craft_chance(recipe_key, skill)):
			Crafting.inventory_add(recipe_key, Crafting.quality_tier(recipe_key, skill))
			items_out[recipe_key] = items_out.get(recipe_key, 0) + 1
			Contacts.award_contact_xp(contact_id, "crafting", xp_reward)
		else:
			Contacts.award_contact_xp(contact_id, "crafting", int(floor(float(xp_reward) / 3.0)))
		return
