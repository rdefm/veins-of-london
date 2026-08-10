class_name VeinsScreen
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

	var player: Dictionary = GameState.state["player"]
	var skill: int = player["cultivatingSkill"]
	var chance_pct: int = int(round(Cultivating.get_cult_chance(skill) * 100))

	_content.add_child(UI.back_button("home"))
	_content.add_child(UI.heading("Veins"))
	_content.add_child(UI.muted_label("%d active · Lv%d · %d%% success · +%d dev/cultivate" % [player["veins"].size(), skill, chance_pct, Cultivating.get_bar_gain(skill)]))

	if player["veins"].is_empty():
		_content.add_child(UI.muted_label("No veins yet. Seed one from an unclaimed site on the Map tab."))
	else:
		for vein in player["veins"]:
			_content.add_child(_build_vein_card(vein))


func _build_vein_card(vein: Dictionary) -> Control:
	var c := UI.card()
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
	var security: Dictionary = GameData.VEIN_SECURITY[vein["security"]]

	c["content"].add_child(UI.heading("%s %s — Lv%d %s" % [ore["symbol"], ore["name"], vein["level"], vein["levelLabel"]], 15))
	c["content"].add_child(UI.muted_label(vein["location"]))
	c["content"].add_child(UI.label(("✅ Ready to harvest" if vein["charged"] else "⏳ Charging") + "   🔒 " + security["label"]))

	var charge_label := "Full" if vein["charged"] else "%d/%d blocks" % [vein["chargeBlocks"], level_data["rechargeBlocks"]]
	c["content"].add_child(UI.muted_label("Charge: %s" % charge_label))
	c["content"].add_child(UI.bar(level_data["rechargeBlocks"] if vein["charged"] else vein["chargeBlocks"], level_data["rechargeBlocks"]))

	var dev_label := "Max level" if vein["level"] >= 5 else "%d/%d" % [vein["devBar"], level_data["devBarMax"]]
	c["content"].add_child(UI.muted_label("Development: %s" % dev_label))
	if vein["level"] < 5:
		c["content"].add_child(UI.bar(vein["devBar"], level_data["devBarMax"]))

	# UI.hflow, not UI.hbox: a charged vein shows all three buttons at once,
	# which overflows a narrow phone's width in a plain HBoxContainer
	# (bugfixes ticket 05) — flow-wrapping keeps every button fully on-screen
	# and tappable instead of clipped past the right edge.
	var actions := UI.hflow()
	var vein_id: String = vein["id"]
	actions.add_child(UI.button("Cultivate", func(): Cultivating.cultivate(vein_id)))
	if vein["charged"]:
		actions.add_child(UI.button("Harvest (cautious)", func(): Cultivating.harvest_cautious(vein_id)))
		actions.add_child(UI.button("Harvest (full)", func(): Cultivating.harvest_full(vein_id)))
	c["content"].add_child(actions)

	return c["panel"]
