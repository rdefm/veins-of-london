# LodedInnit (hiring-spec §10 R9): Feed and People tabs plus a candidate
# profile, mounted as its own root under the plum/copper brand chrome
# (docs/ui-vision.md §10 "LodedInnit exception"). The selected tab, People
# filters and wage order, open profile and pending float top-up prompt are
# view state held here; the directory projection is LodedInnitDirectory and
# hiring goes through Hiring.hire().
#
# PROSE-REVIEW: tab/empty-feed/status strings, feed intro, People controls, empty-directory and group strings, profile stat captions and seat line.
class_name LodedInnitApp
extends PhoneApp

const FEED_TAB := "feed"
const PEOPLE_TAB := "people"
const ROOT_NODE_NAME := "LodedInnitRoot"
const BRAND_BAR_NODE_NAME := "LodedInnitBrandBar"
const TABS_NODE_NAME := "LodedInnitTabs"
const ROLE_FILTER_NODE_NAME := "LodedInnitRoleFilter"
const ORE_FILTER_NODE_NAME := "LodedInnitOreFilter"
const WAGE_SORT_NODE_NAME := "LodedInnitWageSort"
const EMPTY_NODE_NAME := "LodedInnitEmpty"
const ROW_NODE_PREFIX := "LodedInnitRow_"
const PROFILE_ROLE_NODE_NAME := "LodedInnitProfileRole"
const PROFILE_LEVEL_NODE_NAME := "LodedInnitProfileLevel"
const PROFILE_WAGE_NODE_NAME := "LodedInnitProfileWage"
const PROFILE_XP_NODE_NAME := "LodedInnitProfileExperience"
const PROFILE_SEAT_NODE_NAME := "LodedInnitProfileSeats"
const HIRE_AREA_NODE_NAME := "LodedInnitHireArea"
const HIRE_BUTTON_NODE_NAME := "LodedInnitHireButton"
const HIRE_REASON_NODE_NAME := "LodedInnitHireReason"
const TOP_UP_QUESTION_NODE_NAME := "LodedInnitTopUpQuestion"
const TOP_UP_YES_NODE_NAME := "LodedInnitTopUpYes"
const TOP_UP_NO_NODE_NAME := "LodedInnitTopUpNo"
const TOP_UP_REASON_NODE_NAME := "LodedInnitTopUpReason"
const LOGO_PATH := "res://assets/phone/icons/lodedinnit.png"

const PLUM_FALLBACK := Color("#81549a")
const PLUM_LIGHT_FALLBACK := Color("#dab8eb")
const COPPER_FALLBACK := Color("#dda477")
const BAR_FILL := Color("#3c3042")
const GROUP_FILL := Color("#323236")

var _tab := PEOPLE_TAB
var _profile_id := ""
var _top_up_id := ""
var _role_filter := LodedInnitDirectory.ALL
var _ore_filter := LodedInnitDirectory.ALL
var _wage_order := LodedInnitDirectory.WAGE_ROSTER
var _root: Control = null


static func plum() -> Color:
	return GameData.PALETTE.get("lodedinnit_plum", PLUM_FALLBACK)


static func plum_light() -> Color:
	return GameData.PALETTE.get("lodedinnit_plum_light", PLUM_LIGHT_FALLBACK)


static func copper() -> Color:
	return GameData.PALETTE.get("lodedinnit_copper", COPPER_FALLBACK)


static func row_node_name(candidate_id: String) -> String:
	return ROW_NODE_PREFIX + candidate_id


func build(_content: VBoxContainer) -> void:
	_root = UI.vbox(0)
	_root.name = ROOT_NODE_NAME
	shell.mount_custom_root(_root)
	_root.add_child(_build_brand_bar())
	if _profile_id == "":
		_root.add_child(_build_tabs())
	var scroll := UI.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(scroll)
	var page := UI.vbox(10)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	margin.add_child(page)
	scroll.add_child(margin)
	if _profile_id != "":
		_build_profile(page)
		_root.add_child(_build_hire_area(_profile_id))
	elif _tab == FEED_TAB:
		LodedInnitFeed.mark_seen()
		_build_feed(page)
	else:
		_build_people(page)


func teardown() -> void:
	if _root != null:
		if _root.get_parent() != null:
			_root.get_parent().remove_child(_root)
		_root.queue_free()
		_root = null


# Logo and wordmark on the plum bar; back returns to the phone home.
func _build_brand_bar() -> Control:
	var style := StyleBoxFlat.new()
	style.bg_color = BAR_FILL
	style.border_color = plum()
	style.border_width_bottom = 2
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	var bar := PanelContainer.new()
	bar.name = BRAND_BAR_NODE_NAME
	bar.add_theme_stylebox_override("panel", style)
	var row := UI.hbox(8)
	bar.add_child(row)
	var back := UI.button("‹", func(): PhoneNav.go_home())
	back.flat = true
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_color_override("font_color", plum_light())
	row.add_child(back)
	var logo := TextureRect.new()
	logo.texture = load(LOGO_PATH)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(31, 31)
	logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(logo)
	var name_box := UI.vbox(0)
	var wordmark_row := UI.hbox(0)
	var wordmark := UI.label("Loded")
	wordmark.add_theme_font_size_override("font_size", 19)
	wordmark.autowrap_mode = TextServer.AUTOWRAP_OFF
	wordmark_row.add_child(wordmark)
	var accent := UI.tinted_label("Innit", plum_light())
	accent.add_theme_font_size_override("font_size", 19)
	accent.autowrap_mode = TextServer.AUTOWRAP_OFF
	wordmark_row.add_child(accent)
	name_box.add_child(wordmark_row)
	var tagline := UI.tinted_label("THE PROFESSIONAL UNDERGROUND", plum_light())
	tagline.add_theme_font_size_override("font_size", 8)
	tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_box.add_child(tagline)
	row.add_child(name_box)
	return bar


func _build_tabs() -> Control:
	var tabs := UI.hbox(0)
	tabs.name = TABS_NODE_NAME
	for tab in [[FEED_TAB, "Feed"], [PEOPLE_TAB, "People"]]:
		var b := UI.button(tab[1], _set_tab.bind(tab[0]))
		b.disabled = _tab == tab[0]
		tabs.add_child(UI.expand_fill(b))
	return tabs


func _set_tab(tab: String) -> void:
	_tab = tab
	refresh()


func _build_feed(content: VBoxContainer) -> void:
	content.add_child(UI.heading("Network activity", 18))
	var entries := LodedInnitFeed.entries()
	if entries.is_empty():
		content.add_child(UI.muted_label("Nothing on your feed yet. Posts arrive as the day goes on."))
		return
	content.add_child(UI.muted_label("The people doing the work, and the people saying they are."))
	for entry in entries:
		content.add_child(_post_card(LodedInnitFeed.card(entry)))


# One social card from LodedInnitFeed.card(); any entry kind renders here.
func _post_card(view: Dictionary) -> Control:
	var c := UI.card()
	var head := UI.hbox(9)
	head.add_child(_avatar(view["initials"]))
	var who := UI.vbox(2)
	who.add_child(UI.label(view["name"]))
	who.add_child(UI.muted_label("%s · %s" % [view["meta"], view["time"]]))
	head.add_child(UI.expand_fill(who))
	c["content"].add_child(head)
	c["content"].add_child(UI.label(view["body"]))
	var engage := UI.hbox()
	var comment_count: int = view["comments"].size()
	engage.add_child(UI.expand_fill(UI.muted_label("%d likes" % view["likes"])))
	engage.add_child(UI.muted_label("%d comment%s" % [comment_count, "" if comment_count == 1 else "s"]))
	c["content"].add_child(engage)
	for comment in view["comments"]:
		c["content"].add_child(UI.muted_label("%s: %s" % [comment["author"], comment["text"]]))
	return c["panel"]


func _avatar(initials: String) -> Control:
	var panel := PanelContainer.new()
	var style := UI.bordered_panel_style(plum(), plum_light(), 18, 4, 4)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(36, 36)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var l := UI.label(initials)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(l)
	return panel


func _build_people(content: VBoxContainer) -> void:
	content.add_child(_build_controls())
	var groups := LodedInnitDirectory.groups(_role_filter, _ore_filter, _wage_order)
	if groups.is_empty():
		var empty := UI.muted_label("Nobody on LodedInnit matches those filters.")
		empty.name = EMPTY_NODE_NAME
		content.add_child(empty)
		return
	content.add_child(UI.muted_label("%d people" % LodedInnitDirectory.visible_count(groups)))
	for group in groups:
		content.add_child(_group_header(group))
		for candidate_id in group["ids"]:
			content.add_child(_person_row(candidate_id))


func _build_controls() -> Control:
	var row := UI.hflow(10)
	row.add_child(_filter_box("Role", ROLE_FILTER_NODE_NAME, LodedInnitDirectory.role_options(), _role_filter, _on_role_selected))
	row.add_child(_filter_box("Ore specialism", ORE_FILTER_NODE_NAME, LodedInnitDirectory.ore_options(), _ore_filter, _on_ore_selected))
	var wage_box := UI.vbox(2)
	wage_box.add_child(UI.muted_label("Pay"))
	var wage := UI.button(_wage_label(), _on_wage_pressed)
	wage.name = WAGE_SORT_NODE_NAME
	wage_box.add_child(wage)
	row.add_child(wage_box)
	return row


func _filter_box(caption: String, node_name: String, options: Array, selected_id: String, on_selected: Callable) -> Control:
	var box := UI.vbox(2)
	box.add_child(UI.muted_label(caption))
	var labels: Array = []
	var selected := 0
	for i in options.size():
		labels.append(options[i]["label"])
		if options[i]["id"] == selected_id:
			selected = i
	var select := UI.option_button(labels)
	select.name = node_name
	select.select(selected)
	select.item_selected.connect(func(index: int): on_selected.call(options[index]["id"]))
	box.add_child(select)
	return box


func _wage_label() -> String:
	match _wage_order:
		LodedInnitDirectory.WAGE_DESC:
			return "Wage · high to low"
		LodedInnitDirectory.WAGE_ASC:
			return "Wage · low to high"
	return "Wage"


func _on_role_selected(role_id: String) -> void:
	_role_filter = role_id
	refresh()


func _on_ore_selected(ore_id: String) -> void:
	_ore_filter = ore_id
	refresh()


func _on_wage_pressed() -> void:
	_wage_order = LodedInnitDirectory.next_wage_order(_wage_order)
	refresh()


func _group_header(group: Dictionary) -> Control:
	var style := StyleBoxFlat.new()
	style.bg_color = GROUP_FILL
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	var row := UI.hbox(8)
	panel.add_child(row)
	row.add_child(UI.expand_fill(UI.tinted_label("%s · %d" % [str(group["label"]).to_upper(), group["ids"].size()], plum_light())))
	row.add_child(UI.muted_label("Lv/cap · £/wk"))
	return panel


func _person_row(candidate_id: String) -> Control:
	var box := UI.vbox(2)
	box.name = row_node_name(candidate_id)
	var top := UI.hbox(8)
	top.add_child(_avatar(LodedInnitFeed.initials(Contacts.display_name(candidate_id))))
	var who := UI.vbox(2)
	var name_button := UI.button(Contacts.display_name(candidate_id), _open_profile.bind(candidate_id))
	name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_button.flat = true
	who.add_child(name_button)
	who.add_child(UI.muted_label(Hiring.candidate(candidate_id)["headline"]))
	who.add_child(UI.tinted_label(_status_text(candidate_id), plum_light()))
	top.add_child(UI.expand_fill(who))
	var right := UI.vbox(2)
	var wage := UI.tinted_label("£%d" % Hiring.weekly_wage(candidate_id), copper())
	wage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(wage)
	var level := UI.muted_label("Lv %d/%d" % [Hiring.level(candidate_id), Hiring.level_cap(candidate_id)])
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(level)
	top.add_child(right)
	box.add_child(top)
	box.add_child(HSeparator.new())
	return box


func _status_text(candidate_id: String) -> String:
	match Hiring.status(candidate_id)["state"]:
		Hiring.STATUS_OURS:
			return "Works for you"
		Hiring.STATUS_EMPLOYED:
			return "Employed at %s" % _employer_name(candidate_id)
	return "Open to work"


func _employer_name(candidate_id: String) -> String:
	return GameData.FACTIONS[Hiring.employer(candidate_id)]["name"]


func _open_profile(candidate_id: String) -> void:
	_profile_id = candidate_id
	_top_up_id = ""
	refresh()


func _close_profile() -> void:
	_profile_id = ""
	_top_up_id = ""
	refresh()


func _build_profile(content: VBoxContainer) -> void:
	var candidate_id := _profile_id
	var data := Hiring.candidate(candidate_id)
	content.add_child(UI.button("‹ People", _close_profile))
	content.add_child(UI.heading(Contacts.display_name(candidate_id)))
	content.add_child(UI.muted_label(data["headline"]))
	content.add_child(UI.tinted_label(_status_text(candidate_id), plum_light()))

	var c := UI.card()
	var body: VBoxContainer = c["content"]
	body.add_child(_profile_stat("Role", Hiring.role(candidate_id)["label"], PROFILE_ROLE_NODE_NAME))
	body.add_child(_profile_stat("Level", "%d / %d" % [Hiring.level(candidate_id), Hiring.level_cap(candidate_id)], PROFILE_LEVEL_NODE_NAME))
	body.add_child(_profile_stat("Wage", "£%d a week" % Hiring.weekly_wage(candidate_id), PROFILE_WAGE_NODE_NAME))
	body.add_child(_profile_stat("Experience", LodedInnitProfile.experience_text(candidate_id), PROFILE_XP_NODE_NAME))
	body.add_child(_profile_stat("Room", LodedInnitProfile.seat_text(candidate_id), PROFILE_SEAT_NODE_NAME))
	body.add_child(_speciality_pips(data.get("specialities", [])))
	content.add_child(c["panel"])

	var about := UI.label(data["about"])
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(about)


func _profile_stat(caption: String, value: String, node_name: String) -> Control:
	var row := UI.hbox(8)
	row.add_child(UI.muted_label(caption))
	var v := UI.tinted_label(value, copper())
	v.name = node_name
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(UI.expand_fill(v))
	return row


# Lower hire area, pinned under the scrolling profile: hire/poach action with
# its block reason, or the float top-up question.
func _build_hire_area(candidate_id: String) -> Control:
	var panel := PanelContainer.new()
	panel.name = HIRE_AREA_NODE_NAME
	var style := StyleBoxFlat.new()
	style.bg_color = BAR_FILL
	for side in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, 12)
	panel.add_theme_stylebox_override("panel", style)
	var box := UI.vbox(6)
	panel.add_child(box)
	if Hiring.status(candidate_id)["state"] == Hiring.STATUS_OURS:
		box.add_child(UI.tinted_label("Works for you", plum_light()))
		return panel
	if _top_up_id == candidate_id:
		_build_top_up_prompt(box, candidate_id)
		return panel
	var reason := Hiring.hire_block_reason(candidate_id)
	var verb := "Hire"
	if Hiring.is_employed(candidate_id):
		verb = "Poach"
		var note := UI.muted_label("Wage +%d%% for good. Costs %d relation with %s." % [roundi((Hiring.poach_mult() - 1.0) * 100.0), Hiring.poach_relation_cost(), _employer_name(candidate_id)])
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(note)
	var hire := UI.button("%s · £%d first week" % [verb, Hiring.weekly_wage(candidate_id)], _on_hire_pressed.bind(candidate_id))
	hire.disabled = reason != ""
	hire.name = HIRE_BUTTON_NODE_NAME
	box.add_child(hire)
	if reason != "":
		var why := UI.muted_label(reason)
		why.name = HIRE_REASON_NODE_NAME
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(why)
	return panel


func _speciality_pips(specialities: Array) -> Control:
	var row := UI.hbox(4)
	row.add_child(UI.muted_label("Specialities"))
	for ore_type in specialities:
		var glyph := SymbolGlyph.new()
		glyph.symbol = GameData.ORE_TYPES[ore_type]["symbol"]
		glyph.draw_fallback = SymbolGlyph.ore_fallback(ore_type)
		glyph.custom_minimum_size = Vector2(UI.SYMBOL_GLYPH_SIZE, UI.SYMBOL_GLYPH_SIZE)
		glyph.glyph_radius = UI.SYMBOL_GLYPH_SIZE * 0.34
		glyph.color = MapPalette.ore_colour_in(ore_type, true)
		glyph.tooltip_text = GameData.ORE_TYPES[ore_type].get("name", ore_type)
		row.add_child(glyph)
	return row


func _on_hire_pressed(candidate_id: String) -> void:
	var result := Hiring.hire(candidate_id)
	if not result["ok"] and result.has("topUp"):
		_top_up_id = candidate_id
		refresh()


func _build_top_up_prompt(content: VBoxContainer, candidate_id: String) -> void:
	var needed := Hiring.top_up_needed(candidate_id)
	var question := UI.label("Top up the float by £%d to cover this hire?" % needed)
	question.name = TOP_UP_QUESTION_NODE_NAME
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(question)
	var row := UI.hbox()
	var cash := int(GameState.state["player"]["cash"])
	var yes := UI.button("Yes", _on_top_up_yes.bind(candidate_id))
	yes.disabled = cash < needed
	yes.name = TOP_UP_YES_NODE_NAME
	var no := UI.button("No", _on_top_up_no)
	no.name = TOP_UP_NO_NODE_NAME
	row.add_child(UI.expand_fill(yes))
	row.add_child(UI.expand_fill(no))
	content.add_child(row)
	if cash < needed:
		var why := UI.muted_label("Not enough cash.")
		why.name = TOP_UP_REASON_NODE_NAME
		content.add_child(why)


func _on_top_up_yes(candidate_id: String) -> void:
	_top_up_id = ""
	Hiring.hire(candidate_id, true)
	refresh()


func _on_top_up_no() -> void:
	_top_up_id = ""
	refresh()
