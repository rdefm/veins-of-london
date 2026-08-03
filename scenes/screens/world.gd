class_name WorldScreen
extends Control

var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.heading("World"))
	_content.add_child(UI.muted_label("Day %d" % GameState.state["world"]["day"]))

	_content.add_child(_build_barometer_summary())
	_content.add_child(_build_property_summary())
	_content.add_child(_build_factions_summary())
	_content.add_child(UI.button("💾 Save & Load", func(): Nav.go_to("save")))


func _build_barometer_summary() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Global Barometer", 14))
	var barometer: Dictionary = GameState.state["barometer"]
	for section in ["economic", "social", "political"]:
		var state_id: String = barometer[section]
		var state_data: Dictionary = GameData.BAROMETER_STATES[section][state_id]
		var has_fx: bool = not state_data["effects"].is_empty()
		c["content"].add_child(UI.label("%s: %s (%s)" % [section.capitalize(), state_data["label"], "active effects" if has_fx else "neutral"]))
	c["content"].add_child(UI.button("View details & influence actions →", func(): Nav.go_to("barometer")))
	return c["panel"]


func _build_property_summary() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Your Property", 14))
	var home: Dictionary = GameState.state["home"]
	var tier: Dictionary = GameData.HOME_TIERS[home["tier"]]
	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
	c["content"].add_child(UI.label("🏠 %s" % tier["name"]))
	c["content"].add_child(UI.muted_label("Raid risk: %d%% · %d security upgrades · %d rooms" % [raid_pct, home["security"].size(), home["rooms"].size()]))
	c["content"].add_child(UI.button("Manage property →", func(): Nav.go_to("hq")))
	return c["panel"]


func _build_factions_summary() -> Control:
	var c := UI.card()
	var joined_names: Array[String] = []
	for faction_id in GameData.FACTIONS.keys():
		if GameState.state["factions"][faction_id]["joined"]:
			joined_names.append(GameData.FACTIONS[faction_id]["shortName"])
	var heading_text := "Factions"
	if not joined_names.is_empty():
		heading_text += " · Member of %s" % ", ".join(joined_names)
	c["content"].add_child(UI.heading(heading_text, 14))

	var faction_ids: Array = GameData.FACTIONS.keys()
	faction_ids.sort_custom(func(a, b): return GameState.state["factions"][a]["relation"] > GameState.state["factions"][b]["relation"])
	var shown := 0
	for faction_id in faction_ids:
		if shown >= 3:
			break
		shown += 1
		var f: Dictionary = GameData.FACTIONS[faction_id]
		var rel: int = GameState.state["factions"][faction_id]["relation"]
		c["content"].add_child(UI.label("%s — %d/%d" % [f["name"], rel, f["joinRelation"]]))

	c["content"].add_child(UI.button("View all factions →", func(): Nav.go_to("factions")))
	return c["panel"]
