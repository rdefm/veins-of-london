class_name TitleScreen
extends Control
const PICKER_PREVIEW_SIZE := Vector2(160, 240)

var _slot_list: VBoxContainer
var _menu: VBoxContainer
# Sprite picker overlay: shown by New Game / Debug Start before either
# starts; `_on_picked` is the flow Select continues with.
var _picker: VBoxContainer
var _picker_preview: TextureRect
var _picker_prev: Button
var _picker_next: Button
var _picker_index: int = 0
var _on_picked: Callable

func _ready() -> void:
	UI.anchor_full_rect(self)
	_build()


func _build() -> void:
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.anchor_center(layout)
	add_child(layout)
	_menu = layout
	_build_picker()

	var title := Label.new()
	title.text = "VEIN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var menu_buttons: Array[Button] = [
		MapCardStyle.chip_button("New Game", _on_new_game_pressed),
		MapCardStyle.chip_button("Load Game", _on_load_game_pressed, not _any_slot_saved()),
		MapCardStyle.chip_button("Debug Start", _on_debug_start_pressed),
	]
	_fit_to_widest_label(menu_buttons)
	for b in menu_buttons:
		layout.add_child(b)

	_slot_list = VBoxContainer.new()
	_slot_list.visible = false
	layout.add_child(_slot_list)
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		_slot_list.add_child(_build_slot_row(slot))

# One shared width that fits the widest full label inside the button's own
# (chip) stylebox, so no label ellipsises and the column reads as one block.
static func _fit_to_widest_label(buttons: Array[Button]) -> void:
	var width := 0.0
	for b in buttons:
		var font: Font = b.get_theme_font("font")
		var text_w: float = font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
		width = maxf(width, ceilf(text_w + b.get_theme_stylebox("normal").get_minimum_size().x))
	for b in buttons:
		b.clip_text = false
		b.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		b.custom_minimum_size.x = width

func _any_slot_saved() -> bool:
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		if SaveManager.slot_exists(slot):
			return true
	return false

func _build_slot_row(slot: int) -> Control:
	var summary := SaveManager.slot_summary(slot)
	var filled: bool = not summary.is_empty()

	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Slot %d" % slot, 14))
	if filled:
		c["content"].add_child(UI.muted_label("%s · £%d" % [Calendar.format_day(int(summary["day"])),summary["cash"]]))
		c["content"].add_child(MapCardStyle.footer([MapCardStyle.text_button("Load", _on_load_slot_pressed.bind(slot))]))
	else:
		c["content"].add_child(UI.muted_label("Empty"))

	return c["panel"]

func _on_load_game_pressed() -> void:
	_slot_list.visible = true
func _on_load_slot_pressed(slot: int) -> void:
	SaveManager.load_from_slot(slot)
	Nav.go_to(GameState.state["currentScreen"])

func _on_new_game_pressed() -> void:
	_open_picker(_start_new_game)

func _on_debug_start_pressed() -> void:
	_open_picker(_start_debug)

func _start_new_game(model: String) -> void:
	GameState.reset()
	PlayerModel.set_model(model)
	Factions.seed_day_one_veins()
	Events.start_event("intro")

func _start_debug(model: String) -> void:
	DebugStart.apply(model)


func _build_picker() -> void:
	_picker = VBoxContainer.new()
	_picker.alignment = BoxContainer.ALIGNMENT_CENTER
	_picker.visible = false
	UI.anchor_center(_picker)
	add_child(_picker)

	_picker_preview = TextureRect.new()
	_picker_preview.custom_minimum_size = PICKER_PREVIEW_SIZE
	_picker_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picker_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_picker_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_picker.add_child(_picker_preview)

	var arrows := HBoxContainer.new()
	arrows.alignment = BoxContainer.ALIGNMENT_CENTER
	_picker_prev = _arrow_button(Icons.draw_arrow_left, -1)
	_picker_next = _arrow_button(Icons.draw_arrow_right, 1)
	arrows.add_child(_picker_prev)
	arrows.add_child(_picker_next)
	_picker.add_child(arrows)

	_picker.add_child(MapCardStyle.chip_button("Select", _on_picker_select_pressed))
	_picker.add_child(MapCardStyle.chip_button("Back", _close_picker))

# With no discovered variants there's nothing to pick: the flow starts on
# new_game_state()'s default model.
# Drawn arrow on a round chip: the theme font has no ◀/▶ glyphs.
func _arrow_button(draw_arrow: Callable, step: int) -> Button:
	var b := MapCardStyle.style_chip(UI.icon_button(draw_arrow, _cycle_picker.bind(step), MapCardStyle.ink()))
	for state in ["normal", "hover", "pressed", "disabled"]:
		(b.get_theme_stylebox(state) as StyleBoxFlat).set_corner_radius_all(int(UI.ICON_BUTTON_SIZE / 2))
	return b


func _open_picker(on_picked: Callable) -> void:
	if GameData.TERRITORIAL_VARIANTS.is_empty():
		on_picked.call("")
		return
	_on_picked = on_picked
	_picker_index = 0
	_show_picker_variant()
	_menu.visible = false
	_picker.visible = true

func _close_picker() -> void:
	_picker.visible = false
	_menu.visible = true

func _cycle_picker(step: int) -> void:
	_picker_index = posmod(_picker_index + step, GameData.TERRITORIAL_VARIANTS.size())
	_show_picker_variant()

func picker_variant() -> String:
	return GameData.TERRITORIAL_VARIANTS[_picker_index]

func _show_picker_variant() -> void:
	var idle: Dictionary = GameData.territorial_variant_template(picker_variant()).get("idle", {})
	var images: Array = idle.get("images", [])
	_picker_preview.texture = load(images[0]) if not images.is_empty() else null

func _on_picker_select_pressed() -> void:
	_on_picked.call(picker_variant())
