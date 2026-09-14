class_name CombatPrototype
extends RefCounted

# day-rhythm-business-and-combat ticket 14 (rules: ticket 13a, superseded/
# extended by ticket 15's squad+item contracts, resolved via ticket 14b's
# grilling session): a bounded, throwaway combat experiment testing the
# four-action Fast/Heavy/Counter/Dodge matchup grid, committed-intent
# resolution, exhaustion, real calc-effect items and Rewind reliability --
# NOT production combat. Deliberately isolated from systems/combat.gd and
# GameState.state["combat"]: its own state lives in
# GameState.state["combatPrototype"], its own snapshot stack ("combatPrototype"
# in Snapshots.MAX_SIZES), its own screen (scenes/screens/combat_prototype.gd).
# Nothing here mutates production combat state or the real player's hp --
# GameState.state["player"]["hp"] is never touched (the prototype keeps its
# own hp field, seeded fresh from the real player's hpMax). Item use IS
# real, though (ticket 15's own "no synthetic pool" resolution): Crafting.
# inventory_remove()/Dial.cast_complication() spend from the player's actual
# stock/Dial charge, restored on Rewind (see push_prototype_snapshot()/
# rewind()'s own comments) but NOT by exiting/losing a fight otherwise.
#
# ── Squad/wave shape (ticket 15) ────────────────────────────────────────
# cp.enemies is always an Array now (solo == a one-element array) -- see
# _current_wave_defs()/_build_enemy_state(). cp.wave/cp.totalWaves track a
# multi-wave encounter's progress; a non-wave encounter is just totalWaves
# == 1. The player's Fast/Heavy/Counter/Dodge/Blast all take an explicit
# enemy-index target now (auto-resolved to "the sole living enemy" for a
# solo fight via _resolve_target(), so every pre-ticket-15 solo call site
# that omits target_index keeps working unchanged).
#
# ── Round engine (ticket 15) ────────────────────────────────────────────
# A round is no longer always one call. Enhancement Powder's existing
# extra-queue-turn (§3.7a, reused per 13a scenario 9) means a round can
# need up to 3 separate player commits when Motion is active (2 at
# motionPower < 3, 3 at >= 3, mirroring Combat.build_turn_queue()'s own
# attack_count). cp["_pending"] (null between rounds) holds the in-progress
# round's queue/cursor/beats while it's mid-resolution; a call that reaches
# a player queue slot needing fresh input returns {needsPlayerAction: true}
# instead of finishing the round -- the caller (screen) calls
# take_player_action()/use_item()/cast_dial_complication() again for that
# slot, which resumes rather than starting over. See _advance_round()'s own
# comment for the full walk. Ticket 14b's resolved "Enhancement Powder vs.
# exhaustion" rule (a Heavy committed on a Motion round's first slot skips
# the *second, same-round* slot, not next round's) falls out of this
# design for free: the walk-loop's exhausted-check runs on every player
# entry it reaches, including an inserted one, before it would otherwise
# ask for input.
#
# ── Frozen (ticket 15) ──────────────────────────────────────────────────
# cp["frozenTurns"] is a single shared pool (mirrors Combat's own
# combat.frozenTurns exactly, per ticket 15's "Blast/Black Hole in squad
# fights: exercised as-is, unchanged from production") -- decremented once
# per living enemy's own queue turn while > 0, gating that one enemy's
# turn. Ticket 14b's "Freeze + exhaustion overlap" amendment (the two now
# stack as two separate skipped turns) falls out of resolving frozen
# strictly before exhaustion at each enemy's own turn, and never clearing
# exhaustedNextTurn on a frozen skip -- see _resolve_enemy_entry().
#
# ── Scope NOT covered (documented per the ticket's own instruction) ─────
#  - Grab/Bolt/Call: ticket 15's own checklist gates these behind "their
#    prototype contracts are explicit" -- no such resolution exists yet (no
#    ticket 14b-equivalent grilling session for them), so they are not
#    wired here. Recommendation: a dedicated contract ticket, same shape as
#    14b, before any future prototype work touches them.
#  - Prophet's Breath and Wormhole: real combat items in production, but
#    absent from ticket 14b's own enumerated "Approved rule" item list
#    (Time Pearl, Shield, Blast, Black Hole, Healing Burst, Healing Salve) --
#    treated the same as an unresolved contract, not wired.
#  - Healing Salve: 14b confirms it keeps its production out-of-combat-only
#    restriction, so it's simply never offered as a committable action here.
#  - Blast's disarm chance still rolls (for parity with production's
#    formula) but has no mechanical effect in this prototype -- these
#    enemies carry no weapon/ability fields to strip (that machinery is
#    real-combat-only; wiring a prototype-only stand-in was judged out of
#    scope for this ticket's own budget).
#  - Allies: still absent, same as ticket 14. Every squad/wave roster here
#    is player-solo vs. N enemies, never player+ally vs. N enemies.

const ACTION_FAST := "fast"
const ACTION_HEAVY := "heavy"
const ACTION_COUNTER := "counter"
const ACTION_DODGE := "dodge"
const ACTION_FLEE := "flee"
const ACTION_ITEM := "item"

# The four combat actions a script entry (data/combat_prototype.json) may
# name -- also what GameData._validate_combat_prototype() checks scripts
# against. Flee/Item are deliberately excluded: no scripted enemy in this
# roster ever flees or uses an item.
const SCRIPTABLE_ACTIONS: Array[String] = [ACTION_FAST, ACTION_HEAVY, ACTION_COUNTER, ACTION_DODGE]
const ACTIONS_STANCE: Array[String] = [ACTION_COUNTER, ACTION_DODGE]
const COMMITTABLE_ACTIONS: Array[String] = [ACTION_FAST, ACTION_HEAVY, ACTION_COUNTER, ACTION_DODGE, ACTION_FLEE]

# Ticket 15's 14b-approved item roster -- the only calc effects this
# prototype ever wires (see this file's own top comment for what's
# deliberately excluded and why).
const ITEM_RECIPE_KEYS: Array[String] = ["timePearl", "enhancementPowder", "shield", "blast", "blackHole", "healingBurst"]

const ITEM_ZERO_STOCK_REASON := {
	"timePearl": "No time pearls.", "enhancementPowder": "No enhancement powder.",
	"shield": "No shield.", "blast": "No blast.", "blackHole": "No black hole.",
	"healingBurst": "No healing burst.",
}

# Ticket 13a's approved rule: "Heavy = Fast range x 1.5 (min and max),
# rounded via GameState.round_epsilon(). Prototype-only multiplier, not
# balance-final."
const HEAVY_MULTIPLIER := 1.5

# Ticket 13a: "Item use ... and Flee each consume the actor's one committed
# action for the round, exactly as today". Reuses systems/combat.gd's own
# flee()/use_blast() base chance and boost (no weapon/disarm mechanic
# exists in this prototype -- see this file's top comment).
const FLEE_CHANCE := 0.65
const BLAST_FLEE_BOOST_CHANCE := 0.90
const BLAST_DISARM_CHANCE := 0.15


# ── Encounter setup ──────────────────────────────────────────────────────

# Fresh full-hp start for `encounter_id` (must be a key in
# GameData.COMBAT_PROTOTYPE.encounters). The prototype's own player.hp/hpMax
# is seeded from the real player's hpMax but is NOT the same field -- every
# resolution function below only ever reads or writes cp["player"]["hp"],
# never GameState.state["player"]["hp"], so a prototype fight can never leak
# damage (or a death) into the real save. Fast's own damage range still
# comes from the real player via Combat.get_attack_range() (ticket 13a:
# "today's baseline attack range ... unchanged"), a pure query.
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
# sequence only (ticket 15's squad/wave encounters live outside this order,
# see list_launchable_encounters() below). Returns { ok:false } with no
# state change past the last encounter.
static func advance_to_next_encounter() -> Dictionary:
	var order: Array = GameData.COMBAT_PROTOTYPE.get("encounterOrder", [])
	var current: String = GameState.state["combatPrototype"]["encounterId"]
	var idx: int = order.find(current)
	if idx == -1 or idx + 1 >= order.size():
		return { "ok": false, "reason": "No further encounter." }
	return start_encounter(order[idx + 1])


# Ticket 15: every encounters.<id> NOT in the fixed teaching order --
# squad/wave/other evaluation encounters, reached directly rather than via
# advance_to_next_encounter(). The Debug app's card (scenes/screens/phone.gd)
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


# The current wave's roster of raw JSON enemy defs (name/hp/attackMin/
# attackMax/speed/evadeChance/script) -- a flat teaching-order entry (no
# "enemies"/"waves" key) wraps itself as a one-element roster, so solo
# encounters go through exactly the same path as a squad/wave one.
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
# living enemy" (every pre-ticket-15 solo call site keeps working
# unchanged) and refuses (-1) when a squad has more than one still standing
# -- there's no correct default to guess in that case.
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

	_ensure_round_started(cp)
	return _advance_round(cp, action, resolved_target, null)


# Called by the screen instead of take_player_action() when
# cp.player.exhaustedNextTurn is true at the START of a round -- there's no
# action to pick, the round auto-resolves as "no commit, no action" for the
# player (every enemy turn still happens) per ticket 13a ("Available
# actions while exhausted: none"). Not valid mid-round (an already-paused
# extra Motion slot auto-skips on its own inside _advance_round() instead --
# see that func's own comment).
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


# ── Items (ticket 15, 14b's resolved item contracts) ─────────────────────

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
# exactly as production combat.gd does today (ticket 15's "real inventory,
# no synthetic pool" resolution).
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
	# reflects this item as spent (see _ensure_round_started()'s own
	# comment). A no-op if this call is filling an already-open Motion
	# extra slot instead of starting a fresh round.
	_ensure_round_started(cp)

	Crafting.inventory_remove(item_id, 1)
	var skill: int = GameState.state["player"]["craftingSkill"]
	var power = Crafting.effect_power(item_id, skill)
	var pre_beats: Array = []
	_apply_item_effect(cp, item_id, power, 1, resolved_target, pre_beats)

	return _advance_round(cp, ACTION_ITEM, resolved_target, item_id, pre_beats)


# Dial-cast entry point (Dial.cast_complication(), including its per-dial
# power/target multiplier) -- ticket 15's "both entry points in scope".
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
	_ensure_round_started(cp)

	var cast: Dictionary = Dial.cast_complication(dial_index)
	if not cast["ok"]:
		return cast

	var pre_beats: Array = []
	_apply_item_effect(cp, recipe_key, cast["power"], cast["targets"], resolved_target, pre_beats)

	return _advance_round(cp, ACTION_ITEM, resolved_target, recipe_key, pre_beats)


# Applies one item's effect immediately (production's own use_*()/
# cast_complication() branches are all immediate free actions too -- there's
# no reactive "wait and see" an item's effect needs, unlike a Fast/Heavy
# matchup). `targets` is the Dial's per-tier Spread Movement multiplier
# (always 1 for the direct-bag path) -- folded in exactly like production's
# cast_complication() does per recipe, including enhancementPowder's
# deliberate exception (motionPower/motionTurns read `power` directly, not
# multiplied by targets, matching that same branch in Combat.
# cast_complication()).
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
				# See this file's top comment: disarm has no weapon/ability to
				# strip here, so this is a logged-only flourish, not a mechanic.
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
# player-first-then-enemy-array-order -- same convention as
# Combat.build_turn_queue() (R§3.7a). While cp.motionTurns > 0 (Enhancement
# Powder active), (attack_count - 1) extra player entries are spliced in
# immediately after the player's own base slot -- mirrors
# Combat.build_turn_queue()'s own Motion-insertion exactly, just inserting
# "a player entry awaiting a fresh commit" instead of "a bonus attack".
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


# Starts a new round if one isn't already in progress: pushes the
# snapshot, resets stance-triggered flags, commits every living enemy's
# action for the round (ticket 13a's "commit phase, before resolution
# phase" -- see _commit_enemies()'s own comment for why this has to happen
# up front rather than lazily), and builds the queue. A no-op if
# cp["_pending"] is already set (this call is filling an already-open
# Motion extra slot, not starting a fresh round).
#
# Called from take_player_action()/use_item()/cast_dial_complication()
# BEFORE any of them spend anything real (Crafting.inventory_remove(),
# Dial.cast_complication()) -- ticket 15's resolved Rewind contract
# ("restores item stock ... Dial charges") only holds if the snapshot is
# taken before the spend, not after; pushing it here, ahead of the
# item-specific guards/spend in use_item()/cast_dial_complication(), is
# what guarantees that ordering regardless of which entry point started
# the round.
static func _ensure_round_started(cp: Dictionary) -> void:
	if cp.get("_pending") != null:
		return
	push_prototype_snapshot()
	cp["player"]["stanceTriggered"] = false
	for enemy in cp["enemies"]:
		enemy["stanceTriggered"] = false
	_commit_enemies(cp)
	cp["_pending"] = { "queue": _build_queue(cp), "pos": 0, "beats": [] }


# The shared round engine behind take_player_action()/use_item()/
# cast_dial_complication(), called after _ensure_round_started() has
# guaranteed cp["_pending"] exists. `action` is one of COMMITTABLE_ACTIONS
# or ACTION_ITEM; for ACTION_ITEM the effect has already been applied by
# the caller (items are immediate, see _apply_item_effect()'s own comment)
# -- `pre_beats` carries whatever it already logged so this call's
# returned beats include it.
#
# The action/target/item this call was given resolves the very first
# not-yet-resolved player queue entry the walk reaches (`action_consumed`,
# scoped to this one call) -- every player entry reached AFTER that in the
# same call either auto-skips (already exhausted -- this is where ticket
# 14b's "Enhancement Powder + Heavy exhaustion" rule falls out for free,
# same-round) or pauses again asking for the next commit.
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
	var stance = enemy["committedAction"]  # this enemy's own stance is always "aimed at the player" -- the player is the only attacker an enemy can ever defend against here

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


# Ticket 13a's "commit phase": every living enemy not currently exhausted
# reveals its scripted action NOW, before any resolution this round runs --
# a slower enemy's Counter/Dodge (or a faster one's Fast/Heavy) has to be
# already visible in state the instant an earlier queue entry (the player's
# own slot, or another enemy) needs to check it, regardless of THIS
# enemy's own queue position. An exhausted enemy commits nothing (13a:
# "Frozen/exhausted combatants auto-skip and are shown as such -- no
# commit") -- script pick/advance only ever happens on a real commit,
# matching ticket 14's "an exhausted skip round doesn't consume a step".
# Frozen is deliberately NOT checked here: it's a live, resolution-order-
# dependent pool (see _resolve_enemy_entry() below), so it can only be
# resolved at each enemy's own queue turn, not decided up front.
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
# already revealed for it. Ticket 14b's frozen/exhaustion ordering: frozen
# is checked and resolved FIRST every time this enemy's turn comes up,
# decrementing the shared pool and leaving exhaustedNextTurn exactly as it
# was (pending, untouched) -- only once frozenTurns has stopped gating this
# enemy's turn does a pending exhaustedNextTurn (signalled by a null
# committedAction -- see _commit_enemies()) actually consume a turn. A
# committed stance (Counter/Dodge) has nothing to execute here at all --
# same as the player's own stance commits, it resolves reactively, from
# whichever attack targets this enemy.
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
	# Ticket 13a: "A stance covers only its one selected opponent; other
	# attackers remain fully dangerous." -- an unguarded enemy (or one the
	# player's stance isn't currently pointed at) connects normally, which
	# is exactly ticket 15 checklist item 1's demonstration.
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
# (a plain hit, a bypassing Heavy, Fast catching a Dodge, a Counter's own
# retaliation, or an item) funnels through here. Ticket 13a: "evadeChance
# rolls apply after the matchup resolves, before HP loss -- unchanged order
# from today." target/actor are (is_player, enemy_idx) pairs rather than a
# single "defender" reference, since retaliation's target is the original
# ATTACKER, not whoever just defended. Also owns shield absorption
# (player-only) and the enemy-koed -> maybe-wave-cleared check.
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


# Ticket 13a: "A stance ... aimed at an opponent who doesn't attack the
# defender that round ... fizzles with no effect -- the action is still
# spent." Skipped once the fight's already resolved this round.
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
# reset, Motion decay, round increment. Ticket 15's "do not turn routine
# encounters into waves" -- this is the ONLY place a wave transition can
# happen, and it only fires for an encounter def that actually has
# `waves` (cp.totalWaves > 1); every squad/solo encounter's win resolves
# immediately here exactly as before.
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

# Ticket 15's resolved Rewind contract: "restores item stock, HP, Dial
# charges, and all other combat state to the snapshot -- except the Rewind
# consumable/Dial-charge itself" (there is no rewind item wired into this
# prototype at all, so that carve-out is moot here -- everything captured
# below is restorable). Captures the real player's inventory buckets for
# every ITEM_RECIPE_KEYS entry (tier-exact, not just an aggregate qty) and
# the real Dial's currentCharge, alongside cp's own combat state -- pushed
# once per round, BEFORE that round's first action (including an item cast)
# is applied, so Rewind can undo a spent item exactly as it undoes damage.
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


# Freely available in this prototype (no consumable/Dial gating like
# production's combat_rewind()) -- the point here is proving restoration is
# reliable, not resource scarcity. Bounded only by whether a snapshot
# exists (2-deep stack, same as production). Safe to call mid-round (while
# cp["_pending"] is non-null, i.e. an Enhancement-Powder-inserted slot is
# still awaiting its own commit) -- the snapshot was taken before ANY of
# this round's actions, so it unwinds the whole round, pending slot
# included.
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


# Tears the prototype fight down and returns to whichever screen launched
# it (the Debug app -- see scenes/screens/phone.gd's own "Solo Combat
# Prototype" card) rather than any production combat exit routing.
static func exit_encounter() -> Dictionary:
	GameState.state["combatPrototype"]["active"] = false
	Nav.go_to("phone")
	return { "ok": true }
