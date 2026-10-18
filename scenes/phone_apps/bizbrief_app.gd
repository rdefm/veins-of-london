# BizBrief: Brief tab (Today card from DailyBrief; wage and poach decisions
# sit on their person's Staff detail, or below Today while Staff is locked;
# then a Yesterday row opening the Morning report page (bank, payday,
# operations) and a Business money row opening the pot/float page, then moves
# against you, London and supplier shares),
# Manage tab (an index of Sales, Production and Procurement rows, each
# opening its own page: sales offers/contracts, lab production targets,
# cultivator procurement), once bizStaffTabOpen is set, Staff tab (a roster
# row per recruit, each opening role, skills, pay, assignments and any wage
# prompt or poach decision) and, once the business pot is active, Stats tab
# (10-day business performance charts, expenses split by kind). The
# selected tab, Brief page, Manage page, Staff person and ore-chart source are view state held here, not in
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

const SALES_EMPTY_TEXT := "No offers or orders yet."

const CONTRACT_TYPE_PIP_TEXT := { "oneOff": "ONE-OFF", "recurring": "WEEKLY" }

const BRIEF_TAB := "brief"
const MANAGE_TAB := "manage"
const STAFF_TAB := "staff"
const STATS_TAB := "stats"
const SALES_PAGE := "sales"
const PRODUCTION_PAGE := "production"
const PROCUREMENT_PAGE := "procurement"
const MANAGE_PAGE_TITLES := { SALES_PAGE: "Sales", PRODUCTION_PAGE: "Production", PROCUREMENT_PAGE: "Procurement" }
const MORNING_PAGE := "morning"
const MONEY_PAGE := "money"
const MARKET_PAGE := "market"
const BRIEF_PAGE_TITLES := { MORNING_PAGE: "Morning report", MONEY_PAGE: "Business money", MARKET_PAGE: "Market position" }
const MORNING_REPORT_EMPTY_TEXT := "No morning report yet. The first comes after you rest."
const POT_CLOSED_TEXT := "Business pot not open yet."
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
# Expenses-by-kind rows: BusinessStats expense kind and label.
const EXPENSE_KIND_LINES := [
	{ "kind": BusinessStats.EXPENSE_STAFF, "label": "Staff wages" },
	{ "kind": BusinessStats.EXPENSE_GUARD, "label": "Guard wages" },
	{ "kind": BusinessStats.EXPENSE_CALC, "label": "Calc bought" },
]

var _tab := BRIEF_TAB
# Brief detail page shown ("" = Today and the Brief index), view state.
var _brief_page := ""
# Manage workstream page shown ("" = the Manage index), view state.
var _manage_page := ""
# Offer/contract id (Sales) or recipe key (Production) the next page build
# scrolls to.
var _page_focus_id := ""
# Cultivator whose Assign vein chooser replaces the Procurement list ("" = list).
var _vein_chooser_for := ""
# The recruit whose Staff detail is open; "" shows the roster.
var _staff_person := ""
var _ore_source := "oreCultivator"
# Production-log days shown expanded (view state), day -> true.
var _expanded_log_days := {}
var _production_log_open := false
var _sales_history_open := false
var _sales_details_id := ""
# Today card view state: rows past the cap shown, Routine and demand
# summaries expanded.
var _today_more_open := false
var _routine_open := false
var _demand_open := false
# Ticked row keys already shown ticked (view state); a row ticked since then
# fades in its tick.
var _shown_ticks := {}
# Set by an expand toggle ("more" or "routine") so the next build fades in
# the rows it revealed.
var _reveal := ""
# Wage prompt and poach cards on the Brief tab while Staff is locked,
# contact id -> Control.
var _decision_anchors := {}
# Pending offer cards on the Manage tab, offer id -> Control.
var _offer_anchors := {}
# Active contract cards on the Sales page, contract id -> Control.
var _contract_anchors := {}
# Recipe rows on the Production page, recipe key -> Control.
var _recipe_anchors := {}
# Procurement cultivator sections by contact id, for Staff's Assignments link.
var _cultivator_anchors := {}
var _short_pay := ShortPayViewScript.new()
var _guard_costs := GuardCostsViewScript.new()
var _root: Control = null
var _scroll: ScrollContainer = null
var _production_log_anchor: Control = null
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
	style.content_margin_left = 6
	style.content_margin_right = 13
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	# One row: back route, icon, wordmark, live day/block.
	var row := UI.hbox(7)
	panel.add_child(row)
	row.add_child(_quiet_link("‹ Phone", func(): PhoneNav.go_home(), "BizBriefBack"))
	var icon := TextureRect.new()
	icon.name = "BizBriefIcon"
	icon.custom_minimum_size = Vector2(24, 24)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load(ICON_PATH) as Texture2D
	if icon.texture == null:
		var image := Image.load_from_file(ProjectSettings.globalize_path(ICON_PATH))
		if not image.is_empty():
			icon.texture = ImageTexture.create_from_image(image)
	row.add_child(icon)
	var brand := UI.heading("BizBrief", 20)
	brand.name = "BizBriefBrand"
	brand.add_theme_font_override("font", _serif_font())
	brand.add_theme_color_override("font_color", PAPER)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(brand)
	var world: Dictionary = GameState.state["world"]
	var phase: int = clampi(int(world["timeBlock"]), 0, GameData.TIME_BLOCKS.size() - 1)
	var day := UI.label("DAY %d · %s" % [int(world["day"]), String(GameData.TIME_BLOCKS[phase]).to_upper()])
	day.name = "BizBriefDayBlock"
	day.add_theme_font_size_override("font_size", 9)
	day.add_theme_color_override("font_color", MUTED)
	day.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	day.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(day)
	return panel


# Flat, muted back/route link with a full-height touch target.
func _quiet_link(text: String, on_press: Callable, node_name: String) -> Button:
	var link := UI.button(text, on_press)
	link.name = node_name
	link.flat = true
	link.alignment = HORIZONTAL_ALIGNMENT_LEFT
	link.custom_minimum_size.y = 44
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		link.add_theme_color_override(state, MUTED)
	return link


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
			var quiet := button.text == "Decline" or button.text == "No" or button.text == "Let them go" or button.text == "Unassign" or button.text == "Cancel contract" or button.text.begins_with("+") or button.text.begins_with("-")
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
	# A selected tab stays tappable while a sub-page or person is open: it returns to the index.
	button.disabled = selected and _brief_page == "" and _manage_page == "" and _staff_person == ""
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
	if tab == _tab and _brief_page == "" and _manage_page == "" and _staff_person == "":
		return
	if (tab == STAFF_TAB and not _staff_tab_open()) or (tab == STATS_TAB and not Business.is_pot_active()):
		return
	_tab = tab
	_brief_page = ""
	_manage_page = ""
	_vein_chooser_for = ""
	_staff_person = ""
	refresh()


# Opens a Manage workstream page; focus_id names a Sales offer or contract
# (a contract also opens its details), a Production recipe or a Procurement
# cultivator to land on.
func _open_manage_page(page: String, focus_id: String = "") -> void:
	_tab = MANAGE_TAB
	_brief_page = ""
	_manage_page = page
	_page_focus_id = focus_id
	_vein_chooser_for = ""
	_staff_person = ""
	if focus_id != "" and ContractsSystem.active_contracts().any(func(c: Dictionary) -> bool: return c["id"] == focus_id):
		_sales_details_id = focus_id
	refresh()


func _build_brief(content: VBoxContainer) -> void:
	match _brief_page:
		MORNING_PAGE:
			content.add_child(_build_brief_subnav())
			_build_morning_report(content)
			return
		MONEY_PAGE:
			content.add_child(_build_brief_subnav())
			_build_business_money(content)
			return
		MARKET_PAGE:
			content.add_child(_build_brief_subnav())
			_build_market_position(content)
			return
	# The Today card is read live, including before the first rollover.
	content.add_child(_build_today())
	# Today's wage and poach rows open the person's Staff detail; while Staff
	# is locked their decision cards sit here as the rows' destination.
	_decision_anchors = {}
	if not _staff_tab_open():
		for contact_id in Business.pending_wage_prompts():
			_decision_anchors[contact_id] = _build_wage_prompt(contact_id)
			content.add_child(_decision_anchors[contact_id])
		for contact_id in Hiring.pending_poach_ids():
			_decision_anchors[contact_id] = _build_poach_alert(contact_id)
			content.add_child(_decision_anchors[contact_id])
	content.add_child(_brief_section("Yesterday"))
	content.add_child(_build_nav_row("BriefRow_%s" % MORNING_PAGE, BRIEF_PAGE_TITLES[MORNING_PAGE], _yesterday_lines(), func(): _open_brief_page(MORNING_PAGE)))
	content.add_child(_brief_section("Business"))
	content.add_child(_build_nav_row("BriefRow_%s" % MONEY_PAGE, BRIEF_PAGE_TITLES[MONEY_PAGE], [_money_status()], func(): _open_brief_page(MONEY_PAGE)))
	content.add_child(_build_nav_row("BriefRow_%s" % MARKET_PAGE, BRIEF_PAGE_TITLES[MARKET_PAGE], [_market_status()], func(): _open_brief_page(MARKET_PAGE)))


# BizBrief Today card (spec .scratch/bizbrief-today §Brief tab layout): date,
# blocks left, then one compact full-width row per DailyBrief.card() row under
# its tier heading, each with one action button. Routine items, and two or
# more demand spikes, each sit behind one summary row; rows past the cap
# behind "+N more".
func _build_today() -> Control:
	var summary := DailyBrief.summary()
	var c := UI.card()
	c["panel"].name = "BizBriefToday"
	c["content"].add_theme_constant_override("separation", 0)
	var head := UI.hbox()
	head.add_child(UI.heading("Today", 20))
	var blocks: int = summary["blocksLeft"]
	var when := UI.muted_label("%s · %d block%s left" % [summary["dateLabel"], blocks, "" if blocks == 1 else "s"])
	when.name = "TodayWhen"
	UI.expand_fill(when)
	when.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	when.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(when)
	c["content"].add_child(head)
	var card := DailyBrief.card()
	var rows: Array = card["visible"]
	if rows.is_empty():
		var empty := UI.muted_label(DailyBrief.empty_text())
		empty.custom_minimum_size.y = 44
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		c["content"].add_child(empty)
	if _today_more_open:
		rows = rows + card["hidden"]
	var labels: Dictionary = GameData.DAILY_BRIEF
	var reveal_more := _reveal == "more"
	var reveal_routine := _reveal == "routine"
	var reveal_demand := _reveal == "demand"
	_reveal = ""
	# Ticks cleared at rollover can fade in again when re-ticked.
	var ticks: Array = GameState.state["morningAccounts"]["briefTicks"]
	for key in _shown_ticks.keys():
		if not ticks.has(key):
			_shown_ticks.erase(key)
	var tier := ""
	for i in rows.size():
		var row: Dictionary = rows[i]
		var past_cap: bool = i >= card["visible"].size()
		if row["tier"] != tier:
			tier = row["tier"]
			c["content"].add_child(_today_tier_heading(tier, summary["counts"][tier]))
		else:
			c["content"].add_child(_today_rule())
		if row["kind"] == "routineSummary":
			var toggle_label: String = labels["routineCollapseLabel"] if _routine_open else labels["routineExpandLabel"]
			c["content"].add_child(_today_row(row, reveal_more and past_cap, toggle_label, _toggle_routine))
			if _routine_open:
				for child in row["children"]:
					c["content"].add_child(_today_rule())
					c["content"].add_child(_today_row(child, reveal_routine))
		elif row["kind"] == "demandSummary":
			var toggle_label: String = labels["demandCollapseLabel"] if _demand_open else labels["demandExpandLabel"]
			c["content"].add_child(_today_row(row, reveal_more and past_cap, toggle_label, _toggle_demand))
			if _demand_open:
				for child in row["children"]:
					c["content"].add_child(_today_rule())
					c["content"].add_child(_today_row(child, reveal_demand))
		else:
			c["content"].add_child(_today_row(row, reveal_more and past_cap))
	if card["more"] > 0:
		var more_label: String = labels["lessLabel"] if _today_more_open else String(labels["moreLabel"]).format({ "n": card["more"] })
		var more := UI.button(more_label, _toggle_today_more)
		more.name = "TodayMore"
		c["content"].add_child(_today_rule())
		c["content"].add_child(more)
	return c["panel"]


# A tier heading: uppercase tier name, its row count (Routine's one summary
# row carries its own), and a rule; Urgent in signal red.
func _today_tier_heading(tier: String, count: int) -> Control:
	var head := UI.hbox(8)
	head.name = "TodayTier_%s" % tier
	head.custom_minimum_size.y = 30
	var text := String(GameData.DAILY_BRIEF["tierLabels"][tier]).to_upper()
	if tier != "routine":
		text += " · %d" % count
	var title := UI.label(text)
	title.custom_minimum_size.x = 0
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_vertical = Control.SIZE_SHRINK_END
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", SIGNAL if tier == "urgent" else MUTED)
	head.add_child(title)
	var rule := _today_rule()
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_END
	head.add_child(rule)
	return head


func _today_rule() -> HSeparator:
	var rule := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = LINE
	line.thickness = 1
	rule.add_theme_stylebox_override("separator", line)
	rule.add_theme_constant_override("separation", 1)
	return rule


# One Today row; on_press defaults to ticking the row and routing its
# action. A done row carries the doneMark; it fades in when newly ticked or
# just revealed by an expand toggle, unless reduced motion is on.
func _today_row(row: Dictionary, revealed: bool = false, button_label: String = "", on_press: Callable = Callable()) -> Control:
	var action: Dictionary = row["action"]
	var key: String = row["key"]
	var line := UI.hbox(10)
	line.name = "TodayRow_%s" % key.validate_node_name()
	line.custom_minimum_size.y = 52
	var text := UI.vbox(2)
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title := UI.muted_label("%s %s" % [GameData.DAILY_BRIEF["doneMark"], row["label"]]) if row["done"] else UI.label(row["label"])
	title.custom_minimum_size.x = 0
	title.add_theme_font_size_override("font_size", 13)
	text.add_child(title)
	if row["consequence"] != "":
		var consequence := UI.muted_label(row["consequence"])
		consequence.custom_minimum_size.x = 0
		consequence.add_theme_font_size_override("font_size", 12)
		text.add_child(consequence)
	line.add_child(UI.expand_fill(text))
	if on_press.is_null():
		on_press = func():
			DailyBrief.mark_acted(key)
			_open_today_action(action)
	var route := UI.button(row["actionLabel"] if button_label == "" else button_label, on_press)
	route.custom_minimum_size.y = 44
	route.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(route)
	var newly_ticked: bool = row["done"] and not _shown_ticks.has(key)
	if row["done"]:
		_shown_ticks[key] = true
	if (revealed or newly_ticked) and not GameState.state["meta"].get("reducedMotion", false):
		line.modulate.a = 0.0
		# The row isn't in the tree yet, so the tween comes from the SceneTree.
		(Engine.get_main_loop() as SceneTree).create_tween().bind_node(line).tween_property(line, "modulate:a", 1.0, float(GameData.DAILY_BRIEF["revealSeconds"]))
	return line


func _toggle_routine() -> void:
	_routine_open = not _routine_open
	_reveal = "routine" if _routine_open else ""
	refresh()


func _toggle_demand() -> void:
	_demand_open = not _demand_open
	_reveal = "demand" if _demand_open else ""
	refresh()


func _toggle_today_more() -> void:
	_today_more_open = not _today_more_open
	_reveal = "more" if _today_more_open else ""
	refresh()


# Routes a DailyBrief action descriptor onto existing navigation.
func _open_today_action(action: Dictionary) -> void:
	match action["to"]:
		"alarms":
			RaidAlarms.open()
		"short_pay":
			PhoneNav.open_short_pay()
		"map_vein":
			VeinList.apply_option(VeinList.MANAGE_ID, action["veinId"])
		"bizbrief_staff":
			var contact_id := String(action.get("contactId", ""))
			var anchor: Variant = _decision_anchors.get(contact_id)
			if contact_id != "" and _staff_tab_open():
				_open_staff_person(contact_id)
			elif is_instance_valid(_scroll) and is_instance_valid(anchor):
				_scroll.ensure_control_visible(anchor)
			else:
				_set_tab(STAFF_TAB)
		"bizbrief_production":
			_open_manage_page(PRODUCTION_PAGE, String(action.get("recipeKey", "")))
		"bizbrief_sales":
			_open_manage_page(SALES_PAGE, String(action.get("contractId", "")))
		"bizbrief_offer":
			_open_manage_page(SALES_PAGE, String(action["offerId"]))
		"trade":
			Modal.open("sell_menu")
		"thread":
			PhoneNav.select_conversation(action["contactId"])
		"map":
			Nav.go_to("map")
		"rest":
			Nav.go_to("hq")
		"bank", "property", "todo":
			PhoneNav.open_app(action["to"])


func _brief_section(title: String, note: String = "") -> Control:
	var row := UI.hbox()
	var heading := UI.heading(title, 16)
	row.add_child(UI.expand_fill(heading))
	if not note.is_empty():
		row.add_child(UI.muted_label(note))
	return row


func _open_brief_page(page: String) -> void:
	_tab = BRIEF_TAB
	_brief_page = page
	_manage_page = ""
	_vein_chooser_for = ""
	_staff_person = ""
	refresh()


func _build_brief_subnav() -> Control:
	var row := UI.hbox(4)
	row.name = "BriefSubnav"
	row.add_child(_quiet_link("‹ Brief", func(): _set_tab(BRIEF_TAB), "BriefBack"))
	var crumb := UI.muted_label("/ %s" % BRIEF_PAGE_TITLES[_brief_page])
	crumb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(crumb)
	return row


# The Yesterday row's status: Reynard's close and net change from the latest
# Morning Brief, then which detail sections the report holds.
func _yesterday_lines() -> Array:
	var account: Variant = MorningAccountsSystem.latest()
	if account == null:
		return [MORNING_REPORT_EMPTY_TEXT]
	var change: int = int(account["closingBalance"]) - int(account["openingBalance"])
	var lines := ["Reynard's £%d · %s£%d overnight" % [int(account["closingBalance"]), "+" if change >= 0 else "−", absi(change)]]
	var parts: Array[String] = []
	if account.get("payday") != null:
		parts.append("Payday")
	if MorningAccountsSystem.has_operations(account):
		parts.append("Operations")
	var exceptions: int = account["exceptions"].size()
	if exceptions > 0:
		parts.append("%d exception%s" % [exceptions, "" if exceptions == 1 else "s"])
	lines.append(" · ".join(parts) if not parts.is_empty() else "No payday or operations.")
	return lines


func _money_status() -> String:
	if not Business.is_pot_active():
		return POT_CLOSED_TEXT
	var business: Dictionary = GameState.state["business"]
	return "Pot £%d · float £%d" % [int(business["pot"]), int(business["float"])]


# The full latest Morning Brief: bank, payday and every operations line.
func _build_morning_report(content: VBoxContainer) -> void:
	var account: Variant = MorningAccountsSystem.latest()
	if account == null:
		content.add_child(UI.muted_label(MORNING_REPORT_EMPTY_TEXT))
		return
	content.add_child(UI.muted_label("%s · overnight changes" % Calendar.format_day(int(account["day"]))))
	content.add_child(_build_bank(account))
	if account.get("payday") != null:
		content.add_child(_build_payday(account["payday"]))
	if MorningAccountsSystem.has_operations(account):
		content.add_child(_build_operations(account))
	else:
		content.add_child(UI.muted_label("No overnight operations to report."))


# Pot and float as separate cards, each with its role (REFERENCE §3.10
# "Business pot and payday", "Business float"); the float card holds
# Donate/Withdraw.
func _build_business_money(content: VBoxContainer) -> void:
	if not Business.is_pot_active():
		content.add_child(UI.muted_label(POT_CLOSED_TEXT))
		return
	var business: Dictionary = GameState.state["business"]
	var pot := UI.card()
	pot["panel"].name = "BizBriefPot"
	pot["content"].add_child(UI.heading("Business pot", 14))
	pot["content"].add_child(UI.heading("£%d" % int(business["pot"]), 25))
	pot["content"].add_child(UI.muted_label("Contract payments land here. Monday's payday pays wages and guards from it, then splits the rest with your partners."))
	content.add_child(pot["panel"])
	var float_card := UI.card()
	float_card["panel"].name = "BizBriefFloat"
	float_card["content"].add_child(UI.heading("Bill float", 14))
	float_card["content"].add_child(UI.heading("£%d" % int(business["float"]), 25))
	float_card["content"].add_child(UI.label("Cash in hand £%d" % int(GameState.state["player"]["cash"])))
	float_card["content"].add_child(_build_float())
	content.add_child(float_card["panel"])


const MOVES_SHOWN := 5


# The Market position row's status: rival moves and wars against the player.
func _market_status() -> String:
	var moves := FactionAI.moves_against_player().size()
	var enemies: Array = FactionAI.wars_of(Shares.PLAYER).map(func(w: Dictionary) -> String: return GameData.FACTIONS[FactionAI.war_enemy(w, Shares.PLAYER)]["shortName"])
	var parts: Array[String] = []
	if moves > 0:
		parts.append("%d move%s against you" % [moves, "" if moves == 1 else "s"])
	if not enemies.is_empty():
		parts.append("At war with %s" % ", ".join(enemies))
	return " · ".join(parts) if not parts.is_empty() else "No rival moves · not at war"


# Rival moves, war and weariness, London share and supplier share, each under
# its own heading; a quiet group is one muted line rather than an empty card.
func _build_market_position(content: VBoxContainer) -> void:
	content.add_child(_brief_section("Moves against you"))
	content.add_child(_build_moves_against_you())
	content.add_child(_brief_section("War"))
	content.add_child(_build_war())
	content.add_child(_brief_section("Your share of London"))
	content.add_child(_build_london_share())
	content.add_child(_brief_section("Supplier share"))
	content.add_child(_build_supplier_share())


# The latest faction moves against the player, newest first, each naming
# its faction (spec §Communication).
func _build_moves_against_you() -> Control:
	var moves := FactionAI.moves_against_player()
	if moves.is_empty():
		return UI.muted_label("Nobody has moved against you.")
	var c := UI.card()
	c["panel"].name = "MarketMoves"
	for move in moves.slice(0, MOVES_SHOWN):
		c["content"].add_child(UI.label("%s · %s: %s" % [Calendar.format_day(int(move["day"])), GameData.FACTIONS[move["factionId"]]["shortName"], move["text"]]))
	return c["panel"]


# The player's weariness meter and the wars they're in (spec §War &
# weariness).
func _build_war() -> Control:
	var value := FactionAI.weariness(Shares.PLAYER)
	var wars := FactionAI.wars_of(Shares.PLAYER)
	if wars.is_empty() and roundi(value) == 0:
		return UI.muted_label("Not at war · weariness 0 / 100")
	var c := UI.card()
	c["panel"].name = "MarketWar"
	var row := UI.hbox()
	row.add_child(UI.expand_fill(UI.label("Weariness")))
	row.add_child(UI.tinted_label("%d / 100" % roundi(value), UI._MUTED_COLOUR))
	c["content"].add_child(row)
	c["content"].add_child(UI.bar(value, 100.0))
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
	c["panel"].name = "MarketLondonShare"
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
	var delivered: Dictionary = Shares.deliveries()
	var buyers: Array = GameData.FACTIONS.keys().filter(func(id: String) -> bool: return int(delivered.get(id, 0)) > 0)
	if buyers.is_empty():
		return UI.muted_label("No contract deliveries in the last %d days." % GameData.SHARES_WINDOW_DAYS)
	var c := UI.card()
	c["panel"].name = "MarketSupplierShare"
	for faction_id in buyers:
		c["content"].add_child(UI.label(GameData.FACTIONS[faction_id]["shortName"]))
		c["content"].add_child(UI.muted_label("%d%% of your deliveries · %d%% of their intake" % [_percent_points(Shares.delivery_split(faction_id)), _percent_points(Shares.intake_share(faction_id))]))
	return c["panel"]


static func _percent_points(fraction: float) -> int:
	return roundi(fraction * 100.0)


func _build_manage(content: VBoxContainer) -> void:
	match _manage_page:
		SALES_PAGE:
			content.add_child(_build_manage_subnav())
			content.add_child(_build_sales())
			_focus_page_item()
		PRODUCTION_PAGE:
			content.add_child(_build_manage_subnav())
			content.add_child(_build_production())
			_focus_page_item()
		PROCUREMENT_PAGE:
			content.add_child(_build_manage_subnav())
			content.add_child(_build_procurement())
			_focus_page_item()
		_:
			content.add_child(UI.muted_label("WORKSTREAMS"))
			content.add_child(_build_manage_row(SALES_PAGE, _sales_status()))
			content.add_child(_build_manage_row(PRODUCTION_PAGE, _production_status()))
			content.add_child(_build_manage_row(PROCUREMENT_PAGE, _procurement_status()))


func _build_manage_subnav() -> Control:
	var row := UI.hbox(4)
	row.name = "ManageSubnav"
	row.add_child(_quiet_link("‹ Manage", func(): _set_tab(MANAGE_TAB), "ManageBack"))
	var crumb := UI.muted_label("/ %s" % MANAGE_PAGE_TITLES[_manage_page])
	crumb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(crumb)
	return row


# A full-width workstream row: title, one live status, chevron. The flat
# button laid over the card makes the whole row the touch target.
func _build_manage_row(page: String, status: String) -> Control:
	return _build_nav_row("ManageRow_%s" % page, MANAGE_PAGE_TITLES[page], [status], func(): _open_manage_page(page))


# A tappable row: title, muted status lines, optional signal badge, chevron.
# node_name ends "Row_<id>"; the full-row button is named "RowButton_<id>".
func _build_nav_row(node_name: String, title: String, lines: Array, on_press: Callable, badge: String = "") -> Control:
	var panel := PanelContainer.new()
	panel.name = node_name
	var row := UI.hbox(8)
	panel.add_child(row)
	var text := UI.vbox(3)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UI.heading(title, 16))
	for line in lines:
		text.add_child(UI.muted_label(line))
	row.add_child(text)
	if badge != "":
		var tag := UI.tinted_label(badge, SIGNAL)
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(tag)
	var chevron := UI.heading("›", 20)
	chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chevron.add_theme_color_override("font_color", SIGNAL)
	row.add_child(chevron)
	var tap := Button.new()
	tap.name = node_name.replace("Row_", "RowButton_")
	tap.custom_minimum_size.y = 44
	tap.pressed.connect(on_press)
	var press := StyleBoxFlat.new()
	press.bg_color = Color(PAPER, 0.06)
	for state in ["normal", "focus"]:
		tap.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["hover", "pressed"]:
		tap.add_theme_stylebox_override(state, press)
	panel.add_child(tap)
	return panel


func _sales_status() -> String:
	var counts := _sales_counts()
	if counts == "":
		return SALES_EMPTY_TEXT
	if not ContractsSystem.active_contracts().is_empty() and not ContractsSystem.has_staffed_sales():
		counts += " · nobody on Sales"
	return counts


# "2 active · 1 offer waiting", omitting zero parts; "" when both are zero.
func _sales_counts() -> String:
	var offers: int = OffersSystem.pending_offers().size()
	var active: int = ContractsSystem.active_contracts().size()
	var parts: Array[String] = []
	if active > 0:
		parts.append("%d active" % active)
	if offers > 0:
		parts.append("%d offer%s waiting" % [offers, "" if offers == 1 else "s"])
	return " · ".join(parts)


func _production_status() -> String:
	if not Rooms.production_settings_open():
		return "Needs the Improved Lab."
	var recipe_keys := Rooms.production_recipes()
	if recipe_keys.is_empty():
		return "Nothing your crafters can make yet."
	var targeted := 0
	var uncovered := 0
	for recipe_key in recipe_keys:
		if int(GameState.state["labThresholds"].get(recipe_key, 0)) > 0 or Rooms.lab_covers_contracts(recipe_key):
			targeted += 1
		if not Rooms.lab_covers_contracts(recipe_key):
			uncovered += Rooms.contract_need(recipe_key)
	var status := "No targets set." if targeted == 0 else "%d of %d recipes targeted" % [targeted, recipe_keys.size()]
	if uncovered > 0:
		status = "%s · %d contract need not covered" % [status.trim_suffix("."), uncovered]
	return status


func _procurement_status() -> String:
	var cultivators: Array = Contacts.contacts_in_role("cultivation")
	if cultivators.is_empty():
		return "No cultivators yet." if GameState.state["home"]["rooms"].has("veinStation") else "Needs the Vein Cultivation Station."
	var veins: Array = VeinList.veins(null, null)
	if veins.is_empty():
		return "No veins yet."
	var assigned := 0
	for contact_id in cultivators:
		assigned += Rooms.cultivator_veins(contact_id).size()
	return "%d of %d veins assigned" % [mini(assigned, veins.size()), veins.size()]


func _recruited_ids() -> Array[String]:
	var contacts: Dictionary = GameState.state["contacts"]
	var recruited: Array[String] = []
	for contact_id in contacts.keys():
		if contacts[contact_id]["recruited"]:
			recruited.append(contact_id)
	return recruited


# The roster, or one person's detail while _staff_person names a recruit.
func _build_staff(content: VBoxContainer) -> void:
	var recruited := _recruited_ids()
	if recruited.has(_staff_person):
		_build_staff_detail(content, _staff_person)
		return
	_staff_person = ""
	content.add_child(UI.heading("Staff", 16))
	content.add_child(UI.muted_label("ROSTER / %02d RECRUITED" % recruited.size()))
	var owed_total := 0
	for wage in GameState.state["business"]["wages"].values():
		owed_total += int(wage.get("owed", 0))
	var summary := UI.card()
	summary["panel"].name = "BizBriefHero"
	summary["content"].add_child(UI.muted_label("PAYROLL EXPOSURE"))
	var summary_row := UI.hbox(8)
	summary_row.add_child(UI.expand_fill(UI.heading("£%d owed" % owed_total, 24)))
	if owed_total > 0:
		summary_row.add_child(UI.tinted_label("ACTION", SIGNAL))
	summary["content"].add_child(summary_row)
	content.add_child(summary["panel"])
	if recruited.is_empty():
		content.add_child(UI.muted_label("No recruited contacts yet."))
	for contact_id in recruited:
		content.add_child(_build_staff_row(contact_id))


# One roster row: name, role, working/owed status; a decision or debt badges it.
func _build_staff_row(contact_id: String) -> Control:
	var role: Variant = Contacts.role_of(contact_id)
	var lines := ["No role" if role == null else String(role).capitalize(), Business.staff_status(contact_id)]
	var badge := ""
	if Hiring.pending_poach_ids().has(contact_id):
		badge = "OFFER"
	elif Business.owed(contact_id) > 0:
		badge = "DUE"
	return _build_nav_row("StaffRow_%s" % contact_id, Contacts.display_name(contact_id), lines, func(): _open_staff_person(contact_id), badge)


# Opens one recruit's detail on the Staff tab: role, skills, pay, assignments
# and any pending wage prompt or poach decision.
func _open_staff_person(contact_id: String) -> void:
	if not _staff_tab_open():
		return
	_tab = STAFF_TAB
	_manage_page = ""
	_vein_chooser_for = ""
	_staff_person = contact_id
	refresh()
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = 0


func _build_staff_detail(content: VBoxContainer, contact_id: String) -> void:
	var nav := UI.hbox(4)
	nav.name = "StaffSubnav"
	nav.add_child(_quiet_link("‹ Staff", _close_staff_person, "StaffBack"))
	var crumb := UI.muted_label("/ %s" % Contacts.display_name(contact_id))
	crumb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nav.add_child(crumb)
	content.add_child(nav)
	if Business.pending_wage_prompts().has(contact_id):
		content.add_child(_build_wage_prompt(contact_id))
	if Hiring.pending_poach_ids().has(contact_id):
		content.add_child(_build_poach_alert(contact_id))
	content.add_child(_build_staff_card(contact_id))
	if Contacts.role_of(contact_id) == "cultivation":
		content.add_child(_brief_section("Assignments"))
		var assignments := UI.card()
		var count: int = Rooms.cultivator_veins(contact_id).size()
		assignments["content"].add_child(UI.muted_label("%d vein%s assigned" % [count, "" if count == 1 else "s"]))
		var link := UI.button("Veins: Manage → Procurement", func(): _open_manage_page(PROCUREMENT_PAGE, contact_id))
		link.name = "StaffAssignmentsLink"
		assignments["content"].add_child(link)
		content.add_child(assignments["panel"])


func _close_staff_person() -> void:
	_staff_person = ""
	refresh()


# Every Stats figure covers BusinessStats.window_days(): completed days only,
# so today's running tally never shows here (R§3.10 Business stats).
func _build_stats(content: VBoxContainer) -> void:
	content.add_child(UI.muted_label(_stats_window_line()))
	content.add_child(_build_stats_hero())
	content.add_child(_brief_section("Revenue vs expenses", "PER DAY"))
	content.add_child(_build_daily_trend())
	content.add_child(_brief_section("Expenses by kind", _stats_period()))
	content.add_child(_build_expense_breakdown())
	content.add_child(_brief_section("Ore collected", "PER DAY"))
	var toggle := UI.hbox()
	for source in ORE_SOURCES:
		var button := UI.button(ORE_SOURCES[source], func(): _set_ore_source(source))
		button.disabled = _ore_source == source
		_style_stats_toggle(button, _ore_source == source)
		toggle.add_child(UI.expand_fill(button))
	content.add_child(toggle)
	content.add_child(_build_chart(_ore_source, "calc_gold_light"))
	content.add_child(_brief_section("Items made", "PER DAY"))
	var items := UI.card()
	var item_row := UI.hbox()
	item_row.add_child(UI.expand_fill(UI.muted_label("TOTAL · %s" % _stats_period())))
	item_row.add_child(UI.heading(str(_stats_total("items")), 18))
	items["content"].add_child(item_row)
	items["content"].add_child(_stats_chart(BusinessStats.series("items"), "pastel_teal"))
	content.add_child(items["panel"])


# The Stats header: which completed days the figures span.
func _stats_window_line() -> String:
	var days := BusinessStats.window_days()
	if days.is_empty():
		return "No full day on the books yet. Figures start once today ends."
	var span := Calendar.format_day(days[0])
	if days.size() > 1:
		span = "%s – %s" % [span, Calendar.format_day(days[-1])]
	return "Completed days only · %s. Today joins once it ends." % span


# Short window label for totals, e.g. "LAST 10 DAYS".
func _stats_period() -> String:
	var count := BusinessStats.window_days().size()
	if count == 1:
		return "LAST DAY"
	return "LAST %d DAYS" % count


# A completed-day LineChart, or an empty note before the first full day.
func _stats_chart(values: Array[int], colour_id: String, prefix: String = "") -> Control:
	if BusinessStats.window_days().is_empty():
		return UI.muted_label("No completed days to chart yet.")
	var chart: LineChart = LineChartScript.new()
	return chart.setup(values, BusinessStats.window_days(), colour_id, prefix)


func _stats_total(metric: String) -> int:
	var total := 0
	for value in BusinessStats.series(metric):
		total += value
	return total


func _build_stats_hero() -> Control:
	var c := UI.card()
	c["panel"].name = "BizBriefHero"
	var row := UI.hbox()
	var revenue := UI.vbox(3)
	revenue.add_child(UI.muted_label("REVENUE"))
	revenue.add_child(UI.heading("£%d" % _stats_total("revenue"), 26))
	row.add_child(UI.expand_fill(revenue))
	var expenses := UI.vbox(3)
	expenses.add_child(UI.muted_label("EXPENSES"))
	expenses.add_child(UI.heading("£%d" % _stats_total("expenses"), 18))
	row.add_child(expenses)
	c["content"].add_child(row)
	c["content"].add_child(UI.muted_label("TOTALS · %s" % _stats_period()))
	return c["panel"]


func _build_daily_trend() -> Control:
	var c := UI.card()
	var chart := _stats_chart(BusinessStats.series("revenue"), "brick_lit", "£")
	if chart is LineChart:
		chart = (chart as LineChart).with_primary_colour(SIGNAL).with_series([{ "values": BusinessStats.series("expenses"), "colour_id": "pastel_blue" }])
	c["content"].add_child(chart)
	var legend := UI.hflow()
	legend.add_child(UI.tinted_label("● REVENUE", SIGNAL))
	legend.add_child(UI.tinted_label("● EXPENSES", GameData.PALETTE.get("pastel_blue", PAPER)))
	c["content"].add_child(legend)
	return c["panel"]


func _style_stats_toggle(button: Button, selected: bool) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = HEADER if selected else CARD
	box.border_color = SIGNAL if selected else LINE
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	box.set_content_margin_all(8)
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, box)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(state, PAPER if selected else MUTED)


# A card holding one completed-day metric's LineChart.
func _build_chart(metric: String, colour_id: String) -> Control:
	var c := UI.card()
	c["content"].add_child(_stats_chart(BusinessStats.series(metric), colour_id))
	return c["panel"]


# Completed-day expense totals by kind; guard wages opens Guard Costs.
func _build_expense_breakdown() -> Control:
	var c := UI.card()
	for line in EXPENSE_KIND_LINES:
		var row := UI.hbox()
		var metric: String = BusinessStats.EXPENSE_KIND_METRICS[line["kind"]]
		if line["kind"] == BusinessStats.EXPENSE_GUARD:
			row.add_child(UI.expand_fill(UI.button("GUARD WAGES ↗", func(): PhoneNav.open_guard_costs())))
		else:
			row.add_child(UI.expand_fill(UI.label(String(line["label"]).to_upper())))
		row.add_child(UI.label("£%d" % _stats_total(metric)))
		c["content"].add_child(row)
	return c["panel"]


func _set_ore_source(source: String) -> void:
	if source == _ore_source:
		return
	_ore_source = source
	refresh()


func _build_staff_card(contact_id: String) -> Control:
	var c := UI.card()
	var role: Variant = Contacts.role_of(contact_id)
	var top := UI.hbox(8)
	var avatar := UI.tinted_label(Contacts.display_name(contact_id).left(2).to_upper(), PAPER)
	avatar.custom_minimum_size = Vector2(34, 34)
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(avatar)
	var identity := UI.vbox(2)
	identity.add_child(UI.heading(Contacts.display_name(contact_id), 14))
	identity.add_child(UI.label("%s · %s" % ["No role" if role == null else String(role).capitalize(), Business.pay_terms(contact_id)]))
	identity.add_child(UI.muted_label(Business.staff_status(contact_id)))
	top.add_child(UI.expand_fill(identity))
	var owed := Business.owed(contact_id)
	if Business.is_unpaid(contact_id):
		top.add_child(UI.tinted_label("DUE", SIGNAL))
	else:
		top.add_child(UI.muted_label("IDLE" if role == null else "CLEAR"))
	c["content"].add_child(top)
	var contact: Dictionary = GameState.state["contacts"][contact_id]
	var caps: Dictionary = GameData.CONTACTS_DEFAULTS.get(contact_id, {}).get("skillCaps", {})
	for skill in SKILLS:
		if not contact.has(skill + "Skill"):
			continue
		var skill_row := UI.hbox(5)
		var skill_label := UI.muted_label(skill.to_upper())
		skill_label.add_theme_font_size_override("font_size", 10)
		skill_row.add_child(UI.expand_fill(skill_label))
		var line := "LV %d / %d XP" % [int(contact[skill + "Skill"]), int(contact.get(skill + "XP", 0))]
		if caps.has(skill):
			line += " · cap %d" % Contacts.skill_cap(contact_id, skill)
		skill_row.add_child(UI.muted_label(line))
		c["content"].add_child(skill_row)
	if Contacts.is_founder(contact_id):
		c["content"].add_child(_build_role_picker(contact_id, role))
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
	var section := UI.vbox(7)
	var title := UI.hbox(6)
	title.add_child(UI.expand_fill(UI.heading("Production", 16)))
	title.add_child(UI.button("Log →" if not _production_log_open else "Log ▾", func(): _toggle_production_log()))
	section.add_child(title)
	var c := UI.card()
	_recipe_anchors = {}

	if not Rooms.production_settings_open():
		c["content"].add_child(UI.muted_label("Requires the Improved Lab."))
	else:
		var recipe_keys := Rooms.production_recipes()
		if not recipe_keys.is_empty():
			var all_on := Rooms.lab_covers_all_contracts()
			var cover_all := UI.button("Stop covering contracts: all" if all_on else "Cover contract needs: all", func(): Rooms.toggle_all_lab_cover_contracts())
			cover_all.name = "CoverAllToggle"
			c["content"].add_child(cover_all)
		for recipe_key in recipe_keys:
			c["content"].add_child(_build_production_recipe_row(recipe_key))
		if recipe_keys.is_empty():
			c["content"].add_child(UI.muted_label("Nothing your crafters can make yet."))
	section.add_child(c["panel"])
	if _production_log_open:
		var log_card := UI.card()
		_production_log_anchor = log_card["panel"]
		log_card["content"].add_child(_build_production_log())
		section.add_child(log_card["panel"])
	return section


func _toggle_production_log() -> void:
	_production_log_open = not _production_log_open
	refresh()
	if _production_log_open and is_instance_valid(_scroll) and is_instance_valid(_production_log_anchor):
		_scroll.ensure_control_visible(_production_log_anchor)


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

	var box := UI.vbox(5)
	box.name = "ProductionRecipe_%s" % recipe_key
	_recipe_anchors[recipe_key] = box
	box.add_child(UI.heading(recipe["name"], 14))

	# Target, contract need and coverage sit above the controls.
	var target_label := UI.muted_label(_target_text(recipe_key, target, covering))
	box.add_child(target_label)
	var on_change := func(value: int) -> void: target_label.text = _target_text(recipe_key, value, covering)
	box.add_child(MapCardStyle.quantity_slider("Target", target, GameData.PRODUCTION_TARGET_MAX, on_change, func(value: int): Rooms.set_lab_threshold(recipe_key, value), 0))

	var target_row := UI.hbox()
	target_row.add_child(UI.button("Stop covering contracts" if covering else "Cover contract needs", func(): Rooms.set_lab_cover_contracts(recipe_key, not covering)))
	box.add_child(target_row)
	var separator := HSeparator.new()
	box.add_child(separator)

	return box


# "Personal target: 5 · contract need: 3 · crafting to: 8" while covering
# contracts, "... · contracts not covered" otherwise.
static func _target_text(recipe_key: String, target: int, covering: bool) -> String:
	var text := "Personal target: %d · contract need: %d" % [target, Rooms.contract_need(recipe_key)]
	if covering:
		return text + " · crafting to: %d" % Rooms.effective_lab_target(recipe_key, target)
	return text + " · contracts not covered"


# Each cultivator's assigned veins, or the Assign vein chooser for one of
# them while _vein_chooser_for names a current cultivator.
func _build_procurement() -> Control:
	var section := UI.vbox(7)
	section.add_child(UI.heading("Procurement", 16))
	var c := UI.card()
	section.add_child(c["panel"])

	var cultivators: Array = Contacts.contacts_in_role("cultivation")
	if cultivators.is_empty():
		if not GameState.state["home"]["rooms"].has("veinStation"):
			c["content"].add_child(UI.muted_label("Requires the Vein Cultivation Station room."))
		else:
			c["content"].add_child(UI.muted_label("No cultivators yet."))
		return section

	var veins: Array = VeinList.veins(null, null)
	if veins.is_empty():
		c["content"].add_child(UI.muted_label("No veins yet."))
		return section

	if cultivators.has(_vein_chooser_for):
		_build_vein_chooser(c["content"], _vein_chooser_for, veins)
		return section
	_vein_chooser_for = ""
	_cultivator_anchors = {}
	for contact_id in cultivators:
		var cultivator := _build_cultivator_section(contact_id, veins)
		_cultivator_anchors[contact_id] = cultivator
		c["content"].add_child(cultivator)
	return section


func _open_vein_chooser(contact_id: String) -> void:
	_vein_chooser_for = contact_id
	refresh()
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = 0


func _close_vein_chooser() -> void:
	_vein_chooser_for = ""
	refresh()


# Closes the chooser first: assign_vein's state_changed rebuilds the page.
func _pick_vein(contact_id: String, vein_id: String) -> void:
	_vein_chooser_for = ""
	Rooms.assign_vein(contact_id, vein_id)


# Veins not on the cultivator's own list, in vein-list order.
func _eligible_veins(contact_id: String, veins: Array) -> Array:
	var assigned: Array = Rooms.cultivator_veins(contact_id)
	return veins.filter(func(vein: Dictionary) -> bool: return not assigned.has(vein["id"]))


# One row per eligible vein; a vein another cultivator holds shows who has
# it, and picking it moves it (Rooms.assign_vein).
func _build_vein_chooser(content: VBoxContainer, contact_id: String, veins: Array) -> void:
	var title := UI.hbox(6)
	title.name = "VeinChooser"
	title.add_child(UI.expand_fill(UI.heading("Assign vein · %s" % Contacts.display_name(contact_id), 14)))
	title.add_child(UI.button("Cancel", func(): _close_vein_chooser()))
	content.add_child(title)
	var eligible := _eligible_veins(contact_id, veins)
	if eligible.is_empty():
		content.add_child(UI.muted_label("Every vein is already theirs."))
	for vein in eligible:
		var vein_id: String = vein["id"]
		var row := UI.vbox(2)
		row.name = "VeinChoice_%s" % vein_id
		var pick := UI.button(_vein_name(vein), func(): _pick_vein(contact_id, vein_id))
		pick.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(pick)
		var held_text: Variant = Rooms.vein_station_target_text(vein_id)
		if held_text != null:
			row.add_child(UI.muted_label(String(held_text)))
		content.add_child(row)


# Scrolls to the offer, contract, recipe or cultivator _open_manage_page() named, once,
# and marks a named card with the signal-red edge. Deferred so the freshly
# built page has its layout before scrolling.
func _focus_page_item() -> void:
	var anchor: Variant = _offer_anchors.get(_page_focus_id, _contract_anchors.get(_page_focus_id, _recipe_anchors.get(_page_focus_id, _cultivator_anchors.get(_page_focus_id))))
	_page_focus_id = ""
	if anchor is PanelContainer:
		var mark := StyleBoxFlat.new()
		mark.bg_color = Color("#1e3040")
		mark.border_color = SIGNAL
		mark.set_border_width_all(1)
		mark.border_width_left = 3
		mark.set_corner_radius_all(6)
		mark.set_content_margin_all(12)
		(anchor as PanelContainer).add_theme_stylebox_override("panel", mark)
	if is_instance_valid(_scroll) and is_instance_valid(anchor):
		_scroll.ensure_control_visible.call_deferred(anchor)


func _vein_name(vein: Dictionary) -> String:
	return "%s — %s" % [GameData.DISTRICTS[vein["district"]]["name"], GameData.ORE_TYPES[vein["oreType"]]["name"]]


# One cultivator: their assigned veins with target controls, then one
# Assign vein button opening the chooser.
func _build_cultivator_section(contact_id: String, veins: Array) -> Control:
	var box := UI.vbox(4)
	box.name = "Cultivator_%s" % contact_id
	var assigned: Array = Rooms.cultivator_veins(contact_id)
	box.add_child(UI.heading(Contacts.display_name(contact_id), 14))
	if assigned.is_empty():
		box.add_child(UI.muted_label("No veins assigned."))
	for vein in veins:
		if assigned.has(vein["id"]):
			box.add_child(_build_procurement_vein_row(vein))
	if not _eligible_veins(contact_id, veins).is_empty():
		box.add_child(UI.button("Assign vein", func(): _open_vein_chooser(contact_id)))
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
		var text := "%d %s" % [line["qty"], _request_type_name(line["kind"], line["type"])]
		if line.has("minTier"):
			text = GameData.OFFER_ASSAY["rankSuffix"] % [text, int(line["minTier"])]
		parts.append(text)
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
	var title := UI.hbox(8)
	title.add_child(UI.expand_fill(UI.heading("Sales", 20)))
	title.add_child(UI.button("History →" if not _sales_history_open else "History ▾", func(): _toggle_sales_history()))
	section.add_child(title)
	if offers.is_empty() and contracts.is_empty():
		section.add_child(UI.muted_label(SALES_EMPTY_TEXT))
	else:
		section.add_child(UI.muted_label("%s. %s" % [_sales_counts(), SALES_STATUS_TEXT[ContractsSystem.has_staffed_sales()]]))
	if not offers.is_empty():
		section.add_child(UI.heading("Offered · %d" % offers.size(), 14))
	_offer_anchors = {}
	_contract_anchors = {}
	for offer in offers:
		var c := UI.card()
		c["panel"].name = "OfferCard_%s" % String(offer["id"]).validate_node_name()
		_offer_anchors[offer["id"]] = c["panel"]
		var request: Dictionary = offer["request"]
		var expiry: String = "expires %s" % Calendar.format_day(int(offer["expiresDay"]))
		var head := UI.hbox(6)
		head.add_child(_build_contract_tags(offer))
		head.add_child(UI.expand_fill(UI.muted_label(_counterparty_text(offer))))
		c["content"].add_child(head)
		if offer.get("source", "") == "renewal":
			c["content"].add_child(UI.muted_label("Renewal. Same order, today's price."))
		elif offer.get("source", "") == OffersSystem.SOURCE_ASSAY:
			c["content"].add_child(UI.muted_label(GameData.OFFER_ASSAY["offerNote"] % int(GameData.OFFER_ASSAY["relation"])))
		c["content"].add_child(UI.heading(_request_summary(request), 13))
		c["content"].add_child(UI.muted_label("%s · £%d per delivery" % [expiry, int(offer["quote"]["payment"])]))
		var poach: Dictionary = offer.get("poach", {})
		var offer_row := head
		if poach.is_empty():
			offer_row.add_child(UI.button("Accept", func(): OffersSystem.accept_offer(offer["id"])))
		else:
			var rival: String = GameData.FACTIONS.get(poach["factionId"], {}).get("shortName", "A rival")
			c["content"].add_child(UI.muted_label("Undercut by %s: £%d. Match it or the buyer walks." % [rival, int(poach["payment"])]))
			offer_row.add_child(UI.button("Match £%d" % int(poach["payment"]), func(): OffersSystem.match_poach(offer["id"])))
		offer_row.add_child(UI.button("Decline", func(): OffersSystem.decline_offer(offer["id"])))
		section.add_child(c["panel"])
	if not contracts.is_empty():
		section.add_child(UI.heading("Accepted · %d" % contracts.size(), 14))
		section.add_child(UI.muted_label("Drag cards to set delivery priority."))
	for index in contracts.size():
		var contract: Dictionary = contracts[index]
		var card := ContractCard.new()
		card.name = "ContractCard_%s" % String(contract["id"]).validate_node_name()
		_contract_anchors[contract["id"]] = card
		card.configure(contract["id"], index)
		var box := UI.vbox(3)
		card.add_child(box)
		var lead := UI.hbox(6)
		lead.add_child(UI.expand_fill(UI.heading("≡ %02d · %s" % [index + 1, _request_summary(contract["request"])], 13)))
		lead.add_child(UI.button("Details →" if _sales_details_id != contract["id"] else "Details ▾", func(): _toggle_sales_details(contract["id"])))
		box.add_child(lead)
		box.add_child(UI.muted_label("%s · due %s · ACTIVE" % [_contract_progress_summary(contract), Calendar.format_day(int(contract["dueDay"]))]))
		var total := 0
		var delivered := 0
		for line in ContractsSystem.request_lines(contract["request"]):
			total += int(line["qty"])
			delivered += ContractsSystem.delivered_qty(contract, line["type"])
		var progress := ProgressBar.new()
		progress.name = "ContractProgress"
		progress.custom_minimum_size.y = 4
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
		if _sales_details_id == contract["id"]:
			var buying: bool = contract.get("buyCalc", false)
			box.add_child(UI.muted_label(str(contract["id"])))
			box.add_child(UI.button("Buy missing calc: on" if buying else "Buy missing calc: off", func(): ContractsSystem.set_buy_calc(contract["id"], not buying)))
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
	c["panel"].name = "BizBriefWagePrompt_%s" % contact_id
	c["content"].add_child(UI.label(MorningAccountsSystem.wage_prompt_label(contact_id)))
	var row := UI.hbox()
	var short: bool = int(GameState.state["player"]["cash"]) < Business.top_up_needed(contact_id)
	row.add_child(UI.expand_fill(UI.action_button("Yes", func(): Business.top_up_and_pay_owed(contact_id), short, "Not enough cash.")))
	row.add_child(UI.expand_fill(UI.button("No", func(): Business.decline_wage_prompt(contact_id))))
	c["content"].add_child(row)
	return c["panel"]


func _build_poach_alert(contact_id: String) -> Control:
	var c := UI.card()
	c["panel"].name = "BizBriefPoach_%s" % contact_id
	c["content"].add_child(UI.label(Hiring.poach_alert_label(contact_id)))
	var row := UI.hbox()
	var match_button := UI.button("Match £%d/wk" % int(Hiring.pending_poach(contact_id)["offer"]), func(): Hiring.match_poach(contact_id))
	match_button.name = "PoachMatch"
	var go_button := UI.button("Let them go", func(): Hiring.decline_poach(contact_id))
	go_button.name = "PoachLetGo"
	row.add_child(UI.expand_fill(match_button))
	row.add_child(UI.expand_fill(go_button))
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
		c["content"].add_child(UI.symbol_row([ItemIcons.part(recipe_key), "Produced %d %s" % [account["production"]["items"][recipe_key], GameData.RECIPES[recipe_key]["name"]]]))
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


func _signed_amount(amount: int) -> String:
	return "+%d" % amount if amount > 0 else str(amount)
