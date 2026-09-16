# Row builders shared by sell_menu_modal.gd's Archie and faction lanes.
class_name SellRowBuilders
extends RefCounted


static var _ore_expanded: bool = true
static var _items_expanded: bool = true
static var _assets_expanded: bool = true


static func sell_row(parts: Array, key: String, qty: int, max_qty: int) -> Control:
	var row := UI.hflow()
	var text_row := UI.symbol_row(parts)
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	var stepper := UI.hbox()
	stepper.add_child(UI.button("-", func(): Economy.adjust_sell_qty(key, -1, max_qty)))
	stepper.add_child(UI.label(str(qty)))
	stepper.add_child(UI.button("+", func(): Economy.adjust_sell_qty(key, 1, max_qty)))
	row.add_child(stepper)
	return row


static func buy_ore_row(parts: Array, key: String, qty: int, max_qty: int) -> Control:
	var row := UI.hflow()
	var text_row := UI.symbol_row(parts)
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	if max_qty <= 0:
		row.add_child(UI.muted_label("Sold out"))
		return row
	var stepper := UI.hbox()
	stepper.add_child(UI.button("-", func(): Economy.adjust_sell_qty(key, -1, max_qty)))
	stepper.add_child(UI.label(str(qty)))
	stepper.add_child(UI.button("+", func(): Economy.adjust_sell_qty(key, 1, max_qty)))
	row.add_child(stepper)
	return row


static func sell_vein_row(parts: Array, vein_id: String, selected: bool) -> Control:
	var row := UI.hflow(6)
	row.add_child(UI.button("☑" if selected else "☐", func(): Economy.toggle_sell_vein(vein_id)))
	var text_row := UI.symbol_row(parts)
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	return row


static func buy_vein_row(parts: Array, vein_id: String, selected: bool) -> Control:
	var row := UI.hflow(6)
	row.add_child(UI.button("☑" if selected else "☐", func(): Economy.toggle_buy_vein(vein_id)))
	var text_row := UI.symbol_row(parts)
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	return row


static func sell_sections(container: VBoxContainer, ore_rows: Array, item_rows: Array, asset_rows: Array) -> void:
	var ore_section := UI.collapsible_section("Ore", _ore_expanded, func(v): _ore_expanded = v)
	for row in ore_rows:
		ore_section["content"].add_child(row)
	container.add_child(ore_section["panel"])

	var items_section := UI.collapsible_section("Items", _items_expanded, func(v): _items_expanded = v)
	for row in item_rows:
		items_section["content"].add_child(row)
	container.add_child(items_section["panel"])

	if GameState.state["flags"].get("veinSaleUnlocked", false):
		var assets_section := UI.collapsible_section("Assets", _assets_expanded, func(v): _assets_expanded = v)
		for row in asset_rows:
			assets_section["content"].add_child(row)
		container.add_child(assets_section["panel"])
