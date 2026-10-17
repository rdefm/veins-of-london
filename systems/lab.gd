class_name Lab
extends RefCounted

# The live Lab (.scratch/lab-port/spec.md): recipe knowledge and procedure
# definitions over GameState.state["lab"] and data/lab.json (GameData.LAB).
#
# A recipe is known once granted (grant_recipe(): its base procedure). Its
# hidden steps -- ideal steps the base procedure lacks or gets wrong, each
# with an authored hint and rung -- are then granted at a specificity
# (grant_steps()): "vague" shows a fuzzy region and direction, "exact" the
# true band. A grant only ever raises a step's specificity.


static func _data() -> Dictionary:
	return GameData.LAB


# ── State ────────────────────────────────────────────────────────────────

static func new_state() -> Dictionary:
	return {
		# recipeKey -> { steps: { "<idealIndex>": specificity }, vagueHits:
		# { "<idealIndex>": in-band runs while vague } }. Unknown steps are
		# absent; specificity is a data/lab.json specificities entry.
		"known": {},
		# recipeKey -> 1..5, only ever rising.
		"bestRanks": {},
		# null, or the run in progress.
		"activeRun": null,
		# Recipe keys performed by hand at least once (batch needs one).
		"performedOnce": [],
	}


static func _root() -> Dictionary:
	return GameState.state["lab"]


# ── Knowledge ────────────────────────────────────────────────────────────

static func procedure_def(recipe_key: String) -> Dictionary:
	return _data().get("procedures", {}).get(recipe_key, {})


static func is_known(recipe_key: String) -> bool:
	return _root()["known"].has(recipe_key)


# Known recipes in data/recipes.json order; with an ore type, only those
# using it as an ingredient (the recipe book's ore tab).
static func known_recipes(ore_type: String = "") -> Array:
	var result := []
	for recipe_key in GameData.RECIPES.keys():
		if not is_known(recipe_key):
			continue
		if ore_type.is_empty() or GameData.RECIPES[recipe_key].get("ingredients", {}).has(ore_type):
			result.append(recipe_key)
	return result


# Adds a recipe at base (no hidden steps known). Granting a known recipe
# changes nothing.
static func grant_recipe(recipe_key: String) -> Dictionary:
	if procedure_def(recipe_key).is_empty():
		return { "ok": false, "reason": "Unknown recipe." }
	var known: Dictionary = _root()["known"]
	if not known.has(recipe_key):
		known[recipe_key] = { "steps": {}, "vagueHits": {} }
		EventBus.state_changed.emit()
	return { "ok": true }


# Grants hidden ideal steps of a known recipe at a specificity: unknown ->
# granted, vague -> exact in place. A grant at or below a step's current
# specificity leaves it alone. Indices that aren't hidden steps are skipped.
# { ok, granted: [idealIndex] } -- the steps whose specificity rose.
static func grant_steps(recipe_key: String, ideal_indices: Array, specificity: String) -> Dictionary:
	var order: Array = _data().get("specificities", [])
	if not order.has(specificity):
		return { "ok": false, "reason": "Unknown specificity." }
	if not is_known(recipe_key):
		return { "ok": false, "reason": "Recipe not known." }
	var entry: Dictionary = _root()["known"][recipe_key]
	var granted := []
	for index in ideal_indices:
		var i := int(index)
		if _hint_for_step(recipe_key, i).is_empty():
			continue
		var key := str(i)
		if order.find(entry["steps"].get(key, "")) >= order.find(specificity):
			continue
		entry["steps"][key] = specificity
		entry["vagueHits"].erase(key)
		granted.append(i)
	if not granted.is_empty():
		EventBus.state_changed.emit()
	return { "ok": true, "granted": granted }


# Ideal indices of a recipe's hidden steps tagged with a rung.
static func rung_steps(recipe_key: String, rung: String) -> Array:
	var result := []
	for hint in procedure_def(recipe_key).get("hints", []):
		if hint.get("rung") == rung:
			result.append(int(hint["step"]))
	return result


# A hidden step's specificity, or "" while unknown.
static func step_specificity(recipe_key: String, ideal_index: int) -> String:
	if not is_known(recipe_key):
		return ""
	return _root()["known"][recipe_key]["steps"].get(str(ideal_index), "")


# The steps the player knows: the base procedure, where each granted hint
# either corrects the target of the base step matching its ideal step or
# inserts that ideal step (no calc) in ideal order. An unknown ideal step is
# simply absent. Each step carries knowledge "base", "vague" or "exact"; a
# hinted one also its hintId and note. While the player's Prophet's Breath
# effect runs, every ideal step not known exact shows its true target as
# knowledge "revealed" (unknown steps inserted, vague ones sharpened, no
# note); knowledge is untouched. Targets are floats so a saved run
# round-trips unchanged.
static func known_procedure(recipe_key: String) -> Array:
	var procedure := procedure_def(recipe_key)
	var ideal: Array = procedure["ideal"]
	var base: Array = procedure["base"]
	var granted := {}
	for hint in procedure.get("hints", []):
		var level := step_specificity(recipe_key, int(hint["step"]))
		if not level.is_empty():
			granted[int(hint["step"])] = { "hint": hint, "level": level }
	if ActiveEffects.prophets_breath_active():
		for i in ideal.size():
			if granted.get(i, {}).get("level") != "exact":
				granted[i] = { "level": "revealed" }
	var steps := []
	var next_ideal := 0
	var base_matches := match_ideal(ideal, base)
	for i in base.size():
		var m: int = base_matches[i]
		if m >= 0:
			_insert_hinted(steps, ideal, granted, next_ideal, m)
			next_ideal = m + 1
		var step: Dictionary = base[i].duplicate(true)
		step["target"] = float(step["target"])
		step["knowledge"] = "base"
		if granted.has(m):
			_apply_hint(step, ideal[m], granted[m])
		steps.append(step)
	_insert_hinted(steps, ideal, granted, next_ideal, ideal.size())
	return steps


static func _insert_hinted(steps: Array, ideal: Array, granted: Dictionary, from: int, to: int) -> void:
	for i in range(from, to):
		if granted.has(i):
			var step := { "apparatus": ideal[i]["apparatus"] }
			_apply_hint(step, ideal[i], granted[i])
			steps.append(step)


static func _apply_hint(step: Dictionary, ideal_step: Dictionary, grant: Dictionary) -> void:
	step["target"] = float(ideal_step["target"])
	step["knowledge"] = grant["level"]
	step.erase("note")
	if grant.has("hint"):
		step["hintId"] = grant["hint"]["id"]
		step["note"] = grant["hint"][grant["level"]]["note"]


# The hint at an ideal step, or {} when it has none.
static func _hint_for_step(recipe_key: String, ideal_index: int) -> Dictionary:
	for hint in procedure_def(recipe_key).get("hints", []):
		if int(hint["step"]) == ideal_index:
			return hint
	return {}


static func _hint_by_id(recipe_key: String, hint_id: String) -> Dictionary:
	for hint in procedure_def(recipe_key).get("hints", []):
		if hint["id"] == hint_id:
			return hint
	return {}


# ── Bands ────────────────────────────────────────────────────────────────

# band_half_width = baseTolerance × (1 + skillFactor × craftingSkill).
static func band_half_width(recipe_key: String) -> float:
	var skill := int(GameState.state["player"]["craftingSkill"])
	return float(procedure_def(recipe_key)["baseTolerance"]) * (1.0 + float(_data().get("skillFactor", 0.0)) * skill)


# What the gauge shows for a known step, clamped to the 0-100 gauge: the
# band around its target, or for a vague step a fuzzy region vagueSpread
# wider each side and shifted by the hint's offset (|offset| <= vagueSpread,
# so the true band always sits inside it).
static func step_region(recipe_key: String, step: Dictionary) -> Dictionary:
	var half := band_half_width(recipe_key)
	var low := float(step["target"]) - half
	var high := float(step["target"]) + half
	var vague: bool = step.get("knowledge", "base") == "vague"
	if vague:
		var spread := float(_data().get("vagueSpread", 0))
		var offset := float(_hint_by_id(recipe_key, step["hintId"])["vague"]["offset"])
		low += offset - spread
		high += offset + spread
	return { "low": maxf(0.0, low), "high": minf(100.0, high), "vague": vague }


# ── Matching ─────────────────────────────────────────────────────────────

# Pairs each performed step with an ideal step: in order, same apparatus,
# the ideal step's ore (if it names one) already in the mixture by then,
# each ideal step used at most once. -1 marks an extra step.
static func match_ideal(ideal: Array, performed: Array) -> Array[int]:
	var matches: Array[int] = []
	var next := 0
	var mixture := {}
	for step in performed:
		for ore_type in _added_ores(step):
			mixture[ore_type] = true
		var found := -1
		for i in range(next, ideal.size()):
			if ideal[i]["apparatus"] == step["apparatus"] and (not ideal[i].has("ore") or mixture.has(ideal[i]["ore"])):
				found = i
				break
		matches.append(found)
		if found >= 0:
			next = found + 1
	return matches


# The ore types a step adds to the mixture: a performed step's ores, or a
# base procedure step's calc.
static func _added_ores(step: Dictionary) -> Array:
	return step["ores"] if step.has("ores") else step.get("calc", {}).keys()
