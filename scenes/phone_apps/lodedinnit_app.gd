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
const FEED_TAB_NODE_NAME := "LodedInnitFeedTab"
const FEED_INTRO_NODE_NAME := "LodedInnitFeedIntro"
const FEED_CARD_NODE_NAME := "LodedInnitPostCard"
const FEED_BODY_NODE_NAME := "LodedInnitPostBody"
const FEED_ENGAGEMENT_NODE_NAME := "LodedInnitPostEngagement"
const FEED_COMMENT_NODE_NAME := "LodedInnitPostComment"
const PEOPLE_TAB_NODE_NAME := "LodedInnitPeopleTab"
const ROLE_FILTER_NODE_NAME := "LodedInnitRoleFilter"
const ORE_FILTER_NODE_NAME := "LodedInnitOreFilter"
const WAGE_SORT_NODE_NAME := "LodedInnitWageSort"
const PEOPLE_INTRO_NODE_NAME := "LodedInnitPeopleIntro"
const PEOPLE_COUNT_NODE_NAME := "LodedInnitPeopleCount"
const PEOPLE_TOOLBAR_NODE_NAME := "LodedInnitPeopleToolbar"
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
const CARD_FILL := Color("#303034")
const CONTROL_FILL := Color("#343038")
const AVATAR_FILL := Color("#4b4650")
const FEED_CARD_BORDER := Color("#45454b")
const FEED_RULE := Color("#4c4c50")
const FEED_COMMENT_RULE := Color("#66666b")
const OLD_MUTED := Color(0.541176, 0.541176, 0.541176, 1)

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
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(scroll)
	var flush_page := _profile_id == ""
	var page := UI.vbox(0 if flush_page else 10)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 0 if flush_page else 12)
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
	_apply_local_chrome(_root)


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
	wordmark.add_theme_color_override("font_color", _ink())
	var bold := FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.6
	wordmark.add_theme_font_override("font", bold)
	wordmark.autowrap_mode = TextServer.AUTOWRAP_OFF
	wordmark_row.add_child(wordmark)
	var accent := UI.tinted_label("Innit", plum_light())
	accent.add_theme_font_size_override("font_size", 19)
	accent.add_theme_font_override("font", bold)
	accent.autowrap_mode = TextServer.AUTOWRAP_OFF
	wordmark_row.add_child(accent)
	name_box.add_child(wordmark_row)
	var tagline := UI.tinted_label("THE PROFESSIONAL UNDERGROUND", plum_light())
	tagline.add_theme_font_size_override("font_size", 7)
	tagline.add_theme_font_override("font", bold)
	tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_box.add_child(tagline)
	row.add_child(name_box)
	return bar


func _build_tabs() -> Control:
	var tabs := UI.vbox(0)
	tabs.name = TABS_NODE_NAME
	var row := UI.hbox(0)
	tabs.add_child(row)
	for tab in [[FEED_TAB, "Feed"], [PEOPLE_TAB, "People"]]:
		var b := UI.button(tab[1], _set_tab.bind(tab[0]))
		b.name = FEED_TAB_NODE_NAME if tab[0] == FEED_TAB else PEOPLE_TAB_NODE_NAME
		b.toggle_mode = true
		b.button_pressed = _tab == tab[0]
		b.custom_minimum_size.y = 42
		row.add_child(UI.expand_fill(b))
	var rule := HSeparator.new()
	rule.add_theme_stylebox_override("separator", _rule_style())
	rule.add_theme_constant_override("separation", 1)
	tabs.add_child(rule)
	return tabs


func _ink() -> Color:
	return GameData.PALETTE.get("phone_text_primary", Color("#ededee"))


func _muted_ink() -> Color:
	return GameData.PALETTE.get("phone_text_muted", Color("#999a9d"))


func _rule_style() -> StyleBoxLine:
	var style := StyleBoxLine.new()
	style.color = GameData.PALETTE.get("phone_divider", Color("#424246"))
	style.thickness = 1
	return style


func _button_style(fill: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	if border.a > 0.0:
		style.set_border_width_all(1)
		style.border_color = border
	return style


func _style_button(button: Button) -> void:
	var ink := _ink()
	var muted := _muted_ink()
	if button.name == FEED_TAB_NODE_NAME or button.name == PEOPLE_TAB_NODE_NAME:
		var selected := button.button_pressed
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			var style := _button_style(Color.TRANSPARENT)
			style.set_corner_radius_all(0)
			if selected:
				style.border_width_bottom = 2
				style.border_color = plum()
			button.add_theme_stylebox_override(state, style)
		button.add_theme_color_override("font_color", ink if selected else muted)
		button.add_theme_color_override("font_hover_color", ink)
		button.add_theme_color_override("font_pressed_color", ink)
		button.add_theme_color_override("font_hover_pressed_color", ink)
		return
	if button.name == ROLE_FILTER_NODE_NAME or button.name == ORE_FILTER_NODE_NAME or button.name == WAGE_SORT_NODE_NAME:
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			button.add_theme_stylebox_override(state, _button_style(CONTROL_FILL if state == "normal" else BAR_FILL, Color("#5b5360")))
		button.add_theme_color_override("font_color", plum_light() if button.name == WAGE_SORT_NODE_NAME else ink)
		button.add_theme_color_override("font_hover_color", ink)
		button.add_theme_color_override("font_pressed_color", ink)
		button.add_theme_font_size_override("font_size", 11)
		return
	var fill := BAR_FILL
	button.add_theme_stylebox_override("normal", _button_style(fill, plum()))
	button.add_theme_stylebox_override("hover", _button_style(plum()))
	button.add_theme_stylebox_override("pressed", _button_style(plum()))
	button.add_theme_stylebox_override("hover_pressed", _button_style(plum()))
	button.add_theme_stylebox_override("disabled", _button_style(GROUP_FILL, _muted_ink()))
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_hover_pressed_color", ink)
	button.add_theme_color_override("font_disabled_color", muted)


# Style only controls mounted inside this app; the shared theme and phone frame stay untouched.
func _apply_local_chrome(node: Node) -> void:
	if node is Label:
		var label := node as Label
		if not label.has_theme_color_override("font_color"):
			label.add_theme_color_override("font_color", _ink())
		elif label.get_theme_color("font_color") == OLD_MUTED:
			label.add_theme_color_override("font_color", _muted_ink())
	elif node is Button:
		_style_button(node as Button)
	elif node is PanelContainer:
		var panel := node as PanelContainer
		if not panel.has_theme_stylebox_override("panel"):
			panel.add_theme_stylebox_override("panel", UI.bordered_panel_style(CARD_FILL, GameData.PALETTE.get("phone_divider", Color("#424246")), 8, 12, 10))
	elif node is HSeparator:
		var rule := node as HSeparator
		if not rule.has_theme_stylebox_override("separator"):
			rule.add_theme_stylebox_override("separator", _rule_style())
	for child in node.get_children():
		_apply_local_chrome(child)


func _set_tab(tab: String) -> void:
	_tab = tab
	refresh()


func _build_feed(content: VBoxContainer) -> void:
	var intro_margin := MarginContainer.new()
	intro_margin.name = FEED_INTRO_NODE_NAME
	intro_margin.add_theme_constant_override("margin_left", 17)
	intro_margin.add_theme_constant_override("margin_right", 17)
	intro_margin.add_theme_constant_override("margin_top", 20)
	intro_margin.add_theme_constant_override("margin_bottom", 12)
	var intro := UI.vbox(7)
	intro_margin.add_child(intro)
	var heading := UI.tinted_label("Network activity", _ink())
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_font_override("font", _bold_font())
	intro.add_child(heading)
	var subtitle := UI.tinted_label("The people doing the work, and the people saying they are.", _muted_ink())
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_constant_override("line_spacing", 3)
	subtitle.custom_minimum_size.x = 0
	intro.add_child(subtitle)
	content.add_child(intro_margin)
	var entries := LodedInnitFeed.entries()
	if entries.is_empty():
		var empty_margin := MarginContainer.new()
		empty_margin.add_theme_constant_override("margin_left", 17)
		empty_margin.add_theme_constant_override("margin_right", 17)
		empty_margin.add_child(UI.tinted_label("Nothing on your feed yet. Posts arrive as the day goes on.", _muted_ink()))
		content.add_child(empty_margin)
		return
	for entry in entries:
		var card_margin := MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 13)
		card_margin.add_theme_constant_override("margin_right", 13)
		card_margin.add_theme_constant_override("margin_bottom", 11)
		card_margin.add_child(_post_card(LodedInnitFeed.card(entry)))
		content.add_child(card_margin)


# One social card from LodedInnitFeed.card(); any entry kind renders here.
func _post_card(view: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = FEED_CARD_NODE_NAME
	var card_style := UI.bordered_panel_style(CARD_FILL, FEED_CARD_BORDER, 14, 14, 10)
	card_style.content_margin_top = 14
	panel.add_theme_stylebox_override("panel", card_style)
	var content := UI.vbox(0)
	panel.add_child(content)
	var head := UI.hbox(9)
	head.add_child(_avatar(view["initials"]))
	var who := UI.vbox(2)
	var name_label := UI.tinted_label(view["name"], _ink())
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_font_override("font", _bold_font())
	name_label.custom_minimum_size.x = 0
	who.add_child(name_label)
	var meta := UI.tinted_label("%s · %s" % [view["meta"], view["time"]], _muted_ink())
	meta.add_theme_font_size_override("font_size", 10)
	meta.custom_minimum_size.x = 0
	who.add_child(meta)
	head.add_child(UI.expand_fill(who))
	content.add_child(head)
	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_top", 12)
	body_margin.add_theme_constant_override("margin_bottom", 15)
	var body := UI.tinted_label(view["body"], _ink())
	body.name = FEED_BODY_NODE_NAME
	body.add_theme_font_size_override("font_size", 12)
	body.add_theme_constant_override("line_spacing", 4)
	body.custom_minimum_size.x = 0
	body_margin.add_child(body)
	content.add_child(body_margin)
	var rule := HSeparator.new()
	var rule_style := StyleBoxLine.new()
	rule_style.color = FEED_RULE
	rule_style.thickness = 1
	rule.add_theme_stylebox_override("separator", rule_style)
	rule.add_theme_constant_override("separation", 1)
	content.add_child(rule)
	var engage_margin := MarginContainer.new()
	engage_margin.add_theme_constant_override("margin_left", 2)
	engage_margin.add_theme_constant_override("margin_right", 2)
	engage_margin.add_theme_constant_override("margin_top", 10)
	engage_margin.add_theme_constant_override("margin_bottom", 2)
	var engage := UI.hbox(0)
	engage.name = FEED_ENGAGEMENT_NODE_NAME
	engage_margin.add_child(engage)
	var comment_count: int = view["comments"].size()
	engage.add_child(UI.expand_fill(_engagement_count(int(view["likes"]), "likes")))
	engage.add_child(_engagement_count(comment_count, "comment" if comment_count == 1 else "comments"))
	content.add_child(engage_margin)
	for comment in view["comments"]:
		content.add_child(_feed_comment(comment))
	return panel


func _engagement_count(count: int, caption: String) -> HBoxContainer:
	var row := UI.hbox(3)
	var number := UI.tinted_label(str(count), _ink())
	number.add_theme_font_size_override("font_size", 11)
	number.add_theme_font_override("font", _bold_font())
	row.add_child(number)
	var label := UI.tinted_label(caption, _muted_ink())
	label.add_theme_font_size_override("font_size", 11)
	row.add_child(label)
	return row


func _feed_comment(comment: Dictionary) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 1)
	var panel := PanelContainer.new()
	panel.name = FEED_COMMENT_NODE_NAME
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = FEED_COMMENT_RULE
	style.border_width_left = 2
	style.content_margin_left = 10
	panel.add_theme_stylebox_override("panel", style)
	margin.add_child(panel)
	var row := UI.hbox(3)
	panel.add_child(row)
	var author := UI.tinted_label("%s:" % comment["author"], _ink())
	author.add_theme_font_size_override("font_size", 11)
	author.add_theme_font_override("font", _bold_font())
	row.add_child(author)
	var reply := UI.tinted_label(comment["text"], _muted_ink())
	reply.add_theme_font_size_override("font_size", 11)
	reply.add_theme_constant_override("line_spacing", 3)
	reply.custom_minimum_size.x = 0
	row.add_child(UI.expand_fill(reply))
	return margin


func _avatar(initials: String) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = AVATAR_FILL
	style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(36, 36)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var l := UI.tinted_label(initials, _ink())
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_font_override("font", _bold_font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(l)
	return panel


func _build_people(content: VBoxContainer) -> void:
	var groups := LodedInnitDirectory.groups(_role_filter, _ore_filter, _wage_order)
	var count := LodedInnitDirectory.visible_count(groups)
	content.add_child(_people_intro(count))
	content.add_child(_build_controls(groups))
	if groups.is_empty():
		var empty := UI.muted_label("Nobody on LodedInnit matches those filters.")
		empty.name = EMPTY_NODE_NAME
		var empty_margin := _people_margin(12, 16)
		empty_margin.add_child(empty)
		content.add_child(empty_margin)
		return
	for group in groups:
		content.add_child(_group_header(group))
		for candidate_id in group["ids"]:
			content.add_child(_person_row(candidate_id))


func _people_margin(vertical: int, horizontal: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_bottom", vertical)
	return margin


func _people_intro(count: int) -> Control:
	var panel := PanelContainer.new()
	panel.name = PEOPLE_INTRO_NODE_NAME
	var style := StyleBoxFlat.new()
	style.bg_color = BAR_FILL
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 13
	panel.add_theme_stylebox_override("panel", style)
	var body := UI.vbox(4)
	panel.add_child(body)
	var kicker := UI.tinted_label("PEOPLE / %02d" % count, plum_light())
	kicker.add_theme_font_size_override("font_size", 10)
	kicker.add_theme_font_override("font", _bold_font())
	body.add_child(kicker)
	var title := UI.tinted_label("Who’s available.", _ink())
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_font_override("font", _bold_font())
	body.add_child(title)
	var subtitle := UI.tinted_label("A useful network, when the work needs doing.", _muted_ink())
	subtitle.add_theme_font_size_override("font_size", 11)
	body.add_child(subtitle)
	return panel


func _bold_font() -> FontVariation:
	var bold := FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.6
	return bold


func _build_controls(groups: Array) -> Control:
	var margin := _people_margin(10, 16)
	margin.name = PEOPLE_TOOLBAR_NODE_NAME
	var body := UI.vbox(7)
	margin.add_child(body)
	var count_row := UI.hbox(4)
	body.add_child(count_row)
	var count := LodedInnitDirectory.visible_count(groups)
	var open_count := 0
	for group in groups:
		for candidate_id in group["ids"]:
			if Hiring.status(candidate_id)["state"] == Hiring.STATUS_OPEN:
				open_count += 1
	var number := UI.tinted_label(str(count), _ink())
	number.name = PEOPLE_COUNT_NODE_NAME
	number.add_theme_font_size_override("font_size", 12)
	number.add_theme_font_override("font", _bold_font())
	count_row.add_child(number)
	var context := UI.tinted_label("shown · %d open to work" % open_count, _muted_ink())
	context.add_theme_font_size_override("font_size", 11)
	count_row.add_child(context)
	var controls := UI.hbox(6)
	body.add_child(controls)
	controls.add_child(_filter_box(ROLE_FILTER_NODE_NAME, LodedInnitDirectory.role_options(), _role_filter, _on_role_selected))
	controls.add_child(_filter_box(ORE_FILTER_NODE_NAME, LodedInnitDirectory.ore_options(), _ore_filter, _on_ore_selected))
	var wage := UI.button(_wage_label(), _on_wage_pressed)
	wage.name = WAGE_SORT_NODE_NAME
	wage.custom_minimum_size = Vector2(0, 42)
	wage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wage.size_flags_stretch_ratio = 1.05
	wage.tooltip_text = _wage_tooltip()
	controls.add_child(wage)
	return margin


func _filter_box(node_name: String, options: Array, selected_id: String, on_selected: Callable) -> OptionButton:
	var labels: Array = []
	var selected := 0
	for i in options.size():
		labels.append(options[i]["label"])
		if options[i]["id"] == selected_id:
			selected = i
	var select := UI.option_button(labels)
	select.name = node_name
	select.fit_to_longest_item = false
	select.clip_text = true
	select.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	select.custom_minimum_size = Vector2(0, 42)
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.size_flags_stretch_ratio = 0.95 if node_name == ROLE_FILTER_NODE_NAME else 1.05
	select.select(selected)
	var caption := "Role" if node_name == ROLE_FILTER_NODE_NAME else "Ore"
	select.text = "%s: %s" % [caption, options[selected]["label"]]
	select.tooltip_text = "%s: %s" % ["Role" if node_name == ROLE_FILTER_NODE_NAME else "Ore specialism", options[selected]["label"]]
	select.item_selected.connect(func(index: int): on_selected.call(options[index]["id"]))
	return select


func _wage_label() -> String:
	match _wage_order:
		LodedInnitDirectory.WAGE_DESC:
			return "Wage: high→low"
		LodedInnitDirectory.WAGE_ASC:
			return "Wage: low→high"
	return "Wage: roster"


func _wage_tooltip() -> String:
	match _wage_order:
		LodedInnitDirectory.WAGE_DESC:
			return "Wage: high to low"
		LodedInnitDirectory.WAGE_ASC:
			return "Wage: low to high"
	return "Wage: roster order"


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
	style.border_color = _rule_style().color
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	var row := UI.hbox(8)
	panel.add_child(row)
	var title := UI.tinted_label("%s · %d" % [str(group["label"]).to_upper(), group["ids"].size()], plum_light())
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_font_override("font", _bold_font())
	row.add_child(UI.expand_fill(title))
	var guide := UI.tinted_label("Level / cap · £/wk", _muted_ink())
	guide.add_theme_font_size_override("font_size", 10)
	row.add_child(guide)
	return panel


func _person_row(candidate_id: String) -> Control:
	var outer := _people_margin(0, 16)
	outer.name = row_node_name(candidate_id)
	outer.mouse_filter = Control.MOUSE_FILTER_PASS
	var body := UI.vbox(0)
	outer.add_child(body)
	var pad := _people_margin(10, 0)
	body.add_child(pad)
	var row := UI.hbox(9)
	pad.add_child(row)
	row.add_child(_people_avatar(LodedInnitFeed.initials(Contacts.display_name(candidate_id))))
	var who := UI.vbox(3)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(who)
	var name := UI.tinted_label(Contacts.display_name(candidate_id), _ink())
	name.add_theme_font_size_override("font_size", 13)
	name.add_theme_font_override("font", _bold_font())
	name.custom_minimum_size.x = 0
	who.add_child(name)
	var headline := UI.tinted_label(Hiring.candidate(candidate_id)["headline"], _muted_ink())
	headline.add_theme_font_size_override("font_size", 11)
	headline.custom_minimum_size.x = 0
	who.add_child(headline)
	var status := UI.tinted_label("●  %s" % _status_text(candidate_id).to_upper(), plum_light())
	status.add_theme_font_size_override("font_size", 9)
	status.add_theme_font_override("font", _bold_font())
	status.custom_minimum_size.x = 0
	who.add_child(status)
	var right := UI.vbox(4)
	row.add_child(right)
	var wage := UI.tinted_label("£%d" % Hiring.weekly_wage(candidate_id), copper())
	wage.add_theme_font_size_override("font_size", 12)
	wage.add_theme_font_override("font", _bold_font())
	wage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(wage)
	var level := UI.tinted_label("LV %d/%d" % [Hiring.level(candidate_id), Hiring.level_cap(candidate_id)], _muted_ink())
	level.add_theme_font_size_override("font_size", 10)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(level)
	var chevron := UI.tinted_label("›", plum_light())
	chevron.add_theme_font_size_override("font_size", 16)
	chevron.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(chevron)
	var rule := HSeparator.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(rule)
	_ignore_mouse_tree(outer)
	outer.mouse_filter = Control.MOUSE_FILTER_PASS
	outer.gui_input.connect(_on_person_row_input.bind(outer, candidate_id))
	return outer


func _on_person_row_input(event: InputEvent, row: Control, candidate_id: String) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			row.set_meta("tap_start", event.position)
		elif row.has_meta("tap_start"):
			var start: Vector2 = row.get_meta("tap_start")
			row.remove_meta("tap_start")
			if start.distance_to(event.position) < 12.0:
				_open_profile(candidate_id)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			row.set_meta("tap_start", event.position)
		elif row.has_meta("tap_start"):
			var start: Vector2 = row.get_meta("tap_start")
			row.remove_meta("tap_start")
			if start.distance_to(event.position) < 12.0:
				_open_profile(candidate_id)


func _people_avatar(initials: String) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = AVATAR_FILL
	style.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(31, 31)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var label := UI.tinted_label(initials, plum_light())
	label.add_theme_font_size_override("font_size", 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _ignore_mouse_tree(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse_tree(child)


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
