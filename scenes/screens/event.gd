class_name EventScreen
extends Control

# Generic event screen driven by state.event (M0-T13). Cards accumulate
# in a bottom-anchored ScrollContainer so new ones push older ones up —
# this replaces the prototype's per-event screens and its scroll bug.
# Action bar (Continue, Rewind when available) is pinned below.

const DANGER_COLOR := Color(0.607843, 0.137255, 0.207843, 1)
const AMBER_COLOR := Color(0.784314, 0.529412, 0.227451, 1)
const AMBER_BG := Color(0.980392, 0.945098, 0.882353, 1)

var _scroll: ScrollContainer
var _cards_box: VBoxContainer
var _action_bar: HBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)

	_scroll = UI.scroll_container()
	_scroll.offset_top = TopBar.BAR_HEIGHT  # clears the persistent top bar — visible mid-event per D4.4
	_scroll.offset_bottom = -64
	add_child(_scroll)

	var margin := MarginContainer.new()
	# See UI.screen_body()'s matching comment: a ScrollContainer sizes its
	# child itself (anchors are ignored), so SIZE_EXPAND is required here
	# or this shrinks to its word-wrapped content's minimum width.
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_scroll.add_child(margin)

	_cards_box = UI.vbox(10)
	margin.add_child(_cards_box)

	_action_bar = UI.hbox(8)
	_action_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_action_bar.offset_left = 16
	_action_bar.offset_right = -16
	# Bugfixes ticket 20: -8 alone pins this directly under the OS gesture-
	# nav bar on a notched/gesture-nav device, where Continue/Rewind/choice
	# buttons land underneath it and are untappable -- lift the whole bar
	# clear of that inset while keeping its own 48px height fixed.
	var bottom_inset := UI.safe_area_bottom_inset()
	_action_bar.offset_top = -56 - bottom_inset
	_action_bar.offset_bottom = -8 - bottom_inset
	add_child(_action_bar)

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if GameState.state["event"] == null:
		return  # on_complete already navigated away; this node is about to be freed

	for child in _cards_box.get_children():
		child.queue_free()
	for child in _action_bar.get_children():
		child.queue_free()

	for card in Events.revealed_cards():
		_cards_box.add_child(_build_card(card))

	if Events.can_rewind():
		_action_bar.add_child(UI.button("⟲ Rewind", func(): Events.rewind()))

	if Events.is_awaiting_choice():
		var choices: Array = Events.current_card()["choices"]
		for i in range(choices.size()):
			var choice_index := i
			var choice_button := UI.button(choices[i]["label"], func(): Events.choose(choice_index))
			choice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_action_bar.add_child(choice_button)
	else:
		var continue_button := UI.button("Continue →", func(): Events.advance())
		continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_action_bar.add_child(continue_button)

	_scroll_to_bottom()


func _build_card(card: Dictionary) -> Control:
	var c := UI.card()
	_style_card(c["panel"], card["type"])

	if card.get("label") != null:
		c["content"].add_child(UI.muted_label(card["label"]))

	match card["type"]:
		"speaker":
			c["content"].add_child(UI.heading(card["speaker"], 14))
			c["content"].add_child(UI.label(card["text"]))
		_:
			c["content"].add_child(UI.label(card["text"]))

	return c["panel"]


func _style_card(panel: PanelContainer, card_type: String) -> void:
	if card_type != "tension" and card_type != "craft":
		return

	var box := StyleBoxFlat.new()
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_right = 10
	box.corner_radius_bottom_left = 10
	box.content_margin_left = 16.0
	box.content_margin_top = 16.0
	box.content_margin_right = 16.0
	box.content_margin_bottom = 16.0
	box.border_width_left = 4

	if card_type == "tension":
		box.bg_color = Color(0.980392, 0.972549, 0.952941, 1)
		box.border_color = DANGER_COLOR
	else:  # craft
		box.bg_color = AMBER_BG
		box.border_color = AMBER_COLOR

	panel.add_theme_stylebox_override("panel", box)


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	if not is_instance_valid(_scroll):
		return
	var vscroll := _scroll.get_v_scroll_bar()
	_scroll.scroll_vertical = int(vscroll.max_value)
