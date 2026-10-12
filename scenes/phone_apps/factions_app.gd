# The Register (app id "factions"): a five-row directory of the player's
# standing with each faction (stored stance, signed relation, centred meter,
# live war/truce or request alert); each row opens that faction's dossier page,
# name, tagline, relation meter, stance, pressure and war/truce first, then
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
	var c := UI.card()
	var box: VBoxContainer = c["content"]
	box.add_child(_build_dossier_top(faction_id))
	box.add_child(_build_available(faction_id))
	box.add_child(UI.label(f["description"]))
	box.add_child(_build_identity(faction_id))
	box.add_child(_build_footprint(faction_id))
	box.add_child(_collapsible("Intel", _intel_open, func(open: bool): _intel_open = open, _build_intel(faction_id)))
	box.add_child(_collapsible("Activity", _activity_open, func(open: bool): _activity_open = open, _build_activity(faction_id)))
	content.add_child(c["panel"])


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
	const DOT_RADIUS := 5.0
	var value := 0
	var ink := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(0, 11)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var mid := h * 0.5
		draw_rect(Rect2(0, mid - 2.5, w, 5), Color(ink, 0.22))
		var half := w * 0.5
		var span := (w * 0.5 - DOT_RADIUS) * clampf(value / float(METER_RANGE), -1.0, 1.0)
		draw_rect(Rect2(minf(half, half + span), mid - 2.5, absf(span), 5), Color(ink, 0.9))
		draw_rect(Rect2(half - 0.5, 0, 1, h), Color(ink, 0.55))
		draw_circle(Vector2(half + span, mid), DOT_RADIUS, ink)


func _open_shares(open: bool) -> void:
	shares_open = open
	refresh()


# Market shares page: tally toggle, ore choice, then one oxide bar per producer
# for the selected tally and ore. Selection is view state.
func _build_shares_page(content: VBoxContainer) -> void:
	content.add_child(_back_link("‹ The Register", func(): _open_shares(false)))
	content.add_child(_masthead())
	var c := UI.card()
	var box: VBoxContainer = c["content"]
	box.add_child(UI.heading("London's calc, last %d days" % GameData.SHARES_WINDOW_DAYS, 15))
	var toggle := UI.hbox()
	for tally in TALLY_NAMES:
		var button := UI.button(TALLY_NAMES[tally], func(): _set_tally(tally))
		button.disabled = _tally == tally
		button.set_meta(ContactCards.TOGGLE_OPTION_META, true)
		toggle.add_child(UI.expand_fill(button))
	box.add_child(toggle)
	box.add_child(_share_ore_choices())
	var table := Shares.overview(_tally)
	var bars := UI.vbox(6)
	for producer in Shares.producers():
		bars.add_child(UI.label(_producer_name(producer)))
		var fraction: float = table[producer][_share_ore]
		var bar := ShareCell.make(fraction, _percent(fraction))
		bar.set_meta(SHARE_BAR_META, producer)
		bars.add_child(bar)
	box.add_child(bars)
	content.add_child(c["panel"])


func _share_ore_choices() -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		var button := UI.button("      " + _ore_name(ore_type), func(): _set_share_ore(ore_type))
		button.disabled = _share_ore == ore_type
		button.custom_minimum_size.y = 44
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta(SHARE_ORE_META, ore_type)
		var glyph := _ore_glyph(ore_type)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
		glyph.position = Vector2(8, (44 - UI.SYMBOL_GLYPH_SIZE) / 2.0)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(glyph)
		grid.add_child(button)
	return grid


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
	var c := UI.card()
	var box: VBoxContainer = c["content"]
	box.add_child(UI.heading("London politics", 15))
	box.add_child(_politics_grid())
	box.add_child(UI.muted_label(_politics_legend()))
	box.add_child(_pair_detail())
	content.add_child(c["panel"])


static func _abbrev(faction_id: String) -> String:
	return str(GameData.FACTIONS[faction_id]["shortName"]).trim_prefix("The ").substr(0, 3).to_upper()


static func _politics_legend() -> String:
	var parts: Array[String] = []
	for stance in STANCE_GLYPHS:
		parts.append("%s %s" % [STANCE_GLYPHS[stance], FactionAI.stance_name(stance)])
	return " · ".join(parts)


func _politics_grid() -> Control:
	var ids: Array = GameData.FACTIONS.keys()
	var grid := GridContainer.new()
	grid.columns = ids.size() + 1
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.add_child(Control.new())
	for faction_id in ids:
		var head := UI.muted_label(_abbrev(faction_id))
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(head)
	for i in ids.size():
		grid.add_child(UI.muted_label(_abbrev(ids[i])))
		for j in ids.size():
			if j <= i:
				grid.add_child(Control.new())
				continue
			grid.add_child(_politics_cell(ids[i], ids[j]))
	return grid


func _politics_cell(faction_a: String, faction_b: String) -> Control:
	var key := FactionAI.pair_key(faction_a, faction_b)
	var button := UI.button(STANCE_GLYPHS.get(FactionAI.pair_stance(faction_a, faction_b), "·"), func(): _select_pair(key))
	button.set_meta(POLITICS_META, key)
	button.custom_minimum_size = Vector2(44, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = key == selected_pair
	return button


func _select_pair(key: String) -> void:
	selected_pair = key
	refresh()


# Both full names, stored stance, signed raw pair relation, war and truce.
func _pair_detail() -> Control:
	if selected_pair == "":
		return UI.muted_label("Tap a cell for the pair.")
	var ids := selected_pair.split(":")
	var a: String = ids[0]
	var b: String = ids[1]
	var box := UI.vbox(2)
	box.add_child(UI.heading("%s – %s" % [GameData.FACTIONS[a]["name"], GameData.FACTIONS[b]["name"]], 15))
	box.add_child(UI.label("Stance: %s" % FactionAI.stance_name(FactionAI.pair_stance(a, b))))
	box.add_child(UI.label("Relation %+d" % Factions.get_relation(a, b)))
	if FactionAI.at_war(a, b):
		box.add_child(UI.tinted_label("At war", _brand("register_oxide", Color("#e47a50"))))
	var truce := FactionAI.find_truce(a, b)
	if not truce.is_empty():
		box.add_child(UI.tinted_label("Truce until %s" % Calendar.format_day(int(truce["endDay"])), _brand("register_oxide", Color("#e47a50"))))
	return box


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
	var ink := _brand("register_ink", Color("#d9d3cc"))
	var box := UI.vbox(4)
	box.add_child(UI.heading(f["name"] + (" — Member" if joined else ""), 15))
	box.add_child(UI.muted_label(f["tagline"]))
	var line := UI.hbox(8)
	line.add_child(UI.expand_fill(UI.label("Stance: %s" % FactionAI.stance_name(FactionAI.player_stance(faction_id)))))
	line.add_child(UI.label("Relation %+d" % relation))
	box.add_child(line)
	var meter := RelationMeter.new()
	meter.value = relation
	meter.ink = ink
	box.add_child(meter)
	box.add_child(UI.label("Pressure: %s" % FactionAI.pressure_label(faction_id)))
	var alert := _war_truce_text(faction_id)
	if alert != "":
		box.add_child(UI.tinted_label(alert, _brand("register_oxide", Color("#e47a50"))))
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
	var box := UI.vbox(4)
	box.add_child(UI.muted_label("Available now"))
	box.add_child(_build_favour(faction_id))
	box.add_child(_build_partner(faction_id))
	var talks := FactionAI.negotiation()
	if talks.get("factionId", "") == faction_id:
		box.add_child(UI.button("Peace talks →", func(): Modal.open("negotiation")))
	elif FactionAI.at_war(Shares.PLAYER, faction_id):
		var check := FactionAI.can_open_talks(faction_id)
		box.add_child(UI.action_button("Negotiate peace", func(): ContactCards.open_talks(faction_id), not check["ok"], check.get("reason", "")))
	box.add_child(UI.button("Gift →", func(): Modal.open("gift", { "factionId": faction_id })))
	for action in ContactCards.build_membership_actions(faction_id):
		box.add_child(action)
	return box


# Archetype, primary and secondary ore with glyphs, and crafts.
func _build_identity(faction_id: String) -> Control:
	var f: Dictionary = GameData.FACTIONS[faction_id]
	var box := UI.vbox(4)
	box.add_child(UI.label(ARCHETYPE_NAMES.get(f["archetype"], String(f["archetype"]).capitalize())))
	box.add_child(_ore_line("Primary ore", f["primaryOre"]))
	box.add_child(_ore_line("Secondary ore", f["secondaryOre"]))
	var items: Array[String] = []
	for recipe_key in f["crafts"]:
		items.append(GameData.RECIPES[recipe_key]["name"])
	box.add_child(UI.label("Crafts: %s" % (", ".join(items) if not items.is_empty() else "nothing")))
	return box


func _ore_line(title: String, ore_type: String) -> Control:
	var row := UI.hbox(6)
	row.add_child(UI.label("%s:" % title))
	row.add_child(_ore_tag(ore_type))
	return row


# Canonical glyph beside the short ore name.
func _ore_tag(ore_type: String) -> Control:
	var row := UI.hbox(4)
	row.add_child(_ore_glyph(ore_type))
	row.add_child(UI.label(_ore_name(ore_type)))
	return row


# Two-column grid: primary and secondary ore as columns, Ore and Crafting
# as the only rows; each cell is the exact share with a proportional fill.
func _build_footprint(faction_id: String) -> Control:
	var f: Dictionary = GameData.FACTIONS[faction_id]
	var box := UI.vbox(4)
	box.add_child(UI.muted_label("Market footprint"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.add_child(Control.new())
	var ores: Array = [f["primaryOre"], f["secondaryOre"]]
	for ore_type in ores:
		grid.add_child(UI.expand_fill(_ore_tag(ore_type)))
	grid.add_child(UI.label(TALLY_NAMES["ore"]))
	for ore_type in ores:
		grid.add_child(ShareCell.make(Shares.ore_share(faction_id, ore_type), _percent(Shares.ore_share(faction_id, ore_type))))
	grid.add_child(UI.label(TALLY_NAMES["craft"]))
	for ore_type in ores:
		grid.add_child(ShareCell.make(Shares.crafting_share(faction_id, ore_type), _percent(Shares.crafting_share(faction_id, ore_type))))
	box.add_child(grid)
	return box


# A percentage with an oxide-orange fill proportional to the share.
class ShareCell extends Control:
	var fraction := 0.0

	static func make(share: float, text: String) -> ShareCell:
		var cell := ShareCell.new()
		cell.fraction = share
		cell.custom_minimum_size = Vector2(0, 28)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l := UI.label(text)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.custom_minimum_size.x = 0
		cell.add_child(l)
		return cell

	func _draw() -> void:
		var oxide := FactionsApp._brand("register_oxide", Color("#e47a50"))
		draw_rect(Rect2(Vector2.ZERO, size), Color(oxide, 0.15))
		draw_rect(Rect2(0, 0, size.x * clampf(fraction, 0.0, 1.0), size.y), Color(oxide, 0.6))


# Header button that opens or closes a body in one tap; the open state is
# view state so a refresh keeps it.
func _collapsible(title: String, expanded: bool, on_toggle: Callable, body: Control) -> Control:
	var section := UI.collapsible_section(title, expanded, on_toggle)
	section["content"].add_child(body)
	return section["panel"]


func _build_favour(faction_id: String) -> Control:
	var box := UI.vbox(2)
	var owed := Diplomacy.accepted_for(faction_id)
	if not owed.is_empty():
		box.add_child(UI.muted_label("Favour owed"))
		box.add_child(UI.label(Diplomacy.describe(owed)))
	for entry in Diplomacy.pending_for(faction_id):
		box.add_child(UI.muted_label("Favour asked · answer by %s" % Calendar.format_day(int(entry["payload"]["expiresDay"]))))
		box.add_child(UI.label(entry["text"]))
		for action in ContactCards.build_pending_actions(entry, func(_e: Dictionary) -> void: pass):
			box.add_child(action)
	return box


# At Partner stance: the price-favour ask or the running partner rate, and
# any trouble ask (R§3.10 "Partners").
func _build_partner(faction_id: String) -> Control:
	var box := UI.vbox(2)
	if Partners.is_player_partner(faction_id):
		if Partners.price_favour_active(faction_id):
			box.add_child(UI.label("Partner rate in their shop until %s" % Calendar.format_day(Partners.price_favour_until(faction_id))))
		else:
			var check := Partners.can_ask_price_favour(faction_id)
			var cost := int(GameData.PARTNERS["priceFavour"]["relationCost"])
			box.add_child(UI.action_button("Ask for a better price (−%d relation)" % cost, func(): ContactCards.notify_failure(Partners.ask_price_favour(faction_id)), not check["ok"], check.get("reason", "")))
	for entry in Partners.pending_for(faction_id):
		box.add_child(UI.muted_label("Partner asks · answer by %s" % Calendar.format_day(int(entry["payload"]["expiresDay"]))))
		box.add_child(UI.label(entry["text"]))
		for action in ContactCards.build_pending_actions(entry, func(_e: Dictionary) -> void: pass):
			box.add_child(action)
	return box


# Your intel level on the faction and one line per level reached; nothing
# past the level shows.
func _build_intel(faction_id: String) -> Control:
	var box := UI.vbox(2)
	var reached := Intel.level(Shares.PLAYER, faction_id)
	box.add_child(UI.muted_label("Intel · %s · %d/%d" % [reached.get("name", "None"), Intel.meter(Shares.PLAYER, faction_id), int(GameData.INTEL["max"])]))
	var holdings: Dictionary = GameState.state["factions"][faction_id]["holdings"]
	if Intel.knows(Shares.PLAYER, faction_id, Intel.VEIN_SECURITY):
		var counts := Intel.vein_security_counts(faction_id)
		var parts: Array[String] = []
		for security in counts:
			parts.append("%d %s" % [counts[security], security])
		box.add_child(UI.label("Veins: %s" % (", ".join(parts) if not parts.is_empty() else "none")))
	if Intel.knows(Shares.PLAYER, faction_id, Intel.HOLDINGS):
		var ores: Array[String] = []
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			ores.append("%s %d" % [_ore_name(ore_type), FactionSim.ore_held(faction_id, ore_type)])
		box.add_child(UI.label("Ore held: %s" % ", ".join(ores)))
		box.add_child(UI.label("Items held: %s" % _item_list(faction_id, holdings["items"].keys())))
	if Intel.knows(Shares.PLAYER, faction_id, Intel.STOCKPILE_LOCATION):
		var stockpile: Dictionary = GameState.state["factions"][faction_id]["stockpile"]
		var district: String = GameData.DISTRICTS[stockpile["district"]]["name"] if GameData.DISTRICTS.has(stockpile["district"]) else "somewhere"
		box.add_child(UI.label("Stockpile: %s, %s" % [stockpile["place"], district]))
	if Intel.knows(Shares.PLAYER, faction_id, Intel.STOCKPILE_SECURITY):
		var kit: Dictionary = GuardKit.recipe_totals(FactionSim.raider_kit(faction_id, "defend")["items"])
		var kit_parts: Array[String] = []
		for recipe_key in kit:
			kit_parts.append("%s ×%d" % [GameData.RECIPES[recipe_key]["name"], kit[recipe_key]])
		box.add_child(UI.label("Stockpile kit: %s" % (", ".join(kit_parts) if not kit_parts.is_empty() else "none")))
	if Intel.knows(Shares.PLAYER, faction_id, Intel.STASH):
		for recipe_key in holdings["items"]:
			var tiers: Array[String] = []
			for tier in holdings["items"][recipe_key]:
				var qty := int(holdings["items"][recipe_key][tier])
				if qty > 0:
					tiers.append("%s ×%d" % ["untiered" if int(tier) <= 0 else "tier %s" % tier, qty])
			if not tiers.is_empty():
				box.add_child(UI.label("%s: %s" % [GameData.RECIPES[recipe_key]["name"], ", ".join(tiers)]))
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
		box.add_child(UI.muted_label("Nothing yet."))
	for i in range(entries.size() - 1, -1, -1):
		var entry: Dictionary = entries[i]
		box.add_child(UI.label("%s · %s" % [Calendar.format_day(int(entry["day"])), entry["text"]]))
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
