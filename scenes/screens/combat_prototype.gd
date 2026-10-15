class_name CombatPrototypeScreen
extends Control

# Debug-app-only sandbox screen for systems/combat_prototype.gd: setup
# (player Combat Skill level), then per round the combatants with their
# guard-state preview, the shared timeline with enemy intents and the
# player's draft positions, Commit, Rewind and the beat log.

# View state only: the setup level pick, kept across rebuilds.
var _player_level: int = 1

var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()
	MapPalette.build_light(_build)


func _build() -> void:
	var cp: Dictionary = GameState.state["combatPrototype"]
	_content.add_child(MapCardStyle.text_button("‹ Exit", func(): CombatPrototype.exit()))
	_content.add_child(UI.heading("Combat Prototype"))
	if not cp["active"]:
		_content.add_child(_build_setup_card())
		return

	_content.add_child(UI.muted_label("Round %d" % cp["round"]))
	for i in range(cp["combatants"].size()):
		_content.add_child(_build_combatant_card(cp, i))
	if cp["outcome"] != null:
		_content.add_child(_build_outcome_card(cp["outcome"]))
	else:
		_content.add_child(_build_timeline_card(cp))
		var reason := CombatPrototype.plan_block_reason(cp, cp["playerPlan"])
		if reason != "":
			_content.add_child(UI.muted_label(reason))
		_content.add_child(MapCardStyle.text_button("Commit", func(): CombatPrototype.resolve_round(cp["playerPlan"]), reason != ""))
	_content.add_child(MapCardStyle.text_button("Rewind", func(): CombatPrototype.rewind(), cp["snapshots"].is_empty()))
	_content.add_child(_build_log_card(cp["log"]))


func _build_setup_card() -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Setup", 14))
	var levels: Array = []
	for level in range(1, CombatPrototype.level_max() + 1):
		levels.append("Your Combat Skill: %d" % level)
	var level_select := UI.option_button(levels)
	level_select.selected = _player_level - 1
	level_select.item_selected.connect(func(index: int): _player_level = index + 1)
	c["content"].add_child(level_select)
	c["content"].add_child(UI.muted_label("Against one level-1 mugger."))
	c["content"].add_child(MapCardStyle.text_button("Start", func(): CombatPrototype.start({ "playerLevel": _player_level })))
	return c["panel"]


func _build_combatant_card(cp: Dictionary, index: int) -> Control:
	var combatant: Dictionary = cp["combatants"][index]
	var c := MapCardStyle.card()
	var status: String = " (down)" if combatant["koed"] else ""
	c["content"].add_child(UI.label("%s — level %d — %d/%d HP%s" % [CombatPrototype.display_name(combatant), combatant["level"], combatant["hp"], combatant["hpMax"], status]))
	c["content"].add_child(UI.bar(combatant["hp"], combatant["hpMax"]))
	if not combatant["koed"]:
		var preview: Array = CombatPrototype.guard_preview(cp, index).map(func(state): return str(state).capitalize())
		c["content"].add_child(UI.muted_label("Guard: %s" % " → ".join(preview)))
	return c["panel"]


# One row per timeline position: enemy rows show the intent's move type,
# the player's rows show the move palette with the current pick disabled.
func _build_timeline_card(cp: Dictionary) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("This round", 14))
	var combatants: Array = cp["combatants"]
	for entry in CombatPrototype.timeline(cp):
		var actor: int = entry["actor"]
		var position: int = entry["index"]
		var row := UI.hbox()
		row.add_child(UI.label("%d · %s" % [position + 1, CombatPrototype.display_name(combatants[actor])]))
		if actor == CombatPrototype.PLAYER_INDEX:
			var picked = cp["playerPlan"][position]
			for move_id in GameData.COMBAT_PROTOTYPE["moves"].keys():
				var is_picked: bool = picked != null and picked["move"] == move_id
				row.add_child(MapCardStyle.text_button(CombatPrototype.move(move_id)["name"], func(): CombatPrototype.set_plan_action(position, move_id), is_picked))
		else:
			var intent: Dictionary = combatants[actor]["plan"][position]
			row.add_child(UI.label(CombatPrototype.move(intent["move"])["name"]))
		c["content"].add_child(row)
	return c["panel"]


func _build_outcome_card(outcome: String) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.label("You win." if outcome == "win" else "You lose."))
	c["content"].add_child(MapCardStyle.text_button("New fight", func(): CombatPrototype.close_fight()))
	return c["panel"]


# Every beat so far, grouped by round, newest round first.
func _build_log_card(log: Array) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Beats", 14))
	if log.is_empty():
		c["content"].add_child(UI.muted_label("Nothing's happened yet."))
		return c["panel"]
	var rounds: Dictionary = {}
	for beat in log:
		if not rounds.has(beat["round"]):
			rounds[beat["round"]] = []
		rounds[beat["round"]].append(beat["text"])
	var round_ids: Array = rounds.keys()
	round_ids.reverse()
	for round_id in round_ids:
		c["content"].add_child(UI.muted_label("Round %d" % round_id))
		c["content"].add_child(UI.label("\n".join(rounds[round_id])))
	return c["panel"]
