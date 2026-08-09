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


# Full rect, clipped to the gap between the persistent TopBar and NavBar
# (both visible on any screen not in Main.gd's NAV_HIDDEN_SCREENS /
# TOP_BAR_HIDDEN_SCREENS lists). For a screen with its own bespoke layout
# (scroll region + a separately pinned action bar) where UI.screen_body()'s
# single-scroll skeleton doesn't fit — screen_body() solves the same
# clearance problem for the common case via margins instead of offsets.
# Anything anchored via bare anchor_full_rect() instead of this ends up
# with content flush against the screen edges, invisible/unreachable under
# whichever bar is drawn on top (scenes/screens/sms_archie.gd's/
# sms_archie_2.gd's Continue button did exactly this — bugfixes ticket 07).
static func anchor_below_bars(control: Control) -> void:
	anchor_full_rect(control)
	control.offset_top = TopBar.BAR_HEIGHT
	control.offset_bottom = -NavBar.BAR_HEIGHT


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


# Like hbox(), but wraps overflowing children onto additional lines instead
# of forcing them into one row that runs past the container's right edge
# (bugfixes ticket 05: the site sheet's charged-vein action row — Cultivate
# + Harvest cautious + Harvest full together are wider than a narrow phone
# screen). HFlowContainer uses separate h/v separation theme constants
# rather than HBoxContainer's single "separation".
static func hflow(sep: int = 8) -> HFlowContainer:
	var box := HFlowContainer.new()
	box.add_theme_constant_override("h_separation", sep)
	box.add_theme_constant_override("v_separation", sep)
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


# Flags a control SIZE_EXPAND_FILL before returning it, for the common
# one-liner `row.add_child(UI.expand_fill(UI.label(...)))` inside an
# HBoxContainer — see checklist_row()'s comment below for why a wrapping
# Label needs this in a horizontal row (collapses to one character per
# line otherwise).
static func expand_fill(control: Control) -> Control:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return control


# A label tinted with an arbitrary colour (e.g. a faction's data/factions.json
# "colour" hex string) — the swatch-via-font-colour approach the faction
# vein sheet (faction-vein-ownership T04) uses instead of a separate colour
# chip, since every faction colour is dark/saturated enough to stay legible
# as text on the panel's near-white background (theme/main_theme.tres).
static func tinted_label(text: String, colour: Color) -> Label:
	var l := label(text)
	l.add_theme_color_override("font_color", colour)
	return l


# Cap on the text-driven minimum width UI.button() will reserve (see below)
# -- bugfixes ticket 05's £1,000,000-balance blowout is still possible for
# any button whose text is genuinely this long; capping it, rather than
# letting clip_text drop the contribution to zero (bugfixes ticket 08's
# blank-button regression), keeps ordinary labels fully readable while still
# bounding the pathological case.
const MAX_BUTTON_TEXT_WIDTH := 220.0

const _THEME: Theme = preload("res://theme/main_theme.tres")


static func button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	# A Button's minimum_size grows to fit its full text by default, so one
	# long dynamic label (e.g. a cost string built from the player's cash)
	# can force every container up its parent chain wider than the screen --
	# none of which scroll horizontally, so the excess just overflows past
	# the right edge (bugfixes ticket 05: a debug £1,000,000 balance blew up
	# the site sheet's security-upgrade button this way, dragging the charge
	# bar, dev bar, and action row wide along with it even after those got
	# their own overflow fix). clip_text lets the surrounding layout's width
	# win instead.
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.pressed.connect(callback)

	# clip_text (above) makes Button.get_minimum_size() drop the text's width
	# contribution entirely, leaving only the style's content-margin padding.
	# That's invisible inside a plain HBoxContainer (bugfixes ticket 08):
	# a HBoxContainer gives a non-expand child exactly its minimum size, so
	# with no text-driven width left the button collapses to its padding
	# alone -- zero space remains for the label to draw into, so it reads as
	# fully blank rather than clipped-with-"...". Reserving the button's own
	# (capped) natural text width as custom_minimum_size restores real room
	# for the glyphs while still bounding runaway dynamic labels via the cap.
	# Fixing this once here (rather than per call site) covers every UI.hbox()
	# + UI.button() row in the project without needing to touch each one --
	# audited: combat.gd, event.gd, hq.gd, inventory.gd, map.gd, modal_layer.gd,
	# phone.gd, top_bar.gd, veins.gd, you.gd all build button rows this way.
	var style := _THEME.get_stylebox("normal", "Button")
	# main_theme.tres doesn't override Button's font, so it inherits the
	# engine's default -- get_font() returns null in that case, hence the
	# fallback (querying the theme first, rather than assuming the fallback
	# directly, keeps this correct if a themed Button font is ever added).
	var font: Font = _THEME.get_font("font", "Button")
	if font == null:
		font = ThemeDB.fallback_font
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _THEME.default_font_size).x
	b.custom_minimum_size.x = minf(text_width + style.get_minimum_size().x, MAX_BUTTON_TEXT_WIDTH)

	return b


static func back_button(target_screen: String) -> Button:
	return button("‹ Back", func(): Nav.go_to(target_screen))


# SMS chat-bubble row (sms_archie.gd / sms_archie_2.gd): a card-styled
# bubble, right-aligned for from_player. The label needs an explicit
# custom_minimum_size.x — an HBoxContainer row's non-expand child (the
# bubble panel) only ever gets ITS minimum size, and a word-wrapping
# Label's minimum size is near-zero by design (same failure mode
# checklist_row()/screen_body() work around) — without it, nothing in the
# Row -> Panel -> VBox -> Label chain ever hands the Label real width to
# wrap against, and it collapses to one word (or character) per line.
const BUBBLE_WIDTH := 260.0

static func message_bubble(text: String, from_player: bool) -> Control:
	var row := hbox()
	if from_player:
		row.alignment = BoxContainer.ALIGNMENT_END
	var bubble := card()
	var text_label := label(text)
	text_label.custom_minimum_size.x = BUBBLE_WIDTH
	bubble["content"].add_child(text_label)
	row.add_child(bubble["panel"])
	return row


# A checkbox glyph + wrapping text label, side by side (e.g. the to-do
# list — home's "Things to do" card, Phone's Notes app). The text label
# MUST get SIZE_EXPAND_FILL here: an HBoxContainer gives non-expand
# children exactly their own minimum size on its main axis, and a
# word-wrapped Label's minimum size is near-zero by design (it expects a
# parent to hand it real width) — without the flag it collapses to one
# character per line (same failure mode top_bar.gd's _day_label/_cash_label
# comment documents, seen in human QA on-device for this exact row).
static func checklist_row(text: String, done: bool) -> Control:
	var row := hbox(6)
	# label() turns on autowrap for every label it builds, including this
	# one-glyph checkbox — an autowrapping Label's minimum size collapses to
	# its longest unbreakable fragment, not its full content (same failure
	# mode top_bar.gd's _day_label/_cash_label comment documents), so
	# without this it renders as a ~1px column with the glyph overflowing
	# across the text label that follows it in this row. This is compact,
	# unwrappable single-glyph content, so turn wrapping off entirely
	# rather than guess a fixed pixel width.
	var check_label := label("☑" if done else "☐")
	check_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(check_label)
	var text_label := label(text)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if done:
		text_label.add_theme_color_override("font_color", Color(0.541176, 0.541176, 0.541176, 1))
	row.add_child(text_label)
	return row


static func bar(value: float, max_value: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0
	b.max_value = max(max_value, 0.0001)
	b.value = value
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 8)
	return b


# D4.4's shared cost-label helper. `cost` is { label:String, resource:String,
# amount:int } — `resource` is either "cash" or an ore-type id ("physics"
# etc.); `holdings` is the Dictionary to read the player's current amount
# from (player.orichalchum for ore, or a synthetic {"cash": player.cash} —
# see callers). Produces "Seed — 40 physics (have 52)" / "Bribe — £50 (have
# £210)" per D4.4's examples; every cost-gated button in the game routes its
# label through this so a player never has to open the bag drawer just to
# see if they can afford something.
static func format_cost_label(cost: Dictionary, holdings: Dictionary) -> String:
	var resource: String = cost.get("resource", "")
	var amount: int = cost.get("amount", 0)
	var have: int = holdings.get(resource, 0)

	var amount_text: String
	if resource == "cash":
		amount_text = "£%d (have £%d)" % [amount, have]
	else:
		amount_text = "%d %s (have %d)" % [amount, resource, have]

	var label: String = cost.get("label", "")
	if label == "":
		return amount_text
	return "%s — %s" % [label, amount_text]


# D3's block-cost label helper: the block cost of a districted action
# (prospect/seed/cultivate/harvest) — flat regardless of the target
# district since D3's travel surcharge was removed (faction-resource-economy
# ticket 05). Pure formatter over a pre-computed block count — same contract
# as format_cost_label above (cost in, string out).
static func block_cost_suffix(action_blocks: int = 1) -> String:
	var unit: String = "block" if action_blocks == 1 else "blocks"
	return "%d %s" % [action_blocks, unit]


static func format_block_cost_label(action_label: String, action_blocks: int = 1) -> String:
	return "%s — %s" % [action_label, block_cost_suffix(action_blocks)]


# TouchScrollContainer, not a bare ScrollContainer — see its own class
# comment: vanilla ScrollContainer has no touch/finger drag-to-scroll, only
# this subclass's manual handling gives every screen built through this
# (i.e. nearly all of them, via screen_body()) that behaviour.
static func scroll_container() -> ScrollContainer:
	var sc := TouchScrollContainer.new()
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
	margin.add_theme_constant_override("margin_top", 72)  # room below the top bar (TopBar.BAR_HEIGHT + 16)
	margin.add_theme_constant_override("margin_bottom", 80)  # room above the nav bar
	sc.add_child(margin)

	var content := vbox(12)
	margin.add_child(content)
	return content
