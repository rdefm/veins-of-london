class_name MapPalette
extends RefCounted

# Presentation-side accessor for the Map palette (M1.5 §Map palette,
# data/map_palette.json): every colour the Map tab draws with resolves
# through here at draw/build time, picking the light or dark token set from
# GameState.state["meta"].get("mapDarkMode", false). Faction and ore colours
# come from their own data tables, with an optional dark-only override per id.


static var _light_scope: int = 0


static func is_dark() -> bool:
	if _light_scope > 0:
		return false
	return GameState.state.get("meta", {}).get("mapDarkMode", false)


# Runs `build` with every token resolving to the light set, for screens off
# the Map tab that reuse the map-card family (MapCardStyle) and must not
# follow the Map-only dark toggle.
static func build_light(build: Callable) -> void:
	_light_scope += 1
	build.call()
	_light_scope -= 1


static func colour(key: String) -> Color:
	return colour_in(key, is_dark())


# Fixed light-set value, for callers off the Map tab that share a token.
static func light(key: String) -> Color:
	return colour_in(key, false)


static func colour_in(key: String, dark: bool) -> Color:
	var tokens: Dictionary = GameData.MAP_PALETTE.get("dark" if dark else "light", {})
	if not tokens.has(key):
		push_error("MapPalette: unknown token '%s'" % key)
		return Color()
	return Color(tokens[key])


static func faction_colour(faction_id: String) -> Color:
	return faction_colour_in(faction_id, is_dark())


static func faction_colour_in(faction_id: String, dark: bool) -> Color:
	return _data_colour_in(GameData.FACTIONS[faction_id]["colour"], "factions", faction_id, dark)


static func ore_colour(ore_type: String) -> Color:
	return ore_colour_in(ore_type, is_dark())


static func ore_colour_in(ore_type: String, dark: bool) -> Color:
	return _data_colour_in(GameData.ORE_TYPES[ore_type]["colour"], "oreTypes", ore_type, dark)


static func _data_colour_in(data_hex: String, group: String, id: String, dark: bool) -> Color:
	if dark:
		var overrides: Dictionary = GameData.MAP_PALETTE.get("darkOverrides", {}).get(group, {})
		if overrides.has(id):
			return Color(overrides[id])
	return Color(data_hex)
