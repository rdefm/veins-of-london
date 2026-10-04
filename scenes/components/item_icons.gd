class_name ItemIcons
extends RefCounted
# Shared crafted-consumable -> pixel-art icon lookup. Paths come from the
# "icon" field in data/recipes.json; symbol-row parts built here draw the
# texture in place of the text glyph.

const ICON_SIZE := 24.0

static var _cache: Dictionary = {}


static func texture(recipe_key: String) -> Texture2D:
	if _cache.has(recipe_key):
		return _cache[recipe_key]
	var recipe: Dictionary = GameData.RECIPES.get(recipe_key, {})
	var path: String = recipe.get("icon", "")
	var tex: Texture2D = load(path) if path != "" and ResourceLoader.exists(path) else null
	_cache[recipe_key] = tex
	return tex


# Part dict for UI.symbol_row / symbol_button / symbol_option_row.
static func part(recipe_key: String) -> Dictionary:
	var recipe: Dictionary = GameData.RECIPES.get(recipe_key, {})
	return {
		"symbol": recipe.get("symbol", ""),
		"fallback": SymbolGlyph.generic_fallback(),
		"icon": texture(recipe_key),
	}
