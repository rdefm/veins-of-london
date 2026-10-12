# The Register (app id "factions"): a five-row directory of the player's
# standing with each faction (stored stance, signed relation, centred meter,
# live war/truce or request alert); each row opens that faction's dossier page,
# the faction card with its economic identity, ore- and crafting-share bars
# (spec §UI reads), stance, pressure label, Negotiate entry while at war, Gift
# entry (R§3.10 "Gifts"), favour request or owed favour (R§3.10 "Favours"),
# partner price ask and trouble asks (R§3.10 "Partners"), your intel on it,
# and its activity log, newest first. The directory page also keeps London's
# share overview and stance matrix. Holdings, vein security and the stockpile
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
const METER_RANGE := 100

var _tally := "ore"
var selected_faction := ""


func build(content: VBoxContainer) -> void:
	if selected_faction != "" and not GameData.FACTIONS.has(selected_faction):
		selected_faction = ""
	if selected_faction == "":
		_build_directory(content)
	else:
		_build_dossier(content, selected_faction)


func _build_directory(content: VBoxContainer) -> void:
	content.add_child(UI.button("‹ Back", func(): PhoneNav.go_home()))
	content.add_child(_masthead())
	content.add_child(UI.muted_label("Your standing"))
	for faction_id in GameData.FACTIONS.keys():
		content.add_child(_build_row(faction_id))
	content.add_child(_build_overview())
	content.add_child(_build_politics())


func _build_dossier(content: VBoxContainer, faction_id: String) -> void:
	content.add_child(UI.button("‹ The Register", func(): _select("")))
	content.add_child(ContactCards.build_faction_card(faction_id, _build_economy(faction_id)))


func _select(faction_id: String) -> void:
	selected_faction = faction_id
	refresh()


func _masthead() -> Control:
	var box := UI.vbox(4)
	var title := UI.heading("The Register", 22)
	title.add_theme_color_override("font_color", _brand("register_oxide", Color("#e47a50")))
	box.add_child(title)
	var rule := ColorRect.new()
	rule.color = _brand("register_oxide", Color("#e47a50"))
	rule.custom_minimum_size = Vector2(0, 2)
	box.add_child(rule)
	return box


static func _brand(id: String, fallback: Color) -> Color:
	return GameData.PALETTE.get(id, fallback)


# One whole-row button: faction dot and short name, stored stance, signed
# relation, centred meter, and any live alert. Stance is the stored read, never
# derived from the relation number.
func _build_row(faction_id: String) -> Control:
	var relation := int(GameState.state["factions"][faction_id]["relation"])
	var row := Button.new()
	row.set_meta(ROW_META, faction_id)
	row.set_meta(ContactCards.OWN_STYLE_META, true)
	row.custom_minimum_size = Vector2(0, 64)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = _brand("register_graphite", Color("#2b2724"))
	style.border_color = _brand("register_graphite_edge", Color("#4a423c"))
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	for state_name in ["normal", "hover", "pressed", "focus"]:
		row.add_theme_stylebox_override(state_name, style)
	row.pressed.connect(func(): _select(faction_id))

	var ink := _brand("register_ink", Color("#d9d3cc"))
	var box := UI.vbox(4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	var top := UI.hbox(8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dot := ColorRect.new()
	dot.color = MapPalette.faction_colour(faction_id)
	dot.custom_minimum_size = Vector2(12, 12)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(dot)
	top.add_child(UI.expand_fill(_row_label(GameData.FACTIONS[faction_id]["shortName"], ink)))
	top.add_child(_row_label(FactionAI.stance_name(FactionAI.player_stance(faction_id)), ink))
	top.add_child(_row_label("%+d" % relation, ink))
	box.add_child(top)
	var meter := RelationMeter.new()
	meter.value = relation
	meter.ink = ink
	box.add_child(meter)
	var alert := _alert_text(faction_id)
	if alert != "":
		box.add_child(_row_label(alert, _brand("register_oxide", Color("#e47a50"))))
	row.add_child(box)
	row.custom_minimum_size.y = 64 + (20 if alert != "" else 0)
	return row


func _row_label(text: String, colour: Color) -> Label:
	var l := UI.label(text)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# Live war, truce or pending-request note; "" when none applies.
func _alert_text(faction_id: String) -> String:
	if FactionAI.at_war(Shares.PLAYER, faction_id):
		return "At war"
	var truce := FactionAI.find_truce(Shares.PLAYER, faction_id)
	if not truce.is_empty():
		return "Truce until %s" % Calendar.format_day(int(truce["endDay"]))
	if not Diplomacy.pending_for(faction_id).is_empty() or not Partners.pending_for(faction_id).is_empty():
		return "Request waiting"
	return ""


# Neutral −100..100 relation meter: ink fill from the centre towards the
# value, with a zero marker.
class RelationMeter extends Control:
	var value := 0
	var ink := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(0, 8)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, h * 0.25, w, h * 0.5), Color(ink, 0.18))
		var half := w * 0.5
		var span := half * clampf(absf(value) / float(METER_RANGE), 0.0, 1.0)
		var x := half if value >= 0 else half - span
		draw_rect(Rect2(x, h * 0.25, span, h * 0.5), ink)
		draw_rect(Rect2(half - 1, 0, 2, h), ink)


func _build_overview() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("London's calc, last %d days" % GameData.SHARES_WINDOW_DAYS, 15))
	var toggle := UI.hbox()
	for tally in TALLY_NAMES:
		var button := UI.button(TALLY_NAMES[tally], func(): _set_tally(tally))
		button.disabled = _tally == tally
		button.set_meta(ContactCards.TOGGLE_OPTION_META, true)
		toggle.add_child(UI.expand_fill(button))
	c["content"].add_child(toggle)

	var grid := GridContainer.new()
	grid.columns = 1 + GameData.CANONICAL_ORE_TYPES.size()
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_child(Control.new())
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		grid.add_child(_ore_glyph(ore_type))
	var table := Shares.overview(_tally)
	for producer in Shares.producers():
		grid.add_child(UI.expand_fill(UI.label(_producer_name(producer))))
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			grid.add_child(UI.label(_percent(table[producer][ore_type])))
	c["content"].add_child(grid)
	return c["panel"]


# London's stance matrix, read-only: one row per pair (you with each
# faction, then faction pairs) with its stance and any war or truce.
func _build_politics() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("London's politics", 15))
	for row in FactionAI.stance_matrix():
		var parts: Array[String] = [FactionAI.stance_name(row["stance"])]
		if row["war"]:
			parts.append("at war")
		if int(row["truceEndDay"]) >= 0:
			parts.append("truce until %s" % Calendar.format_day(int(row["truceEndDay"])))
		c["content"].add_child(UI.muted_label("%s – %s" % [_producer_name(row["a"]), _producer_name(row["b"])]))
		c["content"].add_child(UI.label(" · ".join(parts)))
	return c["panel"]


func _set_tally(tally: String) -> void:
	if tally == _tally:
		return
	_tally = tally
	refresh()


# Archetype, ores, crafted items, and share bars for the primary and
# secondary ore.
func _build_economy(faction_id: String) -> Control:
	var f: Dictionary = GameData.FACTIONS[faction_id]
	var box := UI.vbox(4)
	box.add_child(UI.label(ARCHETYPE_NAMES.get(f["archetype"], String(f["archetype"]).capitalize())))
	box.add_child(UI.label("Ore: %s, then %s" % [_ore_name(f["primaryOre"]), _ore_name(f["secondaryOre"])]))
	var items: Array[String] = []
	for recipe_key in f["crafts"]:
		items.append(GameData.RECIPES[recipe_key]["name"])
	box.add_child(UI.label("Crafts: %s" % (", ".join(items) if not items.is_empty() else "nothing")))
	for ore_type in [f["primaryOre"], f["secondaryOre"]]:
		box.add_child(_share_row("%s ore" % _ore_name(ore_type), Shares.ore_share(faction_id, ore_type)))
		box.add_child(_share_row("%s crafting" % _ore_name(ore_type), Shares.crafting_share(faction_id, ore_type)))
	box.add_child(UI.label("Stance: %s" % FactionAI.stance_name(FactionAI.player_stance(faction_id))))
	box.add_child(UI.label("Pressure: %s" % FactionAI.pressure_label(faction_id)))
	var talks := FactionAI.negotiation()
	if talks.get("factionId", "") == faction_id:
		box.add_child(UI.button("Peace talks →", func(): Modal.open("negotiation")))
	elif FactionAI.at_war(Shares.PLAYER, faction_id):
		var check := FactionAI.can_open_talks(faction_id)
		box.add_child(UI.action_button("Negotiate peace", func(): ContactCards.open_talks(faction_id), not check["ok"], check.get("reason", "")))
	box.add_child(UI.button("Gift →", func(): Modal.open("gift", { "factionId": faction_id })))
	box.add_child(_build_favour(faction_id))
	box.add_child(_build_partner(faction_id))
	box.add_child(_build_intel(faction_id))
	box.add_child(_build_activity(faction_id))
	return box


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
	box.add_child(UI.muted_label("Activity"))
	var entries := FactionAI.activity_log(faction_id)
	if entries.is_empty():
		box.add_child(UI.muted_label("Nothing yet."))
	for i in range(entries.size() - 1, -1, -1):
		var entry: Dictionary = entries[i]
		box.add_child(UI.label("%s · %s" % [Calendar.format_day(int(entry["day"])), entry["text"]]))
	return box


func _share_row(title: String, fraction: float) -> Control:
	var box := UI.vbox(2)
	box.add_child(UI.muted_label("%s · %s" % [title, _percent(fraction)]))
	box.add_child(UI.bar(fraction, 1.0))
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
