# Ore-store slip (docs/ui-vision.md §5 stamped/red-ink annotation for the
# raid-risk line) plus the personal-stash move controls, on the vein-popover
# card family (MapCardStyle).
class_name HqOreReadoutModal
extends RefCounted


const _STAMP_ROTATION_DEGREES := -3.5


# Off the Map tab: always the light card family (MapCardStyle).
static func build(container: VBoxContainer, _data: Dictionary) -> void:
	MapPalette.build_light(func(): _build(container))


static func _build(container: VBoxContainer) -> void:
	var player: Dictionary = GameState.state["player"]

	var slip := MapCardStyle.card()
	var slip_content: VBoxContainer = slip["content"]

	slip_content.add_child(MapCardStyle.label("Ore store", 15, MapCardStyle.ink()))
	var rule := _SlipRule.new()
	rule.ink_color = MapCardStyle.ink()
	rule.custom_minimum_size = Vector2(0, 10)
	slip_content.add_child(rule)

	var any_ore := false
	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = player["orichalchum"].get(ore_type, 0)
		if qty <= 0:
			continue
		any_ore = true
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		slip_content.add_child(_ink_row(ore["symbol"], SymbolGlyph.ore_fallback(ore_type), "%s — %d" % [ore["name"], qty]))
	if not any_ore:
		slip_content.add_child(MapCardStyle.section_label("None in stock."))

	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
	slip_content.add_child(_raid_stamp(raid_pct))
	slip_content.add_child(MapCardStyle.section_label("Ore kept at the flat is what a raid takes — carry less, lose less."))

	container.add_child(slip["panel"])
	container.add_child(_personal_stash_section())
	var close := MapCardStyle.text_button("Close", func(): Modal.close())
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	container.add_child(close)


static func _ink_row(symbol: String, fallback: Variant, text: String) -> Control:
	return MapCardStyle.tint_symbols(UI.symbol_row([{ "symbol": symbol, "fallback": fallback }, text]), MapCardStyle.ink())


static func _personal_stash_section() -> Control:
	var card := MapCardStyle.card()
	var content: VBoxContainer = card["content"]
	content.add_child(MapCardStyle.label("Personal stash", 15, MapCardStyle.ink()))
	content.add_child(MapCardStyle.section_label("Stashed stock is off-limits to contracts and staff — and to a raid."))

	var player: Dictionary = GameState.state["player"]
	var any_ore_row := false
	for ore_type in GameData.ORE_TYPES.keys():
		var shared: int = int(player["orichalchum"].get(ore_type, 0))
		var stashed: int = Stash.stashed_ore_qty(ore_type)
		if shared <= 0 and stashed <= 0:
			continue
		any_ore_row = true
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		content.add_child(_move_row(
			_ink_row(ore["symbol"], SymbolGlyph.ore_fallback(ore_type), "%s — shared %d / stashed %d" % [ore["name"], shared, stashed]),
			shared, stashed, Stash.get_ore_move_qty(ore_type),
			func(delta: int, limit: int): Stash.adjust_ore_move_qty(ore_type, delta, limit),
			func(): Stash.move_ore_to_stash(ore_type, Stash.get_ore_move_qty(ore_type)),
			func(): Stash.move_ore_to_shared(ore_type, Stash.get_ore_move_qty(ore_type))))
	if not any_ore_row:
		content.add_child(MapCardStyle.section_label("No ore to stash."))

	content.add_child(MapCardStyle.section_label("Crafted items", 13))
	var any_item_row := false
	for recipe_key in GameData.RECIPES.keys():
		var shared_qty: int = Crafting.inventory_qty(recipe_key)
		var stashed_qty: int = Stash.stashed_item_qty(recipe_key)
		if shared_qty <= 0 and stashed_qty <= 0:
			continue
		any_item_row = true
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		content.add_child(_move_row(
			_ink_row(recipe["symbol"], SymbolGlyph.generic_fallback(), "%s — shared %d / stashed %d" % [recipe["name"], shared_qty, stashed_qty]),
			shared_qty, stashed_qty, Stash.get_item_move_qty(recipe_key),
			func(delta: int, limit: int): Stash.adjust_item_move_qty(recipe_key, delta, limit),
			func(): Stash.move_item_to_stash(recipe_key, Stash.get_item_move_qty(recipe_key)),
			func(): Stash.move_item_to_shared(recipe_key, Stash.get_item_move_qty(recipe_key))))
	if not any_item_row:
		content.add_child(MapCardStyle.section_label("No crafted items to stash."))

	return card["panel"]


# One stash row: identity line, a round -/+ qty stepper and quiet
# Stash/Shared moves on one line.
static func _move_row(identity: Control, shared: int, stashed: int, move_qty: int, adjust: Callable, to_stash_fn: Callable, to_shared_fn: Callable) -> Control:
	var row := UI.vbox(4)
	row.add_child(identity)

	var stepper_max: int = maxi(shared, stashed)
	var qty: int = clampi(move_qty, 1, maxi(stepper_max, 1))
	var controls := UI.hflow(6)
	controls.add_child(MapCardStyle.section_label("Qty"))
	controls.add_child(MapCardStyle.round_button("-", func(): adjust.call(-1, stepper_max)))
	var qty_label := MapCardStyle.label(str(qty), 14, MapCardStyle.ink())
	qty_label.custom_minimum_size.x = 20
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_child(qty_label)
	controls.add_child(MapCardStyle.round_button("+", func(): adjust.call(1, stepper_max)))
	controls.add_child(MapCardStyle.text_button("→ Stash", to_stash_fn, qty > shared))
	controls.add_child(MapCardStyle.text_button("← Shared", to_shared_fn, qty > stashed))
	row.add_child(controls)

	return row


static func _raid_stamp(raid_pct: int) -> Control:
	var accent := UI.action_colour()

	var stamp := _SlipStamp.new()
	stamp.ink_color = accent
	stamp.rotation_degrees = _STAMP_ROTATION_DEGREES
	stamp.add_theme_constant_override("margin_left", 10)
	stamp.add_theme_constant_override("margin_top", 6)
	stamp.add_theme_constant_override("margin_right", 10)
	stamp.add_theme_constant_override("margin_bottom", 6)

	var raid_label := UI.label("Raid risk: %d%%" % raid_pct)
	raid_label.add_theme_color_override("font_color", accent)
	stamp.add_child(raid_label)

	return stamp


static func _draw_ink_polyline(target: CanvasItem, points: PackedVector2Array, ink_color: Color) -> void:
	for i in range(points.size() - 1):
		target.draw_line(points[i], points[i + 1], ink_color, 1.5)


class _SlipRule extends Control:
	var ink_color: Color = Color.BLACK

	func _draw() -> void:
		if size.x <= 0:
			return
		var segments := 5
		var jitter_amount := 1.5
		var y: float = size.y * 0.5
		var seg_w: float = size.x / float(segments)
		var points := PackedVector2Array()
		for i in range(segments + 1):
			var jitter: float = 0.0
			if i > 0 and i < segments:
				jitter = jitter_amount if i % 2 == 0 else -jitter_amount
			points.append(Vector2(seg_w * i, y + jitter))
		HqOreReadoutModal._draw_ink_polyline(self, points, ink_color)


class _SlipStamp extends MarginContainer:
	var ink_color: Color = UI.ACTION_COLOUR_FALLBACK

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 0 or h <= 0:
			return
		var points := PackedVector2Array([
			Vector2(2, 2), Vector2(w * 0.5, 0), Vector2(w - 2, 3),
			Vector2(w - 1, h * 0.5), Vector2(w - 3, h - 2),
			Vector2(w * 0.5, h - 1), Vector2(1, h - 3), Vector2(2, h * 0.5),
			Vector2(2, 2),
		])
		HqOreReadoutModal._draw_ink_polyline(self, points, ink_color)
