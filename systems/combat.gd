class_name Combat
extends RefCounted

# Turn-based combat per R§3.7, plus rewind per R§3.9. Static funcs only.

# Named constants for combat.context; a typo becomes a push_error instead of
# a silent mis-route.
const CONTEXT_RAID: String = "raid"
const CONTEXT_MUGGING: String = "mugging"
const CONTEXT_EVENT_MUGGING: String = "event_mugging"
const CONTEXT_HOME_RAID: String = "home_raid"
# A later HQ raid defended from its alarm (Home.trigger_defend()); no quest
# dialogue, Home owns the win/loss consequence (R§3.8).
const CONTEXT_HOME_ALARM_DEFEND: String = "home_alarm_defend"
const CONTEXT_EVENT_RAID: String = "event_raid"
const CONTEXT_DEFEND_VEIN: String = "defend_vein"
# Archie's own deal going wrong; resolves via ArchieDeals.resolve_mugging(),
# and a loss (not just a win) needs its own exit_combat() handling.
const CONTEXT_ARCHIE_DEAL_MUGGING: String = "archie_deal_mugging"

const CANONICAL_CONTEXTS: Array[String] = [
	CONTEXT_RAID, CONTEXT_MUGGING, CONTEXT_EVENT_MUGGING,
	CONTEXT_HOME_RAID, CONTEXT_EVENT_RAID, CONTEXT_DEFEND_VEIN,
	CONTEXT_ARCHIE_DEAL_MUGGING, CONTEXT_HOME_ALARM_DEFEND,
]

# Contexts that are a mugging in flavour (no vein at stake) rather than a
# raid; shared with scenes/screens/combat.gd's win-line/label logic.
const NON_LETHAL_MUGGING_CONTEXTS: Array[String] = [CONTEXT_MUGGING, CONTEXT_EVENT_MUGGING, CONTEXT_ARCHIE_DEAL_MUGGING]

# Beat "kind" vocabulary (same named-constant precedent as CONTEXT_*) so a
# typo errors instead of silently mismatching the director's switch.
const BEAT_PLAYER_ATTACK := "player_attack"
const BEAT_ALLY_ATTACK := "ally_attack"
const BEAT_ALLY_HEAL := "ally_heal"
const BEAT_ENEMY_ATTACK := "enemy_attack"
const BEAT_ENEMY_EVADE := "enemy_evade"
const BEAT_PLAYER_EVADE := "player_evade"
const BEAT_ABILITY_UNLOCKED := "ability_unlocked"
const BEAT_FROZEN_WEARS_OFF := "frozen_wears_off"
const BEAT_ALLY_KO := "ally_ko"
const BEAT_COMBAT_WIN := "combat_win"
const BEAT_COMBAT_LOSS := "combat_loss"
const BEAT_MOTION_ANNOUNCE := "motion_announce"
const BEAT_MOTION_END := "motion_end"
const BEAT_FLEE_SUCCESS := "flee_success"
const BEAT_FLEE_FAILED := "flee_failed"

# cast_complication()'s own beat kinds (the Dial-cast path only -- the
# direct bag-inventory use_*() path logs through _log() too, see below).
const BEAT_COMPLICATION_TIME_PEARL := "complication_time_pearl"
const BEAT_COMPLICATION_MOTION := "complication_motion"
const BEAT_COMPLICATION_BLAST := "complication_blast"
const BEAT_COMPLICATION_DISARM := "complication_disarm"
const BEAT_COMPLICATION_SHIELD := "complication_shield"
const BEAT_COMPLICATION_BLACK_HOLE_ANNOUNCE := "complication_black_hole_announce"
const BEAT_COMPLICATION_BLACK_HOLE_HIT := "complication_black_hole_hit"
const BEAT_COMPLICATION_HEALING_BURST := "complication_healing_burst"
const BEAT_COMPLICATION_PROPHETS_BREATH := "complication_prophets_breath"
const BEAT_COMPLICATION_WORMHOLE := "complication_wormhole"

# The direct bag-item use_*() path's own beat kinds, parallel to
# BEAT_COMPLICATION_*. Both paths stamp the same `effectKey` field, so the
# screen's effect-sheet dispatch reads one field regardless of the path.
const BEAT_USE_TIME_PEARL := "use_time_pearl"
const BEAT_USE_MOTION := "use_motion"
const BEAT_USE_BLAST := "use_blast"
const BEAT_USE_DISARM := "use_disarm"
const BEAT_USE_SHIELD := "use_shield"
const BEAT_USE_BLACK_HOLE_ANNOUNCE := "use_black_hole_announce"
const BEAT_USE_WORMHOLE := "use_wormhole"
const BEAT_USE_HEALING_BURST := "use_healing_burst"

# Placeholder percentages/turns, not final balance.
const BLAST_FLEE_BOOST_CHANCE := 0.90
const BLAST_DISARM_CHANCE := 0.15
const BLAST_DISARM_TURNS := 2

# recipeKeys with a defined combat effect; cast_complication() refuses
# anything else (rejuvenation/beALady/pansPrank/healingSalve have no
# in-combat mechanic; rewind casts via combat_rewind()'s own fallback).
const COMBAT_COMPLICATION_RECIPES: Array[String] = ["timePearl", "enhancementPowder", "blast", "shield", "blackHole", "healingBurst", "prophetsBreath", "wormhole"]

# Below this fraction of hpMax, an ally spends their turn on their own
# stash instead of attacking -- no player to hand them a Healing Burst.
const ALLY_HEAL_THRESHOLD_FRACTION := 0.4

# R§3.7a turn-order values. MUGGER_SPEED: the mugger has no data/enemies.json
# template of its own (generated procedurally below), so its speed lives
# here. DEFAULT_TEMPLATE_SPEED: default for a template that omits `speed`.
const MUGGER_SPEED := 11
const DEFAULT_TEMPLATE_SPEED := 10

# R§3.7a: Combat Skill's XP sources, flat regardless of hit/miss/outcome
# (mirrors Dial.cast_complication()'s flat +10 -- the attempt is what's
# awarded, not the result).
const COMBAT_XP_PER_ATTACK_TURN := 5
const COMBAT_XP_PER_GYM_SESSION := 30
const COMBAT_XP_PER_WORKOUT_SESSION := 10

# R§3.7a "Roster generation": ENEMY_INSTANCE_VARIANCE is the per-instance
# hp/attack variance band for spawned mugger/guard entries (draft, not
# balance-final); SQUAD_MAX is the squad-size cap generate_raid_enemy()
# clamps guard_count to.
const ENEMY_INSTANCE_VARIANCE := 0.15
const SQUAD_MAX := 3


static func is_canonical_context(context: String) -> bool:
	return CANONICAL_CONTEXTS.has(context)


# R§3.7a: rolls variance for one stat independently, called once per
# hp/attackMin/attackMax so same-archetype squadmates never match exactly.
static func _apply_instance_variance(base: float) -> int:
	return GameState.round_epsilon(base * Rng.randf_range(1.0 - ENEMY_INSTANCE_VARIANCE, 1.0 + ENEMY_INSTANCE_VARIANCE))


# A trade including a vein rolls a harder mugger encounter: a wider,
# higher-floor roster (2-4 vs. the default 1-3) at 1.3x base stats. Draft,
# needs balance sign-off (see MUG_BASE_CHANCE_VEIN in economy.gd).
const HARD_MUGGER_MIN_COUNT := 2
const HARD_MUGGER_MAX_COUNT := 4
const HARD_MUGGER_STAT_SCALE := 1.3


# `count` distinct entries off the single mugger archetype's base stats
# (hp 28, atk 4-10 per R§3.7a), each with independent variance. `harder`
# widens the roster and scales stats -- see HARD_MUGGER_* above.
static func generate_mugger(harder: bool = false) -> Array:
	var min_count: int = HARD_MUGGER_MIN_COUNT if harder else 1
	var max_count: int = HARD_MUGGER_MAX_COUNT if harder else 3
	var count: int = Rng.randi_range(min_count, max_count)
	var entries: Array = []
	for _i in range(count):
		entries.append(_spawn_mugger_instance(harder))
	return entries


static func _spawn_mugger_instance(harder: bool = false) -> Dictionary:
	var scale: float = HARD_MUGGER_STAT_SCALE if harder else 1.0
	var hp: int = _apply_instance_variance(28 * scale)
	return {
		"name": "A mugger",
		"hp": hp,
		"hpMax": hp,
		"attackMin": _apply_instance_variance(4 * scale),
		"attackMax": _apply_instance_variance(10 * scale),
		"isMugging": true,
		"weapon": null,
		"ability": null,
		"evadeChance": 0.0,
		"speed": MUGGER_SPEED,
	}


# The "N muggers stepped out" intro-line label; naming a roster is the
# caller's job, not generate_mugger()'s.
static func _mugger_intro_label(count: int) -> String:
	return "A mugger" if count == 1 else "%d muggers" % count


# Builds the {weapon, ability, evadeChance} fields shared by every
# enemy-construction path. evadeChance defaults to 20% when a template
# omits the key (existing templates specify 0 explicitly).
static func _enemy_capabilities_from_template(template: Dictionary) -> Dictionary:
	var ability = null
	if template.has("ability"):
		ability = { "id": template["ability"], "lockedTurns": 0 }
	return {
		"weapon": template.get("weapon"),
		"ability": ability,
		"evadeChance": template.get("evadeChance", 0.2),
		"speed": template.get("speed", DEFAULT_TEMPLATE_SPEED),
	}


# Debug-only in M0 (R§3.7); M0 has no NPC-claimed-vein storage, so callers
# supply a value tier/guards directly. value_tier is Cultivating.combined_magnitude()
# (R§3.4: value_tier blended with a vein's earned level); guard_count
# (capped at SQUAD_MAX) entries roll independently from
# GameData.ENEMY_RAID_GUARDS unless `template_key` forces one template.
static func generate_raid_enemy(vein_id, value_tier: int, guards: int = 1, template_key: String = "") -> Array:
	var templates: Dictionary = GameData.ENEMY_RAID_GUARDS
	var guard_count: int = clampi(guards, 1, SQUAD_MAX)
	var entries: Array = []
	for _i in range(guard_count):
		var key: String = template_key
		if key == "" or not templates.has(key):
			key = Rng.rand_from(templates.keys())
		entries.append(_spawn_guard_instance(templates[key], value_tier))
	return entries


static func _spawn_guard_instance(template: Dictionary, value_tier: int) -> Dictionary:
	var hp_scale: float = 1.0 + (value_tier - 1) * 0.3
	var hp: int = _apply_instance_variance(template["hpBase"] * hp_scale)
	var entry := {
		"name": template["name"],
		"hp": hp,
		"hpMax": hp,
		"attackMin": _apply_instance_variance(template["attackMin"]),
		"attackMax": _apply_instance_variance(template["attackMax"] + (value_tier - 1)),
		"isMugging": false,
	}
	entry.merge(_enemy_capabilities_from_template(template))
	return entry


# Raid-intro group label for a spawned guard roster: collapses same-named
# entries to "N× Name", joins distinct names for a mixed-archetype squad
# (e.g. one Scrapper + one Vein Guard).
static func _guard_group_name(entries: Array) -> String:
	var counts: Dictionary = {}
	var order: Array = []
	for entry in entries:
		var n: String = entry["name"]
		if not counts.has(n):
			counts[n] = 0
			order.append(n)
		counts[n] += 1
	var parts: Array = []
	for n in order:
		var c: int = counts[n]
		parts.append(n if c <= 1 else "%d× %s" % [c, n])
	return " and ".join(parts)


static func get_attack_range() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	# R§3.7a: Combat Skill's attack bonus applies before the weapon bonus
	# below; level 1 is 0, so a fresh save's math is unaffected.
	var skill_bonus: int = GameData.COMBAT_ATTACK_BONUS_BY_LEVEL[player["combatSkill"]]
	var min_atk: int = player["attackMin"] + skill_bonus
	var max_atk: int = player["attackMax"] + skill_bonus
	var weapon_id = player["equipment"]["weapon"]
	if weapon_id != null:
		for item in player["items"]:
			if item["id"] == weapon_id:
				var def: Dictionary = GameData.ITEMS.get(item["type"], {})
				if def.has("attackBonus"):
					min_atk += def["attackBonus"]["min"]
					max_atk += def["attackBonus"]["max"]
				break
	return { "min": min_atk, "max": max_atk }


# Mirrors get_attack_range() for the enemy side: base attack + equipped
# weapon bonus, if any (the same weapon disarm_enemy() strips).
static func get_enemy_attack_range(enemy: Dictionary) -> Dictionary:
	var min_atk: int = enemy["attackMin"]
	var max_atk: int = enemy["attackMax"]
	var weapon = enemy.get("weapon")
	if weapon != null:
		min_atk += weapon["min"]
		max_atk += weapon["max"]
	return { "min": min_atk, "max": max_atk }


static func is_ability_locked(enemy: Dictionary) -> bool:
	var ability = enemy.get("ability")
	return ability != null and ability.get("lockedTurns", 0) > 0


# Strips the enemy's weapon bonus and locks any ability out for `turns`
# player-attack turns (ticked down and re-announced in player_attack()).
static func disarm_enemy(enemy: Dictionary, turns: int) -> void:
	enemy["weapon"] = null
	if enemy.get("ability") != null:
		enemy["ability"]["lockedTurns"] = turns


# Fires out of Economy.execute_sale()'s Archie lane -- his own deal going
# wrong, so he always fights here, bypassing Contacts.can_join_combat()'s
# gate. `vein_included` rolls generate_mugger()'s harder roster.
static func start_mugging(vein_included: bool = false) -> void:
	var enemies := generate_mugger(vein_included)
	var log_lines := ["%s step out of nowhere. They want what you're carrying." % _mugger_intro_label(enemies.size())]
	if vein_included:
		log_lines.append("Word of a vein in the mix travels fast -- this lot came heavier.")
	log_lines.append("Archie's deal, Archie's problem -- he wades in.")
	_start_combat(CONTEXT_MUGGING, null, enemies, log_lines, "muggingWon",
		[Contacts.build_combat_ally("archie")])


# Fires out of ArchieDeals.accept_deal() -- his own deal, same always-ally
# reasoning as start_mugging(). onWin is "" since both outcomes need
# handling: ArchieDeals.resolve_mugging() runs from exit_combat() either way.
static func start_archie_deal_mugging() -> void:
	var enemies := generate_mugger()
	var log_lines := ["%s step out of nowhere. They want what you're carrying." % _mugger_intro_label(enemies.size())]
	log_lines.append("Archie's deal, Archie's problem -- he wades in.")
	_start_combat(CONTEXT_ARCHIE_DEAL_MUGGING, null, enemies, log_lines, "",
		[Contacts.build_combat_ally("archie")])


# District-event-triggered street mugging (M1-LONDON D5). Distinct from
# "mugging": no pendingSaleCut to settle, onWin is "" (no dispatch), and
# exit_combat() routes back to the still-active event screen.
static func start_street_mugging() -> void:
	var enemies := generate_mugger()
	_start_combat(CONTEXT_EVENT_MUGGING, null, enemies,
		["%s want a word. This is about to get physical." % _mugger_intro_label(enemies.size())],
		"")


# Called by combat_intro events via the start_home_raid_combat effect op.
static func start_home_raid_combat() -> void:
	_start_combat(CONTEXT_HOME_RAID, null, [_home_raider_enemy()],
		["They're in the flat. You've got the crowbar. This is happening."],
		"homeRaidWon")


# Called by Home.trigger_defend(): same raider, no onWin (Home resolves it).
static func start_home_alarm_defend_combat() -> void:
	_start_combat(CONTEXT_HOME_ALARM_DEFEND, null, [_home_raider_enemy()],
		["They're in the flat. You've got the crowbar. This is happening."],
		"")


static func _home_raider_enemy() -> Dictionary:
	var raider: Dictionary = GameData.ENEMY_HOME_RAID_RAIDER
	var enemy := {
		"name": raider["name"], "hp": raider["hp"], "hpMax": raider["hp"],
		"attackMin": raider["attackMin"], "attackMax": raider["attackMax"],
		"isMugging": false,
	}
	enemy.merge(_enemy_capabilities_from_template(raider))
	return enemy


# Debug-only in M0 (see generate_raid_enemy). Also called by events.gd's
# "start_raid_combat" op with context "event_raid", so exit_combat() below
# resumes the still-active event on a win instead of routing home.
static func start_raid(vein_id: String, value_tier: int, guards: int = 1, template_key: String = "", context: String = CONTEXT_RAID, ally_ids: Array = []) -> void:
	var enemies := generate_raid_enemy(vein_id, value_tier, guards, template_key)
	var log_lines := ["%s steps out to meet you." % _guard_group_name(enemies)]
	var allies := _gather_raid_allies(ally_ids, log_lines)
	_start_combat(context, vein_id, enemies, log_lines, "raidWon", allies)


# Unlike _gather_defend_allies' auto-join-everyone, bringing an ally on a
# raid is the player's explicit choice at the Raid button (map.gd).
# Re-validated against can_join_combat() since relation/cooldown/recruit
# state can move between pressing Raid and combat actually starting.
static func _gather_raid_allies(ally_ids: Array, log_lines: Array) -> Array:
	var allies: Array = []
	for contact_id in ally_ids:
		if Contacts.can_join_combat(contact_id):
			allies.append(Contacts.build_combat_ally(contact_id))
			log_lines.append("%s comes in behind you." % Contacts.display_name(contact_id))
	return allies


# The alarm-upgrade defend encounter, called by Raiding.maybe_trigger_defend()
# once the player travels into the vein's district within the pending
# window. onWin is "" -- a loss is handled by Raiding.resolve_defend_outcome().
static func start_defend_vein(vein_id: String, value_tier: int) -> void:
	var enemies := generate_raid_enemy(vein_id, value_tier)
	var log_lines := ["The alarm wasn't lying. %s is already there." % _guard_group_name(enemies)]
	# Act 2 T8a's pre-fight reminder (spec §5.1/§6.8a): one Nadia-voiced line,
	# prepended only for the vein col_a2_nadia_defend is watching, only once.
	if vein_id == GameState.state["collective"].get("nadiaDefendVeinId") and not GameState.state["flags"].get("colA2DefendReminderShown", false):
		log_lines.push_front("Nadia, in your ear: \"Go on then. That's what the Blast and the Shield were for — use them properly this time, not for luck.\"")
		GameState.state["flags"]["colA2DefendReminderShown"] = true
	var allies := _gather_defend_allies(log_lines)
	_start_combat(CONTEXT_DEFEND_VEIN, vein_id, enemies, log_lines, "", allies)


# Vein-defense fights only: every recruited contact with a combat kit
# joins automatically (no offer/decline step). Generic over contact_id.
static func _gather_defend_allies(log_lines: Array) -> Array:
	var allies: Array = []
	for contact_id in GameState.state["contacts"].keys():
		if Contacts.can_join_combat(contact_id):
			allies.append(Contacts.build_combat_ally(contact_id))
			log_lines.append("%s peels off to help cover the vein." % Contacts.display_name(contact_id))
	return allies


static func _start_combat(context: String, vein_id, enemies: Array, log_lines: Array, on_win: String, allies: Array = []) -> void:
	if not is_canonical_context(context):
		push_error("Combat: unrecognized context '%s' — not in CANONICAL_CONTEXTS, exit_combat() will mis-route it." % context)
	# Every roster entry needs koed regardless of which start_* path built
	# it -- one chokepoint (speed is already set at construction time).
	for enemy in enemies:
		enemy["koed"] = false
	GameState.state["combat"] = {
		"active": true, "context": context, "veinId": vein_id, "enemies": enemies,
		# R§2: player/ally/enemy selection. Defaults to the first enemy.
		"selection": { "type": "enemy", "index": 0 },
		"log": log_lines, "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": on_win, "snapshots": [],
		"allies": allies,
		# Every beat _log() threads since the oldest snapshot still on the stack
		# was pushed; see combat_rewind()'s "beat queue in reverse" use of it.
		"beatsSinceSnapshot": [],
		# R§3.7a "Resumable turn progression": the round's queue + how far
		# into it we've resolved. Never carried between fights -- the first
		# advance_to_next_decision() call populates queue/round from empty.
		"turnCursor": { "queue": [], "index": 0, "round": 0 },
	}
	GameState.state["currentScreen"] = "combat"
	EventBus.screen_changed.emit("combat")
	EventBus.state_changed.emit()
	# Sets currentScreen/emits screen_changed itself rather than via
	# Nav.go_to(), so it needs the same abandon-after-both-emits treatment,
	# since Raiding.maybe_trigger_defend() can fire this synchronously
	# mid-Sites.prospect()/Travel.travel_to() while a Map animation plays.
	MapEvents.abandon_playback()


# The player's single-target enemy-only actions (Attack, Blast, any non-AoE
# Complication) all resolve against this one entry.
static func _focused_enemy(combat: Dictionary) -> Dictionary:
	return combat["enemies"][_enemy_action_index(combat)]


# Enemy-only actions need a concrete enemy index regardless of what
# combat.selection currently points at -- a non-enemy selection falls
# back to the first living enemy here rather than indexing out of range.
# Command-level availability (rejecting an enemy-only action outright
# when selection.type != "enemy", R§2) is a separate concern from this
# index resolution.
static func _enemy_action_index(combat: Dictionary) -> int:
	var selection: Dictionary = combat["selection"]
	if selection["type"] == "enemy":
		return selection["index"]
	return _first_living_enemy_index(combat["enemies"])


static func _first_living_enemy_index(enemies: Array) -> int:
	for i in range(enemies.size()):
		if not enemies[i]["koed"]:
			return i
	return 0


# The turn-order strip's tap-to-select gesture (card or stage sprite, R§2)
# calls this rather than writing combat.selection directly (screens never
# mutate GameState.state). Not a combat action -- no snapshot, no turn,
# no log.
static func set_selection(type: String, index: int) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	if type == "player":
		combat["selection"] = { "type": "player", "index": 0 }
		EventBus.state_changed.emit()
		return { "ok": true }
	if type != "ally" and type != "enemy":
		return { "ok": false, "reason": "Invalid target." }
	var roster: Array = combat["allies"] if type == "ally" else combat["enemies"]
	if index < 0 or index >= roster.size() or roster[index]["koed"]:
		return { "ok": false, "reason": "Invalid target." }
	combat["selection"] = { "type": type, "index": index }
	EventBus.state_changed.emit()
	return { "ok": true }


static func push_combat_snapshot() -> void:
	var combat: Dictionary = GameState.state["combat"]
	if combat["enemies"].is_empty():
		return
	var player: Dictionary = GameState.state["player"]
	var focused: Dictionary = _focused_enemy(combat)
	var snap := {
		"playerHp": player["hp"],
		"enemyHp": focused["hp"],
		# The concrete enemy the above hp belongs to -- kept separate from
		# `selection` below since selection may not be enemy-type at all
		# (R§2); re-deriving it from the restored selection could land on a
		# different enemy than the one this hp was actually captured from.
		"enemyIndex": _enemy_action_index(combat),
		"selection": combat["selection"].duplicate(),
		"log": combat["log"].duplicate(),
		"frozenTurns": combat["frozenTurns"],
		"motionTurns": combat["motionTurns"],
		"motionPower": combat["motionPower"],
		"evadeTurns": combat["evadeTurns"],
		"evadeChance": combat["evadeChance"],
		# R§3.7a: parked cursor position at this decision point, so a
		# restore resumes at the same queued player-type entry rather than
		# losing its place in the round.
		"turnCursor": combat["turnCursor"].duplicate(),
	}
	Snapshots.push("combat", combat["snapshots"], snap)


# R§3.7a "Turn order": every non-koed combatant, sorted by speed
# descending, ties broken player > allies > enemies (construction order
# plus an index-stable comparator, since Array.sort_custom isn't stable).
# Motion (motionTurns > 0) inserts attack_count - 1 extra player entries
# after the player's slot (2 below motionPower 3, 3 at/above), so total
# damage spreads across visible queue entries, not a hidden multiplier.
static func _player_speed() -> int:
	var player: Dictionary = GameState.state["player"]
	return GameData.COMBAT_SPEED_BY_LEVEL[player["combatSkill"]]


static func build_turn_queue(combat: Dictionary) -> Array:
	var entries: Array = [{ "type": "player", "speed": _player_speed() }]

	var allies: Array = combat["allies"]
	for i in range(allies.size()):
		if not allies[i]["koed"]:
			entries.append({ "type": "ally", "index": i, "speed": allies[i].get("speed", 0) })

	var enemies: Array = combat["enemies"]
	for i in range(enemies.size()):
		if not enemies[i]["koed"]:
			entries.append({ "type": "enemy", "index": i, "speed": enemies[i].get("speed", 0) })

	var order: Array = range(entries.size())
	order.sort_custom(func(a, b):
		if entries[a]["speed"] != entries[b]["speed"]:
			return entries[a]["speed"] > entries[b]["speed"]
		return a < b
	)
	var queue: Array = []
	for i in order:
		queue.append(entries[i])

	if combat["motionTurns"] > 0:
		var player_pos := 0
		for i in range(queue.size()):
			if queue[i]["type"] == "player":
				player_pos = i
				break
		var attack_count: int = 3 if combat["motionPower"] >= 3 else 2
		for _n in range(attack_count - 1):
			queue.insert(player_pos + 1, { "type": "player", "speed": _player_speed(), "extra": true })

	return queue


# R§3.7a "Resumable turn progression": the engine's resume function.
# Starting from combat.turnCursor.index, auto-resolves every non-player
# entry in place (ally/enemy turns, unchanged bodies -- a koed entry is
# skipped exactly as its own turn body already handles) and stops the
# instant either combat.outcome resolves or a player-type entry (the
# round's own slot or a Motion-inserted extra) is reached. Never resolves
# the player entry itself -- it parks there and waits for a command. A
# round boundary (cursor exhausts the queue) decrements motionTurns once,
# rebuilds the queue via build_turn_queue() against the post-tick state,
# and keeps auto-resolving into the new round.
static func advance_to_next_decision(combat: Dictionary, beats: Variant = null) -> void:
	var cursor: Dictionary = combat["turnCursor"]
	while true:
		if cursor["index"] >= cursor["queue"].size():
			# Only decrement when the round that's ending actually spent the
			# buff (its queue carries Motion-inserted "extra" slots) -- not
			# whenever motionTurns happens to be >0. Activating Motion mid-
			# round (an item use) sets motionTurns after this round's queue
			# was already built without extras, so it takes effect starting
			# next round; decrementing here too would expire it before it
			# ever granted an extra attack, including at the very first
			# round of a fight (queue starts empty, no round has run yet).
			var round_spent_motion := false
			for queued_entry in cursor["queue"]:
				if queued_entry.get("extra", false):
					round_spent_motion = true
					break
			if round_spent_motion and combat["motionTurns"] > 0:
				combat["motionTurns"] -= 1
				if combat["motionTurns"] == 0:
					_log(combat, beats, "The powder wears off. Back to normal speed.", BEAT_MOTION_END, {})
			cursor["queue"] = build_turn_queue(combat)
			cursor["index"] = 0
			cursor["round"] += 1
			if combat["motionTurns"] > 0:
				var motion_label: String = "three times" if combat["motionPower"] >= 3 else "twice"
				_log(combat, beats, "Motion powder — you move %s as fast." % motion_label, BEAT_MOTION_ANNOUNCE, {})
			continue

		var entry: Dictionary = cursor["queue"][cursor["index"]]
		if entry["type"] == "player":
			return

		cursor["index"] += 1
		match entry["type"]:
			"ally":
				var allies: Array = combat["allies"]
				if entry["index"] < allies.size() and not allies[entry["index"]]["koed"]:
					_ally_turn(combat, allies[entry["index"]], entry["index"], beats)
			"enemy":
				var enemies: Array = combat["enemies"]
				if entry["index"] < enemies.size() and not enemies[entry["index"]]["koed"]:
					_enemy_turn(combat, enemies[entry["index"]], entry["index"], beats)

		if combat["outcome"] != null:
			return


# Guarantees the cursor is parked at a player-type entry before a command's
# own effect resolves against it. Only ever does real work on the very
# first decision of a fresh fight (turnCursor.queue starts empty) -- every
# later call arrives already parked there, because the previous decision's
# conclude_decision_point() already ran the engine forward into this round.
# Returns false when advancing here itself ends the fight (e.g. a
# faster-than-player enemy opens with a lethal hit) -- callers bail out
# without resolving their own action.
static func prime_decision_point(combat: Dictionary, beats: Variant = null) -> bool:
	if combat["turnCursor"]["queue"].is_empty():
		advance_to_next_decision(combat, beats)
	return combat["outcome"] == null


# Marks the cursor's current player-type entry resolved and runs the engine
# forward to the next decision point (or outcome) -- called once a
# command's own effect has been applied to that entry.
static func conclude_decision_point(combat: Dictionary, beats: Variant = null) -> void:
	combat["turnCursor"]["index"] += 1
	if combat["outcome"] == null:
		advance_to_next_decision(combat, beats)


# R§3.7a "Bounded queue-projection policy": a pure, non-mutating "what's
# coming" read for the turn-order strip (docs/combat-animation-vision.md
# §2.4). Horizon: the remainder of the current round from turnCursor.index
# onward, plus exactly one additional full round, built against the state
# as it would stand after the deterministic round-boundary tick -- never
# committed to turnCursor, a projection only. One extra round always
# guarantees every living combatant's next occurrence appears (worst
# case: a combatant who just acted at the very start of the current
# round). Repeated occurrences and Motion-inserted extra slots appear
# exactly as build_turn_queue() naturally produces them -- no dedup.
# Never reveals unresolved-turn outcomes (evade rolls, damage, an enemy's
# target pick) -- only who acts and in what order.
static func project_queue(combat: Dictionary) -> Array:
	var cursor: Dictionary = combat["turnCursor"]
	var projected: Array = []

	for i in range(cursor["index"], cursor["queue"].size()):
		projected.append(_project_occurrence(cursor["queue"][i], cursor["round"], i))

	# Mirrors advance_to_next_decision()'s own round-boundary tick, but
	# against a duplicated dict so the real combat state is never mutated
	# by a read. Only decrements a projected motionTurns when the ending
	# round's own queue actually carried a Motion-inserted "extra" slot --
	# same reasoning as the real tick (see that function's own comment).
	var round_spent_motion := false
	for queued_entry in cursor["queue"]:
		if queued_entry.get("extra", false):
			round_spent_motion = true
			break
	var projected_combat: Dictionary = combat.duplicate()
	if round_spent_motion and combat["motionTurns"] > 0:
		projected_combat["motionTurns"] = combat["motionTurns"] - 1

	var next_round: Array = build_turn_queue(projected_combat)
	for i in range(next_round.size()):
		projected.append(_project_occurrence(next_round[i], cursor["round"] + 1, i))

	return projected


# occurrenceId is stable within one project_queue() call -- "round:index
# within that round's queue" -- unique across the whole projection since
# each (round, index) pair appears at most once.
static func _project_occurrence(entry: Dictionary, round_num: int, index_in_round: int) -> Dictionary:
	var occurrence: Dictionary = entry.duplicate()
	occurrence["occurrenceId"] = "%d:%d" % [round_num, index_in_round]
	return occurrence


# R§3.7a: shared by player_attack()'s per-turn XP and train()'s gym-session
# XP -- same Progression.award_xp()/GameData.COMBAT_XP_LEVELS mechanism
# Cultivating.award_xp() already uses.
static func award_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	var on_level_up := func(): Notify.push("Combat Skill up — now level %d." % player["combatSkill"], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(player, "combatXP", "combatSkill", GameData.COMBAT_XP_LEVELS, amount, on_level_up)


# Resolves exactly the one queued player-type entry the cursor is parked
# on -- never a whole round (R§3.7a "Resumable turn progression") -- then
# runs the engine forward to the next decision point. Also returns `beats`
# (docs/combat-animation-vision.md §8): an ordered Array of pure-data
# dictionaries, one per new log line. GameState.state gains no new schema --
# beats live only in the return value, so save/load and Rewind are untouched.
static func player_attack() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "outcome": combat["outcome"], "beats": beats }

	push_combat_snapshot()
	# Tier-5 Recharge Movement's in-combat regen ticks once per player turn;
	# a silent no-op for every other Movement/no-Dial case.
	Dial.combat_turn_tick()

	# R§3.7a: flat XP once per player_attack() call, regardless of hit/miss/
	# kill/loss -- taking a turn has no success/fail split to award against.
	# A Motion round now calls this once per resolved player entry (2-3
	# calls), so it visibly awards 2-3x -- matching "once per player turn
	# taken" as already written here, not a formula change.
	award_xp(COMBAT_XP_PER_ATTACK_TURN)

	# Stamped onto this attack's beat, since motionTurns may already be 0 by
	# playback time -- beats must be self-describing snapshots, never a
	# live-state re-read. Stable for the whole round (only the round
	# boundary decrements it), so every player entry in a Motion round sees
	# the same value.
	_resolve_player_turn(combat, beats, combat["motionTurns"] > 0)

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "outcome": combat["outcome"], "beats": beats }


# Appends `line` to combat.log and, when a live `beats` Array was threaded
# through, a matching pure-data beat with the same line plus caller-supplied
# fields. `beats` is null (not an empty Array) at call sites that don't
# need it. No Node/Callable/SpriteFrames ever enters a beat -- ids/numbers/
# strings only, resolved by the screen.
static func _log(combat: Dictionary, beats: Variant, line: String, kind: String, extra: Dictionary = {}) -> void:
	combat["log"].append(line)
	if beats == null:
		return
	var beat: Dictionary = { "kind": kind, "logLine": line }
	beat.merge(extra)
	beats.append(beat)
	# Mirrors every threaded beat onto a rolling accumulator combat_rewind()
	# hands back (reversed) for replay, cleared only when
	# _restore_from_snapshot() consumes it -- purely cosmetic (GameState is
	# already correctly restored by then).
	combat["beatsSinceSnapshot"].append(beat)


# Public entry point for a system outside this file (Consumables.
# use_healing_burst()) to thread a beat through the same accumulator
# convention every use_*() below uses.
static func append_beat(combat: Dictionary, beats: Variant, line: String, kind: String, extra: Dictionary = {}) -> void:
	_log(combat, beats, line, kind, extra)


# One atomic player turn: a single attack against the focused enemy. Called
# once per player-type queue entry -- normally once a round, twice/three
# times on a Motion-boosted round (build_turn_queue()'s extra entries).
static func _resolve_player_turn(combat: Dictionary, beats: Variant = null, motion_boosted: bool = false) -> void:
	var enemy: Dictionary = _focused_enemy(combat)
	var target_index: int = _enemy_action_index(combat)
	# `motionBoosted` is stamped on this beat whenever this round is a Motion
	# round, so the screen's afterimage trail can key off the beat itself
	# rather than live state. Only added when true.
	if Rng.chance(enemy.get("evadeChance", 0.0)):
		var evade_extra: Dictionary = { "actorType": "player", "targetType": "enemy", "targetIndex": target_index }
		if motion_boosted:
			evade_extra["motionBoosted"] = true
		_log(combat, beats, "%s dodges — no damage." % enemy["name"], BEAT_ENEMY_EVADE, evade_extra)
		return
	var atk := get_attack_range()
	var dmg: int = Rng.randi_range(atk["min"], atk["max"])
	enemy["hp"] = maxi(0, enemy["hp"] - dmg)
	var frozen_note: String = " (enemy frozen)" if combat["frozenTurns"] > 0 else ""
	var attack_extra: Dictionary = { "actorType": "player", "targetType": "enemy", "targetIndex": target_index, "dmg": dmg }
	if motion_boosted:
		attack_extra["motionBoosted"] = true
	_log(combat, beats, "You attack — %d damage%s. Enemy: %d/%d HP." % [dmg, frozen_note, enemy["hp"], enemy["hpMax"]], BEAT_PLAYER_ATTACK, attack_extra)
	_maybe_win_from_direct_damage(combat, enemy, beats)


# One atomic ally turn: patch up from stash below the heal threshold, or
# attack the player's focused enemy. Same evade/damage shape as the
# player's own attack. `ally_index` is only needed to stamp onto the beat.
static func _ally_turn(combat: Dictionary, ally: Dictionary, ally_index: int, beats: Variant = null) -> void:
	var enemy: Dictionary = _focused_enemy(combat)
	var target_index: int = _enemy_action_index(combat)

	if ally["hp"] < ally["hpMax"] * ALLY_HEAL_THRESHOLD_FRACTION and ally["stash"] > 0:
		ally["stash"] -= 1
		ally["hp"] = mini(ally["hpMax"], ally["hp"] + ally["healAmount"])
		_log(combat, beats, "%s patches themselves up. %s: %d/%d HP." % [ally["name"], ally["name"], ally["hp"], ally["hpMax"]], BEAT_ALLY_HEAL,
			{ "actorType": "ally", "actorIndex": ally_index, "amount": ally["healAmount"] })
		return

	if Rng.chance(enemy.get("evadeChance", 0.0)):
		_log(combat, beats, "%s swings at %s — they dodge." % [ally["name"], enemy["name"]], BEAT_ENEMY_EVADE,
			{ "actorType": "ally", "actorIndex": ally_index, "targetType": "enemy", "targetIndex": target_index })
		return

	var dmg: int = Rng.randi_range(ally["attackMin"], ally["attackMax"])
	enemy["hp"] = maxi(0, enemy["hp"] - dmg)
	_log(combat, beats, "%s hits %s for %d. Enemy: %d/%d HP." % [ally["name"], enemy["name"], dmg, enemy["hp"], enemy["hpMax"]], BEAT_ALLY_ATTACK,
		{ "actorType": "ally", "actorIndex": ally_index, "targetType": "enemy", "targetIndex": target_index, "dmg": dmg })
	_maybe_win_from_direct_damage(combat, enemy, beats)


# The enemy's single attack targets the player or one alive ally,
# uniform-random over whoever's still standing. Returns combat.allies'
# index (-1 sentinel for "attack the player"), not the dict itself, since
# beats need a stable ids-only reference.
static func _pick_enemy_target(combat: Dictionary) -> int:
	var alive_indices: Array = []
	for i in range(combat["allies"].size()):
		if not combat["allies"][i]["koed"]:
			alive_indices.append(i)
	if alive_indices.is_empty():
		return -1
	var candidates: Array = [-1]
	candidates.append_array(alive_indices)
	return candidates[Rng.randi_range(0, candidates.size() - 1)]


# Standalone entry point, called directly (not via the turn queue) by
# flee()'s failed-flee parting shot and by tests driving an enemy's attack
# in isolation -- "the acting enemy" is always index 0 here. Doesn't emit
# state_changed itself; every caller owns that.
static func enemy_attack() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	var beats: Array = []
	if combat["outcome"] != null or combat["frozenTurns"] > 0:
		return { "beats": beats }
	_resolve_enemy_attack(combat, combat["enemies"][0], 0, beats)
	return { "beats": beats }


static func _resolve_enemy_attack(combat: Dictionary, enemy: Dictionary, enemy_index: int = 0, beats: Variant = null) -> void:
	var target_index: int = _pick_enemy_target(combat)
	if target_index == -1:
		_enemy_attack_player(combat, enemy, enemy_index, beats)
	else:
		_enemy_attack_ally(combat, enemy, combat["allies"][target_index], target_index, enemy_index, beats)


# One atomic enemy turn: ability-lock/frozen bookkeeping runs at this
# enemy's own queue slot. A frozen turn is a no-op-plus-decrement -- the
# entry is still walked, it just doesn't attack.
static func _enemy_turn(combat: Dictionary, enemy: Dictionary, enemy_index: int, beats: Variant = null) -> void:
	if is_ability_locked(enemy):
		enemy["ability"]["lockedTurns"] -= 1
		if enemy["ability"]["lockedTurns"] == 0:
			_log(combat, beats, "%s's ability is back online." % enemy["name"], BEAT_ABILITY_UNLOCKED,
				{ "actorType": "enemy", "actorIndex": enemy_index })

	if combat["frozenTurns"] > 0:
		combat["frozenTurns"] -= 1
		if combat["frozenTurns"] == 0:
			_log(combat, beats, "The time effect wears off. They're coming back round.", BEAT_FROZEN_WEARS_OFF,
				{ "actorType": "enemy", "actorIndex": enemy_index })
		return

	_resolve_enemy_attack(combat, enemy, enemy_index, beats)


static func _enemy_attack_player(combat: Dictionary, enemy: Dictionary, enemy_index: int = 0, beats: Variant = null) -> void:
	if combat["evadeTurns"] > 0:
		combat["evadeTurns"] -= 1
		if Rng.chance(combat["evadeChance"]):
			var evade_note: String
			if combat["evadeTurns"] > 0:
				evade_note = "%d evade turn%s left." % [combat["evadeTurns"], "" if combat["evadeTurns"] == 1 else "s"]
			else:
				evade_note = "Evade fades."
			_log(combat, beats, "%s swings — you're not there. %s" % [enemy["name"], evade_note], BEAT_PLAYER_EVADE,
				{ "actorType": "enemy", "actorIndex": enemy_index, "targetType": "player" })
			return

	var atk := get_enemy_attack_range(enemy)
	var dmg: int = Rng.randi_range(atk["min"], atk["max"])
	var player: Dictionary = GameState.state["player"]

	# Shield absorbs 1:1 out of player.shieldPool before HP takes anything --
	# dmg <= pool drains the pool for zero damage, dmg > pool passes the
	# remainder through.
	var shield_note := ""
	var absorbed := 0
	if player["shieldPool"] > 0:
		absorbed = mini(dmg, player["shieldPool"])
		player["shieldPool"] -= absorbed
		dmg -= absorbed
		if absorbed > 0:
			shield_note = " (%d absorbed by shield)" % absorbed

	player["hp"] = maxi(0, player["hp"] - dmg)
	var beat_extra: Dictionary = { "actorType": "enemy", "actorIndex": enemy_index, "targetType": "player", "dmg": dmg }
	if absorbed > 0:
		# Shield cracks on each absorb, carried independently of `dmg`
		# (0 on a full absorb) so the crack still plays.
		beat_extra["shieldAbsorbed"] = absorbed
	_log(combat, beats, "%s hits you for %d%s. You: %d/%d HP." % [enemy["name"], dmg, shield_note, player["hp"], player["hpMax"]], BEAT_ENEMY_ATTACK, beat_extra)
	if player["hp"] <= 0:
		# A failsafe/rewind trigger rewrites combat.log wholesale, so this
		# path deliberately stays un-beaten -- rewind-as-animation is its
		# own, separate mechanism, not this linear beat queue.
		if _try_failsafe(combat, player):
			return
		combat["outcome"] = "loss"
		_log(combat, beats, "You're done. You come round somewhere unpleasant.", BEAT_COMBAT_LOSS, {})
		player["hp"] = GameState.round_epsilon(player["hpMax"] * 0.3)


# No shield/evade/failsafe -- those are player-only resources. KO sets
# the `koed` flag Combat's loops already check, and starts the contact's
# persistent cooldown via Contacts.knock_out().
static func _enemy_attack_ally(combat: Dictionary, enemy: Dictionary, ally: Dictionary, ally_index: int, enemy_index: int = 0, beats: Variant = null) -> void:
	var atk := get_enemy_attack_range(enemy)
	var dmg: int = Rng.randi_range(atk["min"], atk["max"])
	ally["hp"] = maxi(0, ally["hp"] - dmg)
	_log(combat, beats, "%s hits %s for %d. %s: %d/%d HP." % [enemy["name"], ally["name"], dmg, ally["name"], ally["hp"], ally["hpMax"]], BEAT_ENEMY_ATTACK,
		{ "actorType": "enemy", "actorIndex": enemy_index, "targetType": "ally", "targetIndex": ally_index, "dmg": dmg })
	if ally["hp"] <= 0:
		ally["koed"] = true
		_clamp_selection(combat)
		_log(combat, beats, "%s is knocked out of the fight." % ally["name"], BEAT_ALLY_KO,
			{ "targetType": "ally", "targetIndex": ally_index })
		Contacts.knock_out(ally["contactId"], GameState.state["world"]["day"])


# Also returns `beats`, same shape as player_attack()'s -- the failed-flee
# parting shot's own returned beats are appended onto this call's. Leg it
# resolves the cursor's parked player-type entry exactly like Attack does
# (R§3.7a): a snapshot per attempt, then the engine runs forward afterward.
static func flee() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "outcome": combat["outcome"], "beats": beats }

	push_combat_snapshot()

	# Blast's one-use flee boost, read defensively and cleared here
	# regardless of the roll's outcome, so it never survives past the next
	# attempt.
	var flee_chance := 0.65
	if combat.get("blastFleeBoost", false):
		flee_chance = BLAST_FLEE_BOOST_CHANCE
		combat["blastFleeBoost"] = false

	if Rng.chance(flee_chance):
		combat["outcome"] = "fled"
		_log(combat, beats, "You back off sharpish. Probably the right call.", BEAT_FLEE_SUCCESS, {})
	else:
		_log(combat, beats, "You try to leg it — they get a parting shot in.", BEAT_FLEE_FAILED, {})
		var parting_shot: Dictionary = enemy_attack()
		beats.append_array(parting_shot.get("beats", []))

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "outcome": combat["outcome"], "beats": beats }


static func use_time_pearl() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("timePearl") <= 0:
		return { "ok": false, "reason": "No time pearls." }
	if combat["frozenTurns"] > 0:
		combat["log"].append("Already frozen. Save the pearl.")
		EventBus.state_changed.emit()
		return { "ok": false, "reason": "Already frozen." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	Crafting.inventory_remove("timePearl", 1)
	var power = Crafting.effect_power("timePearl", player["craftingSkill"])
	combat["frozenTurns"] += power
	var turn_word: String = "turn" if power == 1 else "turns"
	_log(combat, beats, "You throw a time pearl. The air goes thick. Everything slows. (%d %s)" % [power, turn_word], BEAT_USE_TIME_PEARL, { "effectKey": "timePearl" })

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


static func use_enhancement_powder() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("enhancementPowder") <= 0:
		return { "ok": false, "reason": "No enhancement powder." }
	if combat["motionTurns"] > 0:
		combat["log"].append("Already moving fast. Wait for it to wear off.")
		EventBus.state_changed.emit()
		return { "ok": false, "reason": "Already moving fast." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	Crafting.inventory_remove("enhancementPowder", 1)
	var power = Crafting.effect_power("enhancementPowder", player["craftingSkill"])
	combat["motionPower"] = power
	combat["motionTurns"] = 2 if power >= 3 else 1
	# No effectKey/manifest sheet -- the afterimage trail is a duplicate-sprite
	# alpha ramp the screen triggers off combat.motionTurns during subsequent
	# BEAT_PLAYER_ATTACK beats, not off this activation beat. The current
	# round's queue is already fixed (R§3.7a) -- the extra attacks land
	# starting next round, not this one.
	_log(combat, beats, "You rub the powder in. The world slows slightly around you. You feel very fast.", BEAT_USE_MOTION, {})

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# Immediate damage, a one-use boost to the next flee() roll, and a small
# chance to disarm the enemy via disarm_enemy(). Resolves the cursor's
# parked player-type entry, same as every other combat command (R§3.7a).
static func use_blast() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("blast") <= 0:
		return { "ok": false, "reason": "No blast." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	Crafting.inventory_remove("blast", 1)
	var power = Crafting.effect_power("blast", player["craftingSkill"])
	var enemy: Dictionary = _focused_enemy(combat)
	var target_index: int = _enemy_action_index(combat)
	enemy["hp"] = maxi(0, enemy["hp"] - power)
	_log(combat, beats, "You let off a blast — %d damage. Enemy: %d/%d HP." % [power, enemy["hp"], enemy["hpMax"]], BEAT_USE_BLAST,
		{ "targetType": "enemy", "targetIndex": target_index, "dmg": power, "effectKey": "blast" })
	combat["blastFleeBoost"] = true

	if Rng.chance(BLAST_DISARM_CHANCE):
		disarm_enemy(enemy, BLAST_DISARM_TURNS)
		_log(combat, beats, "The shove knocks their weapon loose.", BEAT_USE_DISARM, { "targetType": "enemy", "targetIndex": target_index })

	_maybe_win_from_direct_damage(combat, enemy, beats)

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# Sets player.shieldPool, drained 1:1 by enemy_attack() above. Blocked
# while a pool is still active, same guard shape as use_time_pearl()'s.
static func use_shield() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("shield") <= 0:
		return { "ok": false, "reason": "No shield." }
	if player["shieldPool"] > 0:
		combat["log"].append("Shield's already up. Save it.")
		EventBus.state_changed.emit()
		return { "ok": false, "reason": "Shield already active." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	Crafting.inventory_remove("shield", 1)
	var power = Crafting.effect_power("shield", player["craftingSkill"])
	player["shieldPool"] = power
	_log(combat, beats, "A shimmer folds around you. Shield up — %d absorption." % power, BEAT_USE_SHIELD, { "effectKey": "shield" })

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# Black Hole is the one AoE effect (R§3.7a): hits every non-koed enemy
# independently at full, un-diluted power. frozenTurns is one shared pool
# across the fight, so N enemies hit adds freeze_turns once per enemy, not
# once total. Each hit gets its own log line + beat, so the juice layer
# can play an effect per enemy in the fan, sequentially.
static func _apply_black_hole_aoe(combat: Dictionary, dmg: int, freeze_turns: int, beats: Variant = null) -> void:
	for i in range(combat["enemies"].size()):
		var enemy: Dictionary = combat["enemies"][i]
		if enemy["koed"]:
			continue
		enemy["hp"] = maxi(0, enemy["hp"] - dmg)
		combat["frozenTurns"] += freeze_turns
		_log(combat, beats, "%s takes %d damage, frozen %d turn(s). %s: %d/%d HP." % [enemy["name"], dmg, freeze_turns, enemy["name"], enemy["hp"], enemy["hpMax"]], BEAT_COMPLICATION_BLACK_HOLE_HIT,
			{ "targetType": "enemy", "targetIndex": i, "dmg": dmg, "effectKey": "blackHole" })
		_maybe_win_from_direct_damage(combat, enemy, beats)


# Immediate damage plus frozenTurns, always additive regardless of source
# (stacks with Time Pearl or a prior Black Hole) -- no reuse guard. Turn
# count derives from effectPower, not a separate recipe schema field.
static func use_black_hole() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("blackHole") <= 0:
		return { "ok": false, "reason": "No black hole." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	Crafting.inventory_remove("blackHole", 1)
	var power = Crafting.effect_power("blackHole", player["craftingSkill"])
	var freeze_turns: int = 1 + int(floor(float(power) / 8.0))
	# Per-enemy hit beats (via _apply_black_hole_aoe(), the same shared helper
	# cast_complication() uses) replace a single combined summary line.
	_log(combat, beats, "You drop a black hole.", BEAT_USE_BLACK_HOLE_ANNOUNCE, {})
	_apply_black_hole_aoe(combat, power, freeze_turns, beats)

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# Shared by player_attack/use_blast/use_black_hole -- all three can deal a
# lethal hit and need the same koed-flagging/win-check afterward. hp
# hitting 0 flags that entry koed and auto-clamps selection off a dead
# target; the fight ends only once every entry in combat.enemies is koed.
static func _maybe_win_from_direct_damage(combat: Dictionary, enemy: Dictionary, beats: Variant = null) -> void:
	if enemy["hp"] > 0:
		return
	enemy["koed"] = true
	_clamp_selection(combat)
	if not _all_enemies_koed(combat["enemies"]):
		return
	combat["outcome"] = "win"
	var line: String = "They leg it. Good call on their part." if NON_LETHAL_MUGGING_CONTEXTS.has(combat["context"]) else "They go down. Vein is yours."
	_log(combat, beats, line, BEAT_COMBAT_WIN, {})
	_dispatch_on_win()


static func _all_enemies_koed(enemies: Array) -> bool:
	for enemy in enemies:
		if not enemy["koed"]:
			return false
	return true


# Keeps combat.selection pointed at a living entry after a kill/KO -- a
# no-op when the currently-selected entry is still alive. R§2's KO-clamp
# rule: same-type first (next living ally/enemy in array order), else
# fall back to the next living enemy; never fires for type "player".
static func _clamp_selection(combat: Dictionary) -> void:
	var selection: Dictionary = combat["selection"]
	if selection["type"] == "player":
		return
	var roster: Array = combat["allies"] if selection["type"] == "ally" else combat["enemies"]
	var idx: int = selection["index"]
	if idx < roster.size() and not roster[idx]["koed"]:
		return
	for i in range(roster.size()):
		if not roster[i]["koed"]:
			combat["selection"] = { "type": selection["type"], "index": i }
			return
	for i in range(combat["enemies"].size()):
		if not combat["enemies"][i]["koed"]:
			combat["selection"] = { "type": "enemy", "index": i }
			return


# Grants the same evadeTurns/evadeChance fields Rewind grants (R§3.9) --
# activating this while Rewind's grant is still active simply overwrites
# both, no stacking or reconciliation.
static func use_prophets_breath() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("prophetsBreath") <= 0:
		return { "ok": false, "reason": "No prophet's breath." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	Crafting.inventory_remove("prophetsBreath", 1)
	var power = Crafting.effect_power("prophetsBreath", player["craftingSkill"])
	combat["evadeTurns"] = power
	combat["evadeChance"] = 0.50
	combat["log"].append("You take a lungful. For a few seconds, you can see it coming.")

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# Wormhole's combat half: guarantees flee()'s escape outright rather than
# boosting its roll (contrast Blast's blastFleeBoost, which still rolls).
# The map-travel half lives in Travel.travel_via_wormhole().
static func use_wormhole() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	if Crafting.inventory_qty("wormhole") <= 0:
		return { "ok": false, "reason": "No wormhole." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	Crafting.inventory_remove("wormhole", 1)
	combat["outcome"] = "fled"
	_log(combat, beats, "You fold the space between you and gone. Clean exit -- no parting shot.", BEAT_USE_WORMHOLE, { "actorType": "player" })

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# Casts a loaded Complication by its player.dial.loadedComplications index.
# "rewind" is refused here (cast via combat_rewind()'s own fallback
# instead). Every "already active" guard below runs before
# Dial.cast_complication() spends a charge -- a blocked cast never costs one.
static func cast_complication(index: int) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }

	var player: Dictionary = GameState.state["player"]
	var dial: Variant = player["dial"]
	if dial == null:
		return { "ok": false, "reason": "No Dial." }
	var loaded: Array = dial["loadedComplications"]
	if index < 0 or index >= loaded.size():
		return { "ok": false, "reason": "No such Complication." }

	var recipe_key: String = loaded[index]["recipeKey"]
	if recipe_key == "rewind":
		return { "ok": false, "reason": "Use Rewind for a rewind unit." }
	if not COMBAT_COMPLICATION_RECIPES.has(recipe_key):
		return { "ok": false, "reason": "No combat effect for that unit." }

	if recipe_key == "timePearl" and combat["frozenTurns"] > 0:
		combat["log"].append("Already frozen. Save the charge.")
		EventBus.state_changed.emit()
		return { "ok": false, "reason": "Already frozen." }
	if recipe_key == "enhancementPowder" and combat["motionTurns"] > 0:
		combat["log"].append("Already moving fast. Wait for it to wear off.")
		EventBus.state_changed.emit()
		return { "ok": false, "reason": "Already moving fast." }
	if recipe_key == "shield" and player["shieldPool"] > 0:
		combat["log"].append("Shield's already up. Save it.")
		EventBus.state_changed.emit()
		return { "ok": false, "reason": "Shield already active." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "outcome": combat["outcome"], "beats": beats }

	var cast: Dictionary = Dial.cast_complication(index)
	if not cast["ok"]:
		return cast
	push_combat_snapshot()

	var power = cast["power"]
	var targets: int = cast["targets"]
	var recipe: Dictionary = GameData.RECIPES[recipe_key]
	var enemy: Dictionary = _focused_enemy(combat)

	# targets > 1 (a tier-indexed Spread Movement) has no per-target dilution
	# by design -- for blast (single-target) this repeats the effect at
	# full power `targets` times. blackHole folds `targets` into its
	# per-enemy power/freeze instead. blast/blackHole are the only branches
	# that set a `dmg` field on their beats -- the juice layer keys off that.
	match recipe_key:
		"timePearl":
			var total: int = int(power) * targets
			combat["frozenTurns"] += total
			var turn_word: String = "turn" if total == 1 else "turns"
			_log(combat, beats, "You trigger %s. Enemy frozen for %d %s." % [recipe["name"], total, turn_word], BEAT_COMPLICATION_TIME_PEARL, { "effectKey": "timePearl" })
		"enhancementPowder":
			combat["motionPower"] = power
			combat["motionTurns"] = 2 if power >= 3 else 1
			_log(combat, beats, "You trigger %s. Movement accelerated." % recipe["name"], BEAT_COMPLICATION_MOTION, {})
		"blast":
			var dmg: int = int(power) * targets
			var target_index: int = _enemy_action_index(combat)
			enemy["hp"] = maxi(0, enemy["hp"] - dmg)
			_log(combat, beats, "You trigger %s — %d damage. Enemy: %d/%d HP." % [recipe["name"], dmg, enemy["hp"], enemy["hpMax"]], BEAT_COMPLICATION_BLAST,
				{ "targetType": "enemy", "targetIndex": target_index, "dmg": dmg, "effectKey": "blast" })
			combat["blastFleeBoost"] = true
			if Rng.chance(BLAST_DISARM_CHANCE):
				disarm_enemy(enemy, BLAST_DISARM_TURNS)
				_log(combat, beats, "The shove knocks their weapon loose.", BEAT_COMPLICATION_DISARM, { "targetType": "enemy", "targetIndex": target_index })
			_maybe_win_from_direct_damage(combat, enemy, beats)
		"shield":
			player["shieldPool"] += int(power) * targets
			_log(combat, beats, "You trigger %s. Shield up — %d absorption." % [recipe["name"], player["shieldPool"]], BEAT_COMPLICATION_SHIELD, { "effectKey": "shield" })
		"blackHole":
			# AoE, ignores selection -- hits every non-koed enemy
			# independently at full power, same as use_black_hole() above.
			var dmg: int = int(power) * targets
			var freeze_turns: int = (1 + int(floor(float(power) / 8.0))) * targets
			_log(combat, beats, "You trigger %s." % recipe["name"], BEAT_COMPLICATION_BLACK_HOLE_ANNOUNCE, {})
			_apply_black_hole_aoe(combat, dmg, freeze_turns, beats)
		"healingBurst":
			var old_hp: int = player["hp"]
			player["hp"] = mini(player["hp"] + int(power) * targets, player["hpMax"])
			var healed: int = player["hp"] - old_hp
			_log(combat, beats, "You trigger %s — +%d HP. %d/%d HP." % [recipe["name"], healed, player["hp"], player["hpMax"]], BEAT_COMPLICATION_HEALING_BURST, { "effectKey": "healingBurst" })
		"prophetsBreath":
			combat["evadeTurns"] = int(power) * targets
			combat["evadeChance"] = 0.50
			_log(combat, beats, "You trigger %s. For a few seconds, you can see it coming." % recipe["name"], BEAT_COMPLICATION_PROPHETS_BREATH, {})
		"wormhole":
			combat["outcome"] = "fled"
			_log(combat, beats, "You trigger %s. You fold the space between you and gone." % recipe["name"], BEAT_COMPLICATION_WORMHOLE, { "actorType": "player" })

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "recipeKey": recipe_key, "power": power, "targets": targets, "beats": beats }


static func combat_rewind() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["snapshots"].is_empty():
		return { "ok": false, "reason": "Nothing to rewind." }

	var player: Dictionary = GameState.state["player"]
	var has_consumable: bool = Crafting.inventory_qty("rewind") > 0
	var rewind_index: int = Dial.find_loaded_rewind_complication_index()
	var has_complication: bool = rewind_index >= 0

	if not has_consumable and not has_complication:
		return { "ok": false, "reason": "No rewind available." }

	if has_consumable:
		Crafting.inventory_remove("rewind", 1)
	else:
		Dial.cast_complication(rewind_index)

	# Rewind/failsafe plays the beat queue in reverse. Captured before
	# _restore_from_snapshot() clears combat.beatsSinceSnapshot -- purely
	# cosmetic, GameState is already restored by playback time.
	var replay_beats: Array = combat["beatsSinceSnapshot"].duplicate()
	replay_beats.reverse()

	_restore_from_snapshot(combat, player)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": replay_beats }


# The actual snapshot-restore mechanics, shared by combat_rewind() and
# _try_failsafe(). Neither the availability guard nor the resource
# deduction lives here; each caller owns its own.
static func _restore_from_snapshot(combat: Dictionary, player: Dictionary) -> void:
	var snap: Dictionary = Snapshots.oldest(combat["snapshots"])
	Snapshots.clear(combat["snapshots"])

	player["hp"] = snap["playerHp"]
	# R§2: restores whoever/whatever was selected at the snapshotted decision
	# point (player, ally or enemy), not just an enemy index.
	combat["selection"] = snap["selection"].duplicate()
	# koed is kept in lockstep with hp -- a rewound snapshot's hp is always
	# pre-lethal in practice, but this keeps the invariant true regardless.
	var focused_enemy: Dictionary = combat["enemies"][snap["enemyIndex"]]
	focused_enemy["hp"] = snap["enemyHp"]
	focused_enemy["koed"] = focused_enemy["hp"] <= 0
	var new_log: Array = snap["log"].duplicate()
	new_log.append("⟲ Time unspools. The moment resets. Only you remember.")
	combat["log"] = new_log
	combat["frozenTurns"] = snap["frozenTurns"]
	combat["motionTurns"] = snap["motionTurns"]
	combat["motionPower"] = snap["motionPower"]
	combat["outcome"] = null
	combat["evadeTurns"] = 2
	combat["evadeChance"] = 0.50
	# R§3.7a: restores the cursor to the same parked player-type entry the
	# snapshot was pushed in front of -- a coherent decision point to resume.
	combat["turnCursor"] = snap["turnCursor"].duplicate()
	# The accumulator combat_rewind()/_try_failsafe() read for their "beat
	# queue in reverse" replay -- cleared here after combat_rewind() already
	# captured its own copy, so accumulation restarts from this state.
	combat["beatsSinceSnapshot"] = []


# Checked the moment the player's hp would hit 0, before "loss" resolves
# -- a separate resource from Rewind, tried automatically. Requires a
# snapshot to restore to; with none available the loss proceeds normally.
static func _try_failsafe(combat: Dictionary, player: Dictionary) -> bool:
	if Crafting.inventory_qty("failsafe") <= 0:
		return false
	if combat["snapshots"].is_empty():
		return false

	Crafting.inventory_remove("failsafe", 1)
	# Unlike combat_rewind(), this skips the reverse-replay capture -- it
	# fires synchronously mid-round, and a second reverse playback would
	# race the enclosing round's forward one. GameState is still fully
	# restored; only the cosmetic animation is skipped.
	_restore_from_snapshot(combat, player)
	combat["log"].append("⚑ Failsafe fires. Death, reversed -- administratively.")
	return true



static func _dispatch_on_win() -> void:
	var combat: Dictionary = GameState.state["combat"]
	var on_win: String = combat.get("onWin", "")
	match on_win:
		"muggingWon":
			Economy.complete_mugged_sale()
		"raidWon":
			_raid_won()
		"homeRaidWon":
			GameState.state["flags"]["homeRaidWon"] = true
			GameState.state["flags"]["homeRaidEventSeen"] = true
		_:
			pass


static func _raid_won() -> void:
	# M0 has no NPC-claimed-vein storage (M1's prospecting/sites system) --
	# nothing to transfer yet. Kept as a documented no-op so onWin dispatch
	# stays wireable once M1 lands (R§3.7).
	pass


# Tears down combat state and routes to the next screen (R§3.7): mugging-
# win leaves the screen alone; home_raid routes into the matching debrief
# event (R§3.8); event_raid resumes the still-active event on a win, ends
# it on a loss; otherwise phone home, bag drawer opened on a raid win.
static func exit_combat() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	var outcome = combat["outcome"]
	var context: String = combat["context"]

	# Hand any allies' ending hp/stash back to persistent contact state
	# before the combat dict is torn down below.
	Contacts.replenish_after_combat(combat["allies"])

	GameState.state["combat"] = {
		"active": false, "context": CONTEXT_RAID, "veinId": null, "enemies": [],
		"selection": { "type": "enemy", "index": 0 }, "log": [],
		"outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": null, "snapshots": [],
		"allies": [],
		"beatsSinceSnapshot": [],
		"turnCursor": { "queue": [], "index": 0, "round": 0 },
	}
	SaveManager.autosave()  # R§6: autosave on combat exit
	# The per-context handlers below only emit screen_changed (some emit
	# nothing) -- top_bar.gd's merged board needs state_changed specifically
	# to know combat.active flipped false, so guarantee it fires here.
	EventBus.state_changed.emit()

	if context == CONTEXT_MUGGING and outcome == "win":
		return _exit_mugging_win()
	if context == CONTEXT_ARCHIE_DEAL_MUGGING:
		return _exit_archie_deal_mugging(outcome)
	if context == CONTEXT_EVENT_MUGGING:
		return _exit_event_mugging()
	if context == CONTEXT_HOME_RAID:
		return _exit_home_raid(outcome)
	if context == CONTEXT_HOME_ALARM_DEFEND:
		return _exit_home_alarm_defend(outcome)
	if context == CONTEXT_EVENT_RAID:
		return _exit_event_raid(outcome)
	if context == CONTEXT_DEFEND_VEIN:
		return _exit_defend_vein(outcome)
	return _exit_default(outcome, context)


static func _exit_mugging_win() -> Dictionary:
	return { "nextScreen": null }


# ArchieDeals.resolve_mugging() handles both outcomes (paying out on a
# win, clearing archieDealActive either way) -- a win stays put (its modal
# is already visible), a loss routes home immediately.
static func _exit_archie_deal_mugging(outcome) -> Dictionary:
	ArchieDeals.resolve_mugging(outcome == "win")
	if outcome == "win":
		return { "nextScreen": null }
	_route_phone_home()
	return { "nextScreen": "phone" }


# event_mugging (D5): state.event is still active regardless of outcome
# — route back to the event screen so its scripted cards can resume.
static func _exit_event_mugging() -> Dictionary:
	GameState.state["currentScreen"] = "event"
	EventBus.screen_changed.emit("event")
	return { "nextScreen": "event" }


# Every "route home" destination below is the phone app grid. Hand-rolled
# rather than PhoneNav.route_home(): exit_combat() already guarantees one
# state_changed emit, so route_home() would fire a redundant second one.
static func _route_phone_home() -> void:
	GameState.state["currentScreen"] = "phone"
	EventBus.screen_changed.emit("phone")
	PhoneNav.go_home()


static func _exit_home_raid(outcome) -> Dictionary:
	_after_home_raid_combat(outcome)
	var debrief_id: String = "home_raid_debrief_win" if outcome == "win" else "home_raid_debrief_loss"
	Events.start_event(debrief_id)
	return { "nextScreen": "event" }


# Home owns the consequence (nothing on a win, the undefended-raid loss
# otherwise); no debrief event either way, routes home.
static func _exit_home_alarm_defend(outcome) -> Dictionary:
	Home.resolve_defend_outcome(outcome == "win")
	_route_phone_home()
	return { "nextScreen": "phone" }


# A raid event card's "caught" branch, via start_raid(..., "event_raid").
# A win resumes the still-active event, same event_mugging shape above,
# still on cardIndex from before combat interrupted it. A loss fails the
# raid outright -- the event is cleared and the player goes home.
static func _exit_event_raid(outcome) -> Dictionary:
	if outcome == "win":
		GameState.state["currentScreen"] = "event"
		EventBus.screen_changed.emit("event")
		return { "nextScreen": "event" }
	GameState.state["event"] = null
	_route_phone_home()
	return { "nextScreen": "phone" }


# Raiding owns the win/loss consequence (nothing on a win, the same
# whole-vein-loss transfer as the no-alarm path on a loss) -- this just
# tells it which happened, then routes home either way.
static func _exit_defend_vein(outcome) -> Dictionary:
	Raiding.resolve_defend_outcome(outcome == "win")
	_route_phone_home()
	return { "nextScreen": "phone" }


# A raid win opens the bag drawer over the phone home grid so the loot is
# immediately visible.
static func _exit_default(outcome, context: String) -> Dictionary:
	_route_phone_home()
	if outcome == "win" and context == CONTEXT_RAID:
		Bag.open()
	return { "nextScreen": "phone" }


# R§3.8: on loss, carried orichalchum is halved (floor). Only one pool
# (player.orichalchum) to lose -- see systems/home.gd.
static func _after_home_raid_combat(outcome) -> void:
	if outcome == "win":
		return

	GameState.state["flags"]["homeRaidWon"] = false
	GameState.state["flags"]["homeRaidEventSeen"] = true

	var player: Dictionary = GameState.state["player"]
	var lost := 0

	for ore_type in player["orichalchum"].keys():
		var qty: int = player["orichalchum"][ore_type]
		var take: int = int(floor(qty * 0.5))
		player["orichalchum"][ore_type] = maxi(0, qty - take)
		lost += take

	if lost > 0:
		Notify.push("The raider took %d units of ore before fleeing." % lost, Notify.CATEGORY_DANGER)


# ── Train (R§3.7a) ───────────────────────────────────────────────────────
# HQ action, always available -- a bodyweight workout awards the lower
# flat XP; once Home Gym is built the same action awards the larger
# amount instead. No separate cooldown: spending a time block is it.

static func train() -> Dictionary:
	if TimeSystem.is_time_exhausted():
		return { "ok": false, "reason": "No time blocks left today." }

	var has_gym: bool = GameState.state["home"]["rooms"].has("homeGym")
	TimeSystem.advance_time_block()
	award_xp(COMBAT_XP_PER_GYM_SESSION if has_gym else COMBAT_XP_PER_WORKOUT_SESSION)
	if has_gym:
		Notify.push("A session on the bar and the bag. You feel it tomorrow.", Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Press-ups and shadow boxing on the flat floor. You feel it tomorrow.", Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	return { "ok": true }
