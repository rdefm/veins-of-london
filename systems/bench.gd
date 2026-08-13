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
const XP_REFINE := 30

const NOTES_CAP := 20

const REFINE_ORE_PER_TYPE := 3
const REFINE_BASE_CHANCE := 0.55
const REFINE_SKILL_BONUS := 0.10
const REFINE_TIER_PENALTY := 0.15
const REFINE_CHANCE_FLOOR := 0.08


# Canonical type-set key: alphabetically sorted, "+"-joined. Every
# cell/census/notes lookup goes through this helper so the key can never
# drift ("time+life" vs "life+time").
static func type_set_key(types: Array) -> String:
	var sorted_types := types.duplicate()
	sorted_types.sort()
	return "+".join(sorted_types)


static func cell_key(types: Array, approach: String) -> String:
	return "%s|%s" % [type_set_key(types), approach]


# A cell with no persisted entry defaults to "untried" -- except a cell
# occupied by a taughtBy recipe (calc-discovery ticket 10, M3 §9.2: the
# tutorial always teaches timePearl/enhancementPowder/rewind before the
# bench is reachable), which defaults straight to "found" instead. This
# needs no cells-dict write to be true, so it survives GameState.reset()
# and a fresh save with zero extra state.
static func _default_cell(types: Array, approach: String) -> Dictionary:
	var state := "untried"
	var recipe_key := find_recipe_for_cell(types, approach)
	if recipe_key != "" and not GameData.RECIPES[recipe_key].get("taughtBy", "").is_empty():
		state = "found"
	return { "state": state, "misses": 0, "refine": 0 }


static func get_cell(types: Array, approach: String) -> Dictionary:
	var cells: Dictionary = GameState.state["player"]["bench"]["cells"]
	return cells.get(cell_key(types, approach), _default_cell(types, approach))


static func cell_state(types: Array, approach: String) -> String:
	return get_cell(types, approach)["state"]


static func _set_cell(types: Array, approach: String, updates: Dictionary) -> void:
	var cells: Dictionary = GameState.state["player"]["bench"]["cells"]
	var key := cell_key(types, approach)
	var cell: Dictionary = cells.get(key, _default_cell(types, approach)).duplicate()
	for field in updates:
		cell[field] = updates[field]
	cells[key] = cell


# Recipe keys whose discovery.types normalizes to this type set, across ALL
# approaches -- including ones behind approaches not yet learned, since the
# census counts everything (M3 §3.3, §12.1).
static func _recipes_in_set(types: Array) -> Array[String]:
	var key := type_set_key(types)
	var matches: Array[String] = []
	for recipe_key in _lab_reachable_recipe_keys():
		if type_set_key(GameData.RECIPES[recipe_key]["discovery"]["types"]) == key:
			matches.append(recipe_key)
	return matches


# Recipe keys with a non-empty `discovery` field -- shared by every Bench
# query that scans the whole catalogue for Lab-reachable recipes.
static func _lab_reachable_recipe_keys() -> Array[String]:
	var keys: Array[String] = []
	for recipe_key in GameData.RECIPES:
		if not GameData.RECIPES[recipe_key].get("discovery", {}).is_empty():
			keys.append(recipe_key)
	return keys


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


# Shared by found_recipe_keys() and found_count_in_set() below -- filters
# any recipe-key list down to the ones whose cell is currently "found".
static func _found_among(recipe_keys: Array[String]) -> Array[String]:
	var found: Array[String] = []
	for recipe_key in recipe_keys:
		var discovery: Dictionary = GameData.RECIPES[recipe_key]["discovery"]
		if cell_state(discovery["types"], discovery["approach"]) == "found":
			found.append(recipe_key)
	return found


# Recipe keys whose cell is currently "found" -- the Lab home screen's
# trophy-shelf list (M3 UI structure, calc-discovery ticket 06). Order
# follows GameData.RECIPES's own key order.
static func found_recipe_keys() -> Array[String]:
	return _found_among(_lab_reachable_recipe_keys())


# How many of a specific type set's effects are currently "found" -- the
# pairing panel's census sentence (calc-discovery ticket 07) needs this
# alongside census_count() to say "N of M", not just the total.
static func found_count_in_set(types: Array) -> int:
	return _found_among(_recipes_in_set(types)).size()


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


# The tier a refinement attempt is pushing toward -- 1 on a freshly found
# cell (refine == 0), 2 on its next successful refinement, and so on,
# uncapped (M3 §5).
static func refine_tier_target(types: Array, approach: String) -> int:
	return get_cell(types, approach)["refine"] + 1


static func refine_cost(types: Array, approach: String) -> Dictionary:
	var n := refine_tier_target(types, approach)
	var costs := {}
	for ore_type in types:
		costs[ore_type] = REFINE_ORE_PER_TYPE * (n + 1)
	return costs


# Odds fall with each tier but never hit the floor (M3 §7). Refinement has
# no pity channel -- only tier and skill move this number.
static func refine_chance(types: Array, approach: String, skill: int) -> float:
	var n := refine_tier_target(types, approach)
	return maxf(REFINE_CHANCE_FLOOR, REFINE_BASE_CHANCE + (skill - 1) * REFINE_SKILL_BONUS - REFINE_TIER_PENALTY * (n - 1))


# The value a refineStep-targeted recipe field takes on at an arbitrary
# tier -- derived from the recipe's authored base value, never by mutating
# GameData.RECIPES (boot-time content, not part of the snapshotted state
# tree). Split out from refined_value() below so the result screen (ticket
# 08) can show "old value -> new value" for a just-applied tier by asking
# for tier-1 and tier separately.
#
# calc-discovery ticket 10: the targeted field can be either a scalar (a
# Lab-only effect authored with a flat base value) or the pre-existing
# skill-indexed array convention every crafted recipe's effectPower uses
# (systems/crafting.gd's effect_power()) -- refinement stacks as a flat
# bonus on top of that per-skill base rather than replacing it, so a
# refined tutorial recipe (timePearl/enhancementPowder/rewind) keeps
# scaling with crafting skill exactly as before. `skill` is only actually
# read when the field is an Array, but it's a required param anyway (not
# defaulted) so an Array-field caller can't silently fall back to skill 1.
static func value_at_refine_tier(recipe_key: String, tier: int, skill: int) -> Variant:
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var step: Dictionary = r["refineStep"]
	var field: String = step["field"]
	var base: Variant = r[field]
	if base is Array:
		base = base[skill]
	return base + step["add"] * tier


# The current value of a refineStep-targeted recipe field. Deriving it this
# way is what makes refine progress survive Rewind and an app close/reopen
# (M3 §10, spec stories 47-48) for free: the tier count is the only thing
# that needs to persist.
static func refined_value(recipe_key: String, types: Array, approach: String, skill: int) -> Variant:
	var tier: int = get_cell(types, approach)["refine"]
	return value_at_refine_tier(recipe_key, tier, skill)


# Public (not `_`-prefixed): the confirm screen (ticket 08) shows this
# exact reason text next to a disabled Confirm button, same "reason, not
# apology" convention as every other cost-gated action (CONTENT-GUIDE §4).
static func refine_block_reason(types: Array, approach: String) -> String:
	if not Approaches.is_known(approach):
		return "You haven't the technique for that yet."
	var state: String = cell_state(types, approach)
	if state != "found":
		return "Nothing here to refine."
	var costs := refine_cost(types, approach)
	var orichalchum: Dictionary = GameState.state["player"]["orichalchum"]
	for ore_type in costs:
		if orichalchum.get(ore_type, 0) < costs[ore_type]:
			return "Not enough calc."
	return ""


static func can_refine(types: Array, approach: String) -> bool:
	return refine_block_reason(types, approach) == ""


# Re-experiments an already-found effect to push it toward its next tier.
# Ore and a time block are spent regardless of outcome (M3 §7's "ore
# deduction: always"); on success the cell's refine tier increments, which
# is the entirety of "applying" refineStep -- refined_value() reads it back
# out. Inert and never-found cells are never reachable here (M3 §5).
static func refine(types: Array, approach: String) -> Dictionary:
	var reason := refine_block_reason(types, approach)
	if reason != "":
		return { "ok": false, "reason": reason }

	TimeSystem.advance_time_block()

	var player: Dictionary = GameState.state["player"]
	var costs := refine_cost(types, approach)
	for ore_type in costs:
		player["orichalchum"][ore_type] = maxi(0, player["orichalchum"].get(ore_type, 0) - costs[ore_type])

	var skill: int = player["craftingSkill"]
	var chance := refine_chance(types, approach, skill)
	var outcome: String

	if Rng.chance(chance):
		outcome = "refined"
		_set_cell(types, approach, { "refine": refine_tier_target(types, approach) })
		Crafting.award_crafting_xp(XP_REFINE)
	else:
		outcome = "refine_failed"

	_append_note(types, approach, outcome)
	EventBus.state_changed.emit()

	return { "ok": true, "outcome": outcome }


# Public for the same reason as refine_block_reason() above.
static func probe_block_reason(types: Array, approach: String) -> String:
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
	return probe_block_reason(types, approach) == ""


# Type sets the player has touched -- probed or refined at least once.
# Bench notes' listing source (calc-discovery ticket 09, spec story 41).
# Unions notes' and cells' keys rather than trusting notes alone: today
# probe()/refine() always write both together, but the state schema
# describes touched pairings as living in "notes/cells", and a future
# direct cell write (e.g. an NPC-taught grant_effect, ticket 11) should
# still surface here even if it never appends a note. Sorted so render
# order is deterministic across calls.
static func touched_type_sets() -> Array:
	var bench: Dictionary = GameState.state["player"]["bench"]
	var keys: Dictionary = {}
	for key in bench["notes"].keys():
		keys[key] = true
	for cell_key in bench["cells"].keys():
		keys[cell_key.split("|")[0]] = true

	var sorted_keys: Array = keys.keys()
	sorted_keys.sort()

	var sets: Array = []
	for key in sorted_keys:
		sets.append(Array(key.split("+")))  # split() returns PackedStringArray; callers expect a plain Array
	return sets


# The stored note entries for a type set, oldest first, already capped at
# NOTES_CAP by _append_note() below -- an untouched set returns [].
static func notes_for(types: Array) -> Array:
	var bench: Dictionary = GameState.state["player"]["bench"]
	return bench["notes"].get(type_set_key(types), [])


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
	var reason := probe_block_reason(types, approach)
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
