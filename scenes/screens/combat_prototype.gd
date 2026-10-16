class_name CombatPrototypeScreen
extends Control

# Debug-app-only sandbox screen for systems/combat_prototype.gd: setup
# (player, enemy and ally Combat Skill levels, 1-3 enemies by archetype, 0-2
# allies, a 2-slot sandbox item loadout by recipe and tier for the player
# and each ally), then per round the combatants with their guard-state
# preview, the shared timeline with enemy intents (type only, or target and
# damage range plus a next-round preview under Prophet's Breath sight), ally
# plans (an [item] tag marking an item use) and the player's positions:
# picks so far, and at the paused position the move palette plus unspent
# loadout items (one button per target where there's a choice), each pick
# resolving at once. Then Rewind (back to the last pick) and the beat log.

# Setup's enemy count cap (spec §Out of Scope: no more than 3 per side).
const MAX_ENEMIES := 3

# View state only: the setup picks, kept across rebuilds.
var _player_level: int = 1
var _enemy_level: int = 1
var _enemy_archetypes: Array = [CombatPrototype.DEFAULT_ARCHETYPE]
var _ally_count: int = 0
var _ally_level: int = 1
# One { item, tier } per loadout slot; item "" leaves the slot empty.
var _loadout: Array = _empty_loadout()
# One such loadout per possible ally, by ally order.
var _ally_loadouts: Array = range(CombatPrototype.MAX_ALLIES).map(func(_i): return _empty_loadout())
# View state only: why the last palette pick was refused, until the next pick.
var _refusal: String = ""

var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()
	_build()


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
		if _refusal != "":
			_content.add_child(UI.muted_label(_refusal))
	_content.add_child(MapCardStyle.text_button("Rewind", func(): CombatPrototype.rewind(), cp["snapshots"].is_empty()))
	_content.add_child(_build_log_card(cp["log"]))


func _build_setup_card() -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Setup", 14))
	c["content"].add_child(_level_select("Your Combat Skill: %d", _player_level, func(level: int): _player_level = level))
	c["content"].add_child(_level_select("Enemy level: %d", _enemy_level, func(level: int): _enemy_level = level))

	var counts: Array = []
	for n in range(1, MAX_ENEMIES + 1):
		counts.append("%d enem%s" % [n, "y" if n == 1 else "ies"])
	var count_select := UI.option_button(counts)
	count_select.selected = _enemy_archetypes.size() - 1
	count_select.item_selected.connect(_set_enemy_count)
	c["content"].add_child(count_select)

	var archetype_ids: Array = GameData.COMBAT_PROTOTYPE["archetypes"].keys()
	var archetype_names: Array = archetype_ids.map(func(id): return str(GameData.COMBAT_PROTOTYPE["archetypes"][id]["name"]).capitalize())
	for i in range(_enemy_archetypes.size()):
		var select := UI.option_button(archetype_names)
		select.selected = maxi(0, archetype_ids.find(_enemy_archetypes[i]))
		select.item_selected.connect(func(index: int): _enemy_archetypes[i] = archetype_ids[index])
		c["content"].add_child(select)

	var ally_counts: Array = []
	for n in range(CombatPrototype.MAX_ALLIES + 1):
		ally_counts.append("%d all%s" % [n, "y" if n == 1 else "ies"])
	var ally_select := UI.option_button(ally_counts)
	ally_select.selected = _ally_count
	ally_select.item_selected.connect(func(index: int):
		_ally_count = index
		_refresh()
	)
	c["content"].add_child(ally_select)
	c["content"].add_child(_level_select("Ally level: %d", _ally_level, func(level: int): _ally_level = level))

	c["content"].add_child(UI.muted_label("Your loadout"))
	for slot in range(_loadout.size()):
		c["content"].add_child(_build_loadout_slot(_loadout, slot))
	for i in range(_ally_count):
		c["content"].add_child(UI.muted_label("Ally %s loadout" % char(65 + i) if _ally_count > 1 else "Ally loadout"))
		for slot in range(_ally_loadouts[i].size()):
			c["content"].add_child(_build_loadout_slot(_ally_loadouts[i], slot))

	c["content"].add_child(MapCardStyle.text_button("Start", func():
		var allies: Array = []
		for i in range(_ally_count):
			allies.append({ "level": _ally_level, "loadout": _picked_slots(_ally_loadouts[i]) })
		CombatPrototype.start({
			"playerLevel": _player_level,
			"enemies": _enemy_archetypes.map(func(id): return { "archetype": id, "level": _enemy_level }),
			"allies": allies,
			"loadout": _picked_slots(_loadout),
		})
	))
	return c["panel"]


static func _empty_loadout() -> Array:
	return [{ "item": "", "tier": 1 }, { "item": "", "tier": 1 }]


static func _picked_slots(loadout: Array) -> Array:
	return loadout.filter(func(s): return s["item"] != "")


# Item and tier pickers for one slot of a sandbox `loadout` (the player's or
# an ally's); the tier list follows the picked item's effectPower curve.
func _build_loadout_slot(loadout: Array, slot: int) -> Control:
	var row := UI.hbox()
	var item_ids: Array = CombatPrototype.item_ids()
	var names: Array = ["Slot %d: empty" % (slot + 1)]
	for id in item_ids:
		names.append("Slot %d: %s" % [slot + 1, CombatPrototype.move(id)["name"]])
	var item_select := UI.option_button(names)
	item_select.selected = item_ids.find(loadout[slot]["item"]) + 1
	item_select.item_selected.connect(func(index: int):
		loadout[slot]["item"] = "" if index == 0 else item_ids[index - 1]
		loadout[slot]["tier"] = 1
		_refresh()
	)
	row.add_child(item_select)
	var item_id: String = loadout[slot]["item"]
	if item_id != "":
		var tiers: Array = []
		for tier in range(1, CombatPrototype.item_tier_max(item_id) + 1):
			tiers.append("Tier %d" % tier)
		var tier_select := UI.option_button(tiers)
		tier_select.selected = int(loadout[slot]["tier"]) - 1
		tier_select.item_selected.connect(func(index: int): loadout[slot]["tier"] = index + 1)
		row.add_child(tier_select)
	return row


func _level_select(text: String, current: int, on_pick: Callable) -> OptionButton:
	var levels: Array = []
	for level in range(1, CombatPrototype.level_max() + 1):
		levels.append(text % level)
	var select := UI.option_button(levels)
	select.selected = current - 1
	select.item_selected.connect(func(index: int): on_pick.call(index + 1))
	return select


# Grows (repeating the last pick) or trims the enemy list, then rebuilds so
# the per-enemy archetype pickers match.
func _set_enemy_count(index: int) -> void:
	var count := index + 1
	while _enemy_archetypes.size() < count:
		_enemy_archetypes.append(_enemy_archetypes[-1])
	_enemy_archetypes.resize(count)
	_refresh()


func _build_combatant_card(cp: Dictionary, index: int) -> Control:
	var combatant: Dictionary = cp["combatants"][index]
	var c := MapCardStyle.card()
	var status: String = " (down)" if combatant["koed"] else ""
	c["content"].add_child(UI.label("%s — level %d — %d/%d HP%s" % [CombatPrototype.display_name(combatant), combatant["level"], combatant["hp"], combatant["hpMax"], status]))
	c["content"].add_child(UI.bar(combatant["hp"], combatant["hpMax"]))
	if not combatant["koed"]:
		var preview: Array = CombatPrototype.guard_preview(cp, index).map(func(state): return str(state).capitalize())
		c["content"].add_child(UI.muted_label("Guard: %s" % " → ".join(preview)))
		if CombatPrototype.is_exposed(cp, combatant):
			c["content"].add_child(UI.muted_label("Exposed through round %d" % combatant["exposedUntil"]))
		if combatant["frozenActions"] > 0:
			c["content"].add_child(UI.muted_label("Frozen (Open): next %d action(s)" % combatant["frozenActions"]))
		if combatant["actionsLost"] > combatant["frozenActions"]:
			c["content"].add_child(UI.muted_label("Stunned: loses next %d action(s)" % (combatant["actionsLost"] - combatant["frozenActions"])))
		if combatant["shield"] > 0:
			c["content"].add_child(UI.muted_label("Shield: %d (counts as Guarded)" % combatant["shield"]))
		if CombatPrototype.is_powered(cp, combatant):
			c["content"].add_child(UI.muted_label("Powder: +1 action through round %d" % combatant["powderUntil"]))
		if CombatPrototype.has_lady(cp, combatant):
			c["content"].add_child(UI.muted_label("Be a Lady: max rolls through round %d" % combatant["ladyUntil"]))
		if index == CombatPrototype.PLAYER_INDEX and CombatPrototype.has_sight(cp):
			c["content"].add_child(UI.muted_label("Sight through round %d" % combatant["sightUntil"]))
		for slot in combatant["loadout"]:
			c["content"].add_child(UI.muted_label("%s T%d (power %d)%s" % [CombatPrototype.move(slot["item"])["name"], slot["tier"], slot["power"], " — used" if slot["used"] else ""]))
	return c["panel"]


# One row per timeline position: enemy rows show the intent's move type
# only, ally rows their planned move and its target, the player's rows the
# pick made there (a multi-action move's later positions say so), and at the
# paused position the palette (see _build_palette()).
func _build_timeline_card(cp: Dictionary) -> Control:
	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("This round", 14))
	var combatants: Array = cp["combatants"]
	var pause := CombatPrototype.decision_position(cp)
	for entry in CombatPrototype.timeline(cp):
		var actor: int = entry["actor"]
		var position: int = entry["index"]
		var row := UI.hbox()
		row.add_child(UI.label("%d · %s" % [position + 1, CombatPrototype.display_name(combatants[actor])]))
		if actor == CombatPrototype.PLAYER_INDEX:
			if position >= CombatPrototype.actions_per_round(combatants[actor]):
				row.add_child(UI.muted_label("(Powder)"))
			var picked = cp["playerPlan"][position] if position < cp["playerPlan"].size() else null
			if position == pause:
				c["content"].add_child(row)
				c["content"].add_child(_build_palette(cp))
				continue
			if picked == null:
				row.add_child(UI.muted_label("—"))
			elif int(picked.get("part", 0)) > 0:
				row.add_child(UI.muted_label("(%s, cont.)" % CombatPrototype.move(picked["move"])["name"]))
			else:
				row.add_child(UI.label(_aimed(cp, CombatPrototype.move(picked["move"])["name"], picked["move"], int(picked["target"]))))
		elif combatants[actor]["side"] == CombatPrototype.SIDE_ALLY:
			var planned: Dictionary = combatants[actor]["plan"][position]
			var m := CombatPrototype.move(planned["move"])
			var aim: String = ""
			if m["target"] in [CombatPrototype.TARGET_ENEMY, CombatPrototype.TARGET_FRIEND] and int(planned["target"]) >= 0:
				aim = " → %s" % CombatPrototype.display_name(combatants[planned["target"]])
			var label: String = m["name"]
			if planned.has("slot"):
				label = "[item] %s T%d" % [label, combatants[actor]["loadout"][planned["slot"]]["tier"]]
			row.add_child(UI.label("(ally) %s%s" % [label, aim]))
		else:
			row.add_child(UI.label(_intent_text(cp, CombatPrototype.enemy_intents(cp, actor)[position])))
		c["content"].add_child(row)
	if CombatPrototype.has_sight(cp):
		c["content"].add_child(UI.heading("Next round (Prophet's Breath)", 14))
		for i in range(combatants.size()):
			if combatants[i]["side"] != CombatPrototype.SIDE_ENEMY or combatants[i]["koed"]:
				continue
			var intents: Array = CombatPrototype.enemy_intents(cp, i, true).map(func(intent): return _intent_text(cp, intent))
			c["content"].add_child(UI.label("%s: %s" % [CombatPrototype.display_name(combatants[i]), ", ".join(intents)]))
	return c["panel"]


# An enemy intent: its move type, plus target and damage range under sight.
func _intent_text(cp: Dictionary, intent: Dictionary) -> String:
	var text: String = intent["name"]
	if intent.has("target") and int(intent["target"]) >= 0 and CombatPrototype.move(intent["move"])["target"] != CombatPrototype.TARGET_SELF:
		text += " → %s" % CombatPrototype.display_name(cp["combatants"][intent["target"]])
	if intent.has("dmgMin"):
		text += " (%d–%d)" % [intent["dmgMin"], intent["dmgMax"]]
	return text


# The pick at the paused position: each move, then each loadout item, as
# one button per target where it aims at a choice of living enemies (or, for
# a heal, the player and living allies), each disabled while the system
# would refuse it.
func _build_palette(cp: Dictionary) -> Control:
	var flow := HFlowContainer.new()
	for move_id in GameData.COMBAT_PROTOTYPE["moves"].keys():
		var move_name: String = CombatPrototype.move(move_id)["name"]
		for target in _palette_targets(cp, move_id):
			var blocked := CombatPrototype.move_block_reason(cp, move_id, target) != ""
			flow.add_child(MapCardStyle.text_button(_aimed(cp, move_name, move_id, target), func(): _pick(move_id, target), blocked))
	var loadout: Array = cp["combatants"][CombatPrototype.PLAYER_INDEX]["loadout"]
	for slot in range(loadout.size()):
		var item_id: String = loadout[slot]["item"]
		var label := "%s T%d" % [CombatPrototype.move(item_id)["name"], loadout[slot]["tier"]]
		for target in _palette_targets(cp, item_id):
			var blocked := CombatPrototype.item_block_reason(cp, slot, target) != ""
			flow.add_child(MapCardStyle.text_button(_aimed(cp, label, item_id, target), func(): _pick_item(slot, target), blocked))
	return flow


# The targets to offer `move_id` at: each option when it aims at a choice
# of more than one, else just the default (-1).
func _palette_targets(cp: Dictionary, move_id: String) -> Array:
	var targets: Array = CombatPrototype.target_options(cp, CombatPrototype.PLAYER_INDEX, move_id)
	var aims: bool = CombatPrototype.move(move_id)["target"] in [CombatPrototype.TARGET_ENEMY, CombatPrototype.TARGET_FRIEND]
	return targets if aims and targets.size() > 1 else [-1]


# `label`, plus " → target" when `move_id` aims at a chosen combatant.
func _aimed(cp: Dictionary, label: String, move_id: String, target: int) -> String:
	var aims: bool = CombatPrototype.move(move_id)["target"] in [CombatPrototype.TARGET_ENEMY, CombatPrototype.TARGET_FRIEND]
	if not aims or target < 0:
		return label
	return "%s → %s" % [label, CombatPrototype.display_name(cp["combatants"][target])]


func _pick(move_id: String, target: int) -> void:
	# Cleared first: a successful pick refreshes via state_changed mid-call.
	_refusal = ""
	_show_refusal(CombatPrototype.choose_move(move_id, target))


func _pick_item(slot: int, target: int) -> void:
	_refusal = ""
	_show_refusal(CombatPrototype.choose_item(slot, target))


func _show_refusal(result: Dictionary) -> void:
	if not result["ok"]:
		_refusal = str(result["reason"])
		_refresh()


func _build_outcome_card(outcome: String) -> Control:
	var c := MapCardStyle.card()
	var lines := { "win": "You win.", "loss": "You lose.", "fled": "You got away." }
	c["content"].add_child(UI.label(lines.get(outcome, outcome)))
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
