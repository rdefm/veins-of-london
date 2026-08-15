class_name BagDrawer
extends Control

# D4.4's global bag drawer: a bottom sheet, openable from ANY screen
# (Bag.open(), driven by state.bagDrawerOpen) without costing a turn, a
# block, or advancing anything — it's a pure read of state, same as
# ModalLayer, just anchored to the bottom and keyed off a different state
# field so it can be open independently of state.modal.
#
# Read-only everywhere except combat, where it shows the legal Use buttons
# and replaces the old "combat_items" modal (ported from modal_layer.gd's
# former _build_combat_items). itemHooks (event cards with legal item uses)
# don't exist yet in the event framework (M1-LONDON.md D5/ticket 08) — no
# event has one to test against — so that half of D4.4 is deferred until
# events actually carry hooks; combat is the only non-read-only context for
# now.

const DRAWER_HEIGHT := 420.0

# calc-effect-wiring-02: extended with the five newly-wired effects. Still a
# curated list, not every GameData.RECIPES key (unlike inventory.gd's tab,
# which now iterates all of them) -- this summary only covers consumables
# with a real, usable effect; sale-only/not-yet-wired recipes (rejuvenation,
# prophetsBreath, etc.) stay off it.
const CONSUMABLE_KEYS := ["timePearl", "enhancementPowder", "rewind", "healingSalve", "blast", "shield", "blackHole", "healingBurst"]

var _dim: ColorRect
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

	var card := PanelContainer.new()
	UI.anchor_bottom_wide(card)
	card.offset_top = -DRAWER_HEIGHT
	card.offset_bottom = 0
	add_child(card)

	var scroll := UI.scroll_container()
	card.add_child(scroll)

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

	_content.add_child(UI.heading("Bag"))

	_content.add_child(UI.heading("Ore", 14))
	for ore_type in GameData.ORE_TYPES.keys():
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var qty: int = player["orichalchum"].get(ore_type, 0)
		_content.add_child(UI.label("%s %s: %d" % [ore["symbol"], ore["name"], qty]))

	_content.add_child(UI.heading("Consumables", 14))
	for recipe_key in CONSUMABLE_KEYS:
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		var qty: int = player["inventory"].get(recipe_key, 0)
		_content.add_child(UI.label("%s %s: %d" % [recipe["symbol"], recipe["name"], qty]))

	_content.add_child(UI.heading("Equipped", 14))
	_content.add_child(_build_equipped_weapon_label(player))
	_content.add_child(_build_equipped_device_label(player))

	if combat["active"]:
		_content.add_child(UI.heading("Use an item", 14))
		_add_combat_use_buttons(player, combat)

	_content.add_child(UI.button("Close", func(): Bag.close()))


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
	if player["inventory"]["timePearl"] > 0:
		_content.add_child(UI.button("⧖ Time Pearl (%d) — freeze enemy" % player["inventory"]["timePearl"], _on_use_time_pearl))

	if player["inventory"]["enhancementPowder"] > 0:
		_content.add_child(UI.button("↯ Enhancement Powder (%d) — extra attacks" % player["inventory"]["enhancementPowder"], _on_use_enhancement_powder))

	# calc-effect-wiring-02: blast/shield/blackHole/healingBurst.
	# PROSE-REVIEW: new button labels below, drafted against CONTENT-GUIDE.md's tone bible.
	if player["inventory"].get("blast", 0) > 0:
		_content.add_child(UI.button("☄ Blast (%d) — damage, flee boost, chance to disarm" % player["inventory"]["blast"], _on_use_blast))

	if player["inventory"].get("shield", 0) > 0:
		var shield_button := UI.button("⛨ Shield (%d) — absorb incoming damage" % player["inventory"]["shield"], _on_use_shield)
		shield_button.disabled = player["shieldPool"] > 0
		_content.add_child(shield_button)

	if player["inventory"].get("blackHole", 0) > 0:
		_content.add_child(UI.button("⊙ Black Hole (%d) — damage and freeze" % player["inventory"]["blackHole"], _on_use_black_hole))

	if player["inventory"].get("healingBurst", 0) > 0:
		_content.add_child(UI.button("✚ Healing Burst (%d) — instant heal" % player["inventory"]["healingBurst"], _on_use_healing_burst))

	var snap_count: int = combat["snapshots"].size()
	if player["inventory"]["rewind"] > 0:
		var rewind_label := "(%d turn(s) back · +50%% evade x2 turns)" % snap_count if snap_count > 0 else "(nothing to undo yet)"
		var rewind_button := UI.button("⟲ Rewind (%d) — %s" % [player["inventory"]["rewind"], rewind_label], func(): Combat.combat_rewind())
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
