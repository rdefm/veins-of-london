class_name ModalLayer
extends Control

# Dim background + centred card, dispatching on modal.type. Covers the
# roster T12 asks for except room_detail and generic confirm dialogs
# (deferred — see the note at the bottom of this file).

var _dim: ColorRect
var _card: PanelContainer
var _card_content: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.5)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	add_child(_card)

	var scroll := UI.scroll_container()
	scroll.custom_minimum_size = Vector2(330, 0)
	_card.add_child(scroll)

	_card_content = UI.vbox(8)
	scroll.add_child(_card_content)

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var modal = GameState.state["modal"]
	visible = modal != null
	if modal == null:
		return

	for child in _card_content.get_children():
		child.queue_free()

	_build_modal_content(modal)


func _build_modal_content(modal: Dictionary) -> void:
	var type_id: String = modal.get("type", "")
	var data: Dictionary = modal.get("data", {})

	match type_id:
		"seed_result":
			_build_seed_result(data)
		"cultivate_result":
			_build_cultivate_result(data)
		"craft_result":
			_build_craft_result(data)
		"sell_menu":
			_build_sell_menu()
		"sale_result":
			_build_sale_result(data)
		"james_job_offer":
			_build_james_job_offer(data)
		"james_job_short":
			_build_james_job_short(data)
		"james_job_complete":
			_build_james_job_complete(data)
		"combat_items":
			_build_combat_items()
		_:
			_card_content.add_child(UI.heading(type_id))
			_card_content.add_child(UI.label("…"))
			_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _build_seed_result(data: Dictionary) -> void:
	var success: bool = data.get("success", false)
	_card_content.add_child(UI.heading("✅ Vein seeded." if success else "❌ Nothing took."))
	if success:
		var ore: Dictionary = GameData.ORE_TYPES[data["oreType"]]
		_card_content.add_child(UI.label("A level 1 %s vein has formed. Cultivate it to grow." % ore["name"]))
	else:
		_card_content.add_child(UI.label("The calc dispersed without forming anything. Happens. Keep practising."))
	_card_content.add_child(UI.button("Got it", func(): Modal.close()))


func _build_cultivate_result(data: Dictionary) -> void:
	var success: bool = data.get("success", false)
	var levelled_up: bool = data.get("levelledUp", false)
	_card_content.add_child(UI.heading("🌱 Cultivation worked." if success else "❌ Nothing happened."))
	if success:
		if levelled_up:
			_card_content.add_child(UI.label("The vein responded well. It's levelled up to %s." % data.get("newLabel", "")))
		else:
			_card_content.add_child(UI.label("Development bar +%d. Keep at it." % data.get("gain", 0)))
	else:
		_card_content.add_child(UI.label("The vein didn't respond this time. Happens. Your cultivating skill will improve with practice."))
	_card_content.add_child(UI.button("Got it", func(): Modal.close()))


func _build_craft_result(data: Dictionary) -> void:
	var success: bool = data.get("success", false)
	var recipe_key: String = data.get("recipeKey", "")
	var r: Dictionary = GameData.RECIPES.get(recipe_key, {})
	_card_content.add_child(UI.heading("✅ Success" if success else "❌ Failed"))
	if success:
		var power = data.get("power", 0)
		_card_content.add_child(UI.label("You made a %s. Effect power: %s. The calc cost was worth it." % [r.get("name", ""), str(power)]))
	else:
		_card_content.add_child(UI.label("The calc dispersed. Nothing to show for it."))
	_card_content.add_child(UI.button("Got it", func(): Modal.close()))


func _build_sale_result(data: Dictionary) -> void:
	var mugged: bool = data.get("mugged", false)
	_card_content.add_child(UI.heading("You held them off." if mugged else "Done."))
	if mugged:
		_card_content.add_child(UI.label("They tried their luck. They didn't get it. Archie owes you a pint."))
	else:
		_card_content.add_child(UI.label("Smooth as you like. Buyer paid promptly and left."))
	_card_content.add_child(UI.label("+£%d" % data.get("earned", 0)))
	_card_content.add_child(UI.button("Back to it", _on_sale_result_close))


func _on_sale_result_close() -> void:
	Modal.close()
	Nav.go_to("home")


func _build_sell_menu() -> void:
	var player: Dictionary = GameState.state["player"]
	var sell_state: Dictionary = GameState.state["sellState"]

	_card_content.add_child(UI.heading("Find a buyer"))
	_card_content.add_child(UI.muted_label("Archie splits 50/50. Select what you want to move."))

	var gross := 0

	for ore_type in GameData.ORE_TYPES.keys():
		var have: int = player["orichalchum"].get(ore_type, 0)
		if have <= 0:
			continue
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var key := "ore_%s" % ore_type
		var qty: int = sell_state.get(key, 0)
		gross += ore["basePrice"] * qty
		_card_content.add_child(_build_sell_row("%s %s (£%d/u, have %d)" % [ore["symbol"], ore["name"], ore["basePrice"], have], key, qty, have))

	if GameState.state["flags"]["canSellConsumables"]:
		for recipe_key in GameData.CONSUMABLE_PRICES.keys():
			var have: int = player["inventory"].get(recipe_key, 0)
			if have <= 0:
				continue
			var recipe: Dictionary = GameData.RECIPES[recipe_key]
			var price: int = GameData.CONSUMABLE_PRICES[recipe_key]
			var key := "con_%s" % recipe_key
			var qty: int = sell_state.get(key, 0)
			gross += price * qty
			_card_content.add_child(_build_sell_row("%s %s (£%d/ea, have %d)" % [recipe["symbol"], recipe["name"], price, have], key, qty, have))

	var player_cut: int = int(floor(gross * Economy.PLAYER_CUT_RATIO))
	_card_content.add_child(UI.label("Your cut (50%%): £%d" % player_cut))
	_card_content.add_child(UI.muted_label("20% chance of mugging"))

	var go_button := UI.button("Go — find a buyer", func(): Economy.sell_from_sell_state())
	go_button.disabled = player_cut == 0
	_card_content.add_child(go_button)
	_card_content.add_child(UI.button("Cancel", _on_sell_menu_cancel))


func _on_sell_menu_cancel() -> void:
	Economy.clear_sell_state()
	Modal.close()


func _build_sell_row(label_text: String, key: String, qty: int, max_qty: int) -> Control:
	var row := UI.hbox()
	row.add_child(UI.label(label_text))
	row.add_child(UI.button("−", func(): Economy.adjust_sell_qty(key, -1, max_qty)))
	row.add_child(UI.label(str(qty)))
	row.add_child(UI.button("+", func(): Economy.adjust_sell_qty(key, 1, max_qty)))
	return row


func _build_james_job_offer(data: Dictionary) -> void:
	var job: Dictionary = data["job"]
	_card_content.add_child(UI.heading("Job from James"))
	_card_content.add_child(UI.label("\"I need %d %s. Standard rate. Don't take too long about it.\"" % [job["qty"], job["recipeName"]]))
	_card_content.add_child(UI.label("%s %s ×%d — £%d/ea — total £%d" % [job["symbol"], job["recipeName"], job["qty"], job["payPerItem"], job["totalPay"]]))
	_card_content.add_child(UI.button("Accept", _on_job_accept))
	_card_content.add_child(UI.button("Decline", _on_job_decline))


func _on_job_accept() -> void:
	Jobs.accept_job()
	Modal.close()


func _on_job_decline() -> void:
	Modal.close()
	Jobs.decline_job()


func _build_james_job_short(data: Dictionary) -> void:
	var job: Dictionary = data["job"]
	_card_content.add_child(UI.heading("Not enough stock"))
	_card_content.add_child(UI.label("James needs %d× %s. You have %d. Get crafting." % [job["qty"], job["recipeName"], data.get("have", 0)]))
	_card_content.add_child(UI.button("Back to it", func(): Modal.close()))


func _build_james_job_complete(data: Dictionary) -> void:
	_card_content.add_child(UI.heading("Job done."))
	_card_content.add_child(UI.label("\"Adequate work. Prompt enough.\" He counts out the money without ceremony."))
	_card_content.add_child(UI.label("+£%d" % data.get("earned", 0)))
	_card_content.add_child(UI.button("Good.", func(): Modal.close()))


func _build_combat_items() -> void:
	var player: Dictionary = GameState.state["player"]
	var combat: Dictionary = GameState.state["combat"]

	_card_content.add_child(UI.heading("Use an item"))
	_card_content.add_child(UI.muted_label("Pick what to use this turn."))

	if player["inventory"]["timePearl"] > 0:
		_card_content.add_child(UI.button("⧖ Time Pearl (%d) — freeze enemy" % player["inventory"]["timePearl"], _on_use_time_pearl))

	if player["inventory"]["enhancementPowder"] > 0:
		_card_content.add_child(UI.button("↯ Enhancement Powder (%d) — extra attacks" % player["inventory"]["enhancementPowder"], _on_use_enhancement_powder))

	var snap_count: int = combat["snapshots"].size()
	if player["inventory"]["rewind"] > 0:
		var rewind_label := "(%d turn(s) back · +50%% evade x2 turns)" % snap_count if snap_count > 0 else "(nothing to undo yet)"
		var rewind_button := UI.button("⟲ Rewind (%d) — %s" % [player["inventory"]["rewind"], rewind_label], func(): Combat.combat_rewind())
		rewind_button.disabled = snap_count == 0
		_card_content.add_child(rewind_button)

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
			_card_content.add_child(device_button)

	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


func _on_use_time_pearl() -> void:
	Modal.close()
	Combat.use_time_pearl()


func _on_use_enhancement_powder() -> void:
	Modal.close()
	Combat.use_enhancement_powder()


func _on_use_device() -> void:
	var player: Dictionary = GameState.state["player"]
	var device_id = player["equipment"]["device"]
	var dt: Dictionary = {}
	for d in player["devicesCompleted"]:
		if d["id"] == device_id:
			dt = GameData.DEVICES[d["type"]]
			break
	Modal.close()
	if dt.get("effect", "") == "rewind":
		Combat.combat_rewind()
	else:
		Combat.use_device()

# Deferred: room_detail (manage/assign a built room) and generic confirm
# dialogs. Confirm specifically needs its own design pass — state.modal.
# data can't hold a Callable (state purity, R§2), so a reusable "confirm
# with an arbitrary callback" modal isn't possible under this schema; it
# needs a per-action-type dispatch (e.g. modal.type = "confirm_abandon_
# device", data = {deviceId}) the same way every other modal here works.
# No destructive action currently routes through this screen without a
# confirm step, so nothing is blocked on it — noted for a follow-up pass.
