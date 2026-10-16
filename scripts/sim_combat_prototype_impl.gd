extends RefCounted

# Body of scripts/sim_combat_prototype.gd (see there for usage). Drives the
# fight only through CombatPrototype.start() / choose_move() / choose_item(),
# a policy deciding at each pause, reading state through its read-only
# helpers; enemy plans are read as the player sees them (enemy_intents():
# targets only under Prophet's Breath sight, unread intents unknown).

const POLICIES := ["naive", "reader"]
const ROUND_CAP := 60
const FOG_MODES := { "both": [true, false], "on": [true], "off": [false] }
const DEFAULTS := {
	"n": "100", "seed": "1", "levels": "1,3,5", "elevels": "match",
	"archetypes": "mugger,bruiser,turtle", "counts": "1,2", "allies": "0",
	"loadouts": "none,blast+shield,prophetsBreath+beALady", "fog": "both",
}


func run(raw: Dictionary) -> void:
	var opts := DEFAULTS.duplicate()
	opts.merge(raw, true)
	for key in raw.keys():
		if not DEFAULTS.has(key) and not _override(key, raw[key]):
			return
	if not FOG_MODES.has(opts["fog"]):
		print("Unknown fog mode: %s (both, on or off)" % opts["fog"])
		return
	var overall := {}
	for fog in FOG_MODES[opts["fog"]]:
		overall[fog] = _run_table(opts, fog)
		print("")
	if overall.size() == 2:
		for policy in POLICIES:
			print("%-7s fog cost: overall win %5.1f%% with fog vs %5.1f%% without (%+.1f pts)" % [
				policy, overall[true][policy], overall[false][policy], overall[true][policy] - overall[false][policy]])


# One table over the grid with the fight's fog on or off; returns each
# policy's overall win %.
func _run_table(opts: Dictionary, fog: bool) -> Dictionary:
	var n := int(opts["n"])
	var base_seed := int(opts["seed"])
	var matchups := _grid(opts)
	print("Combat prototype sim: fog %s, n=%d seed=%d, %d matchups x %d policies" % ["on" if fog else "off", n, base_seed, matchups.size(), POLICIES.size()])
	print("%-4s %-16s %-3s %-30s %-7s %6s %4s %6s %8s %7s" % ["plv", "enemies", "al", "loadout", "policy", "rounds", "p90", "win%", "HP%win", "actions"])
	var totals := {}
	for policy in POLICIES:
		totals[policy] = { "wins": 0, "fights": 0, "better": 0 }
	for m in range(matchups.size()):
		var matchup: Dictionary = matchups[m]
		var win_pcts := {}
		for policy in POLICIES:
			var stats := _run_matchup(matchup, policy, n, base_seed, m, fog)
			win_pcts[policy] = stats["winPct"]
			totals[policy]["wins"] += stats["wins"]
			totals[policy]["fights"] += n
			print("%-4d %-16s %-3d %-30s %-7s %6.1f %4d %5.1f%% %7.1f%% %7.1f%s" % [
				matchup["playerLevel"], matchup["label"], matchup["allies"], matchup["loadoutLabel"], policy,
				stats["roundsMean"], stats["roundsP90"], stats["winPct"], stats["hpLeftPct"], stats["actionsMean"],
				"  (%d timed out)" % stats["timeouts"] if stats["timeouts"] > 0 else ""])
		if win_pcts["reader"] > win_pcts["naive"]:
			totals["reader"]["better"] += 1
		elif win_pcts["naive"] > win_pcts["reader"]:
			totals["naive"]["better"] += 1
	print("")
	var overall := {}
	for policy in POLICIES:
		var t: Dictionary = totals[policy]
		overall[policy] = 100.0 * t["wins"] / maxi(1, t["fights"])
		print("%-7s overall win %5.1f%%, higher win %% in %d of %d matchups" % [
			policy, overall[policy], t["better"], matchups.size()])
	return overall


# What-if override for this run only: a dotted path to an existing number
# in GameData.COMBAT_PROTOTYPE (e.g. archetypes.mugger.hpBase=45,
# chipMultiplier=0.3), set to `value` as that number's type. False (with
# the reason printed) for a path that isn't one.
func _override(path: String, value: String) -> bool:
	var keys := path.split(".")
	var node = GameData.COMBAT_PROTOTYPE
	for k in keys.slice(0, -1):
		node = node.get(k) if node is Dictionary else null
	var last: String = keys[-1]
	if not (node is Dictionary and node.has(last) and typeof(node[last]) in [TYPE_INT, TYPE_FLOAT]):
		print("Unknown option or not a number in combat_prototype.json: %s" % path)
		return false
	node[last] = float(value) if typeof(node[last]) == TYPE_FLOAT else int(value)
	return true


# One matchup per player level x enemy level x archetype x count x allies x
# loadout. elevels=match pits each player level against its own level.
func _grid(opts: Dictionary) -> Array:
	var levels := _ints(opts["levels"])
	var loadouts: Array = []
	for spec in str(opts["loadouts"]).split(","):
		loadouts.append({ "label": spec, "entries": _loadout(spec) })
	var matchups: Array = []
	for plv in levels:
		var elevels: Array = [plv] if opts["elevels"] == "match" else _ints(opts["elevels"])
		for elv in elevels:
			for archetype in str(opts["archetypes"]).split(","):
				for count in _ints(opts["counts"]):
					for allies in _ints(opts["allies"]):
						for loadout in loadouts:
							var enemies: Array = []
							for _i in range(count):
								enemies.append({ "archetype": archetype, "level": elv })
							matchups.append({
								"playerLevel": plv, "enemies": enemies, "allies": allies,
								"label": "%dx %s L%d" % [count, archetype, elv],
								"loadout": loadout["entries"], "loadoutLabel": loadout["label"],
							})
	return matchups


func _ints(csv: String) -> Array:
	return Array(csv.split(",")).map(func(v: String) -> int: return int(v))


# "none" or items joined by "+", each "item" (tier 1) or "item:tier".
func _loadout(spec: String) -> Array:
	if spec == "none":
		return []
	var entries: Array = []
	for part in spec.split("+"):
		var bits := part.split(":")
		entries.append({ "item": bits[0], "tier": int(bits[1]) if bits.size() > 1 else 1 })
	return entries


# Fight i of matchup m uses the same seed under every policy and fog mode,
# so they all meet the same opening plans.
func _run_matchup(matchup: Dictionary, policy: String, n: int, base_seed: int, m: int, fog: bool) -> Dictionary:
	var rounds: Array = []
	var wins := 0
	var timeouts := 0
	var hp_left := 0.0
	var actions := 0
	for i in range(n):
		var allies: Array = []
		for _a in range(matchup["allies"]):
			allies.append({ "level": matchup["playerLevel"] })
		var cp := CombatPrototype.start({
			"playerLevel": matchup["playerLevel"], "enemies": matchup["enemies"],
			"allies": allies, "loadout": matchup["loadout"], "fog": fog,
			"seed": base_seed * 1000003 + m * 10007 + i,
		})
		assert(not cp.is_empty(), "bad matchup config: %s" % matchup["label"])
		var outcome = cp["outcome"]
		var planned := 0
		while outcome == null and int(cp["round"]) <= ROUND_CAP:
			var action := _decide(cp, policy)
			planned += 1
			var result := CombatPrototype.choose_item(action["slot"], action["target"]) if action.has("slot") else CombatPrototype.choose_move(action["move"], action["target"])
			assert(result["ok"], "pick refused: %s" % result.get("reason", ""))
			outcome = result["outcome"]
			cp = GameState.state["combatPrototype"]
		rounds.append(int(cp["round"]))
		actions += planned
		if outcome == null:
			timeouts += 1
		elif outcome == "win":
			wins += 1
			var player: Dictionary = cp["combatants"][CombatPrototype.PLAYER_INDEX]
			hp_left += 100.0 * player["hp"] / player["hpMax"]
	rounds.sort()
	var total := 0
	for r in rounds:
		total += r
	return {
		"roundsMean": float(total) / n,
		"roundsP90": rounds[mini(n - 1, int(ceil(0.9 * n)) - 1)],
		"wins": wins, "winPct": 100.0 * wins / n,
		"hpLeftPct": hp_left / wins if wins > 0 else 0.0,
		"actionsMean": float(actions) / n, "timeouts": timeouts,
	}


# ── Policies ─────────────────────────────────────────────────────────────

# The pick at the paused position: at the round's first pick, at most one
# loadout item (same rule under both policies, so loadouts compare like for
# like); else the policy's move.
func _decide(cp: Dictionary, policy: String) -> Dictionary:
	if cp["playerPlan"].all(func(a): return a == null):
		var item := _item_action(cp)
		if not item.is_empty():
			return item
	if policy == "naive":
		return { "move": CombatPrototype.MOVE_STRIKE, "target": -1 }
	var i := CombatPrototype.decision_position(cp)
	return _reader_action(cp, i, CombatPrototype.actions_this_round(cp, CombatPrototype.PLAYER_INDEX))


# A heal below the ally AI's heal threshold; else the first unspent non-heal
# item, holding a Time Pearl or Black Hole while any enemy is still losing
# actions. {} for none.
func _item_action(cp: Dictionary) -> Dictionary:
	var player: Dictionary = cp["combatants"][CombatPrototype.PLAYER_INDEX]
	var loadout: Array = player["loadout"]
	var low: bool = float(player["hp"]) / player["hpMax"] < float(GameData.COMBAT_PROTOTYPE["allyHealBelow"])
	var paused: bool = _enemies(cp).any(func(e): return cp["combatants"][e]["actionsLost"] > 0)
	for slot in range(loadout.size()):
		if loadout[slot]["used"]:
			continue
		var item_id: String = loadout[slot]["item"]
		var effect: String = CombatPrototype.move(item_id)["effect"]
		if effect == CombatPrototype.ITEM_HEAL:
			if low:
				return { "move": item_id, "slot": slot, "target": CombatPrototype.PLAYER_INDEX }
		elif effect in [CombatPrototype.ITEM_FREEZE, CombatPrototype.ITEM_BLACK_HOLE]:
			if not paused:
				return { "move": item_id, "slot": slot, "target": -1 }
		else:
			return { "move": item_id, "slot": slot, "target": _weakest(cp, _enemies(cp)) }
	return {}


# At the paused position i, when a strike lands after it (this index, or
# the next from a faster enemy): already Guarded, Feint an enemy open for
# the next action (Feint keeps the guard); else Strike an opening only when
# the player wins the HP race at full damage both ways; else Guard.
# Unthreatened: Strike the weakest enemy that'll be Open; else that Feint;
# else Strike the weakest for chip.
func _reader_action(cp: Dictionary, i: int, size: int) -> Dictionary:
	var enemies := _enemies(cp)
	var open: Array = enemies.filter(func(e): return _sees_open(cp, e, i, i, []))
	var feint_target := _feint_target(cp, enemies, i, size)
	if _threatened(cp, enemies, i, size):
		if feint_target >= 0 and not CombatPrototype.is_open(cp, cp["combatants"][CombatPrototype.PLAYER_INDEX]):
			return { "move": CombatPrototype.MOVE_FEINT, "target": feint_target }
		if not open.is_empty() and _wins_race(cp, enemies, _weakest(cp, open)):
			return { "move": CombatPrototype.MOVE_STRIKE, "target": _weakest(cp, open) }
		return { "move": CombatPrototype.MOVE_GUARD, "target": CombatPrototype.PLAYER_INDEX }
	if not open.is_empty():
		return { "move": CombatPrototype.MOVE_STRIKE, "target": _weakest(cp, open) }
	if feint_target >= 0:
		return { "move": CombatPrototype.MOVE_FEINT, "target": feint_target }
	return { "move": CombatPrototype.MOVE_STRIKE, "target": _weakest(cp, enemies) }


# A Guarded enemy that a Feint at action i leaves Open for action i+1; -1
# for none (or no action i+1).
func _feint_target(cp: Dictionary, enemies: Array, i: int, size: int) -> int:
	if i + 1 >= size:
		return -1
	for e in enemies:
		if not _sees_open(cp, e, i, i + 1, []) and _sees_open(cp, e, i, i + 1, [i]):
			return e
	return -1


# Whether trading full hits with every living enemy downs `target` no later
# than the player goes down, at mean rolls.
func _wins_race(cp: Dictionary, enemies: Array, target: int) -> bool:
	var incoming := 0.0
	for e in enemies:
		incoming += _mean_roll(cp, e)
	var hits_to_kill := ceilf(float(cp["combatants"][target]["hp"]) / _mean_roll(cp, CombatPrototype.PLAYER_INDEX))
	var hits_to_die := ceilf(float(cp["combatants"][CombatPrototype.PLAYER_INDEX]["hp"]) / incoming)
	return hits_to_kill <= hits_to_die


func _mean_roll(cp: Dictionary, actor: int) -> float:
	var roll_range := CombatPrototype.damage_range(cp, actor)
	return (roll_range[0] + roll_range[1]) / 2.0


# Whether a damaging enemy action aimed at the player (or at anyone, when
# sight doesn't show targets) lands between the player's action i (the
# paused one) and its next: a slower or tied enemy's action i, or a faster
# enemy's action i+1 (next round's first, under sight, for the last action).
func _threatened(cp: Dictionary, enemies: Array, i: int, size: int) -> bool:
	var me: int = cp["combatants"][CombatPrototype.PLAYER_INDEX]["speed"]
	for e in enemies:
		var faster: bool = cp["combatants"][e]["speed"] > me
		var intents := CombatPrototype.enemy_intents(cp, e)
		if not faster and _strikes(cp, e, intents, i):
			return true
		if faster:
			if i + 1 < size and _strikes(cp, e, intents, i + 1):
				return true
			if i + 1 >= size and _strikes(cp, e, CombatPrototype.enemy_intents(cp, e, true), 0, true):
				return true
	return false


# Whether intent `index` (this round's next for enemy e, or next round's
# with next_round) is a damaging action aimed at the player; an unread one
# isn't known to be.
func _strikes(cp: Dictionary, e: int, intents: Array, index: int, next_round: bool = false) -> bool:
	if index >= intents.size() or intents[index].get("unread", false):
		return false
	if not next_round and int(cp["combatants"][e]["actionsLost"]) > 0:
		return false
	var intent: Dictionary = intents[index]
	if CombatPrototype.move(intent["move"])["effect"] not in [CombatPrototype.EFFECT_DAMAGE, CombatPrototype.EFFECT_STUN]:
		return false
	return int(intent.get("target", CombatPrototype.PLAYER_INDEX)) == CombatPrototype.PLAYER_INDEX


# Whether enemy e will be Open when the player takes action i, read from
# the fight paused at the player's action `now`: its guard state now, then
# its own committed guard changes still to come before i (minus any it's
# losing) and the player's Feints planned at `feints` indices, in timeline
# order. A frozen or Exposed enemy reads Open; an unread intent leaves its
# guard unknown, which doesn't.
func _sees_open(cp: Dictionary, e: int, now: int, i: int, feints: Array) -> bool:
	var enemy: Dictionary = cp["combatants"][e]
	if CombatPrototype.is_exposed(cp, enemy):
		return true
	var faster: bool = enemy["speed"] > cp["combatants"][CombatPrototype.PLAYER_INDEX]["speed"]
	var intents := CombatPrototype.enemy_intents(cp, e)
	var resolved := mini(now + 1 if faster else now, intents.size())
	var acted := mini(i + 1 if faster else i, intents.size())
	if int(enemy["frozenActions"]) > acted - resolved:
		return true
	var lost := int(enemy["actionsLost"])
	# Events as [index, enemy-first-at-that-index, guard state].
	var events: Array = []
	for j in range(resolved, acted):
		var guard: String = CombatPrototype.UNKNOWN if intents[j].get("unread", false) else CombatPrototype.move(intents[j]["move"])["actorGuard"]
		if j - resolved >= lost and guard != CombatPrototype.UNCHANGED:
			events.append([j, faster, guard])
	for f in feints:
		if f < i:
			events.append([f, not faster, CombatPrototype.OPEN])
	events.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] and not b[1]))
	var state: String = CombatPrototype.OPEN if CombatPrototype.is_open(cp, enemy) else CombatPrototype.GUARDED
	for ev in events:
		state = ev[2]
	return state == CombatPrototype.OPEN


func _enemies(cp: Dictionary) -> Array:
	var result: Array = []
	var combatants: Array = cp["combatants"]
	for i in range(combatants.size()):
		if combatants[i]["side"] == CombatPrototype.SIDE_ENEMY and not combatants[i]["koed"]:
			result.append(i)
	return result


func _weakest(cp: Dictionary, candidates: Array) -> int:
	var best: int = candidates[0]
	for e in candidates:
		if cp["combatants"][e]["hp"] < cp["combatants"][best]["hp"]:
			best = e
	return best
