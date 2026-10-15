class_name CombatPrototype
extends RefCounted

# Sandboxed Open/Guarded round-planning combat prototype
# (.scratch/combat-revamp/spec.md). Own state at
# GameState.state["combatPrototype"], own Rewind stack, own screen
# (scenes/screens/combat_prototype.gd); never reads or writes the real
# player, inventory, Dial, XP or calendar. Live combat (Combat) is separate.
#
# A fight is start(config), then resolve_round(plan) once per round.
# Combatants live in one array, the player at index 0 and enemies after, so
# array order is the timeline's last tie-break (spec §Timeline order). Each
# enemy holds this round's committed plan and next round's pre-rolled one;
# the player's draft plan is playerPlan, edited with set_plan_action().
# Randomness runs off the fight's own RNG state (rngState), so a Rewind
# replays the same rolls for the same plan.

const SIDE_PLAYER := "player"
const SIDE_ENEMY := "enemy"

const GUARDED := "guarded"
const OPEN := "open"
const UNCHANGED := "unchanged"
const GUARD_EFFECTS: Array[String] = [GUARDED, OPEN, UNCHANGED]

const TARGET_SELF := "self"
const TARGET_ENEMY := "enemy"
const TARGET_TYPES: Array[String] = [TARGET_SELF, TARGET_ENEMY]

const EFFECT_NONE := "none"
const EFFECT_DAMAGE := "damage"
const EFFECTS: Array[String] = [EFFECT_NONE, EFFECT_DAMAGE]

const PLAYER_INDEX := 0
const DEFAULT_ARCHETYPE := "mugger"


static func _data() -> Dictionary:
	return GameData.COMBAT_PROTOTYPE


static func _root() -> Dictionary:
	return GameState.state["combatPrototype"]


static func new_state() -> Dictionary:
	return {
		"active": false,
		"round": 0,
		# null while the fight runs, then "win" or "loss".
		"outcome": null,
		# Player at PLAYER_INDEX, then enemies; see _build_combatant().
		"combatants": [],
		# The player's draft for this round: one entry per action, each
		# null (unfilled) or { move, target }.
		"playerPlan": [],
		"rngState": 0,
		# Every resolved beat so far, oldest first (see _beat()).
		"log": [],
		"snapshots": [],
	}


static func open() -> void:
	Nav.go_to("combat_prototype")


static func exit() -> void:
	Nav.go_to("phone")


# Drops the current fight so the screen shows setup again.
static func close_fight() -> void:
	GameState.state["combatPrototype"] = new_state()
	EventBus.state_changed.emit()


static func level_max() -> int:
	return int(_data()["levelMax"])


static func move(move_id: String) -> Dictionary:
	return _data()["moves"].get(move_id, {})


static func actions_per_round(combatant: Dictionary) -> int:
	return int(_data()["actionsPerRound"][combatant["level"]])


static func display_name(combatant: Dictionary) -> String:
	return str(combatant["name"]).capitalize() if combatant["side"] == SIDE_ENEMY else "You"


# ── Setup ────────────────────────────────────────────────────────────────

# config: playerLevel (1..levelMax, default 1); enemies, an Array of
# { archetype, level } (default one level-1 mugger); seed (default fresh);
# enemyPlans, test-only: per enemy an Array of rounds, each an Array of move
# ids, used in place of the archetype's patterns (round n reads entry
# (n-1) mod size). Everyone starts Guarded. Returns the new fight state, or
# {} for an unknown archetype.
static func start(config: Dictionary = {}) -> Dictionary:
	var archetypes: Dictionary = _data()["archetypes"]
	var enemy_specs: Array = config.get("enemies", [{ "archetype": DEFAULT_ARCHETYPE, "level": 1 }])
	for spec in enemy_specs:
		if not archetypes.has(spec.get("archetype", "")):
			return {}

	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get("seed", Rng.fresh_seed()))

	var cp := new_state()
	cp["active"] = true
	cp["round"] = 1
	var combatants: Array = cp["combatants"]
	combatants.append(_build_combatant(SIDE_PLAYER, _data()["playerBase"], int(config.get("playerLevel", 1))))
	var overrides: Array = config.get("enemyPlans", [])
	for i in range(enemy_specs.size()):
		var spec: Dictionary = enemy_specs[i]
		var enemy := _build_combatant(SIDE_ENEMY, archetypes[spec["archetype"]], int(spec.get("level", 1)))
		enemy["archetype"] = spec["archetype"]
		enemy["planOverride"] = overrides[i] if i < overrides.size() else null
		combatants.append(enemy)

	for i in range(combatants.size()):
		if combatants[i]["side"] == SIDE_ENEMY:
			combatants[i]["plan"] = _roll_plan(cp, i, 1, rng)
			combatants[i]["nextPlan"] = _roll_plan(cp, i, 2, rng)
	cp["playerPlan"] = _empty_plan(combatants[PLAYER_INDEX])
	cp["rngState"] = rng.state

	GameState.state["combatPrototype"] = cp
	EventBus.state_changed.emit()
	return cp


# HP and attack are the base plus the Combat Skill curves; speed is the
# Combat Skill speed curve (spec §Actions per round).
static func _build_combatant(side: String, base: Dictionary, level: int) -> Dictionary:
	var lv := clampi(level, 1, level_max())
	var hp: int = int(base["hpBase"]) + int(GameData.COMBAT_HP_BONUS_BY_LEVEL[lv])
	var attack_bonus: int = int(GameData.COMBAT_ATTACK_BONUS_BY_LEVEL[lv])
	return {
		"side": side, "name": base["name"], "level": lv,
		"hp": hp, "hpMax": hp,
		"attackMin": int(base["attackMin"]) + attack_bonus,
		"attackMax": int(base["attackMax"]) + attack_bonus,
		"speed": int(GameData.COMBAT_SPEED_BY_LEVEL[lv]),
		"guard": GUARDED, "koed": false,
		"plan": [], "nextPlan": [],
	}


static func _empty_plan(combatant: Dictionary) -> Array:
	var plan: Array = []
	plan.resize(actions_per_round(combatant))
	return plan


# One combatant's committed plan for round `round_no`: a weighted archetype
# pattern (or the test override), cycled to fill its actions per round,
# with a target per offensive action.
static func _roll_plan(cp: Dictionary, actor: int, round_no: int, rng: RandomNumberGenerator) -> Array:
	var combatant: Dictionary = cp["combatants"][actor]
	var moves: Array
	var override = combatant.get("planOverride")
	if override != null and not override.is_empty():
		moves = override[(round_no - 1) % override.size()]
	else:
		moves = _pick_pattern(_data()["archetypes"][combatant["archetype"]]["patterns"], rng)["moves"]
	var plan: Array = []
	for i in range(actions_per_round(combatant)):
		var move_id: String = moves[i % moves.size()]
		plan.append({ "move": move_id, "target": _pick_target(cp, actor, move_id, rng) })
	return plan


static func _pick_pattern(patterns: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total := 0.0
	for pattern in patterns:
		total += float(pattern["weight"])
	var r := rng.randf() * total
	for pattern in patterns:
		r -= float(pattern["weight"])
		if r < 0.0:
			return pattern
	return patterns[-1]


# Self-targeted moves aim at the actor; offensive ones pick uniformly over
# the actor's living opponents.
static func _pick_target(cp: Dictionary, actor: int, move_id: String, rng: RandomNumberGenerator) -> int:
	if move(move_id)["target"] == TARGET_SELF:
		return actor
	var opponents := _living_opponents(cp, actor)
	if opponents.is_empty():
		return -1
	if opponents.size() == 1:
		return opponents[0]
	return opponents[rng.randi_range(0, opponents.size() - 1)]


static func _living_opponents(cp: Dictionary, actor: int) -> Array:
	var combatants: Array = cp["combatants"]
	var side: String = combatants[actor]["side"]
	var result: Array = []
	for i in range(combatants.size()):
		if combatants[i]["side"] != side and not combatants[i]["koed"]:
			result.append(i)
	return result


# ── Planning ─────────────────────────────────────────────────────────────

# Fills the player's draft action at `position`. target -1 picks the first
# living enemy for an offensive move.
static func set_plan_action(position: int, move_id: String, target: int = -1) -> Dictionary:
	var cp := _root()
	if not cp["active"] or cp["outcome"] != null:
		return { "ok": false, "reason": "No fight on." }
	if position < 0 or position >= cp["playerPlan"].size():
		return { "ok": false, "reason": "No such action." }
	var entry = _normalize_action(cp, { "move": move_id, "target": target })
	var reason := _action_block_reason(cp, entry)
	if reason != "":
		return { "ok": false, "reason": reason }
	cp["playerPlan"][position] = entry
	EventBus.state_changed.emit()
	return { "ok": true }


static func clear_plan_action(position: int) -> Dictionary:
	var cp := _root()
	if not cp["active"] or cp["outcome"] != null:
		return { "ok": false, "reason": "No fight on." }
	if position < 0 or position >= cp["playerPlan"].size():
		return { "ok": false, "reason": "No such action." }
	cp["playerPlan"][position] = null
	EventBus.state_changed.emit()
	return { "ok": true }


static func _normalize_action(cp: Dictionary, action) -> Variant:
	if action == null:
		return null
	var move_id: String = str(action.get("move", ""))
	var target: int = int(action.get("target", -1))
	if not move(move_id).is_empty():
		if move(move_id)["target"] == TARGET_SELF:
			target = PLAYER_INDEX
		elif target < 0:
			var opponents := _living_opponents(cp, PLAYER_INDEX)
			target = opponents[0] if not opponents.is_empty() else -1
	return { "move": move_id, "target": target }


static func _action_block_reason(cp: Dictionary, action) -> String:
	if action == null:
		return "Fill every action."
	var m := move(action["move"])
	if m.is_empty():
		return "Unknown move."
	if m["target"] == TARGET_ENEMY and not _living_opponents(cp, PLAYER_INDEX).has(action["target"]):
		return "Pick a target."
	return ""


# Why `plan` can't be committed this round, or "" if it can.
static func plan_block_reason(cp: Dictionary, plan: Array) -> String:
	if plan.size() != actions_per_round(cp["combatants"][PLAYER_INDEX]):
		return "Fill every action."
	for action in plan:
		var reason := _action_block_reason(cp, action)
		if reason != "":
			return reason
	return ""


# ── Read-only helpers for the screen ─────────────────────────────────────

# This round's actions in resolution order: action index, then speed
# descending, then combatant order (player first). Each entry is
# { actor, index }; the player's entries cover every draft position, filled
# or not.
static func timeline(cp: Dictionary) -> Array:
	var combatants: Array = cp["combatants"]
	var entries: Array = []
	for i in range(combatants.size()):
		if combatants[i]["koed"]:
			continue
		for a in range(_plan_of(cp, i).size()):
			entries.append({ "actor": i, "index": a })
	entries.sort_custom(func(x, y):
		if x["index"] != y["index"]:
			return x["index"] < y["index"]
		var sx: int = combatants[x["actor"]]["speed"]
		var sy: int = combatants[y["actor"]]["speed"]
		if sx != sy:
			return sx > sy
		return x["actor"] < y["actor"]
	)
	return entries


static func _plan_of(cp: Dictionary, actor: int) -> Array:
	return cp["playerPlan"] if actor == PLAYER_INDEX else cp["combatants"][actor]["plan"]


# A combatant's guard state now, then after each of its planned actions
# this round (an unfilled player action leaves it unchanged).
static func guard_preview(cp: Dictionary, actor: int) -> Array:
	var state: String = cp["combatants"][actor]["guard"]
	var result: Array = [state]
	for action in _plan_of(cp, actor):
		if action != null:
			var effect: String = move(action["move"]).get("actorGuard", UNCHANGED)
			if effect != UNCHANGED:
				state = effect
		result.append(state)
	return result


# ── Resolution ───────────────────────────────────────────────────────────

# Commits the player's plan (Array of { move, target }; target may be
# omitted for auto-targeting) against the enemies' committed plans and
# resolves the round in timeline() order. A KO'd combatant's remaining
# actions are dropped and the fight stops the moment it's won or lost.
# Returns { ok, beats, outcome }; on a fight still running, next round's
# plans move up and the round after's are rolled.
static func resolve_round(plan: Array) -> Dictionary:
	var cp := _root()
	if not cp["active"] or cp["outcome"] != null:
		return { "ok": false, "reason": "No fight on." }
	var normalized: Array = plan.map(func(action): return _normalize_action(cp, action))
	var reason := plan_block_reason(cp, normalized)
	if reason != "":
		return { "ok": false, "reason": reason }

	cp["playerPlan"] = normalized
	_push_snapshot(cp)

	var rng := RandomNumberGenerator.new()
	rng.state = cp["rngState"]
	var beats: Array = []
	var combatants: Array = cp["combatants"]
	for entry in timeline(cp):
		if cp["outcome"] != null:
			break
		if combatants[entry["actor"]]["koed"]:
			continue
		_resolve_action(cp, entry["actor"], _plan_of(cp, entry["actor"])[entry["index"]], rng, beats)
	cp["log"].append_array(beats)

	if cp["outcome"] == null:
		cp["round"] += 1
		for i in range(combatants.size()):
			if combatants[i]["side"] == SIDE_ENEMY:
				combatants[i]["plan"] = combatants[i]["nextPlan"]
				combatants[i]["nextPlan"] = [] if combatants[i]["koed"] else _roll_plan(cp, i, cp["round"] + 1, rng)
		cp["playerPlan"] = _empty_plan(combatants[PLAYER_INDEX])
	cp["rngState"] = rng.state

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats, "outcome": cp["outcome"] }


# Applies the move's effect, then its effect on the actor's guard state.
static func _resolve_action(cp: Dictionary, actor_idx: int, action: Dictionary, rng: RandomNumberGenerator, beats: Array) -> void:
	var m := move(action["move"])
	var actor: Dictionary = cp["combatants"][actor_idx]
	var first_beat := beats.size()
	match m["effect"]:
		EFFECT_DAMAGE:
			var target := _retarget(cp, actor_idx, int(action["target"]))
			if target >= 0:
				_strike(cp, actor_idx, target, action["move"], rng, beats)
		_:
			_beat(cp, beats, action["move"], actor_idx, -1, action["move"], {})
	if m["actorGuard"] != UNCHANGED and not actor["koed"]:
		actor["guard"] = m["actorGuard"]
	for i in range(first_beat, beats.size()):
		if beats[i]["actor"] == actor_idx:
			beats[i]["actorGuard"] = actor["guard"]


# An action aimed at a KO'd opponent moves to the next living one in index
# order (wrapping); -1 if none is left.
static func _retarget(cp: Dictionary, actor: int, target: int) -> int:
	var opponents := _living_opponents(cp, actor)
	if opponents.is_empty():
		return -1
	if opponents.has(target):
		return target
	for i in opponents:
		if i > target:
			return i
	return opponents[0]


# Damage rolls within the attacker's range: full on an Open target,
# round(roll × chipMultiplier) (min 1) on a Guarded one; a crit doubles the
# final figure (spec §Damage).
static func _strike(cp: Dictionary, actor_idx: int, target_idx: int, move_id: String, rng: RandomNumberGenerator, beats: Array) -> void:
	var combatants: Array = cp["combatants"]
	var actor: Dictionary = combatants[actor_idx]
	var target: Dictionary = combatants[target_idx]
	var roll := rng.randi_range(actor["attackMin"], actor["attackMax"])
	var guarded: bool = target["guard"] == GUARDED
	var dmg := roll
	if guarded:
		dmg = maxi(1, GameState.round_epsilon(roll * float(_data()["chipMultiplier"])))
	var crit := rng.randf() < float(_data()["critChance"][actor["level"]])
	if crit:
		dmg *= 2
	target["hp"] = maxi(0, target["hp"] - dmg)
	_beat(cp, beats, "chip" if guarded else "hit", actor_idx, target_idx, move_id, {
		"roll": roll, "crit": crit, "guarded": guarded, "dmg": dmg, "hpAfter": target["hp"],
	})
	if target["hp"] == 0:
		target["koed"] = true
		_beat(cp, beats, "ko", actor_idx, target_idx, move_id, {})
		_check_outcome(cp)


static func _check_outcome(cp: Dictionary) -> void:
	var combatants: Array = cp["combatants"]
	if combatants[PLAYER_INDEX]["koed"]:
		cp["outcome"] = "loss"
		return
	for c in combatants:
		if c["side"] == SIDE_ENEMY and not c["koed"]:
			return
	cp["outcome"] = "win"


# One beat: { round, kind, actor, target, move, text } plus `extra`. The
# line's "self" variant is used when the player is the actor (or, for a
# KO, the one going down).
static func _beat(cp: Dictionary, beats: Array, kind: String, actor: int, target: int, move_id: String, extra: Dictionary) -> void:
	var lines: Dictionary = _data()["beatLines"]
	var combatants: Array = cp["combatants"]
	var subject: int = target if kind == "ko" else actor
	var variant: String = "self" if subject == PLAYER_INDEX else "other"
	var text: String = lines[kind][variant].format({
		"actor": combatants[actor]["name"],
		"target": combatants[target]["name"] if target >= 0 else "",
		"dmg": extra.get("dmg", 0),
	})
	if extra.get("crit", false):
		text += lines["crit"]
	var beat := { "round": cp["round"], "kind": kind, "actor": actor, "target": target, "move": move_id, "text": text[0].to_upper() + text.substr(1) }
	beat.merge(extra)
	beats.append(beat)


# ── Rewind ───────────────────────────────────────────────────────────────

static func _push_snapshot(cp: Dictionary) -> void:
	var frame := {}
	for key in cp.keys():
		if key != "snapshots":
			frame[key] = cp[key]
	Snapshots.push("combatPrototype", cp["snapshots"], frame)


# Restores the state from just before the last committed round, with that
# round's plan back in playerPlan for editing.
static func rewind() -> Dictionary:
	var cp := _root()
	var frame = Snapshots.pop_newest(cp["snapshots"])
	if frame == null:
		return { "ok": false, "reason": "Nothing to rewind." }
	for key in frame.keys():
		cp[key] = frame[key]
	EventBus.state_changed.emit()
	return { "ok": true }
