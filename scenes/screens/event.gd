class_name EventScreen
extends Control

# Generic event screen driven by state.event (M0-T13). Cards accumulate
# in a bottom-anchored ScrollContainer so new ones push older ones up —
# this replaces the prototype's per-event screens and its scroll bug.
# Action bar (Continue, Rewind when available) is pinned below. event-images
# ticket 03: VN-mode events are the exception -- they have no separate
# action bar at all; Continue/Rewind/choice dock onto the VN text box
# itself (see _build_vn_controls_row()).
#
# ui-vision.md §11 (session 2026-09-12): recoloured into the shared
# palette — no more private AMBER_COLOR/AMBER_BG/DANGER_COLOR constants.
# Tension borders wire to the shared MapStyle.DANGER_COLOUR, craft panels
# to the named calc_gold/calc_gold_light palette entries, and the action
# bar (Continue/Rewind/choice buttons) recolours to ui_action_red via the
# same tinted-fill/accent-text treatment modal_layer.gd's Family 4 "Train"
# button already established (a low-alpha accent wash, not Family 2's
# solid-fill-plus-light-text).

const IMAGE_SLOT_HEIGHT := 170.0

const _ACTION_COLOR_FALLBACK := Color("#c8102e")
const _CALC_GOLD_FALLBACK := Color("#d4af52")
const _CALC_GOLD_LIGHT_FALLBACK := Color("#f2dfa0")
# theme/main_theme.tres' own Label/Button font_color -- not a §6 accent, so
# there's no named data/palette.json entry to look up (only the accent
# colours this ticket names are wired to the shared palette).
const _INK_COLOR := Color(0.101961, 0.101961, 0.101961, 1)

var _scroll: ScrollContainer
var _cards_box: VBoxContainer
var _action_bar: HBoxContainer
var _image_frame: PanelContainer
var _image_texture: TextureRect

# event-images ticket 02: VN mode is decided once in _ready() (Events.
# is_vn_mode() reads the static event definition, not revealed-so-far
# cards) and never revisited for the life of this screen -- the mode must
# not flip mid-event. VN mode builds a completely separate node set
# (_vn_frame/_vn_texture/_vn_card_box) instead of _image_frame/_cards_box,
# so the non-VN path below is untouched byte-for-byte.
var _vn_mode: bool = false
var _vn_frame: Control
var _vn_texture: TextureRect
var _vn_card_box: VBoxContainer
var _vn_card_panel: PanelContainer


func _ready() -> void:
	UI.anchor_full_rect(self)

	_vn_mode = Events.is_vn_mode()

	if _vn_mode:
		_vn_frame = _build_vn_frame()
		add_child(_vn_frame)
	else:
		_image_frame = _build_image_frame()
		add_child(_image_frame)

		_scroll = UI.scroll_container()
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

		# event-images ticket 03: VN-mode retires this bar entirely -- its
		# Continue/Rewind/choice controls move onto the VN text box itself
		# (see _build_vn_controls_row()). Non-VN events keep it exactly as
		# before, so it's only ever built in this branch now; _action_bar
		# stays null for a VN-mode screen.
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

	if _vn_mode:
		_refresh_vn_frame()
		_refresh_vn_card()
		return

	for child in _action_bar.get_children():
		child.queue_free()

	for child in _cards_box.get_children():
		child.queue_free()
	for card in Events.revealed_cards():
		_cards_box.add_child(_build_card(card)["panel"])
	_refresh_image_slot()

	if Events.can_rewind():
		_action_bar.add_child(_build_rewind_button())

	if Events.is_awaiting_choice():
		var choices: Array = Events.current_card()["choices"]
		for i in range(choices.size()):
			_action_bar.add_child(_build_choice_button(choices[i]["label"], i))
	else:
		var continue_button := _build_continue_button("Continue →")
		continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_action_bar.add_child(continue_button)

	_scroll_to_bottom()


func _build_card(card: Dictionary) -> Dictionary:
	var c := UI.card()
	_style_card(c["panel"], card["type"])

	if card.get("label") != null:
		c["content"].add_child(UI.muted_label(card["label"]))

	match card["type"]:
		"speaker":
			c["content"].add_child(UI.heading(card["speaker"], 14))
			c["content"].add_child(UI.label(card["text"]))
		"choice":
			# ui-vision.md §11 bug fix: a choice card's optional speaker field
			# was silently dropped (fell into the plain default case below) --
			# render it the same way a "speaker" card does when present.
			if card.get("speaker") != null:
				c["content"].add_child(UI.heading(card["speaker"], 14))
			c["content"].add_child(UI.label(card["text"]))
		_:
			c["content"].add_child(UI.label(card["text"]))

	return c


# event-images ticket 03: shared by the non-VN action bar (_refresh()) and
# _build_vn_controls_row() so Rewind/choice/Continue construction and
# styling live in exactly one place each, instead of two near-identical
# copies. Callers still own layout concerns the two sites disagree on --
# SIZE_EXPAND_FILL on the non-VN Continue button, the VN Continue button's
# own bare-arrow label -- so those stay at the call site, not in here.
func _build_rewind_button() -> Button:
	var b := UI.button("⟲ Rewind", func(): Events.rewind())
	_style_action_button(b)
	return b


func _build_choice_button(label: String, choice_index: int) -> Button:
	var b := UI.button(label, func(): Events.choose(choice_index))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(b)
	return b


func _build_continue_button(text: String) -> Button:
	var b := UI.button(text, func(): Events.advance())
	_style_action_button(b)
	return b


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
		# Cream fill kept; only the border carries the danger accent now --
		# the old tinted-cream AMBER_BG-style fill is dropped (§11).
		box.bg_color = Color(0.980392, 0.972549, 0.952941, 1)
		box.border_color = MapStyle.DANGER_COLOUR
	else:  # craft
		box.bg_color = _calc_gold_light()
		box.border_color = _calc_gold()

	panel.add_theme_stylebox_override("panel", box)


func _calc_gold() -> Color:
	return GameData.PALETTE.get("calc_gold", _CALC_GOLD_FALLBACK)


func _calc_gold_light() -> Color:
	return GameData.PALETTE.get("calc_gold_light", _CALC_GOLD_LIGHT_FALLBACK)


func _action_color() -> Color:
	return GameData.PALETTE.get("ui_action_red", _ACTION_COLOR_FALLBACK)


# ui-vision.md §11: "all three recolour from the theme's default amber
# button fill to ui_action_red" -- accent wash carried by the text, same
# shape as modal_layer.gd's own _style_action_button()/_action_button_style()
# (the Family 4 "Train" button precedent). Padding here matches this
# screen's own pre-existing button size (theme/main_theme.tres' 16/10
# margins) rather than copying modal_layer.gd's smaller 8/6 verbatim, so
# Continue/Rewind/choice keep their prior footprint -- only the colour
# changes.
#
# Bugfixes ticket 105: unlike Train (flat-at-rest by design, left alone),
# these are the screen's only bottom-of-screen action buttons and read as
# plain coloured text with nothing to fill/hover states. Normal now carries
# a visible border plus a faint fill so they read as buttons at rest; hover/
# pressed still step the fill up from there. Disabled keeps a fainter
# border/fill so an unavailable action still reads as a button, just a
# muted one.
func _style_action_button(b: Button) -> void:
	var accent := _action_color()
	b.add_theme_stylebox_override("normal", _action_button_style(accent, 0.12, 1.0))
	b.add_theme_stylebox_override("hover", _action_button_style(accent, 0.20, 1.0))
	b.add_theme_stylebox_override("pressed", _action_button_style(accent, 0.30, 1.0))
	b.add_theme_stylebox_override("disabled", _action_button_style(accent, 0.05, 0.4))
	b.add_theme_color_override("font_color", accent)
	b.add_theme_color_override("font_hover_color", accent)
	b.add_theme_color_override("font_pressed_color", accent)
	b.add_theme_color_override("font_disabled_color", accent)


func _action_button_style(accent: Color, fill_alpha: float, border_alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, fill_alpha)
	style.set_corner_radius_all(8)
	style.set_border_width_all(1.5)
	style.border_color = Color(accent.r, accent.g, accent.b, border_alpha)
	style.content_margin_left = 16.0
	style.content_margin_top = 10.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 10.0
	return style


# ui-vision.md §11 "New: persistent event image slot" -- a fixed,
# non-scrolling region between the persistent top bar and the scrollable
# entry stack. Built once here; _refresh_image_slot() below toggles its
# visibility/texture/height on every rebuild.
func _build_image_frame() -> PanelContainer:
	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_TOP_WIDE)
	frame.offset_left = 16
	frame.offset_right = -16
	frame.offset_top = UI.top_bar_clearance()
	frame.offset_bottom = UI.top_bar_clearance()  # zero height until an image is shown
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_contents = true
	frame.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = _INK_COLOR
	frame.add_theme_stylebox_override("panel", style)

	_image_texture = TextureRect.new()
	_image_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	frame.add_child(_image_texture)

	return frame


func _refresh_image_slot() -> void:
	var image_path: Variant = Events.current_image_path()
	var showing: bool = image_path != null and typeof(image_path) == TYPE_STRING and ResourceLoader.exists(image_path)

	if showing:
		_image_texture.texture = load(image_path)
	else:
		_image_texture.texture = null

	_image_frame.visible = showing
	# Re-derive top_bar_clearance() here instead of reading back
	# _image_frame.offset_top (baked in once by _build_image_frame(), never
	# revisited) -- same fix as top_bar.gd's own _apply_safe_area_offsets():
	# a value read once at construction can go stale relative to TopBar's
	# now-self-correcting one, and this runs on every _refresh() (every
	# card advance) rather than once per event, so it's essentially free.
	var top: float = UI.top_bar_clearance()
	_image_frame.offset_top = top
	_image_frame.offset_bottom = top + IMAGE_SLOT_HEIGHT if showing else top
	_scroll.offset_top = top + (IMAGE_SLOT_HEIGHT if showing else 0.0)


# event-images ticket 02: VN mode's full-bleed portrait frame, built once
# in _ready() alongside the non-VN _image_frame/_scroll/_cards_box path
# (never both). Full width, no side margins (unlike the small slot's 16px
# gutters) -- ART-BIBLE §3's "VN portrait" row is the nominal 390 x 748
# canvas this collapses to at the baseline viewport with no safe-area
# insets. Two full-rect children layered inside a plain (non-Panel)
# Control so the overlay text box can float over the image rather than
# push it aside: the TextureRect fills the frame edge to edge, and
# _vn_card_box (a VBoxContainer with ALIGNMENT_END) sizes itself to
# exactly its one child's minimum height and pins it to the bottom of the
# frame, the same "shrink to content, anchor to an edge" trick used
# everywhere else a Godot 4 overlay needs content-driven height without
# hand-rolled offset math.
func _build_vn_frame() -> Control:
	var frame := Control.new()
	UI.anchor_full_rect(frame)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_contents = true

	_vn_texture = TextureRect.new()
	UI.anchor_full_rect(_vn_texture)
	_vn_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vn_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vn_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	frame.add_child(_vn_texture)

	_vn_card_box = UI.vbox(0)
	UI.anchor_full_rect(_vn_card_box)
	_vn_card_box.alignment = BoxContainer.ALIGNMENT_END
	_vn_card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_vn_card_box)

	return frame


# Re-derives the frame's vertical extent every refresh, same staleness fix
# as _refresh_image_slot()'s own top_bar_clearance() re-read. event-images
# ticket 03: VN mode no longer leaves room for a separate bottom action bar
# (Continue/Rewind/choice now dock onto the text box itself, in
# _build_vn_controls_row()) -- the portrait frame runs all the way down to
# the safe-area inset, with the same -8px clearance the old action bar kept
# off the screen edge, and _vn_card_box's own ALIGNMENT_END plus its 16px
# margin (_refresh_vn_card()) is what keeps the floating box off that floor.
func _refresh_vn_frame() -> void:
	var top: float = UI.top_bar_clearance()
	var bottom_inset: float = UI.safe_area_bottom_inset()
	_vn_frame.offset_top = top
	_vn_frame.offset_bottom = -8.0 - bottom_inset


# Shows exactly the most-recently-revealed card (the same "last entry" the
# non-VN stack would have pushed to the bottom) -- after a choose(), that's
# the synthetic resolution card, matching what the player would see appear
# next in the accumulating layout. Rebuilt from scratch each refresh via
# _build_card() (same per-card-type accent as the scrolling stack, since
# _build_card() already calls _style_card()), so no prior card's content
# ever lingers in the tree.
func _refresh_vn_card() -> void:
	for child in _vn_card_box.get_children():
		child.queue_free()

	var image_path: Variant = Events.current_image_path()
	var showing: bool = image_path != null and typeof(image_path) == TYPE_STRING and ResourceLoader.exists(image_path)
	_vn_texture.texture = load(image_path) if showing else null

	var card: Dictionary = Events.revealed_cards().back()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	var built := _build_card(card)
	_vn_card_panel = built["panel"]
	built["content"].add_child(_build_vn_controls_row())
	margin.add_child(_vn_card_panel)
	_vn_card_box.add_child(margin)


# event-images ticket 03: VN mode's replacement for the old bottom action
# bar -- Continue/Rewind/choice dock onto the current card's own box instead
# of a separate HBoxContainer beneath it. Rewind (when offered) sits at the
# row's left; Continue is the lone right-aligned arrow glyph the approved
# mockup calls for, pushed into the box's bottom-right corner by the
# trailing spacer. Awaiting a choice replaces the spacer+arrow with the
# choice buttons themselves (Rewind, if also offered, still leads the row) --
# same mutual exclusion the old action bar enforced between Continue and
# choice buttons.
func _build_vn_controls_row() -> HBoxContainer:
	var row := UI.hbox(8)

	if Events.can_rewind():
		row.add_child(_build_rewind_button())

	if Events.is_awaiting_choice():
		var choices: Array = Events.current_card()["choices"]
		for i in range(choices.size()):
			row.add_child(_build_choice_button(choices[i]["label"], i))
	else:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		row.add_child(_build_continue_button("→"))

	return row


func _scroll_to_bottom() -> void:
	# Guards a screen instantiated off-tree (tests/test_event_screen.gd's own
	# EventScreen.new() + _ready() pattern, matching every other screen
	# test's convention) -- get_tree() is null there, and this only ever
	# needs a real frame to let a live ScrollContainer's own deferred layout
	# pass catch up, which off-tree has nothing to wait on anyway.
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_instance_valid(_scroll):
		return
	var vscroll := _scroll.get_v_scroll_bar()
	_scroll.scroll_vertical = int(vscroll.max_value)
