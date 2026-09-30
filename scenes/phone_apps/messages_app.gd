# Conversation index and single-conversation view. Detail mounts its own full-height root on the shell
# (the shared scroll body is hidden) so the action bar sits below a
# scrolling thread; messages unread when the conversation was opened are
# revealed one bubble at a time.
class_name MessagesApp
extends PhoneApp

const ROW_HEIGHT := 64.0
const _PILL_SIZE := 22.0
const _THEME: Theme = preload("res://theme/main_theme.tres")

var _reveal_from_index: Dictionary = {}
var _conversation_root: Control = null
var _bold: FontVariation = null


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


# Inbox row (ui-vision.md §10 list/detail pattern): fixed height, bold name
# over a one-line preview cut with `…`, unread pill, hairline divider; the
# Clear button sits outside the tap target and only shows when there's
# something to clear.
func _build_conversation_row(contact_id: String) -> Control:
	var wrapper := UI.vbox(0)
	var row := UI.hbox(8)
	row.custom_minimum_size.y = ROW_HEIGHT
	wrapper.add_child(row)

	var open := _plain_button(PhoneNav.select_conversation.bind(contact_id))
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open.custom_minimum_size.y = ROW_HEIGHT
	open.clip_contents = true
	row.add_child(open)

	var content := UI.hbox(8)
	UI.anchor_full_rect(content)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	open.add_child(content)
	var copy := UI.vbox(2)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_line(Contacts.display_name(contact_id), ContactCards.phone_colour("text"), _bold_font()))
	copy.add_child(_line(Messages.latest_preview(contact_id).replace("\n", " "), ContactCards.phone_colour("muted")))
	content.add_child(copy)
	var unread := Messages.unread_count(contact_id)
	if unread > 0:
		content.add_child(_unread_pill(unread))

	if Messages.can_clear(contact_id):
		var clear := _plain_button(Messages.clear.bind(contact_id))
		clear.text = "Clear"
		clear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			clear.add_theme_color_override(key, ContactCards.phone_colour("action"))
		row.add_child(clear)

	var divider := ColorRect.new()
	divider.custom_minimum_size.y = 1
	divider.color = ContactCards.phone_colour("divider")
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(divider)
	return wrapper


func _plain_button(callback: Callable) -> Button:
	var b := Button.new()
	b.pressed.connect(callback)
	b.set_meta(ContactCards.OWN_STYLE_META, true)
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 8
	empty.content_margin_right = 8
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, empty)
	return b


# One line of text, cut with `…` rather than wrapped or widening the row.
func _line(text: String, colour: Color, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.max_lines_visible = 1
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", colour)
	if font != null:
		l.add_theme_font_override("font", font)
	return l


func _unread_pill(count: int) -> Label:
	var pill := Label.new()
	pill.text = str(count)
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.custom_minimum_size = Vector2(_PILL_SIZE, _PILL_SIZE)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = AppTile.BADGE_COLOUR
	style.set_corner_radius_all(int(_PILL_SIZE / 2))
	style.content_margin_left = 6
	style.content_margin_right = 6
	pill.add_theme_stylebox_override("normal", style)
	pill.add_theme_color_override("font_color", ContactCards.phone_colour("text"))
	pill.add_theme_font_size_override("font_size", 12)
	return pill


# The theme's UI sans, emboldened, for the contact name.
func _bold_font() -> Font:
	if _bold == null:
		_bold = FontVariation.new()
		var base: Font = _THEME.get_font("font", "Label")
		_bold.base_font = base if base != null else ThemeDB.fallback_font
		_bold.variation_embolden = 0.8
	return _bold


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
	# Opens on the newest message and follows each revealed bubble down.
	var v_bar := scroll.get_v_scroll_bar()
	v_bar.changed.connect(func(): scroll.scroll_vertical = int(v_bar.max_value))

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
		var ledger_action := ContactCards.build_nadia_ledger_action()
		if ledger_action != null:
			bar.add_child(ledger_action)
		var handler_meet_action := ContactCards.build_handler_meet_action()
		if handler_meet_action != null:
			bar.add_child(handler_meet_action)
	if contact_id == ContactCards.HANDLER_ID:
		for action in ContactCards.build_handler_actions():
			bar.add_child(action)
	if contact_id == OwenTexts.CONTACT_ID:
		var replies := OwenTexts.active_replies()
		for i in range(replies.size()):
			bar.add_child(UI.button(replies[i], OwenTexts.reply.bind(i)))
	for entry in Messages.pending_for(contact_id):
		for action in ContactCards.build_pending_actions(entry, _on_pending_action_pressed):
			bar.add_child(action)
	if contact_id == "archie":
		bar.add_child(ContactCards.build_sell_action())
	elif contact_id != "james" and contact_id != ContactCards.HANDLER_ID:
		bar.add_child(ContactCards.build_trade_action(contact_id))
	return bar


func _on_pending_action_pressed(entry: Dictionary) -> void:
	Messages.resolve_pending(entry["id"])
	Events.start_event(entry["kind"], entry["payload"])
