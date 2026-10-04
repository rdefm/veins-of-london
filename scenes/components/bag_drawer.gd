class_name BagDrawer
extends Control


const DRAWER_HEIGHT := 420.0
const MANAGEMENT_DRAWER_HEIGHT := 700.0

const CONSUMABLE_KEYS := ["timePearl", "enhancementPowder", "rewind", "healingSalve", "blast", "shield", "blackHole", "healingBurst", "prophetsBreath", "wormhole"]

const OUT_OF_COMBAT_USE_KEYS := ["healingSalve", "healingBurst"]

var _dim: ColorRect
var _card: PanelContainer
var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	# Off the Map tab: the light card family (MapCardStyle).
	_card = PanelContainer.new()
	MapPalette.build_light(func(): MapCardStyle.style_panel(_card, 18, 0.16))
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
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		Bag.close()


func _refresh() -> void:
	var open: bool = GameState.state["bagDrawerOpen"]
	visible = open
	if not open:
		return

	for child in _content.get_children():
		child.queue_free()
	MapPalette.build_light(_build)


func _build() -> void:
	var player: Dictionary = GameState.state["player"]
	var management: bool = _is_management_mode()

	_card.offset_top = -(MANAGEMENT_DRAWER_HEIGHT if management else DRAWER_HEIGHT)

	_content.add_child(UI.heading("Bag"))

	_content.add_child(UI.heading("Ore", 14))
	for ore_type in GameData.ORE_TYPES.keys():
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var qty: int = player["orichalchum"].get(ore_type, 0)
		_content.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s: %d" % [ore["name"], qty]]))

	_content.add_child(UI.heading("Consumables", 14))
	for recipe_key in CONSUMABLE_KEYS:
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		var qty: int = Crafting.inventory_qty(recipe_key)
		_content.add_child(UI.symbol_row([ItemIcons.part(recipe_key), "%s: %d" % [recipe["name"], qty]]))

	if player["healingSalveDaysLeft"] > 0:
		_content.add_child(UI.symbol_row([ItemIcons.part("healingSalve"), "Healing Salve active — %d HP/day, %d day(s) left" % [player["healingSalveDailyAmount"], player["healingSalveDaysLeft"]]], { "muted": true }))

	if management:
		_add_out_of_combat_use_buttons(player)
	else:
		_content.add_child(UI.heading("Equipped", 14))
		_content.add_child(_build_dial_summary_label(player))

	_content.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Bag.close())]))


func _is_management_mode() -> bool:
	if GameState.state["combat"]["active"]:
		return false
	var event_state: Variant = GameState.state.get("event")
	if event_state != null:
		var card: Dictionary = Events.current_card()
		var hooks: Array = card.get("itemHooks", [])
		if not hooks.is_empty():
			return false
	return true


func _add_out_of_combat_use_buttons(player: Dictionary) -> void:
	if Crafting.inventory_qty("healingSalve") > 0:
		_content.add_child(_symbol_use_button("healingSalve", "Healing Salve (%d) — 2-day heal-over-time" % Crafting.inventory_qty("healingSalve"), _on_use_healing_salve))
	if Crafting.inventory_qty("healingBurst") > 0:
		_content.add_child(_symbol_use_button("healingBurst", "Healing Burst (%d) — instant heal" % Crafting.inventory_qty("healingBurst"), _on_use_healing_burst))


func _symbol_use_button(recipe_key: String, rest_text: String, callback: Callable, disabled: bool = false) -> Button:
	return MapCardStyle.symbol_option_row([ItemIcons.part(recipe_key), rest_text], callback, disabled)


func _on_use_healing_salve() -> void:
	Bag.close()
	Consumables.use_healing_salve()


func _build_dial_summary_label(player: Dictionary) -> Control:
	var dial: Variant = player["dial"]
	if dial == null:
		return UI.muted_label("Dial: none")
	var movement: Variant = dial["movement"]
	if movement == null:
		return UI.label("Dial: Lv%d — no Movement seated (inert)" % dial["level"])
	var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
	return UI.symbol_row(["Dial: Lv%d — " % dial["level"], { "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, " %s, charge %d/%d" % [m["name"], int(dial["currentCharge"]), dial["maxCharge"]]])


func _on_use_healing_burst() -> void:
	Bag.close()
	Consumables.use_healing_burst()
