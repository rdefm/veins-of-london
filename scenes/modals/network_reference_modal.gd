class_name NetworkReferenceModal
extends RefCounted


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Network Reference"))
	container.add_child(UI.muted_label("The lines are money. The dots are where it's coming from — or where someone beat you to it."))
	container.add_child(_legend_row("Amber line", "Your line — stops joined in claim order."))
	container.add_child(_legend_row("Coloured line", "A faction's line, in their colour."))
	container.add_child(_legend_row("Grey stub", "Someone else's claim — not yours, not connected to anything."))
	container.add_child(_legend_row("Ringed dot + symbol", "Your vein. The symbol shows the ore."))
	container.add_child(_legend_row("Tick mark", "Unclaimed site. Double tick — richer ground."))
	container.add_child(_legend_row("Filled grey dot", "Claimed. Not by you."))
	container.add_child(_legend_row("Amber halo", "Charged — ready to harvest."))
	container.add_child(_legend_row("Numeral badge", "Vein level."))
	container.add_child(_legend_row("Padlock", "Security tier — colour shows how well-warded."))
	container.add_child(_legend_row("Zone tint", "A faction's presence in the district."))
	container.add_child(_legend_glyph_row("⌂", Icons.draw_home, " pin", "Home. Taps through to HQ."))
	container.add_child(_legend_glyph_row("✉", Icons.draw_phone, " pin", "Someone's waiting on you there."))
	container.add_child(_legend_row("Padlocked pin", "The Soho market. Not yet."))
	container.add_child(_legend_row("Amber ring", "Where you are right now."))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


static func _legend_row(glyph_label: String, description: String) -> Control:
	var row := UI.vbox(2)
	row.add_child(UI.label(glyph_label))
	row.add_child(UI.muted_label(description))
	return row


static func _legend_glyph_row(symbol: String, fallback: Callable, suffix_text: String, description: String) -> Control:
	var row := UI.vbox(2)
	row.add_child(UI.symbol_row([{ "symbol": symbol, "fallback": fallback }, suffix_text]))
	row.add_child(UI.muted_label(description))
	return row
