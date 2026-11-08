class_name BagDrawer
extends Control


const DRAWER_HEIGHT := 420.0
const MANAGEMENT_DRAWER_HEIGHT := 700.0

# PROSE-REVIEW: one-line effect summary on each timed-effect line.
const ACTIVE_EFFECT_BLURBS := { "beALady": "your cultivating and harvests roll their best", "prophetsBreath": "you see an ambush coming and step round it", "navvysDraught": "extra max and current HP for your next fight" }

var _dim: ColorRect
var _card: PanelContainer
var _content: VBoxContainer
var _info_overlay: Control

# View state only (never saved): ore filter, collapsed categories, open tier
# picker and the `?` modal's item.
var _ore_filter := ""
var _collapsed: Dictionary = {}
var _tier_picker := ""
var _picked_target := ""
var _info_key := ""


func _ready() -> void:
	UI.anchor_full_rect(self)
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	_card = PanelContainer.new()
	UI.anchor_bottom_wide(_card)
	_card.offset_top = -DRAWER_HEIGHT
	_card.offset_bottom = 0
	add_child(_card)

	var scroll := UI.scroll_container()
	_card.add_child(scroll)

	_content = UI.vbox(8)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _on_dim_gui_input(event: InputEvent) -> void:
	if TouchInput.is_emulated_mouse(event):
		return
	if event is InputEventScreenTouch and event.pressed:
		# Deferred so the touch's emulated mouse twin still lands on the dim, not the screen underneath.
		Bag.close.call_deferred()
	elif event is InputEventMouseButton and event.pressed:
		Bag.close()


func _refresh() -> void:
	if is_queued_for_deletion():
		return
	var open: bool = GameState.state["bagDrawerOpen"]
	visible = open
	if not open:
		_tier_picker = ""
		_picked_target = ""
		_info_key = ""
		return

	for child in _content.get_children():
		child.queue_free()
	if _info_overlay != null:
		_info_overlay.queue_free()
		_info_overlay = null
	MapCardStyle.style_panel(_card, 18, 0.16)
	_build()


func _build() -> void:
	var player: Dictionary = GameState.state["player"]
	var management: bool = Bag.is_management_mode()

	_card.offset_top = -(MANAGEMENT_DRAWER_HEIGHT if management else DRAWER_HEIGHT)

	_content.add_child(UI.heading("Bag"))
	_content.add_child(_build_ore_row())

	var projection: Dictionary = Bag.projection(_ore_filter, management)
	if _ore_filter != "" and not projection["filters"].has(_ore_filter):
		_ore_filter = ""
		projection = Bag.projection(_ore_filter, management)
	_content.add_child(_build_filter_chips(projection["filters"]))
	if projection["categories"].is_empty():
		_content.add_child(UI.muted_label(_empty_text()))
	for category in projection["categories"]:
		_add_category(category)

	_add_active_effect_lines(player)
	_content.add_child(UI.heading("Equipped", 14))
	_content.add_child(_build_dial_summary_label(player))

	_content.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Bag.close())]))
	if _info_key != "":
		_build_info_overlay()


# PROSE-REVIEW: empty-Bag line.
func _empty_text() -> String:
	return "Nothing held." if _ore_filter.is_empty() else "Nothing held for that ore."


func _build_ore_row() -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 12)
	for ore_type in GameData.ORE_TYPES.keys():
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var qty: int = Stash.player_ore_qty(ore_type)
		var split: String = _pool_split(int(GameState.state["player"]["orichalchum"].get(ore_type, 0)), Stash.stashed_ore_qty(ore_type))
		flow.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s: %d%s" % [ore["name"], qty, split]]))
	return flow


# All plus only the ores that have held items.
func _build_filter_chips(ores: Array) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	var options: Array = [""]
	options.append_array(ores)
	for ore in options:
		var ore_type: String = ore
		var title := "All" if ore_type.is_empty() else str(GameData.ORE_TYPES[ore_type]["name"]).get_slice(" ", 0)
		var chip := MapCardStyle.text_button(title, _set_ore_filter.bind(ore_type), ore_type == _ore_filter)
		chip.accessibility_name = "%s filter" % title
		flow.add_child(chip)
	return flow


func _set_ore_filter(ore_type: String) -> void:
	_ore_filter = ore_type
	_tier_picker = ""
	_picked_target = ""
	_refresh()


func _add_category(category: Dictionary) -> void:
	var ore: String = category["ore"]
	var rows: Array = category["rows"]
	var section := UI.collapsible_section("%s (%d)" % [category["name"], rows.size()], not _collapsed.get(ore, false), func(open: bool): _collapsed[ore] = not open)
	_content.add_child(section["panel"])
	for row in rows:
		section["content"].add_child(_build_row(row))
		if _tier_picker == row["inventoryKey"] and row["usable"]:
			section["content"].add_child(_build_target_picker(row) if row["targeted"] and _picked_target == "" else _build_tier_picker(row))


func _build_row(row: Dictionary) -> Control:
	var line := UI.hbox(8)
	var left := UI.symbol_row([ItemIcons.part(row["key"]), row["name"]])
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(left)
	var help := MapCardStyle.text_button("?", _open_info.bind(row["key"]))
	help.accessibility_name = "About %s" % row["name"]
	line.add_child(help)

	var right := UI.vbox(2)
	right.add_child(UI.label("×%d" % row["total"]))
	if int(row["stash"]) > 0:
		right.add_child(UI.muted_label(_in_stash_text(int(row["stash"]))))
	line.add_child(right)
	if row["usable"]:
		line.add_child(MapCardStyle.text_button("Use", _on_use_pressed.bind(row)))
	return line


# PROSE-REVIEW: small per-row stash line.
func _in_stash_text(stashed: int) -> String:
	return "%d in stash" % stashed


func _on_use_pressed(row: Dictionary) -> void:
	_picked_target = ""
	if row["targeted"] or row["tiers"].size() > 1:
		_tier_picker = "" if _tier_picker == row["inventoryKey"] else row["inventoryKey"]
		_refresh()
		return
	Bag.use(row["key"])


# One button per valid target for a target item.
func _build_target_picker(row: Dictionary) -> Control:
	var box := UI.vbox(4)
	for target in Bag.targets(row["key"]):
		var target_id: String = target["id"]
		box.add_child(MapCardStyle.text_button(target["label"], _on_target_picked.bind(row, target_id)))
	return box


# A boost on a target asks for a tier when several are held; otherwise it applies.
func _on_target_picked(row: Dictionary, target_id: String) -> void:
	if row["tiers"].size() > 1 and Cultivating.boost_items().has(row["key"]):
		_picked_target = target_id
		_refresh()
		return
	Bag.use_on(row["key"], target_id)


# PROSE-REVIEW: tier picker button text.
func _build_tier_picker(row: Dictionary) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	for tier in row["tiers"]:
		var qty: int = Stash.player_item_tier_qty(row["inventoryKey"], int(tier))
		var callback: Callable = Bag.use_on.bind(row["key"], _picked_target, int(tier)) if row["targeted"] else Bag.use.bind(row["key"], int(tier))
		flow.add_child(MapCardStyle.text_button("Tier %d (%d)" % [tier, qty], callback))
	return flow


func _open_info(recipe_key: String) -> void:
	_info_key = recipe_key
	_refresh()


func _close_info() -> void:
	_info_key = ""
	_refresh()


func _build_info_overlay() -> void:
	var recipe: Dictionary = GameData.RECIPES.get(_info_key, {})
	_info_overlay = Control.new()
	UI.anchor_full_rect(_info_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.4)
	UI.anchor_full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
			_close_info()
	)
	_info_overlay.add_child(dim)
	var centre := CenterContainer.new()
	UI.anchor_full_rect(centre)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_overlay.add_child(centre)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	MapCardStyle.style_panel(panel, 18, 0.16)
	centre.add_child(panel)
	var box := UI.vbox(8)
	panel.add_child(box)
	box.add_child(UI.symbol_row([ItemIcons.part(_info_key), str(recipe.get("name", _info_key))]))
	var effect := UI.label(str(recipe.get("effectText", "")))
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(effect)
	var description := UI.muted_label(str(recipe.get("description", "")))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	box.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", _close_info)]))
	add_child(_info_overlay)


# Timed effects still running and the healing-salve heal-over-time.
func _add_active_effect_lines(player: Dictionary) -> void:
	if player["healingSalveDaysLeft"] > 0:
		_content.add_child(UI.symbol_row([ItemIcons.part("healingSalve"), "Healing Salve active — %d HP/day, %d day(s) left" % [player["healingSalveDailyAmount"], player["healingSalveDaysLeft"]]], { "muted": true }))
	for effect in ActiveEffects.effects():
		var item: String = effect["item"]
		if not GameData.RECIPES.has(item) or ActiveEffects.blocks_left(effect) <= 0:
			continue
		_content.add_child(UI.symbol_row([ItemIcons.part(item), "%s active — %s, %d block(s) left" % [GameData.RECIPES[item]["name"], ACTIVE_EFFECT_BLURBS.get(item, ""), ActiveEffects.blocks_left(effect)]], { "muted": true }))


# PROSE-REVIEW: " (Shared a / Stash b)" suffix, shown only when something is stashed.
func _pool_split(shared: int, stashed: int) -> String:
	return " (Shared %d / Stash %d)" % [shared, stashed] if stashed > 0 else ""


func _build_dial_summary_label(player: Dictionary) -> Control:
	var dial: Variant = player["dial"]
	if dial == null:
		return UI.muted_label("Dial: none")
	var movement: Variant = dial["movement"]
	if movement == null:
		return UI.label("Dial: Lv%d — no Movement seated (inert)" % dial["level"])
	var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
	return UI.symbol_row(["Dial: Lv%d — " % dial["level"], { "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, " %s, charge %d/%d" % [m["name"], int(dial["currentCharge"]), dial["maxCharge"]]])
