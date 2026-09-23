# Estate-agent floorplan for a home tier (docs/hq-diorama-vision.md §6):
# the tier's plan asset on a paper sheet, geometry from data/floorplans.json.
# Static when built without a callback (Harrow's listings); otherwise each
# selectable slot is a touch target labelled with its current use.
class_name FloorplanView
extends RefCounted

const PAPER_FILL := Color(0.94902, 0.941176, 0.913725, 1)
const PAPER_BORDER := Color(0.721569, 0.705882, 0.658824, 1)
const INK := Color(0.141176, 0.141176, 0.141176, 1)
const SLOT_FILL_ALPHA := 0.12
const SLOT_SELECTED_FILL_ALPHA := 0.26
const SLOT_BORDER := 2
const USE_LABEL_FONT_SIZE := 11


static func has_plan(tier_id: String) -> bool:
	return GameData.FLOORPLANS.has(tier_id)


static func slot_node_name(slot: int) -> String:
	return "FloorplanSlot%d" % slot


static func slot_label(tier_id: String, slot: int) -> String:
	return GameData.FLOORPLANS[tier_id]["slots"][slot]["label"]


# on_slot_pressed receives the slot index; leave it unset for a static plan.
static func build(tier_id: String, on_slot_pressed: Callable = Callable(), selected_slot: int = -1) -> Control:
	var plan: Dictionary = GameData.FLOORPLANS[tier_id]
	var plan_size := Vector2(plan["size"][0], plan["size"][1])

	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", UI.bordered_panel_style(PAPER_FILL, PAPER_BORDER, 0, 8, 8))

	var center := CenterContainer.new()
	paper.add_child(center)

	var canvas := Control.new()
	canvas.custom_minimum_size = plan_size
	center.add_child(canvas)

	var tex := TextureRect.new()
	tex.texture = load(plan["texture"])
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.position = Vector2.ZERO
	tex.size = plan_size
	canvas.add_child(tex)

	if on_slot_pressed.is_valid():
		var slots: Array = plan["slots"]
		for i in slots.size():
			canvas.add_child(_build_slot(slots[i], i, on_slot_pressed, i == selected_slot))

	return paper


static func _build_slot(slot_data: Dictionary, slot: int, on_slot_pressed: Callable, selected: bool) -> Control:
	var rect: Array = slot_data["rect"]
	var accent: Color = UI.action_colour()
	var fill_alpha: float = SLOT_SELECTED_FILL_ALPHA if selected else SLOT_FILL_ALPHA

	var b := Button.new()
	b.name = slot_node_name(slot)
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.position = Vector2(rect[0], rect[1])
	b.size = Vector2(rect[2], rect[3])
	b.custom_minimum_size = b.size
	for state_name in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state_name, UI.command_row_style(accent, fill_alpha, SLOT_BORDER))
	b.pressed.connect(func(): on_slot_pressed.call(slot))

	var room_id: String = Home.get_room_in_slot(slot)
	var use_text: String = GameData.HOME_ROOMS[room_id]["name"].to_upper() if room_id != "" else "EMPTY"
	b.tooltip_text = "Room %s · %s" % [slot_data["label"], use_text]

	var use_label := Label.new()
	use_label.text = use_text
	use_label.add_theme_color_override("font_color", accent)
	use_label.add_theme_font_size_override("font_size", USE_LABEL_FONT_SIZE)
	use_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	use_label.position = Vector2(slot_data["useLabelAt"][0], slot_data["useLabelAt"][1]) - b.position
	b.add_child(use_label)

	return b
