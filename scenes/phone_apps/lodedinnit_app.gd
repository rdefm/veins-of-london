# LodedInnit (hiring-spec §10 R9): Feed and People tabs plus a candidate
# profile. The selected tab, open profile and pending float top-up prompt
# are view state held here; hiring goes through Hiring.hire().
#
# PROSE-REVIEW: tab/empty-feed/status strings.
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
		content.add_child(UI.muted_label("Nothing on your feed yet."))
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
			return "Employed"
	return "Open to work"


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
	content.add_child(UI.action_button("Hire · £%d first week" % Hiring.weekly_wage(candidate_id), _on_hire_pressed.bind(candidate_id), reason != "", reason))


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
