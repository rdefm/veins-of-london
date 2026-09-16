class_name CombatPrototypeScreen
extends Control
const ACTION_REMINDERS := {
	CombatPrototype.ACTION_FAST: "Fast — Catches Dodge",
	CombatPrototype.ACTION_HEAVY: "Heavy — Bypasses Counter",
	CombatPrototype.ACTION_COUNTER: "Counter — Stops Fast",
	CombatPrototype.ACTION_DODGE: "Dodge — Avoids Heavy",
}
const SELF_OR_AOE_ITEMS := ["timePearl", "enhancementPowder", "shield", "blackHole", "healingBurst"]

var _content: VBoxContainer

func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	var cp: Dictionary = GameState.state["combatPrototype"]
	if not cp.get("active", false):
		_content.add_child(UI.back_to_home_button())
		_content.add_child(UI.heading("Solo Combat Prototype"))
		_content.add_child(UI.muted_label("No encounter active."))
		return

	_content.add_child(UI.button("‹ Exit", func(): CombatPrototype.exit_encounter()))

	var def: Dictionary = GameData.COMBAT_PROTOTYPE["encounters"][cp["encounterId"]]
	_content.add_child(UI.heading("Solo Combat Prototype — %s" % def.get("name", cp["encounterId"])))
	var round_note: String = "Teaches: %s. Round %d." % [def.get("teaches", ""), cp["round"]]
	if cp["totalWaves"] > 1:
		round_note += " Wave %d/%d." % [cp["wave"] + 1, cp["totalWaves"]]
	_content.add_child(UI.muted_label(round_note))

	_content.add_child(_build_player_card(cp))
	for i in range(cp["enemies"].size()):
		_content.add_child(_build_enemy_card(cp["enemies"][i]))

	_content.add_child(_build_log_card(cp["log"]))

	if cp["outcome"] != null:
		_content.add_child(_build_outcome_controls(cp))
		return

	if cp["player"]["exhaustedNextTurn"] and cp.get("_pending") == null:
		var c := UI.card()
		c["content"].add_child(UI.label("You're exhausted — catching your breath. No action this round."))
		c["content"].add_child(UI.button("Continue", func(): CombatPrototype.skip_exhausted_round()))
		_content.add_child(c["panel"])
	else:
		if cp.get("_pending") != null:
			_content.add_child(UI.muted_label("Enhancement Powder — one more action this round."))
		for i in range(cp["enemies"].size()):
			if not cp["enemies"][i]["koed"]:
				_content.add_child(_build_enemy_block(cp, i))
		_content.add_child(_build_items_card())
		var dial_card := _build_dial_card()
		if dial_card != null:
			_content.add_child(dial_card)
		_content.add_child(UI.button("Flee", func(): CombatPrototype.take_player_action(CombatPrototype.ACTION_FLEE)))

	var rewind_button := UI.button("Rewind", func(): CombatPrototype.rewind())
	rewind_button.disabled = cp["snapshots"].is_empty()
	_content.add_child(rewind_button)

func _build_player_card(cp: Dictionary) -> Control:
	var c := UI.card()
	var player: Dictionary = cp["player"]
	c["content"].add_child(UI.label("You — %d/%d HP" % [player["hp"], player["hpMax"]]))
	c["content"].add_child(UI.bar(player["hp"], player["hpMax"]))
	if player["shieldPool"] > 0:
		c["content"].add_child(UI.muted_label("Shield: %d absorption." % player["shieldPool"]))
	if cp["motionTurns"] > 0:
		c["content"].add_child(UI.muted_label("Moving fast — %d round(s) left." % cp["motionTurns"]))
	return c["panel"]

func _build_enemy_card(enemy: Dictionary) -> Control:
	var c := UI.card()
	var status: String = " (down)" if enemy["koed"] else ""
	c["content"].add_child(UI.label("%s — %d/%d HP%s" % [enemy["name"], enemy["hp"], enemy["hpMax"], status]))
	c["content"].add_child(UI.bar(enemy["hp"], enemy["hpMax"]))
	return c["panel"]

func _build_log_card(log: Array) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Log", 14))
	var text := "\n".join(log)
	var log_label := UI.label(text)
	c["content"].add_child(log_label)
	return c["panel"]
func _build_enemy_block(cp: Dictionary, enemy_index: int) -> Control:
	var enemy: Dictionary = cp["enemies"][enemy_index]
	var block := UI.card()
	var multi: bool = cp["enemies"].size() > 1
	if multi:
		block["content"].add_child(UI.heading("Target: %s" % enemy["name"], 14))
	var row1 := UI.hbox()
	row1.add_child(_build_action_button(CombatPrototype.ACTION_FAST, enemy_index))
	row1.add_child(_build_action_button(CombatPrototype.ACTION_HEAVY, enemy_index))
	block["content"].add_child(row1)
	var row2 := UI.hbox()
	row2.add_child(_build_action_button(CombatPrototype.ACTION_COUNTER, enemy_index))
	row2.add_child(_build_action_button(CombatPrototype.ACTION_DODGE, enemy_index))
	block["content"].add_child(row2)
	if Crafting.inventory_qty("blast") > 0:
		block["content"].add_child(UI.button("Blast", func(): CombatPrototype.use_item("blast", enemy_index)))
	return block["panel"]

func _build_action_button(action: String, enemy_index: int) -> Control:
	var col := UI.vbox(2)
	col.add_child(UI.button(action.capitalize(), func(): CombatPrototype.take_player_action(action, enemy_index)))
	col.add_child(UI.muted_label(ACTION_REMINDERS[action]))
	return col
func _build_items_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Items", 14))
	var any_shown := false
	for item_id in SELF_OR_AOE_ITEMS:
		var qty: int = Crafting.inventory_qty(item_id)
		if qty <= 0:
			continue
		any_shown = true
		c["content"].add_child(_build_item_button(item_id, qty))
	if not any_shown:
		c["content"].add_child(UI.muted_label("No usable items in stock."))
	return c["panel"]
func _build_item_button(item_id: String, qty: int) -> Control:
	return UI.button("%s (%d)" % [item_id.capitalize(), qty], func(): CombatPrototype.use_item(item_id))
func _build_dial_card() -> Control:
	var dial = GameState.state["player"]["dial"]
	if dial == null:
		return null
	var loaded: Array = dial["loadedComplications"]
	if loaded.is_empty():
		return null
	var c := UI.card()
	c["content"].add_child(UI.heading("Dial", 14))
	var any_shown := false
	for i in range(loaded.size()):
		var recipe_key: String = loaded[i]["recipeKey"]
		if recipe_key == "blast" or not CombatPrototype.ITEM_RECIPE_KEYS.has(recipe_key):
			continue
		any_shown = true
		var recipe: Dictionary = GameData.RECIPES.get(recipe_key, {})
		c["content"].add_child(_build_dial_cast_button(i, recipe.get("name", recipe_key)))
	if not any_shown:
		c["content"].add_child(UI.muted_label("Nothing loaded this prototype can use."))
	return c["panel"]

func _build_dial_cast_button(dial_index: int, label: String) -> Control:
	return UI.button("Cast: %s" % label, func(): CombatPrototype.cast_dial_complication(dial_index))

func _build_outcome_controls(cp: Dictionary) -> Control:
	var c := UI.card()
	var outcome: String = cp["outcome"]
	var encounter_id: String = cp["encounterId"]
	match outcome:
		"win":
			c["content"].add_child(UI.label("You win."))
			var order: Array = GameData.COMBAT_PROTOTYPE.get("encounterOrder", [])
			if order.find(encounter_id) + 1 < order.size() and order.has(encounter_id):
				c["content"].add_child(UI.button("Next Encounter", func(): CombatPrototype.advance_to_next_encounter()))
			else:
				c["content"].add_child(UI.label("Sequence complete."))
		"loss":
			c["content"].add_child(UI.label("You go down."))
			c["content"].add_child(UI.button("Retry", func(): CombatPrototype.start_encounter(encounter_id)))
		"fled":
			c["content"].add_child(UI.label("You fled."))
			c["content"].add_child(UI.button("Retry", func(): CombatPrototype.start_encounter(encounter_id)))
	c["content"].add_child(UI.button("Exit", func(): CombatPrototype.exit_encounter()))
	return c["panel"]
