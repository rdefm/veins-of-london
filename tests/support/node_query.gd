extends RefCounted

# Shared node-tree query helpers for off-tree screen tests. Static; use via
# `const NodeQuery := preload("res://tests/support/node_query.gd")`.
#   label_texts(root)                      every Label descendant's text, tree order
#   label_texts_with_symbols(root)         label_texts plus the effective text of each SymbolGlyph's parent row
#   symbol_row_texts(root)                 label_texts, but each SymbolGlyph row's labels collapse into one effective_text entry
#   effective_text(control)                a row's SymbolGlyph symbols and Label texts concatenated in child order
#   find_button(root, text)                first Button descendant whose text matches, or null
#   find_button_by_effective_text(root, t) find_button that also matches a glyph+label child row's effective text
#   button_texts(root)                     every Button descendant's text, tree order
#   find_tiles(root)                       every AppTile descendant, tree order


static func label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	return texts


static func label_texts_with_symbols(root: Node) -> Array[String]:
	var texts: Array[String] = label_texts(root)
	for g in root.find_children("", "SymbolGlyph", true, false):
		var parent := (g as SymbolGlyph).get_parent() as Control
		if parent:
			texts.append(effective_text(parent))
	return texts


static func symbol_row_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	var symbol_row_parents: Dictionary = {}
	for g in root.find_children("", "SymbolGlyph", true, false):
		var parent := (g as SymbolGlyph).get_parent() as Control
		if parent and not symbol_row_parents.has(parent):
			symbol_row_parents[parent] = true
			texts.append(effective_text(parent))
	for l in root.find_children("", "Label", true, false):
		if not symbol_row_parents.has((l as Label).get_parent()):
			texts.append((l as Label).text)
	return texts


static func effective_text(control: Control) -> String:
	var out := ""
	for child in control.get_children():
		if child is SymbolGlyph:
			out += (child as SymbolGlyph).symbol
		elif child is Label:
			out += (child as Label).text
	return out


static func find_button(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


static func find_button_by_effective_text(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		var btn := b as Button
		if btn.text == text:
			return btn
		if btn.get_child_count() > 0 and effective_text(btn.get_child(0) as Control) == text:
			return btn
	return null


static func button_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for b in root.find_children("", "Button", true, false):
		texts.append((b as Button).text)
	return texts


static func find_tiles(root: Node) -> Array[AppTile]:
	var tiles: Array[AppTile] = []
	for t in root.find_children("", "AppTile", true, false):
		tiles.append(t as AppTile)
	return tiles
