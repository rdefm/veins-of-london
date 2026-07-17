class_name ContactsScreen
extends Control

# Actions gated by flags per R§3.11. The HTML's version routes several
# actions to dedicated per-event screens (event_buyer, event_archie_
# motion, ...) that don't exist under R§2.2 — T13 replaces those with
# one generic "event" screen driven by state.event, so those actions
# route to Nav.go_to("event") here for now (a placeholder until T13
# actually starts an event on that screen).


var _content: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.back_button("home"))
	_content.add_child(UI.heading("Contacts"))

	_content.add_child(_build_archie_card())

	if GameState.state["contacts"]["james"]["unlocked"]:
		_content.add_child(_build_james_card())


func _build_archie_card() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	var world: Dictionary = GameState.state["world"]
	var archie: Dictionary = GameState.state["contacts"]["archie"]

	var c := UI.card()
	c["content"].add_child(UI.heading("Archie — Relation %d" % archie["relation"], 15))
	c["content"].add_child(UI.muted_label("Trader · Whitechapel"))

	if flags["archieMotionPending"] and not flags["archieMotionEventSeen"]:
		c["content"].add_child(UI.button("💬 Archie texted — diversify", func(): Nav.go_to("event")))

	if flags["tutorialStage"] == "archie_craft_chat" and not flags["archieCraftChatSeen"]:
		c["content"].add_child(UI.button("💬 Archie wants to meet", func(): Nav.go_to("event")))

	if flags["tutorialStage"] == "buyer_event" and not flags["buyerEventSeen"] and world["day"] >= 2:
		c["content"].add_child(UI.button("💬 Archie texted — buyer tonight", func(): Nav.go_to("sms_archie_2")))

	if flags["tutorialStage"] == "sms_archie":
		c["content"].add_child(UI.button("💬 Message Archie — set up James meeting", func(): Nav.go_to("sms_archie")))

	c["content"].add_child(_build_sell_action())
	c["content"].add_child(_build_recruit_row("archie"))

	return c["panel"]


func _build_sell_action() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	var player: Dictionary = GameState.state["player"]

	if not flags["buyerEventSeen"]:
		var locked := UI.button("💰 Find a buyer (not unlocked yet)", func(): pass)
		locked.disabled = true
		return locked

	var has_ore := false
	for qty in player["orichalchum"].values():
		if qty > 0:
			has_ore = true
			break
	var has_consumables := flags["canSellConsumables"] and (player["inventory"]["timePearl"] > 0 or player["inventory"]["enhancementPowder"] > 0)
	var has_sellable: bool = has_ore or has_consumables

	var b := UI.button("💰 Find a buyer" if has_sellable else "💰 Find a buyer (nothing to sell)", func(): Modal.open("sell_menu"))
	b.disabled = not has_sellable
	return b


func _build_recruit_row(contact_id: String) -> Control:
	var c: Dictionary = GameState.state["contacts"][contact_id]
	var display_name: String = Contacts.display_name(contact_id)

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


func _build_james_card() -> Control:
	var flags: Dictionary = GameState.state["flags"]
	var james: Dictionary = GameState.state["contacts"]["james"]

	var c := UI.card()
	c["content"].add_child(UI.heading("James — Relation %d" % james["relation"], 15))
	c["content"].add_child(UI.muted_label("Craftsman · Bermondsey"))

	if flags["archieMotionEventSeen"] and not flags["jamesMotionEventSeen"]:
		c["content"].add_child(UI.button("💬 Visit James — ask about new recipes", func(): Nav.go_to("event")))

	if flags["jamesMotionEventSeen"]:
		var job_active: bool = flags["jamesJobActive"] and GameState.state["jamesJob"] != null
		if job_active:
			var job: Dictionary = GameState.state["jamesJob"]
			c["content"].add_child(UI.button("📦 Deliver job: %d× %s %s" % [job["qty"], job["symbol"], job["recipeName"]], func(): Jobs.fulfil_job()))
		else:
			c["content"].add_child(UI.button("📋 Ask James for work", func(): Jobs.offer_job()))

	c["content"].add_child(_build_recruit_row("james"))

	return c["panel"]
