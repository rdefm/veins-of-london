class_name CombatScreen
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

	var combat: Dictionary = GameState.state["combat"]
	var player: Dictionary = GameState.state["player"]
	var enemy = combat["enemy"]

	var context_label := "Mugging"
	if combat["context"] == "home_raid":
		context_label = "Home Raid"
	elif combat["context"] == "raid":
		context_label = "Raid"

	_content.add_child(UI.heading(context_label))
	_content.add_child(UI.heading(enemy["name"] if enemy != null else "Combat", 16))

	_content.add_child(_build_player_card(player, combat))
	if enemy != null:
		_content.add_child(_build_enemy_card(enemy, combat))

	var log: Array = combat["log"]
	var log_start: int = maxi(0, log.size() - 6)
	for i in range(log_start, log.size()):
		_content.add_child(UI.muted_label(log[i]))

	if combat["outcome"] != null:
		_content.add_child(_build_outcome_button(combat["outcome"], combat["context"]))
	else:
		_content.add_child(_build_action_bar())


func _build_player_card(player: Dictionary, combat: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("You", 14))
	c["content"].add_child(UI.label("%d / %d HP" % [player["hp"], player["hpMax"]]))
	c["content"].add_child(UI.bar(player["hp"], player["hpMax"]))
	if combat["motionTurns"] > 0:
		var attacks := 3 if combat["motionPower"] >= 3 else 2
		c["content"].add_child(UI.muted_label("↯ Motion — %d turn(s) · %d× attacks" % [combat["motionTurns"], attacks]))
	return c["panel"]


func _build_enemy_card(enemy: Dictionary, combat: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading(enemy["name"], 14))
	c["content"].add_child(UI.label("%d / %d HP" % [enemy["hp"], enemy["hpMax"]]))
	c["content"].add_child(UI.bar(enemy["hp"], enemy["hpMax"]))
	if combat["frozenTurns"] > 0:
		c["content"].add_child(UI.muted_label("⧖ Frozen — %d turn(s)" % combat["frozenTurns"]))
	return c["panel"]


func _build_action_bar() -> Control:
	var row := UI.hbox()
	row.add_child(UI.button("⚔ Attack", func(): Combat.player_attack()))
	row.add_child(UI.button("🏃 Run", func(): Combat.flee()))

	var player: Dictionary = GameState.state["player"]
	var has_items: bool = player["inventory"]["timePearl"] > 0 or player["inventory"]["enhancementPowder"] > 0 or player["inventory"]["rewind"] > 0 or player["equipment"]["device"] != null
	var item_button := UI.button("🎒 Item", func(): Bag.open())
	item_button.disabled = not has_items
	row.add_child(item_button)

	return row


func _build_outcome_button(outcome: String, context: String) -> Control:
	var label: String
	if outcome == "win":
		label = "✅ They've legged it" if Combat.NON_LETHAL_MUGGING_CONTEXTS.has(context) else "✅ Vein secured"
	elif outcome == "fled":
		label = "🏃 Scarper"
	else:
		label = "💀 Come round"

	return UI.button(label, _on_continue_pressed)


# exit_combat() already navigates for every case except mugging-win
# (which deliberately stays put so the sale_result modal stays visible).
func _on_continue_pressed() -> void:
	Combat.exit_combat()
