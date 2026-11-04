class_name ItemIcons
extends RefCounted
# Shared crafted-consumable -> pixel-art icon lookup. Paths come from the
# "icon" field in data/recipes.json; symbol-row parts built here draw the
# texture in place of the text glyph.

const ICON_SIZE := 24.0

# Convention folder: <ICON_DIR><recipe key>.png wins over the recipe's "icon".
static var icon_dir := "res://assets/items/"
static var _cache: Dictionary = {}


static func texture(recipe_key: String) -> Texture2D:
	if _cache.has(recipe_key):
		return _cache[recipe_key]
	var recipe: Dictionary = GameData.RECIPES.get(recipe_key, {})
	var tex: Texture2D = _load_if_exists("%s%s.png" % [icon_dir, recipe_key])
	if tex == null:
		tex = _load_if_exists(recipe.get("icon", ""))
	_cache[recipe_key] = tex
	return tex


static func _load_if_exists(path: String) -> Texture2D:
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null


# Part dict for UI.symbol_row / symbol_button / symbol_option_row.
static func part(recipe_key: String) -> Dictionary:
	var recipe: Dictionary = GameData.RECIPES.get(recipe_key, {})
	return {
		"symbol": recipe.get("symbol", ""),
		"fallback": SymbolGlyph.generic_fallback(),
		"icon": texture(recipe_key),
	}
