class_name SellVeinQuoteModal
extends RefCounted


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var vein_id: String = data["veinId"]
	var price: int = data["price"]
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein == null:
		Modal.close()
		return
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]

	container.add_child(UI.heading("Sell this vein?"))
	container.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, "%s vein — £%d." % [ore["name"], price]]))
	container.add_child(UI.muted_label("It stops being yours. Someone else's line, someone else's cut, from here on."))
	container.add_child(UI.button("Confirm sale", func(): _confirm(vein_id)))
	container.add_child(UI.button("Cancel", func(): Modal.close()))


static func _confirm(vein_id: String) -> void:
	VeinTrade.sell_to_faction(vein_id, VeinTrade.SELL_FACTION_ID)
	Modal.close()
