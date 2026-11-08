class_name ProductionSettings
extends RefCounted

# Master + per-recipe override production settings (R§3.10). A setting set is
# { production, keep, sellAbove, mood, coverContracts }. state.production holds
# { master, overrides: { recipeKey: set } }; a recipe without an override
# follows the master. Editing any field copies the whole master into an
# override first, revert deletes it. Static funcs only.

const FIELDS := ["production", "keep", "sellAbove", "mood", "coverContracts"]


static func default_master() -> Dictionary:
	return {
		"production": 0,
		"keep": 0,
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


# Keep (never-sell floor) stays strictly below Sell-above. Raising Keep pushes
# Sell-above up; lowering Sell-above stops one above Keep. Both clamp to
# 0..productionTargetMax. Production is not part of the ordering.
static func set_keep(recipe_key: String, keep: int) -> void:
	var ordered := ordered_pair(keep, int(resolve(recipe_key)["sellAbove"]))
	set_field(recipe_key, "keep", ordered["keep"])
	set_field(recipe_key, "sellAbove", ordered["sellAbove"])
	EventBus.mark_changed()


static func set_sell_above(recipe_key: String, sell_above: int) -> void:
	var ordered := ordered_pair(int(resolve(recipe_key)["keep"]), sell_above)
	set_field(recipe_key, "keep", ordered["keep"])
	set_field(recipe_key, "sellAbove", ordered["sellAbove"])
	EventBus.mark_changed()


static func set_master_production(production: int) -> void:
	master()["production"] = clampi(production, 0, GameData.PRODUCTION_TARGET_MAX)
	EventBus.mark_changed()


static func set_master_keep(keep: int) -> void:
	var ordered := ordered_pair(keep, int(master()["sellAbove"]))
	master()["keep"] = ordered["keep"]
	master()["sellAbove"] = ordered["sellAbove"]
	EventBus.mark_changed()


static func set_master_sell_above(sell_above: int) -> void:
	var ordered := ordered_pair(int(master()["keep"]), sell_above)
	master()["keep"] = ordered["keep"]
	master()["sellAbove"] = ordered["sellAbove"]
	EventBus.mark_changed()


# { keep, sellAbove } with keep < sellAbove. Keep never exceeds max-1, so Sell-above always has room above it.
static func ordered_pair(keep: int, sell_above: int) -> Dictionary:
	var top: int = GameData.PRODUCTION_TARGET_MAX
	keep = clampi(keep, 0, top - 1)
	sell_above = clampi(sell_above, 0, top)
	if sell_above <= keep:
		sell_above = keep + 1
	return { "keep": keep, "sellAbove": sell_above }


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
	for field in ["production", "keep", "sellAbove"]:
		setting_set[field] = clampi(int(setting_set[field]), 0, GameData.PRODUCTION_TARGET_MAX)
	var ordered := ordered_pair(setting_set["keep"], setting_set["sellAbove"])
	setting_set["keep"] = ordered["keep"]
	setting_set["sellAbove"] = ordered["sellAbove"]
	if not GameData.MARKET["autoSell"]["moods"].has(setting_set["mood"]):
		setting_set["mood"] = defaults["mood"]
	setting_set["coverContracts"] = bool(setting_set["coverContracts"])
