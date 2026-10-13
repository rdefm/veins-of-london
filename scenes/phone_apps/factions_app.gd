# The Register (app id "factions"): a five-row directory of the player's
# standing with each faction (stored stance, signed relation, centred meter,
# live war/truce or request alert); each row opens that faction's dossier page
# on the Register canvas: kicker, name, tagline, stance, relation, labelled
# meter, pressure and war/truce first, then
# Available now (favour request or owed favour R§3.10 "Favours", partner price
# ask and trouble asks R§3.10 "Partners", Negotiate while at war, Gift R§3.10
# "Gifts", Guild Marketplace and Join), then description, identity, the Market
# footprint grid, and collapsible Intel and Activity (newest first). The
# directory page also routes to Market shares (Ore/Crafting toggle, ore choice,
# one percentage bar per producer) and London politics: a 5x5 upper-triangle
# faction-pair stance grid with a selected-pair detail. Holdings, vein security and the stockpile
# show only past your intel level on that faction (R§3.1 "Intel"). The tally
# toggle and the selected dossier are view state.
class_name FactionsApp
extends PhoneApp

const ARCHETYPE_NAMES := {
	"producer": "Producer",
	"crafter": "Crafter",
	"informationBroker": "Information broker",
	"manipulator": "Manipulator",
}
const TALLY_NAMES := { "ore": "Ore", "craft": "Crafting" }
const PRODUCER_NAMES := { Shares.PLAYER: "You", Shares.INDEPENDENTS: "Independents" }

const ROW_META := "register_row"
const ROUTE_META := "register_route"
const METER_RANGE := 100
const SHARE_BAR_META := "share_bar_producer"
const SHARE_ORE_META := "share_ore"

var _tally := "ore"
var selected_faction := ""
var politics_open := false
var shares_open := false
var _share_ore: String = GameData.CANONICAL_ORE_TYPES[0]
var selected_pair := ""
var _intel_open := false
var _activity_open := false


func build(content: VBoxContainer) -> void:
	if selected_faction != "" and not GameData.FACTIONS.has(selected_faction):
		selected_faction = ""
	if selected_faction == "" and shares_open:
		_build_shares_page(content)
	elif selected_faction == "" and politics_open:
		_build_politics_page(content)
	elif selected_faction == "":
		_build_directory(content)
	else:
		_build_dossier(content, selected_faction)


func _build_directory(content: VBoxContainer) -> void:
	content.add_child(_back_link("‹ Back", func(): PhoneNav.go_home()))
	content.add_child(_masthead())
	content.add_child(_page_head())
	var list := UI.vbox(0)
	list.add_child(_divider())
	for faction_id in GameData.FACTIONS.keys():
		list.add_child(_build_row(faction_id))
	content.add_child(list)
	content.add_child(_section_heading("LONDON"))
	var routes := UI.vbox(0)
	routes.add_child(_route_row("politics", "London politics", "How the factions stand with each other", func(): _open_politics(true), false))
	routes.add_child(_route_row("shares", "Market shares", "Ore and crafting across London", func(): _open_shares(true), true))
	content.add_child(routes)


func _open_politics(open: bool) -> void:
	politics_open = open
	selected_pair = ""
	refresh()


func _build_dossier(content: VBoxContainer, faction_id: String) -> void:
	content.add_child(_back_link("‹ The Register", func(): _select("")))
	var f: Dictionary = GameData.FACTIONS[faction_id]
	var box := UI.vbox(14)
	box.add_child(_build_dossier_top(faction_id))
	box.add_child(_build_available(faction_id))
	box.add_child(_wrap(f["description"], 13, _ink()))
	box.add_child(_build_identity(faction_id))
	box.add_child(_build_footprint(faction_id))
	var disclosures := UI.vbox(0)
	disclosures.add_child(_collapsible("Intel", _intel_open, func(open: bool): _intel_open = open, _build_intel(faction_id)))
	disclosures.add_child(_collapsible("Activity", _activity_open, func(open: bool): _activity_open = open, _build_activity(faction_id)))
	disclosures.add_child(_divider())
	box.add_child(disclosures)
	content.add_child(box)


func _select(faction_id: String) -> void:
	selected_faction = faction_id
	refresh()


func surface_colour() -> Variant:
	return _brand("register_graphite", Color("#2b2724"))


static func _brand(id: String, fallback: Color) -> Color:
	return GameData.PALETTE.get(id, fallback)


static func _ink() -> Color:
	return _brand("register_ink", Color("#d9d3cc"))


static func _muted() -> Color:
	return _brand("register_muted", Color("#b4aaa5"))


static func _oxide() -> Color:
	return _brand("register_oxide", Color("#e47a50"))


static func _line() -> Color:
	return _brand("register_graphite_edge", Color("#4a423c"))


# Single-line Register text; never intercepts the tap of the row it sits in.
static func _text(text: String, size: int, colour: Color) -> Label:
	var l := UI.label(text)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.custom_minimum_size.x = 0
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# Wrapping Register body text.
static func _wrap(text: String, size: int, colour: Color) -> Label:
	var l := UI.label(text)
	l.custom_minimum_size.x = 0
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	return l


static func _on_oxide() -> Color:
	return _brand("register_on_oxide", Color("#1d1612"))


static func _graphite() -> Color:
	return _brand("register_graphite", Color("#2b2724"))


static func _button_fill(fill: Color, border: Color, margin_x: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


# Register button: primary is a filled oxide button with dark text, the rest a
# dark panel with an oxide outline; disabled reads muted on the line colour.
static func _style_action(button: Button, primary: bool, fill: Color = Color(0, 0, 0, 0)) -> void:
	button.set_meta(ContactCards.OWN_STYLE_META, true)
	var oxide := _oxide()
	var body := fill if fill.a > 0.0 else _graphite().lerp(oxide, 0.14)
	var text_colour := _on_oxide() if primary else oxide
	var normal := _button_fill(oxide if primary else body, oxide if primary else (_line() if fill.a > 0.0 else oxide))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("focus", normal)
	var lit := _button_fill((oxide if primary else body).lightened(0.1), normal.border_color)
	button.add_theme_stylebox_override("hover", lit)
	button.add_theme_stylebox_override("pressed", _button_fill((oxide if primary else body).darkened(0.12), normal.border_color))
	button.add_theme_stylebox_override("disabled", _button_fill(Color(0, 0, 0, 0), _line()))
	for state_color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state_color, text_colour if fill.a == 0.0 else _ink())
	button.add_theme_color_override("font_disabled_color", _muted())
	button.add_theme_font_size_override("font_size", 13)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 42
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL


# A Register action with its disabled reason underneath.
static func _action(text: String, on_press: Callable, primary: bool, disabled: bool = false, reason: String = "") -> Control:
	var row := UI.vbox(3)
	var b := UI.button(text, on_press)
	b.disabled = disabled
	_style_action(b, primary)
	row.add_child(b)
	if disabled and reason != "":
		row.add_child(_wrap(reason, 11, _muted()))
	return row


# Restyles every phone-built button under a control as a secondary action.
static func _restyle_buttons(root: Node) -> void:
	for node in root.find_children("", "Button", true, false):
		_style_action(node as Button, false)
	if root is Button:
		_style_action(root as Button, false)


static func _divider() -> ColorRect:
	var rule := ColorRect.new()
	rule.color = _line()
	rule.custom_minimum_size = Vector2(0, 1)
	return rule


# Flat transparent button body with optional top and bottom hairlines.
static func _flat_style(top: bool, bottom: bool, shade: float, margin_x: int, margin_y: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(_ink(), shade)
	style.border_color = _line()
	style.border_width_top = 1 if top else 0
	style.border_width_bottom = 1 if bottom else 0
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	return style


static func _apply_flat(button: Button, top: bool, bottom: bool, margin_x: int, margin_y: int) -> void:
	button.set_meta(ContactCards.OWN_STYLE_META, true)
	button.add_theme_stylebox_override("normal", _flat_style(top, bottom, 0.0, margin_x, margin_y))
	button.add_theme_stylebox_override("hover", _flat_style(top, bottom, 0.04, margin_x, margin_y))
	button.add_theme_stylebox_override("pressed", _flat_style(top, bottom, 0.08, margin_x, margin_y))
	button.add_theme_stylebox_override("focus", _flat_style(top, bottom, 0.0, margin_x, margin_y))
	button.add_theme_stylebox_override("disabled", _flat_style(top, bottom, 0.0, margin_x, margin_y))


# Oxide-orange text link used for every Back route.
func _back_link(text: String, on_press: Callable) -> Button:
	var button := UI.button(text, on_press)
	_apply_flat(button, false, false, 0, 0)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.custom_minimum_size = Vector2(0, 44)
	for state_color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state_color, _oxide())
	return button


# Five-node connected mark, uppercase wordmark and brand line on a dark band
# with an oxide-orange bottom rule.
func _masthead() -> Control:
	var band := PanelContainer.new()
	band.set_meta(ContactCards.OWN_STYLE_META, true)
	var style := StyleBoxFlat.new()
	style.bg_color = _brand("register_top", Color("#2d2422"))
	style.border_color = _oxide()
	style.border_width_bottom = 2
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	band.add_theme_stylebox_override("panel", style)
	var row := UI.hbox(12)
	row.add_child(RegisterMark.new())
	var words := UI.vbox(3)
	words.add_child(_text("THE REGISTER", 18, _ink()))
	words.add_child(_text("LONDON POWER INDEX", 10, _oxide()))
	row.add_child(words)
	band.add_child(row)
	return band


class RegisterMark extends Control:
	const SIZE := 36.0

	func _init() -> void:
		custom_minimum_size = Vector2(SIZE, SIZE)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var brand := FactionsApp._oxide()
		var far := SIZE - 5.0
		var nodes := [Vector2(5, 5), Vector2(far, 5), Vector2(SIZE / 2.0, SIZE / 2.0), Vector2(5, far), Vector2(far, far)]
		draw_rect(Rect2(0.5, 0.5, SIZE - 1.0, SIZE - 1.0), brand, false, 1.0)
		draw_line(nodes[0], nodes[4], Color(brand, 0.7), 1.0)
		draw_line(nodes[1], nodes[3], Color(brand, 0.7), 1.0)
		for node in nodes:
			draw_circle(node, 2.5, brand)


func _page_head() -> Control:
	var box := UI.vbox(4)
	box.add_child(_text("YOUR POSITION", 11, _oxide()))
	box.add_child(_text("Your standing", 23, _ink()))
	box.add_child(_text("Five factions. One London.", 12, _muted()))
	return box


func _section_heading(text: String) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_child(_text(text, 11, _oxide()))
	return margin


# Two-line London route: title, short subtitle, orange chevron.
func _route_row(route: String, title: String, subtitle: String, on_press: Callable, last: bool) -> Button:
	var row := Button.new()
	row.set_meta(ROUTE_META, route)
	_apply_flat(row, true, last, 2, 12)
	row.custom_minimum_size = Vector2(0, 62)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.pressed.connect(on_press)
	var box := UI.hbox(8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 2)
	var words := UI.vbox(4)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	words.add_child(_text(title, 14, _ink()))
	var sub := _text(subtitle, 11, _muted())
	sub.clip_text = true
	words.add_child(sub)
	box.add_child(words)
	box.add_child(_chevron(20))
	row.add_child(box)
	return row


static func _chevron(size: int) -> Label:
	var l := _text("›", size, _oxide())
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


# One flat whole-row button: faction dot and short name, stored stance, signed
# relation on the top line; live alert, centred meter and chevron below. Stance
# is the stored read, never derived from the relation number.
func _build_row(faction_id: String) -> Control:
	var relation := int(GameState.state["factions"][faction_id]["relation"])
	var row := Button.new()
	row.set_meta(ROW_META, faction_id)
	_apply_flat(row, false, true, 2, 12)
	row.custom_minimum_size = Vector2(0, 76)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.pressed.connect(func(): _select(faction_id))

	var box := UI.vbox(7)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 2)
	var top := UI.hbox(8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dot := FactionDot.new()
	dot.colour = MapPalette.faction_colour(faction_id)
	top.add_child(dot)
	top.add_child(UI.expand_fill(_text(GameData.FACTIONS[faction_id]["shortName"], 15, _ink())))
	top.add_child(_text(FactionAI.stance_name(FactionAI.player_stance(faction_id)), 12, _ink()))
	top.add_child(_text("%+d" % relation, 12, _muted()))
	box.add_child(top)

	var bottom := UI.hbox(8)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var alert := _text(_alert_text(faction_id), 11, _muted())
	alert.clip_text = true
	alert.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	alert.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(alert)
	var meter := RelationMeter.new()
	meter.value = relation
	meter.ink = _ink()
	meter.custom_minimum_size.x = 112
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(meter)
	bottom.add_child(_chevron(19))
	box.add_child(bottom)
	row.add_child(box)
	return row


class FactionDot extends Control:
	var colour := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(10, 10)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(size * 0.5, 5.0, colour)


# Live war, truce or pending-request note; "" when none applies.
func _alert_text(faction_id: String) -> String:
	var war_truce := _war_truce_text(faction_id)
	if war_truce != "":
		return war_truce
	if not Diplomacy.pending_for(faction_id).is_empty() or not Partners.pending_for(faction_id).is_empty():
		return "Request waiting"
	return ""


# Neutral −100..100 relation meter: a thin track, ink fill from the centre to
# the value, a zero marker and an endpoint dot.
class RelationMeter extends Control:
	var value := 0
	var ink := Color.WHITE
	var dot_radius := 5.0
	var track := 5.0

	static func large() -> RelationMeter:
		var meter := RelationMeter.new()
		meter.dot_radius = 6.5
		meter.track = 7.0
		meter.custom_minimum_size = Vector2(0, 15)
		return meter

	func _init() -> void:
		custom_minimum_size = Vector2(0, 11)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var mid := h * 0.5
		draw_rect(Rect2(0, mid - track * 0.5, w, track), Color(ink, 0.22))
		var half := w * 0.5
		var span := (w * 0.5 - dot_radius) * clampf(value / float(METER_RANGE), -1.0, 1.0)
		draw_rect(Rect2(minf(half, half + span), mid - track * 0.5, absf(span), track), Color(ink, 0.9))
		draw_rect(Rect2(half - 0.5, 0, 1, h), Color(ink, 0.55))
		draw_circle(Vector2(half + span, mid), dot_radius, ink)


func _open_shares(open: bool) -> void:
	shares_open = open
	refresh()


# Market shares page: tally toggle, ore choice, then one oxide bar per producer
# for the selected tally and ore. Selection is view state.
func _build_shares_page(content: VBoxContainer) -> void:
	content.add_child(_back_link("‹ The Register", func(): _open_shares(false)))
	content.add_child(_masthead())
	var box := UI.vbox(14)
	var head := UI.vbox(4)
	head.add_child(_text("LONDON", 11, _oxide()))
	head.add_child(_text("Market shares", 23, _ink()))
	head.add_child(_text("London's calc, last %d days" % GameData.SHARES_WINDOW_DAYS, 12, _muted()))
	box.add_child(head)
	box.add_child(_share_tally_toggle())
	box.add_child(_share_ore_choices())
	var title := UI.hbox(8)
	title.add_child(_ore_glyph(_share_ore))
	title.add_child(_text("%s · %s" % [_ore_name(_share_ore), TALLY_NAMES[_tally]], 15, _ink()))
	box.add_child(title)
	var table := Shares.overview(_tally)
	var rows := UI.vbox(0)
	for producer in Shares.producers():
		var fraction: float = table[producer][_share_ore]
		var row := ShareRow.make(_producer_name(producer), fraction, _percent(fraction))
		row.set_meta(SHARE_BAR_META, producer)
		rows.add_child(_divider())
		rows.add_child(row)
	rows.add_child(_divider())
	box.add_child(rows)
	content.add_child(box)


# Two-part Ore/Crafting control; the selected part is filled oxide.
func _share_tally_toggle() -> Control:
	var toggle := UI.hbox(0)
	for tally in TALLY_NAMES:
		var selected: bool = _tally == tally
		var button := UI.button(TALLY_NAMES[tally], func(): _set_tally(tally))
		button.disabled = selected
		button.set_meta(ContactCards.OWN_STYLE_META, true)
		button.custom_minimum_size.y = 44
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var fill := _oxide() if selected else Color(0, 0, 0, 0)
		var style := _button_fill(fill, _oxide() if selected else _line(), 12)
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, style)
		var text_colour := _on_oxide() if selected else _ink()
		for state_color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
			button.add_theme_color_override(state_color, text_colour)
		button.add_theme_font_size_override("font_size", 14)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		toggle.add_child(button)
	return toggle


# Five compact glyph tabs; the selected one carries a thick oxide underline.
func _share_ore_choices() -> Control:
	var tabs := UI.hbox(0)
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		var selected: bool = _share_ore == ore_type
		var button := UI.button(_ore_name(ore_type), func(): _set_share_ore(ore_type))
		button.disabled = selected
		button.set_meta(SHARE_ORE_META, ore_type)
		button.set_meta(ContactCards.OWN_STYLE_META, true)
		button.custom_minimum_size = Vector2(0, 62)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := _flat_style(false, true, 0.0, 2, 4)
		style.border_width_bottom = 3 if selected else 1
		style.border_color = _oxide() if selected else _line()
		style.content_margin_top = 30
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, style)
		var text_colour := _ink() if selected else _muted()
		for state_color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
			button.add_theme_color_override(state_color, text_colour)
		button.add_theme_font_size_override("font_size", 11)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var glyph := _ore_glyph(ore_type)
		var half := UI.SYMBOL_GLYPH_SIZE / 2.0
		glyph.anchor_left = 0.5
		glyph.anchor_right = 0.5
		glyph.offset_left = -half
		glyph.offset_right = half
		glyph.offset_top = 6
		glyph.offset_bottom = 6 + UI.SYMBOL_GLYPH_SIZE
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(glyph)
		tabs.add_child(button)
	return tabs


func _set_share_ore(ore_type: String) -> void:
	if ore_type == _share_ore:
		return
	_share_ore = ore_type
	refresh()


const POLITICS_META := "politics_pair"
const STANCE_GLYPHS := {
	FactionAI.PARTNER: "P",
	FactionAI.BUSINESS_RIVAL: "R",
	FactionAI.HOSTILE: "H",
	FactionAI.NEUTRAL: "·",
}


# London politics page: faction-pair stance grid (upper triangle, player pairs
# excluded), legend, and the selected pair's detail. View state only.
func _build_politics_page(content: VBoxContainer) -> void:
	content.add_child(_back_link("‹ The Register", func(): _open_politics(false)))
	content.add_child(_masthead())
	var box := UI.vbox(14)
	var head := UI.vbox(4)
	head.add_child(_text("LONDON", 11, _oxide()))
	head.add_child(_text("Politics", 23, _ink()))
	head.add_child(_text("Tap a square for the pair.", 12, _muted()))
	box.add_child(head)
	box.add_child(_politics_grid())
	box.add_child(_politics_legend())
	box.add_child(_pair_detail())
	content.add_child(box)


static func _abbrev(faction_id: String) -> String:
	return str(GameData.FACTIONS[faction_id]["shortName"]).trim_prefix("The ").substr(0, 3).to_upper()


# Restrained stance fill: Partner green, Business rival brown, Hostile red-brown,
# Neutral grey.
static func _stance_fill(stance: String) -> Color:
	match stance:
		FactionAI.PARTNER:
			return _brand("register_stance_partner", Color("#3d5849"))
		FactionAI.BUSINESS_RIVAL:
			return _brand("register_stance_rival", Color("#605047"))
		FactionAI.HOSTILE:
			return _brand("register_stance_hostile", Color("#69434a"))
	return _brand("register_stance_neutral", Color("#333638"))


func _politics_legend() -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 6)
	for stance in STANCE_GLYPHS:
		var item := UI.hbox(5)
		var swatch := ColorRect.new()
		swatch.color = _stance_fill(stance)
		swatch.custom_minimum_size = Vector2(10, 10)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(swatch)
		item.add_child(_text("%s %s" % [STANCE_GLYPHS[stance], FactionAI.stance_name(stance)], 11, _muted()))
		flow.add_child(item)
	return flow


func _politics_row_label(faction_id: String) -> Control:
	var row := UI.hbox(4)
	var dot := FactionDot.new()
	dot.colour = MapPalette.faction_colour(faction_id)
	row.add_child(dot)
	var name_label := _text(str(GameData.FACTIONS[faction_id]["shortName"]).trim_prefix("The "), 11, _ink())
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.custom_minimum_size.x = 76
	return row


func _politics_grid() -> Control:
	var ids: Array = GameData.FACTIONS.keys()
	var grid := GridContainer.new()
	grid.columns = ids.size() + 1
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	grid.add_child(Control.new())
	for faction_id in ids:
		var head := _text(_abbrev(faction_id), 11, _muted())
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(head)
	for i in ids.size():
		grid.add_child(_politics_row_label(ids[i]))
		for j in ids.size():
			if j < i:
				grid.add_child(Control.new())
			elif j == i:
				var dash := _text("—", 12, _muted())
				dash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				grid.add_child(dash)
			else:
				grid.add_child(_politics_cell(ids[i], ids[j]))
	return grid


func _politics_cell(faction_a: String, faction_b: String) -> Control:
	var key := FactionAI.pair_key(faction_a, faction_b)
	var stance := FactionAI.pair_stance(faction_a, faction_b)
	var button := UI.button(STANCE_GLYPHS.get(stance, "·"), func(): _select_pair(key))
	button.set_meta(POLITICS_META, key)
	button.set_meta(ContactCards.OWN_STYLE_META, true)
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill := _stance_fill(stance)
	var selected := key == selected_pair
	var normal := _button_fill(fill, _oxide() if selected else fill, 0)
	if selected:
		normal.set_border_width_all(2)
	for state in ["normal", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, normal)
	var lit := normal.duplicate() as StyleBoxFlat
	lit.bg_color = fill.lightened(0.1)
	button.add_theme_stylebox_override("hover", lit)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = fill.darkened(0.12)
	button.add_theme_stylebox_override("pressed", pressed)
	var text_colour := _muted() if stance == FactionAI.NEUTRAL else _ink()
	for state_color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(state_color, text_colour)
	button.add_theme_font_size_override("font_size", 15)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	return button


func _select_pair(key: String) -> void:
	selected_pair = key
	refresh()


# Bordered strip: both full names, stored stance, signed raw pair relation, war and truce.
func _pair_detail() -> Control:
	var strip := PanelContainer.new()
	strip.set_meta(ContactCards.OWN_STYLE_META, true)
	var style := _flat_style(true, true, 0.0, 2, 13)
	strip.add_theme_stylebox_override("panel", style)
	var box := UI.vbox(5)
	strip.add_child(box)
	if selected_pair == "":
		box.add_child(_wrap("Tap a cell for the pair.", 12, _muted()))
		return strip
	var ids := selected_pair.split(":")
	var a: String = ids[0]
	var b: String = ids[1]
	var title := UI.hbox(6)
	for id in [a, b]:
		var dot := FactionDot.new()
		dot.colour = MapPalette.faction_colour(id)
		title.add_child(dot)
	title.add_child(UI.expand_fill(_wrap("%s – %s" % [GameData.FACTIONS[a]["name"], GameData.FACTIONS[b]["name"]], 15, _ink())))
	box.add_child(title)
	box.add_child(_wrap("Stance: %s" % FactionAI.stance_name(FactionAI.pair_stance(a, b)), 12, _muted()))
	box.add_child(_wrap("Relation %+d" % Factions.get_relation(a, b), 12, _muted()))
	if FactionAI.at_war(a, b):
		box.add_child(_wrap("At war", 12, _oxide()))
	var truce := FactionAI.find_truce(a, b)
	if not truce.is_empty():
		box.add_child(_wrap("Truce until %s" % Calendar.format_day(int(truce["endDay"])), 12, _oxide()))
	return strip


func _set_tally(tally: String) -> void:
	if tally == _tally:
		return
	_tally = tally
	refresh()


# Full name, tagline, signed relation with its centred meter, stored stance,
# pressure and any live war or truce.
func _build_dossier_top(faction_id: String) -> Control:
	var f: Dictionary = GameData.FACTIONS[faction_id]
	var relation := int(GameState.state["factions"][faction_id]["relation"])
	var joined: bool = GameState.state["factions"][faction_id]["joined"]
	var box := UI.vbox(4)
	box.add_child(_text("FACTION DOSSIER", 11, _oxide()))
	box.add_child(_wrap(f["name"] + (" — Member" if joined else ""), 23, _ink()))
	box.add_child(_wrap(f["tagline"], 12, _muted()))
	var standing := UI.vbox(6)
	standing.add_theme_constant_override("separation", 6)
	var line := UI.hbox(8)
	line.add_child(UI.expand_fill(_wrap("Stance: %s" % FactionAI.stance_name(FactionAI.player_stance(faction_id)), 15, _ink())))
	line.add_child(_wrap("Relation %+d" % relation, 15, _ink()))
	standing.add_child(line)
	var meter := RelationMeter.large()
	meter.value = relation
	meter.ink = _ink()
	standing.add_child(meter)
	var ends := UI.hbox(0)
	for end in [["−100", HORIZONTAL_ALIGNMENT_LEFT], ["0", HORIZONTAL_ALIGNMENT_CENTER], ["+100", HORIZONTAL_ALIGNMENT_RIGHT]]:
		var l := _wrap(end[0], 11, _muted())
		l.horizontal_alignment = end[1]
		ends.add_child(l)
	standing.add_child(ends)
	standing.add_child(_wrap("Pressure: %s" % FactionAI.pressure_label(faction_id), 12, _muted()))
	var alert := _war_truce_text(faction_id)
	if alert != "":
		standing.add_child(_wrap(alert, 12, _oxide()))
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_child(standing)
	box.add_child(pad)
	box.add_child(_divider())
	return box


# Live war or truce note; "" when neither applies.
func _war_truce_text(faction_id: String) -> String:
	if FactionAI.at_war(Shares.PLAYER, faction_id):
		return "At war"
	var truce := FactionAI.find_truce(Shares.PLAYER, faction_id)
	if not truce.is_empty():
		return "Truce until %s" % Calendar.format_day(int(truce["endDay"]))
	return ""


# Existing gated actions and current pending or owed requests, before the
# archival detail.
func _build_available(faction_id: String) -> Control:
	var box := UI.vbox(7)
	box.add_child(_text("AVAILABLE NOW", 11, _oxide()))
	box.add_child(_build_favour(faction_id))
	box.add_child(_build_partner(faction_id))
	var talks := FactionAI.negotiation()
	if talks.get("factionId", "") == faction_id:
		box.add_child(_action("Peace talks →", func(): Modal.open("negotiation"), false))
	elif FactionAI.at_war(Shares.PLAYER, faction_id):
		var check := FactionAI.can_open_talks(faction_id)
		box.add_child(_action("Negotiate peace", func(): ContactCards.open_talks(faction_id), false, not check["ok"], check.get("reason", "")))
	box.add_child(_action("Gift →", func(): Modal.open("gift", { "factionId": faction_id }), true))
	for action in ContactCards.build_membership_actions(faction_id):
		_restyle_buttons(action)
		box.add_child(action)
	return box


# Archetype, primary and secondary ore with glyphs, and crafts.
func _build_identity(faction_id: String) -> Control:
	var f: Dictionary = GameData.FACTIONS[faction_id]
	var box := UI.vbox(8)
	box.add_child(_text("DOSSIER", 11, _oxide()))
	var archetype := _wrap(ARCHETYPE_NAMES.get(f["archetype"], String(f["archetype"]).capitalize()), 13, _ink())
	archetype.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var kind := UI.hbox(8)
	kind.add_child(_text("Archetype", 12, _muted()))
	kind.add_child(archetype)
	box.add_child(kind)
	box.add_child(_ore_line("Primary ore", f["primaryOre"]))
	box.add_child(_ore_line("Secondary ore", f["secondaryOre"]))
	var items: Array[String] = []
	for recipe_key in f["crafts"]:
		items.append(GameData.RECIPES[recipe_key]["name"])
	box.add_child(_wrap("Crafts: %s" % (", ".join(items) if not items.is_empty() else "nothing"), 12, _muted()))
	return box


func _ore_line(title: String, ore_type: String) -> Control:
	var row := UI.hbox(8)
	row.add_child(UI.expand_fill(_wrap("%s:" % title, 12, _muted())))
	row.add_child(_ore_tag(ore_type))
	return row


# Canonical glyph beside the short ore name.
func _ore_tag(ore_type: String) -> Control:
	var row := UI.hbox(4)
	row.add_child(_ore_glyph(ore_type))
	var title := _wrap(_ore_name(ore_type), 13, _ink())
	title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(title)
	return row


# Two-column grid: primary and secondary ore as columns, Ore and Crafting
# as the only rows; each cell is the exact share with a proportional fill.
func _build_footprint(faction_id: String) -> Control:
	var f: Dictionary = GameData.FACTIONS[faction_id]
	var box := UI.vbox(8)
	box.add_child(_text("Market footprint", 12, _muted()))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	var corner := Control.new()
	corner.custom_minimum_size.x = 67
	grid.add_child(corner)
	var ores: Array = [f["primaryOre"], f["secondaryOre"]]
	for ore_type in ores:
		var head := _ore_tag(ore_type)
		(head as BoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
		head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(head)
	grid.add_child(_grid_row_name(TALLY_NAMES["ore"]))
	for ore_type in ores:
		grid.add_child(ShareCell.make(Shares.ore_share(faction_id, ore_type), _percent(Shares.ore_share(faction_id, ore_type))))
	grid.add_child(_grid_row_name(TALLY_NAMES["craft"]))
	for ore_type in ores:
		grid.add_child(ShareCell.make(Shares.crafting_share(faction_id, ore_type), _percent(Shares.crafting_share(faction_id, ore_type))))
	box.add_child(grid)
	return box


func _grid_row_name(text: String) -> Control:
	var l := _text(text, 12, _muted())
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


# A percentage centred in a dark cell with a strong oxide fill proportional to
# the share.
class ShareCell extends Control:
	var fraction := 0.0

	static func make(share: float, text: String) -> ShareCell:
		var cell := ShareCell.new()
		cell.fraction = share
		cell.custom_minimum_size = Vector2(0, 43)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l := UI.label(text)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.custom_minimum_size.x = 0
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Color.WHITE)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		l.add_theme_constant_override("outline_size", 3)
		cell.add_child(l)
		return cell

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), FactionsApp._graphite().lerp(Color.WHITE, 0.1))
		draw_rect(Rect2(0, 0, size.x * clampf(fraction, 0.0, 1.0), size.y), FactionsApp._oxide())


# Market shares row: producer name and exact percentage on one line, then a
# dark track with a solid oxide fill proportional to the share.
class ShareRow extends VBoxContainer:
	var fraction := 0.0

	static func make(producer: String, share: float, text: String) -> ShareRow:
		var row := ShareRow.new()
		row.fraction = share
		row.add_theme_constant_override("separation", 6)
		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_top", 10)
		pad.add_theme_constant_override("margin_bottom", 10)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 6)
		var line := UI.hbox(8)
		var name_label := FactionsApp._text(producer, 14, FactionsApp._ink())
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		line.add_child(FactionsApp._text(text, 14, FactionsApp._ink()))
		inner.add_child(line)
		var track := ShareTrack.new()
		track.fraction = share
		inner.add_child(track)
		pad.add_child(inner)
		row.add_child(pad)
		return row


class ShareTrack extends Control:
	var fraction := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(0, 10)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), FactionsApp._graphite().lerp(Color.WHITE, 0.1))
		draw_rect(Rect2(0, 0, size.x * clampf(fraction, 0.0, 1.0), size.y), FactionsApp._oxide())


# Header button that opens or closes a body in one tap; the open state is
# view state so a refresh keeps it.
func _collapsible(title: String, expanded: bool, on_toggle: Callable, body: Control) -> Control:
	var section := UI.collapsible_section(title, expanded, on_toggle)
	var header: Button = section["header"]
	_apply_flat(header, true, false, 0, 12)
	header.add_theme_font_size_override("font_size", 14)
	for state_color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		header.add_theme_color_override(state_color, _ink())
	section["panel"].add_theme_constant_override("separation", 0)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_bottom", 12)
	pad.add_child(body)
	section["content"].add_child(pad)
	return section["panel"]


# Request or owed-favour panel: an oxide edge, the ask, then compact responses
# with the first one primary.
func _request_panel(title: String, text: String, actions: Array[Control]) -> Control:
	var panel := PanelContainer.new()
	panel.set_meta(ContactCards.OWN_STYLE_META, true)
	var style := StyleBoxFlat.new()
	style.bg_color = _graphite().lerp(_ink(), 0.1)
	style.border_color = _oxide()
	style.border_width_left = 2
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	var box := UI.vbox(7)
	box.add_child(_wrap(title, 13, _ink()))
	box.add_child(_wrap(text, 12, _ink()))
	if not actions.is_empty():
		var buttons := HFlowContainer.new()
		buttons.add_theme_constant_override("h_separation", 7)
		buttons.add_theme_constant_override("v_separation", 7)
		for i in actions.size():
			var b := actions[i] as Button
			_style_action(b, i == 0, Color(0, 0, 0, 0) if i == 0 else _graphite().lerp(_ink(), 0.16))
			b.alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.custom_minimum_size.y = 39
			buttons.add_child(b)
		box.add_child(buttons)
	panel.add_child(box)
	return panel


func _build_favour(faction_id: String) -> Control:
	var box := UI.vbox(7)
	var owed := Diplomacy.accepted_for(faction_id)
	if not owed.is_empty():
		box.add_child(_request_panel("Favour owed", Diplomacy.describe(owed), []))
	for entry in Diplomacy.pending_for(faction_id):
		var title := "Favour asked · answer by %s" % Calendar.format_day(int(entry["payload"]["expiresDay"]))
		box.add_child(_request_panel(title, entry["text"], ContactCards.build_pending_actions(entry, func(_e: Dictionary) -> void: pass)))
	return box


# At Partner stance: any trouble ask (R§3.10 "Partners").
func _build_partner(faction_id: String) -> Control:
	var box := UI.vbox(7)
	for entry in Partners.pending_for(faction_id):
		var title := "Partner asks · answer by %s" % Calendar.format_day(int(entry["payload"]["expiresDay"]))
		box.add_child(_request_panel(title, entry["text"], ContactCards.build_pending_actions(entry, func(_e: Dictionary) -> void: pass)))
	return box


# Your intel level on the faction and one line per level reached; nothing
# past the level shows.
func _build_intel(faction_id: String) -> Control:
	var box := UI.vbox(2)
	var reached := Intel.level(Shares.PLAYER, faction_id)
	box.add_child(_wrap("Intel · %s · %d/%d" % [reached.get("name", "None"), Intel.meter(Shares.PLAYER, faction_id), int(GameData.INTEL["max"])], 12, _muted()))
	var holdings: Dictionary = GameState.state["factions"][faction_id]["holdings"]
	if Intel.knows(Shares.PLAYER, faction_id, Intel.VEIN_SECURITY):
		var counts := Intel.vein_security_counts(faction_id)
		var parts: Array[String] = []
		for security in counts:
			parts.append("%d %s" % [counts[security], security])
		box.add_child(_wrap("Veins: %s" % (", ".join(parts) if not parts.is_empty() else "none"), 12, _ink()))
	if Intel.knows(Shares.PLAYER, faction_id, Intel.HOLDINGS):
		var ores: Array[String] = []
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			ores.append("%s %d" % [_ore_name(ore_type), FactionSim.ore_held(faction_id, ore_type)])
		box.add_child(_wrap("Ore held: %s" % ", ".join(ores), 12, _ink()))
		box.add_child(_wrap("Items held: %s" % _item_list(faction_id, holdings["items"].keys()), 12, _ink()))
	if Intel.knows(Shares.PLAYER, faction_id, Intel.STOCKPILE_LOCATION):
		var stockpile: Dictionary = GameState.state["factions"][faction_id]["stockpile"]
		var district: String = GameData.DISTRICTS[stockpile["district"]]["name"] if GameData.DISTRICTS.has(stockpile["district"]) else "somewhere"
		box.add_child(_wrap("Stockpile: %s, %s" % [stockpile["place"], district], 12, _ink()))
	if Intel.knows(Shares.PLAYER, faction_id, Intel.STOCKPILE_SECURITY):
		var kit: Dictionary = GuardKit.recipe_totals(FactionSim.raider_kit(faction_id, "defend")["items"])
		var kit_parts: Array[String] = []
		for recipe_key in kit:
			kit_parts.append("%s ×%d" % [GameData.RECIPES[recipe_key]["name"], kit[recipe_key]])
		box.add_child(_wrap("Stockpile kit: %s" % (", ".join(kit_parts) if not kit_parts.is_empty() else "none"), 12, _ink()))
	if Intel.knows(Shares.PLAYER, faction_id, Intel.STASH):
		for recipe_key in holdings["items"]:
			var tiers: Array[String] = []
			for tier in holdings["items"][recipe_key]:
				var qty := int(holdings["items"][recipe_key][tier])
				if qty > 0:
					tiers.append("%s ×%d" % ["untiered" if int(tier) <= 0 else "tier %s" % tier, qty])
			if not tiers.is_empty():
				box.add_child(_wrap("%s: %s" % [GameData.RECIPES[recipe_key]["name"], ", ".join(tiers)], 12, _ink()))
	return box


func _item_list(faction_id: String, recipe_keys: Array) -> String:
	var items: Array[String] = []
	for recipe_key in recipe_keys:
		var qty := FactionSim.item_held(faction_id, recipe_key)
		if qty > 0:
			items.append("%s ×%d" % [GameData.RECIPES[recipe_key]["name"], qty])
	return ", ".join(items) if not items.is_empty() else "none"


func _build_activity(faction_id: String) -> Control:
	var box := UI.vbox(2)
	var entries := FactionAI.activity_log(faction_id)
	if entries.is_empty():
		box.add_child(_wrap("Nothing yet.", 12, _muted()))
	for i in range(entries.size() - 1, -1, -1):
		var entry: Dictionary = entries[i]
		box.add_child(_wrap("%s · %s" % [Calendar.format_day(int(entry["day"])), entry["text"]], 12, _ink()))
	return box


func _ore_glyph(ore_type: String) -> Control:
	var glyph := SymbolGlyph.new()
	glyph.symbol = GameData.ORE_TYPES[ore_type]["symbol"]
	glyph.draw_fallback = SymbolGlyph.ore_fallback(ore_type)
	glyph.custom_minimum_size = Vector2(UI.SYMBOL_GLYPH_SIZE, UI.SYMBOL_GLYPH_SIZE)
	glyph.glyph_radius = UI.SYMBOL_GLYPH_SIZE * 0.34
	glyph.color = MapPalette.ore_colour_in(ore_type, true)
	return glyph


func _producer_name(producer: String) -> String:
	if PRODUCER_NAMES.has(producer):
		return PRODUCER_NAMES[producer]
	return GameData.FACTIONS[producer]["shortName"]


# Short form ("Life"); the data name ("Life Orichalchum") is too long for a row.
func _ore_name(ore_type: String) -> String:
	return ore_type.capitalize()


static func _percent(fraction: float) -> String:
	return "%d%%" % roundi(fraction * 100.0)
