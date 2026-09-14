class_name CombatPrototype
extends RefCounted

# day-rhythm-business-and-combat ticket 14 (rules: ticket 13a, which
# supersedes/absorbs the old ticket 13): a bounded, throwaway solo-combat
# experiment testing the four-action Fast/Heavy/Counter/Dodge matchup grid,
# committed-intent resolution, exhaustion and Rewind reliability -- NOT
# production combat. Deliberately isolated from systems/combat.gd and
# GameState.state["combat"]: its own state lives in
# GameState.state["combatPrototype"], its own snapshot stack ("combatPrototype"
# in Snapshots.MAX_SIZES), its own screen (scenes/screens/combat_prototype.gd).
# Nothing here mutates production combat state, the real player's hp, or any
# Crafting/Dial inventory. Per ticket 13a: Fast's baseline range and turn
# speed are read from the real player (Combat.get_attack_range()/
# Combat._player_speed(), both pure queries) so the numbers feel real, but
# this prototype's own "player" combatant keeps an entirely separate hp
# field seeded fresh each encounter -- see start_encounter()'s own comment
# for why.
#
# Scope assumptions NOT covered by this ticket (recorded per the ticket's
# own "record prototype assumptions" instruction — see also the ticket file
# itself):
#  - Solo means one enemy only. Ticket 13a's acceptance example 6 (a
#    committed target dying before their own queue turn, interrupting a
#    third party's stance) needs a squad to exercise at all -- that's
#    ticket 15's job, not this one.
#  - Item use isn't wired here (no Crafting/Dial dependency, so no risk of
#    a prototype fight draining real consumables) -- only Fast/Heavy/
#    Counter/Dodge/Flee are real committable actions. Flee reuses
#    production's flat 65% chance for a believable escape option, no more.
#  - No freeze mechanic exists in this prototype (that's an item effect),
#    so ticket 13a's exhaustion/frozen overlap scenario (example 7) is
#    untested here -- deferred to whichever prototype/production ticket
#    next wires an item into this state shape.
#  - Each of the three encounters starts the player at full hp -- a fresh
#    baseline per taught matchup, not cumulative attrition across the
#    three-fight sequence.

const ACTION_FAST := "fast"
const ACTION_HEAVY := "heavy"
const ACTION_COUNTER := "counter"
const ACTION_DODGE := "dodge"
const ACTION_FLEE := "flee"

# The four combat actions a script entry (data/combat_prototype.json) may
# name -- also what GameData._validate_combat_prototype() checks scripts
# against. Flee is deliberately excluded: no scripted enemy in this
# teaching roster ever flees.
const SCRIPTABLE_ACTIONS: Array[String] = [ACTION_FAST, ACTION_HEAVY, ACTION_COUNTER, ACTION_DODGE]
const ACTIONS_STANCE: Array[String] = [ACTION_COUNTER, ACTION_DODGE]
const COMMITTABLE_ACTIONS: Array[String] = [ACTION_FAST, ACTION_HEAVY, ACTION_COUNTER, ACTION_DODGE, ACTION_FLEE]

const SIDE_PLAYER := "player"
const SIDE_ENEMY := "enemy"

# Ticket 13a's approved rule: "Heavy = Fast range x 1.5 (min and max),
# rounded via GameState.round_epsilon(). Prototype-only multiplier, not
# balance-final."
const HEAVY_MULTIPLIER := 1.5

# Ticket 13a: "Item use ... and Flee each consume the actor's one committed
# action for the round, exactly as today". Reuses systems/combat.gd's own
# flee() base chance (no Blast boost exists in this prototype -- no items).
const FLEE_CHANCE := 0.65


# Fresh full-hp start for `encounter_id` (must be a key in
# GameData.COMBAT_PROTOTYPE.encounters). The prototype's own player.hp/hpMax
# is seeded from the real player's hpMax (GameState.state["player"]["hpMax"])
# but is NOT the same field -- resolve_round()/etc. below only ever read or
# write cp["player"]["hp"], never GameState.state["player"]["hp"], so a
# prototype fight can never leak damage (or a death) into the real save.
# Fast's own damage range still comes from the real player via
# Combat.get_attack_range() (ticket 13a: "today's baseline attack range ...
# unchanged"), which is a pure query over equipment/Combat Skill, not state
# this file could accidentally mutate.
static func start_encounter(encounter_id: String) -> Dictionary:
	var encounters: Dictionary = GameData.COMBAT_PROTOTYPE.get("encounters", {})
	if not encounters.has(encounter_id):
		return { "ok": false, "reason": "Unknown encounter '%s'." % encounter_id }
	var def: Dictionary = encounters[encounter_id]
	var player_hp_max: int = GameState.state["player"]["hpMax"]

	GameState.state["combatPrototype"] = {
		"active": true, "encounterId": encounter_id, "round": 1, "outcome": null,
		"log": [def.get("intro", "")],
		"player": {
			"hp": player_hp_max, "hpMax": player_hp_max,
			"committedAction": null, "committedTarget": null,
			"exhaustedNextTurn": false, "stanceTriggered": false,
		},
		"enemy": {
			"name": def["name"], "hp": def["hp"], "hpMax": def["hp"],
			"attackMin": def["attackMin"], "attackMax": def["attackMax"],
			"speed": def["speed"], "evadeChance": def.get("evadeChance", 0.0),
			"scriptIndex": 0, "committedAction": null, "committedTarget": null,
			"exhaustedNextTurn": false, "stanceTriggered": false,
		},
		"snapshots": [], "beatsSinceSnapshot": [],
	}
	Nav.go_to("combat_prototype")
	return { "ok": true }


# Fresh start for whichever encounter follows `current` in
# GameData.COMBAT_PROTOTYPE.encounterOrder -- the "teach Heavy/Dodge/
# exhaustion with a brawler, Fast/Counter with a knife fighter, then
# Counter/Heavy with an enforcer" sequence from the ticket. Returns
# { ok:false } with no state change past the last encounter -- the screen's
# own "sequence complete" state handles that case instead of this looping
# or erroring.
static func advance_to_next_encounter() -> Dictionary:
	var order: Array = GameData.COMBAT_PROTOTYPE.get("encounterOrder", [])
	var current: String = GameState.state["combatPrototype"]["encounterId"]
	var idx: int = order.find(current)
	if idx == -1 or idx + 1 >= order.size():
		return { "ok": false, "reason": "No further encounter." }
	return start_encounter(order[idx + 1])


static func _guard_active(cp: Dictionary):
	if not cp.get("active", false) or cp.get("outcome") != null:
		return { "ok": false, "reason": "Encounter not active." }
	return null


# The player's one commit-and-resolve action for the round -- mirrors
# systems/combat.gd's existing single-button-press UX (tapping "Attack"
# both commits and immediately resolves that round): ticket 13a's two-phase
# "commit phase, then resolution phase" round structure collapses to one
# call here since both sides commit in the same instant a button is
# pressed, with the enemy's already-decided script choice revealed
# alongside the player's own (see _run_round()'s own comment on why the
# snapshot is pushed before either side's commit is recorded).
static func take_player_action(action: String) -> Dictionary:
	var cp: Dictionary = GameState.state["combatPrototype"]
	var guard = _guard_active(cp)
	if guard != null:
		return guard
	if not COMMITTABLE_ACTIONS.has(action):
		return { "ok": false, "reason": "Unknown action '%s'." % action }
	if cp["player"]["exhaustedNextTurn"]:
		return { "ok": false, "reason": "Exhausted this round -- call skip_exhausted_round() instead." }
	return _run_round(cp, action)


# Called by the screen instead of take_player_action() when
# cp.player.exhaustedNextTurn is true -- there's no action to pick, the
# round auto-resolves as "no commit, no action" per ticket 13a ("Available
# actions while exhausted: none").
static func skip_exhausted_round() -> Dictionary:
	var cp: Dictionary = GameState.state["combatPrototype"]
	var guard = _guard_active(cp)
	if guard != null:
		return guard
	if not cp["player"]["exhaustedNextTurn"]:
		return { "ok": false, "reason": "Player is not exhausted." }
	return _run_round(cp, null)


# `player_action` null means the player is skipping an exhausted round (see
# skip_exhausted_round() above) -- every other value is a real commit.
static func _run_round(cp: Dictionary, player_action) -> Dictionary:
	var player: Dictionary = cp["player"]
	var enemy: Dictionary = cp["enemy"]

	# Snapshot BEFORE either side's committedAction for this round is
	# recorded -- ticket 13a: "taken at the start of every player queue
	# turn", i.e. the state as it stood at the END of the previous round.
	# Rewinding restores committedAction/committedTarget/exhaustedNextTurn
	# to null/false here (a clean slate for a fresh commit), not to
	# whatever this round's now-regretted commits were about to be.
	push_prototype_snapshot()

	var beats: Array = []
	var player_skip: bool = player_action == null

	if player_skip:
		player["exhaustedNextTurn"] = false
		player["committedAction"] = null
		player["committedTarget"] = null
		_log(cp, beats, "You're exhausted — catching your breath.", "exhausted", { "actorType": "player" })
	else:
		player["committedAction"] = player_action
		player["committedTarget"] = SIDE_ENEMY if player_action != ACTION_FLEE else null

	var enemy_skip: bool = enemy["exhaustedNextTurn"]
	if enemy_skip:
		enemy["exhaustedNextTurn"] = false
		enemy["committedAction"] = null
		enemy["committedTarget"] = null
		_log(cp, beats, "%s is exhausted — catching their breath." % enemy["name"], "exhausted", { "actorType": "enemy" })
	else:
		var script: Array = _encounter_def(cp)["script"]
		var chosen: String = script[enemy["scriptIndex"] % script.size()]
		enemy["scriptIndex"] += 1
		enemy["committedAction"] = chosen
		enemy["committedTarget"] = SIDE_PLAYER

	player["stanceTriggered"] = false
	enemy["stanceTriggered"] = false

	for side in _turn_order(cp):
		if side == SIDE_PLAYER and player_skip:
			continue
		if side == SIDE_ENEMY and enemy_skip:
			continue
		_resolve_side_turn(cp, side, beats)
		if cp["outcome"] != null:
			break

	# Ticket 13a: "A stance ... aimed at an opponent who doesn't attack the
	# defender that round ... fizzles with no effect -- the action is still
	# spent." Skipped once the fight's already resolved this round (a win/
	# loss/flee makes an unused-stance note meaningless).
	if cp["outcome"] == null:
		_log_unused_stances(cp, beats)

	player["committedAction"] = null
	player["committedTarget"] = null
	enemy["committedAction"] = null
	enemy["committedTarget"] = null
	cp["round"] += 1

	EventBus.state_changed.emit()
	return { "ok": true, "outcome": cp["outcome"], "beats": beats }


static func _log_unused_stances(cp: Dictionary, beats: Array) -> void:
	var player: Dictionary = cp["player"]
	var player_action = player["committedAction"]
	if player_action != null and ACTIONS_STANCE.has(player_action) and not player["stanceTriggered"]:
		_log(cp, beats, "Your stance goes unused — the action's still spent.", "stance_fizzle", { "actorType": "player" })
	var enemy: Dictionary = cp["enemy"]
	var enemy_action = enemy["committedAction"]
	if enemy_action != null and ACTIONS_STANCE.has(enemy_action) and not enemy["stanceTriggered"]:
		_log(cp, beats, "%s's stance goes unused — the action's still spent." % enemy["name"], "stance_fizzle", { "actorType": "enemy" })


static func _encounter_def(cp: Dictionary) -> Dictionary:
	return GameData.COMBAT_PROTOTYPE["encounters"][cp["encounterId"]]


# Speed-descending, ties broken player-first -- same tie-break convention
# as Combat.build_turn_queue() (R§3.7a), just over exactly two combatants.
static func _turn_order(cp: Dictionary) -> Array:
	var player_speed: int = Combat._player_speed()
	var enemy_speed: int = cp["enemy"]["speed"]
	if player_speed >= enemy_speed:
		return [SIDE_PLAYER, SIDE_ENEMY]
	return [SIDE_ENEMY, SIDE_PLAYER]


static func _attack_range(cp: Dictionary, side: String, action: String) -> Dictionary:
	var base: Dictionary
	if side == SIDE_PLAYER:
		base = Combat.get_attack_range()
	else:
		var enemy: Dictionary = cp["enemy"]
		base = { "min": enemy["attackMin"], "max": enemy["attackMax"] }
	if action != ACTION_HEAVY:
		return base
	return {
		"min": GameState.round_epsilon(base["min"] * HEAVY_MULTIPLIER),
		"max": GameState.round_epsilon(base["max"] * HEAVY_MULTIPLIER),
	}


static func _other_side(side: String) -> String:
	return SIDE_ENEMY if side == SIDE_PLAYER else SIDE_PLAYER


# One combatant's queue slot: fast/heavy resolve as an attack against the
# other side (per ticket 13a's matchup table below); counter/dodge/null
# resolve to nothing here -- a stance is checked reactively, from the
# ATTACKER's side, whenever the other combatant's own attack turn comes up
# (ticket 13a: "Stances are live for the whole round ... not gated by the
# defender's own queue position").
static func _resolve_side_turn(cp: Dictionary, attacker_side: String, beats: Array) -> void:
	var attacker: Dictionary = cp[attacker_side]
	# committedAction is nullable (String | null) -- untyped here on purpose,
	# a typed `String` local would throw on this very assignment for a
	# combatant with nothing committed (shouldn't reach this func in that
	# state, since the round loop above skips a skipped side entirely, but
	# defender["committedAction"] below legitimately IS null whenever the
	# OTHER side is the one attacking this round while this combatant sat
	# out an exhausted skip).
	var action = attacker["committedAction"]
	if action == null or action in ACTIONS_STANCE:
		return
	if action == ACTION_FLEE:
		_resolve_flee(cp, attacker_side, beats)
		return

	var defender_side: String = _other_side(attacker_side)
	var defender: Dictionary = cp[defender_side]

	# Ticket 13a: "Trigger: any committed Heavy swing ... regardless of
	# whether it connects or is Dodged." Set before the matchup check below
	# so a Dodged Heavy still exhausts its attacker.
	if action == ACTION_HEAVY:
		attacker["exhaustedNextTurn"] = true

	var atk_range: Dictionary = _attack_range(cp, attacker_side, action)
	var dmg: int = Rng.randi_range(atk_range["min"], atk_range["max"])

	var stance = defender["committedAction"]  # nullable, see the comment on `action` above
	var stance_aimed_here: bool = defender["committedTarget"] == attacker_side

	if stance == ACTION_COUNTER and stance_aimed_here:
		defender["stanceTriggered"] = true
		if action == ACTION_FAST:
			_counter_stop_and_retaliate(cp, attacker_side, defender_side, beats)
		else:
			_counter_bypassed_by_heavy(cp, attacker_side, defender_side, dmg, beats)
		return

	if stance == ACTION_DODGE and stance_aimed_here:
		defender["stanceTriggered"] = true
		if action == ACTION_HEAVY:
			_heavy_dodged(cp, attacker_side, defender_side, beats)
		else:
			_fast_catches_dodge(cp, attacker_side, defender_side, dmg, beats)
		return

	_apply_hit(cp, attacker_side, defender_side, dmg, action, beats)


static func _action_label(action: String) -> String:
	return action.capitalize()


# `player_line`/`enemy_line` read naturally depending on which side is
# acting (second person for the player, same convention systems/combat.gd's
# own hand-written log lines already use throughout).
static func _line(attacker_side: String, player_line: String, enemy_line: String) -> String:
	return player_line if attacker_side == SIDE_PLAYER else enemy_line


static func _apply_hit(cp: Dictionary, attacker_side: String, defender_side: String, dmg: int, action: String, beats: Array) -> void:
	var enemy_name: String = cp["enemy"]["name"]
	var label: String = _action_label(action)
	var line: String
	if attacker_side == SIDE_PLAYER:
		line = "Your %s connects for %d." % [label, dmg]
	else:
		line = "%s's %s connects for %d." % [enemy_name, label, dmg]
	_deal_damage(cp, defender_side, dmg, line, action + "_hit", attacker_side, beats)


static func _counter_stop_and_retaliate(cp: Dictionary, attacker_side: String, defender_side: String, beats: Array) -> void:
	var enemy_name: String = cp["enemy"]["name"]
	_log(cp, beats, _line(attacker_side,
		"Your Fast is stopped cold — %s counters." % enemy_name,
		"%s's Fast is stopped cold — you counter." % enemy_name),
		"counter_stop", { "actorType": attacker_side })
	var retal_range: Dictionary = _attack_range(cp, defender_side, ACTION_FAST)
	var retal_dmg: int = Rng.randi_range(retal_range["min"], retal_range["max"])
	var retal_line: String = _line(defender_side,
		"You hit back for %d." % retal_dmg,
		"%s hits back for %d." % [enemy_name, retal_dmg])
	_deal_damage(cp, attacker_side, retal_dmg, retal_line, "counter_retaliate", defender_side, beats)


static func _counter_bypassed_by_heavy(cp: Dictionary, attacker_side: String, defender_side: String, dmg: int, beats: Array) -> void:
	var enemy_name: String = cp["enemy"]["name"]
	var line: String = _line(attacker_side,
		"Your Heavy barrels through %s's Counter — %d damage." % [enemy_name, dmg],
		"%s's Heavy barrels through your Counter — %d damage." % [enemy_name, dmg])
	_deal_damage(cp, defender_side, dmg, line, "heavy_bypass", attacker_side, beats)


static func _heavy_dodged(cp: Dictionary, attacker_side: String, defender_side: String, beats: Array) -> void:
	var enemy_name: String = cp["enemy"]["name"]
	_log(cp, beats, _line(attacker_side,
		"%s dodges your Heavy — no damage, but the swing leaves you winded." % enemy_name,
		"You dodge %s's Heavy — no damage, but they're left winded." % enemy_name),
		"heavy_dodged", { "actorType": attacker_side })


static func _fast_catches_dodge(cp: Dictionary, attacker_side: String, defender_side: String, dmg: int, beats: Array) -> void:
	var enemy_name: String = cp["enemy"]["name"]
	var line: String = _line(attacker_side,
		"%s can't dodge your Fast — %d damage." % [enemy_name, dmg],
		"You can't dodge %s's Fast — %d damage." % [enemy_name, dmg])
	_deal_damage(cp, defender_side, dmg, line, "fast_catches_dodge", attacker_side, beats)


# Shared HP-application chokepoint: every damage instance in this file --
# a plain hit, a bypassing Heavy, Fast catching a Dodge, or a Counter's own
# retaliation -- funnels through here, which is deliberate: ticket 13a
# "Shield absorption and enemy evadeChance rolls apply after the matchup
# resolves, before HP loss -- unchanged order from today" means the passive
# evadeChance roll belongs at the one point every kind of damage converges,
# not duplicated (or, worse, silently skipped) at each call site. `target_side`
# is whoever's hp this specific instance would reduce -- the retaliation
# case is the one where that's the original ATTACKER, not the defender who
# countered, which is why this takes target/actor as separate params rather
# than assuming attacker-hits-defender. Clamps to 0, appends the HP readout
# to `line`, checks for a win/loss. `kind`/`actor_side` are stamped onto the
# beat for a future presentation layer to key off, same "ids/numbers/
# strings only" beat convention systems/combat.gd's own _log() documents.
static func _deal_damage(cp: Dictionary, target_side: String, dmg: int, line: String, kind: String, actor_side: String, beats: Array) -> void:
	var target: Dictionary = cp[target_side]
	if Rng.chance(target.get("evadeChance", 0.0)):
		var evade_line: String = "You slip out of the way — no damage." if target_side == SIDE_PLAYER else "%s slips out of the way — no damage." % target["name"]
		_log(cp, beats, evade_line, "evaded", { "actorType": actor_side, "targetType": target_side })
		return
	target["hp"] = maxi(0, target["hp"] - dmg)
	var hp_readout: String = "You: %d/%d HP." % [target["hp"], target["hpMax"]] if target_side == SIDE_PLAYER else "%s: %d/%d HP." % [target["name"], target["hp"], target["hpMax"]]
	_log(cp, beats, "%s %s" % [line, hp_readout], kind, { "actorType": actor_side, "targetType": target_side, "dmg": dmg })
	if target["hp"] <= 0:
		if target_side == SIDE_ENEMY:
			cp["outcome"] = "win"
			_log(cp, beats, "%s goes down." % target["name"], "win", {})
		else:
			cp["outcome"] = "loss"
			_log(cp, beats, "You go down.", "loss", {})


static func _resolve_flee(cp: Dictionary, side: String, beats: Array) -> void:
	if side != SIDE_PLAYER:
		return
	if Rng.chance(FLEE_CHANCE):
		cp["outcome"] = "fled"
		_log(cp, beats, "You back off. Fight's over.", "flee_success", {})
	else:
		_log(cp, beats, "You try to leg it — no clean break.", "flee_failed", {})


static func _log(cp: Dictionary, beats: Array, line: String, kind: String, extra: Dictionary) -> void:
	cp["log"].append(line)
	var beat: Dictionary = { "kind": kind, "logLine": line }
	beat.merge(extra)
	beats.append(beat)
	cp["beatsSinceSnapshot"].append(beat)


static func push_prototype_snapshot() -> void:
	var cp: Dictionary = GameState.state["combatPrototype"]
	var snap := {
		"round": cp["round"],
		"log": cp["log"].duplicate(),
		"player": {
			"hp": cp["player"]["hp"],
			"committedAction": cp["player"]["committedAction"],
			"committedTarget": cp["player"]["committedTarget"],
			"exhaustedNextTurn": cp["player"]["exhaustedNextTurn"],
		},
		"enemy": {
			"hp": cp["enemy"]["hp"],
			"committedAction": cp["enemy"]["committedAction"],
			"committedTarget": cp["enemy"]["committedTarget"],
			"exhaustedNextTurn": cp["enemy"]["exhaustedNextTurn"],
			"scriptIndex": cp["enemy"]["scriptIndex"],
		},
	}
	Snapshots.push("combatPrototype", cp["snapshots"], snap)


# Freely available in this prototype (no consumable/Dial gating like
# production's combat_rewind()) -- the point here is proving restoration is
# reliable, not resource scarcity. Bounded only by whether a snapshot exists
# (2-deep stack, same as production).
static func rewind() -> Dictionary:
	var cp: Dictionary = GameState.state["combatPrototype"]
	if not cp["active"] or cp["snapshots"].is_empty():
		return { "ok": false, "reason": "Nothing to rewind." }

	var replay_beats: Array = cp["beatsSinceSnapshot"].duplicate()
	replay_beats.reverse()

	var snap: Dictionary = Snapshots.oldest(cp["snapshots"])
	Snapshots.clear(cp["snapshots"])

	cp["round"] = snap["round"]
	var new_log: Array = snap["log"].duplicate()
	new_log.append("⟲ Rewind. The last exchange never happened.")
	cp["log"] = new_log

	cp["player"]["hp"] = snap["player"]["hp"]
	cp["player"]["committedAction"] = snap["player"]["committedAction"]
	cp["player"]["committedTarget"] = snap["player"]["committedTarget"]
	cp["player"]["exhaustedNextTurn"] = snap["player"]["exhaustedNextTurn"]
	cp["player"]["stanceTriggered"] = false

	cp["enemy"]["hp"] = snap["enemy"]["hp"]
	cp["enemy"]["committedAction"] = snap["enemy"]["committedAction"]
	cp["enemy"]["committedTarget"] = snap["enemy"]["committedTarget"]
	cp["enemy"]["exhaustedNextTurn"] = snap["enemy"]["exhaustedNextTurn"]
	cp["enemy"]["scriptIndex"] = snap["enemy"]["scriptIndex"]
	cp["enemy"]["stanceTriggered"] = false

	cp["outcome"] = null
	cp["beatsSinceSnapshot"] = []

	EventBus.state_changed.emit()
	return { "ok": true, "beats": replay_beats }


# Tears the prototype fight down and returns to whichever screen launched
# it (the Debug app -- see scenes/screens/phone.gd's own "Solo Combat
# Prototype" card) rather than any production combat exit routing.
static func exit_encounter() -> Dictionary:
	GameState.state["combatPrototype"]["active"] = false
	Nav.go_to("phone")
	return { "ok": true }
