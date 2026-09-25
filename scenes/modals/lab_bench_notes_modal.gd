class_name LabBenchNotesModal
extends RefCounted


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Bench notes"))
	var touched := Bench.touched_type_sets()
	if touched.is_empty():
		container.add_child(UI.muted_label("Nothing recorded yet."))
	else:
		for types in touched:
			container.add_child(_notes_card(types))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


static func _notes_card(types: Array) -> Control:
	var c := MapCardStyle.card(12, 0.0)
	c["content"].add_child(UI.heading(_pairing_label(types), 15))
	c["content"].add_child(UI.label("%d/%d" % [Bench.found_count_in_set(types), Bench.get_surveyed_count(types)]))
	for row in _found_recipe_rows(types):
		c["content"].add_child(row)
	for entry in Bench.notes_for(types):
		c["content"].add_child(UI.muted_label(_history_line(entry)))
	return c["panel"]


static func _found_recipe_rows(types: Array) -> Array:
	var rows: Array = []
	for approach_id in GameData.APPROACHES.keys():
		var recipe_key := Bench.find_recipe_for_cell(types, approach_id)
		if recipe_key == "" or Bench.cell_state(types, approach_id) != "found":
			continue
		var r: Dictionary = GameData.RECIPES[recipe_key]
		var tier: int = Bench.get_cell(types, approach_id)["refine"]
		var row := UI.vbox(4)
		row.add_child(UI.symbol_row([{ "symbol": r["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — tier %d" % [r["name"], tier]]))
		LabBenchModalHelpers.append_refine_controls(row, r, types, approach_id)
		rows.append(row)
	return rows


static func _pairing_label(types: Array) -> String:
	var names: Array[String] = []
	for type_id in types:
		names.append(String(type_id).capitalize())
	if names.size() == 1:
		return names[0]
	return "%s and %s" % [names[0], names[1]]


static func _history_line(entry: Dictionary) -> String:
	var approach_name: String = GameData.APPROACHES[entry["approach"]]["name"]
	return "Day %d — %s: %s" % [entry["day"], approach_name, LabBenchModalHelpers.outcome_heading(entry["outcome"])]
