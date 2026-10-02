# BizBrief: Brief tab (morning account — bank, payday, wage prompts, operations, attention,
# moves against you, London and supplier shares),
# Manage tab (sales offers/contracts, lab production targets, cultivator
# procurement), once bizStaffTabOpen is set, Staff tab (recruited
# contacts, roles, pay) and, once the business pot is active, Stats tab
# (10-day business performance charts, expenses split by kind). The
# selected tab and ore-chart source are view state held here, not in
# state.phoneNav, so they reset with the screen. state.phoneNav.bizbriefView "shortPay" shows the
# short-pay sub-view (ShortPayView) instead while a guard shortfall is pending;
# "guardCosts" shows the Guard Costs sub-view (GuardCostsView), pot or not.
class_name BizBriefApp
extends PhoneApp

const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")
const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")
const ContractCard := preload("res://scenes/components/contract_card.gd")
const LineChartScript := preload("res://scenes/components/line_chart.gd")
const ShortPayViewScript := preload("res://scenes/phone_apps/short_pay_view.gd")
const GuardCostsViewScript := preload("res://scenes/phone_apps/guard_costs_view.gd")

# Keyed by Contracts.has_staffed_sales(): whether the block-end Sales pass runs.
const SALES_STATUS_TEXT := {
	false: "Nobody's working Sales. Nothing moves until someone is.",
	true: "Sales delivers from shared stock at the end of each block.",
}

const CONTRACT_TYPE_PIP_TEXT := { "oneOff": "ONE-OFF", "recurring": "WEEKLY" }

const BRIEF_TAB := "brief"
const MANAGE_TAB := "manage"
const STAFF_TAB := "staff"
const STATS_TAB := "stats"
const ICON_PATH := "res://assets/phone/icons/bizbrief.png"
const NAVY := Color("#101923")
const HEADER := Color("#172431")
const CARD := Color("#1b2a38")
const LINE := Color("#354454")
const PAPER := Color("#fbfaf6")
const MUTED := Color("#a9b5bd")
const SIGNAL := Color("#e9353c")
const SERIF_NAMES: PackedStringArray = ["Georgia", "Times New Roman", "Noto Serif", "DejaVu Serif", "serif"]
const ORE_SOURCES := { "oreCultivator": "Cultivators", "orePlayer": "You" }
const SKILLS := ["sales", "crafting", "cultivating"]
# Expenses-by-kind chart lines, in draw order: BusinessStats expense kind,
# legend label, palette colour id.
const EXPENSE_KIND_LINES := [
	{ "kind": BusinessStats.EXPENSE_STAFF, "label": "Staff wages", "colour_id": "pastel_blue" },
	{ "kind": BusinessStats.EXPENSE_GUARD, "label": "Guard wages", "colour_id": "brick_lit" },
	{ "kind": BusinessStats.EXPENSE_CALC, "label": "Calc bought", "colour_id": "calc_gold" },
]

var _tab := BRIEF_TAB
var _ore_source := "oreCultivator"
# Production-log days shown expanded (view state), day -> true.
var _expanded_log_days := {}
var _sales_history_open := false
var _sales_details_id := ""
var _short_pay := ShortPayViewScript.new()
var _guard_costs := GuardCostsViewScript.new()
var _root: Control = null
var _scroll: ScrollContainer = null
var _brief_detail_anchor: Control = null
var _serif: SystemFont = null


func build(content: VBoxContainer) -> void:
	if GameState.state["phoneNav"].get("bizbriefView") == PhoneNav.BIZBRIEF_SHORT_PAY_VIEW and GuardUpkeep.pending_shortfall() != null:
		_short_pay.build(content, refresh)
		return
	if GameState.state["phoneNav"].get("bizbriefView") == PhoneNav.BIZBRIEF_GUARD_COSTS_VIEW:
		_guard_costs.build(content, refresh)
		return
	if (_tab == STAFF_TAB and not _staff_tab_open()) or (_tab == STATS_TAB and not Business.is_pot_active()):
		_tab = BRIEF_TAB
	var page := _mount_root()
	if _tab == MANAGE_TAB:
		_build_manage(page)
	elif _tab == STAFF_TAB and _staff_tab_open():
		_build_staff(page)
	elif _tab == STATS_TAB and Business.is_pot_active():
		_build_stats(page)
	else:
		_build_brief(page)
	_style_page(page)


func teardown() -> void:
	if _root != null:
		if _root.get_parent() != null:
			_root.get_parent().remove_child(_root)
		_root.queue_free()
		_root = null


func _mount_root() -> VBoxContainer:
	_root = UI.vbox(0)
	_root.name = "BizBriefRoot"
	shell.mount_custom_root(_root)
	_root.add_child(_build_header())
	_root.add_child(_build_tabs())
	var scroll := UI.scroll_container()
	_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var surface := StyleBoxFlat.new()
	surface.bg_color = NAVY
	scroll.add_theme_stylebox_override("panel", surface)
	_root.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 13)
	margin.add_theme_constant_override("margin_right", 13)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)
	var page := UI.vbox(10)
	page.name = "BizBriefPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(page)
	return page


func _build_header() -> Control:
	var panel := PanelContainer.new()
	panel.name = "BizBriefHeader"
	var style := StyleBoxFlat.new()
	style.bg_color = HEADER
	style.border_color = LINE
	style.border_width_bottom = 1
	style.content_margin_left = 17
	style.content_margin_right = 17
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var column := UI.vbox(3)
	panel.add_child(column)
	var back := UI.button("‹ Phone", func(): PhoneNav.go_home())
	back.name = "BizBriefBack"
	back.flat = true
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.custom_minimum_size.y = 26
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back.add_theme_color_override(state, MUTED)
	column.add_child(back)
	var row := UI.hbox(9)
	column.add_child(row)
	var icon := TextureRect.new()
	icon.name = "BizBriefIcon"
	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load(ICON_PATH) as Texture2D
	if icon.texture == null:
		var image := Image.load_from_file(ProjectSettings.globalize_path(ICON_PATH))
		if not image.is_empty():
			icon.texture = ImageTexture.create_from_image(image)
	row.add_child(icon)
	var brand := UI.heading("BizBrief", 24)
	brand.name = "BizBriefBrand"
	brand.add_theme_font_override("font", _serif_font())
	brand.add_theme_color_override("font_color", PAPER)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(brand)
	var world: Dictionary = GameState.state["world"]
	var phase: int = clampi(int(world["timeBlock"]), 0, GameData.TIME_BLOCKS.size() - 1)
	var day := UI.label("DAY %d · %s" % [int(world["day"]), String(GameData.TIME_BLOCKS[phase]).to_upper()])
	day.name = "BizBriefDayBlock"
	day.add_theme_font_size_override("font_size", 9)
	day.add_theme_color_override("font_color", MUTED)
	day.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(day)
	var subhead := UI.label("Business, under control.")
	subhead.add_theme_font_size_override("font_size", 11)
	subhead.add_theme_color_override("font_color", MUTED)
	column.add_child(subhead)
	return panel


func _serif_font() -> Font:
	if _serif == null:
		_serif = SystemFont.new()
		_serif.font_names = SERIF_NAMES
	return _serif


func _style_page(page: Node) -> void:
	if not is_instance_valid(page):
		return
	_style_page_nodes(page)


func _style_page_nodes(node: Node) -> void:
	if node is PanelContainer:
		var panel := node as PanelContainer
		if not panel.has_theme_stylebox_override("panel"):
			var card := StyleBoxFlat.new()
			card.bg_color = Color("#1e3040") if panel.name == "BizBriefHero" else CARD
			card.border_color = SIGNAL if panel.name == "BizBriefHero" else LINE
			card.border_width_left = 3 if panel.name == "BizBriefHero" else 1
			card.border_width_top = 1
			card.border_width_right = 1
			card.border_width_bottom = 1
			card.set_corner_radius_all(6)
			card.set_content_margin_all(12)
			panel.add_theme_stylebox_override("panel", card)
	elif node is Label:
		var label := node as Label
		if label.has_theme_color_override("font_color"):
			if label.get_theme_color("font_color").is_equal_approx(UI._MUTED_COLOUR):
				label.add_theme_color_override("font_color", MUTED)
		else:
			label.add_theme_color_override("font_color", PAPER)
		if label.has_theme_font_size_override("font_size") and label.get_theme_font_size("font_size") >= 14:
			label.add_theme_font_override("font", _serif_font())
	elif node is Button:
		var button := node as Button
		if button.has_meta(ContactCards.TOGGLE_OPTION_META):
			ContactCards.apply_phone_os_chrome(button)
		elif not button.has_theme_stylebox_override("normal") and not button.has_theme_color_override("font_color"):
			var primary := button.text == "Accept" or button.text.begins_with("Match £") or button.text.begins_with("Top up £") or button.text == "Yes"
			var quiet := button.text == "Decline" or button.text == "No" or button.text == "Unassign" or button.text == "Cancel contract" or button.text.begins_with("+") or button.text.begins_with("-")
			var fill := StyleBoxFlat.new()
			fill.bg_color = SIGNAL if primary and not button.disabled else CARD
			fill.border_color = LINE if quiet else SIGNAL
			fill.set_border_width_all(1)
			fill.set_corner_radius_all(4)
			fill.set_content_margin_all(8)
			for state in ["normal", "hover", "pressed", "disabled"]:
				button.add_theme_stylebox_override(state, fill)
			for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
				button.add_theme_color_override(state, PAPER if primary and not button.disabled else MUTED if quiet or button.disabled else SIGNAL)
	for child in node.get_children():
		_style_page_nodes(child)


func _build_tabs() -> Control:
	var tabs := UI.hbox(0)
	tabs.name = "BizBriefTabs"
	tabs.custom_minimum_size.y = 46
	_build_tab(tabs, "Brief", BRIEF_TAB)
	_build_tab(tabs, "Manage", MANAGE_TAB)
	if _staff_tab_open():
		_build_tab(tabs, "Staff", STAFF_TAB)
	if Business.is_pot_active():
		_build_tab(tabs, "Stats", STATS_TAB)
	return tabs


func _build_tab(tabs: HBoxContainer, title: String, tab_id: String) -> void:
	var selected := _tab == tab_id
	var button := UI.button(title, func(): _set_tab(tab_id))
	button.name = "BizBriefTab_%s" % tab_id
	button.disabled = selected
	button.custom_minimum_size = Vector2(0, 46)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 11)
	var normal := StyleBoxFlat.new()
	normal.bg_color = HEADER
	normal.border_color = SIGNAL if selected else LINE
	normal.border_width_bottom = 3 if selected else 1
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, normal)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(state, PAPER if selected else MUTED)
	tabs.add_child(button)


func _staff_tab_open() -> bool:
	return bool(GameState.state["flags"].get("bizStaffTabOpen", false))


func _set_tab(tab: String) -> void:
	if tab == _tab:
		return
	if (tab == STAFF_TAB and not _staff_tab_open()) or (tab == STATS_TAB and not Business.is_pot_active()):
		return
	_tab = tab
	refresh()


func _build_brief(content: VBoxContainer) -> void:
	content.add_child(UI.muted_label("Account / %s" % Calendar.format_day(int(GameState.state["world"]["day"]))))
	var account: Variant = MorningAccountsSystem.latest()
	content.add_child(_build_brief_hero(account))
	# Attention is read live, including before the first rollover.
	var attention: Array[Dictionary] = MorningAccountsSystem.attention_items()
	content.add_child(_brief_section("Needs your attention", "%02d OPEN" % (attention.size() + Business.pending_wage_prompts().size())))
	for contact_id in Business.pending_wage_prompts():
		content.add_child(_build_wage_prompt(contact_id))
	content.add_child(_build_attention(attention))
	content.add_child(_brief_section("Treasury"))
	content.add_child(_build_treasury())
	content.add_child(_brief_section("Operations feed"))
	content.add_child(_build_operations_feed(account))
	content.add_child(UI.button("Full brief →", _show_full_brief))
	_brief_detail_anchor = _brief_section("Morning Brief")
	content.add_child(_brief_detail_anchor)
	if account == null:
		content.add_child(UI.muted_label("No morning account yet."))
	else:
		content.add_child(UI.muted_label("%s · overnight changes" % Calendar.format_day(int(account["day"]))))
		content.add_child(_build_bank(account))
		if account.get("payday") != null:
			content.add_child(_build_payday(account["payday"]))
		if MorningAccountsSystem.has_operations(account):
			content.add_child(_build_operations(account))
	content.add_child(_build_moves_against_you())
	content.add_child(_build_war())
	content.add_child(_build_london_share())
	content.add_child(_build_supplier_share())


func _show_full_brief() -> void:
	if is_instance_valid(_scroll) and is_instance_valid(_brief_detail_anchor):
		_scroll.ensure_control_visible(_brief_detail_anchor)


func _brief_section(title: String, note: String = "") -> Control:
	var row := UI.hbox()
	var heading := UI.heading(title, 16)
	row.add_child(UI.expand_fill(heading))
	if not note.is_empty():
		row.add_child(UI.muted_label(note))
	return row


func _build_brief_hero(account: Variant) -> Control:
	var c := UI.card()
	c["panel"].name = "BizBriefHero"
	c["content"].add_child(UI.muted_label("CLOSING / REYNARD'S"))
	var balance: int = int(GameState.state["player"]["cash"]) if account == null else int(account["closingBalance"])
	var row := UI.hbox()
	row.add_child(UI.expand_fill(UI.heading("£%d" % balance, 26)))
	if account != null:
		var change: int = int(account["closingBalance"]) - int(account["openingBalance"])
		row.add_child(UI.tinted_label("%s£%d" % ["+" if change >= 0 else "−", absi(change)], SIGNAL if change < 0 else PAPER))
	c["content"].add_child(row)
	c["content"].add_child(UI.muted_label("NET CHANGE" if account != null else "No morning account yet."))
	return c["panel"]


func _build_treasury() -> Control:
	var c := UI.card()
	if Business.is_pot_active():
		var business: Dictionary = GameState.state["business"]
		c["content"].add_child(UI.label("Business pot · £%d" % int(business["pot"])))
		c["content"].add_child(UI.label("Bill float · £%d" % int(business["float"])))
		c["content"].add_child(_build_float())
	else:
		c["content"].add_child(UI.muted_label("Business pot not open yet."))
	return c["panel"]


func _build_operations_feed(account: Variant) -> Control:
	var c := UI.card()
	if account == null or not MorningAccountsSystem.has_operations(account):
		c["content"].add_child(UI.muted_label("No overnight operations to report."))
		return c["panel"]
	for ore_type in account["production"]["ore"]:
		c["content"].add_child(UI.label("%s ore / produced · +%d" % [ore_type.to_upper(), int(account["production"]["ore"][ore_type])]))
	for recipe_key in account["production"]["items"]:
		c["content"].add_child(UI.label("%s / made · +%d" % [String(GameData.RECIPES[recipe_key]["name"]).to_upper(), int(account["production"]["items"][recipe_key])]))
	if account.get("guardWages") != null:
		c["content"].add_child(UI.label("GUARD WAGES / PAID · −£%d" % int(account["guardWages"]["amount"])))
	if c["content"].get_child_count() == 0:
		c["content"].add_child(UI.muted_label("See the full brief below for stock, sales, losses and exceptions."))
	return c["panel"]


const MOVES_SHOWN := 5


# The latest faction moves against the player, newest first, each naming
# its faction (spec §Communication).
func _build_moves_against_you() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Moves against you", 14))
	var moves := FactionAI.moves_against_player()
	if moves.is_empty():
		c["content"].add_child(UI.muted_label("Nobody has moved against you."))
	for move in moves.slice(0, MOVES_SHOWN):
		c["content"].add_child(UI.label("%s · %s: %s" % [Calendar.format_day(int(move["day"])), GameData.FACTIONS[move["factionId"]]["shortName"], move["text"]]))
	return c["panel"]


# The player's weariness meter and the wars they're in (spec §War &
# weariness).
func _build_war() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("War", 14))
	var value := FactionAI.weariness(Shares.PLAYER)
	var row := UI.hbox()
	row.add_child(UI.expand_fill(UI.label("Weariness")))
	row.add_child(UI.tinted_label("%d / 100" % roundi(value), UI._MUTED_COLOUR))
	c["content"].add_child(row)
	c["content"].add_child(UI.bar(value, 100.0))
	var wars := FactionAI.wars_of(Shares.PLAYER)
	if wars.is_empty():
		c["content"].add_child(UI.muted_label("Not at war."))
	for war in wars:
		var enemy: String = FactionAI.war_enemy(war, Shares.PLAYER)
		c["content"].add_child(UI.label("At war with %s · since %s" % [GameData.FACTIONS[enemy]["shortName"], Calendar.format_day(int(war["startDay"]))]))
		c["content"].add_child(UI.muted_label("Last clash %s" % Calendar.format_day(int(war["lastHostileDay"]))))
	return c["panel"]


# The player's ore and crafting share per ore type this week, each with
# ▲/▼ versus last week (spec §UI reads).
func _build_london_share() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Your share of London", 14))
	c["content"].add_child(UI.muted_label("Last %d days · ▲▼ vs the %d before" % [GameData.SHARES_WINDOW_DAYS, GameData.SHARES_WINDOW_DAYS]))
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		var row := UI.hbox()
		row.add_child(UI.expand_fill(UI.label(ore_type.capitalize())))
		row.add_child(_share_move_label("Ore", Shares.ore_share(Shares.PLAYER, ore_type), Shares.ore_share(Shares.PLAYER, ore_type, 1)))
		row.add_child(_share_move_label("Crafting", Shares.crafting_share(Shares.PLAYER, ore_type), Shares.crafting_share(Shares.PLAYER, ore_type, 1)))
		c["content"].add_child(row)
	return c["panel"]


# "Ore 25% ▲", tinted by the move in whole percentage points.
func _share_move_label(title: String, now: float, before: float) -> Label:
	var move: int = _percent_points(now) - _percent_points(before)
	var text := "%s %d%%" % [title, _percent_points(now)]
	if move != 0:
		text += " " + PriceMove.text(move)
	return UI.tinted_label(text, PriceMove.colour(move, UI._MUTED_COLOUR))


# Per buyer faction the player delivered to this week: share of the
# player's deliveries (read A) and of the faction's intake (read B).
func _build_supplier_share() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Supplier share", 14))
	var delivered: Dictionary = Shares.deliveries()
	var any := false
	for faction_id in GameData.FACTIONS:
		if int(delivered.get(faction_id, 0)) <= 0:
			continue
		any = true
		c["content"].add_child(UI.label(GameData.FACTIONS[faction_id]["shortName"]))
		c["content"].add_child(UI.muted_label("%d%% of your deliveries · %d%% of their intake" % [_percent_points(Shares.delivery_split(faction_id)), _percent_points(Shares.intake_share(faction_id))]))
	if not any:
		c["content"].add_child(UI.muted_label("No contract deliveries in the last %d days." % GameData.SHARES_WINDOW_DAYS))
	return c["panel"]


static func _percent_points(fraction: float) -> int:
	return roundi(fraction * 100.0)


func _build_manage(content: VBoxContainer) -> void:
	content.add_child(UI.muted_label("Operations / Sales pipeline"))
	content.add_child(_build_sales())
	content.add_child(_build_production())
	content.add_child(_build_procurement())


func _build_staff(content: VBoxContainer) -> void:
	content.add_child(UI.heading("Staff", 16))
	var contacts: Dictionary = GameState.state["contacts"]
	for contact_id in contacts.keys():
		if contacts[contact_id]["recruited"]:
			content.add_child(_build_staff_card(contact_id))
	content.add_child(UI.button("Vein picking: Manage → Procurement", func(): _set_tab(MANAGE_TAB)))


func _build_stats(content: VBoxContainer) -> void:
	content.add_child(UI.heading("Stats", 16))
	content.add_child(UI.muted_label("Last %d days" % GameData.BUSINESS_STATS_DAYS))
	content.add_child(_build_chart("Revenue", "revenue", "calc_gold", "£"))
	content.add_child(_build_chart("Expenses", "expenses", "brick_lit", "£"))
	content.add_child(_build_expense_breakdown())
	var toggle := UI.hbox()
	for source in ORE_SOURCES:
		var button := UI.button(ORE_SOURCES[source], func(): _set_ore_source(source))
		button.disabled = _ore_source == source
		button.set_meta(ContactCards.TOGGLE_OPTION_META, true)
		toggle.add_child(UI.expand_fill(button))
	content.add_child(_build_chart("Ore collected", _ore_source, "calc_gold_light", "", toggle))
	content.add_child(_build_chart("Items produced", "items", "pastel_teal"))


# A titled card holding one metric's LineChart; header_extra (e.g. the ore
# source toggle) sits between the title and the chart.
func _build_chart(title: String, metric: String, colour_id: String, prefix: String = "", header_extra: Control = null) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.label(title))
	if header_extra != null:
		c["content"].add_child(header_extra)
	var chart: LineChart = LineChartScript.new()
	c["content"].add_child(chart.setup(BusinessStats.series(metric), BusinessStats.window_days(), colour_id, prefix))
	return c["panel"]


# Expenses per day split by kind on one chart, with a legend; the guard
# wages entry is a button into Guard Costs (spec §Visibility).
func _build_expense_breakdown() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.label("Expenses by kind"))
	var lines: Array = []
	for line in EXPENSE_KIND_LINES:
		lines.append({ "values": BusinessStats.series(BusinessStats.EXPENSE_KIND_METRICS[line["kind"]]), "colour_id": line["colour_id"] })
	var chart: LineChart = LineChartScript.new()
	chart.setup(lines[0]["values"], BusinessStats.window_days(), lines[0]["colour_id"], "£")
	c["content"].add_child(chart.with_series(lines.slice(1)))
	var legend := UI.hflow()
	for line in EXPENSE_KIND_LINES:
		var colour: Color = GameData.PALETTE.get(line["colour_id"], Color.WHITE)
		if line["kind"] == BusinessStats.EXPENSE_GUARD:
			var guard := UI.button("● %s ›" % line["label"], func(): PhoneNav.open_guard_costs())
			guard.add_theme_color_override("font_color", colour)
			legend.add_child(guard)
		else:
			legend.add_child(UI.tinted_label("● %s" % line["label"], colour))
	c["content"].add_child(legend)
	return c["panel"]


func _set_ore_source(source: String) -> void:
	if source == _ore_source:
		return
	_ore_source = source
	refresh()


func _build_staff_card(contact_id: String) -> Control:
	var c := UI.card()
	var role: Variant = Contacts.role_of(contact_id)
	c["content"].add_child(UI.heading(Contacts.display_name(contact_id), 14))
	c["content"].add_child(UI.label("%s · %s" % ["No role" if role == null else String(role).capitalize(), Business.pay_terms(contact_id)]))
	c["content"].add_child(UI.muted_label(Business.staff_status(contact_id)))
	var contact: Dictionary = GameState.state["contacts"][contact_id]
	var caps: Dictionary = GameData.CONTACTS_DEFAULTS.get(contact_id, {}).get("skillCaps", {})
	for skill in SKILLS:
		if not contact.has(skill + "Skill"):
			continue
		var line := "%s %d · %d XP" % [skill.capitalize(), int(contact[skill + "Skill"]), int(contact.get(skill + "XP", 0))]
		if caps.has(skill):
			line += " · cap %d" % int(caps[skill])
		c["content"].add_child(UI.muted_label(line))
	if Contacts.is_founder(contact_id):
		c["content"].add_child(_build_role_picker(contact_id, role))
	var owed := Business.owed(contact_id)
	if owed > 0:
		var top_up := Business.top_up_needed(contact_id)
		c["content"].add_child(UI.action_button("Top up £%d and pay" % top_up, func(): Business.top_up_and_pay_owed(contact_id), int(GameState.state["player"]["cash"]) < top_up, "Not enough cash."))
	return c["panel"]


# The founder's open room-free roles, plus clearing a held role.
func _build_role_picker(contact_id: String, current: Variant) -> Control:
	var row := UI.hflow()
	for role in Contacts.available_roles(contact_id):
		var role_id: String = role
		var pick := UI.button(role_id.capitalize(), func(): Contacts.set_role(contact_id, role_id))
		pick.disabled = current == role_id
		row.add_child(pick)
	if GameState.state["contacts"][contact_id].get("assignedRole") != null:
		row.add_child(UI.button("Clear role", func(): Contacts.set_role(contact_id, null)))
	return row


func _build_production() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Production", 14))

	if not Rooms.production_settings_open():
		c["content"].add_child(UI.muted_label("Requires the Improved Lab."))
		if not GameState.state["productionLog"].is_empty():
			c["content"].add_child(_build_production_log())
		return c["panel"]

	var recipe_keys := Rooms.production_recipes()
	for recipe_key in recipe_keys:
		c["content"].add_child(_build_production_recipe_row(recipe_key))
	if recipe_keys.is_empty():
		c["content"].add_child(UI.muted_label("Nothing your crafters can make yet."))
	c["content"].add_child(_build_production_log())
	return c["panel"]


# state.productionLog, newest day first; each day is a collapsed row that
# expands to its per-block, per-crafter entries.
func _build_production_log() -> Control:
	var box := UI.vbox(4)
	box.add_child(UI.heading("Production log", 13))
	var log: Array = GameState.state["productionLog"]
	if log.is_empty():
		box.add_child(UI.muted_label("Nothing crafted yet."))
		return box
	for i in range(log.size() - 1, -1, -1):
		var day_record: Dictionary = log[i]
		var day: int = day_record["day"]
		var totals: Dictionary = Rooms.production_day_totals(day_record)
		var section := UI.collapsible_section("%s · %d made · %d failed" % [Calendar.format_day(day),totals["made"], totals["failed"]], _expanded_log_days.has(day), func(open: bool): _set_log_day_expanded(day, open))
		for block_record in day_record["blocks"]:
			section["content"].add_child(UI.label(GameData.TIME_BLOCKS[int(block_record["block"])]))
			for entry in block_record["entries"]:
				for line in _production_entry_lines(entry):
					section["content"].add_child(UI.muted_label(line))
		box.add_child(section["panel"])
	return box


func _set_log_day_expanded(day: int, open: bool) -> void:
	if open:
		_expanded_log_days[day] = true
	else:
		_expanded_log_days.erase(day)


func _production_entry_lines(entry: Dictionary) -> Array[String]:
	var name := Contacts.display_name(entry["contactId"])
	var lines: Array[String] = []
	for recipe_key in entry["made"]:
		var tiers: Dictionary = entry["made"][recipe_key]
		for tier_key in tiers:
			lines.append("%s made %d %s (tier %s)" % [name, int(tiers[tier_key]), GameData.RECIPES[recipe_key]["name"], tier_key])
	for recipe_key in entry["failed"]:
		lines.append("%s failed %d %s" % [name, int(entry["failed"][recipe_key]), GameData.RECIPES[recipe_key]["name"]])
	var ore_short = entry.get("oreShort")
	if ore_short != null:
		var ore_names: Array[String] = []
		for ore_type in ore_short["ore"]:
			ore_names.append(GameData.ORE_TYPES[ore_type]["name"])
		lines.append("%s stopped: not enough %s for %s" % [name, ", ".join(ore_names), GameData.RECIPES[ore_short["recipeKey"]]["name"]])
	return lines


func _build_production_recipe_row(recipe_key: String) -> Control:
	var recipe: Dictionary = GameData.RECIPES[recipe_key]
	var target: int = GameState.state["labThresholds"].get(recipe_key, 0)
	var covering: bool = Rooms.lab_covers_contracts(recipe_key)

	var box := UI.vbox(4)
	box.add_child(UI.label(recipe["name"]))

	var target_label := UI.muted_label(_target_text(recipe_key, target, covering))
	box.add_child(target_label)
	var on_change := func(value: int) -> void: target_label.text = _target_text(recipe_key, value, covering)
	box.add_child(MapCardStyle.quantity_slider("Target", target, GameData.PRODUCTION_TARGET_MAX, on_change, func(value: int): Rooms.set_lab_threshold(recipe_key, value), 0))

	var target_row := UI.hbox()
	target_row.add_child(UI.button("Stop covering contracts" if covering else "Cover contract needs", func(): Rooms.set_lab_cover_contracts(recipe_key, not covering)))
	box.add_child(target_row)

	return box


static func _target_text(recipe_key: String, target: int, covering: bool) -> String:
	var text := "Personal target: %d" % target
	if covering:
		text += " · contract need: %d · crafting to: %d" % [Rooms.contract_need(recipe_key), Rooms.effective_lab_target(recipe_key, target)]
	return text


func _build_procurement() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Procurement", 14))

	var cultivators: Array = Contacts.contacts_in_role("cultivation")
	if cultivators.is_empty():
		if not GameState.state["home"]["rooms"].has("veinStation"):
			c["content"].add_child(UI.muted_label("Requires the Vein Cultivation Station room."))
		else:
			c["content"].add_child(UI.muted_label("No cultivators yet."))
		return c["panel"]

	var veins: Array = VeinList.veins(null, null)
	if veins.is_empty():
		c["content"].add_child(UI.muted_label("No veins yet."))
		return c["panel"]

	for contact_id in cultivators:
		c["content"].add_child(_build_cultivator_section(contact_id, veins))
	return c["panel"]


func _vein_name(vein: Dictionary) -> String:
	return "%s — %s" % [GameData.DISTRICTS[vein["district"]]["name"], GameData.ORE_TYPES[vein["oreType"]]["name"]]


# One cultivator: their assigned veins with target controls, then a picker
# of every vein not on their list (picking one held elsewhere moves it).
func _build_cultivator_section(contact_id: String, veins: Array) -> Control:
	var box := UI.vbox(4)
	var assigned: Array = Rooms.cultivator_veins(contact_id)
	box.add_child(UI.heading(Contacts.display_name(contact_id), 14))
	if assigned.is_empty():
		box.add_child(UI.muted_label("No veins assigned."))
	var unassigned: Array = []
	for vein in veins:
		if assigned.has(vein["id"]):
			box.add_child(_build_procurement_vein_row(vein))
		else:
			unassigned.append(vein)
	if not unassigned.is_empty():
		var picker := UI.hflow()
		for vein in unassigned:
			var vein_id: String = vein["id"]
			picker.add_child(UI.button("Assign %s" % _vein_name(vein), func(): Rooms.assign_vein(contact_id, vein_id)))
		box.add_child(picker)
	return box


func _build_procurement_vein_row(vein: Dictionary) -> Control:
	var vein_id: String = vein["id"]
	var target: int = Rooms.vein_station_target(vein_id)

	var box := UI.vbox(4)
	box.add_child(UI.label(_vein_name(vein)))
	box.add_child(UI.muted_label("Target: %d" % target))

	var row := UI.hbox()
	row.add_child(UI.button("-5", func(): Rooms.set_vein_station_target(vein_id, target - 5)))
	row.add_child(UI.button("+5", func(): Rooms.set_vein_station_target(vein_id, target + 5)))
	row.add_child(UI.button("Unassign", func(): Rooms.unassign_vein(vein_id)))
	box.add_child(row)

	return box


func _request_type_name(kind: String, item_type: String) -> String:
	return GameData.ORE_TYPES[item_type]["name"] if kind == "ore" else GameData.RECIPES[item_type]["name"]


func _request_summary(request: Dictionary) -> String:
	var parts: Array = []
	for line in ContractsSystem.request_lines(request):
		parts.append("%d %s" % [line["qty"], _request_type_name(line["kind"], line["type"])])
	return " + ".join(parts)


func _contract_progress_summary(contract: Dictionary) -> String:
	var parts: Array = []
	for line in ContractsSystem.request_lines(contract["request"]):
		parts.append("%d/%d %s" % [ContractsSystem.delivered_qty(contract, line["type"]), line["qty"], _request_type_name(line["kind"], line["type"])])
	return ", ".join(parts)


# Type pip plus one ore glyph per requested ore type, for an offer or an
# active contract (both carry contractType and request).
func _build_contract_tags(entry: Dictionary) -> Control:
	var row := UI.hbox(4)
	var pip := PanelContainer.new()
	var pip_label := UI.muted_label(CONTRACT_TYPE_PIP_TEXT[entry.get("contractType", "oneOff")])
	pip_label.add_theme_font_size_override("font_size", 10)
	pip.add_theme_stylebox_override("panel", UI.bordered_panel_style(Color(0, 0, 0, 0), pip_label.get_theme_color("font_color"), 3, 4, 0))
	pip.add_child(pip_label)
	pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pip)
	for ore_type in ContractsSystem.request_ore_types(entry["request"]):
		var glyph := SymbolGlyph.new()
		glyph.symbol = GameData.ORE_TYPES[ore_type]["symbol"]
		glyph.draw_fallback = SymbolGlyph.ore_fallback(ore_type)
		glyph.custom_minimum_size = Vector2(UI.SYMBOL_GLYPH_SIZE, UI.SYMBOL_GLYPH_SIZE)
		glyph.glyph_radius = UI.SYMBOL_GLYPH_SIZE * 0.34
		glyph.color = MapPalette.ore_colour_in(ore_type, true)
		row.add_child(glyph)
	return row


# R§3.10 "Counterparty": the faction an offer or contract is with.
func _counterparty_text(entry: Dictionary) -> String:
	var faction: Dictionary = GameData.FACTIONS.get(entry.get("counterparty", ""), {})
	return "Buyer: %s" % faction.get("shortName", "unknown")


func _build_sales() -> Control:
	var offers: Array = OffersSystem.pending_offers()
	var contracts: Array = ContractsSystem.active_contracts()
	var history: Array = GameState.state["sales"].get("contractHistory", [])
	var section := UI.vbox(9)
	var summary := UI.card()
	summary["panel"].name = "BizBriefHero"
	summary["content"].add_child(UI.muted_label("SALES PIPELINE"))
	var counts := UI.hbox(8)
	counts.add_child(UI.expand_fill(UI.heading("Sales · %d active" % contracts.size(), 18)))
	counts.add_child(UI.muted_label("%d OFFER%s" % [offers.size(), "" if offers.size() == 1 else "S"]))
	summary["content"].add_child(counts)
	summary["content"].add_child(UI.muted_label(SALES_STATUS_TEXT[ContractsSystem.has_staffed_sales()]))
	section.add_child(summary["panel"])
	section.add_child(UI.heading("Offered contracts · %d" % offers.size(), 14))
	if offers.is_empty():
		section.add_child(UI.muted_label("No pending offers."))
	for offer in offers:
		var c := UI.card()
		var request: Dictionary = offer["request"]
		var expiry: String = "expires %s" % Calendar.format_day(int(offer["expiresDay"]))
		c["content"].add_child(_build_contract_tags(offer))
		c["content"].add_child(UI.muted_label(_counterparty_text(offer)))
		if offer.get("source", "") == "renewal":
			c["content"].add_child(UI.muted_label("Renewal. Same order, today's price."))
		c["content"].add_child(UI.heading(_request_summary(request), 15))
		c["content"].add_child(UI.muted_label("%s · £%d per delivery" % [expiry, int(offer["quote"]["payment"])]))
		var poach: Dictionary = offer.get("poach", {})
		var offer_row := UI.hbox()
		if poach.is_empty():
			offer_row.add_child(UI.button("Accept", func(): OffersSystem.accept_offer(offer["id"])))
		else:
			var rival: String = GameData.FACTIONS.get(poach["factionId"], {}).get("shortName", "A rival")
			c["content"].add_child(UI.muted_label("Undercut by %s: £%d. Match it or the buyer walks." % [rival, int(poach["payment"])]))
			offer_row.add_child(UI.button("Match £%d" % int(poach["payment"]), func(): OffersSystem.match_poach(offer["id"])))
		offer_row.add_child(UI.button("Decline", func(): OffersSystem.decline_offer(offer["id"])))
		c["content"].add_child(offer_row)
		section.add_child(c["panel"])
	var accepted_row := UI.hbox(8)
	accepted_row.add_child(UI.expand_fill(UI.heading("Accepted contracts · %d" % contracts.size(), 14)))
	accepted_row.add_child(UI.button("History →" if not _sales_history_open else "History ▾", func(): _toggle_sales_history()))
	section.add_child(accepted_row)
	if contracts.is_empty():
		section.add_child(UI.muted_label("No accepted contracts."))
	else:
		section.add_child(UI.muted_label("Drag cards to set delivery priority."))
	for index in contracts.size():
		var contract: Dictionary = contracts[index]
		var card := ContractCard.new()
		card.configure(contract["id"], index)
		var box := UI.vbox(6)
		card.add_child(box)
		var lead := UI.hbox(6)
		lead.add_child(UI.expand_fill(UI.heading("≡ %02d · %s" % [index + 1, contract["id"]], 15)))
		lead.add_child(UI.muted_label("ACTIVE"))
		box.add_child(lead)
		box.add_child(UI.muted_label(_request_summary(contract["request"])))
		box.add_child(UI.muted_label("%s · due %s" % [_contract_progress_summary(contract), Calendar.format_day(int(contract["dueDay"]))]))
		var total := 0
		var delivered := 0
		for line in ContractsSystem.request_lines(contract["request"]):
			total += int(line["qty"])
			delivered += ContractsSystem.delivered_qty(contract, line["type"])
		var progress := ProgressBar.new()
		progress.name = "ContractProgress"
		progress.custom_minimum_size.y = 5
		progress.max_value = maxi(total, 1)
		progress.value = delivered
		progress.show_percentage = false
		var track := StyleBoxFlat.new()
		track.bg_color = LINE
		track.set_corner_radius_all(3)
		var fill := StyleBoxFlat.new()
		fill.bg_color = SIGNAL
		fill.set_corner_radius_all(3)
		progress.add_theme_stylebox_override("background", track)
		progress.add_theme_stylebox_override("fill", fill)
		box.add_child(progress)
		var actions := UI.hbox(6)
		var buying: bool = contract.get("buyCalc", false)
		actions.add_child(UI.expand_fill(UI.button("Buy missing calc: on" if buying else "Buy missing calc: off", func(): ContractsSystem.set_buy_calc(contract["id"], not buying))))
		actions.add_child(UI.button("Details →" if _sales_details_id != contract["id"] else "Details ▾", func(): _toggle_sales_details(contract["id"])))
		box.add_child(actions)
		if _sales_details_id == contract["id"]:
			box.add_child(_build_contract_tags(contract))
			box.add_child(UI.muted_label(_counterparty_text(contract)))
			box.add_child(UI.label("£%d per delivery" % int(contract["signedQuote"]["payment"])))
			if contract.has("expiryDay"):
				box.add_child(UI.muted_label("Term ends %s" % Calendar.format_day(int(contract["expiryDay"]))))
			if ContractsSystem.is_period_filled(contract):
				box.add_child(UI.muted_label("Delivered this week — next period %s" % Calendar.format_day(int(contract["dueDay"]))))
			box.add_child(UI.muted_label(SALES_STATUS_TEXT[ContractsSystem.has_staffed_sales()]))
			var contract_summary := "%s · £%d" % [_request_summary(contract["request"]), int(contract["signedQuote"]["payment"])]
			box.add_child(UI.button("Cancel contract", func(): Modal.open("contract_cancel", { "contractId": contract["id"], "summary": contract_summary })))
		section.add_child(card)
	if _sales_history_open:
		section.add_child(UI.heading("History", 14))
		if history.is_empty():
			section.add_child(UI.muted_label("No contract history."))
		for entry in history:
			if ContractsSystem.is_cancelled(entry):
				section.add_child(UI.muted_label("%s · cancelled %s" % [entry["contract"]["id"], Calendar.format_day(int(entry["cancelledDay"]))]))
				continue
			var settled: Dictionary = entry["settlement"]
			var ended: String = " · term ended" if ContractsSystem.is_expired(entry) else ""
			section.add_child(UI.muted_label("%s · %s · £%d%s" % [settled["id"], "complete" if settled["complete"] else "partial", settled["payment"], ended]))
	return section


func _toggle_sales_history() -> void:
	_sales_history_open = not _sales_history_open
	refresh()


func _toggle_sales_details(contract_id: String) -> void:
	_sales_details_id = "" if _sales_details_id == contract_id else contract_id
	refresh()


func _build_bank(account: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Reynard's", 14))
	var closing := UI.heading("£%d" % int(account["closingBalance"]), 25)
	closing.add_theme_color_override("font_color", PAPER)
	c["content"].add_child(closing)
	c["content"].add_child(UI.label("Opening £%d · Closing £%d" % [account["openingBalance"], account["closingBalance"]]))
	c["content"].add_child(UI.label("Income +£%d · Expenses −£%d" % [account["income"], account["expenses"]]))
	c["content"].add_child(UI.button("Transaction history →", func(): MorningAccountsSystem.open_bank()))
	return c["panel"]


# Pot and float side by side, with one amount driving Donate (cash → float)
# and Withdraw (float → cash) (spec §Business float).
func _build_float() -> Control:
	var business: Dictionary = GameState.state["business"]
	var cash := int(GameState.state["player"]["cash"])
	var float_balance := int(business["float"])
	var box := UI.vbox()
	box.add_child(UI.muted_label("The float pays bills the pot can't. Payday never splits it."))
	var amount := SpinBox.new()
	amount.min_value = 1
	amount.max_value = maxi(maxi(cash, float_balance), 1)
	amount.step = 1
	amount.value = 1
	amount.allow_greater = false
	box.add_child(amount)
	var row := UI.hbox()
	row.add_child(UI.expand_fill(UI.action_button("Donate", func(): Business.donate(int(amount.value)), cash < 1, "No cash to give.")))
	row.add_child(UI.expand_fill(UI.action_button("Withdraw", func(): Business.withdraw(int(amount.value)), float_balance < 1, "The float is empty.")))
	box.add_child(row)
	return box


func _build_payday(payday: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Payday", 14))
	for line in MorningAccountsSystem.payday_lines(payday):
		c["content"].add_child(UI.label(line))
	return c["panel"]


func _build_wage_prompt(contact_id: String) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.label(MorningAccountsSystem.wage_prompt_label(contact_id)))
	var row := UI.hbox()
	var short: bool = int(GameState.state["player"]["cash"]) < Business.top_up_needed(contact_id)
	row.add_child(UI.expand_fill(UI.action_button("Yes", func(): Business.top_up_and_pay_owed(contact_id), short, "Not enough cash.")))
	row.add_child(UI.expand_fill(UI.button("No", func(): Business.decline_wage_prompt(contact_id))))
	c["content"].add_child(row)
	return c["panel"]


func _build_operations(account: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Operations", 14))
	for ore_type in account["oreMovement"]:
		var change: int = account["oreMovement"][ore_type]
		c["content"].add_child(UI.symbol_row([{ "symbol": GameData.ORE_TYPES[ore_type]["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s stock %s" % [GameData.ORE_TYPES[ore_type]["name"], _signed_amount(change)]]))
	for ore_type in account["production"]["ore"]:
		c["content"].add_child(UI.muted_label("Produced %d %s" % [account["production"]["ore"][ore_type], GameData.ORE_TYPES[ore_type]["name"]]))
	for recipe_key in account["production"]["items"]:
		c["content"].add_child(UI.symbol_row([{ "symbol": GameData.RECIPES[recipe_key]["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "Produced %d %s" % [account["production"]["items"][recipe_key], GameData.RECIPES[recipe_key]["name"]]]))
	for sale_key in account["sales"]:
		c["content"].add_child(UI.label("Sold %s: %d" % [sale_key, account["sales"][sale_key]]))
	for ore_type in account["losses"]["ore"]:
		c["content"].add_child(UI.symbol_row([{ "symbol": GameData.ORE_TYPES[ore_type]["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "Lost %d %s" % [account["losses"]["ore"][ore_type], GameData.ORE_TYPES[ore_type]["name"]]], { "muted": true }))
	if account["losses"]["veins"] > 0:
		c["content"].add_child(UI.muted_label("Lost %d vein%s" % [account["losses"]["veins"], "" if account["losses"]["veins"] == 1 else "s"]))
	if account.get("guardWages") != null:
		c["content"].add_child(UI.label(MorningAccountsSystem.guard_wages_label(account["guardWages"])))
	for exception in account["exceptions"]:
		match exception["kind"]:
			"missedJob":
				c["content"].add_child(UI.muted_label("Exception: James's order expired."))
			"productionShortfall":
				var recipe: Dictionary = GameData.RECIPES[exception["recipeKey"]]
				c["content"].add_child(UI.muted_label("Exception: %s stock %d/%d." % [recipe["name"], exception["actual"], exception["target"]]))
			"arrearsInterest", "arrearsShortfall", "forcedDowngrade", "arrearsCountdown":
				c["content"].add_child(UI.muted_label(MorningAccountsSystem.arrears_label(exception)))
			"wageShortfall":
				c["content"].add_child(UI.muted_label(MorningAccountsSystem.wage_shortfall_label(exception)))
			"guardShortfall", "guardsWalked":
				c["content"].add_child(UI.muted_label(MorningAccountsSystem.guard_shortfall_label(exception)))
	return c["panel"]


func _build_attention(items: Array[Dictionary]) -> Control:
	var c := UI.card()
	if items.is_empty():
		c["content"].add_child(UI.muted_label("Nothing needs attention."))
		return c["panel"]
	for item in items:
		var captured: Dictionary = item
		var glyph: Callable = Icons.draw_attack
		if item["kind"] == "message":
			glyph = Icons.draw_phone
		elif item["kind"] == "development":
			glyph = Icons.draw_cultivate
		var row := UI.hbox()
		var icon := UI.icon_glyph_control(glyph, 0.7)
		icon.custom_minimum_size = Vector2(24, 24)
		row.add_child(icon)
		row.add_child(UI.expand_fill(UI.button(MorningAccountsSystem.attention_label(item), func(): MorningAccountsSystem.open_attention(captured))))
		c["content"].add_child(row)
	return c["panel"]


func _signed_amount(amount: int) -> String:
	return "+%d" % amount if amount > 0 else str(amount)
