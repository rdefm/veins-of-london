class_name BagDrawer
extends Control


const DRAWER_HEIGHT := 420.0
const MANAGEMENT_DRAWER_HEIGHT := 700.0

const CONSUMABLE_KEYS := ["timePearl", "enhancementPowder", "rewind", "healingSalve", "blast", "shield", "blackHole", "healingBurst", "prophetsBreath", "beALady", "wormhole"]

const OUT_OF_COMBAT_USE_KEYS := ["healingSalve", "healingBurst"]

# PROSE-REVIEW: one-line effect summary on each timed-effect Use row.
const ACTIVE_EFFECT_BLURBS := { "beALady": "your cultivating and harvests roll their best", "prophetsBreath": "you see an ambush coming and step round it", "navvysDraught": "extra max and current HP for your next fight" }

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
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		Bag.close()


func _refresh() -> void:
	var open: bool = GameState.state["bagDrawerOpen"]
	visible = open
	if not open:
		return

	for child in _content.get_children():
		child.queue_free()
	MapCardStyle.style_panel(_card, 18, 0.16)
	_build()


func _build() -> void:
	var player: Dictionary = GameState.state["player"]
	var management: bool = _is_management_mode()

	_card.offset_top = -(MANAGEMENT_DRAWER_HEIGHT if management else DRAWER_HEIGHT)

	_content.add_child(UI.heading("Bag"))

	_content.add_child(UI.heading("Ore", 14))
	for ore_type in GameData.ORE_TYPES.keys():
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var qty: int = Stash.player_ore_qty(ore_type)
		var split: String = _pool_split(int(player["orichalchum"].get(ore_type, 0)), Stash.stashed_ore_qty(ore_type))
		_content.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s: %d%s" % [ore["name"], qty, split]]))

	_content.add_child(UI.heading("Consumables", 14))
	for recipe_key in CONSUMABLE_KEYS:
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		var qty: int = Stash.player_item_qty(recipe_key)
		_content.add_child(UI.symbol_row([ItemIcons.part(recipe_key), "%s: %d%s" % [recipe["name"], qty, _pool_split(Crafting.inventory_qty(recipe_key), Stash.stashed_item_qty(recipe_key))]]))
		var multi_key: String = Crafting.inventory_key(recipe_key, true)
		var multi_qty: int = Stash.player_item_qty(multi_key)
		if multi_qty > 0:
			_content.add_child(UI.symbol_row([ItemIcons.part(recipe_key), "%s (multi): %d%s" % [recipe["name"], multi_qty, _pool_split(Crafting.inventory_qty(multi_key), Stash.stashed_item_qty(multi_key))]]))
	for recipe_key in GameData.RECIPES.keys():
		if CONSUMABLE_KEYS.has(recipe_key) or not GameData.RECIPES[recipe_key].get("bagWhenHeld", false):
			continue
		var held: int = Stash.player_item_qty(recipe_key)
		if held > 0:
			_content.add_child(UI.symbol_row([ItemIcons.part(recipe_key), "%s: %d%s" % [GameData.RECIPES[recipe_key]["name"], held, _pool_split(Crafting.inventory_qty(recipe_key), Stash.stashed_item_qty(recipe_key))]]))

	if player["healingSalveDaysLeft"] > 0:
		_content.add_child(UI.symbol_row([ItemIcons.part("healingSalve"), "Healing Salve active — %d HP/day, %d day(s) left" % [player["healingSalveDailyAmount"], player["healingSalveDaysLeft"]]], { "muted": true }))

	if management:
		_add_out_of_combat_use_buttons(player)
	else:
		_content.add_child(UI.heading("Equipped", 14))
		_content.add_child(_build_dial_summary_label(player))

	_content.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Bag.close())]))


# PROSE-REVIEW: " (Shared a / Stash b)" suffix, shown only when something is stashed.
func _pool_split(shared: int, stashed: int) -> String:
	return " (Shared %d / Stash %d)" % [shared, stashed] if stashed > 0 else ""


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
	if Stash.player_item_qty("healingSalve") > 0:
		_content.add_child(_symbol_use_button("healingSalve", "Healing Salve (%d) — 2-day heal-over-time" % Stash.player_item_qty("healingSalve"), _on_use_healing_salve))
	if Stash.player_item_qty("healingBurst") > 0:
		_content.add_child(_symbol_use_button("healingBurst", "Healing Burst (%d) — instant heal" % Stash.player_item_qty("healingBurst"), _on_use_healing_burst))
	if Stash.player_item_qty("smellingSalts") > 0:
		for contact_id in Contacts.ko_cooldown_contacts():
			var contact_name: String = Contacts.display_name(contact_id)
			_content.add_child(_symbol_use_button("smellingSalts", "Smelling Salts (%d) — wake %s" % [Stash.player_item_qty("smellingSalts"), contact_name], func(): _on_use_smelling_salts(contact_id)))
	if Stash.player_item_qty("cleanSlate") > 0:
		for faction_id in Grudges.clearable_factions():
			var faction_name: String = GameData.FACTIONS[faction_id]["shortName"]
			_content.add_child(_symbol_use_button("cleanSlate", "Clean Slate (%d) — clear %s grudge" % [Stash.player_item_qty("cleanSlate"), faction_name], func(): _on_use_clean_slate(faction_id)))
	if Stash.player_item_qty(TimeSystem.BORROWED_TIME) > 0:
		_content.add_child(_symbol_use_button(TimeSystem.BORROWED_TIME, "Use Borrowed Time (%d) — an extra block today, paid back tomorrow" % Stash.player_item_qty(TimeSystem.BORROWED_TIME), _on_use_borrowed_time))
	for item in ActiveEffects.usable_items():
		var qty: int = Stash.player_item_qty(item)
		if qty > 0:
			_content.add_child(_symbol_use_button(item, "Use %s (%d) — %s" % [GameData.RECIPES[item]["name"], qty, ACTIVE_EFFECT_BLURBS.get(item, "")], func(): _on_use_active_effect(item)))


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


func _on_use_smelling_salts(contact_id: String) -> void:
	Bag.close()
	Contacts.use_smelling_salts(contact_id)


func _on_use_clean_slate(faction_id: String) -> void:
	Bag.close()
	Grudges.use_clean_slate(faction_id)


func _on_use_borrowed_time() -> void:
	Bag.close()
	TimeSystem.use_borrowed_time()


func _on_use_active_effect(item: String) -> void:
	Bag.close()
	ActiveEffects.use(item)


func _on_use_healing_burst() -> void:
	Bag.close()
	Consumables.use_healing_burst()
