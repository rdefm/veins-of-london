class_name RecipeKnowledge
extends RefCounted

# Recipe acquisition over the Lab's knowledge (.scratch/recipe-acquisition/
# spec.md § New RecipeKnowledge system module), tuned by
# data/recipe_knowledge.json (GameData.RECIPE_KNOWLEDGE).
#
# Each recipe has a ladder of rungs: base (the recipe itself) then the hint
# rungs data/lab.json tags its hidden steps with. A hint rung is owned once
# every one of its steps is at least vague, exact once all are exact. The
# rank ceiling is that of the highest rung reached without a gap.
#
# grant_rung() teaches a rung. A grant naming a source that would teach
# nothing new falls back (spec § Further Notes): the same rung on another of
# that source's recipes, else crafting XP, a relation bump and a line.


static func _data() -> Dictionary:
	return GameData.RECIPE_KNOWLEDGE


static func rungs() -> Array:
	return _data().get("rungs", [])


# ── Ladder ───────────────────────────────────────────────────────────────

# "unknown", "vague" or "exact". base is exact once the recipe is known.
static func rung_state(recipe_key: String, rung: String) -> String:
	if not Lab.is_known(recipe_key):
		return "unknown"
	if rung == "base":
		return "exact"
	var steps := Lab.rung_steps(recipe_key, rung)
	if steps.is_empty():
		return "unknown"
	var all_exact := true
	for i in steps:
		var level := Lab.step_specificity(recipe_key, int(i))
		if level.is_empty():
			return "unknown"
		if level != "exact":
			all_exact = false
	return "exact" if all_exact else "vague"


static func owns_rung(recipe_key: String, rung: String) -> bool:
	return rung_state(recipe_key, rung) != "unknown"


# The highest rank a run can reach: the ceiling of the last rung owned with
# every rung before it owned too. 0 for an unknown recipe.
static func rank_ceiling(recipe_key: String) -> int:
	var ceiling := 0
	for rung in rungs():
		if not owns_rung(recipe_key, rung):
			break
		ceiling = int(_data()["rungCeilings"][rung])
	return ceiling


# ── Sources ──────────────────────────────────────────────────────────────

# The seller id whose ores cover every ingredient ore, else defaultSeller.
static func seller_of(recipe_key: String) -> String:
	var ores: Array = GameData.RECIPES.get(recipe_key, {}).get("ingredients", {}).keys()
	var sellers: Dictionary = _data().get("sellers", {})
	for seller_id in sellers.keys():
		var allowed: Array = sellers[seller_id].get("ores", [])
		if ores.all(func(ore): return allowed.has(ore)):
			return seller_id
	return str(_data().get("defaultSeller", ""))


# { source, pointer } with a null pointer read as unknownPointer.
static func master_source(recipe_key: String) -> Dictionary:
	var entry: Dictionary = _data().get("masterSources", {}).get(recipe_key, {})
	var pointer = entry.get("pointer")
	return {
		"source": entry.get("source"),
		"pointer": str(_data().get("unknownPointer", "???")) if pointer == null else str(pointer),
	}


static func _resolve_source(source_id: String) -> String:
	return str(_data().get("sourceAliases", {}).get(source_id, source_id))


# Recipes a source sells or is master source for, in data/recipes.json order.
static func _source_recipes(source_id: String) -> Array:
	var resolved := _resolve_source(source_id)
	var result := []
	for recipe_key in GameData.RECIPES.keys():
		var master = master_source(recipe_key)["source"]
		if seller_of(recipe_key) == resolved or (master != null and _resolve_source(str(master)) == resolved):
			result.append(recipe_key)
	return result


# ── Granting ─────────────────────────────────────────────────────────────

# Teaches a rung at a specificity (ignored for base). A hint rung on an
# unknown recipe grants the recipe too. Vague -> exact upgrades in place; a
# grant at or below what's held changes nothing.
# { ok, path, recipe, rung, line? }: path "granted" (taught as asked),
# "redirected" (nothing new, so recipe names the source's other recipe that
# got the rung), "consolation" (nothing new and nothing left at the source:
# XP + relation, line to show) or "none" (nothing new, no source).
static func grant_rung(recipe_key: String, rung: String, specificity: String = "exact", source_id: String = "") -> Dictionary:
	if Lab.procedure_def(recipe_key).is_empty():
		return { "ok": false, "reason": "Unknown recipe." }
	if not rungs().has(rung):
		return { "ok": false, "reason": "Unknown rung." }
	if not GameData.LAB.get("specificities", []).has(specificity):
		return { "ok": false, "reason": "Unknown specificity." }
	if _teach(recipe_key, rung, specificity):
		return { "ok": true, "path": "granted", "recipe": recipe_key, "rung": rung }
	if source_id.is_empty():
		return { "ok": true, "path": "none", "recipe": recipe_key, "rung": rung }
	for other in _source_recipes(source_id):
		if other != recipe_key and _open_for(other, rung):
			_teach(other, rung, specificity)
			return { "ok": true, "path": "redirected", "recipe": other, "rung": rung }
	return _console(source_id, recipe_key, rung)


# Whether a fallback may teach this rung here: base on an unknown recipe, a
# hint rung not yet owned on a known one.
static func _open_for(recipe_key: String, rung: String) -> bool:
	if rung == "base":
		return not Lab.is_known(recipe_key)
	return Lab.is_known(recipe_key) and not owns_rung(recipe_key, rung)


# True when the grant raised anything.
static func _teach(recipe_key: String, rung: String, specificity: String) -> bool:
	var was_known := Lab.is_known(recipe_key)
	Lab.grant_recipe(recipe_key)
	if rung == "base":
		return not was_known
	var granted: Array = Lab.grant_steps(recipe_key, Lab.rung_steps(recipe_key, rung), specificity).get("granted", [])
	return not was_known or not granted.is_empty()


static func _console(source_id: String, recipe_key: String, rung: String) -> Dictionary:
	var collision: Dictionary = _data()["collision"]
	Crafting.award_crafting_xp(int(collision["xp"]))
	if GameState.state["contacts"].has(source_id):
		Contacts.award_relation(source_id, int(collision["relation"]))
	elif GameState.state["factions"].has(source_id):
		Factions.adjust_player_relation(source_id, int(collision["relation"]))
	var lines: Dictionary = collision["lines"]
	var line: String = lines.get(source_id, lines.get(_resolve_source(source_id), lines["default"]))
	EventBus.state_changed.emit()
	return { "ok": true, "path": "consolation", "recipe": recipe_key, "rung": rung, "line": line }
