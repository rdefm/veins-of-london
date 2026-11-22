class_name HqDialScreen
extends Control
const NO_DIAL_TEXT := "No Dial. Nothing's offered you the gift yet."
const SEED_LENS_PROMPT := "It needs a first lens. Pick the ore it looks through."
const SEED_ORE_BUTTON_SIZE := 56.0

# Lens ore picked on the unseeded screen; UI-local, passed to Dial.attempt_seed().
var _seed_ore := ""
# The seeded Dial menu persists across state changes (it refreshes itself), so its zoom survives.
var _menu: DialMenu

func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if is_queued_for_deletion():
		return
	var player: Dictionary = GameState.state["player"]
	var opened: Variant = PhoneNav.dial_owner()
	var owner_id: String = "" if opened == null else str(opened)
	var dial: Variant = Dial.dial_of(owner_id)
	if dial != null and _menu != null and is_instance_valid(_menu) and _menu.owner_id == owner_id:
		return
	for child in get_children():
		child.queue_free()
	_menu = null
	if dial == null:
		_build_unseeded_screen(player)
	else:
		# Profile-opened: Back returns to Profile, and no Craft mid-Preparation.
		_menu = DialMenu.new()
		_menu.name = "DialMenu"
		_menu.owner_id = owner_id
		if opened != null:
			_menu.on_back = PhoneNav.close_dial
			_menu.craft_enabled = not CombatPrep.is_editing_loadout()
		add_child(_menu)

func _build_unseeded_screen(player: Dictionary) -> void:
	var sc := UI.scroll_container()
	add_child(sc)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", int(UI.top_bar_clearance()) + 16)
	margin.add_theme_constant_override("margin_bottom", int(UI.nav_bar_clearance()) + 16)
	sc.add_child(margin)

	var content := UI.vbox(10)
	margin.add_child(content)

	content.add_child(UI.back_button("hq"))
	content.add_child(UI.heading("Dial"))
	_build_unseeded(content, player)

func _build_unseeded(content: VBoxContainer, player: Dictionary) -> void:
	if GameState.state["flags"].get("dialGiftGranted", false):
		content.add_child(UI.label("You've been given something rare. It wants a name."))
		content.add_child(UI.muted_label(UI.format_cost_label(GameData.DIAL_SEED_COST, player["orichalchum"])))
		content.add_child(UI.label(SEED_LENS_PROMPT))
		content.add_child(_build_seed_ore_row())
		var seed_btn := MapCardStyle.text_button("Seed", _on_seed_pressed, _seed_ore == "")
		seed_btn.name = "SeedButton"
		content.add_child(seed_btn)
	else:
		content.add_child(UI.muted_label(NO_DIAL_TEXT))

func _on_seed_pressed() -> void:
	var result := Dial.attempt_seed(_seed_ore)
	if not result["ok"]:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
	elif result["success"]:
		Notify.push("Dial seeded.", Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Seeding failed — calc spent, no Dial gained.", Notify.CATEGORY_DANGER)

# Five ore-glyph buttons (SeedOre_<ore>); the picked one is full strength, the rest dimmed.
func _build_seed_ore_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for ore in GameData.ORE_TYPES.keys():
		var captured_ore: String = ore
		var b := Button.new()
		b.name = "SeedOre_%s" % ore
		b.tooltip_text = str(GameData.ORE_TYPES[ore].get("name", ore))
		b.custom_minimum_size = Vector2(SEED_ORE_BUTTON_SIZE, SEED_ORE_BUTTON_SIZE)
		b.toggle_mode = true
		b.button_pressed = ore == _seed_ore
		b.modulate.a = 1.0 if ore == _seed_ore or _seed_ore == "" else 0.55
		b.pressed.connect(func(): _on_seed_ore_pressed(captured_ore))
		var glyph := SymbolGlyph.new()
		# Empty symbol forces OreGlyphs.draw(), the same silhouettes as MapCanvas.
		glyph.symbol = ""
		glyph.draw_fallback = SymbolGlyph.ore_fallback(ore)
		glyph.color = MapPalette.ore_colour(ore)
		glyph.glyph_radius = SEED_ORE_BUTTON_SIZE * 0.3
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(glyph)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_child(b)
	return row

func _on_seed_ore_pressed(ore: String) -> void:
	_seed_ore = ore
	_refresh()
