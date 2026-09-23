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

	var player: Dictionary = GameState.state["player"]
	var combat: Dictionary = GameState.state["combat"]
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
		_content.add_child(UI.symbol_row([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s: %d" % [recipe["name"], qty]]))

	if player["healingSalveDaysLeft"] > 0:
		_content.add_child(UI.symbol_row([{ "symbol": GameData.RECIPES["healingSalve"]["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "Healing Salve active — %d HP/day, %d day(s) left" % [player["healingSalveDailyAmount"], player["healingSalveDaysLeft"]]], { "muted": true }))

	if management:
		_add_out_of_combat_use_buttons(player)
		_build_weapon_management(player)
	else:
		_content.add_child(UI.heading("Equipped", 14))
		_content.add_child(_build_equipped_weapon_label(player))
		_content.add_child(_build_dial_summary_label(player))

	if combat["active"]:
		_content.add_child(UI.heading("Use an item", 14))
		_add_combat_use_buttons(player, combat)

	_content.add_child(UI.button("Close", func(): Bag.close()))


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


func _symbol_use_button(recipe_key: String, rest_text: String, callback: Callable) -> Button:
	var symbol: String = GameData.RECIPES[recipe_key]["symbol"]
	return UI.symbol_button([{ "symbol": symbol, "fallback": SymbolGlyph.generic_fallback() }, rest_text], callback)


func _on_use_healing_salve() -> void:
	Bag.close()
	Consumables.use_healing_salve()


func _build_weapon_management(player: Dictionary) -> void:
	_content.add_child(UI.heading("Weapon", 14))
	if player["items"].is_empty():
		_content.add_child(UI.muted_label("No weapons yet."))
		return

	for item in player["items"]:
		var def: Dictionary = GameData.ITEMS.get(item["type"], {})
		if def.is_empty():
			continue
		var is_equipped: bool = player["equipment"]["weapon"] == item["id"]
		var item_id: String = item["id"]
		var c := UI.card()
		c["content"].add_child(UI.label("%s%s" % [def["name"], " (equipped)" if is_equipped else ""]))
		c["content"].add_child(UI.muted_label(def["description"]))
		c["content"].add_child(UI.muted_label("+%d–%d attack" % [def["attackBonus"]["min"], def["attackBonus"]["max"]]))
		if is_equipped:
			c["content"].add_child(UI.button("Unequip", func(): Equipment.unequip_weapon()))
		else:
			c["content"].add_child(UI.button("Equip", func(): Equipment.equip_weapon(item_id)))
		_content.add_child(c["panel"])


func _build_equipped_weapon_label(player: Dictionary) -> Control:
	var weapon_id = player["equipment"]["weapon"]
	for item in player["items"]:
		if item["id"] == weapon_id:
			var def: Dictionary = GameData.ITEMS.get(item["type"], {})
			return UI.label("%s %s (equipped)" % [def.get("symbol", ""), def.get("name", "")])
	return UI.muted_label("Weapon: none equipped")


func _build_dial_summary_label(player: Dictionary) -> Control:
	var dial: Variant = player["dial"]
	if dial == null:
		return UI.muted_label("Dial: none")
	var movement: Variant = dial["movement"]
	if movement == null:
		return UI.label("Dial: Lv%d — no Movement seated (inert)" % dial["level"])
	var m: Dictionary = GameData.DIAL_MOVEMENTS[movement["archetype"]]
	return UI.symbol_row(["Dial: Lv%d — " % dial["level"], { "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, " %s, charge %d/%d" % [m["name"], int(dial["currentCharge"]), dial["maxCharge"]]])


func _add_combat_use_buttons(player: Dictionary, combat: Dictionary) -> void:
	if Crafting.inventory_qty("timePearl") > 0:
		_content.add_child(_combat_use_button("timePearl", "Time Pearl (%d) — freeze enemy" % Crafting.inventory_qty("timePearl"), _on_use_time_pearl))

	if Crafting.inventory_qty("enhancementPowder") > 0:
		_content.add_child(_combat_use_button("enhancementPowder", "Enhancement Powder (%d) — extra attacks" % Crafting.inventory_qty("enhancementPowder"), _on_use_enhancement_powder))

	if Crafting.inventory_qty("blast") > 0:
		_content.add_child(_combat_use_button("blast", "Blast (%d) — damage, flee boost, chance to disarm" % Crafting.inventory_qty("blast"), _on_use_blast))

	if Crafting.inventory_qty("shield") > 0:
		var shield_button := _combat_use_button("shield", "Shield (%d) — absorb incoming damage" % Crafting.inventory_qty("shield"), _on_use_shield)
		shield_button.disabled = shield_button.disabled or player["shieldPool"] > 0
		_content.add_child(shield_button)

	if Crafting.inventory_qty("blackHole") > 0:
		_content.add_child(_combat_use_button("blackHole", "Black Hole (%d) — damage and freeze" % Crafting.inventory_qty("blackHole"), _on_use_black_hole))

	if Crafting.inventory_qty("healingBurst") > 0:
		var burst_target: String = "instant heal"
		var ally_index: int = Combat.selected_ally_index(combat)
		if ally_index >= 0:
			burst_target = "heal %s" % combat["allies"][ally_index]["name"]
		_content.add_child(_combat_use_button("healingBurst", "Healing Burst (%d) — %s" % [Crafting.inventory_qty("healingBurst"), burst_target], _on_use_healing_burst))

	if Crafting.inventory_qty("prophetsBreath") > 0:
		_content.add_child(_combat_use_button("prophetsBreath", "Prophet's Breath (%d) — evade buff" % Crafting.inventory_qty("prophetsBreath"), _on_use_prophets_breath))

	if Crafting.inventory_qty("wormhole") > 0:
		_content.add_child(_combat_use_button("wormhole", "Wormhole (%d) — guaranteed flee" % Crafting.inventory_qty("wormhole"), _on_use_wormhole))

	var snap_count: int = combat["snapshots"].size()
	if Crafting.inventory_qty("rewind") > 0:
		var rewind_label := "(%d turn(s) back · +50%% evade x2 turns)" % snap_count if snap_count > 0 else "(nothing to undo yet)"
		var rewind_button := _symbol_use_button("rewind", "Rewind (%d) — %s" % [Crafting.inventory_qty("rewind"), rewind_label], _on_use_rewind)
		rewind_button.disabled = snap_count == 0
		_content.add_child(rewind_button)



# Disabled, with the reason appended, when the current combat.selection
# can't take this item (Combat.selection_block_reason(), R§3.7).
func _combat_use_button(recipe_key: String, rest_text: String, callback: Callable) -> Button:
	var reason: String = Combat.selection_block_reason(recipe_key)
	var text: String = rest_text if reason.is_empty() else "%s · %s" % [rest_text, reason]
	var button := _symbol_use_button(recipe_key, text, callback)
	button.disabled = not reason.is_empty()
	return button


func _play_result_beats(result: Dictionary) -> void:
	var beats: Array = result.get("beats", [])
	if not beats.is_empty():
		EventBus.combat_beats_played.emit(beats)


func _on_use_time_pearl() -> void:
	Bag.close()
	_play_result_beats(Combat.use_time_pearl())


func _on_use_enhancement_powder() -> void:
	Bag.close()
	_play_result_beats(Combat.use_enhancement_powder())


func _on_use_blast() -> void:
	Bag.close()
	_play_result_beats(Combat.use_blast())


func _on_use_shield() -> void:
	Bag.close()
	_play_result_beats(Combat.use_shield())


func _on_use_black_hole() -> void:
	Bag.close()
	_play_result_beats(Combat.use_black_hole())


func _on_use_healing_burst() -> void:
	Bag.close()
	var combat: Dictionary = GameState.state["combat"]
	var target: Dictionary = combat["selection"].duplicate() if combat["active"] else {}
	_play_result_beats(Consumables.use_healing_burst(target))


func _on_use_prophets_breath() -> void:
	Bag.close()
	Combat.use_prophets_breath()


func _on_use_wormhole() -> void:
	Bag.close()
	_play_result_beats(Combat.use_wormhole())


func _on_use_rewind() -> void:
	var result: Dictionary = Combat.combat_rewind()
	var beats: Array = result.get("beats", [])
	if not beats.is_empty():
		EventBus.combat_rewind_played.emit(beats)
