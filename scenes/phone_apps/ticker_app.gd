# The Ticker: one headline card per barometer axis, drilling into an axis
# detail view (state list with push/pull, greyed influence actions) when
# state.phoneNav.selectedAxis is set.
class_name TickerApp
extends PhoneApp

const SECTION_LABELS := { "economic": "Economic", "social": "Social", "political": "Political" }


func build(content: VBoxContainer) -> void:
	var selected_axis = GameState.state["phoneNav"].get("selectedAxis")
	if selected_axis == null:
		_build_ticker(content)
	else:
		_build_axis_detail(content, selected_axis)


func _build_ticker(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("The Ticker"))
	content.add_child(UI.muted_label("Push/pull costs £2000, once per state+direction per day."))

	for section in Barometer.SECTIONS:
		content.add_child(_build_headline_card(section))


func _build_headline_card(section: String) -> Control:
	var barometer: Dictionary = GameState.state["barometer"]
	var active_state: String = barometer[section]
	var state_data: Dictionary = GameData.BAROMETER_STATES[section][active_state]
	var headline: String = state_data["headlines"][0]

	var c := UI.card()
	c["content"].add_child(UI.muted_label(SECTION_LABELS[section].to_upper()))
	var headline_label := UI.label(headline)
	headline_label.add_theme_font_size_override("font_size", 16)
	c["content"].add_child(headline_label)
	c["content"].add_child(UI.muted_label(state_data["description"]))

	var hint_state = Barometer.trend_hint_state(section)
	if hint_state != null:
		var hint_label: String = GameData.BAROMETER_STATES[section][hint_state]["label"]
		c["content"].add_child(UI.muted_label("Rumblings: %s building." % hint_label))

	c["content"].add_child(UI.button("Open →", func(): PhoneNav.select_axis(section)))
	return c["panel"]


func _build_axis_detail(content: VBoxContainer, section: String) -> void:
	content.add_child(UI.button("‹ Back to Ticker", func(): PhoneNav.back_to_ticker()))
	content.add_child(UI.heading(SECTION_LABELS[section]))

	var barometer: Dictionary = GameState.state["barometer"]
	var active_state: String = barometer[section]
	var state_data: Dictionary = GameData.BAROMETER_STATES[section][active_state]

	var summary := UI.card()
	summary["content"].add_child(UI.heading(state_data["label"], 14))
	summary["content"].add_child(UI.muted_label(state_data["description"]))
	for key in state_data["effects"].keys():
		var v = state_data["effects"][key]
		var sign := "+" if v > 0 else ""
		summary["content"].add_child(UI.muted_label("%s %s%s" % [key, sign, str(v)]))
	content.add_child(summary["panel"])

	content.add_child(UI.heading("All states", 14))
	for state_id in GameData.BAROMETER_STATES[section].keys():
		content.add_child(_build_state_row(section, state_id, active_state))

	content.add_child(_build_influence_actions_card(section))


func _build_state_row(section: String, state_id: String, active_state: String) -> Control:
	var barometer: Dictionary = GameState.state["barometer"]
	var other_state: Dictionary = GameData.BAROMETER_STATES[section][state_id]
	var progress: int = barometer["progress"].get(section, {}).get(state_id, 0)

	var c := UI.card()
	c["content"].add_child(UI.label("%s — %d%%" % [other_state["label"], progress]))
	c["content"].add_child(UI.bar(progress, 100.0))

	if state_id != active_state:
		var holdings := { "cash": GameState.state["player"]["cash"] }
		var row := UI.hbox()
		var push_button := UI.button(UI.format_cost_label({ "label": "Push", "resource": "cash", "amount": Barometer.MANUAL_ACTION_COST }, holdings), func(): Barometer.manual_push(section, state_id))
		push_button.disabled = not Barometer.can_push_pull(section, state_id, "push") or GameState.state["player"]["cash"] < Barometer.MANUAL_ACTION_COST
		row.add_child(push_button)
		var pull_button := UI.button(UI.format_cost_label({ "label": "Pull", "resource": "cash", "amount": Barometer.MANUAL_ACTION_COST }, holdings), func(): Barometer.manual_pull(section, state_id))
		pull_button.disabled = not Barometer.can_push_pull(section, state_id, "pull") or GameState.state["player"]["cash"] < Barometer.MANUAL_ACTION_COST
		row.add_child(pull_button)
		c["content"].add_child(row)

	return c["panel"]


func _build_influence_actions_card(section: String) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Influence actions", 14))
	c["content"].add_child(UI.muted_label("Data only until M4 — shown greyed with their costs."))

	var any_action := false
	for action in GameData.BAROMETER_ACTIONS:
		if action["section"] != section:
			continue
		any_action = true
		var cost_parts: Array[String] = []
		var cost: Dictionary = action["cost"]
		for key in cost.keys():
			cost_parts.append("%s %s" % [str(cost[key]), key])
		c["content"].add_child(UI.label(action["label"]))
		c["content"].add_child(UI.muted_label(action["description"]))
		c["content"].add_child(UI.muted_label("Cost: %s" % ", ".join(cost_parts)))
		var b := UI.button(action["label"], func(): pass)
		b.disabled = true
		c["content"].add_child(b)

	if not any_action:
		c["content"].add_child(UI.muted_label("None for this axis yet."))

	return c["panel"]
