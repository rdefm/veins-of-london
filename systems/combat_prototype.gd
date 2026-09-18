class_name CombatPrototype
extends RefCounted

# A bounded, throwaway combat experiment for the Fast/Heavy/Counter/Dodge
# matchup grid, committed-intent resolution, and Rewind reliability -- not
# production combat. Isolated from systems/combat.gd: own state lives in
# GameState.state["combatPrototype"], own snapshot stack, own screen
# (scenes/screens/combat_prototype.gd); never touches the real player's hp.
# Item use IS real though: it spends from the player's actual
# inventory/Dial charge, restored on Rewind (push_prototype_snapshot()/
# rewind()). cp.enemies is always an Array (solo == one-element);
# cp.wave/cp.totalWaves track a multi-wave encounter's progress.
#
# A round can take multiple player commits when Motion is active;
# cp["_pending"] holds the in-progress round's queue/cursor/beats so a
# call needing fresh input can resume instead of restarting (see
# _advance_round()). Not wired: Grab/Bolt/Call (no contract defined);
# Prophet's Breath and Wormhole (not in the approved item list); Healing
# Salve (out-of-combat only); Blast's disarm (logged-only flourish, no
# weapon/ability to strip here); allies (always player-solo vs N enemies).

const ACTION_FAST := "fast"
const ACTION_HEAVY := "heavy"
const ACTION_COUNTER := "counter"
const ACTION_DODGE := "dodge"
const ACTION_FLEE := "flee"
const ACTION_ITEM := "item"

# The four actions a script entry (data/combat_prototype.json) may name;
# GameData validates scripts against this. Flee/Item excluded -- no
# scripted enemy ever flees or uses an item.
const SCRIPTABLE_ACTIONS: Array[String] = [ACTION_FAST, ACTION_HEAVY, ACTION_COUNTER, ACTION_DODGE]
const ACTIONS_STANCE: Array[String] = [ACTION_COUNTER, ACTION_DODGE]
const COMMITTABLE_ACTIONS: Array[String] = [ACTION_FAST, ACTION_HEAVY, ACTION_COUNTER, ACTION_DODGE, ACTION_FLEE]

# The only calc effects this prototype wires -- see file header for what's
# deliberately excluded and why.
const ITEM_RECIPE_KEYS: Array[String] = ["timePearl", "enhancementPowder", "shield", "blast", "blackHole", "healingBurst"]

const ITEM_ZERO_STOCK_REASON := {
	"timePearl": "No time pearls.", "enhancementPowder": "No enhancement powder.",
	"shield": "No shield.", "blast": "No blast.", "blackHole": "No black hole.",
	"healingBurst": "No healing burst.",
}

# Heavy = Fast range x1.5 (min and max), rounded via GameState.round_epsilon().
# Prototype-only multiplier, not balance-final.
const HEAVY_MULTIPLIER := 1.5

# Item use and Flee each consume the actor's one committed action for the
# round, same as production. Reuses Combat's own flee()/use_blast() chance
# and boost (no weapon/disarm mechanic exists in this prototype).
const FLEE_CHANCE := 0.65
const BLAST_FLEE_BOOST_CHANCE := 0.90
const BLAST_DISARM_CHANCE := 0.15


# ── Encounter setup ──────────────────────────────────────────────────────

# Fresh full-hp start for `encounter_id`. The prototype's own player.hp/
# hpMax is seeded from the real player's hpMax but is never written back --
# every function below only ever touches cp["player"]["hp"], so a prototype
# fight can never leak damage into the real save.
static func start_encounter(encounter_id: String) -> Dictionary:
	var encounters: Dictionary = GameData.COMBAT_PROTOTYPE.get("encounters", {})
	if not encounters.has(encounter_id):
		return { "ok": false, "reason": "Unknown encounter '%s'." % encounter_id }
	var def: Dictionary = encounters[encounter_id]
	var player_hp_max: int = GameState.state["player"]["hpMax"]
	var total_waves: int = def["waves"].size() if def.has("waves") else 1

	GameState.state["combatPrototype"] = {
		"active": true, "encounterId": encounter_id, "wave": 0, "totalWaves": total_waves,
		"round": 1, "outcome": null,
		"log": [def.get("intro", "")],
		"player": {
			"hp": player_hp_max, "hpMax": player_hp_max,
			"committedAction": null, "committedTarget": null, "committedItem": null,
			"exhaustedNextTurn": false, "stanceTriggered": false, "shieldPool": 0,
		},
		"enemies": [],
		"frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "blastFleeBoost": false,
		"snapshots": [], "beatsSinceSnapshot": [],
		"_pending": null, "_waveCleared": false,
	}
	var cp: Dictionary = GameState.state["combatPrototype"]
	cp["enemies"] = _current_wave_defs(cp).map(_build_enemy_state)
	Nav.go_to("combat_prototype")
	return { "ok": true }


# Fresh start for whichever encounter follows `current` in
# GameData.COMBAT_PROTOTYPE.encounterOrder -- the fixed three-fight teaching
# sequence only (squad/wave encounters live outside this order, see
# list_launchable_encounters() below).
static func advance_to_next_encounter() -> Dictionary:
	var order: Array = GameData.COMBAT_PROTOTYPE.get("encounterOrder", [])
	var current: String = GameState.state["combatPrototype"]["encounterId"]
	var idx: int = order.find(current)
	if idx == -1 or idx + 1 >= order.size():
		return { "ok": false, "reason": "No further encounter." }
	return start_encounter(order[idx + 1])


# Every encounters.<id> NOT in the fixed teaching order -- squad/wave/other
# evaluation encounters, reached directly rather than via
# advance_to_next_encounter(). The Debug app's card (scenes/phone_apps/debug_app.gd)
# lists these generically off this instead of hardcoding ids.
static func list_launchable_encounters() -> Array:
	var order: Array = GameData.COMBAT_PROTOTYPE.get("encounterOrder", [])
	var encounters: Dictionary = GameData.COMBAT_PROTOTYPE.get("encounters", {})
	var extra: Array = []
	for id in encounters.keys():
		if not order.has(id):
			extra.append(id)
	extra.sort()
	return extra


static func _guard_active(cp: Dictionary):
	if not cp.get("active", false) or cp.get("outcome") != null:
		return { "ok": false, "reason": "Encounter not active." }
	return null


# ── Roster helpers ───────────────────────────────────────────────────────

static func _encounter_def(cp: Dictionary) -> Dictionary:
	return GameData.COMBAT_PROTOTYPE["encounters"][cp["encounterId"]]


# The current wave's roster of raw JSON enemy defs. A flat teaching-order
# entry (no "enemies"/"waves" key) wraps itself as a one-element roster, so
# solo encounters go through the same path as a squad/wave one.
static func _current_wave_defs(cp: Dictionary) -> Array:
	var def: Dictionary = _encounter_def(cp)
	if def.has("waves"):
		return def["waves"][cp["wave"]]
	if def.has("enemies"):
		return def["enemies"]
	return [def]


static func _build_enemy_state(def: Dictionary) -> Dictionary:
	return {
		"name": def["name"], "hp": def["hp"], "hpMax": def["hp"],
		"attackMin": def["attackMin"], "attackMax": def["attackMax"],
		"speed": def["speed"], "evadeChance": def.get("evadeChance", 0.0),
		"scriptIndex": 0, "committedAction": null, "exhaustedNextTurn": false,
		"stanceTriggered": false, "koed": false,
	}


# target_index >= 0 must name a living enemy; -1 auto-resolves to "the sole
# living enemy" and refuses (-1) when a squad has more than one still
# standing -- there's no correct default to guess in that case.
static func _resolve_target(cp: Dictionary, target_index: int) -> int:
	var enemies: Array = cp["enemies"]
	if target_index >= 0:
		if target_index < enemies.size() and not enemies[target_index]["koed"]:
			return target_index
		return -1
	var living: Array = []
	for i in range(enemies.size()):
		if not enemies[i]["koed"]:
			living.append(i)
	if living.size() == 1:
		return living[0]
	return -1


static func _sorted_living_enemy_indices(cp: Dictionary) -> Array:
	var enemies: Array = cp["enemies"]
	var living: Array = []
	for i in range(enemies.size()):
		if not enemies[i]["koed"]:
			living.append(i)
	living.sort_custom(func(a, b):
		if enemies[a]["speed"] != enemies[b]["speed"]:
			return enemies[a]["speed"] > enemies[b]["speed"]
		return a < b
	)
	return living


static func _attack_range_for(cp: Dictionary, actor_is_player: bool, action: String, enemy_idx: int) -> Dictionary:
	var base: Dictionary
	if actor_is_player:
		base = Combat.get_attack_range()
	else:
		var enemy: Dictionary = cp["enemies"][enemy_idx]
		base = { "min": enemy["attackMin"], "max": enemy["attackMax"] }
	if action != ACTION_HEAVY:
		return base
	return {
		"min": GameState.round_epsilon(base["min"] * HEAVY_MULTIPLIER),
		"max": GameState.round_epsilon(base["max"] * HEAVY_MULTIPLIER),
	}


# ── Player Fast/Heavy/Counter/Dodge/Flee ─────────────────────────────────

static func take_player_action(action: String, target_index: int = -1) -> Dictionary:
	var cp: Dictionary = GameState.state["combatPrototype"]
	var guard = _guard_active(cp)
	if guard != null:
		return guard
	if not COMMITTABLE_ACTIONS.has(action):
		return { "ok": false, "reason": "Unknown action '%s'." % action }
	if cp["player"]["exhaustedNextTurn"] and cp.get("_pending") == null:
		return { "ok": false, "reason": "Exhausted this round -- call skip_exhausted_round() instead." }

	var resolved_target := -1
	if action == ACTION_FAST or action == ACTION_HEAVY or action == ACTION_COUNTER or action == ACTION_DODGE:
		resolved_target = _resolve_target(cp, target_index)
		if resolved_target == -1:
			return { "ok": false, "reason": "Invalid target." }

	if _ensure_round_started(cp):
		_start_round_queue(cp)
	return _advance_round(cp, action, resolved_target, null)


# Called by the screen instead of take_player_action() when
# cp.player.exhaustedNextTurn is true at the START of a round -- there's no
# action to pick, so the round auto-resolves with no player action (every
# enemy turn still happens). Not valid mid-round (an already-paused extra
# Motion slot auto-skips on its own inside _advance_round() instead).
static func skip_exhausted_round() -> Dictionary:
	var cp: Dictionary = GameState.state["combatPrototype"]
	var guard = _guard_active(cp)
	if guard != null:
		return guard
	if cp.get("_pending") != null:
		return { "ok": false, "reason": "A round is already in progress." }
	if not cp["player"]["exhaustedNextTurn"]:
		return { "ok": false, "reason": "Player is not exhausted." }

	push_prototype_snapshot()
	var player: Dictionary = cp["player"]
	player["exhaustedNextTurn"] = false
	player["committedAction"] = null
	player["committedTarget"] = null
	player["committedItem"] = null
	player["stanceTriggered"] = false
	for enemy in cp["enemies"]:
		enemy["stanceTriggered"] = false

	var beats: Array = []
	_log(cp, beats, "You're exhausted — catching your breath.", "exhausted", { "actorType": "player" })
	_commit_enemies(cp)
	for i in _sorted_living_enemy_indices(cp):
		if cp["outcome"] != null:
			break
		_resolve_enemy_entry(cp, i, beats)

	return _finalize_round(cp, beats)


# ── Items ─────────────────────────────────────────────────────────────────

# Zero-stock/already-active guards run BEFORE any real inventory is spent,
# same order production's own use_*() functions use -- a blocked attempt
# costs nothing and doesn't consume the round.
static func _item_already_active_reason(cp: Dictionary, item_id: String) -> String:
	match item_id:
		"timePearl":
			if cp["frozenTurns"] > 0:
				return "Already frozen. Save the pearl."
		"enhancementPowder":
			if cp["motionTurns"] > 0:
				return "Already moving fast. Wait for it to wear off."
		"shield":
			if cp["player"]["shieldPool"] > 0:
				return "Shield's already up. Save it."
	return ""


# Direct-bag entry point -- spends from the player's real
# GameState.state["player"]["inventory"] via Crafting.inventory_remove(),
# exactly as production combat.gd does.
static func use_item(item_id: String, target_index: int = -1) -> Dictionary:
	var cp: Dictionary = GameState.state["combatPrototype"]
	var guard = _guard_active(cp)
	if guard != null:
		return guard
	if not ITEM_RECIPE_KEYS.has(item_id):
		return { "ok": false, "reason": "No combat effect for that item." }
	if cp["player"]["exhaustedNextTurn"] and cp.get("_pending") == null:
		return { "ok": false, "reason": "Exhausted this round -- call skip_exhausted_round() instead." }

	var resolved_target := -1
	if item_id == "blast":
		resolved_target = _resolve_target(cp, target_index)
		if resolved_target == -1:
			return { "ok": false, "reason": "Invalid target." }

	if Crafting.inventory_qty(item_id) <= 0:
		return { "ok": false, "reason": ITEM_ZERO_STOCK_REASON[item_id] }
	var blocked: String = _item_already_active_reason(cp, item_id)
	if blocked != "":
		cp["log"].append(blocked)
		EventBus.state_changed.emit()
		return { "ok": false, "reason": blocked }

	# The round -- and its snapshot -- must exist BEFORE anything real is
	# spent, or a later Rewind would restore to a snapshot that already
	# reflects this item as spent. A no-op if this call is filling an
	# already-open Motion extra slot instead of starting a fresh round.
	var started_round: bool = _ensure_round_started(cp)

	Crafting.inventory_remove(item_id, 1)
	var skill: int = GameState.state["player"]["craftingSkill"]
	var power = Crafting.effect_power(item_id, skill)
	var pre_beats: Array = []
	_apply_item_effect(cp, item_id, power, 1, resolved_target, pre_beats)

	# Queue build deliberately happens AFTER the effect above -- Enhancement
	# Powder's own motionTurns must already be set before _build_queue()
	# decides how many extra player slots this round's queue gets.
	if started_round:
		_start_round_queue(cp)

	return _advance_round(cp, ACTION_ITEM, resolved_target, item_id, pre_beats)


# Dial-cast entry point (Dial.cast_complication(), including its per-dial
# power/target multiplier).
static func cast_dial_complication(dial_index: int, target_index: int = -1) -> Dictionary:
	var cp: Dictionary = GameState.state["combatPrototype"]
	var guard = _guard_active(cp)
	if guard != null:
		return guard
	if cp["player"]["exhaustedNextTurn"] and cp.get("_pending") == null:
		return { "ok": false, "reason": "Exhausted this round -- call skip_exhausted_round() instead." }

	var player: Dictionary = GameState.state["player"]
	var dial = player["dial"]
	if dial == null:
		return { "ok": false, "reason": "No Dial." }
	var loaded: Array = dial["loadedComplications"]
	if dial_index < 0 or dial_index >= loaded.size():
		return { "ok": false, "reason": "No such Complication." }
	var recipe_key: String = loaded[dial_index]["recipeKey"]
	if not ITEM_RECIPE_KEYS.has(recipe_key):
		return { "ok": false, "reason": "No combat effect for that unit." }

	var resolved_target := -1
	if recipe_key == "blast":
		resolved_target = _resolve_target(cp, target_index)
		if resolved_target == -1:
			return { "ok": false, "reason": "Invalid target." }

	var blocked: String = _item_already_active_reason(cp, recipe_key)
	if blocked != "":
		cp["log"].append(blocked)
		EventBus.state_changed.emit()
		return { "ok": false, "reason": blocked }

	# Same ordering requirement as use_item() above: the round (and its
	# snapshot) must exist before Dial.cast_complication() spends a real
	# charge.
	var started_round: bool = _ensure_round_started(cp)

	var cast: Dictionary = Dial.cast_complication(dial_index)
	if not cast["ok"]:
		return cast

	var pre_beats: Array = []
	_apply_item_effect(cp, recipe_key, cast["power"], cast["targets"], resolved_target, pre_beats)

	# Same reordering as use_item() -- see the comment there.
	if started_round:
		_start_round_queue(cp)

	return _advance_round(cp, ACTION_ITEM, resolved_target, recipe_key, pre_beats)


# Applies one item's effect immediately, same as production's own use_*()/
# cast_complication() branches. `targets` is the Dial's per-tier Spread
# Movement multiplier (always 1 for the direct-bag path); enhancementPowder
# is deliberately exempt (motionPower/motionTurns read `power` directly),
# matching that same branch in Combat.cast_complication().
static func _apply_item_effect(cp: Dictionary, item_id: String, power, targets: int, target_index: int, beats: Array) -> void:
	match item_id:
		"timePearl":
			var total: int = int(power) * targets
			cp["frozenTurns"] += total
			_log(cp, beats, "You throw a time pearl. Everything slows. (%d turn%s)" % [total, "" if total == 1 else "s"], "use_time_pearl", { "effectKey": "timePearl" })
		"enhancementPowder":
			cp["motionPower"] = power
			cp["motionTurns"] = 2 if power >= 3 else 1
			_log(cp, beats, "You rub the powder in. You feel very fast.", "use_motion", {})
		"shield":
			cp["player"]["shieldPool"] += int(power) * targets
			_log(cp, beats, "A shimmer folds around you. Shield up — %d absorption." % cp["player"]["shieldPool"], "use_shield", { "effectKey": "shield" })
		"blast":
			var dmg: int = int(power) * targets
			var enemy: Dictionary = cp["enemies"][target_index]
			var line: String = "You let off a blast at %s." % enemy["name"]
			_deal_damage(cp, false, target_index, dmg, line, "use_blast", true, -1, beats)
			cp["blastFleeBoost"] = true
			if Rng.chance(BLAST_DISARM_CHANCE) and not enemy["koed"]:
				# See file header: disarm has no weapon/ability to strip here,
				# so this is a logged-only flourish, not a mechanic.
				_log(cp, beats, "The shove knocks them off balance.", "use_disarm", { "targetType": "enemy", "targetIndex": target_index })
		"blackHole":
			var per_enemy_dmg: int = int(power) * targets
			var freeze_turns: int = (1 + int(floor(float(power) / 8.0))) * targets
			_log(cp, beats, "You drop a black hole.", "use_black_hole_announce", {})
			for i in range(cp["enemies"].size()):
				if cp["enemies"][i]["koed"]:
					continue
				cp["frozenTurns"] += freeze_turns
				var enemy_line: String = "%s is caught in it." % cp["enemies"][i]["name"]
				_deal_damage(cp, false, i, per_enemy_dmg, enemy_line, "use_black_hole_hit", true, -1, beats)
		"healingBurst":
			var player: Dictionary = cp["player"]
			var old_hp: int = player["hp"]
			player["hp"] = mini(player["hp"] + int(power) * targets, player["hpMax"])
			var healed: int = player["hp"] - old_hp
			_log(cp, beats, "You down a healing burst — +%d HP. %d/%d HP." % [healed, player["hp"], player["hpMax"]], "use_healing_burst", { "effectKey": "healingBurst" })


# ── Round engine ──────────────────────────────────────────────────────────

# Speed-descending queue over the player + every living enemy, ties broken
# player-first-then-enemy-array-order (R§3.7a, same convention as
# Combat.build_turn_queue()). While cp.motionTurns > 0, (attack_count - 1)
# extra player entries are spliced in after the player's base slot,
# mirroring Combat.build_turn_queue()'s own Motion-insertion.
static func _build_queue(cp: Dictionary) -> Array:
	var entries: Array = [{ "type": "player", "speed": Combat._player_speed() }]
	var enemies: Array = cp["enemies"]
	for i in range(enemies.size()):
		if not enemies[i]["koed"]:
			entries.append({ "type": "enemy", "idx": i, "speed": enemies[i]["speed"] })

	var order: Array = range(entries.size())
	order.sort_custom(func(a, b):
		if entries[a]["speed"] != entries[b]["speed"]:
			return entries[a]["speed"] > entries[b]["speed"]
		return a < b
	)
	var queue: Array = []
	for i in order:
		queue.append(entries[i])

	if cp["motionTurns"] > 0:
		var player_pos := 0
		for i in range(queue.size()):
			if queue[i]["type"] == "player":
				player_pos = i
				break
		var attack_count: int = 3 if cp["motionPower"] >= 3 else 2
		for _n in range(attack_count - 1):
			queue.insert(player_pos + 1, { "type": "player", "extra": true })

	return queue


# Starts a new round if one isn't already in progress: pushes the snapshot,
# resets stance-triggered flags, and commits every living enemy's action
# up front (see _commit_enemies()). A no-op if cp["_pending"] is already
# set; returns whether a fresh round was actually started, so the caller
# knows to follow up with _start_round_queue(cp) once any same-call item
# effect has been applied. Called before take_player_action()/use_item()/
# cast_dial_complication() spend anything real, so Rewind's "restores item
# stock, Dial charges" contract holds regardless of entry point.
static func _ensure_round_started(cp: Dictionary) -> bool:
	if cp.get("_pending") != null:
		return false
	push_prototype_snapshot()
	cp["player"]["stanceTriggered"] = false
	for enemy in cp["enemies"]:
		enemy["stanceTriggered"] = false
	_commit_enemies(cp)
	return true


# Builds and installs the round's queue. Split out from
# _ensure_round_started() so an item entry point can apply its own effect
# (which may set cp["motionTurns"]/cp["motionPower"]) BEFORE the queue is
# built, letting that round's own cast insert its extra slot(s)
# immediately. Only called when _ensure_round_started() just returned true.
static func _start_round_queue(cp: Dictionary) -> void:
	cp["_pending"] = { "queue": _build_queue(cp), "pos": 0, "beats": [] }


# The shared round engine behind take_player_action()/use_item()/
# cast_dial_complication(), called after _ensure_round_started() has
# guaranteed cp["_pending"] exists. `action` is one of COMMITTABLE_ACTIONS
# or ACTION_ITEM; for ACTION_ITEM the effect has already been applied by
# the caller, and `pre_beats` carries whatever it already logged. The
# action/target/item given resolves the first not-yet-resolved player
# queue entry the walk reaches; every player entry reached after that
# either auto-skips (already exhausted) or pauses for the next commit.
static func _advance_round(cp: Dictionary, action: String, target_index: int, item_id, pre_beats: Array = []) -> Dictionary:
	var player: Dictionary = cp["player"]
	var pending: Dictionary = cp["_pending"]
	var beats: Array = pending["beats"]
	beats.append_array(pre_beats)
	var action_consumed := false

	while cp["outcome"] == null and pending["pos"] < pending["queue"].size():
		var entry: Dictionary = pending["queue"][pending["pos"]]
		if entry["type"] == "enemy":
			_resolve_enemy_entry(cp, entry["idx"], beats)
			pending["pos"] += 1
			continue

		# entry["type"] == "player"
		if not action_consumed:
			player["committedAction"] = action
			player["committedTarget"] = target_index if target_index >= 0 else null
			player["committedItem"] = item_id
			_resolve_player_entry(cp, beats, action, target_index)
			action_consumed = true
			pending["pos"] += 1
			continue

		if player["exhaustedNextTurn"]:
			player["exhaustedNextTurn"] = false
			_log(cp, beats, "You're exhausted — catching your breath.", "exhausted", { "actorType": "player" })
			pending["pos"] += 1
			continue

		EventBus.state_changed.emit()
		return { "ok": true, "needsPlayerAction": true, "beats": beats }

	return _finalize_round(cp, beats)


static func _resolve_player_entry(cp: Dictionary, beats: Array, action: String, target_index: int) -> void:
	match action:
		ACTION_FLEE:
			_resolve_flee(cp, beats)
		ACTION_ITEM:
			pass  # effect already applied before this call (see _apply_item_effect())
		ACTION_FAST, ACTION_HEAVY:
			_resolve_player_attack(cp, beats, action, target_index)
		ACTION_COUNTER, ACTION_DODGE:
			pass  # a stance resolves reactively, when the targeted enemy's own turn comes up


static func _resolve_player_attack(cp: Dictionary, beats: Array, action: String, target_index: int) -> void:
	var enemies: Array = cp["enemies"]
	if target_index < 0 or target_index >= enemies.size() or enemies[target_index]["koed"]:
		_log(cp, beats, "Your target's already down — the swing never lands.", "interrupted", { "actorType": "player" })
		return
	var enemy: Dictionary = enemies[target_index]

	if action == ACTION_HEAVY:
		cp["player"]["exhaustedNextTurn"] = true

	var atk_range: Dictionary = _attack_range_for(cp, true, action, -1)
	var dmg: int = Rng.randi_range(atk_range["min"], atk_range["max"])
	var stance = enemy["committedAction"]  # the player is the only attacker an enemy can ever defend against here

	if stance == ACTION_COUNTER:
		enemy["stanceTriggered"] = true
		if action == ACTION_FAST:
			_log(cp, beats, "Your Fast is stopped cold — %s counters." % enemy["name"], "counter_stop", { "actorType": "player" })
			var retal_range: Dictionary = _attack_range_for(cp, false, ACTION_FAST, target_index)
			var retal_dmg: int = Rng.randi_range(retal_range["min"], retal_range["max"])
			_deal_damage(cp, true, -1, retal_dmg, "%s hits back for %d." % [enemy["name"], retal_dmg], "counter_retaliate", false, target_index, beats)
		else:
			_deal_damage(cp, false, target_index, dmg, "Your Heavy barrels through %s's Counter — %d damage." % [enemy["name"], dmg], "heavy_bypass", true, -1, beats)
		return

	if stance == ACTION_DODGE:
		enemy["stanceTriggered"] = true
		if action == ACTION_HEAVY:
			_log(cp, beats, "%s dodges your Heavy — no damage, but the swing leaves you winded." % enemy["name"], "heavy_dodged", { "actorType": "player" })
		else:
			_deal_damage(cp, false, target_index, dmg, "%s can't dodge your Fast — %d damage." % [enemy["name"], dmg], "fast_catches_dodge", true, -1, beats)
		return

	_deal_damage(cp, false, target_index, dmg, "Your %s connects for %d." % [action.capitalize(), dmg], action + "_hit", true, -1, beats)


# Commit phase: every living enemy not currently exhausted reveals its
# scripted action now, before any resolution this round runs -- a slower
# enemy's Counter/Dodge has to already be visible the instant an earlier
# queue entry needs to check it. An exhausted enemy commits nothing. Frozen
# is deliberately NOT checked here: it's resolved at each enemy's own
# queue turn instead (see _resolve_enemy_entry()).
static func _commit_enemies(cp: Dictionary) -> void:
	var wave_defs: Array = _current_wave_defs(cp)
	var enemies: Array = cp["enemies"]
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		if enemy["koed"]:
			continue
		if enemy["exhaustedNextTurn"]:
			enemy["committedAction"] = null
			continue
		var script: Array = wave_defs[i]["script"]
		var chosen: String = script[enemy["scriptIndex"] % script.size()]
		enemy["scriptIndex"] += 1
		enemy["committedAction"] = chosen


# One living enemy's own queue turn, executing whatever _commit_enemies()
# already revealed for it. Frozen is checked and resolved FIRST every
# time, leaving exhaustedNextTurn untouched until frozenTurns stops
# gating this enemy's turn. A committed stance has nothing to execute
# here -- it resolves reactively, from whichever attack targets it.
static func _resolve_enemy_entry(cp: Dictionary, enemy_idx: int, beats: Array) -> void:
	var enemy: Dictionary = cp["enemies"][enemy_idx]
	if enemy["koed"]:
		return

	if cp["frozenTurns"] > 0:
		cp["frozenTurns"] -= 1
		_log(cp, beats, "%s is frozen — no turn." % enemy["name"], "frozen", { "actorType": "enemy", "actorIndex": enemy_idx })
		return

	var chosen = enemy["committedAction"]
	if chosen == null:
		enemy["exhaustedNextTurn"] = false
		_log(cp, beats, "%s is exhausted — catching their breath." % enemy["name"], "exhausted", { "actorType": "enemy", "actorIndex": enemy_idx })
		return

	if ACTIONS_STANCE.has(chosen):
		return

	if chosen == ACTION_HEAVY:
		enemy["exhaustedNextTurn"] = true

	var atk_range: Dictionary = _attack_range_for(cp, false, chosen, enemy_idx)
	var dmg: int = Rng.randi_range(atk_range["min"], atk_range["max"])
	var player: Dictionary = cp["player"]
	var player_stance = player["committedAction"]
	# A stance covers only its one selected opponent; other attackers
	# remain fully dangerous.
	var stance_aimed_here: bool = player["committedTarget"] == enemy_idx

	if player_stance == ACTION_COUNTER and stance_aimed_here:
		player["stanceTriggered"] = true
		if chosen == ACTION_FAST:
			_log(cp, beats, "%s's Fast is stopped cold — you counter." % enemy["name"], "counter_stop", { "actorType": "enemy", "actorIndex": enemy_idx })
			var retal_range: Dictionary = _attack_range_for(cp, true, ACTION_FAST, -1)
			var retal_dmg: int = Rng.randi_range(retal_range["min"], retal_range["max"])
			_deal_damage(cp, false, enemy_idx, retal_dmg, "You hit back for %d." % retal_dmg, "counter_retaliate", true, -1, beats)
		else:
			_deal_damage(cp, true, -1, dmg, "%s's Heavy barrels through your Counter — %d damage." % [enemy["name"], dmg], "heavy_bypass", false, enemy_idx, beats)
		return

	if player_stance == ACTION_DODGE and stance_aimed_here:
		player["stanceTriggered"] = true
		if chosen == ACTION_HEAVY:
			_log(cp, beats, "You dodge %s's Heavy — no damage, but they're left winded." % enemy["name"], "heavy_dodged", { "actorType": "enemy", "actorIndex": enemy_idx })
		else:
			_deal_damage(cp, true, -1, dmg, "You can't dodge %s's Fast — %d damage." % [enemy["name"], dmg], "fast_catches_dodge", false, enemy_idx, beats)
		return

	_deal_damage(cp, true, -1, dmg, "%s's %s connects for %d." % [enemy["name"], chosen.capitalize(), dmg], chosen + "_hit", false, enemy_idx, beats)


static func _resolve_flee(cp: Dictionary, beats: Array) -> void:
	var chance: float = FLEE_CHANCE
	if cp.get("blastFleeBoost", false):
		chance = BLAST_FLEE_BOOST_CHANCE
		cp["blastFleeBoost"] = false
	if Rng.chance(chance):
		cp["outcome"] = "fled"
		_log(cp, beats, "You back off. Fight's over.", "flee_success", {})
	else:
		_log(cp, beats, "You try to leg it — no clean break.", "flee_failed", {})


# Shared HP-application chokepoint -- every damage instance in this file
# funnels through here. target/actor are (is_player, enemy_idx) pairs
# rather than a single "defender" reference, since retaliation targets the
# original attacker. Also owns shield absorption and the enemy-koed ->
# maybe-wave-cleared check.
static func _deal_damage(cp: Dictionary, target_is_player: bool, target_idx: int, dmg: int, line: String, kind: String, actor_is_player: bool, actor_idx: int, beats: Array) -> void:
	var target: Dictionary = cp["player"] if target_is_player else cp["enemies"][target_idx]
	var extra: Dictionary = {
		"actorType": "player" if actor_is_player else "enemy",
		"targetType": "player" if target_is_player else "enemy",
	}
	if not actor_is_player:
		extra["actorIndex"] = actor_idx
	if not target_is_player:
		extra["targetIndex"] = target_idx

	if Rng.chance(target.get("evadeChance", 0.0)):
		var evade_line: String = "You slip out of the way — no damage." if target_is_player else "%s slips out of the way — no damage." % target["name"]
		_log(cp, beats, evade_line, "evaded", extra)
		return

	var applied: int = dmg
	var shield_note := ""
	if target_is_player and target["shieldPool"] > 0:
		var absorbed: int = mini(applied, target["shieldPool"])
		target["shieldPool"] -= absorbed
		applied -= absorbed
		if absorbed > 0:
			shield_note = " (%d absorbed by shield)" % absorbed

	target["hp"] = maxi(0, target["hp"] - applied)
	var hp_readout: String = "You: %d/%d HP." % [target["hp"], target["hpMax"]] if target_is_player else "%s: %d/%d HP." % [target["name"], target["hp"], target["hpMax"]]
	extra["dmg"] = applied
	_log(cp, beats, "%s%s %s" % [line, shield_note, hp_readout], kind, extra)

	if target["hp"] <= 0:
		if target_is_player:
			cp["outcome"] = "loss"
			_log(cp, beats, "You go down.", "loss", {})
		else:
			target["koed"] = true
			_maybe_wave_cleared(cp)


static func _maybe_wave_cleared(cp: Dictionary) -> void:
	for enemy in cp["enemies"]:
		if not enemy["koed"]:
			return
	cp["_waveCleared"] = true


# A stance aimed at an opponent who doesn't attack the defender that round
# fizzles with no effect -- the action is still spent. Skipped once the
# fight's already resolved this round.
static func _log_unused_stances(cp: Dictionary, beats: Array) -> void:
	var player: Dictionary = cp["player"]
	var player_action = player["committedAction"]
	if player_action != null and ACTIONS_STANCE.has(player_action) and not player["stanceTriggered"]:
		_log(cp, beats, "Your stance goes unused — the action's still spent.", "stance_fizzle", { "actorType": "player" })
	var enemies: Array = cp["enemies"]
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		var enemy_action = enemy["committedAction"]
		if enemy_action != null and ACTIONS_STANCE.has(enemy_action) and not enemy["stanceTriggered"]:
			_log(cp, beats, "%s's stance goes unused — the action's still spent." % enemy["name"], "stance_fizzle", { "actorType": "enemy", "actorIndex": i })


# Ends the round: unused-stance fizzles, wave-clear/win resolution, commit
# reset, Motion decay, round increment. The only place a wave transition
# can happen (only for a def with `waves`, cp.totalWaves > 1); every
# squad/solo encounter's win resolves immediately here.
static func _finalize_round(cp: Dictionary, beats: Array) -> Dictionary:
	if cp["outcome"] == null:
		_log_unused_stances(cp, beats)
		if cp.get("_waveCleared", false):
			cp["_waveCleared"] = false
			if cp["wave"] + 1 < cp["totalWaves"]:
				cp["wave"] += 1
				cp["enemies"] = _current_wave_defs(cp).map(_build_enemy_state)
				_log(cp, beats, "That's one wave down. Next one's already moving in.", "wave_incoming", {})
			else:
				cp["outcome"] = "win"
				_log(cp, beats, "They're all down. Fight's over.", "win", {})

	var player: Dictionary = cp["player"]
	player["committedAction"] = null
	player["committedTarget"] = null
	player["committedItem"] = null
	for enemy in cp["enemies"]:
		enemy["committedAction"] = null

	if cp["motionTurns"] > 0:
		cp["motionTurns"] -= 1
		if cp["motionTurns"] == 0:
			_log(cp, beats, "The powder wears off. Back to normal speed.", "motion_end", {})

	cp["round"] += 1
	cp["_pending"] = null
	EventBus.state_changed.emit()
	return { "ok": true, "outcome": cp["outcome"], "beats": beats }


static func _log(cp: Dictionary, beats: Array, line: String, kind: String, extra: Dictionary) -> void:
	cp["log"].append(line)
	var beat: Dictionary = { "kind": kind, "logLine": line }
	beat.merge(extra)
	beats.append(beat)
	cp["beatsSinceSnapshot"].append(beat)


# ── Snapshot / Rewind ─────────────────────────────────────────────────────

# Rewind restores item stock, HP, Dial charges, and all other combat state
# to the snapshot. Captures the real player's inventory buckets for every
# ITEM_RECIPE_KEYS entry (tier-exact) and the real Dial's currentCharge --
# pushed once per round, before that round's first action, so Rewind can
# undo a spent item exactly as it undoes damage.
static func push_prototype_snapshot() -> void:
	var cp: Dictionary = GameState.state["combatPrototype"]
	var player_state: Dictionary = GameState.state["player"]

	var inventory_snapshot: Dictionary = {}
	for key in ITEM_RECIPE_KEYS:
		inventory_snapshot[key] = player_state["inventory"].get(key, {})
	var dial_charge = player_state["dial"]["currentCharge"] if player_state["dial"] != null else null

	var enemies_snapshot: Array = []
	for enemy in cp["enemies"]:
		enemies_snapshot.append({
			"hp": enemy["hp"], "committedAction": enemy["committedAction"],
			"exhaustedNextTurn": enemy["exhaustedNextTurn"], "scriptIndex": enemy["scriptIndex"],
			"koed": enemy["koed"],
		})

	var snap := {
		"round": cp["round"], "wave": cp["wave"], "log": cp["log"].duplicate(),
		"frozenTurns": cp["frozenTurns"], "motionTurns": cp["motionTurns"], "motionPower": cp["motionPower"],
		"player": {
			"hp": cp["player"]["hp"], "committedAction": cp["player"]["committedAction"],
			"committedTarget": cp["player"]["committedTarget"], "exhaustedNextTurn": cp["player"]["exhaustedNextTurn"],
			"shieldPool": cp["player"]["shieldPool"],
		},
		"enemies": enemies_snapshot,
		"inventorySnapshot": inventory_snapshot,
		"dialCharge": dial_charge,
	}
	Snapshots.push("combatPrototype", cp["snapshots"], snap)


# Freely available in this prototype (no consumable/Dial gating) -- the
# point here is proving restoration is reliable, not resource scarcity.
# Bounded only by whether a snapshot exists (2-deep stack, same as
# production). Safe mid-round, since the snapshot predates this round.
static func rewind() -> Dictionary:
	var cp: Dictionary = GameState.state["combatPrototype"]
	if not cp["active"] or cp["snapshots"].is_empty():
		return { "ok": false, "reason": "Nothing to rewind." }

	var replay_beats: Array = cp["beatsSinceSnapshot"].duplicate()
	replay_beats.reverse()

	var snap: Dictionary = Snapshots.oldest(cp["snapshots"])
	Snapshots.clear(cp["snapshots"])

	cp["round"] = snap["round"]
	cp["wave"] = snap["wave"]
	cp["frozenTurns"] = snap["frozenTurns"]
	cp["motionTurns"] = snap["motionTurns"]
	cp["motionPower"] = snap["motionPower"]
	var new_log: Array = snap["log"].duplicate()
	new_log.append("⟲ Rewind. The last exchange never happened.")
	cp["log"] = new_log

	var player: Dictionary = cp["player"]
	player["hp"] = snap["player"]["hp"]
	player["committedAction"] = snap["player"]["committedAction"]
	player["committedTarget"] = snap["player"]["committedTarget"]
	player["committedItem"] = null
	player["exhaustedNextTurn"] = snap["player"]["exhaustedNextTurn"]
	player["shieldPool"] = snap["player"]["shieldPool"]
	player["stanceTriggered"] = false

	var wave_defs: Array = _current_wave_defs(cp)
	var rebuilt: Array = []
	var enemies_snapshot: Array = snap["enemies"]
	for i in range(enemies_snapshot.size()):
		var enemy: Dictionary = _build_enemy_state(wave_defs[i])
		var s: Dictionary = enemies_snapshot[i]
		enemy["hp"] = s["hp"]
		enemy["committedAction"] = s["committedAction"]
		enemy["exhaustedNextTurn"] = s["exhaustedNextTurn"]
		enemy["scriptIndex"] = s["scriptIndex"]
		enemy["koed"] = s["koed"]
		rebuilt.append(enemy)
	cp["enemies"] = rebuilt

	var player_state: Dictionary = GameState.state["player"]
	var inventory_snapshot: Dictionary = snap["inventorySnapshot"]
	for key in ITEM_RECIPE_KEYS:
		player_state["inventory"][key] = inventory_snapshot[key]
	if player_state["dial"] != null and snap["dialCharge"] != null:
		player_state["dial"]["currentCharge"] = snap["dialCharge"]

	cp["outcome"] = null
	cp["_waveCleared"] = false
	cp["_pending"] = null
	cp["beatsSinceSnapshot"] = []

	EventBus.state_changed.emit()
	return { "ok": true, "beats": replay_beats }


# Tears the prototype fight down and returns to the Debug app (see
# scenes/phone_apps/debug_app.gd's "Solo Combat Prototype" card) rather than any
# production combat exit routing.
static func exit_encounter() -> Dictionary:
	GameState.state["combatPrototype"]["active"] = false
	Nav.go_to("phone")
	return { "ok": true }
