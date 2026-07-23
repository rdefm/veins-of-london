class_name UI
extends RefCounted

# Small shared helpers so screens stay compact and consistent. Godot
# Controls built via code, matching the rest of the T11/T12 UI shell.


# Control.set_anchors_preset(), called with its default keep_offsets, does
# NOT reset offset_right/offset_bottom to 0 for a node whose parent already
# has a resolved size (true everywhere in this project — every node here
# is built inside an already-running, already-sized tree). Instead it
# recomputes them to preserve the control's pre-existing (zero) rect under
# the new anchors, which pins offset_right/offset_bottom at -parent_size
# and collapses the control to 0x0. These wrappers set the anchors and
# then force the offsets to the values the preset is actually supposed to
# produce, so every screen/component gets a real, non-collapsed rect.
static func anchor_full_rect(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0


static func anchor_top_wide(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_WIDE)
	control.offset_left = 0
	control.offset_right = 0
	control.offset_top = 0
	control.offset_bottom = 0


# Left/right offsets are zeroed (full width); top/bottom are left for the
# caller to set afterward (e.g. a fixed bar height above the bottom edge).
static func anchor_bottom_wide(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	control.offset_left = 0
	control.offset_right = 0


# Centres a shrink-to-fit control (one sized by its children, e.g. a
# PanelContainer or VBoxContainer) regardless of parent-size timing: zero
# offsets pin the control's anchor point at the parent's centre, and
# GROW_DIRECTION_BOTH lets it expand symmetrically from that point to its
# own minimum size instead of hanging off one corner.
static func anchor_center(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_CENTER)
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0
	control.grow_horizontal = Control.GROW_DIRECTION_BOTH
	control.grow_vertical = Control.GROW_DIRECTION_BOTH


static func vbox(sep: int = 8) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", sep)
	return box


static func hbox(sep: int = 8) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", sep)
	return box


# A themed "card" panel (uses the Panel style from main_theme.tres) with
# a VBoxContainer inside it, ready for content.
static func card() -> Dictionary:
	var panel := PanelContainer.new()
	var content := vbox(6)
	panel.add_child(content)
	return { "panel": panel, "content": content }


static func heading(text: String, size: int = 20) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	return label


static func label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func muted_label(text: String) -> Label:
	var l := label(text)
	l.add_theme_color_override("font_color", Color(0.541176, 0.541176, 0.541176, 1))
	return l


static func button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	return b


static func back_button(target_screen: String) -> Button:
	return button("‹ Back", func(): Nav.go_to(target_screen))


static func bar(value: float, max_value: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0
	b.max_value = max(max_value, 0.0001)
	b.value = value
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 8)
	return b


static func scroll_container() -> ScrollContainer:
	var sc := ScrollContainer.new()
	anchor_full_rect(sc)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return sc


# Standard screen skeleton: full-rect ScrollContainer > margin > VBoxContainer.
# Returns the VBoxContainer to add content to; caller adds the returned
# root Control as the screen's only top-level child.
static func screen_body(root: Control) -> VBoxContainer:
	var sc := scroll_container()
	root.add_child(sc)

	var margin := MarginContainer.new()
	# Anchors are ignored for a ScrollContainer's child — it sizes that
	# child itself. Without SIZE_EXPAND here, it shrinks the margin (and
	# everything inside it) down to its content's minimum width instead of
	# stretching it to the screen width, which is disastrous for a
	# word-wrapped Label: its minimum width collapses to near 0, so it
	# wraps one character per line.
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 80)  # room above the nav bar
	sc.add_child(margin)

	var content := vbox(12)
	margin.add_child(content)
	return content
