class_name DialWindModal
extends RefCounted
## Wind ore choice, opened only when 2+ Lenses are loaded: one row per loaded
## Lens, paying a charge in that Lens's ore (R§3.5). data: { owner }.

const HEADING := "Wind +1 — pay in which calc?"


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var owner_id: String = data.get("owner", "")
	container.add_child(UI.heading(HEADING))
	var dial: Variant = Dial.dial_of(owner_id)
	if dial != null and dial["movement"] != null:
		var movement: Dictionary = dial["movement"]
		var cost: int = Dial.winding_cost_per_charge(movement["archetype"], movement["tier"])
		var full: bool = dial["currentCharge"] >= dial["maxCharge"]
		for lens in Lenses.loaded(owner_id):
			var ore: String = lens["ore"]
			var have: int = GameState.state["player"]["orichalchum"].get(ore, 0)
			var row := MapCardStyle.symbol_option_row(["Pay %d " % cost, SymbolGlyph.ore_glyph(ore), " (have %d)" % have], func(): _wind(owner_id, ore), full or have < cost)
			row.name = "WindOre_%s" % ore
			container.add_child(row)
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Cancel", func(): Modal.close())]))


static func _wind(owner_id: String, ore: String) -> void:
	var result := Dial.wind(1, owner_id, ore)
	if result["ok"]:
		Modal.close()
	else:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
