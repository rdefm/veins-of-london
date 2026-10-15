class_name CombatPrototype
extends RefCounted

# Sandboxed Open/Guarded round-planning combat prototype
# (.scratch/combat-revamp/spec.md). Own state at
# GameState.state["combatPrototype"], own Rewind stack, own screen
# (scenes/screens/combat_prototype.gd); never reads or writes the real
# player, inventory, Dial, XP or calendar. Live combat (Combat) is separate.
#
# A fight is start(config), then resolve_round(plan) once per round.
# Combatants live in one array, the player at index 0, then allies, then
# enemies, so array order is the timeline's last tie-break (spec §Timeline
# order). Each enemy holds this round's committed plan and next round's
# pre-rolled one; each ally holds this round's plan, planned by the ally AI
# from the enemies' plans; the player's draft plan is playerPlan, edited with
# set_plan_action().
# Randomness runs off the fight's own RNG state (rngState), so a Rewind
# replays the same rolls for the same plan.

const SIDE_PLAYER := "player"
const SIDE_ALLY := "ally"
const SIDE_ENEMY := "enemy"

const GUARDED := "guarded"
const OPEN := "open"
const UNCHANGED := "unchanged"
const GUARD_EFFECTS: Array[String] = [GUARDED, OPEN, UNCHANGED]

const TARGET_SELF := "self"
const TARGET_ENEMY := "enemy"
const TARGET_TYPES: Array[String] = [TARGET_SELF, TARGET_ENEMY]
# Item-only target types: every living opponent at once, or the actor or a
# living teammate.
const TARGET_ALL_ENEMIES := "allEnemies"
const TARGET_FRIEND := "friend"
const ITEM_TARGET_TYPES: Array[String] = [TARGET_SELF, TARGET_ENEMY, TARGET_ALL_ENEMIES, TARGET_FRIEND]

const EFFECT_NONE := "none"
const EFFECT_DAMAGE := "damage"
const EFFECT_OPEN := "open"
const EFFECT_STUN := "stun"
const EFFECT_LURE := "lure"
const EFFECT_FLEE := "flee"
const EFFECTS: Array[String] = [EFFECT_NONE, EFFECT_DAMAGE, EFFECT_OPEN, EFFECT_STUN, EFFECT_LURE, EFFECT_FLEE]

# Item effects (spec §Prototype item effects), keyed from the data's items
# table; each reads its power from the recipe's effectPower at the slot's tier.
const ITEM_FREEZE := "freeze"
const ITEM_BLACK_HOLE := "blackHole"
const ITEM_BLAST := "blast"
const ITEM_SHIELD := "shield"
const ITEM_HEAL := "heal"
const ITEM_POWDER := "powder"
const ITEM_SIGHT := "sight"
const ITEM_LADY := "lady"
const ITEM_EFFECTS: Array[String] = [ITEM_FREEZE, ITEM_BLACK_HOLE, ITEM_BLAST, ITEM_SHIELD, ITEM_HEAL, ITEM_POWDER, ITEM_SIGHT, ITEM_LADY]
# Loadout slots per combatant (spec user story 48).
const LOADOUT_SLOTS := 2

# Move conditions: null (always) or CONDITION_TARGET_OPEN (fizzles on a
# Guarded target).
const CONDITION_TARGET_OPEN := "targetOpen"
const CONDITIONS: Array[String] = [CONDITION_TARGET_OPEN]

# A combatant's "lure" field: none, waiting for a bite, or caught one and
# spent (the rest of its positions hold the actor Open).
const LURE_NONE := ""
const LURE_ACTIVE := "active"
const LURE_SPRUNG := "sprung"

const PLAYER_INDEX := 0
const DEFAULT_ARCHETYPE := "mugger"
# Squad cap (spec user story 5: 0-2 AI allies).
const MAX_ALLIES := 2

# The moves the ally AI plans with (spec §Ally AI); GameData checks they exist.
const MOVE_GUARD := "guard"
const MOVE_STRIKE := "strike"
const MOVE_FEINT := "feint"
const ALLY_AI_MOVES: Array[String] = [MOVE_GUARD, MOVE_STRIKE, MOVE_FEINT]


static func _data() -> Dictionary:
	return GameData.COMBAT_PROTOTYPE


static func _root() -> Dictionary:
	return GameState.state["combatPrototype"]


static func new_state() -> Dictionary:
	return {
		"active": false,
		"round": 0,
		# null while the fight runs, then "win", "loss" or "fled".
		"outcome": null,
		# Player at PLAYER_INDEX, then enemies; see _build_combatant().
		"combatants": [],
		# The player's draft for this round: one entry per action, each
		# null (unfilled) or { move, target, part }. A move costing n actions
		# fills n positions in a row, parts 0..n-1.
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


# A move's row, or for a prototype item's recipe id a move-shaped row built
# from the items table: one action, guard state unchanged, named after the
# recipe. {} for neither.
static func move(move_id: String) -> Dictionary:
	if _data()["moves"].has(move_id):
		return _data()["moves"][move_id]
	if not _data()["items"].has(move_id):
		return {}
	var item: Dictionary = _data()["items"][move_id]
	return {
		"id": move_id, "name": GameData.RECIPES[move_id]["name"], "cost": 1,
		"actorGuard": UNCHANGED, "target": item["target"], "effect": item["effect"],
		"params": item["params"], "condition": null, "item": true,
	}


static func is_item(move_id: String) -> bool:
	return _data()["items"].has(move_id)


# The prototype items, by recipe id, for the setup picker.
static func item_ids() -> Array:
	return _data()["items"].keys()


# Highest tier an item's recipe has an effectPower for.
static func item_tier_max(item_id: String) -> int:
	return GameData.RECIPES[item_id]["effectPower"].size() - 1


static func actions_per_round(combatant: Dictionary) -> int:
	return int(_data()["actionsPerRound"][combatant["level"]])


# Actions `actor` gets this round: its level's count, +1 while an
# Enhancement Powder runs (one Powder or two, never more than +1).
static func actions_this_round(cp: Dictionary, actor: int) -> int:
	var combatant: Dictionary = cp["combatants"][actor]
	return actions_per_round(combatant) + (1 if is_powered(cp, combatant) else 0)


static func is_powered(cp: Dictionary, combatant: Dictionary) -> bool:
	return int(cp["round"]) <= int(combatant["powderUntil"])


static func has_lady(cp: Dictionary, combatant: Dictionary) -> bool:
	return int(cp["round"]) <= int(combatant["ladyUntil"])


# Whether the player has Prophet's Breath sight this round.
static func has_sight(cp: Dictionary) -> bool:
	return int(cp["round"]) <= int(cp["combatants"][PLAYER_INDEX]["sightUntil"])


# The attacker's damage roll range: its attack range, or its max both ends
# under Be a Lady.
static func damage_range(cp: Dictionary, actor: int) -> Array:
	var combatant: Dictionary = cp["combatants"][actor]
	if has_lady(cp, combatant):
		return [combatant["attackMax"], combatant["attackMax"]]
	return [combatant["attackMin"], combatant["attackMax"]]


static func display_name(combatant: Dictionary) -> String:
	if combatant["side"] == SIDE_PLAYER:
		return "You"
	var name: String = combatant["name"]
	return name[0].to_upper() + name.substr(1)


# ── Setup ────────────────────────────────────────────────────────────────

# config: playerLevel (1..levelMax, default 1); enemies, an Array of
# { archetype, level } (default one level-1 mugger); allies, an Array of
# { level } (0..MAX_ALLIES, default none); loadout, the player's sandbox
# items, an Array of up to LOADOUT_SLOTS { item, tier } (item a prototype
# item's recipe id; default none); seed (default fresh);
# enemyPlans / allyPlans, test-only: per combatant an Array of rounds, each
# an Array of move ids or { move, target } entries, used in place of the
# archetype's patterns or the ally AI (round n reads entry (n-1) mod size).
# Everyone starts Guarded. Returns the new fight state, or {} for an unknown
# archetype, too many allies or a bad loadout.
static func start(config: Dictionary = {}) -> Dictionary:
	var archetypes: Dictionary = _data()["archetypes"]
	var enemy_specs: Array = config.get("enemies", [{ "archetype": DEFAULT_ARCHETYPE, "level": 1 }])
	for spec in enemy_specs:
		if not archetypes.has(spec.get("archetype", "")):
			return {}
	var ally_specs: Array = config.get("allies", [])
	if ally_specs.size() > MAX_ALLIES:
		return {}
	var loadout = _build_loadout(config.get("loadout", []))
	if loadout == null:
		return {}

	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get("seed", Rng.fresh_seed()))

	var cp := new_state()
	cp["active"] = true
	cp["round"] = 1
	var combatants: Array = cp["combatants"]
	var player := _build_combatant(SIDE_PLAYER, _data()["playerBase"], int(config.get("playerLevel", 1)))
	player["loadout"] = loadout
	combatants.append(player)
	var ally_overrides: Array = config.get("allyPlans", [])
	for i in range(ally_specs.size()):
		var ally := _build_combatant(SIDE_ALLY, _data()["allyBase"], int(ally_specs[i].get("level", 1)))
		if ally_specs.size() > 1:
			ally["name"] = "%s %s" % [ally["name"], char(65 + i)]
		ally["planOverride"] = ally_overrides[i] if i < ally_overrides.size() else null
		combatants.append(ally)
	var overrides: Array = config.get("enemyPlans", [])
	var archetype_counts: Dictionary = {}
	for spec in enemy_specs:
		archetype_counts[spec["archetype"]] = archetype_counts.get(spec["archetype"], 0) + 1
	var archetype_seen: Dictionary = {}
	for i in range(enemy_specs.size()):
		var spec: Dictionary = enemy_specs[i]
		var enemy := _build_combatant(SIDE_ENEMY, archetypes[spec["archetype"]], int(spec.get("level", 1)))
		enemy["archetype"] = spec["archetype"]
		# Two of a kind get lettered: "the mugger A", "the mugger B".
		if archetype_counts[spec["archetype"]] > 1:
			var nth: int = archetype_seen.get(spec["archetype"], 0)
			archetype_seen[spec["archetype"]] = nth + 1
			enemy["name"] = "%s %s" % [enemy["name"], char(65 + nth)]
		enemy["planOverride"] = overrides[i] if i < overrides.size() else null
		combatants.append(enemy)

	for i in range(combatants.size()):
		if combatants[i]["side"] == SIDE_ENEMY:
			combatants[i]["plan"] = _roll_plan(cp, i, 1, rng)
			combatants[i]["nextPlan"] = _roll_plan(cp, i, 2, rng)
	_plan_allies(cp, rng)
	cp["playerPlan"] = _empty_player_plan(cp)
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
		# Counts as Open through the end of this round number, whatever its
		# own guard state (Exposed, spec §Vocabulary).
		"exposedUntil": 0,
		# Upcoming actions to drop from the timeline (Stun, Time Pearl, Black
		# Hole).
		"actionsLost": 0,
		# How many of those are a Time Pearl's freeze, which holds it Open.
		"frozenActions": 0,
		# Absorb pool; while above 0 it counts as Guarded (Shield).
		"shield": 0,
		"lure": LURE_NONE,
		# The running Lure's params.exposedRounds.
		"lureExposedRounds": 0,
		# Timed item effects, each running through the end of this round
		# number: Enhancement Powder's +1 action, Be a Lady's max rolls (at
		# ladyCrit crit chance) and Prophet's Breath sight.
		"powderUntil": 0,
		"ladyUntil": 0,
		"ladyCrit": 0.0,
		"sightUntil": 0,
		# Sandbox items: { item, tier, power, used } per slot.
		"loadout": [],
		"plan": [], "nextPlan": [],
	}


# Slots from config entries { item, tier }, power read from the recipe's
# effectPower at that tier; null for too many slots, an unknown item or an
# out-of-range tier.
static func _build_loadout(entries: Array) -> Variant:
	if entries.size() > LOADOUT_SLOTS:
		return null
	var slots: Array = []
	for entry in entries:
		var item_id: String = str(entry.get("item", ""))
		var tier: int = int(entry.get("tier", 1))
		if not is_item(item_id) or tier < 1 or tier > item_tier_max(item_id):
			return null
		slots.append({ "item": item_id, "tier": tier, "power": int(GameData.RECIPES[item_id]["effectPower"][tier]), "used": false })
	return slots


static func _empty_player_plan(cp: Dictionary) -> Array:
	var plan: Array = []
	plan.resize(actions_this_round(cp, PLAYER_INDEX))
	return plan


# An enemy's committed plan for round `round_no`: a weighted archetype
# pattern (or the test override), cycled to fill its actions per round,
# with a target per offensive action.
static func _roll_plan(cp: Dictionary, actor: int, round_no: int, rng: RandomNumberGenerator) -> Array:
	var combatant: Dictionary = cp["combatants"][actor]
	if _has_override(combatant):
		return _override_plan(cp, actor, round_no, rng)
	var moves: Array = _pick_pattern(_data()["archetypes"][combatant["archetype"]]["patterns"], rng)["moves"]
	return _plan_from(cp, actor, moves, rng)


static func _has_override(combatant: Dictionary) -> bool:
	var override = combatant.get("planOverride")
	return override != null and not override.is_empty()


static func _override_plan(cp: Dictionary, actor: int, round_no: int, rng: RandomNumberGenerator) -> Array:
	var override: Array = cp["combatants"][actor]["planOverride"]
	return _plan_from(cp, actor, override[(round_no - 1) % override.size()], rng)


# `moves` cycled to the actor's actions per round; each entry a move id
# (target picked) or { move, target }.
static func _plan_from(cp: Dictionary, actor: int, moves: Array, rng: RandomNumberGenerator) -> Array:
	var plan: Array = []
	for i in range(actions_per_round(cp["combatants"][actor])):
		var entry = moves[i % moves.size()]
		if entry is Dictionary:
			plan.append({ "move": entry["move"], "target": int(entry["target"]), "part": 0 })
		else:
			plan.append({ "move": entry, "target": _pick_target(cp, actor, entry, rng), "part": 0 })
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
# the actor's living opponents (for an enemy, the player and living allies).
static func _pick_target(cp: Dictionary, actor: int, move_id: String, rng: RandomNumberGenerator) -> int:
	if move(move_id)["target"] == TARGET_SELF:
		return actor
	var opponents := _living_opponents(cp, actor)
	if opponents.is_empty():
		return -1
	if opponents.size() == 1:
		return opponents[0]
	return opponents[rng.randi_range(0, opponents.size() - 1)]


# A pre-rolled plan as it's committed: any offensive action aimed at a
# combatant KO'd since the roll picks again among the living.
static func _recommit_targets(cp: Dictionary, actor: int, plan: Array, rng: RandomNumberGenerator) -> Array:
	var combatants: Array = cp["combatants"]
	for action in plan:
		var target := int(action["target"])
		if target >= 0 and target != actor and combatants[target]["koed"]:
			action["target"] = _pick_target(cp, actor, action["move"], rng)
	return plan


static func _living_opponents(cp: Dictionary, actor: int) -> Array:
	var combatants: Array = cp["combatants"]
	var enemy_side: bool = combatants[actor]["side"] == SIDE_ENEMY
	var result: Array = []
	for i in range(combatants.size()):
		if (combatants[i]["side"] == SIDE_ENEMY) != enemy_side and not combatants[i]["koed"]:
			result.append(i)
	return result


# ── Ally AI ──────────────────────────────────────────────────────────────

# Plans every living ally's round from the enemies' committed plans (spec
# §Ally AI), per action: Guard where an enemy strikes it; else Strike an
# enemy who'll be Open when it acts; else, with an action to follow, Feint a
# Guarded enemy the Feint leaves Open for that next action's Strike; else
# Guard. Allies plan in array order, each reading the earlier ones' Feints.
# An ally with a test override plays that instead.
static func _plan_allies(cp: Dictionary, rng: RandomNumberGenerator) -> void:
	var combatants: Array = cp["combatants"]
	# { actor, index, target } per Feint planned so far this round.
	var feints: Array = []
	for i in range(combatants.size()):
		var ally: Dictionary = combatants[i]
		if ally["side"] != SIDE_ALLY:
			continue
		if ally["koed"]:
			ally["plan"] = []
		elif _has_override(ally):
			ally["plan"] = _override_plan(cp, i, cp["round"], rng)
		else:
			var plan: Array = []
			var count := actions_per_round(ally)
			for a in range(count):
				var action := _ally_action(cp, i, a, count, feints)
				if action["move"] == MOVE_FEINT:
					feints.append({ "actor": i, "index": a, "target": action["target"] })
				plan.append(action)
			ally["plan"] = plan


static func _ally_action(cp: Dictionary, ally: int, index: int, count: int, feints: Array) -> Dictionary:
	var combatants: Array = cp["combatants"]
	var enemies := _living_opponents(cp, ally)
	for e in enemies:
		var plan: Array = combatants[e]["plan"]
		if index < plan.size() and int(plan[index]["target"]) == ally and move(plan[index]["move"])["effect"] in [EFFECT_DAMAGE, EFFECT_STUN]:
			return { "move": MOVE_GUARD, "target": ally, "part": 0 }
	for e in enemies:
		if _ally_sees_open(cp, e, ally, index, feints):
			return { "move": MOVE_STRIKE, "target": e, "part": 0 }
	if index + 1 < count:
		for e in enemies:
			var with_feint: Array = feints + [{ "actor": ally, "index": index, "target": e }]
			if not _ally_sees_open(cp, e, ally, index + 1, feints) and _ally_sees_open(cp, e, ally, index + 1, with_feint):
				return { "move": MOVE_FEINT, "target": e, "part": 0 }
	return { "move": MOVE_GUARD, "target": ally, "part": 0 }


# Whether enemy `e` will be Open when `observer` takes its action `index`,
# replaying the enemy's committed guard changes and `feints` on it in
# timeline order up to that moment. Exposed counts as Open.
static func _ally_sees_open(cp: Dictionary, e: int, observer: int, index: int, feints: Array) -> bool:
	var enemy: Dictionary = cp["combatants"][e]
	if is_exposed(cp, enemy):
		return true
	var events: Array = []
	var plan: Array = enemy["plan"]
	for i in range(mini(plan.size(), index + 1)):
		var effect: String = move(plan[i]["move"])["actorGuard"]
		if effect != UNCHANGED:
			events.append({ "actor": e, "index": i, "guard": effect })
	for f in feints:
		if f["target"] == e:
			events.append({ "actor": f["actor"], "index": f["index"], "guard": OPEN })
	events = events.filter(func(ev): return _acts_before(cp, ev["actor"], ev["index"], observer, index))
	events.sort_custom(func(x, y): return _acts_before(cp, x["actor"], x["index"], y["actor"], y["index"]))
	var state: String = enemy["guard"]
	for ev in events:
		state = ev["guard"]
	return state == OPEN


# ── Planning ─────────────────────────────────────────────────────────────

static func move_cost(move_id: String) -> int:
	return int(move(move_id).get("cost", 1))


# Fills the player's draft from `position` with `move_id`, taking as many
# positions as the move costs; any multi-action move it overlaps is cleared
# whole. target -1 picks the first living enemy for an offensive move.
static func set_plan_action(position: int, move_id: String, target: int = -1) -> Dictionary:
	return _set_plan_entry(position, { "move": move_id, "target": target })


# Fills the player's draft at `position` with the item in loadout `slot`;
# target -1 picks the default (first living enemy, or the player for a heal).
static func set_plan_item(position: int, slot: int, target: int = -1) -> Dictionary:
	return _set_plan_entry(position, { "slot": slot, "target": target })


static func _set_plan_entry(position: int, action: Dictionary) -> Dictionary:
	var cp := _root()
	if not cp["active"] or cp["outcome"] != null:
		return { "ok": false, "reason": "No fight on." }
	var plan: Array = cp["playerPlan"]
	if position < 0 or position >= plan.size():
		return { "ok": false, "reason": "No such action." }
	var entry = _normalize_action(cp, action)
	var reason := _action_block_reason(cp, entry)
	if reason != "":
		return { "ok": false, "reason": reason }
	var move_id: String = entry["move"]
	reason = _powder_position_reason(cp, position, entry)
	if reason != "":
		return { "ok": false, "reason": reason }
	var cost := move_cost(move_id)
	if position + cost > plan.size():
		return { "ok": false, "reason": _span_reason(move_id) }
	for pos in range(position, position + cost):
		_clear_span(plan, pos)
	# An item goes once: picking its slot here moves it from anywhere else.
	if entry.has("slot"):
		for pos in range(plan.size()):
			if plan[pos] != null and int(plan[pos].get("slot", -1)) == int(entry["slot"]):
				plan[pos] = null
	for part in range(cost):
		var filled: Dictionary = entry.duplicate()
		filled["part"] = part
		plan[position + part] = filled
	_fit_player_plan(cp)
	EventBus.state_changed.emit()
	return { "ok": true }


# Clears the draft action at `position` (all of it, for a multi-action move).
static func clear_plan_action(position: int) -> Dictionary:
	var cp := _root()
	if not cp["active"] or cp["outcome"] != null:
		return { "ok": false, "reason": "No fight on." }
	if position < 0 or position >= cp["playerPlan"].size():
		return { "ok": false, "reason": "No such action." }
	_clear_span(cp["playerPlan"], position)
	_fit_player_plan(cp)
	EventBus.state_changed.emit()
	return { "ok": true }


# How many positions the player's `plan` takes this round: actions this
# round, plus the extra position an Enhancement Powder in the plan opens at
# the end (unless one's already running).
static func player_plan_size(cp: Dictionary, plan: Array) -> int:
	var size := actions_this_round(cp, PLAYER_INDEX)
	if is_powered(cp, cp["combatants"][PLAYER_INDEX]):
		return size
	for action in plan:
		if action != null and _is_powder(action["move"]):
			return size + 1
	return size


static func _is_powder(move_id: String) -> bool:
	return move(move_id).get("effect", "") == ITEM_POWDER


# A Powder can't sit in the extra position it opens itself.
static func _powder_position_reason(cp: Dictionary, position: int, action: Dictionary) -> String:
	if _is_powder(action["move"]) and position >= actions_this_round(cp, PLAYER_INDEX):
		return "Powder goes in one of your usual actions."
	return ""


# Grows or trims the draft to player_plan_size(): placing a Powder opens the
# extra position, removing it closes the position and drops what was in it.
static func _fit_player_plan(cp: Dictionary) -> void:
	var plan: Array = cp["playerPlan"]
	var size := player_plan_size(cp, plan)
	for pos in range(size, plan.size()):
		_clear_span(plan, pos)
	plan.resize(size)


static func _clear_span(plan: Array, position: int) -> void:
	var action = plan[position]
	if action == null:
		return
	var start: int = position - int(action.get("part", 0))
	for pos in range(maxi(0, start), mini(plan.size(), start + move_cost(action["move"]))):
		plan[pos] = null


static func _span_reason(move_id: String) -> String:
	return "%s takes %d actions in a row." % [move(move_id)["name"], move_cost(move_id)]


# A player action as { move, target } (plus slot for an item): an item
# action named by its loadout slot takes the slot's item as its move; a
# self-targeted one aims at the player, an all-enemies one at nobody (-1),
# and an unset target (-1) at the first of target_options().
static func _normalize_action(cp: Dictionary, action) -> Variant:
	if action == null:
		return null
	var move_id: String = str(action.get("move", ""))
	var target: int = int(action.get("target", -1))
	var slot: int = int(action.get("slot", -1))
	if action.has("slot"):
		var loadout: Array = cp["combatants"][PLAYER_INDEX]["loadout"]
		move_id = loadout[slot]["item"] if slot >= 0 and slot < loadout.size() else ""
	var m := move(move_id)
	if not m.is_empty():
		var options := target_options(cp, PLAYER_INDEX, move_id)
		if m["target"] == TARGET_SELF:
			target = PLAYER_INDEX
		elif m["target"] == TARGET_ALL_ENEMIES:
			target = -1
		elif target < 0:
			target = options[0] if not options.is_empty() else -1
	var result := { "move": move_id, "target": target }
	if action.has("slot"):
		result["slot"] = slot
	return result


# Who `actor` may aim `move_id` at: itself (self), each living opponent
# (enemy), itself then each living teammate (friend); [] for an
# all-enemies action, which needs no pick.
static func target_options(cp: Dictionary, actor: int, move_id: String) -> Array:
	match move(move_id).get("target", ""):
		TARGET_SELF:
			return [actor]
		TARGET_ENEMY:
			return _living_opponents(cp, actor)
		TARGET_FRIEND:
			var combatants: Array = cp["combatants"]
			var enemy_side: bool = combatants[actor]["side"] == SIDE_ENEMY
			var result: Array = [actor]
			for i in range(combatants.size()):
				if i != actor and (combatants[i]["side"] == SIDE_ENEMY) == enemy_side and not combatants[i]["koed"]:
					result.append(i)
			return result
	return []


# Normalizes each action, then numbers the parts of multi-action moves: n
# positions in a row holding the same move form one action, parts 0..n-1.
# A run that's too short is left with part -1 (see _action_block_reason).
static func _normalize_plan(cp: Dictionary, plan: Array) -> Array:
	var result: Array = plan.map(func(action): return _normalize_action(cp, action))
	var i := 0
	while i < result.size():
		var action = result[i]
		if action == null or move(action["move"]).is_empty():
			i += 1
			continue
		var cost := move_cost(action["move"])
		var run := 1
		while run < cost and i + run < result.size() and result[i + run] != null and result[i + run]["move"] == action["move"]:
			run += 1
		for part in range(run):
			result[i + part]["part"] = part if run == cost else -1
		i += run
	return result


static func _action_block_reason(cp: Dictionary, action) -> String:
	if action == null:
		return "Fill every action."
	var m := move(action["move"])
	if m.is_empty():
		return "Unknown move."
	if int(action.get("part", 0)) < 0:
		return _span_reason(action["move"])
	if m.get("item", false):
		if not action.has("slot"):
			return "Items come out of your loadout."
		if cp["combatants"][PLAYER_INDEX]["loadout"][action["slot"]]["used"]:
			return "That one's spent."
	if m["target"] in [TARGET_ENEMY, TARGET_FRIEND] and not target_options(cp, PLAYER_INDEX, action["move"]).has(action["target"]):
		return "Pick a target."
	return ""


# Why `plan` can't be committed this round, or "" if it can.
static func plan_block_reason(cp: Dictionary, plan: Array) -> String:
	if plan.size() != player_plan_size(cp, plan):
		return "Fill every action."
	var slots: Dictionary = {}
	for pos in range(plan.size()):
		var action = plan[pos]
		var reason := _action_block_reason(cp, action)
		if reason == "":
			reason = _powder_position_reason(cp, pos, action)
		if reason != "":
			return reason
		if action.has("slot"):
			if slots.has(action["slot"]):
				return "Each item goes once a fight."
			slots[action["slot"]] = true
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
	entries.sort_custom(func(x, y): return _acts_before(cp, x["actor"], x["index"], y["actor"], y["index"]))
	return entries


# Timeline order: action index, then speed descending, then combatant order.
static func _acts_before(cp: Dictionary, actor_a: int, index_a: int, actor_b: int, index_b: int) -> bool:
	if index_a != index_b:
		return index_a < index_b
	var speed_a: int = cp["combatants"][actor_a]["speed"]
	var speed_b: int = cp["combatants"][actor_b]["speed"]
	if speed_a != speed_b:
		return speed_a > speed_b
	return actor_a < actor_b


static func _plan_of(cp: Dictionary, actor: int) -> Array:
	return cp["playerPlan"] if actor == PLAYER_INDEX else cp["combatants"][actor]["plan"]


# What the player can read of enemy `actor`'s plan for this round, or with
# next_round its pre-rolled plan for the round after. Each entry is
# { move, name }; under Prophet's Breath sight it adds target and, for a
# damage move, dmgMin/dmgMax (the roll range before guard and crit). Without
# sight next round reads as [] (spec user stories 12-13).
static func enemy_intents(cp: Dictionary, actor: int, next_round: bool = false) -> Array:
	var sight := has_sight(cp)
	if next_round and not sight:
		return []
	var result: Array = []
	for action in cp["combatants"][actor]["nextPlan" if next_round else "plan"]:
		var m := move(action["move"])
		var intent := { "move": action["move"], "name": m["name"] }
		if sight:
			intent["target"] = int(action["target"])
			if m["effect"] == EFFECT_DAMAGE:
				var roll_range := damage_range(cp, actor)
				intent["dmgMin"] = roll_range[0]
				intent["dmgMax"] = roll_range[1]
		result.append(intent)
	return result


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

# Commits the player's plan (Array of { move, target }, or { slot, target }
# for a loadout item; target may be omitted for auto-targeting) against the enemies' committed plans and
# resolves the round in timeline() order. A KO'd combatant's remaining
# actions are dropped, as are a Leg it's actor's later ones and any lost
# to a Stun, Time Pearl or Black Hole; the fight stops the moment it's won, lost or fled.
# Returns { ok, beats, outcome }; on a fight still running, next round's
# plans move up and the round after's are rolled.
static func resolve_round(plan: Array) -> Dictionary:
	var cp := _root()
	if not cp["active"] or cp["outcome"] != null:
		return { "ok": false, "reason": "No fight on." }
	var normalized := _normalize_plan(cp, plan)
	var reason := plan_block_reason(cp, normalized)
	if reason != "":
		return { "ok": false, "reason": reason }

	cp["playerPlan"] = normalized
	_push_snapshot(cp)

	var rng := RandomNumberGenerator.new()
	rng.state = cp["rngState"]
	var beats: Array = []
	var combatants: Array = cp["combatants"]
	# Actors whose remaining actions this round are gone (Leg it).
	var done: Dictionary = {}
	for entry in timeline(cp):
		if cp["outcome"] != null:
			break
		var actor: int = entry["actor"]
		var combatant: Dictionary = combatants[actor]
		if combatant["koed"] or done.has(actor):
			continue
		# A Powder's extra position only plays once the Powder has resolved.
		if entry["index"] >= actions_this_round(cp, actor):
			continue
		var action: Dictionary = _plan_of(cp, actor)[entry["index"]]
		if combatant["actionsLost"] > 0:
			combatant["actionsLost"] -= 1
			var frozen: bool = combatant["frozenActions"] > 0
			combatant["frozenActions"] = maxi(0, combatant["frozenActions"] - 1)
			_beat(cp, beats, "frozen" if frozen else "lost", actor, -1, action["move"], {})
			continue
		_resolve_action(cp, actor, action, rng, beats)
		if move(action["move"])["effect"] == EFFECT_FLEE:
			done[actor] = true
	cp["log"].append_array(beats)

	if cp["outcome"] == null:
		cp["round"] += 1
		for i in range(combatants.size()):
			combatants[i]["lure"] = LURE_NONE
			if combatants[i]["side"] == SIDE_ENEMY:
				combatants[i]["plan"] = _recommit_targets(cp, i, combatants[i]["nextPlan"], rng)
				combatants[i]["nextPlan"] = [] if combatants[i]["koed"] else _roll_plan(cp, i, cp["round"] + 1, rng)
		_plan_allies(cp, rng)
		cp["playerPlan"] = _empty_player_plan(cp)
	cp["rngState"] = rng.state

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats, "outcome": cp["outcome"] }


# Applies the move's effect, then its effect on the actor's guard state. A
# Lure ends when its actor next acts on anything but its own later parts.
static func _resolve_action(cp: Dictionary, actor_idx: int, action: Dictionary, rng: RandomNumberGenerator, beats: Array) -> void:
	var m := move(action["move"])
	var move_id: String = action["move"]
	var actor: Dictionary = cp["combatants"][actor_idx]
	var first_beat := beats.size()
	var continuing_lure: bool = m["effect"] == EFFECT_LURE and int(action.get("part", 0)) > 0
	if not continuing_lure:
		actor["lure"] = LURE_NONE
	var apply_guard := true
	match m["effect"]:
		EFFECT_DAMAGE:
			var target := _retarget(cp, actor_idx, int(action["target"]))
			if target >= 0:
				_strike(cp, actor_idx, target, move_id, rng, beats)
		EFFECT_OPEN:
			var target := _retarget(cp, actor_idx, int(action["target"]))
			if target >= 0:
				_feint(cp, actor_idx, target, move_id, beats)
		EFFECT_STUN:
			var target := _retarget(cp, actor_idx, int(action["target"]))
			if target >= 0:
				_stun(cp, actor_idx, target, move_id, m, beats)
		EFFECT_LURE:
			if not continuing_lure:
				actor["lure"] = LURE_ACTIVE
				actor["lureExposedRounds"] = int(m["params"]["exposedRounds"])
				_beat(cp, beats, "lure", actor_idx, -1, move_id, {})
			elif actor["lure"] == LURE_SPRUNG:
				# Spent: the actor stays Open for the rest of the Lure.
				apply_guard = false
		EFFECT_FLEE:
			if rng.randf() < float(m["params"]["chance"]):
				_beat(cp, beats, "fled", actor_idx, -1, move_id, {})
				if actor_idx == PLAYER_INDEX:
					cp["outcome"] = "fled"
			else:
				_beat(cp, beats, "fleeFailed", actor_idx, -1, move_id, {})
		EFFECT_NONE:
			_beat(cp, beats, move_id, actor_idx, -1, move_id, {})
		_:
			_use_item(cp, actor_idx, action, m, beats)
	if apply_guard and m["actorGuard"] != UNCHANGED and not actor["koed"]:
		actor["guard"] = m["actorGuard"]
	for i in range(first_beat, beats.size()):
		if beats[i]["actor"] == actor_idx:
			beats[i]["actorGuard"] = actor["guard"]


# Open for damage and conditions: frozen by a Time Pearl; else Guarded while
# a Shield pool lasts; else its own guard state is Open, or it's Exposed
# this round.
static func is_open(cp: Dictionary, combatant: Dictionary) -> bool:
	if combatant["frozenActions"] > 0:
		return true
	if combatant["shield"] > 0:
		return false
	return combatant["guard"] == OPEN or is_exposed(cp, combatant)


static func is_exposed(cp: Dictionary, combatant: Dictionary) -> bool:
	return int(cp["round"]) <= int(combatant["exposedUntil"])


# Guarded target → Open until its next Guard; no-op on one already Open.
static func _feint(cp: Dictionary, actor_idx: int, target_idx: int, move_id: String, beats: Array) -> void:
	var target: Dictionary = cp["combatants"][target_idx]
	if is_open(cp, target):
		_beat(cp, beats, "fizzle", actor_idx, target_idx, move_id, {})
		return
	target["guard"] = OPEN
	_beat(cp, beats, "feint", actor_idx, target_idx, move_id, {})


# Open target → loses its next params.actions actions (its guard state
# stays as it was); a Guarded target shrugs it off (spec §Stun and freeze
# removal). Either way it's an attack, so it can spring a Lure.
static func _stun(cp: Dictionary, actor_idx: int, target_idx: int, move_id: String, m: Dictionary, beats: Array) -> void:
	var target: Dictionary = cp["combatants"][target_idx]
	if m["condition"] == CONDITION_TARGET_OPEN and not is_open(cp, target):
		_beat(cp, beats, "fizzle", actor_idx, target_idx, move_id, {})
	else:
		target["actionsLost"] += int(m["params"]["actions"])
		_beat(cp, beats, "stun", actor_idx, target_idx, move_id, {})
	_spring_lure(cp, actor_idx, target_idx, move_id, beats)


# The first attack on an actively Luring target leaves the attacker Exposed
# (through the end of round + exposedRounds) and the lurer Open.
static func _spring_lure(cp: Dictionary, attacker_idx: int, target_idx: int, move_id: String, beats: Array) -> void:
	var combatants: Array = cp["combatants"]
	var target: Dictionary = combatants[target_idx]
	if target["lure"] != LURE_ACTIVE or target["koed"]:
		return
	target["lure"] = LURE_SPRUNG
	target["guard"] = OPEN
	combatants[attacker_idx]["exposedUntil"] = int(cp["round"]) + int(target["lureExposedRounds"])
	_beat(cp, beats, "exposed", target_idx, attacker_idx, move_id, {})


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


# Damage rolls within the attacker's range: full on an Open (or Exposed)
# target, round(roll × chipMultiplier) (min 1) on a Guarded one; a crit
# doubles the final figure (spec §Damage). Under Be a Lady the roll is the
# attacker's max and the crit chance its ladyCrit (spec §Crit chance).
static func _strike(cp: Dictionary, actor_idx: int, target_idx: int, move_id: String, rng: RandomNumberGenerator, beats: Array) -> void:
	var combatants: Array = cp["combatants"]
	var actor: Dictionary = combatants[actor_idx]
	var target: Dictionary = combatants[target_idx]
	var lady := has_lady(cp, actor)
	var roll_range := damage_range(cp, actor_idx)
	var roll := rng.randi_range(roll_range[0], roll_range[1])
	var guarded: bool = not is_open(cp, target)
	var dmg := roll
	if guarded:
		dmg = maxi(1, GameState.round_epsilon(roll * float(_data()["chipMultiplier"])))
	var crit_chance: float = float(actor["ladyCrit"]) if lady else float(_data()["critChance"][actor["level"]])
	var crit := rng.randf() < crit_chance
	if crit:
		dmg *= 2
	_deal_damage(cp, actor_idx, target_idx, dmg, "chip" if guarded else "hit", move_id, beats, {
		"roll": roll, "crit": crit, "guarded": guarded,
	})
	if not target["koed"]:
		_spring_lure(cp, actor_idx, target_idx, move_id, beats)


# `dmg` drains the target's Shield pool 1:1 before its HP (spec §Damage);
# beats `kind` with dmg, absorbed and hpAfter, then the KO if it drops.
static func _deal_damage(cp: Dictionary, actor_idx: int, target_idx: int, dmg: int, kind: String, move_id: String, beats: Array, extra: Dictionary) -> void:
	var target: Dictionary = cp["combatants"][target_idx]
	var absorbed: int = mini(target["shield"], dmg)
	target["shield"] -= absorbed
	target["hp"] = maxi(0, target["hp"] - (dmg - absorbed))
	var fields := { "dmg": dmg, "absorbed": absorbed, "hpAfter": target["hp"] }
	fields.merge(extra)
	_beat(cp, beats, kind, actor_idx, target_idx, move_id, fields)
	if target["hp"] == 0:
		target["koed"] = true
		_beat(cp, beats, "ko", actor_idx, target_idx, move_id, {})
		_check_outcome(cp)


# Applies an item's effect at `power` from the action's loadout slot, and
# spends the slot (spec §Prototype item effects). Item damage ignores guard.
static func _use_item(cp: Dictionary, actor_idx: int, action: Dictionary, m: Dictionary, beats: Array) -> void:
	var combatants: Array = cp["combatants"]
	var actor: Dictionary = combatants[actor_idx]
	var slot: Dictionary = actor["loadout"][int(action["slot"])]
	slot["used"] = true
	var power: int = slot["power"]
	var move_id: String = action["move"]
	match m["effect"]:
		ITEM_FREEZE:
			_beat(cp, beats, "timePearl", actor_idx, -1, move_id, {})
			for e in _living_opponents(cp, actor_idx):
				combatants[e]["actionsLost"] += power
				combatants[e]["frozenActions"] = combatants[e]["actionsLost"]
		ITEM_BLACK_HOLE:
			_beat(cp, beats, "blackHole", actor_idx, -1, move_id, {})
			var lost: int = int(m["params"]["actionsBase"]) + floori(power / float(m["params"]["powerPerAction"]))
			for e in _living_opponents(cp, actor_idx):
				_deal_damage(cp, actor_idx, e, power, "pull", move_id, beats, {})
				combatants[e]["actionsLost"] += lost
				if cp["outcome"] != null:
					return
		ITEM_BLAST:
			var target := _retarget(cp, actor_idx, int(action["target"]))
			if target >= 0:
				_deal_damage(cp, actor_idx, target, power, "blast", move_id, beats, {})
		ITEM_SHIELD:
			actor["shield"] = maxi(actor["shield"], power)
			_beat(cp, beats, "shield", actor_idx, -1, move_id, {})
		ITEM_HEAL:
			var target: int = int(action["target"])
			var patient: Dictionary = combatants[target]
			if patient["koed"]:
				_beat(cp, beats, "fizzle", actor_idx, target, move_id, {})
				return
			var healed: int = mini(power, patient["hpMax"] - patient["hp"])
			patient["hp"] += healed
			_beat(cp, beats, "healSelf" if target == actor_idx else "heal", actor_idx, target, move_id, { "amount": healed, "hpAfter": patient["hp"] })
		ITEM_POWDER:
			# +1 action from this round on: longRounds rounds at power >=
			# longPowerMin, else rounds. A second Powder extends, never stacks.
			var params: Dictionary = m["params"]
			var rounds: int = int(params["longRounds"]) if power >= int(params["longPowerMin"]) else int(params["rounds"])
			actor["powderUntil"] = maxi(actor["powderUntil"], int(cp["round"]) + rounds - 1)
			_beat(cp, beats, "powder", actor_idx, -1, move_id, {})
		ITEM_SIGHT:
			# Sight covers the `power` rounds after this one (planning them
			# reads their targets/damage and the round after's plans).
			actor["sightUntil"] = maxi(actor["sightUntil"], int(cp["round"]) + power)
			_beat(cp, beats, "sight", actor_idx, -1, move_id, {})
		ITEM_LADY:
			actor["ladyUntil"] = maxi(actor["ladyUntil"], int(cp["round"]) + power - 1)
			actor["ladyCrit"] = float(m["params"]["critChance"])
			_beat(cp, beats, "lady", actor_idx, -1, move_id, {})


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
		"amount": extra.get("amount", 0),
	})
	if extra.get("crit", false):
		text += lines["crit"]
	if extra.get("absorbed", 0) > 0:
		text += lines["absorb"].format({ "absorbed": extra["absorbed"] })
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
