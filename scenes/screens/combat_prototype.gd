class_name CombatPrototypeScreen
extends Control

# day-rhythm-business-and-combat ticket 14: minimal, functional (not
# polished) screen over systems/combat_prototype.gd -- the bounded solo
# combat experiment. Deliberately NOT scenes/screens/combat.gd's production
# UI (that's tickets 18/19/20's job, applying ticket 13a's "Agreed UI
# direction" to the real fight screen once these rules are validated) --
# this exists only so a human can actually play the teaching encounters and
# ticket 15's squad/wave evaluation rosters. Same "queue_free() + rebuild
# from scratch on every EventBus.state_changed" convention every other
# screen in this project uses (see e.g. scenes/screens/factions.gd).
#
# Reached via the Debug app's "Solo Combat Prototype" card
# (scenes/screens/phone.gd) -- registered in scenes/main.gd's SCREEN_SCRIPTS
# as "combat_prototype", full-bleed (NAV_HIDDEN_SCREENS) same as "combat".
#
# Ticket 15: cp.enemies is always an Array now -- one card + one Fast/Heavy/
# Counter/Dodge/Blast action row per LIVING enemy (target is implicit: the
# enemy whose row a button sits under), rather than one fixed action grid.
# A round mid-resolution (cp["_pending"] != null, an Enhancement-Powder-
# inserted extra slot awaiting its own commit) needs no special-case here
# at all: EventBus.state_changed already fired, outcome is still null, the
# player isn't (necessarily) exhausted, so this just rebuilds the same
# action rows again for the next commit -- see systems/combat_prototype.gd's
# _advance_round() for why that's always correct.

# Ticket 13a's own "Agreed UI direction" reminder copy (already PROSE-
# REVIEWed there) -- "not a complete symmetrical rock-paper-scissors rule
# table", just enough to remind the player what each button does.
const ACTION_REMINDERS := {
	CombatPrototype.ACTION_FAST: "Fast — Catches Dodge",
	CombatPrototype.ACTION_HEAVY: "Heavy — Bypasses Counter",
	CombatPrototype.ACTION_COUNTER: "Counter — Stops Fast",
	CombatPrototype.ACTION_DODGE: "Dodge — Avoids Heavy",
}

# Ticket 15: self/AoE items (no per-enemy target) shown as one flat list;
# Blast (the one targeted item) rides in each enemy's own action row
# instead -- see _build_enemy_block().
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


# One target's action block: Fast/Heavy/Counter/Dodge (2x2) plus Blast if
# the player has any in stock -- ticket 15 checklist item 1's whole point
# is that a stance only ever covers the ONE enemy its row was tapped for.
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


# Self/AoE items only (Blast rides each enemy's own block above) -- one
# button per item, showing real inventory qty, hidden entirely at zero
# stock (no synthetic pool per ticket 15's resolved resource contract).
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


# Split out of the loop above for the same closure-captures-the-loop-
# variable reason _build_debug_combat_prototype_launch_button() documents
# in scenes/screens/phone.gd.
func _build_item_button(item_id: String, qty: int) -> Control:
	return UI.button("%s (%d)" % [item_id.capitalize(), qty], func(): CombatPrototype.use_item(item_id))


# Ticket 15: the Dial-cast entry point ("both entry points in scope"). Kept
# deliberately minimal (not the full loadout widget device-plan-spec.md
# describes) -- one button per loaded Complication this prototype can
# actually resolve. A loaded Blast Complication is skipped here rather than
# offered without a target picker (still reachable through the public API/
# tests) -- see this file's own top comment.
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
