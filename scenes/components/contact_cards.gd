class_name ContactCards
extends RefCounted

const HANDLER_ID := NetworkHandler.CONTACT_ID

static func layout_directory_row(card: Control, contact_id: String) -> void:
	# Reuse the card's existing gated actions; only its presentation changes.
	card.set_meta("contact_directory_row", true)
	var content := card.get_child(0) as VBoxContainer
	var original := content.get_children()
	for child in original:
		content.remove_child(child)

	var header := UI.hbox(10)
	var avatar := Panel.new()
	avatar.custom_minimum_size = Vector2(50, 50)
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color("#70444d") if contact_id == "archie" else Color("#465b68")
	avatar_style.set_corner_radius_all(25)
	avatar.add_theme_stylebox_override("panel", avatar_style)
	var initial := Label.new()
	initial.text = Contacts.display_name(contact_id).substr(0, 1).to_upper()
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial.add_theme_font_size_override("font_size", 22)
	UI.anchor_full_rect(initial)
	avatar.add_child(initial)
	header.add_child(avatar)

	var copy := UI.vbox(2)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name := original[0] as Label
	name.text = Contacts.display_name(contact_id)
	copy.add_child(name)
	copy.add_child(original[1])
	header.add_child(copy)
	# The handler has no relation track of their own (collective-act2 spec §3).
	if contact_id != HANDLER_ID:
		var relation := UI.label("Rel. %d" % GameState.state["contacts"][contact_id]["relation"])
		relation.add_theme_font_size_override("font_size", 12)
		relation.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(relation)
	content.add_child(header)

	var quick: Dictionary = {}
	var extra: Array[Node] = []
	for i in range(2, original.size()):
		var child: Node = original[i]
		var kind := _quick_action_kind(child)
		if kind == "":
			extra.append(child)
		else:
			quick[kind] = child
	var row := UI.hbox(7)
	for kind in ["messages", "trade", "recruit"]:
		if quick.has(kind):
			var button := quick[kind] as Button
			_format_quick_action(button, kind, contact_id)
			row.add_child(button)
	content.add_child(row)
	for child in extra:
		content.add_child(child)


static func _quick_action_kind(node: Node) -> String:
	if not node is Button:
		return ""
	var label: String = (node as Button).text
	if label.contains("Messages"):
		return "messages"
	if label.contains("Trade"):
		return "trade"
	if label.contains("Recruit") or label.contains("recruited"):
		return "recruit"
	return ""


static func _format_quick_action(button: Button, kind: String, contact_id: String) -> void:
	button.set_meta("contact_quick_action", kind)
	button.tooltip_text = button.text
	button.text = ""
	button.custom_minimum_size = Vector2(0, 76)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var copy := UI.vbox(1)
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor_full_rect(copy)
	button.add_child(copy)
	var icon := Label.new()
	icon.text = {"messages": "▣", "trade": "⇄", "recruit": "☆"}[kind]
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 21)
	icon.add_theme_color_override("font_color", _palette("ui_action_red", _FALLBACK_ACTION) if not button.disabled else _palette(_PHONE_TEXT_MUTED, _FALLBACK_TEXT_MUTED))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(icon)
	var title := Label.new()
	title.text = {"messages": "Messages", "trade": "Trade", "recruit": "Recruit"}[kind]
	if kind == "recruit" and GameState.state["contacts"][contact_id]["recruited"]:
		title.text = "Recruited"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", _palette(_PHONE_TEXT_PRIMARY, _FALLBACK_TEXT_PRIMARY) if not button.disabled else _palette(_PHONE_TEXT_MUTED, _FALLBACK_TEXT_MUTED))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title)
	if kind == "recruit" and button.disabled and not GameState.state["contacts"][contact_id]["recruited"]:
		var needed: int = GameState.state["contacts"][contact_id]["recruitThreshold"] - GameState.state["contacts"][contact_id]["relation"]
		var hint := Label.new()
		hint.text = "%d more rel." % needed
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 10)
		hint.add_theme_color_override("font_color", _palette(_PHONE_TEXT_MUTED, _FALLBACK_TEXT_MUTED))
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_child(hint)



static func build_archie_card() -> Control:
	var archie: Dictionary = GameState.state["contacts"]["archie"]

	var c := UI.card()
	c["content"].add_child(UI.heading("Archie — Relation %d" % archie["relation"], 15))
	c["content"].add_child(UI.muted_label("Trader · Whitechapel"))

	for shortcut in build_pin_shortcut_actions("archie"):
		c["content"].add_child(shortcut)

	var pry_action := build_archie_pry_action()
	if pry_action != null:
		c["content"].add_child(pry_action)

	for entry in Messages.pending_for("archie"):
		if entry["kind"] == ArchieDeals.PENDING_KIND:
			c["content"].add_child(UI.label(entry["text"]))
			c["content"].add_child(UI.button("Accept", _on_archie_deal_accept.bind(entry)))
			c["content"].add_child(UI.button("Decline", _on_archie_deal_decline.bind(entry)))
		else:
			c["content"].add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))

	c["content"].add_child(build_messages_button("archie"))
	c["content"].add_child(build_sell_action())
	var recruit_row := build_recruit_row("archie")
	if recruit_row != null:
		c["content"].add_child(recruit_row)

	return c["panel"]


static func build_archie_pry_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA1ArchiePryAvailable", false):
		return null
	if flags.get("colA1AskedAboutDebt", false) or flags.get("colA1Complete", false):
		return null
	return UI.button("Ask about Des", func(): Events.start_event("col_a1_archie_pry"))


static func build_sell_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	var player: Dictionary = GameState.state["player"]

	if not flags["buyerEventSeen"]:
		var locked := UI.button("🤝 Trade (not unlocked yet)", func(): pass)
		locked.disabled = true
		return locked

	var has_ore := false
	for qty in player["orichalchum"].values():
		if qty > 0:
			has_ore = true
			break
	var has_consumables: bool = flags["canSellConsumables"] and (Crafting.inventory_qty("timePearl") > 0 or Crafting.inventory_qty("enhancementPowder") > 0)
	var has_sellable: bool = has_ore or has_consumables

	var b := UI.button("🤝 Trade" if has_sellable else "🤝 Trade (nothing to sell)", func(): Modal.open("sell_menu"))
	b.disabled = not has_sellable
	return b


static func build_trade_action(contact_id: String) -> Control:
	if not GameState.state["flags"].get("collectiveLaneUnlocked", false):
		var locked := UI.button("🤝 Trade (not unlocked yet)", func(): pass)
		locked.disabled = true
		return locked

	return UI.button("🤝 Trade", func(): Modal.open("sell_menu", { "factionId": "collective", "contactId": contact_id }))


static func build_pin_shortcut_actions(contact_id: String) -> Array:
	var actions: Array = []
	for pin in MapPins.active_phone_shortcuts_for(contact_id):
		actions.append(UI.button("📍 %s" % pin["phoneLabel"], func(): Events.start_event(pin["eventId"])))
	return actions


static func build_des_report_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("colA1DesThreadDone", false):
		return null
	var ore_type := Collective.next_reportable_des_ore_type()
	if ore_type == "":
		return null
	return UI.button("Tell Des about the ground", func(): _on_des_report_pressed(ore_type))


static func _on_des_report_pressed(ore_type: String) -> void:
	var result := Collective.report_des_site(ore_type)
	if not result.get("ok", false):
		return

	if GameState.state["objectives"]["col_a1_des_sites"]["complete"]:
		Events.start_event("col_a1_des_report")
	else:
		Events.start_event("col_a1_des_report_first_%s" % ore_type)


static func build_nadia_meet_action() -> Control:
	if GameState.state["flags"].get("colA1NadiaMet", false):
		return null
	return UI.button("Go and see Nadia", func(): Events.start_event("col_a1_nadia_meet"))


static func build_nadia_vein_ask_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA1NadiaSupplied", false) or flags.get("colA1NadiaAskSeen", false):
		return null
	return UI.button("Nadia has an idea", func(): Events.start_event("col_a1_nadia_vein"))


static func build_nadia_supply_action() -> Control:
	var runtime: Dictionary = GameState.state["objectives"].get("col_a1_nadia_supply", {})
	if not runtime.get("active", false) or runtime.get("complete", false):
		return null
	var presentation: Dictionary = GameData.OBJECTIVES["col_a1_nadia_supply"].get("presentation", {})
	return UI.button(presentation.get("supplyAction", ""), func(): Modal.open("nadia_supply"))


static func build_hakim_done_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA1HakimRescued", false) or flags.get("colA1HakimThreadDone", false):
		return null
	return UI.button("Hand Hakim's vein back", func(): Events.start_event("col_a1_hakim_done"))


# collective-act2 spec §6.13: T13's retake, open from the first Targets
# purchase on Hakim's Firm-held vein until the retake plays.
static func build_hakim_retake_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA2HakimIntelBought", false) or flags.get("colA2HakimRetaken", false):
		return null
	return UI.button("Get the yard back", func(): Events.start_event("col_a2_hakim_retake"))


# collective-act2 spec §6.8: T8's ledger scene, open from the end of Phase 0
# (T4) until it plays -- player-ordered alongside T5-T7 (spec §4).
static func build_nadia_ledger_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA2HandlerDeferred", false) or flags.get("colA2LedgerStarted", false):
		return null
	return UI.button("Sit down with Nadia", func(): Events.start_event("col_a2_nadia_ledger"))


# collective-act2 spec §6.12: T12's "Go with Nadia", open between
# colA2SecondLossSeen and the meet itself.
static func build_handler_meet_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA2SecondLossSeen", false) or flags.get("networkHandlerUnlocked", false):
		return null
	return UI.button("Go with Nadia", func(): Events.start_event("col_a2_handler_meet"))


# The handler's Targets/Sourcing entries (spec §5.3), once T12 unlocks them.
static func build_handler_actions() -> Array[Control]:
	var actions: Array[Control] = []
	if not GameState.state["flags"].get("networkHandlerUnlocked", false):
		return actions
	actions.append(UI.button("Targets", func(): Modal.open("network_targets")))
	actions.append(UI.button("Sourcing", func(): Modal.open("network_sourcing")))
	return actions


static func build_ask_des_joining_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA1DeferredJoin", false) or flags.get("colA1Joined", false):
		return null
	return UI.button("Ask Des about joining", func(): Events.start_event("col_a1_deferred_join"))


static func build_messages_button(contact_id: String) -> Control:
	var text := "💬 Messages"
	if Messages.has_unread(contact_id):
		text += " ●"
	return UI.button(text, func():
		Nav.go_to("phone")
		PhoneNav.select_conversation(contact_id)
	)


static func _on_pending_action_pressed(entry: Dictionary) -> void:
	Messages.resolve_pending(entry["id"])
	Events.start_event(entry["kind"], entry["payload"])


static func _on_archie_deal_accept(entry: Dictionary) -> void:
	ArchieDeals.accept_deal(entry["id"])


static func _on_archie_deal_decline(entry: Dictionary) -> void:
	ArchieDeals.decline_deal(entry["id"])


static func build_recruit_row(contact_id: String) -> Control:
	var c: Dictionary = GameState.state["contacts"][contact_id]
	var display_name: String = Contacts.display_name(contact_id)

	if not c.get("recruitable", true):
		return null

	if c["recruited"]:
		var done_button := UI.button("✅ %s recruited" % display_name, func(): pass)
		done_button.disabled = true
		return done_button

	if Contacts.can_recruit(contact_id):
		return UI.button("⭐ Recruit %s" % display_name, func(): Contacts.recruit(contact_id))

	var needed: int = c["recruitThreshold"] - c["relation"]
	var locked := UI.button("⭐ Recruit %s (%d relation needed)" % [display_name, needed], func(): pass)
	locked.disabled = true
	return locked


static func build_james_card() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	var james: Dictionary = GameState.state["contacts"]["james"]

	var c := UI.card()
	c["content"].add_child(UI.heading("James — Relation %d" % james["relation"], 15))
	c["content"].add_child(UI.muted_label("Craftsman · Bermondsey"))

	for shortcut in build_pin_shortcut_actions("james"):
		c["content"].add_child(shortcut)

	for entry in Messages.pending_for("james"):
		c["content"].add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))

	c["content"].add_child(build_messages_button("james"))

	if flags["jamesMotionEventSeen"]:
		var job_active: bool = flags["jamesJobActive"] and GameState.state["jamesJob"] != null
		if job_active:
			var job: Dictionary = GameState.state["jamesJob"]
			if not flags["jamesJobAccepted"]:
				c["content"].add_child(UI.button("📋 James has work for you", func(): Modal.open("james_job_offer", { "job": job })))
			elif job["type"] == "flatPay":
				c["content"].add_child(UI.button(UI.format_block_cost_label("💷 Do the job (£%d)" % job["pay"]), func(): Jobs.fulfil_job()))
			else:
				c["content"].add_child(UI.symbol_button(["📦 Deliver job: %d× " % job["qty"], { "symbol": job["symbol"], "fallback": SymbolGlyph.generic_fallback() }, " %s" % job["recipeName"]], func(): Jobs.fulfil_job()))

	var recruit_row := build_recruit_row("james")
	if recruit_row != null:
		c["content"].add_child(recruit_row)

	return c["panel"]


static func build_des_card() -> Control:
	var des: Dictionary = GameState.state["contacts"]["des"]

	var c := UI.card()
	c["content"].add_child(UI.heading("Des — Relation %d" % des["relation"], 15))
	c["content"].add_child(UI.muted_label("Prospector · Crystal Palace"))

	for shortcut in build_pin_shortcut_actions("des"):
		c["content"].add_child(shortcut)

	var report_action := build_des_report_action()
	if report_action != null:
		c["content"].add_child(report_action)
	var ask_joining_action := build_ask_des_joining_action()
	if ask_joining_action != null:
		c["content"].add_child(ask_joining_action)
	for entry in Messages.pending_for("des"):
		c["content"].add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))

	c["content"].add_child(build_messages_button("des"))
	c["content"].add_child(build_trade_action("des"))
	var recruit_row := build_recruit_row("des")
	if recruit_row != null:
		c["content"].add_child(recruit_row)

	return c["panel"]


# Owen is story-recruited (no relation path, no trade lane).
static func build_owen_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Owen", 15))
	c["content"].add_child(UI.muted_label("Apprentice cultivator · Bermondsey"))

	for shortcut in build_pin_shortcut_actions("owen"):
		c["content"].add_child(shortcut)
	c["content"].add_child(build_messages_button("owen"))
	return c["panel"]


static func build_nadia_card() -> Control:
	var nadia: Dictionary = GameState.state["contacts"]["nadia"]

	var c := UI.card()
	c["content"].add_child(UI.heading("Nadia — Relation %d" % nadia["relation"], 15))
	c["content"].add_child(UI.muted_label("Fixer · Hackney"))

	for shortcut in build_pin_shortcut_actions("nadia"):
		c["content"].add_child(shortcut)

	var meet_action := build_nadia_meet_action()
	if meet_action != null:
		c["content"].add_child(meet_action)
	var vein_ask_action := build_nadia_vein_ask_action()
	if vein_ask_action != null:
		c["content"].add_child(vein_ask_action)
	var supply_action := build_nadia_supply_action()
	if supply_action != null:
		c["content"].add_child(supply_action)
	var ledger_action := build_nadia_ledger_action()
	if ledger_action != null:
		c["content"].add_child(ledger_action)
	var handler_meet_action := build_handler_meet_action()
	if handler_meet_action != null:
		c["content"].add_child(handler_meet_action)
	for entry in Messages.pending_for("nadia"):
		c["content"].add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))

	c["content"].add_child(build_messages_button("nadia"))
	c["content"].add_child(build_trade_action("nadia"))
	var recruit_row := build_recruit_row("nadia")
	if recruit_row != null:
		c["content"].add_child(recruit_row)

	return c["panel"]


static func build_hakim_card() -> Control:
	var hakim: Dictionary = GameState.state["contacts"]["hakim"]

	var c := UI.card()
	c["content"].add_child(UI.heading("Hakim — Relation %d" % hakim["relation"], 15))
	c["content"].add_child(UI.muted_label("Newsagent · Whitechapel"))

	for shortcut in build_pin_shortcut_actions("hakim"):
		c["content"].add_child(shortcut)

	var done_action := build_hakim_done_action()
	if done_action != null:
		c["content"].add_child(done_action)
	var retake_action := build_hakim_retake_action()
	if retake_action != null:
		c["content"].add_child(retake_action)
	for entry in Messages.pending_for("hakim"):
		c["content"].add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))

	c["content"].add_child(build_messages_button("hakim"))
	c["content"].add_child(build_trade_action("hakim"))
	var recruit_row := build_recruit_row("hakim")
	if recruit_row != null:
		c["content"].add_child(recruit_row)

	return c["panel"]


static func build_handler_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Handler", 15))
	c["content"].add_child(UI.muted_label("The Network · Clerkenwell"))

	for action in build_handler_actions():
		c["content"].add_child(action)
	for entry in Messages.pending_for(HANDLER_ID):
		c["content"].add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))

	c["content"].add_child(build_messages_button(HANDLER_ID))

	return c["panel"]


const _PHONE_BG_HOME := "phone_bg_home"
const _PHONE_BG_CONTENT := "phone_bg_content"
const _PHONE_DIVIDER := "phone_divider"
const _PHONE_TEXT_PRIMARY := "phone_text_primary"
const _PHONE_TEXT_MUTED := "phone_text_muted"
const _PHONE_BUBBLE_INCOMING := "phone_bubble_incoming"

const _FALLBACK_BG_HOME := Color("#1b1b1d")
const _FALLBACK_BG_CONTENT := Color("#252528")
const _FALLBACK_DIVIDER := Color("#424246")
const _FALLBACK_TEXT_PRIMARY := Color("#ededee")
const _FALLBACK_TEXT_MUTED := Color("#999a9d")
const _FALLBACK_ACTION := Color("#c8102e")
const _FALLBACK_BUBBLE_INCOMING := Color("#333336")

const _GLOBAL_MUTED_GREY := Color(0.541176, 0.541176, 0.541176, 1)


static func _palette(id: String, fallback: Color) -> Color:
	return GameData.PALETTE.get(id, fallback)


static func apply_phone_os_chrome(root: Node) -> void:
	_style_subtree(root, false)


static func _style_subtree(node: Node, inside_button: bool) -> void:
	var next_inside_button := inside_button
	if node is PanelContainer:
		_style_panel(node as PanelContainer)
	elif node is Button:
		_style_button(node as Button)
		next_inside_button = true
	elif node is Label and not inside_button:
		_style_label(node as Label)
	elif node is ProgressBar:
		_style_progress_bar(node as ProgressBar)

	for child in node.get_children():
		_style_subtree(child, next_inside_button)


static func _style_panel(panel: PanelContainer) -> void:
	var parent := panel.get_parent()
	if parent is HBoxContainer:
		_style_bubble_panel(panel, (parent as HBoxContainer).alignment == BoxContainer.ALIGNMENT_END)
	else:
		_style_card_panel(panel)


static func _style_card_panel(panel: PanelContainer) -> void:
	if panel.has_meta("contact_directory_row"):
		var row_style := StyleBoxFlat.new()
		row_style.bg_color = _palette(_PHONE_BG_CONTENT, _FALLBACK_BG_CONTENT)
		row_style.border_color = _palette(_PHONE_DIVIDER, _FALLBACK_DIVIDER)
		row_style.border_width_bottom = 1
		row_style.content_margin_top = 8
		row_style.content_margin_bottom = 16
		panel.add_theme_stylebox_override("panel", row_style)
		return
	panel.add_theme_stylebox_override("panel", UI.bordered_panel_style(_palette(_PHONE_BG_CONTENT, _FALLBACK_BG_CONTENT), _palette(_PHONE_DIVIDER, _FALLBACK_DIVIDER), 10, 16, 16))


static func _style_bubble_panel(panel: PanelContainer, outgoing: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = _palette("ui_action_red", _FALLBACK_ACTION) if outgoing else _palette(_PHONE_BUBBLE_INCOMING, _FALLBACK_BUBBLE_INCOMING)
	style.set_corner_radius_all(14)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)


static func _style_progress_bar(bar: ProgressBar) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = _palette(_PHONE_TEXT_PRIMARY, _FALLBACK_TEXT_PRIMARY)
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)

	var track := StyleBoxFlat.new()
	track.bg_color = _palette(_PHONE_DIVIDER, _FALLBACK_DIVIDER)
	track.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", track)


static func _style_label(l: Label) -> void:
	if l.has_theme_color_override("font_color"):
		if l.get_theme_color("font_color").is_equal_approx(_GLOBAL_MUTED_GREY):
			l.add_theme_color_override("font_color", _palette(_PHONE_TEXT_MUTED, _FALLBACK_TEXT_MUTED))
	else:
		l.add_theme_color_override("font_color", _palette(_PHONE_TEXT_PRIMARY, _FALLBACK_TEXT_PRIMARY))


static func _style_button(b: Button) -> void:
	if b.has_meta("contact_quick_action"):
		_style_contact_quick_button(b)
		return
	if b.has_meta("contact_back"):
		var plain := _button_fill_style(Color(0, 0, 0, 0))
		plain.content_margin_left = 0
		b.add_theme_stylebox_override("normal", plain)
		b.add_theme_stylebox_override("hover", plain)
		b.add_theme_stylebox_override("pressed", plain)
		b.add_theme_color_override("font_color", _palette("ui_action_red", _FALLBACK_ACTION))
		return
	if b.disabled:
		_style_outline_button(b)
	else:
		_style_filled_button(b)


static func _style_contact_quick_button(b: Button) -> void:
	var style := _button_fill_style(Color("#36363a") if not b.disabled else Color("#2c2c2f"))
	style.set_corner_radius_all(12)
	b.add_theme_stylebox_override("normal", style)
	b.add_theme_stylebox_override("disabled", style)
	b.add_theme_stylebox_override("hover", _button_fill_style(Color("#444448")))
	b.add_theme_stylebox_override("pressed", _button_fill_style(Color("#29292c")))


static func _style_filled_button(b: Button) -> void:
	var accent := _palette("ui_action_red", _FALLBACK_ACTION)
	var text_colour := _palette(_PHONE_TEXT_PRIMARY, _FALLBACK_TEXT_PRIMARY)
	b.add_theme_stylebox_override("normal", _button_fill_style(accent))
	b.add_theme_stylebox_override("hover", _button_fill_style(accent.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", _button_fill_style(accent.darkened(0.15)))
	b.add_theme_color_override("font_color", text_colour)
	b.add_theme_color_override("font_hover_color", text_colour)
	b.add_theme_color_override("font_pressed_color", text_colour)
	_recolor_button_content(b, text_colour)


static func _style_outline_button(b: Button) -> void:
	var muted := _palette(_PHONE_TEXT_MUTED, _FALLBACK_TEXT_MUTED)
	var style := _button_fill_style(Color(0, 0, 0, 0))
	style.border_color = _palette(_PHONE_DIVIDER, _FALLBACK_DIVIDER)
	style.set_border_width_all(1)
	b.add_theme_stylebox_override("disabled", style)
	b.add_theme_color_override("font_disabled_color", muted)
	_recolor_button_content(b, muted)


static func _button_fill_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.content_margin_left = 16
	style.content_margin_top = 10
	style.content_margin_right = 16
	style.content_margin_bottom = 10
	style.set_corner_radius_all(8)
	return style


static func _recolor_button_content(b: Button, colour: Color) -> void:
	for l in b.find_children("", "Label", true, false):
		(l as Label).add_theme_color_override("font_color", colour)
	for g in b.find_children("", "SymbolGlyph", true, false):
		(g as SymbolGlyph).color = colour


static func build_faction_card(faction_id: String) -> Control:
	var f: Dictionary = GameData.FACTIONS[faction_id]
	var state: Dictionary = GameState.state["factions"][faction_id]
	var rel: int = state["relation"]

	var c := UI.card()
	c["content"].add_child(UI.heading(f["name"] + (" — Member" if state["joined"] else ""), 15))
	c["content"].add_child(UI.muted_label(f["tagline"]))
	c["content"].add_child(UI.label(f["description"]))
	c["content"].add_child(UI.label("Relation: %d / %d" % [rel, f["joinRelation"]]))
	c["content"].add_child(UI.bar(rel, f["joinRelation"]))

	if faction_id == "guild":
		c["content"].add_child(UI.button("Guild Marketplace", func(): Nav.go_to("guild_marketplace")))

	if state["joined"]:
		var member_label := UI.button("✅ Member", func(): pass)
		member_label.disabled = true
		c["content"].add_child(member_label)
	elif faction_id == "collective":
		pass
	elif Factions.can_join(faction_id):
		c["content"].add_child(UI.button("Join %s" % f["name"], func(): Factions.join(faction_id)))
	else:
		var locked := UI.button("Need %d more relation" % (f["joinRelation"] - rel), func(): pass)
		locked.disabled = true
		c["content"].add_child(locked)

	return c["panel"]
