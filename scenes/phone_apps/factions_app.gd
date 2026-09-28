# Factions: a London overview table (player, factions, Independents × ore
# type, ore/crafting toggle) then one card per faction with its economic
# identity and its ore- and crafting-share bars (spec §UI reads). Shares
# only -- holdings and vein kits never show. The toggle is view state.
class_name FactionsApp
extends PhoneApp

const ARCHETYPE_NAMES := {
	"producer": "Producer",
	"crafter": "Crafter",
	"informationBroker": "Information broker",
	"manipulator": "Manipulator",
}
const TALLY_NAMES := { "ore": "Ore", "craft": "Crafting" }
const PRODUCER_NAMES := { Shares.PLAYER: "You", Shares.INDEPENDENTS: "Independents" }

var _tally := "ore"


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Factions"))
	content.add_child(UI.muted_label("Build relations. Join. Use rooms."))
	content.add_child(_build_overview())

	for faction_id in GameData.FACTIONS.keys():
		content.add_child(ContactCards.build_faction_card(faction_id, _build_economy(faction_id)))


func _build_overview() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("London's calc, last %d days" % GameData.SHARES_WINDOW_DAYS, 15))
	var toggle := UI.hbox()
	for tally in TALLY_NAMES:
		var button := UI.button(TALLY_NAMES[tally], func(): _set_tally(tally))
		button.disabled = _tally == tally
		button.set_meta(ContactCards.TOGGLE_OPTION_META, true)
		toggle.add_child(UI.expand_fill(button))
	c["content"].add_child(toggle)

	var grid := GridContainer.new()
	grid.columns = 1 + GameData.CANONICAL_ORE_TYPES.size()
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_child(Control.new())
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		grid.add_child(_ore_glyph(ore_type))
	var table := Shares.overview(_tally)
	for producer in Shares.producers():
		grid.add_child(UI.expand_fill(UI.label(_producer_name(producer))))
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			grid.add_child(UI.label(_percent(table[producer][ore_type])))
	c["content"].add_child(grid)
	return c["panel"]


func _set_tally(tally: String) -> void:
	if tally == _tally:
		return
	_tally = tally
	refresh()


# Archetype, ores, crafted items, and share bars for the primary and
# secondary ore.
func _build_economy(faction_id: String) -> Control:
	var f: Dictionary = GameData.FACTIONS[faction_id]
	var box := UI.vbox(4)
	box.add_child(UI.label(ARCHETYPE_NAMES.get(f["archetype"], String(f["archetype"]).capitalize())))
	box.add_child(UI.label("Ore: %s, then %s" % [_ore_name(f["primaryOre"]), _ore_name(f["secondaryOre"])]))
	var items: Array[String] = []
	for recipe_key in f["crafts"]:
		items.append(GameData.RECIPES[recipe_key]["name"])
	box.add_child(UI.label("Crafts: %s" % (", ".join(items) if not items.is_empty() else "nothing")))
	for ore_type in [f["primaryOre"], f["secondaryOre"]]:
		box.add_child(_share_row("%s ore" % _ore_name(ore_type), Shares.ore_share(faction_id, ore_type)))
		box.add_child(_share_row("%s crafting" % _ore_name(ore_type), Shares.crafting_share(faction_id, ore_type)))
	return box


func _share_row(title: String, fraction: float) -> Control:
	var box := UI.vbox(2)
	box.add_child(UI.muted_label("%s · %s" % [title, _percent(fraction)]))
	box.add_child(UI.bar(fraction, 1.0))
	return box


func _ore_glyph(ore_type: String) -> Control:
	var glyph := SymbolGlyph.new()
	glyph.symbol = GameData.ORE_TYPES[ore_type]["symbol"]
	glyph.draw_fallback = SymbolGlyph.ore_fallback(ore_type)
	glyph.custom_minimum_size = Vector2(UI.SYMBOL_GLYPH_SIZE, UI.SYMBOL_GLYPH_SIZE)
	glyph.glyph_radius = UI.SYMBOL_GLYPH_SIZE * 0.34
	glyph.color = MapPalette.ore_colour_in(ore_type, true)
	return glyph


func _producer_name(producer: String) -> String:
	if PRODUCER_NAMES.has(producer):
		return PRODUCER_NAMES[producer]
	return GameData.FACTIONS[producer]["shortName"]


# Short form ("Life"); the data name ("Life Orichalchum") is too long for a row.
func _ore_name(ore_type: String) -> String:
	return ore_type.capitalize()


static func _percent(fraction: float) -> String:
	return "%d%%" % roundi(fraction * 100.0)
