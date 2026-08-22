class_name BagDrawer
extends Control

# D4.4's global bag drawer: a bottom sheet, openable from ANY screen
# (Bag.open(), driven by state.bagDrawerOpen) without costing a turn, a
# block, or advancing anything — it's a pure read of state, same as
# ModalLayer, just anchored to the bottom and keyed off a different state
# field so it can be open independently of state.modal.
#
# 05-bag-drawer-promotion: full management (equip/unequip weapon+device,
# device start/build-attempt/abandon — ported straight from inventory.gd's
# equipment tab) outside combat/item-hook events. Inside them it falls back
# to read-only contents plus the legal Use buttons — combat's version
# replaces the old "combat_items" modal (ported from modal_layer.gd's former
# _build_combat_items). itemHooks (event cards with legal item uses) don't
# exist yet in the event framework (M1-LONDON.md D5/ticket 08) — no event
# has one, or a Use-button system to go with it — so the itemHooks half of
# the gate only ever hides management controls for now; it never has
# anything to show in their place.

const DRAWER_HEIGHT := 420.0
const MANAGEMENT_DRAWER_HEIGHT := 700.0

# calc-effect-wiring-02/03: extended with the newly-wired effects. Still a
# curated list, not every GameData.RECIPES key (unlike inventory.gd's tab,
# which now iterates all of them) -- this summary only covers consumables
# with a real, usable effect reachable from THIS drawer; sale-only/not-yet-
# wired recipes (rejuvenation, etc.) stay off it. failsafe is deliberately
# absent too -- it's wired (calc-effect-wiring-03) but has no manual Use
# action, so it belongs only on inventory.gd's tab, which lists every
# in-stock recipe regardless of whether it has a button here.
const CONSUMABLE_KEYS := ["timePearl", "enhancementPowder", "rewind", "healingSalve", "blast", "shield", "blackHole", "healingBurst", "prophetsBreath", "wormhole"]

# Ticket 12: the two strictly-out-of-combat effects (healingSalve is a 2-day
# heal-over-time; healingBurst is instant but also legal outside a fight) --
# ported from the deleted inventory.gd's OUT_OF_COMBAT_USE_KEYS, since that
# screen was the only place either had a manual Use control. Only shown in
# management mode (outside combat and outside an itemHooks event card), same
# gate as equip/device management -- these are self-service actions, not
# combat-legal item hooks.
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
	# Ticket 12: without this, STOP just swallows the tap silently, leaving
	# scrolling to the explicit Close button as the only way out. Same
	# pattern as map_controls.gd's filter drawer.
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	_card = PanelContainer.new()
	UI.anchor_bottom_wide(_card)
	_card.offset_top = -DRAWER_HEIGHT
	_card.offset_bottom = 0
	add_child(_card)

	var scroll := UI.scroll_container()
	_card.add_child(scroll)

	# Anchors are ignored for a ScrollContainer's child, and without
	# SIZE_EXPAND_FILL it shrinks to its content's minimum width instead of
	# the drawer's — the same failure mode UI.screen_body()'s own comment
	# documents (a word-wrapped Label's minimum width collapses near 0,
	# breaking mid-word, e.g. "Orichalchum" -> "Orichalchu"/"m: 20"), just
	# not worked around here until a real device showed it.
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
		_content.add_child(UI.label("%s %s: %d" % [ore["symbol"], ore["name"], qty]))

	_content.add_child(UI.heading("Consumables", 14))
	for recipe_key in CONSUMABLE_KEYS:
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		var qty: int = Crafting.inventory_qty(recipe_key)
		_content.add_child(UI.label("%s %s: %d" % [recipe["symbol"], recipe["name"], qty]))

	# A used-up salve still has a running HoT even once its stock hits 0 --
	# ported from inventory.gd, same unconditional-on-days-left visibility.
	if player["healingSalveDaysLeft"] > 0:
		_content.add_child(UI.muted_label("♥ Healing Salve active — %d HP/day, %d day(s) left" % [player["healingSalveDailyAmount"], player["healingSalveDaysLeft"]]))

	if management:
		_add_out_of_combat_use_buttons(player)
		_build_weapon_management(player)
		_build_device_management(player)
	else:
		_content.add_child(UI.heading("Equipped", 14))
		_content.add_child(_build_equipped_weapon_label(player))
		_content.add_child(_build_equipped_device_label(player))

	if combat["active"]:
		_content.add_child(UI.heading("Use an item", 14))
		_add_combat_use_buttons(player, combat)

	_content.add_child(UI.button("Close", func(): Bag.close()))


# Full management (equip/unequip, device lifecycle) is only safe outside
# combat and outside an event card carrying itemHooks — both are contexts
# where re-optimizing a loadout for free would be an exploit. itemHooks
# doesn't exist on any authored card yet (see class comment), so this half
# of the check is always false today, same as bag_drawer's original D4.4
# comment already documented — it's here so the gate is correct the moment
# ticket 08's event content lands, without another edit to this file.
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


# Ported from inventory.gd's OUT_OF_COMBAT_USE_KEYS section — the only two
# recipes with a legal manual Use outside combat. healingBurst reuses
# _on_use_healing_burst below (same Consumables call combat's button makes);
# healingSalve gets its own handler since combat never offered it a button.
func _add_out_of_combat_use_buttons(player: Dictionary) -> void:
	if Crafting.inventory_qty("healingSalve") > 0:
		_content.add_child(UI.button("♥ Healing Salve (%d) — 2-day heal-over-time" % Crafting.inventory_qty("healingSalve"), _on_use_healing_salve))
	if Crafting.inventory_qty("healingBurst") > 0:
		_content.add_child(UI.button("✚ Healing Burst (%d) — instant heal" % Crafting.inventory_qty("healingBurst"), _on_use_healing_burst))


func _on_use_healing_salve() -> void:
	Bag.close()
	Consumables.use_healing_salve()


# Ported from inventory.gd's _build_equipment_tab weapon half — same
# equip/unequip logic, Equipment system calls unchanged.
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
		# items.json's schema (REFERENCE.md §1.5: key/name/slot/attackBonus/
		# description) has no "symbol" field, unlike ore/recipes/devices --
		# def["name"] alone, matching that canon schema.
		c["content"].add_child(UI.label("%s%s" % [def["name"], " (equipped)" if is_equipped else ""]))
		c["content"].add_child(UI.muted_label(def["description"]))
		c["content"].add_child(UI.muted_label("+%d–%d attack" % [def["attackBonus"]["min"], def["attackBonus"]["max"]]))
		if is_equipped:
			c["content"].add_child(UI.button("Unequip", func(): Equipment.unequip_weapon()))
		else:
			c["content"].add_child(UI.button("Equip", func(): Equipment.equip_weapon(item_id)))
		_content.add_child(c["panel"])


# Ported from inventory.gd's _build_equipment_tab device half — equipped
# device summary + unequip, other completed devices' equip buttons,
# in-progress devices' build-attempt/abandon, and the start-new-device row.
func _build_device_management(player: Dictionary) -> void:
	_content.add_child(UI.heading("Device", 14))
	var equipped_device_id = player["equipment"]["device"]
	var equipped_device = null
	for d in player["devicesCompleted"]:
		if d["id"] == equipped_device_id:
			equipped_device = d
			break

	if equipped_device != null:
		var dt: Dictionary = GameData.DEVICES[equipped_device["type"]]
		var c := UI.card()
		c["content"].add_child(UI.label("%s %s (equipped) — Lv%d" % [dt["symbol"], dt["name"], equipped_device["level"]]))
		c["content"].add_child(UI.muted_label("%d/%d charges today" % [equipped_device["chargesPerDay"] - equipped_device["chargesUsedToday"], equipped_device["chargesPerDay"]]))
		c["content"].add_child(UI.button("Unequip", func(): Devices.unequip_device()))
		_content.add_child(c["panel"])
	else:
		_content.add_child(UI.muted_label("No device equipped."))

	for d in player["devicesCompleted"]:
		if d["id"] == equipped_device_id:
			continue
		var dt: Dictionary = GameData.DEVICES[d["type"]]
		var device_id: String = d["id"]
		var c := UI.card()
		c["content"].add_child(UI.label("%s %s — Lv%d" % [dt["symbol"], dt["name"], d["level"]]))
		c["content"].add_child(UI.button("Equip", func(): Devices.equip_device(device_id)))
		_content.add_child(c["panel"])

	if not player["devicesInProgress"].is_empty():
		_content.add_child(UI.heading("Devices in progress", 14))
		for d in player["devicesInProgress"]:
			var dt: Dictionary = GameData.DEVICES[d["type"]]
			var device_id: String = d["id"]
			var c := UI.card()
			c["content"].add_child(UI.label("%s %s — %d%%" % [dt["symbol"], dt["name"], int(d["progress"])]))
			c["content"].add_child(UI.bar(d["progress"], 100.0))
			var actions := UI.hbox()
			actions.add_child(UI.button("Build attempt", func(): Devices.attempt_device_build(device_id)))
			actions.add_child(UI.button("Abandon", func(): Devices.abandon_device(device_id)))
			c["content"].add_child(actions)
			_content.add_child(c["panel"])

	_content.add_child(UI.heading("Start a new device", 14))
	var start_row := UI.hbox()
	for device_key in GameData.DEVICES.keys():
		var dt: Dictionary = GameData.DEVICES[device_key]
		var captured_key: String = device_key
		start_row.add_child(UI.button("%s %s" % [dt["symbol"], dt["name"]], func(): Devices.start_device(captured_key)))
	_content.add_child(start_row)


func _build_equipped_weapon_label(player: Dictionary) -> Control:
	var weapon_id = player["equipment"]["weapon"]
	for item in player["items"]:
		if item["id"] == weapon_id:
			var def: Dictionary = GameData.ITEMS.get(item["type"], {})
			return UI.label("%s %s (equipped)" % [def.get("symbol", ""), def.get("name", "")])
	return UI.muted_label("Weapon: none equipped")


func _build_equipped_device_label(player: Dictionary) -> Control:
	var device_id = player["equipment"]["device"]
	for device in player["devicesCompleted"]:
		if device["id"] == device_id:
			var dt: Dictionary = GameData.DEVICES[device["type"]]
			var charges_left: int = device["chargesPerDay"] - device["chargesUsedToday"]
			return UI.label("%s %s (equipped) — %d/%d charges" % [dt["symbol"], dt["name"], charges_left, device["chargesPerDay"]])
	return UI.muted_label("Device: none equipped")


# Ported from modal_layer.gd's former _build_combat_items — same legal-use
# logic, Bag.close() instead of Modal.close() since this drawer replaces
# that modal (D4.4).
func _add_combat_use_buttons(player: Dictionary, combat: Dictionary) -> void:
	if Crafting.inventory_qty("timePearl") > 0:
		_content.add_child(UI.button("⧖ Time Pearl (%d) — freeze enemy" % Crafting.inventory_qty("timePearl"), _on_use_time_pearl))

	if Crafting.inventory_qty("enhancementPowder") > 0:
		_content.add_child(UI.button("↯ Enhancement Powder (%d) — extra attacks" % Crafting.inventory_qty("enhancementPowder"), _on_use_enhancement_powder))

	# calc-effect-wiring-02: blast/shield/blackHole/healingBurst.
	# PROSE-REVIEW: new button labels below, drafted against CONTENT-GUIDE.md's tone bible.
	if Crafting.inventory_qty("blast") > 0:
		_content.add_child(UI.button("☄ Blast (%d) — damage, flee boost, chance to disarm" % Crafting.inventory_qty("blast"), _on_use_blast))

	if Crafting.inventory_qty("shield") > 0:
		var shield_button := UI.button("⛨ Shield (%d) — absorb incoming damage" % Crafting.inventory_qty("shield"), _on_use_shield)
		shield_button.disabled = player["shieldPool"] > 0
		_content.add_child(shield_button)

	if Crafting.inventory_qty("blackHole") > 0:
		_content.add_child(UI.button("⊙ Black Hole (%d) — damage and freeze" % Crafting.inventory_qty("blackHole"), _on_use_black_hole))

	if Crafting.inventory_qty("healingBurst") > 0:
		_content.add_child(UI.button("✚ Healing Burst (%d) — instant heal" % Crafting.inventory_qty("healingBurst"), _on_use_healing_burst))

	# calc-effect-wiring-03: prophetsBreath/wormhole (combat evade buff /
	# guaranteed flee). failsafe has no button here -- see CONSUMABLE_KEYS'
	# comment.
	# PROSE-REVIEW: new button labels below, drafted against CONTENT-GUIDE.md's tone bible.
	if Crafting.inventory_qty("prophetsBreath") > 0:
		_content.add_child(UI.button("≋ Prophet's Breath (%d) — evade buff" % Crafting.inventory_qty("prophetsBreath"), _on_use_prophets_breath))

	if Crafting.inventory_qty("wormhole") > 0:
		_content.add_child(UI.button("⊗ Wormhole (%d) — guaranteed flee" % Crafting.inventory_qty("wormhole"), _on_use_wormhole))

	var snap_count: int = combat["snapshots"].size()
	if Crafting.inventory_qty("rewind") > 0:
		var rewind_label := "(%d turn(s) back · +50%% evade x2 turns)" % snap_count if snap_count > 0 else "(nothing to undo yet)"
		var rewind_button := UI.button("⟲ Rewind (%d) — %s" % [Crafting.inventory_qty("rewind"), rewind_label], func(): Combat.combat_rewind())
		rewind_button.disabled = snap_count == 0
		_content.add_child(rewind_button)

	var device_id = player["equipment"]["device"]
	if device_id != null:
		var device = null
		for d in player["devicesCompleted"]:
			if d["id"] == device_id:
				device = d
				break
		if device != null:
			var dt: Dictionary = GameData.DEVICES[device["type"]]
			var charges_left: int = device["chargesPerDay"] - device["chargesUsedToday"]
			var device_button := UI.button("%s %s (%d/%d)" % [dt["symbol"], dt["name"], charges_left, device["chargesPerDay"]], _on_use_device)
			device_button.disabled = charges_left <= 0
			_content.add_child(device_button)


func _on_use_time_pearl() -> void:
	Bag.close()
	Combat.use_time_pearl()


func _on_use_enhancement_powder() -> void:
	Bag.close()
	Combat.use_enhancement_powder()


func _on_use_blast() -> void:
	Bag.close()
	Combat.use_blast()


func _on_use_shield() -> void:
	Bag.close()
	Combat.use_shield()


func _on_use_black_hole() -> void:
	Bag.close()
	Combat.use_black_hole()


func _on_use_healing_burst() -> void:
	Bag.close()
	Consumables.use_healing_burst()


func _on_use_prophets_breath() -> void:
	Bag.close()
	Combat.use_prophets_breath()


func _on_use_wormhole() -> void:
	Bag.close()
	Combat.use_wormhole()


func _on_use_device() -> void:
	var player: Dictionary = GameState.state["player"]
	var device_id = player["equipment"]["device"]
	var dt: Dictionary = {}
	for d in player["devicesCompleted"]:
		if d["id"] == device_id:
			dt = GameData.DEVICES[d["type"]]
			break
	Bag.close()
	if dt.get("effect", "") == "rewind":
		Combat.combat_rewind()
	else:
		Combat.use_device()
