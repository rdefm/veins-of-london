class_name ModalLayer
extends Control

# Dim background + centred card, dispatching on modal.type. Covers the
# roster T12 asks for except room_detail and generic confirm dialogs
# (deferred — see the note at the bottom of this file).

var _dim: ColorRect
var _card: PanelContainer
var _scroll: ScrollContainer
var _card_content: VBoxContainer

# Root cause of "cultivate/seed shows a blank white modal, nothing tappable"
# (bugfixes ticket 06): _card is a shrink-to-fit PanelContainer (UI.anchor_
# center — its rect clamps up to its own minimum size, per Control's normal
# anchor/offset/minimum-size resolution), sized by its one child, _scroll.
# But a ScrollContainer deliberately reports ZERO minimum size on any axis
# where scrolling isn't disabled (that's what lets it scroll instead of
# forcing its parent bigger) — vertical_scroll_mode was left at its default
# (enabled), so _card's computed minimum height was always 0 regardless of
# how much content _card_content held. The card rect was really there
# (330 wide) but zero-tall: invisible and untappable, on every modal, every
# time — not just seed/cultivate, just first hit there because those are
# the earliest modals a fresh playthrough reaches. Fixed by capping
# _scroll's own minimum height to whatever _card_content actually needs (so
# short results like this one size the card to fit, like PanelContainer
# always should have), falling back to MAX_CARD_HEIGHT and real scrolling
# only for content taller than that (sell_menu, network_reference).
const MAX_CARD_HEIGHT := 620.0


func _ready() -> void:
	UI.anchor_full_rect(self)
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	# Ticket 12: without this, STOP just swallows the tap silently, leaving
	# scrolling to an explicit Close/Cancel/Decline button as the only way
	# out. Same pattern as map_controls.gd's filter drawer.
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	_card = PanelContainer.new()
	UI.anchor_center(_card)
	add_child(_card)

	_scroll = UI.scroll_container()
	_scroll.custom_minimum_size = Vector2(330, 0)
	_card.add_child(_scroll)

	# Anchors are ignored for a ScrollContainer's child, and without
	# SIZE_EXPAND_FILL it shrinks to its content's minimum width instead of
	# scroll's 330px — the same failure mode UI.screen_body()'s own comment
	# documents (a word-wrapped Label's minimum width collapses near 0,
	# breaking mid-word), and the same fix bag_drawer.gd needed.
	_card_content = UI.vbox(8)
	_card_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_card_content)

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _on_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		_dismiss_modal()


# Ticket 12: tapping outside must run the same side effect as the modal's
# own Close/Cancel/Decline button, not a bare Modal.close() that leaves
# state half-applied — sell_menu's sellState selections, james_job_offer's
# job-decline bookkeeping, and sale_result's return-to-home nav all need
# that. Every other modal's own close button is a bare Modal.close() with no
# side effect (checked against the full match in _build_modal_content()
# above), so they fall through to the default. james_job_offer's Accept
# isn't included here: it's a positive action, not the modal's dismiss path,
# so outside-tap must not run it.
func _dismiss_modal() -> void:
	var modal = GameState.state["modal"]
	if modal == null:
		return
	match modal.get("type", ""):
		"sell_menu":
			_on_sell_menu_cancel()
		"james_job_offer":
			_on_job_decline()
		"sale_result":
			_on_sale_result_close()
		_:
			Modal.close()


func _refresh() -> void:
	var modal = GameState.state["modal"]
	visible = modal != null
	if modal == null:
		return

	for child in _card_content.get_children():
		child.queue_free()

	_build_modal_content(modal)

	# One pass now (covers every unwrapped/single-line label immediately, so
	# there's never a fully blank frame) and one deferred (a freshly-added
	# autowrapping Label can't know its own wrapped height until a layout
	# pass has actually handed it _card_content's real width — same chicken-
	# and-egg UI.screen_body()'s own comments describe — so the first pass
	# can undercount a wrapped line and needs the deferred correction).
	_size_card_to_content()
	_size_card_to_content.call_deferred()


func _size_card_to_content() -> void:
	if _card_content.get_child_count() == 0:
		return
	var content_height: float = _card_content.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = minf(content_height, MAX_CARD_HEIGHT)


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
		"network_reference":
			_build_network_reference()
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
	var text_label := UI.label(label_text)
	# Same fix as UI.message_bubble()/checklist_row(): a non-expand
	# autowrapping Label's minimum size collapses to ~1px, so without this
	# it renders as a 1px-wide column with the text overflowing across the
	# "-"/qty/"+" controls that follow it in this row.
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_label)
	# Bugfixes ticket 13: this was "−" (U+2212 MINUS SIGN), the same
	# invisible-non-ASCII-glyph bug as the map top bar's "☰"/"🎒", and
	# unlike its "+" sibling it had no fallback text to keep the button
	# legible. ASCII "-" renders correctly.
	row.add_child(UI.button("-", func(): Economy.adjust_sell_qty(key, -1, max_qty)))
	var qty_label := UI.label(str(qty))
	qty_label.autowrap_mode = TextServer.AUTOWRAP_OFF  # compact number, same fix as the checkbox glyph above
	row.add_child(qty_label)
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


# M1.5 N5's legend button ("?" on the filter chip row, map_controls.gd) ->
# "Network Reference": the glyph grammar, N2, plain-listed. PROSE-REVIEW:
# every string in this function — the flavour line and all the row
# descriptions below — is new prose, drafted per CONTENT-GUIDE.md's tone
# bible, not yet human-audited.
func _build_network_reference() -> void:
	_card_content.add_child(UI.heading("Network Reference"))
	_card_content.add_child(UI.muted_label("The lines are money. The dots are where it's coming from — or where someone beat you to it."))
	_card_content.add_child(_legend_row("Amber line", "Your line — stops joined in claim order."))
	_card_content.add_child(_legend_row("Coloured line", "A faction's line, in their colour."))
	_card_content.add_child(_legend_row("Grey stub", "Someone else's claim — not yours, not connected to anything."))
	_card_content.add_child(_legend_row("Ringed dot + symbol", "Your vein. The symbol shows the ore."))
	_card_content.add_child(_legend_row("Tick mark", "Unclaimed site. Double tick — richer ground."))
	_card_content.add_child(_legend_row("Filled grey dot", "Claimed. Not by you."))
	_card_content.add_child(_legend_row("Amber halo", "Charged — ready to harvest."))
	_card_content.add_child(_legend_row("Numeral badge", "Vein level."))
	_card_content.add_child(_legend_row("Padlock", "Security tier — colour shows how well-warded."))
	_card_content.add_child(_legend_row("Zone tint", "A faction's presence in the district."))
	_card_content.add_child(_legend_row("⌂ pin", "Home. Taps through to HQ."))
	_card_content.add_child(_legend_row("✉ pin", "Someone's waiting on you there."))
	_card_content.add_child(_legend_row("Padlocked pin", "The Soho market. Not yet."))
	_card_content.add_child(_legend_row("Amber ring", "Where you are right now."))
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _legend_row(glyph_label: String, description: String) -> Control:
	var row := UI.vbox(2)
	row.add_child(UI.label(glyph_label))
	row.add_child(UI.muted_label(description))
	return row


# Item-use during combat used to be a modal here ("combat_items"); D4.4's
# BagDrawer (scenes/components/bag_drawer.gd) replaces it — combat.gd's
# "Item" button now opens that instead of a modal.

# Deferred: room_detail (manage/assign a built room) and generic confirm
# dialogs. Confirm specifically needs its own design pass — state.modal.
# data can't hold a Callable (state purity, R§2), so a reusable "confirm
# with an arbitrary callback" modal isn't possible under this schema; it
# needs a per-action-type dispatch (e.g. modal.type = "confirm_abandon_
# device", data = {deviceId}) the same way every other modal here works.
# No destructive action currently routes through this screen without a
# confirm step, so nothing is blocked on it — noted for a follow-up pass.
