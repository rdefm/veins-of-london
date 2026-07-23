class_name SmsArchieScreen
extends Control

# SMS thread 1 (ARCHIE_SMS_1): sets up the James meeting. Staged reveal
# per T12's deferral note — await get_tree().create_timer(...).timeout in
# the screen, 0.6/0.9s alternating delays. The reveal counter is
# screen-local presentation state, not game state.

const THREAD_ID := "archie_1"
const NEXT_EVENT_ID := "james_meeting"

var _messages_box: VBoxContainer
var _action_bar: VBoxContainer
var _messages: Array
var _revealed := 0


func _ready() -> void:
	UI.anchor_full_rect(self)
	_messages = GameData.SMS_THREADS[THREAD_ID]

	var root := UI.vbox(0)
	UI.anchor_full_rect(root)
	add_child(root)

	var scroll := UI.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)

	_messages_box = UI.vbox(8)
	margin.add_child(_messages_box)

	_action_bar = UI.vbox(8)
	root.add_child(_action_bar)

	_reveal_next()


func _reveal_next() -> void:
	if _revealed >= _messages.size():
		_show_continue()
		return

	var msg: Dictionary = _messages[_revealed]
	var row := UI.hbox()
	if msg["from"] == "player":
		row.alignment = BoxContainer.ALIGNMENT_END
	var bubble := UI.card()
	bubble["content"].add_child(UI.label(msg["text"]))
	row.add_child(bubble["panel"])
	_messages_box.add_child(row)
	_revealed += 1

	var delay: float = 0.9 if _revealed % 2 == 0 else 0.6
	await get_tree().create_timer(delay).timeout
	_reveal_next()


func _show_continue() -> void:
	_action_bar.add_child(UI.button("Continue →", func(): Events.start_event(NEXT_EVENT_ID)))
