# Conversation index and single-conversation view. Detail mounts its own full-height root on the shell
# (the shared scroll body is hidden) so the action bar sits below a
# scrolling thread; messages unread when the conversation was opened are
# revealed one bubble at a time.
class_name MessagesApp
extends PhoneApp

var _reveal_from_index: Dictionary = {}
var _conversation_root: Control = null


func build(content: VBoxContainer) -> void:
	var contact_id: Variant = GameState.state["phoneNav"]["selectedContactId"]
	if contact_id == null:
		_build_index(content)
		return
	if not _reveal_from_index.has(contact_id):
		var reveal_from_index = GameState.state["phoneNav"].get("revealFromIndex")
		_reveal_from_index[contact_id] = reveal_from_index if reveal_from_index != null else 0
	_build_conversation(content, contact_id)


func _build_index(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Messages"))
	var ids := Messages.conversation_ids()
	if ids.is_empty():
		# PROSE-REVIEW: new Messages empty-state copy.
		content.add_child(UI.muted_label("No conversations yet."))
		return
	for contact_id in ids:
		content.add_child(_build_conversation_row(contact_id))


func _build_conversation_row(contact_id: String) -> Control:
	var button := Button.new()
	button.custom_minimum_size.y = 64
	button.pressed.connect(PhoneNav.select_conversation.bind(contact_id))
	var row := UI.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var copy := UI.vbox(2)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(UI.label(Contacts.display_name(contact_id)))
	copy.add_child(UI.muted_label(Messages.latest_preview(contact_id)))
	row.add_child(copy)
	var unread := Messages.unread_count(contact_id)
	if unread > 0:
		row.add_child(UI.label(str(unread)))
	button.add_child(row)
	return button


func teardown() -> void:
	if _conversation_root != null:
		_conversation_root.queue_free()
		_conversation_root = null


func _build_conversation(content: VBoxContainer, contact_id: String) -> void:
	_conversation_root = UI.vbox(0)
	shell.mount_custom_root(_conversation_root)

	var header := UI.hbox()
	header.add_child(UI.button("‹ Back", PhoneNav.back_to_messages))
	header.add_child(UI.heading(Contacts.display_name(contact_id)))
	_conversation_root.add_child(header)

	var scroll := UI.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_conversation_root.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)

	var box := UI.vbox(8)
	margin.add_child(box)

	var thread: Array = GameState.state["messages"].get(contact_id, [])
	var reveal_from: int = mini(_reveal_from_index.get(contact_id, thread.size()), thread.size())
	for i in range(reveal_from):
		box.add_child(UI.message_bubble(thread[i]["text"], thread[i]["from"] == "player"))

	_conversation_root.add_child(_build_action_bar(contact_id))
	ContactCards.apply_phone_os_chrome(_conversation_root)

	if reveal_from < thread.size():
		_reveal_from_index[contact_id] = thread.size()
		if shell.is_inside_tree():
			_reveal_remaining(box, thread, reveal_from)
		else:
			for i in range(reveal_from, thread.size()):
				box.add_child(UI.message_bubble(thread[i]["text"], thread[i]["from"] == "player"))


func _reveal_remaining(box: VBoxContainer, thread: Array, start_index: int) -> void:
	for i in range(start_index, thread.size()):
		if not is_instance_valid(shell) or not is_instance_valid(box):
			return
		var bubble := UI.message_bubble(thread[i]["text"], thread[i]["from"] == "player")
		box.add_child(bubble)
		ContactCards.apply_phone_os_chrome(bubble)
		var delay: float = 0.9 if (i - start_index) % 2 == 0 else 0.6
		await shell.get_tree().create_timer(delay).timeout


func _build_action_bar(contact_id: String) -> Control:
	var bar := UI.vbox(8)
	for shortcut in ContactCards.build_pin_shortcut_actions(contact_id):
		bar.add_child(shortcut)
	if contact_id == "archie":
		var pry_action := ContactCards.build_archie_pry_action()
		if pry_action != null:
			bar.add_child(pry_action)
	if contact_id == "des":
		var report_action := ContactCards.build_des_report_action()
		if report_action != null:
			bar.add_child(report_action)
		var ask_joining_action := ContactCards.build_ask_des_joining_action()
		if ask_joining_action != null:
			bar.add_child(ask_joining_action)
	if contact_id == "nadia":
		var meet_action := ContactCards.build_nadia_meet_action()
		if meet_action != null:
			bar.add_child(meet_action)
		var vein_ask_action := ContactCards.build_nadia_vein_ask_action()
		if vein_ask_action != null:
			bar.add_child(vein_ask_action)
		var supply_action := ContactCards.build_nadia_supply_action()
		if supply_action != null:
			bar.add_child(supply_action)
	if contact_id == "hakim":
		var hakim_done_action := ContactCards.build_hakim_done_action()
		if hakim_done_action != null:
			bar.add_child(hakim_done_action)
	if contact_id == "nadia":
		var handler_meet_action := ContactCards.build_handler_meet_action()
		if handler_meet_action != null:
			bar.add_child(handler_meet_action)
	if contact_id == ContactCards.HANDLER_ID:
		for action in ContactCards.build_handler_actions():
			bar.add_child(action)
	for entry in Messages.pending_for(contact_id):
		bar.add_child(UI.button("Continue →", _on_pending_action_pressed.bind(entry)))
	if contact_id == "archie":
		bar.add_child(ContactCards.build_sell_action())
	elif contact_id != "james" and contact_id != ContactCards.HANDLER_ID:
		bar.add_child(ContactCards.build_trade_action(contact_id))
	return bar


func _on_pending_action_pressed(entry: Dictionary) -> void:
	Messages.resolve_pending(entry["id"])
	Events.start_event(entry["kind"], entry["payload"])
