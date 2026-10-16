# Conversation index and single-conversation view. Detail mounts its own full-height root on the shell
# (the shared scroll body is hidden) so the action bar sits below a
# scrolling thread; messages unread when the conversation was opened are
# revealed one bubble at a time, each incoming one after a three-dot typing
# bubble (ui-vision.md §10 Messages row) that a tap on the thread skips.
class_name MessagesApp
extends PhoneApp

const ROW_HEIGHT := 64.0
const _PILL_SIZE := 22.0
const _THEME: Theme = preload("res://theme/main_theme.tres")
const _TYPING_DOT_PULSE := 0.25
const _TYPING_DOT_DIM := 0.3
const _TAP_SLOP := 12.0

var _reveal_from_index: Dictionary = {}
var _conversation_root: Control = null
var _bold: FontVariation = null
var _skip_wait := false
var _tap_origin: Vector2 = Vector2.INF


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
	var b := TapButton.new()
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
	scroll.gui_input.connect(_on_thread_input)

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
		if not _alive(box):
			return
		var from_player: bool = thread[i]["from"] == "player"
		if not from_player:
			var typing := _typing_bubble()
			box.add_child(typing)
			ContactCards.apply_phone_os_chrome(typing)
			_animate_typing_dots(typing)
			await _skippable_wait(Messages.typing_seconds(thread[i]["text"]))
			if not _alive(box):
				return
			box.remove_child(typing)
			typing.queue_free()
		var bubble := UI.message_bubble(thread[i]["text"], from_player)
		box.add_child(bubble)
		ContactCards.apply_phone_os_chrome(bubble)


func _alive(box: VBoxContainer) -> bool:
	return is_instance_valid(shell) and is_instance_valid(box) and box.is_inside_tree()


# Waits `seconds`, or until a tap on the thread sets _skip_wait.
func _skippable_wait(seconds: float) -> void:
	_skip_wait = false
	var end_msec := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end_msec and not _skip_wait:
		if not is_instance_valid(shell) or not shell.is_inside_tree():
			return
		await shell.get_tree().process_frame


# A tap (press and release without dragging past _TAP_SLOP) skips the
# current typing wait; a scroll drag doesn't.
func _on_thread_input(event: InputEvent) -> void:
	var pressed: bool
	var pos: Vector2
	if event is InputEventScreenTouch:
		pressed = event.pressed
		pos = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		pos = event.position
	else:
		return
	if pressed:
		_tap_origin = pos
	elif _tap_origin != Vector2.INF and pos.distance_to(_tap_origin) <= _TAP_SLOP:
		_skip_wait = true
		_tap_origin = Vector2.INF


# An incoming-side bubble holding three dots; apply_phone_os_chrome gives it
# the incoming fill like any other left-aligned bubble.
func _typing_bubble() -> Control:
	var row := UI.hbox()
	var bubble := UI.card()
	var dots := UI.hbox(4)
	dots.name = "TypingDots"
	for _n in range(3):
		var dot := Label.new()
		dot.text = "●"
		dot.add_theme_color_override("font_color", ContactCards.phone_colour("muted"))
		dot.modulate.a = _TYPING_DOT_DIM
		dots.add_child(dot)
	bubble["content"].add_child(dots)
	row.add_child(bubble["panel"])
	return row


# Each dot brightens and dims in turn, looping until the bubble is freed.
func _animate_typing_dots(typing: Control) -> void:
	var dots := typing.find_child("TypingDots", true, false)
	var tween := typing.create_tween().set_loops()
	for dot in dots.get_children():
		tween.tween_property(dot, "modulate:a", 1.0, _TYPING_DOT_PULSE)
		tween.tween_property(dot, "modulate:a", _TYPING_DOT_DIM, _TYPING_DOT_PULSE)


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
	var replies := ContactTexts.active_replies(contact_id)
	for i in range(replies.size()):
		bar.add_child(UI.button(replies[i], ContactTexts.reply.bind(contact_id, i)))
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
