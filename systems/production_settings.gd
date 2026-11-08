class_name ProductionSettings
extends RefCounted

# Master + per-recipe override production settings (RÂ§3.10). A setting set is
# { production, sellAbove, mood, coverContracts }. state.production holds
# { master, overrides: { recipeKey: set } }; a recipe without an override
# follows the master. Editing any field copies the whole master into an
# override first, revert deletes it. Static funcs only.

const FIELDS := ["production", "sellAbove", "mood", "coverContracts"]


static func default_master() -> Dictionary:
	return {
		"production": 0,
		"sellAbove": GameData.PRODUCTION_TARGET_MAX,
		"mood": GameData.MARKET["autoSell"]["defaultMood"],
		"coverContracts": true,
	}


static func default_state() -> Dictionary:
	return { "master": default_master(), "overrides": {} }


static func master() -> Dictionary:
	return GameState.state["production"]["master"]


static func overrides() -> Dictionary:
	return GameState.state["production"]["overrides"]


static func has_override(recipe_key: String) -> bool:
	return overrides().has(recipe_key)


# The effective setting set for a recipe: its override, else the master.
static func resolve(recipe_key: String) -> Dictionary:
	return overrides().get(recipe_key, master())


# Sets one field on a recipe, creating a full override from the master first.
static func set_field(recipe_key: String, field: String, value: Variant) -> void:
	if not overrides().has(recipe_key):
		overrides()[recipe_key] = master().duplicate()
	overrides()[recipe_key][field] = value


static func revert(recipe_key: String) -> void:
	if overrides().erase(recipe_key):
		EventBus.mark_changed()


# Sets one field on the master; recipes without an override follow.
static func set_master_field(field: String, value: Variant) -> void:
	master()[field] = value
	EventBus.mark_changed()


# Sell-above clamps to 0..productionTargetMax; it is independent of Production.
static func set_sell_above(recipe_key: String, sell_above: int) -> void:
	set_field(recipe_key, "sellAbove", clampi(sell_above, 0, GameData.PRODUCTION_TARGET_MAX))
	EventBus.mark_changed()


static func set_master_production(production: int) -> void:
	master()["production"] = clampi(production, 0, GameData.PRODUCTION_TARGET_MAX)
	EventBus.mark_changed()


static func set_master_sell_above(sell_above: int) -> void:
	master()["sellAbove"] = clampi(sell_above, 0, GameData.PRODUCTION_TARGET_MAX)
	EventBus.mark_changed()


# Load fix-up: fills missing fields from defaults, int-ifies and clamps
# numbers, drops unknown moods back to the default.
static func sanitize(production: Dictionary) -> void:
	var defaults := default_master()
	if not production.get("master") is Dictionary:
		production["master"] = defaults
	if not production.get("overrides") is Dictionary:
		production["overrides"] = {}
	_sanitize_set(production["master"], defaults)
	for setting_set in production["overrides"].values():
		_sanitize_set(setting_set, defaults)


static func _sanitize_set(setting_set: Dictionary, defaults: Dictionary) -> void:
	for field in FIELDS:
		if not setting_set.has(field):
			setting_set[field] = defaults[field]
	for field in ["production", "sellAbove"]:
		setting_set[field] = clampi(int(setting_set[field]), 0, GameData.PRODUCTION_TARGET_MAX)
	setting_set.erase("keep")
	if not GameData.MARKET["autoSell"]["moods"].has(setting_set["mood"]):
		setting_set["mood"] = defaults["mood"]
	setting_set["coverContracts"] = bool(setting_set["coverContracts"])
