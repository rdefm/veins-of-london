class_name BarometerScreen
extends Control

const SECTION_LABELS := { "economic": "Economic", "social": "Social", "political": "Political" }

var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	Barometer.ensure_progress()
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.back_button("home"))
	_content.add_child(UI.heading("Barometer"))
	_content.add_child(UI.muted_label("Push/pull costs £2000, once per state+direction per day."))

	for section in ["economic", "social", "political"]:
		_content.add_child(_build_section_card(section))

	_content.add_child(_build_influence_actions_card())


func _build_section_card(section: String) -> Control:
	var barometer: Dictionary = GameState.state["barometer"]
	var active_state: String = barometer[section]
	var state_data: Dictionary = GameData.BAROMETER_STATES[section][active_state]

	var c := UI.card()
	c["content"].add_child(UI.heading("%s — %s" % [SECTION_LABELS[section], state_data["label"]], 14))
	c["content"].add_child(UI.muted_label(state_data["description"]))

	for key in state_data["effects"].keys():
		var v = state_data["effects"][key]
		var sign := "+" if v > 0 else ""
		c["content"].add_child(UI.muted_label("%s %s%s" % [key, sign, str(v)]))

	for state_id in GameData.BAROMETER_STATES[section].keys():
		var row := UI.hbox()
		var other_state: Dictionary = GameData.BAROMETER_STATES[section][state_id]
		var progress: int = barometer["progress"].get(section, {}).get(state_id, 0)
		row.add_child(UI.label("%s — %d%%" % [other_state["label"], progress]))
		if state_id != active_state:
			var captured_section: String = section
			var captured_state: String = state_id
			var push_button := UI.button("Push", func(): Barometer.manual_push(captured_section, captured_state))
			push_button.disabled = not Barometer.can_push_pull(section, state_id, "push") or GameState.state["player"]["cash"] < Barometer.MANUAL_ACTION_COST
			row.add_child(push_button)
			var pull_button := UI.button("Pull", func(): Barometer.manual_pull(captured_section, captured_state))
			pull_button.disabled = not Barometer.can_push_pull(section, state_id, "pull") or GameState.state["player"]["cash"] < Barometer.MANUAL_ACTION_COST
			row.add_child(pull_button)
		c["content"].add_child(row)

	return c["panel"]


func _build_influence_actions_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Influence actions", 14))
	c["content"].add_child(UI.muted_label("Data only until M4 — shown greyed with their costs."))
	for action in GameData.BAROMETER_ACTIONS:
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

	return c["panel"]
