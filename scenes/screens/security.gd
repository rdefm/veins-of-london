class_name SecurityScreen
extends Control

# Security screen, opened from the Security Office tile. Posts tab: HQ, each
# vein and Reserve with headcount, weekly cost and kit status, + Assign and
# → Reserve. Guards tab: one row per hired guard (short name, level, wage,
# traits, post), a detail sheet on tap and the Hire board. Costs tab: see
# SecurityCosts. Reads state and calls Muscle / PhoneNav only.

const SCREEN_ID := "security"
const TAB_POSTS := "posts"
const TAB_GUARDS := "guards"
const TAB_COSTS := "costs"

var _tab: String = TAB_POSTS
# Costs-tab place rows currently expanded: { place id: true }.
var _costs_open := {}


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

	content.add_child(UI.back_button("hq_floorplan"))
	content.add_child(UI.heading("Security"))
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


func _build_tabs() -> HBoxContainer:
	var row := UI.hbox(8)
	for entry in [[TAB_POSTS, "Posts"], [TAB_GUARDS, "Guards"], [TAB_COSTS, "Costs"]]:
		var tab: String = entry[0]
		var b := MapCardStyle.option_row(entry[1], func(): _set_tab(tab), _tab == tab)
		b.name = "Tab_%s" % tab
		row.add_child(b)
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


# Weekly wages of everyone posted at `place_id`, "£1500/week" or "".
static func place_cost_text(place_id: String) -> String:
	var total := int(GuardUpkeep.muscle_wages_by_place().get(place_id, 0))
	return "£%d/week" % total if total > 0 else ""


# "Kit 1/4 …" for HQ and veins; "" for Reserve (no kit).
static func place_kit_text(place_id: String) -> String:
	if place_id == Muscle.POST_RESERVE:
		return ""
	if place_id == Muscle.POST_HOME:
		return GuardKit.status_text(GameState.state["home"].get("guardKit", {}), GuardKit.hq_capacity())
	var vein: Variant = Cultivating.find_vein(place_id)
	if vein == null:
		return ""
	return GuardKit.status_text(vein.get("guardKit", {}), GuardKit.capacity(vein))


func _build_posts(content: VBoxContainer) -> void:
	for place_id in place_ids():
		var c := MapCardStyle.card(12)
		c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c["panel"].name = "Post_%s" % place_id
		content.add_child(c["panel"])
		c["content"].add_child(MapCardStyle.section_label(place_header(place_id)))
		var details: Array[String] = []
		for text in [place_cost_text(place_id), place_kit_text(place_id)]:
			if text != "":
				details.append(text)
		if not details.is_empty():
			c["content"].add_child(UI.muted_label(" · ".join(details)))
		for g in Muscle.guards_at(place_id):
			c["content"].add_child(_build_post_row(g))
		if place_id != Muscle.POST_RESERVE:
			var full: bool = Muscle.guards_at(place_id).size() >= Muscle.cap(place_id)
			var assign := MapCardStyle.action_button("+ Assign", func(): Modal.open("guard_assign", { "place": place_id }), full or not Muscle.can_manage())
			assign.name = "Assign_%s" % place_id
			c["content"].add_child(assign)


func _build_post_row(g: Dictionary) -> Control:
	var gid: String = g["id"]
	var row := UI.hbox(6)
	row.add_child(UI.expand_fill(MapCardStyle.option_row(summary_text(g), func(): Modal.open("guard_detail", { "guardId": gid }))))
	if g["post"] != Muscle.POST_RESERVE:
		var to_reserve := MapCardStyle.text_button("→ Reserve", func(): Muscle.post(gid, Muscle.POST_RESERVE), not Muscle.can_manage())
		to_reserve.name = "ToReserve_%s" % gid
		row.add_child(to_reserve)
	return row


# ── Guards tab ────────────────────────────────────────────────────────

func _build_guards(content: VBoxContainer) -> void:
	content.add_child(MapCardStyle.action_button("Hire", func(): Modal.open("guard_hire"), not Muscle.can_manage()))

	var guards := Muscle.guards()
	if guards.is_empty():
		content.add_child(UI.muted_label("No guards. Hire from the board."))
		return
	var c := MapCardStyle.card(12)
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(c["panel"])
	for g in guards:
		c["content"].add_child(_build_row(g))


func _build_row(g: Dictionary) -> Button:
	var gid: String = g["id"]
	var row := MapCardStyle.option_row(row_text(g), func(): Modal.open("guard_detail", { "guardId": gid }))
	row.name = "GuardRow_%s" % gid
	row.custom_minimum_size.y = maxf(row.custom_minimum_size.y, 52.0)
	return row


# "Dee O. · L2 · £660/wk · Cheap, Brawler\nReserve ›".
static func row_text(g: Dictionary) -> String:
	return "%s\n%s ›" % [summary_text(g), post_text(g)]


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
