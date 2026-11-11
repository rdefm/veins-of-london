class_name SecurityScreen
extends Control

# Security screen, opened from the Security Office tile. Posts tab: see
# SecurityPosts. Guards tab: filter chips plus one GuardWidgets row per hired
# guard (level-sorted), a detail sheet on tap and the Hire board. Costs tab: see
# SecurityCosts. Reads state and calls Muscle / PhoneNav only.

const SCREEN_ID := "security"
const TAB_POSTS := "posts"
const TAB_GUARDS := "guards"
const TAB_COSTS := "costs"

const FILTER_ALL := "all"
const FILTER_POSTED := "posted"
const FILTER_RESERVE := "reserve"
const FILTER_OUT := "out"
const FILTERS := [FILTER_ALL, FILTER_POSTED, FILTER_RESERVE, FILTER_OUT]
const FILTER_LABELS := { "all": "All", "posted": "Posted", "reserve": "Reserve", "out": "Out" }
const GUARDS_FOOTER := "Reserve guards earn no XP. Post them to grow."
const ROW_MIN_HEIGHT := 64.0

var _tab: String = TAB_POSTS
# Guards-tab filter; screen-local, never in state.
var _filter: String = FILTER_ALL
# Costs-tab place rows currently expanded: { place id: true }.
var _costs_open := {}
# Posts-tab folded vein cards the player has expanded: { place id: true }.
var _posts_open := {}


func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if is_queued_for_deletion():
		return
	_tab = PhoneNav.take_security_tab(_tab)
	for child in get_children():
		child.queue_free()
	_build()


func _build() -> void:
	var sc := UI.scroll_container()
	add_child(sc)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", int(UI.top_bar_clearance()) + 16)
	margin.add_theme_constant_override("margin_bottom", int(UI.nav_bar_clearance()) + 16)
	sc.add_child(margin)

	var content := UI.vbox(8)
	margin.add_child(content)

	content.add_child(_build_header())
	content.add_child(UI.muted_label(summary_strip_text()))
	if not Muscle.can_manage():
		content.add_child(UI.muted_label("The Security Office is gone. Guards stay employed, but you can't manage them."))
	content.add_child(_build_tabs())
	match _tab:
		TAB_POSTS:
			_build_posts(content)
		TAB_GUARDS:
			_build_guards(content)
		_:
			SecurityCosts.build(content, _costs_open, _toggle_cost_row)


func _build_header() -> HBoxContainer:
	var row := UI.hbox(8)
	var back := MapCardStyle.text_button("‹ HQ", func(): Nav.go_to("hq_floorplan"))
	back.name = "Back"
	row.add_child(back)
	var title := UI.heading("Security")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(title)
	var hire := MapCardStyle.text_button("Hire ›", func(): Modal.open("guard_hire"), not Muscle.can_manage())
	hire.name = "HireLink"
	row.add_child(hire)
	return row


# "5 guards · 3 posted · 1 ready · 1 out · Mon bill £2100".
static func summary_strip_text() -> String:
	var counts := Muscle.roster_counts()
	return "%d guards · %d posted · %d ready · %d out · Mon bill £%d" % [
		counts["total"], counts["posted"], counts["ready"], counts["out"], GuardUpkeep.next_monday_bill()]


# Three equal columns; the active tab carries an action-colour underline.
func _build_tabs() -> HBoxContainer:
	var row := UI.hbox(0)
	for entry in [[TAB_POSTS, "Posts"], [TAB_GUARDS, "Guards"], [TAB_COSTS, "Costs"]]:
		var tab: String = entry[0]
		var col := UI.vbox(0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var b := MapCardStyle.text_button(entry[1], func(): _set_tab(tab))
		b.name = "Tab_%s" % tab
		col.add_child(b)
		var rule := ColorRect.new()
		rule.custom_minimum_size.y = 2
		rule.color = MapCardStyle.action() if _tab == tab else MapCardStyle.line()
		col.add_child(rule)
		row.add_child(col)
	return row


func _set_tab(tab: String) -> void:
	_tab = tab
	_refresh()


func _toggle_cost_row(place_id: String) -> void:
	if _costs_open.has(place_id):
		_costs_open.erase(place_id)
	else:
		_costs_open[place_id] = true
	_refresh()


# ── Posts tab ─────────────────────────────────────────────────────────

# HQ, each player vein in list order, then Reserve.
static func place_ids() -> Array[String]:
	var ids: Array[String] = [Muscle.POST_HOME]
	for vein in GameState.state["player"]["veins"]:
		ids.append(vein["id"])
	ids.append(Muscle.POST_RESERVE)
	return ids


# "HQ · 2/4" or "Reserve · 3" -- headcount against the post cap.
static func place_header(place_id: String) -> String:
	var count := Muscle.guards_at(place_id).size()
	var cap := Muscle.cap(place_id)
	var label := GuardUpkeep.place_label(place_id)
	if cap < 0:
		return "%s · %d" % [label, count]
	return "%s · %d/%d · Security %s" % [label, count, cap, Muscle.score_text(place_id)]


func _toggle_post_open(place_id: String) -> void:
	if _posts_open.has(place_id):
		_posts_open.erase(place_id)
	else:
		_posts_open[place_id] = true
	_refresh()


func _build_posts(content: VBoxContainer) -> void:
	SecurityPosts.build(content, _posts_open, _toggle_post_open)


# ── Guards tab ────────────────────────────────────────────────────────

func _build_guards(content: VBoxContainer) -> void:
	content.add_child(MapCardStyle.action_button("Hire", func(): Modal.open("guard_hire"), not Muscle.can_manage()))

	var guards := Muscle.guards()
	if guards.is_empty():
		content.add_child(UI.muted_label("No guards. Hire from the board."))
		return
	content.add_child(_build_filters(guards))
	var c := MapCardStyle.card(12)
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(c["panel"])
	for g in filtered_sorted(guards, _filter):
		c["content"].add_child(_build_row(g))
	content.add_child(UI.muted_label(GUARDS_FOOTER))


func _build_filters(guards: Array) -> HBoxContainer:
	var row := UI.hbox(6)
	for f in FILTERS:
		var label: String = FILTER_LABELS[f]
		if f == FILTER_ALL:
			label = "%s %d" % [label, guards.size()]
		var chip := MapCardStyle.chip_button(label, func(): _set_filter(f))
		chip.name = "Filter_%s" % f
		chip.button_pressed = _filter == f
		row.add_child(chip)
	return row


func _set_filter(f: String) -> void:
	_filter = f
	_refresh()


# Guards matching filter `f`, highest level first (stable for ties).
static func filtered_sorted(guards: Array, f: String) -> Array:
	var out: Array = guards.filter(func(g): return filter_matches(g, f))
	out.sort_custom(func(a, b): return int(a["level"]) > int(b["level"]))
	return out


static func filter_matches(g: Dictionary, f: String) -> bool:
	var kind: String = Muscle.status(g)["kind"]
	match f:
		FILTER_POSTED:
			return kind == Muscle.STATUS_POSTED
		FILTER_RESERVE:
			return kind == Muscle.STATUS_RESERVE
		FILTER_OUT:
			return kind == Muscle.STATUS_INJURED or kind == Muscle.STATUS_TRAINING
	return true


# Tappable row: avatar, name + level, XP bar, trait chips, status pill. A flat
# Button sits under the content so the whole row taps.
func _build_row(g: Dictionary) -> Control:
	var gid: String = g["id"]
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = ROW_MIN_HEIGHT
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var tap := Button.new()
	tap.name = "GuardRow_%s" % gid
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.pressed.connect(func(): Modal.open("guard_detail", { "guardId": gid }))
	panel.add_child(tap)

	var body := UI.hbox(10)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(GuardWidgets.avatar(g))
	var mid := UI.vbox(4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := UI.hbox(6)
	top.add_child(MapCardStyle.label(Muscle.short_name(g), 15, MapCardStyle.ink()))
	top.add_child(GuardWidgets.level_badge(g))
	mid.add_child(top)
	mid.add_child(GuardWidgets.xp_bar(g))
	mid.add_child(GuardWidgets.trait_chips(g))
	body.add_child(mid)
	body.add_child(GuardWidgets.status_pill(g))
	panel.add_child(body)
	ignore_mouse(body)
	return panel


static func ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		ignore_mouse(child)


# "Dee O. · L2 · £660/wk · Cheap, Brawler".
static func summary_text(g: Dictionary) -> String:
	return "%s · L%d · £%d/wk · %s" % [Muscle.short_name(g), int(g["level"]), Muscle.wage(g), trait_names(g)]


static func trait_names(g: Dictionary) -> String:
	var names: Array = g["traits"].map(func(t): return GameData.MUSCLE_TRAITS[t]["label"])
	return ", ".join(names)


# The guard's post, with "Injured" while they're out.
static func post_text(g: Dictionary) -> String:
	var text := GuardUpkeep.place_label(g["post"])
	if Muscle.injury_days_left(g) > 0:
		text += " · Injured · %dd" % Muscle.injury_days_left(g)
	if int(g["trainingUntilDay"]) > int(GameState.state["world"]["day"]):
		text += " · Training"
	return text
