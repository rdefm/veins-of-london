class_name CombatPrototypeScreen
extends Control

# day-rhythm-business-and-combat ticket 14: minimal, functional (not
# polished) screen over systems/combat_prototype.gd -- the bounded solo
# combat experiment. Deliberately NOT scenes/screens/combat.gd's production
# UI (that's tickets 18/19/20's job, applying ticket 13a's "Agreed UI
# direction" to the real fight screen once these rules are validated) --
# this exists only so a human can actually play the three teaching
# encounters for evaluation. Same "queue_free() + rebuild from scratch on
# every EventBus.state_changed" convention every other screen in this
# project uses (see e.g. scenes/screens/factions.gd).
#
# Reached via the Debug app's "Solo Combat Prototype" card
# (scenes/screens/phone.gd) -- registered in scenes/main.gd's SCREEN_SCRIPTS
# as "combat_prototype", full-bleed (NAV_HIDDEN_SCREENS) same as "combat".

# Ticket 13a's own "Agreed UI direction" reminder copy (already PROSE-
# REVIEWed there) -- "not a complete symmetrical rock-paper-scissors rule
# table", just enough to remind the player what each button does.
const ACTION_REMINDERS := {
	CombatPrototype.ACTION_FAST: "Fast — Catches Dodge",
	CombatPrototype.ACTION_HEAVY: "Heavy — Bypasses Counter",
	CombatPrototype.ACTION_COUNTER: "Counter — Stops Fast",
	CombatPrototype.ACTION_DODGE: "Dodge — Avoids Heavy",
}

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
	_content.add_child(UI.heading("Solo Combat Prototype — %s" % def["name"]))
	_content.add_child(UI.muted_label("Teaches: %s. Round %d." % [def.get("teaches", ""), cp["round"]]))

	_content.add_child(_build_combatant_card("You", cp["player"]["hp"], cp["player"]["hpMax"]))
	_content.add_child(_build_combatant_card(cp["enemy"]["name"], cp["enemy"]["hp"], cp["enemy"]["hpMax"]))

	_content.add_child(_build_log_card(cp["log"]))

	if cp["outcome"] != null:
		_content.add_child(_build_outcome_controls(cp))
		return

	if cp["player"]["exhaustedNextTurn"]:
		var c := UI.card()
		c["content"].add_child(UI.label("You're exhausted — catching your breath. No action this round."))
		c["content"].add_child(UI.button("Continue", func(): CombatPrototype.skip_exhausted_round()))
		_content.add_child(c["panel"])
	else:
		_content.add_child(_build_action_grid())
		_content.add_child(UI.button("Flee", func(): CombatPrototype.take_player_action(CombatPrototype.ACTION_FLEE)))

	var rewind_button := UI.button("Rewind", func(): CombatPrototype.rewind())
	rewind_button.disabled = cp["snapshots"].is_empty()
	_content.add_child(rewind_button)


func _build_combatant_card(display_name: String, hp: int, hp_max: int) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.label("%s — %d/%d HP" % [display_name, hp, hp_max]))
	c["content"].add_child(UI.bar(hp, hp_max))
	return c["panel"]


func _build_log_card(log: Array) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Log", 14))
	var text := "\n".join(log)
	var log_label := UI.label(text)
	c["content"].add_child(log_label)
	return c["panel"]


func _build_action_grid() -> Control:
	var grid := VBoxContainer.new()
	var row1 := UI.hbox()
	row1.add_child(_build_action_button(CombatPrototype.ACTION_FAST))
	row1.add_child(_build_action_button(CombatPrototype.ACTION_HEAVY))
	grid.add_child(row1)
	var row2 := UI.hbox()
	row2.add_child(_build_action_button(CombatPrototype.ACTION_COUNTER))
	row2.add_child(_build_action_button(CombatPrototype.ACTION_DODGE))
	grid.add_child(row2)
	return grid


func _build_action_button(action: String) -> Control:
	var col := UI.vbox(2)
	col.add_child(UI.button(action.capitalize(), func(): CombatPrototype.take_player_action(action)))
	col.add_child(UI.muted_label(ACTION_REMINDERS[action]))
	return col


func _build_outcome_controls(cp: Dictionary) -> Control:
	var c := UI.card()
	var outcome: String = cp["outcome"]
	var encounter_id: String = cp["encounterId"]
	match outcome:
		"win":
			c["content"].add_child(UI.label("You win."))
			var order: Array = GameData.COMBAT_PROTOTYPE.get("encounterOrder", [])
			if order.find(encounter_id) + 1 < order.size():
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
