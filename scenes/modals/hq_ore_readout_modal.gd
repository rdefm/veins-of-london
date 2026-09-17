# Ore-store slip (docs/ui-vision.md §5 stamped/red-ink annotation for the
# raid-risk line) plus the personal-stash move controls.
class_name HqOreReadoutModal
extends RefCounted


const _SLIP_FILL := Color(0.976471, 0.960784, 0.882353, 1)
const _SLIP_INK := Color(0.219608, 0.219608, 0.239216, 1)
const _STAMP_ROTATION_DEGREES := -3.5


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	var player: Dictionary = GameState.state["player"]

	var slip := UI.card()
	slip["panel"].add_theme_stylebox_override("panel", UI.bordered_panel_style(_SLIP_FILL, _SLIP_INK, 2, 16, 14))
	var slip_content: VBoxContainer = slip["content"]

	slip_content.add_child(UI.heading("Ore store", 14))
	var rule := _SlipRule.new()
	rule.custom_minimum_size = Vector2(0, 10)
	slip_content.add_child(rule)

	var any_ore := false
	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = player["orichalchum"].get(ore_type, 0)
		if qty <= 0:
			continue
		any_ore = true
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		slip_content.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s — %d" % [ore["name"], qty]]))
	if not any_ore:
		slip_content.add_child(UI.muted_label("None in stock."))

	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
	slip_content.add_child(_raid_stamp(raid_pct))
	slip_content.add_child(UI.muted_label("Ore kept at the flat is what a raid takes — carry less, lose less."))

	container.add_child(slip["panel"])
	container.add_child(_personal_stash_section())
	container.add_child(UI.button("Close", func(): Modal.close()))


static func _personal_stash_section() -> Control:
	var card := UI.card()
	var content: VBoxContainer = card["content"]
	content.add_child(UI.heading("Personal stash", 14))
	content.add_child(UI.muted_label("Stashed stock is off-limits to contracts and staff — and to a raid."))

	var player: Dictionary = GameState.state["player"]
	var any_ore_row := false
	for ore_type in GameData.ORE_TYPES.keys():
		var shared: int = int(player["orichalchum"].get(ore_type, 0))
		var stashed: int = Stash.stashed_ore_qty(ore_type)
		if shared <= 0 and stashed <= 0:
			continue
		any_ore_row = true
		content.add_child(_stash_ore_row(ore_type, GameData.ORE_TYPES[ore_type], shared, stashed))
	if not any_ore_row:
		content.add_child(UI.muted_label("No ore to stash."))

	content.add_child(UI.heading("Crafted items", 13))
	var any_item_row := false
	for recipe_key in GameData.RECIPES.keys():
		var shared_qty: int = Crafting.inventory_qty(recipe_key)
		var stashed_qty: int = Stash.stashed_item_qty(recipe_key)
		if shared_qty <= 0 and stashed_qty <= 0:
			continue
		any_item_row = true
		content.add_child(_stash_item_row(recipe_key, GameData.RECIPES[recipe_key], shared_qty, stashed_qty))
	if not any_item_row:
		content.add_child(UI.muted_label("No crafted items to stash."))

	return card["panel"]


static func _stash_ore_row(ore_type: String, ore: Dictionary, shared: int, stashed: int) -> Control:
	var row := UI.vbox(4)
	row.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s — shared %d / stashed %d" % [ore["name"], shared, stashed]]))

	var stepper_max: int = maxi(shared, stashed)
	var qty: int = clampi(Stash.get_ore_move_qty(ore_type), 1, maxi(stepper_max, 1))
	var stepper := UI.hbox()
	stepper.add_child(UI.label("Qty:"))
	stepper.add_child(UI.button("-", func(): Stash.adjust_ore_move_qty(ore_type, -1, stepper_max)))
	stepper.add_child(UI.label(str(qty)))
	stepper.add_child(UI.button("+", func(): Stash.adjust_ore_move_qty(ore_type, 1, stepper_max)))
	row.add_child(stepper)

	var buttons := UI.hflow()
	var to_stash := UI.button("→ Stash", func(): Stash.move_ore_to_stash(ore_type, Stash.get_ore_move_qty(ore_type)))
	to_stash.disabled = qty > shared
	buttons.add_child(to_stash)
	var to_shared := UI.button("← Shared", func(): Stash.move_ore_to_shared(ore_type, Stash.get_ore_move_qty(ore_type)))
	to_shared.disabled = qty > stashed
	buttons.add_child(to_shared)
	row.add_child(buttons)

	return row


static func _stash_item_row(recipe_key: String, recipe: Dictionary, shared: int, stashed: int) -> Control:
	var row := UI.vbox(4)
	row.add_child(UI.symbol_row([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — shared %d / stashed %d" % [recipe["name"], shared, stashed]]))

	var stepper_max: int = maxi(shared, stashed)
	var qty: int = clampi(Stash.get_item_move_qty(recipe_key), 1, maxi(stepper_max, 1))
	var stepper := UI.hbox()
	stepper.add_child(UI.label("Qty:"))
	stepper.add_child(UI.button("-", func(): Stash.adjust_item_move_qty(recipe_key, -1, stepper_max)))
	stepper.add_child(UI.label(str(qty)))
	stepper.add_child(UI.button("+", func(): Stash.adjust_item_move_qty(recipe_key, 1, stepper_max)))
	row.add_child(stepper)

	var buttons := UI.hflow()
	var to_stash := UI.button("→ Stash", func(): Stash.move_item_to_stash(recipe_key, Stash.get_item_move_qty(recipe_key)))
	to_stash.disabled = qty > shared
	buttons.add_child(to_stash)
	var to_shared := UI.button("← Shared", func(): Stash.move_item_to_shared(recipe_key, Stash.get_item_move_qty(recipe_key)))
	to_shared.disabled = qty > stashed
	buttons.add_child(to_shared)
	row.add_child(buttons)

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
	var ink_color: Color = _SLIP_INK

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
