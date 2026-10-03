# LodedInnit (hiring-spec §10 R9): Feed and People tabs plus a candidate
# profile. The selected tab, open profile and pending float top-up prompt
# are view state held here; hiring goes through Hiring.hire().
#
# PROSE-REVIEW: tab/empty-feed/status strings, feed intro.
class_name LodedInnitApp
extends PhoneApp

const FEED_TAB := "feed"
const PEOPLE_TAB := "people"

var _tab := PEOPLE_TAB
var _profile_id := ""
var _top_up_id := ""


func build(content: VBoxContainer) -> void:
	if _profile_id != "":
		_build_profile(content)
		return
	content.add_child(back_button())
	content.add_child(UI.heading("LodedInnit"))
	content.add_child(_build_tabs())
	if _tab == FEED_TAB:
		LodedInnitFeed.mark_seen()
		_build_feed(content)
	else:
		_build_people(content)


func _build_tabs() -> Control:
	var tabs := UI.hbox()
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
	var style := UI.bordered_panel_style(Color(0.506, 0.329, 0.604), Color(0.855, 0.722, 0.922), 18, 4, 4)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(36, 36)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var l := UI.label(initials)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(l)
	return panel


func _build_people(content: VBoxContainer) -> void:
	for candidate_id in Hiring.candidate_ids():
		var c := UI.card()
		var name_button := UI.button(Contacts.display_name(candidate_id), _open_profile.bind(candidate_id))
		name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		c["content"].add_child(name_button)
		c["content"].add_child(UI.muted_label(Hiring.candidate(candidate_id)["headline"]))
		c["content"].add_child(UI.label("%s · Lv%d · %s" % [Hiring.role(candidate_id)["label"], Hiring.level(candidate_id), _status_text(candidate_id)]))
		content.add_child(c["panel"])


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

	var c := UI.card()
	c["content"].add_child(UI.label("%s · %s" % [Hiring.role(candidate_id)["label"], _status_text(candidate_id)]))
	c["content"].add_child(UI.label("Level %d → cap %d" % [Hiring.level(candidate_id), Hiring.level_cap(candidate_id)]))
	c["content"].add_child(UI.label("£%d a week" % Hiring.weekly_wage(candidate_id)))
	c["content"].add_child(_speciality_pips(data.get("specialities", [])))
	content.add_child(c["panel"])

	var about := UI.label(data["about"])
	content.add_child(about)

	if Hiring.status(candidate_id)["state"] == Hiring.STATUS_OURS:
		return
	if _top_up_id == candidate_id:
		_build_top_up_prompt(content, candidate_id)
		return
	var reason := Hiring.hire_block_reason(candidate_id)
	var verb := "Hire"
	if Hiring.is_employed(candidate_id):
		verb = "Poach"
		content.add_child(UI.muted_label("Wage +%d%% for good. Costs %d relation with %s." % [roundi((Hiring.poach_mult() - 1.0) * 100.0), Hiring.poach_relation_cost(), _employer_name(candidate_id)]))
	content.add_child(UI.action_button("%s · £%d first week" % [verb, Hiring.weekly_wage(candidate_id)], _on_hire_pressed.bind(candidate_id), reason != "", reason))


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
	content.add_child(UI.label("Top up the float by £%d to cover this hire?" % needed))
	var row := UI.hbox()
	var cash := int(GameState.state["player"]["cash"])
	row.add_child(UI.expand_fill(UI.action_button("Yes", _on_top_up_yes.bind(candidate_id), cash < needed, "Not enough cash.")))
	row.add_child(UI.expand_fill(UI.button("No", _on_top_up_no)))
	content.add_child(row)


func _on_top_up_yes(candidate_id: String) -> void:
	_top_up_id = ""
	Hiring.hire(candidate_id, true)
	refresh()


func _on_top_up_no() -> void:
	_top_up_id = ""
	refresh()
