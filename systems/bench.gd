class_name Bench
extends RefCounted

# The Lab's discovery engine (M3-CALC-DISCOVERY.md). Static funcs only,
# mirrors systems/crafting.gd's shape. Cells are (type set) x (approach)
# pairs; a cell is written lazily into player.bench.cells the first time it
# is probed -- an absent key means "untried" (see GameState.new_game_state).
#
# Formulas below are the PROVISIONAL constants from M3-CALC-DISCOVERY.md
# §7, implemented as specified per calc-discovery ticket 04. Promote to
# REFERENCE.md, not here, when the doc is specced.

const DISCOVERY_BASE_CHANCE := 0.35
const DISCOVERY_SKILL_BONUS := 0.12
const DISCOVERY_CHANCE_CAP := 0.90
const PITY_PER_MISS := 0.12

const ORE_COST_PER_TYPE := 3

const XP_FOUND := 40
const XP_HOT := 12
const XP_INERT := 6

const NOTES_CAP := 20


# Canonical type-set key: alphabetically sorted, "+"-joined. Every
# cell/census/notes lookup goes through this helper so the key can never
# drift ("time+life" vs "life+time").
static func type_set_key(types: Array) -> String:
	var sorted_types := types.duplicate()
	sorted_types.sort()
	return "+".join(sorted_types)


static func cell_key(types: Array, approach: String) -> String:
	return "%s|%s" % [type_set_key(types), approach]


static func _default_cell() -> Dictionary:
	return { "state": "untried", "misses": 0, "refine": 0 }


static func get_cell(types: Array, approach: String) -> Dictionary:
	var cells: Dictionary = GameState.state["player"]["bench"]["cells"]
	return cells.get(cell_key(types, approach), _default_cell())


static func cell_state(types: Array, approach: String) -> String:
	return get_cell(types, approach)["state"]


static func _set_cell(types: Array, approach: String, updates: Dictionary) -> void:
	var cells: Dictionary = GameState.state["player"]["bench"]["cells"]
	var key := cell_key(types, approach)
	var cell: Dictionary = cells.get(key, _default_cell()).duplicate()
	for field in updates:
		cell[field] = updates[field]
	cells[key] = cell


# Recipe keys whose discovery.types normalizes to this type set, across ALL
# approaches -- including ones behind approaches not yet learned, since the
# census counts everything (M3 §3.3, §12.1).
static func _recipes_in_set(types: Array) -> Array[String]:
	var key := type_set_key(types)
	var matches: Array[String] = []
	for recipe_key in GameData.RECIPES:
		var discovery: Dictionary = GameData.RECIPES[recipe_key].get("discovery", {})
		if discovery.is_empty():
			continue
		if type_set_key(discovery["types"]) == key:
			matches.append(recipe_key)
	return matches


# The recipe key occupying this exact cell, or "" if the cell is empty.
# A cell holds at most one effect (M3 §2.1), so the first match is the
# only match.
static func find_recipe_for_cell(types: Array, approach: String) -> String:
	for recipe_key in _recipes_in_set(types):
		if GameData.RECIPES[recipe_key]["discovery"]["approach"] == approach:
			return recipe_key
	return ""


static func census_count(types: Array) -> int:
	return _recipes_in_set(types).size()


static func is_surveyed(types: Array) -> bool:
	var bench: Dictionary = GameState.state["player"]["bench"]
	return bench["surveyed"].has(type_set_key(types))


static func get_surveyed_count(types: Array) -> int:
	var bench: Dictionary = GameState.state["player"]["bench"]
	return bench["surveyed"].get(type_set_key(types), 0)


static func _survey(types: Array) -> void:
	var bench: Dictionary = GameState.state["player"]["bench"]
	var key := type_set_key(types)
	if not bench["surveyed"].has(key):
		bench["surveyed"][key] = census_count(types)


static func discovery_cost(types: Array) -> Dictionary:
	var costs := {}
	for ore_type in types:
		costs[ore_type] = ORE_COST_PER_TYPE
	return costs


# Odds on an occupied cell, pity already baked in (M3 §8.4). Reuses
# Home.get_workshop_bonus() unchanged -- no new bonus channel.
static func discovery_chance(types: Array, approach: String, skill: int) -> float:
	var pity: float = get_cell(types, approach)["misses"] * PITY_PER_MISS
	return minf(DISCOVERY_CHANCE_CAP, DISCOVERY_BASE_CHANCE + (skill - 1) * DISCOVERY_SKILL_BONUS + Home.get_workshop_bonus() + pity)


static func _probe_block_reason(types: Array, approach: String) -> String:
	if not Approaches.is_known(approach):
		return "You haven't the technique for that yet."
	var state: String = cell_state(types, approach)
	if state == "inert":
		return "Nothing here. Already confirmed."
	if state == "found":
		return "Already discovered. Refine it instead."
	var costs := discovery_cost(types)
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	for ore_type in costs:
		if orichalchum.get(ore_type, 0) < costs[ore_type]:
			return "Not enough calc."
	return ""


static func can_probe(types: Array, approach: String) -> bool:
	return _probe_block_reason(types, approach) == ""


static func _append_note(types: Array, approach: String, outcome: String) -> void:
	var bench: Dictionary = GameState.state["player"]["bench"]
	var key := type_set_key(types)
	var notes: Array = bench["notes"].get(key, [])
	notes.append({ "day": GameState.state["world"]["day"], "approach": approach, "outcome": outcome })
	if notes.size() > NOTES_CAP:
		notes.pop_front()
	bench["notes"][key] = notes


# Runs an experiment against a pairing+approach cell. Resolves the cell's
# permanent truth (empty -> inert, forever) or rolls an occupied cell
# (hit -> found; miss -> hot, pity accrues). Ore and a time block are spent
# and XP is awarded on every attempt that isn't blocked, regardless of
# outcome (M3 §7's "ore deduction: always" plus the discovery-XP rows).
static func probe(types: Array, approach: String) -> Dictionary:
	var reason := _probe_block_reason(types, approach)
	if reason != "":
		return { "ok": false, "reason": reason }

	TimeSystem.advance_time_block()

	var player: Dictionary = GameState.state["player"]
	var costs := discovery_cost(types)
	for ore_type in costs:
		player["orichalchum"][ore_type] = maxi(0, player["orichalchum"].get(ore_type, 0) - costs[ore_type])

	if not is_surveyed(types):
		_survey(types)

	var recipe_key := find_recipe_for_cell(types, approach)
	var outcome: String

	if recipe_key == "":
		outcome = "inert"
		_set_cell(types, approach, { "state": "inert" })
		Crafting.award_crafting_xp(XP_INERT)
	else:
		var skill: int = player["craftingSkill"]
		var chance := discovery_chance(types, approach, skill)
		if Rng.chance(chance):
			outcome = "found"
			_set_cell(types, approach, { "state": "found" })
			Crafting.award_crafting_xp(XP_FOUND)
		else:
			outcome = "hot"
			var misses: int = get_cell(types, approach)["misses"]
			_set_cell(types, approach, { "state": "hot", "misses": misses + 1 })
			Crafting.award_crafting_xp(XP_HOT)

	_append_note(types, approach, outcome)
	EventBus.state_changed.emit()

	return { "ok": true, "outcome": outcome, "recipeKey": recipe_key }
