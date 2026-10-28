class_name CombatRounds
extends RefCounted

# The Open/Guarded round rules (R§3.7b), on whichever pure-data combat dict
# it is passed, RNG streams included; live Combat drives it on state.combat.
#
# A fight is open_fight() on a dict holding its combatants (new_combatant()),
# then one play_pick() per player decision point (R§3.7b Round). Combatants
# live in one array, the player at index 0, then allies, then enemies, so
# array order is the timeline's last tie-break. Each enemy holds this
# round's committed plan and next round's pre-rolled one; each ally holds
# this round's plan, planned by the ally AI from the enemies' plans. The
# round resolves in timeline order from the cursor and pauses at each of the
# player's positions; the pick there goes into playerPlan and resolves.
# Randomness runs off the fight's own RNG state (rngState), so a Rewind
# (rewind_pick()) replays the same rolls for the same pick. Fog of war marks
# each enemy action read or unread as its plan is rolled, off a separate
# stream (fogRngState), so the fog never shifts the fight's rolls.

const SIDE_PLAYER := "player"
const SIDE_ALLY := "ally"
const SIDE_ENEMY := "enemy"

const GUARDED := "guarded"
const OPEN := "open"
const UNCHANGED := "unchanged"
const GUARD_EFFECTS: Array[String] = [GUARDED, OPEN, UNCHANGED]
# guard_preview()'s state for an enemy after an unread action.
const UNKNOWN := "unknown"
# Salts the fight seed into the fog stream's seed.
const FOG_SEED_SALT := 0x5F0C0F06
# The move-level rolls' own RNG off the fight seed (_roll_move_levels()).
const MOVE_LEVEL_SEED_SALT := 0x30E1E7E1
# An action whose first beat is one of these fizzled, for move XP: a Stun
# on a Guarded target, an evaded Strike, a failed Leg it.
const FIZZLE_KINDS: Array[String] = ["fizzle", "evade", "fleeFailed"]

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
const EFFECT_FLEE := "flee"
const EFFECTS: Array[String] = [EFFECT_NONE, EFFECT_DAMAGE, EFFECT_OPEN, EFFECT_STUN, EFFECT_FLEE]

# Item effects (R§3.7b Items), keyed from the data's items
# table; each reads its power from the recipe's effectPower at the slot's tier.
const ITEM_FREEZE := "freeze"
const ITEM_BLACK_HOLE := "blackHole"
const ITEM_BLAST := "blast"
const ITEM_SHIELD := "shield"
const ITEM_HEAL := "heal"
const ITEM_POWDER := "powder"
const ITEM_SIGHT := "sight"
const ITEM_LADY := "lady"
const ITEM_PANIC := "panic"
const ITEM_RAPTURE := "rapture"
const ITEM_ANGER := "anger"
const ITEM_FURY := "fury"
const ITEM_WORMHOLE := "wormhole"
const ITEM_EFFECTS: Array[String] = [ITEM_FREEZE, ITEM_BLACK_HOLE, ITEM_BLAST, ITEM_SHIELD, ITEM_HEAL, ITEM_POWDER, ITEM_SIGHT, ITEM_LADY, ITEM_PANIC, ITEM_RAPTURE, ITEM_ANGER, ITEM_FURY, ITEM_WORMHOLE]
# The Pan family (R§3.7b Table 4): an enemy holds one of their statuses at a
# time and refuses another while it runs.
const PAN_EFFECTS: Array[String] = [ITEM_PANIC, ITEM_RAPTURE, ITEM_ANGER, ITEM_FURY]
const REASON_PAN_STATUSED := "Already out of it."
const REASON_NO_CHARGE := "Not enough charge."
# The turns Panic and Pan's Rapture play in place of an enemy's own actions
# (the data's statusTurns).
const STATUS_PANIC := "panic"
const STATUS_RAPTURE := "rapture"

# The shared kit pools a live fight keeps on its combat dict, each
# { items, used, reserved } by recipe then tier (R§3.7b Table 5): a
# raider kit for the enemies, a guard kit for guard allies. A combatant's
# "kit" names the pool it plans from ("" for none).
const KIT_RAIDER := "raiderKit"
const KIT_GUARD := "guardKit"
const KIT_POOLS: Array[String] = [KIT_RAIDER, KIT_GUARD]
const KIT_HEAL := "healingBurst"
const KIT_SIGHT := "prophetsBreath"
const KIT_SHIELD := "shield"
const KIT_BLAST := "blast"
const KIT_POWDER := "enhancementPowder"
# The guard kit's crowd items, in rule order.
const KIT_CROWD: Array[String] = ["blackHole", "timePearl"]
# The ally's own reactive save (R§3.7b Rewind): never planned, so no round
# item, but a kit or recruit slot can hold it.
const FAILSAFE := "failsafe"

# Move conditions: null (always) or CONDITION_TARGET_OPEN (fizzles on a
# Guarded target).
const CONDITION_TARGET_OPEN := "targetOpen"
const CONDITIONS: Array[String] = [CONDITION_TARGET_OPEN]

const PLAYER_INDEX := 0
# Squad cap: 0-2 active allies (R§3.7b Combatants).
const MAX_ALLIES := 2
# Active fighters per side, the player counting on theirs (R§3.7a
# Reinforcements).
const SQUAD_SIZE := MAX_ALLIES + 1
const QUEUE_KEYS := { SIDE_ALLY: "allyQueue", SIDE_ENEMY: "enemyQueue" }
# The live roster an entrant's queue entry joins, where the fight keeps one.
const ROSTER_KEYS := { SIDE_ALLY: "allies", SIDE_ENEMY: "enemies" }

# A timed effect's end round that no fight reaches (carry_in()).
const WHOLE_FIGHT := 1 << 30

# A scripted fight's phases (R§3.7b Scripted fights).
const SCRIPT_PRE := "pre"
const SCRIPT_POST := "post"
# A script with no Rewind lock: a normal fight on fixed plans throughout.
const SCRIPT_OPEN := "open"

# What a demo fight's blocked picks and Rewind say.
const DEMO_REASON := "Just watch."


# The moves the ally AI plans with (R§3.7b Round); GameData checks they exist.
const MOVE_GUARD := "guard"
const MOVE_STRIKE := "strike"
const MOVE_FEINT := "feint"
const ALLY_AI_MOVES: Array[String] = [MOVE_GUARD, MOVE_STRIKE, MOVE_FEINT]


static func _data() -> Dictionary:
	return GameData.COMBAT_ROUNDS


static func new_state() -> Dictionary:
	return {
		"active": false,
		"round": 0,
		# null while the fight runs, then "win", "loss" or "fled".
		"outcome": null,
		# Player at PLAYER_INDEX, then allies, then enemies (new_combatant()).
		"combatants": [],
		# The player's picks this round: one entry per position, each null
		# (not picked yet, or lost) or { move, target, part } (plus slot for
		# an item). A move costing n actions fills n positions in a row from
		# one pick, parts 0..n-1.
		"playerPlan": [],
		# Where this round's resolution has got to (see _new_cursor()).
		"cursor": _new_cursor(),
		"rngState": 0,
		# Whether enemy actions can be unread (the sim switches it off), and
		# the fog rolls' own RNG state.
		"fog": true,
		"fogRngState": 0,
		# Every resolved beat so far, oldest first (see _beat()).
		"log": [],
		# The fight's play-by-play, oldest first: the opening lines, each
		# beat's text as it's logged, and the Rewind/Failsafe lines.
		"transcript": [],
		"snapshots": [],
		# Round-start frames for a tiered Rewind (push_round_frame()): the
		# opening frame, then one per round's first decision point.
		"roundFrames": [],
		# The stage backdrop: the fight's context and a locationKey (the
		# combat_visuals locationBackdrops plate; "" for none).
		"backdrop": { "context": "", "locationKey": "" },
		# Reinforcements waiting per side (R§3.7b): entries each carrying its
		# prebuilt combatant under "fighter" (_admit_reserves()).
		"enemyQueue": [], "allyQueue": [],
		# Set once the player's KO stands and the fight plays on without them
		# (continue_after_ko()).
		"playerKoed": false,
		# The event fight's active situational mods (Combat.situational_active()).
		"situational": {},
		# A scripted fight's data block (SCRIPT_PRE, then SCRIPT_POST after its
		# Rewind; see script_locked(); SCRIPT_OPEN throughout with no lock),
		# null for an ordinary fight.
		"script": null,
		# A pearl lock ({ item, enemyBelowHp, prompt }, R§3.7b Pearl lock),
		# null for none.
		"pearlLock": null,
		# A demo fight's data block (R§3.7b Demo fights), null for any other.
		"demo": null,
		# A gym spar's or practice scripted fight's data block
		# (Sparring.spar_block()): what to restore when it ends and how far its
		# free Rewind goes; null for any other fight.
		"spar": null,
		# Coach marks (R§3.7b Coach marks): { lessons: { "<round>": line }, allowed:
		# { "<round>": [move or item ids] }, notes: { "<round>": { "<variant>.<kind>":
		# line or [lines] } } } or null for none.
		"coach": null,
	}


# The round's resolution cursor: the timeline entry last resolved (index -1
# before the round's first), the actors whose remaining actions this round
# are gone (Leg it), and the player position paused on for a pick (-1 when
# not paused: no fight on, or it's over).
static func _new_cursor() -> Dictionary:
	return { "index": -1, "actor": -1, "done": [], "pause": -1 }


static func level_max() -> int:
	return int(_data()["levelMax"])


# A move's row, or for a round item's recipe id a move-shaped row built
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


# The round items, by recipe id.
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


# Actions `actor` gets next round as things stand: its level's count, +1
# while an Enhancement Powder already running lasts into it.
static func actions_next_round(cp: Dictionary, actor: int) -> int:
	var combatant: Dictionary = cp["combatants"][actor]
	return actions_per_round(combatant) + (1 if int(cp["round"]) + 1 <= int(combatant["powderUntil"]) else 0)


static func is_powered(cp: Dictionary, combatant: Dictionary) -> bool:
	return int(cp["round"]) <= int(combatant["powderUntil"])


static func has_lady(cp: Dictionary, combatant: Dictionary) -> bool:
	return int(cp["round"]) <= int(combatant["ladyUntil"])


# Whether the player has Prophet's Breath sight this round.
static func has_sight(cp: Dictionary) -> bool:
	return int(cp["round"]) <= int(cp["combatants"][PLAYER_INDEX]["sightUntil"])


# Gives `combatant` Prophet's Breath sight and/or Be a Lady's max rolls,
# crit and evade cut (at `lady_tier`; 0 for no Be a Lady) for the whole
# fight (R§3.7b Carry-in effects).
static func carry_in(combatant: Dictionary, sight: bool, lady_tier: int) -> void:
	if sight:
		combatant["sightUntil"] = WHOLE_FIGHT
	if lady_tier > 0:
		combatant["ladyUntil"] = WHOLE_FIGHT
		combatant["ladyTier"] = lady_tier
		combatant["ladyCrit"] = float(_data()["items"]["beALady"]["params"]["critChance"])


static func has_pan_status(combatant: Dictionary) -> bool:
	return int(combatant["panicActions"]) > 0 or int(combatant["raptureActions"]) > 0 or int(combatant["angerActions"]) > 0


# The status turn (STATUS_PANIC or STATUS_RAPTURE) enemy `actor` plays at
# its plan position `index` this round (with next_round, next round's), or
# "": its pending status turns take its upcoming positions in order, after
# the ones it's due to lose (a lost action never ticks a status, R§3.7b
# Table 4).
static func status_turn(cp: Dictionary, actor: int, index: int, next_round: bool = false) -> String:
	var combatant: Dictionary = cp["combatants"][actor]
	var status := ""
	if int(combatant["panicActions"]) > 0:
		status = STATUS_PANIC
	elif int(combatant["raptureActions"]) > 0:
		status = STATUS_RAPTURE
	if status == "" or combatant["side"] != SIDE_ENEMY:
		return ""
	var turns: int = combatant["panicActions"] if status == STATUS_PANIC else combatant["raptureActions"]
	var lost: int = combatant["actionsLost"]
	# [round offset, index] per upcoming position, this round's then next's.
	var upcoming: Array = []
	for i in range(combatant["plan"].size()):
		if not is_resolved(cp, actor, i):
			upcoming.append([0, i])
	for i in range(combatant["nextPlan"].size()):
		upcoming.append([1, i])
	return status if upcoming.slice(lost, lost + turns).has([1 if next_round else 0, index]) else ""


# Multiplier on the damage `combatant` deals (dealing) or takes under
# Panger/Pandemonium: its first phaseActions actions deal +angerPct% and
# take -angerPct%, the rest the reverse, floored at 0 (R§3.7b Table 4).
static func anger_factor(combatant: Dictionary, dealing: bool) -> float:
	var left := int(combatant["angerActions"])
	if left == 0:
		return 1.0
	var buffed: bool = left > int(_data()["anger"]["phaseActions"])
	var sign := 1.0 if buffed == dealing else -1.0
	return maxf(0.0, 1.0 + sign * float(combatant["angerPct"]) / 100.0)


# The combatant's running Table 4 statuses as short badges: Panic or
# Rapture with its turns left, Anger or Fury with the damage it deals now
# (+/- angerPct%), Disarmed (with an ability's locked rounds).
static func status_badges(combatant: Dictionary) -> Array:
	var labels: Dictionary = _data()["statusBadges"]
	var badges: Array = []
	if combatant["koed"]:
		return badges
	if int(combatant["panicActions"]) > 0:
		badges.append("%s (%d)" % [labels["panic"], combatant["panicActions"]])
	if int(combatant["raptureActions"]) > 0:
		badges.append("%s (%d)" % [labels["rapture"], combatant["raptureActions"]])
	if int(combatant["angerActions"]) > 0:
		var sign := "+" if anger_factor(combatant, true) >= 1.0 else "−"
		badges.append("%s %s%d%%" % [labels["fury" if combatant["fury"] else "anger"], sign, combatant["angerPct"]])
	if combatant["disarmed"]:
		var ability = combatant["ability"]
		var locked: int = int(ability["lockedTurns"]) if ability is Dictionary else 0
		badges.append(labels["disarmed"] if locked == 0 else "%s (%d)" % [labels["disarmed"], locked])
	return badges


# Combatant `index`'s running statuses as [{ id, count }] for the stage icon
# row, in display order (removal, control, damage mods, buffs). count is the
# actions or rounds left, 0 where there is none. Failsafe and Shield have no
# icon; Frozen and Open-hold ride their own stage marks.
static func status_icons(cp: Dictionary, index: int) -> Array:
	var c: Dictionary = cp["combatants"][index]
	var icons: Array = []
	if c["koed"]:
		return icons
	if c["disarmed"]:
		var ability = c["ability"]
		icons.append({ "id": "disarmed", "count": int(ability["lockedTurns"]) if ability is Dictionary else 0 })
	var stunned: int = int(c["actionsLost"]) - int(c["frozenActions"])
	if stunned > 0:
		icons.append({ "id": "stunned", "count": stunned })
	if c["guardFailed"]:
		icons.append({ "id": "feinted", "count": 0 })
	if int(c["panicActions"]) > 0:
		icons.append({ "id": "panic", "count": int(c["panicActions"]) })
	if int(c["raptureActions"]) > 0:
		icons.append({ "id": "rapture", "count": int(c["raptureActions"]) })
	if int(c["feintPct"]) > 0:
		icons.append({ "id": "feintBonus", "count": 0 })
	if int(c["angerActions"]) > 0:
		var id := "fury" if c["fury"] else ("angerHot" if anger_factor(c, true) >= 1.0 else "angerCold")
		icons.append({ "id": id, "count": int(c["angerActions"]) })
	if is_powered(cp, c):
		icons.append({ "id": "powdered", "count": _rounds_left(cp, int(c["powderUntil"])) })
	if index == PLAYER_INDEX and has_sight(cp):
		icons.append({ "id": "sight", "count": _rounds_left(cp, int(c["sightUntil"])) })
	if has_lady(cp, c):
		icons.append({ "id": "lady", "count": _rounds_left(cp, int(c["ladyUntil"])) })
	if float(c["fleeBoost"]) > 0.0:
		icons.append({ "id": "legIt", "count": 0 })
	return icons


# Rounds a through-round status still covers, this one included (0 for the whole fight).
static func _rounds_left(cp: Dictionary, until_round: int) -> int:
	return 0 if until_round >= WHOLE_FIGHT else until_round - int(cp["round"]) + 1


# status_icons() as full-text lines with their remaining counts (statusPeek).
static func status_peek_lines(cp: Dictionary, index: int) -> Array:
	var text: Dictionary = _data()["statusPeek"]
	var c: Dictionary = cp["combatants"][index]
	var lines: Array = []
	for icon in status_icons(cp, index):
		var n: int = int(icon["count"])
		var line: String
		match icon["id"]:
			"disarmed":
				line = str(text["disarmed"] if n == 0 else text["disarmedLocked"])
			"feintBonus":
				line = str(text["feintBonus"]).replace("{pct}", str(c["feintPct"]))
			"sight":
				line = str(text["sightFight"] if n == 0 else text["sight"])
			"lady":
				line = str(text["ladyFight"] if n == 0 else text["lady"])
			"angerHot", "angerCold", "fury":
				var label: String = str(_data()["statusBadges"]["fury" if icon["id"] == "fury" else "anger"])
				var cold: int = int(_data()["anger"]["phaseActions"])
				if anger_factor(c, true) >= 1.0:
					line = str(text["angerHot"]).replace("{hot}", str(n - cold)).replace("{cold}", str(cold))
				else:
					line = str(text["angerCold"])
				line = line.replace("{name}", label).replace("{pct}", str(c["angerPct"]))
			_:
				line = str(text[icon["id"]])
		lines.append(line.replace("{n}", str(n)))
	return lines


# The attacker's damage roll range: its attack range, or its max both ends
# under Be a Lady, plus its Strike level's damageBonus.
static func damage_range(cp: Dictionary, actor: int) -> Array:
	var combatant: Dictionary = cp["combatants"][actor]
	var bonus := int(level_effects(MOVE_STRIKE)["damageBonus"][move_level(combatant, MOVE_STRIKE)])
	if has_lady(cp, combatant):
		return [combatant["attackMax"] + bonus, combatant["attackMax"] + bonus]
	return [combatant["attackMin"] + bonus, combatant["attackMax"] + bonus]


# `combatant`'s level in `move_id` (1 with no record).
static func move_level(combatant: Dictionary, move_id: String) -> int:
	return int(combatant.get("moveLevels", {}).get(move_id, 1))


# A move's row of the data's moveLevelEffects (R§3.7b Move levels).
static func level_effects(move_id: String) -> Dictionary:
	return _data()["moveLevelEffects"][move_id]


# Chip multiplier on a Guarded `target` hit by `attacker`'s Strike: the
# attacker's Strike chip (chipMultiplier, or its L5 chip) scaled by the
# defender's Guard level relative to the base.
static func chip_multiplier(attacker: Dictionary, target: Dictionary) -> float:
	var strike := level_effects(MOVE_STRIKE)
	var base := float(_data()["chipMultiplier"])
	var chip := float(strike["chipMultiplier"]) if move_level(attacker, MOVE_STRIKE) >= int(strike["chipLevel"]) else base
	var guard_chip := float(level_effects(MOVE_GUARD)["chipMultiplier"][move_level(target, MOVE_GUARD)])
	return chip * guard_chip / base


# The Leg it flee chance at the actor's Leg it level.
static func flee_chance(actor: Dictionary) -> float:
	return float(level_effects("legIt")["chance"][move_level(actor, "legIt")])


static func display_name(combatant: Dictionary) -> String:
	if combatant["side"] == SIDE_PLAYER:
		return "You"
	var name: String = combatant["name"]
	return name[0].to_upper() + name.substr(1)


# ── Setup ────────────────────────────────────────────────────────────────

# A fight's opening, on `cp` with its combatants already
# in place (player at PLAYER_INDEX, then allies, then enemies, each from
# new_combatant(); an enemy also carries its archetype): seeds both RNG
# streams off `seed_value`, rolls round 1's and round 2's enemy plans and
# fog, plans the allies, and resolves round 1 up to the player's first
# position.
static func open_fight(cp: Dictionary, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var fog_rng := RandomNumberGenerator.new()
	fog_rng.seed = seed_value ^ FOG_SEED_SALT
	cp["active"] = true
	cp["round"] = 1
	_roll_move_levels(cp, seed_value)
	var combatants: Array = cp["combatants"]
	var patients: Array = []
	for i in range(combatants.size()):
		if combatants[i]["side"] == SIDE_ENEMY:
			combatants[i]["plan"] = _roll_plan(cp, i, 1, rng)
			_roll_fog(cp, i, combatants[i]["plan"], 1, fog_rng)
			_commit_kit_item(cp, i, patients)
			combatants[i]["nextPlan"] = _roll_plan(cp, i, 2, rng)
			_roll_fog(cp, i, combatants[i]["nextPlan"], 2, fog_rng)
	cp["fogRngState"] = fog_rng.state
	_plan_allies(cp, rng)
	cp["playerPlan"] = _empty_player_plan(cp)
	push_round_frame(cp, rng.state)
	cp["roundFrames"][0]["atOpen"] = true
	var beats: Array = []
	_advance(cp, rng, beats)
	_record(cp, beats)
	cp["rngState"] = rng.state


# The beats open_fight() resolved ahead of the player's first position, while
# no pick has played yet; [] once one has, or in a demo fight. The fight as
# it stood before them is cp.roundFrames[0].
static func opening_beats(cp: Dictionary) -> Array:
	if is_demo(cp) or int(cp["round"]) != 1 or not cp["snapshots"].is_empty() or cp.get("roundFrames", []).size() != 1:
		return []
	return cp["log"].duplicate()


# Every fighter without move levels yet, active or queued, in order: the
# player all level 1 unless it has an owner's; anyone else with no owner
# rolls MoveLevels.roll() at its Combat Skill level, off the fight seed.
static func _roll_move_levels(cp: Dictionary, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ MOVE_LEVEL_SEED_SALT
	var fighters: Array = cp["combatants"].duplicate()
	for side in [SIDE_ALLY, SIDE_ENEMY]:
		for entry in cp.get(QUEUE_KEYS[side], []):
			if entry.has("fighter"):
				fighters.append(entry["fighter"])
	for fighter in fighters:
		if not fighter.get("moveLevels", {}).is_empty():
			continue
		if fighter["side"] == SIDE_PLAYER:
			var levels := {}
			for move_id in MoveLevels.move_ids():
				levels[move_id] = 1
			fighter["moveLevels"] = levels
		else:
			fighter["moveLevels"] = MoveLevels.roll(int(fighter["level"]), rng)


# Appends `beats` to the fight's log and their lines (each followed by its
# coach note, if any) to its transcript; each move level-up among them also
# posts its line as a Notification.
static func _record(cp: Dictionary, beats: Array) -> void:
	cp["log"].append_array(beats)
	var transcript: Array = cp["transcript"]
	for beat in beats:
		transcript.append(beat["text"])
		if beat.has("coachNote"):
			transcript.append(beat["coachNote"])
		if beat["kind"] == "levelUp":
			var notice := MoveLevels.level_up_notice(str(beat["moveOwner"]), beat["move"], int(beat["level"]))
			Notify.push(notice["text"], Notify.CATEGORY_SUCCESS, { "detail": notice["detail"], Notify.META_MOVE_OWNER: beat["moveOwner"], Notify.META_MOVE_ID: beat["move"] })


# A combatant at Combat Skill `level` (clamped to 1..levelMax) with these
# final stats, Guarded, no statuses, no loadout and no plans yet.
static func new_combatant(side: String, name: String, level: int, hp: int, hp_max: int, attack_min: int, attack_max: int, speed: int) -> Dictionary:
	return {
		"side": side, "name": name, "level": clampi(level, 1, level_max()),
		"hp": hp, "hpMax": hp_max,
		"attackMin": attack_min,
		"attackMax": attack_max,
		"speed": speed,
		"guard": GUARDED, "koed": false,
		# A Feint landed on it: its next Guard action fails (R§3.7b Moves).
		"guardFailed": false,
		# Upcoming actions to drop from the timeline (Stun, Time Pearl, Black
		# Hole).
		"actionsLost": 0,
		# How many of those are a Time Pearl's freeze, which holds it Open.
		"frozenActions": 0,
		# Absorb pool; while above 0 it counts as Guarded (Shield).
		"shield": 0,
		# The pool a Shield last raised it to (the stage's density denominator).
		"shieldMax": 0,
		# Timed item effects, each running through the end of this round
		# number: Enhancement Powder's +1 action, Be a Lady's max rolls (at
		# ladyCrit crit chance, cutting targets' evade by ladyTier steps) and
		# Prophet's Breath sight.
		"powderUntil": 0,
		"ladyUntil": 0,
		"ladyCrit": 0.0,
		"ladyTier": 0,
		# Chance (0.0-1.0) a Strike at it misses outright (evade_chance()).
		"evadeChance": 0.0,
		"sightUntil": 0,
		# A Blast's one-use Leg it chance for the next Leg it (0.0 for none).
		"fleeBoost": 0.0,
		# Pan statuses (R§3.7b Table 4), counted down on the combatant's own
		# resolved actions: Panic and Pan's Rapture turns still to play, and
		# Panger/Pandemonium's anger (angerPct either way; fury turns its
		# Strikes and Stuns on its own side).
		"panicActions": 0, "raptureActions": 0,
		"angerActions": 0, "angerPct": 0, "fury": false,
		# What a Blast's disarm takes: the weapon's attack bonus { min, max }
		# (null for none) and the ability { id, lockedTurns } it locks for
		# some rounds (null for none).
		"weapon": null, "ability": null, "disarmed": false,
		# Items: { item, tier, power, used } per slot, plus multi for a
		# multi-target unit and sourceSlot for a live fight's real slot. A
		# recruit's failsafe sits here too, never planned (_ally_failsafe()).
		"loadout": [],
		# The shared kit pool it plans items from (KIT_POOLS; "" for none),
		# and whether an ally's Enhancement Powder (kit, slot or Dial cast)
		# has resolved for it (once per fight).
		"kit": "", "powderUsed": false,
		# A live fight's Dial (R§3.7b Dial Complications), null for none:
		# { owner, charge, regenCounter, casts, spent, actions }. casts are
		# loadout-shaped { item, tier, power, multi, sourceIndex } per
		# castable loaded Complication (plus lost for a Black Hole's actions
		# taken, angerPct for Panger/Pandemonium); a resolved cast takes 1
		# charge and logs its sourceIndex on spent, and every resolved
		# action of the owner counts on actions, for the live layer to
		# settle (casts, and in-combat Recharge regen).
		"dial": null,
		# Its level per move { moveId: level } (R§3.7b Move levels), and whose
		# persistent record its move XP goes to: "" the player, a contact id,
		# or null for none (open_fight() then rolls its levels).
		"moveLevels": {}, "moveOwner": null,
		# The levelled moves it has used this fight { moveId: true }.
		"usedMoves": {},
		# Guard L5's once-a-round full absorb has been used this round, and
		# the actions a Stun L5 keeps it Open for.
		"firstHitSpent": false, "openActions": 0,
		# The extra % damage a Feint's opening adds to hits on it, and the move
		# its last resolved action used (Feint passives).
		"feintPct": 0, "lastMove": "",
		"plan": [], "nextPlan": [],
	}


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


# Marks each action of enemy `actor`'s freshly rolled `plan` (for round
# `round_no`) read or unread: a fog roll under unread_chance(), or the test
# override; every action reads with the fight's fog off. Draws one roll per
# action the enemy's level gives, whatever the plan holds, so the stream
# stays in step however the fight goes.
static func _roll_fog(cp: Dictionary, actor: int, plan: Array, round_no: int, fog_rng: RandomNumberGenerator) -> void:
	var combatant: Dictionary = cp["combatants"][actor]
	var override = combatant.get("unreadOverride")
	var forced: Array = override[(round_no - 1) % override.size()] if override != null and not override.is_empty() else []
	for a in range(actions_per_round(combatant)):
		var unread := fog_rng.randf() < unread_chance(cp, actor, a)
		if a >= plan.size():
			continue
		if override != null and not override.is_empty():
			unread = a < forced.size() and bool(forced[a])
		plan[a]["unread"] = bool(cp["fog"]) and unread


# The chance enemy `actor`'s action `index` rolls unread (data fog): the
# player's Combat Skill base, raised per level the enemy is above the player
# (lowered per level below), scaled by the action's position, within [0, 1].
static func unread_chance(cp: Dictionary, actor: int, index: int) -> float:
	var fog: Dictionary = _data()["fog"]
	var player_level: int = cp["combatants"][PLAYER_INDEX]["level"]
	var gap: int = int(cp["combatants"][actor]["level"]) - player_level
	var chance := float(fog["unreadChance"][player_level])
	if gap > 0:
		chance += gap * float(fog["perLevelAbove"])
	else:
		chance += gap * float(fog["perLevelBelow"])
	var multipliers: Array = fog["positionMultiplier"]
	chance *= float(multipliers[mini(index, multipliers.size() - 1)])
	return clampf(chance, 0.0, 1.0)


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


# ── Kits (R§3.7b Table 5) ────────────────────────────────────────────────
#
# A kit unit is reserved when the action holding it commits, spent when
# that action resolves, and back in the pool when it fizzles or never
# resolves (_release_kits() at each round's end). A kit action is
# { move, target, part, kit, tier, power }.

# The kit pool `actor` plans from ({} for none).
static func _kit_pool(cp: Dictionary, actor: int) -> Dictionary:
	var pool = cp.get(cp["combatants"][actor].get("kit", ""), {})
	return pool if pool is Dictionary else {}


static func _kit_has(pool: Dictionary, recipe_key: String) -> bool:
	return GuardKit.unit_count({ recipe_key: pool.get("items", {}).get(recipe_key, {}) }) > 0


# Moves one `recipe_key` unit at `tier_key` from pool[from] to pool[to]
# (each by recipe then tier), erasing emptied tiers and recipes.
static func _kit_move(pool: Dictionary, recipe_key: String, tier_key: String, from: String, to: String) -> void:
	var source: Dictionary = pool[from][recipe_key]
	var left := int(source[tier_key]) - 1
	if left > 0:
		source[tier_key] = left
	else:
		source.erase(tier_key)
		if source.is_empty():
			pool[from].erase(recipe_key)
	if not (pool.get(to) is Dictionary):
		pool[to] = {}
	if not (pool[to].get(recipe_key) is Dictionary):
		pool[to][recipe_key] = {}
	pool[to][recipe_key][tier_key] = int(pool[to][recipe_key].get(tier_key, 0)) + 1


# `actor`'s kit action for `recipe_key` at `target`, reserving the pool's
# highest-tier unit; power is the recipe's effectPower at that tier.
static func _kit_action(cp: Dictionary, actor: int, recipe_key: String, target: int) -> Dictionary:
	var pool := _kit_pool(cp, actor)
	var tier_key := GuardKit.highest_tier_key(pool["items"][recipe_key])
	_kit_move(pool, recipe_key, tier_key, "items", "reserved")
	var powers: Array = GameData.RECIPES[recipe_key]["effectPower"]
	return { "move": recipe_key, "target": target, "part": 0, "kit": cp["combatants"][actor]["kit"],
		"tier": int(tier_key), "power": int(powers[clampi(int(tier_key), 1, powers.size() - 1)]) }


# Hands every unit still reserved back to its pool's items.
static func _release_kits(cp: Dictionary) -> void:
	for kit in KIT_POOLS:
		var pool = cp.get(kit)
		if not (pool is Dictionary) or not (pool.get("reserved") is Dictionary):
			continue
		var reserved: Dictionary = pool["reserved"]
		for recipe_key in reserved.keys():
			for tier_key in reserved[recipe_key].keys():
				for _n in range(int(reserved[recipe_key][tier_key])):
					_kit_move(pool, recipe_key, tier_key, "reserved", "items")


# Enemy `actor`'s just-committed plan with its first Strike swapped for a
# raider-kit item when a rule fires on the round-start state, in order: a
# heal on the worst-off teammate under allyHealBelow of hpMax not already in
# `patients` (enemies commit in array order; the patient joins it); a Shield
# on itself while its own pool is 0; a Blast at the Strike's target. At most
# one per enemy per round; the item keeps the Strike's fog.
static func _commit_kit_item(cp: Dictionary, actor: int, patients: Array) -> void:
	var pool := _kit_pool(cp, actor)
	if pool.get("items", {}).is_empty():
		return
	var plan: Array = cp["combatants"][actor]["plan"]
	for i in range(plan.size()):
		if plan[i]["move"] != MOVE_STRIKE:
			continue
		var action := {}
		if _kit_has(pool, KIT_HEAL):
			var patient := _ally_heal_patient(cp, actor, KIT_HEAL, patients)
			if patient >= 0:
				patients.append(patient)
				action = _kit_action(cp, actor, KIT_HEAL, patient)
		if action.is_empty() and _kit_has(pool, KIT_SHIELD) and int(cp["combatants"][actor]["shield"]) == 0:
			action = _kit_action(cp, actor, KIT_SHIELD, actor)
		if action.is_empty() and _kit_has(pool, KIT_BLAST):
			action = _kit_action(cp, actor, KIT_BLAST, int(plan[i]["target"]))
		if not action.is_empty():
			action["unread"] = bool(plan[i].get("unread", false))
			plan[i] = action
		return


# Guard ally `ally`'s next guard-kit action given its `plan` so far, or {}
# when no rule fires; `planned` as in _plan_allies(). In order: a heal as
# _ally_heal_patient(); Prophet's Breath, giving the player sight, while the
# player stands under allyHealBelow of hpMax with no sight running or
# planned; a Shield on the worst-off of itself and its teammates with no
# Shield up or planned; Black Hole, else Time Pearl, on the same crowd rule
# as _ally_item_action(); a Blast at the lowest-hp enemy; Enhancement Powder
# on itself, once per fight.
static func _kit_ally_action(cp: Dictionary, ally: int, plan: Array, planned: Dictionary) -> Dictionary:
	var pool := _kit_pool(cp, ally)
	if pool.get("items", {}).is_empty():
		return {}
	var combatants: Array = cp["combatants"]
	if _kit_has(pool, KIT_HEAL):
		var patient := _ally_heal_patient(cp, ally, KIT_HEAL, planned["patients"])
		if patient >= 0:
			return _kit_action(cp, ally, KIT_HEAL, patient)
	var player: Dictionary = combatants[PLAYER_INDEX]
	var hurt: bool = float(player["hp"]) < float(player["hpMax"]) * float(_data()["allyHealBelow"])
	if _kit_has(pool, KIT_SIGHT) and hurt and not player["koed"] and not has_sight(cp) and not planned["sight"]:
		return _kit_action(cp, ally, KIT_SIGHT, PLAYER_INDEX)
	if _kit_has(pool, KIT_SHIELD):
		var shielded := -1
		var best := INF
		for i in _team(cp, ally):
			var fraction: float = float(combatants[i]["hp"]) / float(combatants[i]["hpMax"])
			if int(combatants[i]["shield"]) == 0 and not planned["shielded"].has(i) and fraction < best:
				shielded = i
				best = fraction
		if shielded >= 0:
			return _kit_action(cp, ally, KIT_SHIELD, shielded)
	var opponents := _living_opponents(cp, ally)
	var paused: bool = opponents.any(func(e): return combatants[e]["actionsLost"] > 0)
	if not planned["crowd"] and not paused and opponents.size() >= int(_data()["allyCrowdEnemies"]):
		for recipe_key in KIT_CROWD:
			if _kit_has(pool, recipe_key):
				return _kit_action(cp, ally, recipe_key, -1)
	if _kit_has(pool, KIT_BLAST) and not opponents.is_empty():
		var weakest: int = opponents[0]
		for e in opponents:
			if int(combatants[e]["hp"]) < int(combatants[weakest]["hp"]):
				weakest = e
		return _kit_action(cp, ally, KIT_BLAST, weakest)
	if _kit_has(pool, KIT_POWDER) and not combatants[ally].get("powderUsed", false) and not plan.any(func(a): return a["move"] == KIT_POWDER):
		return _kit_action(cp, ally, KIT_POWDER, ally)
	return {}


# An ally's own failsafe on its lethal hit (R§3.7b Rewind): a guard's from
# its kit, a recruit's from an unspent loadout slot; one unit puts it back
# on 1 hp. Whether one fired.
static func _ally_failsafe(cp: Dictionary, idx: int, beats: Array) -> bool:
	var ally: Dictionary = cp["combatants"][idx]
	if ally["side"] != SIDE_ALLY:
		return false
	var pool := _kit_pool(cp, idx)
	if _kit_has(pool, FAILSAFE):
		_kit_move(pool, FAILSAFE, GuardKit.highest_tier_key(pool["items"][FAILSAFE]), "items", "used")
	else:
		var slots: Array = ally["loadout"].filter(func(s): return s["item"] == FAILSAFE and not s["used"])
		if slots.is_empty():
			return false
		slots[0]["used"] = true
	ally["hp"] = 1
	_beat(cp, beats, "failsafe", idx, -1, FAILSAFE, { "hpAfter": 1 })
	return true


# ── Ally AI ──────────────────────────────────────────────────────────────

# Plans every living ally's round from the enemies' committed plans as the
# player reads them (R§3.7b Round, Fog: an unread action is
# unknown, never a Strike to guard), per action: Guard where an enemy
# strikes it; else Strike an enemy who'll be Open when it acts; else, with an action to follow, Feint a
# Guarded enemy the Feint leaves Open for that next action's Strike; else,
# with chance allyChipStrikeChance, chip-Strike a Guarded enemy; else Guard.
# Before those, a guard ally's kit item takes the action when
# _kit_ally_action() has one, else an unspent loadout slot or Dial cast by
# _ally_item_action()'s rules. Allies plan in array order, each reading the
# earlier ones' Feints and leaving alone what an earlier one (or its own
# earlier action) already covers this round: a patient, a Shield, a Pan
# target, a Time Pearl or Black Hole, Prophet's Breath. An ally with a test
# override plays that instead.
static func _plan_allies(cp: Dictionary, rng: RandomNumberGenerator) -> void:
	var combatants: Array = cp["combatants"]
	# { actor, index, target } per Feint planned so far this round.
	var feints: Array = []
	# Item uses planned so far this round: combatant index per heal, per
	# Shield and per Pan status, whether a Time Pearl or Black Hole is out,
	# and whether a Prophet's Breath is.
	var planned := { "patients": [], "shielded": [], "panned": [], "crowd": false, "sight": false }
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
			var count := actions_this_round(cp, i)
			for a in range(count):
				var action := _kit_ally_action(cp, i, plan, planned)
				if action.is_empty():
					action = _ally_item_action(cp, i, plan, planned)
				if action.is_empty():
					action = _ally_action(cp, i, a, count, feints, rng)
				if action["move"] == MOVE_FEINT:
					feints.append({ "actor": i, "index": a, "target": action["target"] })
				var effect: String = move(action["move"]).get("effect", "")
				# A multi unit (target -1) covers its whole side.
				var aimed: Array = [action["target"]] if int(action["target"]) >= 0 else []
				if effect == ITEM_HEAL:
					planned["patients"].append_array(aimed if not aimed.is_empty() else _team(cp, i))
				elif effect == ITEM_SHIELD:
					planned["shielded"].append_array(aimed if not aimed.is_empty() else _team(cp, i))
				elif effect == ITEM_SIGHT:
					planned["sight"] = true
				elif effect in [ITEM_FREEZE, ITEM_BLACK_HOLE]:
					planned["crowd"] = true
				elif effect in PAN_EFFECTS:
					planned["panned"].append_array(aimed if not aimed.is_empty() else _living_opponents(cp, i))
				plan.append(action)
			ally["plan"] = plan


# The ally's next item action given the `plan` so far, or {} when no rule
# fires; `planned` as in _plan_allies(). Its units are its Dial's casts
# (while the plan holds fewer casts than it has charge), then each unspent
# item slot once (a failsafe slot is never planned). On the round-start
# state, the first rule with a unit for it fires (R§3.7b Table 5, Recruit
# slots): a heal as _ally_heal_patient() (multi: the team); Prophet's Breath
# while the player has no sight and an enemy action is unread; a Shield on
# itself while a read enemy Strike aims at it and its pool is 0 (multi: at
# any such friendly; the team); Time Pearl or Black Hole while
# allyCrowdEnemies or more enemies stand and none is losing actions; a Blast
# at the biggest enemy it can drop (hp at most its power), else the
# lowest-hp one (multi: all); Enhancement Powder on its round's first action
# with no Powder running, once per fight; Be a Lady on round 1's first
# action; a Pan item at _ally_pan_target() (multi: every unstatused enemy),
# Panger only at an enemy on offence, Pandemonium only with 2+ enemies
# standing.
static func _ally_item_action(cp: Dictionary, ally: int, plan: Array, planned: Dictionary) -> Dictionary:
	var combatants: Array = cp["combatants"]
	var combatant: Dictionary = combatants[ally]
	var units: Array = []
	var dial = combatant.get("dial")
	if dial is Dictionary and plan.filter(func(a): return a.has("dial")).size() < floori(float(dial["charge"])):
		for d in range(dial["casts"].size()):
			units.append({ "move": dial["casts"][d]["item"], "dial": d, "multi": bool(dial["casts"][d].get("multi", false)) })
	var loadout: Array = combatant["loadout"]
	for slot in range(loadout.size()):
		if not loadout[slot]["used"] and is_item(loadout[slot]["item"]) and not plan.any(func(a): return int(a.get("slot", -1)) == slot):
			units.append({ "move": loadout[slot]["item"], "slot": slot, "multi": bool(loadout[slot].get("multi", false)) })
	if units.is_empty():
		return {}
	var opponents := _living_opponents(cp, ally)
	for unit in _units_with(units, [ITEM_HEAL]):
		var patient := _ally_heal_patient(cp, ally, unit["move"], planned["patients"])
		if patient >= 0:
			return _unit_action(unit, -1 if unit["multi"] else patient)
	if not has_sight(cp) and not planned["sight"] and opponents.any(func(e): return range(combatants[e]["plan"].size()).any(func(i): return not is_read(cp, e, i))):
		for unit in _units_with(units, [ITEM_SIGHT]):
			return _unit_action(unit, PLAYER_INDEX)
	var struck := _read_strike_targets(cp, ally)
	for unit in _units_with(units, [ITEM_SHIELD]):
		var exposed: Array = _team(cp, ally) if unit["multi"] else [ally]
		if exposed.any(func(f): return struck.has(f) and int(combatants[f]["shield"]) == 0 and not planned["shielded"].has(f)):
			return _unit_action(unit, -1 if unit["multi"] else ally)
	var paused: bool = opponents.any(func(e): return combatants[e]["actionsLost"] > 0)
	if not planned["crowd"] and not paused and opponents.size() >= int(_data()["allyCrowdEnemies"]):
		for unit in _units_with(units, [ITEM_FREEZE, ITEM_BLACK_HOLE]):
			return _unit_action(unit, -1)
	if not opponents.is_empty():
		for unit in _units_with(units, [ITEM_BLAST]):
			return _unit_action(unit, -1 if unit["multi"] else _ally_blast_target(cp, ally, _unit_power(combatant, unit)))
	if plan.is_empty() and not is_powered(cp, combatant) and not combatant.get("powderUsed", false):
		for unit in _units_with(units, [ITEM_POWDER]):
			return _unit_action(unit, ally)
	if plan.is_empty() and int(cp["round"]) == 1:
		for unit in _units_with(units, [ITEM_LADY]):
			return _unit_action(unit, ally)
	for unit in _units_with(units, PAN_EFFECTS):
		var effect: String = move(unit["move"])["effect"]
		if effect == ITEM_FURY and opponents.size() < 2:
			continue
		var panned := _ally_pan_target(cp, ally, planned["panned"], effect == ITEM_ANGER)
		if panned >= 0:
			return _unit_action(unit, -1 if unit["multi"] else panned)
	return {}


# The `units` whose item has one of `effects`, in order.
static func _units_with(units: Array, effects: Array) -> Array:
	return units.filter(func(u): return effects.has(move(u["move"])["effect"]))


static func _unit_power(combatant: Dictionary, unit: Dictionary) -> int:
	if unit.has("dial"):
		return int(combatant["dial"]["casts"][int(unit["dial"])]["power"])
	return int(combatant["loadout"][int(unit["slot"])]["power"])


static func _unit_action(unit: Dictionary, target: int) -> Dictionary:
	var action: Dictionary = unit.duplicate()
	action.erase("multi")
	action.merge({ "target": target, "part": 0 })
	return action


# The friendlies of `ally` a read enemy Strike (damage, not a status turn,
# not lost, its target read) aims at this round.
static func _read_strike_targets(cp: Dictionary, ally: int) -> Array:
	var combatants: Array = cp["combatants"]
	var result: Array = []
	for e in _living_opponents(cp, ally):
		if _is_furious(cp, e):
			continue
		var plan: Array = combatants[e]["plan"]
		for i in range(plan.size()):
			if not _action_lost(cp, e, i) and is_read(cp, e, i) and status_turn(cp, e, i) == "" and move(plan[i]["move"])["effect"] == EFFECT_DAMAGE:
				result.append(int(plan[i]["target"]))
	return result


# The living enemy with the most hp at or below `power` (a Blast drops it),
# else the lowest-hp one; ties to the first in combatant order.
static func _ally_blast_target(cp: Dictionary, ally: int, power: int) -> int:
	var combatants: Array = cp["combatants"]
	var opponents := _living_opponents(cp, ally)
	var droppable: Array = opponents.filter(func(e): return int(combatants[e]["hp"]) <= power)
	var best: int = -1
	for e in droppable:
		if best < 0 or int(combatants[e]["hp"]) > int(combatants[best]["hp"]):
			best = e
	if best >= 0:
		return best
	for e in opponents:
		if best < 0 or int(combatants[e]["hp"]) < int(combatants[best]["hp"]):
			best = e
	return best


# The enemy under no Pan status, and not in `panned`, with the most read
# offensive (damage or Stun) actions this round, ties to the first in
# combatant order; with none on offence the first such enemy, or -1 when
# `need_offence`. -1 for none.
static func _ally_pan_target(cp: Dictionary, ally: int, panned: Array, need_offence: bool) -> int:
	var combatants: Array = cp["combatants"]
	var best := -1
	var best_count := 0 if need_offence else -1
	for e in _living_opponents(cp, ally):
		if has_pan_status(combatants[e]) or panned.has(e):
			continue
		var plan: Array = combatants[e]["plan"]
		var count := 0
		for i in range(plan.size()):
			if is_read(cp, e, i) and status_turn(cp, e, i) == "" and move(plan[i]["move"])["effect"] in [EFFECT_DAMAGE, EFFECT_STUN]:
				count += 1
		if count > best_count:
			best = e
			best_count = count
	return best


# The lowest-HP-fraction of the ally and its living teammates under
# allyHealBelow of hpMax and not already in `patients`; -1 for none.
static func _ally_heal_patient(cp: Dictionary, ally: int, item_id: String, patients: Array) -> int:
	var combatants: Array = cp["combatants"]
	var threshold := float(_data()["allyHealBelow"])
	var best := -1
	var best_fraction := threshold
	for i in target_options(cp, ally, item_id):
		var fraction: float = float(combatants[i]["hp"]) / float(combatants[i]["hpMax"])
		if fraction < best_fraction and not patients.has(i):
			best = i
			best_fraction = fraction
	return best


static func _ally_action(cp: Dictionary, ally: int, index: int, count: int, feints: Array, rng: RandomNumberGenerator) -> Dictionary:
	var combatants: Array = cp["combatants"]
	var enemies := _living_opponents(cp, ally)
	for e in enemies:
		var plan: Array = combatants[e]["plan"]
		if index < plan.size() and not _action_lost(cp, e, index) and is_read(cp, e, index) and status_turn(cp, e, index) == "" and int(plan[index]["target"]) == ally and move(plan[index]["move"])["effect"] in [EFFECT_DAMAGE, EFFECT_STUN]:
			return { "move": MOVE_GUARD, "target": ally, "part": 0 }
	for e in enemies:
		if _ally_sees_open(cp, e, ally, index, feints):
			return { "move": MOVE_STRIKE, "target": e, "part": 0 }
	if index + 1 < count:
		for e in enemies:
			var with_feint: Array = feints + [{ "actor": ally, "index": index, "target": e }]
			if not _ally_sees_open(cp, e, ally, index + 1, feints) and _ally_sees_open(cp, e, ally, index + 1, with_feint):
				return { "move": MOVE_FEINT, "target": e, "part": 0 }
	var guarded: Array = enemies.filter(func(e): return not _ally_sees_open(cp, e, ally, index, feints))
	if not guarded.is_empty() and rng.randf() < float(_data()["allyChipStrikeChance"]):
		return { "move": MOVE_STRIKE, "target": guarded[0], "part": 0 }
	return { "move": MOVE_GUARD, "target": ally, "part": 0 }


# Whether enemy `e` will be Open when `observer` takes its action `index`,
# replaying the enemy's committed guard changes and `feints` on it in
# timeline order up to that moment. An unread action leaves its
# guard Unknown, which doesn't open it; a Guard the Feint fails leaves it Open.
# A Time Pearl holds it Open until its frozen positions pass, and an action it
# loses changes no guard.
static func _ally_sees_open(cp: Dictionary, e: int, observer: int, index: int, feints: Array) -> bool:
	var enemy: Dictionary = cp["combatants"][e]
	var events: Array = []
	var plan: Array = enemy["plan"]
	var passed: int = range(plan.size()).filter(func(i): return not is_resolved(cp, e, i) and _acts_before(cp, e, i, observer, index)).size()
	if passed < int(enemy["frozenActions"]):
		return true
	for i in range(mini(plan.size(), index + 1)):
		if _action_lost(cp, e, i):
			continue
		var effect := _planned_guard(cp, e, i, plan[i])
		if effect != UNCHANGED:
			events.append({ "actor": e, "index": i, "guard": effect })
	for f in feints:
		if f["target"] == e:
			events.append({ "actor": f["actor"], "index": f["index"], "guard": OPEN, "feint": true })
	events = events.filter(func(ev): return _acts_before(cp, ev["actor"], ev["index"], observer, index))
	events.sort_custom(func(x, y): return _acts_before(cp, x["actor"], x["index"], y["actor"], y["index"]))
	var state: String = enemy["guard"]
	var failing: bool = enemy["guardFailed"]
	for ev in events:
		if ev.get("feint", false):
			failing = true
		elif ev["guard"] == GUARDED and failing:
			failing = false
			continue
		state = ev["guard"]
	return state == OPEN


# Whether `actor`'s planned action `index` this round is one it loses to a
# Stun, Time Pearl or Black Hole: its unresolved positions lose in order.
static func _action_lost(cp: Dictionary, actor: int, index: int) -> bool:
	if is_resolved(cp, actor, index):
		return false
	var ahead: int = range(index).filter(func(i): return not is_resolved(cp, actor, i)).size()
	return ahead < int(cp["combatants"][actor]["actionsLost"])


# ── Planning ─────────────────────────────────────────────────────────────

static func move_cost(move_id: String) -> int:
	return int(move(move_id).get("cost", 1))


# The player position the fight is paused on for a pick, or -1.
static func decision_position(cp: Dictionary) -> int:
	if not cp["active"] or cp["outcome"] != null:
		return -1
	return int(cp["cursor"]["pause"])


# Why the player can't play `move_id` (at `target`, -1 for the default) at
# the paused position, or "" if they can.
static func move_block_reason(cp: Dictionary, move_id: String, target: int = -1) -> String:
	return _pick_block_reason(cp, { "move": move_id, "target": target })


# As move_block_reason(), for the item in loadout `slot`.
static func item_block_reason(cp: Dictionary, slot: int, target: int = -1) -> String:
	return _pick_block_reason(cp, { "slot": slot, "target": target })


# As move_block_reason(), for the player's Dial cast `index` (into its
# dial.casts).
static func cast_block_reason(cp: Dictionary, index: int, target: int = -1) -> String:
	return _pick_block_reason(cp, { "dial": index, "target": target })


# Plays the raw pick `action` ({ move, target }, { slot, target } or
# { dial, target }) at the paused position of the fight `cp`, snapshotting it
# first onto `cp`'s Rewind stack (capped as Snapshots' `stack_id`). A move
# costing n actions takes n of the player's positions in a row (the later
# parts resolve when their positions come up, without a pause), then the
# fight resolves on to the next pause or its end; target -1 takes the move's
# default. Returns { ok, beats }, or { ok: false, reason }. A player KO the
# fight survives stops resolution there for the caller's saves, then
# continue_after_ko().
static func play_pick(cp: Dictionary, action: Dictionary, stack_id: String) -> Dictionary:
	var reason := _pick_block_reason(cp, action)
	if reason != "":
		return { "ok": false, "reason": reason }
	var entry = _normalize_action(cp, action)
	_push_snapshot(cp, stack_id)
	var position := decision_position(cp)
	_counter_pick(cp, position, entry["move"])
	for part in range(move_cost(entry["move"])):
		var filled: Dictionary = entry.duplicate()
		filled["part"] = part
		cp["playerPlan"][position + part] = filled
	cp["cursor"]["pause"] = -1

	var rng := RandomNumberGenerator.new()
	rng.state = cp["rngState"]
	var beats: Array = []
	_advance(cp, rng, beats)
	_record(cp, beats)
	cp["rngState"] = rng.state
	return { "ok": true, "beats": beats, "outcome": cp["outcome"] }


# Why the raw pick `action` ({ move, target } or { slot, target }) can't be
# played at the paused position, or "".
static func _pick_block_reason(cp: Dictionary, action: Dictionary) -> String:
	if is_demo(cp):
		return DEMO_REASON
	var position := decision_position(cp)
	if position < 0:
		return "No fight on."
	if script_locked(cp):
		return str(cp["script"]["prompt"])
	var entry = _normalize_action(cp, action)
	if pearl_locked(cp) and not (entry.has("slot") and entry["move"] == cp["pearlLock"]["item"]):
		return str(cp["pearlLock"]["prompt"])
	var allowed := coach_allowed(cp)
	if not allowed.is_empty() and not allowed.has(entry["move"]):
		return str(GameData.COMBAT_ROUNDS["coach"]["notNow"])
	var reason := _action_block_reason(cp, entry)
	if reason != "":
		return reason
	if position + move_cost(entry["move"]) > actions_this_round(cp, PLAYER_INDEX):
		return _span_reason(entry["move"])
	return ""


# ── Coach marks (R§3.7b Coach marks) ─────────────────────────────────────

# The move / item ids this round allows; [] when the fight has no coach or
# sets no limit for the round.
static func coach_allowed(cp: Dictionary) -> Array:
	if not cp.get("coach") is Dictionary or cp["outcome"] != null:
		return []
	return cp["coach"].get("allowed", {}).get(str(cp["round"]), [])


# This round's lesson line, "" for none.
static func coach_lesson(cp: Dictionary) -> String:
	if not cp.get("coach") is Dictionary or cp["outcome"] != null:
		return ""
	return str(cp["coach"].get("lessons", {}).get(str(cp["round"]), ""))


# Whether the fight shows coach marks at all.
static func coach_active(cp: Dictionary) -> bool:
	return cp.get("coach") is Dictionary and cp["outcome"] == null


# The default hint line for a move or item id, "" for none.
static func coach_hint(id: String) -> String:
	return str(GameData.COMBAT_ROUNDS["coach"]["hints"].get(id, ""))


# ── Demo fights (R§3.7b Demo fights) ─────────────────────────────────────

static func is_demo(cp: Dictionary) -> bool:
	return cp.get("demo") is Dictionary


static func is_spar(cp: Dictionary) -> bool:
	return cp.get("spar") is Dictionary


# Shows a demo fight's next beat (the player sits out, so nothing pauses for
# a pick) and returns it as [beat]; a round resolves whole into the demo's
# `queue` and its beats go to the log and transcript one per call. The
# fight ends `fled` once its last round's last beat has shown.
static func demo_continue(cp: Dictionary) -> Array:
	_demo_fill(cp)
	if not is_demo(cp) or cp["demo"]["queue"].is_empty():
		return []
	var beats: Array = [cp["demo"]["queue"].pop_front()]
	_record(cp, beats)
	_demo_finish(cp)
	return beats


# Shows the rest of a demo fight's round at once (the next whole round when
# none is part-shown) and returns its beats.
static func demo_step(cp: Dictionary) -> Array:
	_demo_fill(cp)
	if not is_demo(cp):
		return []
	var beats: Array = cp["demo"]["queue"]
	cp["demo"]["queue"] = []
	_record(cp, beats)
	_demo_finish(cp)
	return beats


# A demo's beats resolved but not yet shown.
static func demo_queue(cp: Dictionary) -> Array:
	return cp["demo"]["queue"] if is_demo(cp) else []


# What Arnie's voiceover box shows: the last shown beat's coach note, else
# the transcript's last line (the intro before the first beat).
static func demo_voiceover(cp: Dictionary) -> String:
	if not cp["log"].is_empty() and cp["log"][-1].has("coachNote"):
		return str(cp["log"][-1]["coachNote"])
	return str(cp["transcript"][-1]) if not cp["transcript"].is_empty() else ""


# Resolves the demo's next round into its queue when nothing is waiting.
static func _demo_fill(cp: Dictionary) -> void:
	if not is_demo(cp) or cp["outcome"] != null or not cp["demo"]["queue"].is_empty():
		return
	if int(cp["round"]) > int(cp["demo"]["rounds"]):
		return
	cp["demo"]["upTo"] = int(cp["round"])
	var rng := RandomNumberGenerator.new()
	rng.state = cp["rngState"]
	var beats: Array = []
	_advance(cp, rng, beats)
	cp["rngState"] = rng.state
	cp["demo"]["queue"] = beats


static func _demo_finish(cp: Dictionary) -> void:
	if cp["outcome"] == null and cp["demo"]["queue"].is_empty() and int(cp["round"]) > int(cp["demo"]["rounds"]):
		cp["outcome"] = "fled"


# Whether the demo's unspent forced `kind` proc ("autoguard" or "retaliate")
# for combatant `idx` fires now, marking it spent.
static func _take_demo_proc(cp: Dictionary, kind: String, idx: int) -> bool:
	if not is_demo(cp):
		return false
	for proc in cp["demo"]["procs"]:
		if not proc.get("spent", false) and proc["kind"] == kind and int(proc["target"]) == idx:
			proc["spent"] = true
			return true
	return false


# ── Pearl lock (R§3.7b Pearl lock) ───────────────────────────────────────

# Whether the fight's pearl lock still waits on its item: the player holds
# an unspent unit of it in a loadout slot and has played none.
static func _pearl_pending(cp: Dictionary) -> bool:
	var lock: Variant = cp.get("pearlLock")
	if not lock is Dictionary or cp["outcome"] != null:
		return false
	var units: Array = cp["combatants"][PLAYER_INDEX]["loadout"].filter(func(s): return s["item"] == lock["item"])
	return units.any(func(s): return not s["used"]) and not units.any(func(s): return s["used"])


# Whether a still-pending pearl lock has engaged: a standing enemy is below
# its enemyBelowHp, so the lock's item is the only playable command.
static func pearl_locked(cp: Dictionary) -> bool:
	if not _pearl_pending(cp):
		return false
	var below := int(cp["pearlLock"]["enemyBelowHp"])
	return cp["combatants"].any(func(c): return c["side"] == SIDE_ENEMY and not c["koed"] and int(c["hp"]) < below)


# The line a lock shows in place of the round's lesson (a scripted fight's
# prompt, or the pearl lock's), "" while unlocked.
static func lock_prompt(cp: Dictionary) -> String:
	if pearl_locked(cp):
		return str(cp["pearlLock"]["prompt"])
	return script_prompt(cp)


# Whether the fight's pearl lock item has been played: a loadout unit of it
# is spent.
static func _pearl_played(cp: Dictionary) -> bool:
	var lock: Variant = cp.get("pearlLock")
	return lock is Dictionary and cp["combatants"][PLAYER_INDEX]["loadout"].any(func(s): return s["item"] == lock["item"] and s["used"])


# Whether the fight's pearl lock has its enemies counter the player's picks:
# until its item is played.
static func _counters(cp: Dictionary) -> bool:
	var lock: Variant = cp.get("pearlLock")
	return lock is Dictionary and bool(lock.get("raiderCounters", false)) and not _pearl_played(cp)


# Whether every player hit crits: the pearl lock asks for it and its item
# has been played.
static func _pearl_crits(cp: Dictionary) -> bool:
	var lock: Variant = cp.get("pearlLock")
	return lock is Dictionary and bool(lock.get("pearlCrits", false)) and _pearl_played(cp)


# Whether a countering enemy answers the player's `move_id` pick: a Guard,
# or a Strike, Feint or Stun.
static func _countered(move_id: String) -> bool:
	return not is_item(move_id) and (move_id == MOVE_GUARD or move(move_id)["effect"] in [EFFECT_DAMAGE, EFFECT_OPEN, EFFECT_STUN])


# In a countering fight, each standing enemy rewrites its unresolved
# action at `index` to answer the player's pick there: Guard against a
# Strike, Feint or Stun; against a Guard, a Feint, or a Strike straight
# after its own Feint. Item and Leg it picks leave its plan as rolled.
# The rewritten action then resolves ahead of the pick (_acts_before()).
static func _counter_pick(cp: Dictionary, index: int, move_id: String) -> void:
	if not _counters(cp) or not _countered(move_id):
		return
	var attack := move_id != MOVE_GUARD
	for e in side_indices(cp, SIDE_ENEMY):
		var enemy: Dictionary = cp["combatants"][e]
		var plan: Array = enemy["plan"]
		if enemy["koed"] or index >= plan.size() or is_item(plan[index]["move"]) or is_resolved(cp, e, index):
			continue
		var reply := MOVE_GUARD
		if not attack:
			reply = MOVE_STRIKE if enemy["lastMove"] == MOVE_FEINT else MOVE_FEINT
		plan[index] = { "move": reply, "target": e if reply == MOVE_GUARD else PLAYER_INDEX, "part": 0, "unread": plan[index].get("unread", false) }


# Whether a countering fight's enemies act just ahead of the player: at
# every action, picked or not, this round and next, so the timeline never
# reorders as picks land.
static func _counter_ahead(cp: Dictionary, _index: int, _round_no: int) -> bool:
	return _counters(cp)


# ── Scripted fights (R§3.7b Scripted fights) ─────────────────────────────

# Whether the fight is a scripted one still before its Rewind.
static func _script_pre(cp: Dictionary) -> bool:
	return cp.get("script") is Dictionary and cp["script"]["phase"] == SCRIPT_PRE


# Whether the player has fallen below the script's lock HP: every move and
# item is blocked and only the Rewind is open.
static func script_locked(cp: Dictionary) -> bool:
	return _script_pre(cp) and cp["outcome"] == null and int(cp["combatants"][PLAYER_INDEX]["hp"]) < int(cp["script"]["lockBelowHp"])


# The script's prompt line while locked, else "".
static func script_prompt(cp: Dictionary) -> String:
	return str(cp["script"]["prompt"]) if script_locked(cp) else ""


# The unspent forced hit `actor_idx` lands on `target_idx` before the
# Rewind ({ crit, ko }), marked spent; {} for none.
static func _take_forced_hit(cp: Dictionary, actor_idx: int, target_idx: int) -> Dictionary:
	if not _script_pre(cp):
		return {}
	for hit in cp["script"]["forcedHits"]:
		if not hit.get("spent", false) and int(hit["actor"]) == actor_idx and int(hit["target"]) == target_idx:
			hit["spent"] = true
			return hit
	return {}


# A scripted plan for `actor` from `entries`, each a move id or { move,
# target?, slot? }; a missing target is the actor for a self move, else -1.
static func _script_plan(cp: Dictionary, actor: int, entries: Array) -> Array:
	var plan: Array = []
	for entry in entries:
		var step: Dictionary = entry.duplicate() if entry is Dictionary else { "move": entry }
		var target_kind: String = move(step["move"]).get("target", "")
		step["target"] = int(step.get("target", actor if target_kind == TARGET_SELF else -1))
		step["part"] = 0
		if step.has("slot"):
			step["slot"] = int(step["slot"])
		plan.append(step)
	return plan


# The script's post-Rewind beats, set on the restored opening: the allies'
# round-1 plans, the player's picks played for them with a Leg it that can't
# fail, and no sucker punch ahead of the room.
static func _begin_script_post(cp: Dictionary) -> void:
	var script: Dictionary = cp["script"]
	script["phase"] = SCRIPT_POST
	cp["enemyFirst"] = false
	var post: Dictionary = script["post"]
	for key in post.get("allyPlans", {}).keys():
		var actor := int(key)
		cp["combatants"][actor]["plan"] = _script_plan(cp, actor, post["allyPlans"][key])
	cp["playerPlan"] = _script_plan(cp, PLAYER_INDEX, post["playerPlan"])
	cp["combatants"][PLAYER_INDEX]["fleeBoost"] = 1.0


static func _span_reason(move_id: String) -> String:
	return "%s takes %d actions in a row." % [move(move_id)["name"], move_cost(move_id)]


# A player action as { move, target } (plus slot for an item, dial for a
# Dial cast): an item action named by its loadout slot or Dial cast takes
# that unit's item as its move; a self-targeted one aims at the player, an
# all-enemies one or a multi-target unit at nobody (-1), and an unset target
# (-1) at the first of target_options().
static func _normalize_action(cp: Dictionary, action) -> Variant:
	if action == null:
		return null
	var move_id: String = str(action.get("move", ""))
	var target: int = int(action.get("target", -1))
	var unit := _player_unit(cp, action)
	if action.has("slot") or action.has("dial"):
		move_id = unit.get("item", "")
	var m := move(move_id)
	if not m.is_empty():
		var options := target_options(cp, PLAYER_INDEX, move_id)
		if m["target"] == TARGET_SELF:
			target = PLAYER_INDEX
		elif m["target"] == TARGET_ALL_ENEMIES or bool(unit.get("multi", false)):
			target = -1
		elif target < 0:
			target = options[0] if not options.is_empty() else -1
	var result := { "move": move_id, "target": target }
	for key in ["slot", "dial"]:
		if action.has(key):
			result[key] = int(action[key])
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
			return _team(cp, actor)
	return []


# `actor` then each living teammate.
static func _team(cp: Dictionary, actor: int) -> Array:
	var combatants: Array = cp["combatants"]
	var enemy_side: bool = combatants[actor]["side"] == SIDE_ENEMY
	var result: Array = [actor]
	for i in range(combatants.size()):
		if i != actor and (combatants[i]["side"] == SIDE_ENEMY) == enemy_side and not combatants[i]["koed"]:
			result.append(i)
	return result


static func _action_block_reason(cp: Dictionary, action) -> String:
	var m := move(action["move"])
	if m.is_empty():
		return "Unknown move."
	if m.get("item", false):
		if action.has("dial"):
			if float(cp["combatants"][PLAYER_INDEX]["dial"]["charge"]) < 1.0:
				return REASON_NO_CHARGE
		elif not action.has("slot"):
			return "Items come out of your loadout."
		elif cp["combatants"][PLAYER_INDEX]["loadout"][action["slot"]]["used"]:
			return "That one's spent."
	var multi := bool(_player_unit(cp, action).get("multi", false))
	if m["target"] in [TARGET_ENEMY, TARGET_FRIEND] and not multi and not target_options(cp, PLAYER_INDEX, action["move"]).has(action["target"]):
		return "Pick a target."
	if m["effect"] in PAN_EFFECTS and _pan_targets(cp, PLAYER_INDEX, int(action["target"]), multi).is_empty():
		return REASON_PAN_STATUSED
	return ""


# The player's unit a raw action names: its loadout slot's entry, or its
# Dial cast; {} for neither or an index out of range.
static func _player_unit(cp: Dictionary, action: Dictionary) -> Dictionary:
	var player: Dictionary = cp["combatants"][PLAYER_INDEX]
	var units: Array = []
	var index := -1
	if action.has("slot"):
		units = player["loadout"]
		index = int(action["slot"])
	elif action.has("dial") and player.get("dial") is Dictionary:
		units = player["dial"]["casts"]
		index = int(action["dial"])
	return units[index] if index >= 0 and index < units.size() else {}


# ── Read-only helpers for the screen ─────────────────────────────────────

# This round's actions in resolution order: action index, then speed
# descending, then combatant order (player first). Each entry is
# { actor, index }; the player's entries cover each of its actions this
# round, picked or not (an Enhancement Powder resolved this round adds one).
static func timeline(cp: Dictionary) -> Array:
	var combatants: Array = cp["combatants"]
	var entries: Array = []
	for i in range(combatants.size()):
		if combatants[i]["koed"]:
			continue
		var count: int = actions_this_round(cp, i) if i == PLAYER_INDEX else _plan_of(cp, i).size()
		for a in range(count):
			entries.append({ "actor": i, "index": a })
	entries.sort_custom(func(x, y): return _acts_before(cp, x["actor"], x["index"], y["actor"], y["index"]))
	return entries


# Timeline order in round `round_no` (default the current one): action
# index, then speed descending, then combatant order. A fight opened with
# enemyFirst puts enemies ahead of friendlies at each index of round 1.
static func _acts_before(cp: Dictionary, actor_a: int, index_a: int, actor_b: int, index_b: int, round_no: int = -1) -> bool:
	if index_a != index_b:
		return index_a < index_b
	if round_no < 0:
		round_no = int(cp["round"])
	var enemy_a: bool = cp["combatants"][actor_a]["side"] == SIDE_ENEMY
	var enemy_b: bool = cp["combatants"][actor_b]["side"] == SIDE_ENEMY
	if bool(cp.get("enemyFirst", false)) and round_no == 1 and enemy_a != enemy_b:
		return enemy_a
	# A countering fight's enemies slot in just ahead of the player at an
	# action the player has picked (_counter_pick()).
	if enemy_a != enemy_b and _counter_ahead(cp, index_a, round_no):
		if enemy_a:
			return actor_b == PLAYER_INDEX or _acts_before(cp, PLAYER_INDEX, index_a, actor_b, index_b, round_no)
		return actor_a != PLAYER_INDEX and _acts_before(cp, actor_a, index_a, PLAYER_INDEX, index_b, round_no)
	var speed_a: int = cp["combatants"][actor_a]["speed"]
	var speed_b: int = cp["combatants"][actor_b]["speed"]
	if speed_a != speed_b:
		return speed_a > speed_b
	# Player, then allies, then enemies: a reinforcement sits after the
	# enemies in combatant order but ties on its side's rank.
	var rank_a := _side_rank(cp, actor_a)
	var rank_b := _side_rank(cp, actor_b)
	if rank_a != rank_b:
		return rank_a < rank_b
	return actor_a < actor_b


static func _side_rank(cp: Dictionary, actor: int) -> int:
	match cp["combatants"][actor]["side"]:
		SIDE_PLAYER:
			return 0
		SIDE_ALLY:
			return 1
	return 2


# The combatant indices on `side`, in combatant order: the i-th ally is the
# fight's allies[i] (entrants join both at the end).
static func side_indices(cp: Dictionary, side: String) -> Array:
	var result: Array = []
	var combatants: Array = cp["combatants"]
	for i in range(combatants.size()):
		if combatants[i]["side"] == side:
			result.append(i)
	return result


static func _plan_of(cp: Dictionary, actor: int) -> Array:
	return cp["playerPlan"] if actor == PLAYER_INDEX else cp["combatants"][actor]["plan"]


# What the player can read of enemy `actor`'s plan for this round, or with
# next_round its pre-rolled plan for the round after. Each entry is
# { move, name }; under Prophet's Breath sight it adds target and, for a
# damage move, dmgMin/dmgMax (the roll range before guard and crit). Without
# sight next round reads as [] (spec user stories 12-13). An action that
# isn't read (is_read()) is { move: "", name: "", unread: true }; a status
# turn (status_turn()) reads { move: its status, name, status: true }; a
# furious enemy's actions read as fury_move()'s, its Strike or Stun carrying
# targetUnread in place of a target (R§3.7b Table 4).
static func enemy_intents(cp: Dictionary, actor: int, next_round: bool = false) -> Array:
	var sight := has_sight(cp)
	if next_round and not sight:
		return []
	var result: Array = []
	var plan: Array = cp["combatants"][actor]["nextPlan" if next_round else "plan"]
	for index in range(plan.size()):
		var action: Dictionary = plan[index]
		var status := status_turn(cp, actor, index, next_round)
		if status != "":
			result.append({ "move": status, "name": _data()["statusTurns"][status]["name"], "status": true })
			continue
		if not next_round and not is_read(cp, actor, index):
			result.append({ "move": "", "name": "", "unread": true })
			continue
		var move_id := fury_move(cp, actor, action["move"])
		var m := move(move_id)
		var intent := { "move": move_id, "name": m["name"] }
		var furious: bool = _is_furious(cp, actor) and m["effect"] in [EFFECT_DAMAGE, EFFECT_STUN]
		if furious:
			intent["targetUnread"] = true
		if sight:
			if not furious:
				intent["target"] = int(action["target"])
			if m["effect"] == EFFECT_DAMAGE:
				var roll_range := damage_range(cp, actor)
				intent["dmgMin"] = roll_range[0]
				intent["dmgMax"] = roll_range[1]
		result.append(intent)
	return result


# What the player can see of `actor`'s move levels, per levelled move
# { id, name, level } with level 0 for unknown. An enemy's level shows once it
# has used the move this fight or has a read action of it planned this round
# (enemy_intents()); everyone else's always shows (R§3.7b Move levels).
static func move_levels_seen(cp: Dictionary, actor: int) -> Array:
	var combatant: Dictionary = cp["combatants"][actor]
	var known: Dictionary = combatant.get("usedMoves", {}).duplicate()
	if combatant["side"] == SIDE_ENEMY:
		for intent in enemy_intents(cp, actor):
			if intent.get("move", "") != "" and not intent.has("status"):
				known[intent["move"]] = true
	var rows: Array = []
	for move_id in MoveLevels.move_ids():
		var seen: bool = combatant["side"] != SIDE_ENEMY or known.has(move_id)
		rows.append({ "id": move_id, "name": str(move(move_id)["name"]), "level": move_level(combatant, move_id) if seen else 0 })
	return rows


# The long-press panel for combatant `actor`: { title, rows } from
# move_levels_seen(), rows the "Move: Lv3" / "Move: ?" lines (moveBook.fighterPeek).
static func fighter_peek(cp: Dictionary, actor: int) -> Dictionary:
	var text: Dictionary = _data()["moveBook"]["fighterPeek"]
	var combatant: Dictionary = cp["combatants"][actor]
	var rows: Array = []
	for row in move_levels_seen(cp, actor):
		var level_text: String = str(text["levelUnknown"]) if int(row["level"]) == 0 else str(text["levelKnown"]).replace("{level}", str(row["level"]))
		rows.append(str(text["row"]).replace("{move}", row["name"]).replace("{level}", level_text))
	return {
		"title": str(text["title"]).replace("{name}", display_name(combatant)).replace("{level}", str(combatant["level"])),
		"rows": rows, "statuses": status_peek_lines(cp, actor),
	}


# Next round's actions in timeline order, as timeline() entries: each
# enemy's pre-rolled next plan, and the player's and each ally's
# actions_next_round(). Known with or without sight; sight only reads them.
static func next_round_timeline(cp: Dictionary) -> Array:
	var combatants: Array = cp["combatants"]
	var entries: Array = []
	for i in range(combatants.size()):
		if combatants[i]["koed"]:
			continue
		var count: int = combatants[i]["nextPlan"].size() if combatants[i]["side"] == SIDE_ENEMY else actions_next_round(cp, i)
		for a in range(count):
			entries.append({ "actor": i, "index": a })
	var next_round: int = int(cp["round"]) + 1
	entries.sort_custom(func(x, y): return _acts_before(cp, x["actor"], x["index"], y["actor"], y["index"], next_round))
	return entries


# Whether the player can read `actor`'s action `index` this round: always
# for the player and allies; for an enemy, unless it rolled unread, while
# Prophet's Breath sight lasts, once the action has resolved, or where a
# status turn takes it; a countering fight's enemies only once resolved.
static func is_read(cp: Dictionary, actor: int, index: int) -> bool:
	var combatant: Dictionary = cp["combatants"][actor]
	if combatant["side"] != SIDE_ENEMY or status_turn(cp, actor, index) != "":
		return true
	# A countering enemy's plan answers picks not yet made.
	if _counters(cp):
		return is_resolved(cp, actor, index)
	if has_sight(cp):
		return true
	var plan: Array = combatant["plan"]
	if index >= plan.size() or not plan[index].get("unread", false):
		return true
	return is_resolved(cp, actor, index)


# Whether `actor`'s action `index` on this round's timeline has resolved.
static func is_resolved(cp: Dictionary, actor: int, index: int) -> bool:
	var cursor: Dictionary = cp["cursor"]
	if int(cursor["index"]) < 0:
		return false
	if actor == int(cursor["actor"]) and index == int(cursor["index"]):
		return true
	return _acts_before(cp, actor, index, cursor["actor"], cursor["index"])


# A combatant's guard state now, then after each of its planned actions
# this round (an unfilled player action leaves it unchanged). With
# next_round, an enemy's state as this round leaves it, then after each
# action of its pre-rolled next plan. An unread enemy action this round
# leaves it UNKNOWN until a read action sets its guard; a status turn sets
# its own (_planned_guard()).
static func guard_preview(cp: Dictionary, actor: int, next_round: bool = false) -> Array:
	var state: String = cp["combatants"][actor]["guard"]
	var plan: Array = _plan_of(cp, actor)
	if next_round:
		state = guard_preview(cp, actor).back()
		plan = cp["combatants"][actor]["nextPlan"]
	var result: Array = [state]
	for index in range(plan.size()):
		var action = plan[index]
		if action != null:
			var effect := _planned_guard(cp, actor, index, action, next_round)
			if effect != UNCHANGED:
				state = effect
		result.append(state)
	return result


# The guard effect `actor`'s planned `action` at `index` (this round, or
# next_round's) has as the player reads it: a status turn's, UNKNOWN for an
# unread action this round, else the move's.
static func _planned_guard(cp: Dictionary, actor: int, index: int, action: Dictionary, next_round: bool = false) -> String:
	var status := status_turn(cp, actor, index, next_round)
	if status != "":
		return _data()["statusTurns"][status]["actorGuard"]
	if not next_round and not is_read(cp, actor, index):
		return UNKNOWN
	return move(fury_move(cp, actor, action["move"])).get("actorGuard", UNCHANGED)


# ── Resolution ───────────────────────────────────────────────────────────

# Resolves the timeline from the cursor, appending to `beats`, until the
# player's next unpicked position (the cursor pauses there) or the fight
# ends. A KO'd combatant's remaining actions are dropped, as are a Leg it's
# actor's later ones and any lost to a Stun, Time Pearl or Black Hole; a
# player position lost that way, or taken by an earlier pick's later part,
# plays without a pause. At the end of a round next round's plans move up,
# the round after's are rolled, and resolution carries on into it. A player
# KO the fight survives (friendlies still standing) stops resolution there
# until continue_after_ko(), so a Failsafe can undo it first.
static func _advance(cp: Dictionary, rng: RandomNumberGenerator, beats: Array) -> void:
	var combatants: Array = cp["combatants"]
	var cursor: Dictionary = cp["cursor"]
	while cp["outcome"] == null:
		if combatants[PLAYER_INDEX]["koed"] and not cp.get("playerKoed", false):
			break
		# A demo fight resolves a round at a time (_demo_fill()).
		if is_demo(cp) and int(cp["round"]) > int(cp["demo"]["upTo"]):
			break
		cp["playerPlan"].resize(maxi(cp["playerPlan"].size(), actions_this_round(cp, PLAYER_INDEX)))
		var entry := _next_entry(cp)
		if entry.is_empty() or _awaiting_enemy_reserves(cp):
			_end_round(cp, rng, beats)
			cursor = cp["cursor"]
			continue
		var actor: int = entry["actor"]
		var combatant: Dictionary = combatants[actor]
		var action = _plan_of(cp, actor)[entry["index"]]
		if not cursor["done"].has(actor) and combatant["actionsLost"] == 0 and action == null:
			cursor["pause"] = entry["index"]
			return
		if _awaits_counter_pick(cp, actor, entry["index"]):
			cursor["pause"] = entry["index"]
			return
		cursor["index"] = entry["index"]
		cursor["actor"] = actor
		if cursor["done"].has(actor):
			continue
		if combatant["actionsLost"] > 0:
			combatant["actionsLost"] -= 1
			_tick_open(combatant)
			var frozen: bool = combatant["frozenActions"] > 0
			combatant["frozenActions"] = maxi(0, combatant["frozenActions"] - 1)
			_beat(cp, beats, "frozen" if frozen else "lost", actor, -1, action["move"] if action != null else "", {})
			beats[-1]["marks"] = stage_marks(cp)
			continue
		var fleeing: bool = move(fury_move(cp, actor, action["move"]))["effect"] == EFFECT_FLEE
		var flee_failed := _resolve_action(cp, actor, action, rng, beats)
		if fleeing and not (flee_failed and move_level(combatant, fury_move(cp, actor, action["move"])) >= int(level_effects("legIt")["keepActionsLevel"])):
			cursor["done"].append(actor)
	cursor["pause"] = -1


# Whether a countering enemy's action at `index` waits on the player's pick
# there: the enemy resolves ahead of the player but answers the pick
# (_counter_pick()), so the fight pauses on the enemy's slot.
static func _awaits_counter_pick(cp: Dictionary, actor: int, index: int) -> bool:
	if actor == PLAYER_INDEX or not _counters(cp) or cp["combatants"][actor]["side"] != SIDE_ENEMY:
		return false
	var player: Dictionary = cp["combatants"][PLAYER_INDEX]
	var plan: Array = cp["playerPlan"]
	return not cp["cursor"]["done"].has(PLAYER_INDEX) and player["actionsLost"] == 0 and not player["koed"] and index < plan.size() and plan[index] == null


# One of the combatant's action slots (acted or lost) passes a Stun L5 hold.
static func _tick_open(combatant: Dictionary) -> void:
	if int(combatant.get("openActions", 0)) > 0:
		combatant["openActions"] -= 1


# The first timeline entry after the cursor's, or {} once the round's done.
static func _next_entry(cp: Dictionary) -> Dictionary:
	var cursor: Dictionary = cp["cursor"]
	for entry in timeline(cp):
		if _acts_before(cp, cursor["actor"], cursor["index"], entry["actor"], entry["index"]):
			return entry
	return {}


# The plans moving up were on show under sight through the round just ended
# when the player had it, so they all commit read. A disarmed ability's
# lock ticks down a round. Kit units the round left reserved go back to
# their pools before the new plans commit theirs. Reinforcements join first
# (_admit_reserves()), an entering enemy rolling this round's plan fresh.
static func _end_round(cp: Dictionary, rng: RandomNumberGenerator, beats: Array) -> void:
	var combatants: Array = cp["combatants"]
	var seen := has_sight(cp)
	cp["round"] += 1
	var fog_rng := RandomNumberGenerator.new()
	fog_rng.state = int(cp["fogRngState"])
	# The new round's cursor first: the ally AI's is_read() sees nothing of
	# it resolved, and entry beats name no timeline position.
	cp["cursor"] = _new_cursor()
	var entrants := _admit_reserves(cp, rng, fog_rng, beats)
	_release_kits(cp)
	var patients: Array = []
	for i in range(combatants.size()):
		combatants[i]["firstHitSpent"] = false
		var ability = combatants[i]["ability"]
		if ability is Dictionary and int(ability["lockedTurns"]) > 0:
			ability["lockedTurns"] -= 1
		if combatants[i]["side"] == SIDE_ENEMY:
			combatants[i]["plan"] = _recommit_targets(cp, i, combatants[i]["nextPlan"], rng)
			if seen and not entrants.has(i):
				for action in combatants[i]["plan"]:
					action["unread"] = false
			if not combatants[i]["koed"]:
				_commit_kit_item(cp, i, patients)
			combatants[i]["nextPlan"] = [] if combatants[i]["koed"] else _roll_plan(cp, i, cp["round"] + 1, rng)
			_roll_fog(cp, i, combatants[i]["nextPlan"], cp["round"] + 1, fog_rng)
	cp["fogRngState"] = fog_rng.state
	_plan_allies(cp, rng)
	cp["playerPlan"] = _empty_player_plan(cp)


# R§3.7b Reinforcements: while a side has fewer than SQUAD_SIZE standing,
# the next entry of its queue joins: its prebuilt "fighter" becomes a new
# combatant at the end of the order, the entry itself joins the fight's
# live roster (ROSTER_KEYS) where it keeps one. An enemy entrant's plan for
# the round now starting rolls here (as its nextPlan, which the round end
# moves up); an ally's comes from _plan_allies(). Returns the entrants'
# combatant indices.
static func _admit_reserves(cp: Dictionary, rng: RandomNumberGenerator, fog_rng: RandomNumberGenerator, beats: Array) -> Array:
	var combatants: Array = cp["combatants"]
	var entrants: Array = []
	for side in [SIDE_ALLY, SIDE_ENEMY]:
		var queue: Array = cp.get(QUEUE_KEYS[side], [])
		while not queue.is_empty() and _standing(cp, side) < SQUAD_SIZE:
			var entry: Dictionary = queue.pop_front()
			var fighter: Dictionary = entry["fighter"]
			entry.erase("fighter")
			combatants.append(fighter)
			var index := combatants.size() - 1
			if cp.has(ROSTER_KEYS[side]):
				cp[ROSTER_KEYS[side]].append(entry)
			if side == SIDE_ENEMY:
				fighter["nextPlan"] = _roll_plan(cp, index, cp["round"], rng)
				_roll_fog(cp, index, fighter["nextPlan"], cp["round"], fog_rng)
			_beat(cp, beats, "enter", index, -1, "", {})
			entrants.append(index)
	return entrants


# No enemy left standing with reinforcements waiting: the round ends at
# once so they come in (R§3.7b KO and outcome).
static func _awaiting_enemy_reserves(cp: Dictionary) -> bool:
	return _standing(cp, SIDE_ENEMY) == 0 and not cp.get(QUEUE_KEYS[SIDE_ENEMY], []).is_empty()


# Standing fighters on `side`, the player counting with the allies.
static func _standing(cp: Dictionary, side: String) -> int:
	var count := 0
	for c in cp["combatants"]:
		if not c["koed"] and (c["side"] == SIDE_ENEMY) == (side == SIDE_ENEMY):
			count += 1
	return count


# R§3.7a Player KO: once no Failsafe or ally rewind has undone the player's
# KO, the fight plays on without them -- their actions gone from the
# timeline, never paused for -- to its end. Returns the beats that resolved
# ([] when the player isn't newly down or the KO already ended the fight).
static func continue_after_ko(cp: Dictionary) -> Array:
	var beats: Array = []
	if not cp["combatants"][PLAYER_INDEX]["koed"] or cp.get("playerKoed", false) or cp["outcome"] != null:
		return beats
	cp["playerKoed"] = true
	var rng := RandomNumberGenerator.new()
	rng.state = cp["rngState"]
	_advance(cp, rng, beats)
	_record(cp, beats)
	cp["rngState"] = rng.state
	return beats


# Applies the move's effect (fury_move()'s), then its effect on the actor's guard state;
# a Panic or Pan's Rapture turn plays instead while one runs, and the
# action ticks a running anger down. A failed Guard (Feint) leaves the actor
# Open and spends the failure. True when a Leg it failed.
static func _resolve_action(cp: Dictionary, actor_idx: int, action: Dictionary, rng: RandomNumberGenerator, beats: Array) -> bool:
	var move_id: String = fury_move(cp, actor_idx, action["move"])
	var m := move(move_id)
	var actor: Dictionary = cp["combatants"][actor_idx]
	var first_beat := beats.size()
	var flee_failed := false
	if actor.get("dial") is Dictionary:
		actor["dial"]["actions"] = int(actor["dial"].get("actions", 0)) + 1
	if _play_status_turn(cp, actor_idx, rng, beats):
		actor["lastMove"] = ""
		_stamp_marks(cp, actor_idx, first_beat, beats)
		return false
	if MoveLevels.move_ids().has(move_id):
		actor["usedMoves"] = actor.get("usedMoves", {})
		actor["usedMoves"][move_id] = true
	match m["effect"]:
		EFFECT_DAMAGE:
			var target := _fury_target(cp, actor_idx, rng)
			if target < 0:
				target = _retarget(cp, actor_idx, int(action["target"]))
			if target >= 0:
				_strike(cp, actor_idx, target, move_id, rng, beats)
		EFFECT_OPEN:
			var target := _retarget(cp, actor_idx, int(action["target"]))
			if target >= 0:
				_feint(cp, actor_idx, target, move_id, beats)
		EFFECT_STUN:
			var target := _fury_target(cp, actor_idx, rng)
			if target < 0:
				target = _retarget(cp, actor_idx, int(action["target"]))
			if target >= 0:
				_stun(cp, actor_idx, target, move_id, m, rng, beats)
		EFFECT_FLEE:
			var chance := flee_chance(actor)
			var boosted: bool = float(actor["fleeBoost"]) > 0.0
			if boosted:
				chance = float(actor["fleeBoost"])
				actor["fleeBoost"] = 0.0
			# Before its Rewind a scripted fight's Leg it never gets away.
			if rng.randf() < chance and not (actor_idx == PLAYER_INDEX and _script_pre(cp)):
				_beat(cp, beats, "fled", actor_idx, -1, move_id, { "boosted": boosted })
				if actor_idx == PLAYER_INDEX:
					cp["outcome"] = "fled"
			else:
				_beat(cp, beats, "fleeFailed", actor_idx, -1, move_id, {})
				flee_failed = true
		EFFECT_NONE:
			_beat(cp, beats, move_id, actor_idx, -1, move_id, {})
		_:
			_use_item(cp, actor_idx, action, m, rng, beats)
	if beats.size() > first_beat and not m.get("item", false):
		_gain_move_xp(cp, actor_idx, move_id, FIZZLE_KINDS.has(beats[first_beat]["kind"]), beats)
	actor["lastMove"] = move_id
	if m["actorGuard"] != UNCHANGED and not actor["koed"]:
		actor["feintPct"] = 0
		if m["actorGuard"] == GUARDED and actor["guardFailed"]:
			actor["guardFailed"] = false
		else:
			actor["guard"] = m["actorGuard"]
	if flee_failed and not actor["koed"] and move_level(actor, move_id) >= int(level_effects(move_id)["guardedOnFailLevel"]):
		actor["guard"] = GUARDED
	_tick_anger(cp, actor_idx, beats)
	_tick_open(actor)
	_stamp_marks(cp, actor_idx, first_beat, beats)
	return flee_failed


# A move use's XP (MoveLevels.xp_for_use()) to the actor's persistent
# record, outside the fight dict so a Rewind keeps it; a level-up lifts its
# fight level too and beats "levelUp" (R§3.7b Move levels). Nothing for a
# fighter with no owner, or for a move not in moveXp.moves.
static func _gain_move_xp(cp: Dictionary, actor_idx: int, move_id: String, fizzled: bool, beats: Array) -> void:
	var actor: Dictionary = cp["combatants"][actor_idx]
	var owner = actor.get("moveOwner")
	if not (owner is String):
		return
	var xp := MoveLevels.xp_for_use(fizzled)
	if owner == "":
		Progression.award_bucket_share("body", xp)
	var level := MoveLevels.award(owner, move_id, xp)
	if level == 0:
		return
	actor["moveLevels"][move_id] = level
	_beat(cp, beats, "levelUp", actor_idx, -1, move_id, { "moveName": move(move_id)["name"], "level": level, "moveOwner": owner })


# Each of the action's beats from `first_beat` on gets the stage marks as
# it leaves the fight, and the actor's own its guard state.
static func _stamp_marks(cp: Dictionary, actor_idx: int, first_beat: int, beats: Array) -> void:
	var marks := stage_marks(cp)
	for i in range(first_beat, beats.size()):
		if beats[i]["actor"] == actor_idx:
			beats[i]["actorGuard"] = cp["combatants"][actor_idx]["guard"]
		beats[i]["marks"] = marks


# A Panic or Pan's Rapture turn in place of the actor's own action (R§3.7b
# Table 4), leaving it on its statusTurns guard: Panic bolts at boltChance
# (defeated, counted as a KO), else cowers; Rapture idles. False when
# neither runs.
static func _play_status_turn(cp: Dictionary, actor_idx: int, rng: RandomNumberGenerator, beats: Array) -> bool:
	var actor: Dictionary = cp["combatants"][actor_idx]
	var status := ""
	if int(actor["panicActions"]) > 0:
		status = STATUS_PANIC
		actor["panicActions"] -= 1
	elif int(actor["raptureActions"]) > 0:
		status = STATUS_RAPTURE
		actor["raptureActions"] -= 1
	else:
		return false
	actor["guard"] = _data()["statusTurns"][status]["actorGuard"]
	if status == STATUS_PANIC and rng.randf() < float(_data()["items"]["panic"]["params"]["boltChance"]):
		actor["hp"] = 0
		actor["koed"] = true
		actor["panicActions"] = 0
		_beat(cp, beats, "bolt", actor_idx, -1, "", { "status": status })
		_check_outcome(cp)
	else:
		_beat(cp, beats, "cower" if status == STATUS_PANIC else "enraptured", actor_idx, -1, "", { "status": status })
	return true


static func _is_furious(cp: Dictionary, actor: int) -> bool:
	var combatant: Dictionary = cp["combatants"][actor]
	return int(combatant["angerActions"]) > 0 and combatant["fury"]


# The move `actor` plays for its planned `move_id`: a furious actor with a
# teammate standing turns anything but a Strike or Stun into a Strike (at
# _fury_target()); else `move_id` (R§3.7b Table 4).
static func fury_move(cp: Dictionary, actor: int, move_id: String) -> String:
	if not _is_furious(cp, actor) or _team(cp, actor).size() < 2:
		return move_id
	return move_id if move(move_id).get("effect", "") in [EFFECT_DAMAGE, EFFECT_STUN] else MOVE_STRIKE


# A furious actor's Strike or Stun target: a random other living member of
# its own side; -1 when it isn't furious or stands alone (R§3.7b Table 4).
static func _fury_target(cp: Dictionary, actor_idx: int, rng: RandomNumberGenerator) -> int:
	if not _is_furious(cp, actor_idx):
		return -1
	var others := _team(cp, actor_idx).slice(1)
	if others.is_empty():
		return -1
	return others[rng.randi_range(0, others.size() - 1)]


# One of the actor's own resolved actions under Panger/Pandemonium; the
# last one ends it.
static func _tick_anger(cp: Dictionary, actor_idx: int, beats: Array) -> void:
	var actor: Dictionary = cp["combatants"][actor_idx]
	if int(actor["angerActions"]) == 0:
		return
	actor["angerActions"] -= 1
	if actor["angerActions"] == 0:
		actor["angerPct"] = 0
		actor["fury"] = false
		if not actor["koed"]:
			_beat(cp, beats, "calm", actor_idx, -1, "", {})


# Each combatant's stage overlay as the fight stands: { guard: guard_marker()
# ("" once KO'd), shielded (a Shield pool holds), frozen (a Time Pearl
# freeze holds), shieldFraction (shield_fraction()), frozenLeft (frozen actions still to pass), icons
# (status_icons()), powdered (an Enhancement Powder runs), openLeft (Stun hold-open actions still to pass) }.
static func stage_marks(cp: Dictionary) -> Array:
	var marks: Array = []
	for i in range(cp["combatants"].size()):
		var c: Dictionary = cp["combatants"][i]
		marks.append({
			"guard": "" if c["koed"] else guard_marker(cp, c),
			"shielded": int(c["shield"]) > 0, "shieldFraction": shield_fraction(c),
			"frozen": not c["koed"] and int(c["frozenActions"]) > 0,
			"frozenLeft": 0 if c["koed"] else int(c["frozenActions"]),
			"icons": status_icons(cp, i),
			"powdered": not c["koed"] and is_powered(cp, c),
			"openLeft": 0 if c["koed"] else int(c.get("openActions", 0)),
		})
	return marks


# The Shield pool left over the pool it was raised to, 0..1 (0 with none up).
static func shield_fraction(combatant: Dictionary) -> float:
	var pool := int(combatant["shield"])
	if pool <= 0:
		return 0.0
	return clampf(float(pool) / float(maxi(int(combatant.get("shieldMax", pool)), pool)), 0.0, 1.0)


# "open" or "guarded", in is_open()'s order: a freeze or Stun hold reads Open, a Shield
# pool Guarded, then the guard state.
static func guard_marker(_cp: Dictionary, combatant: Dictionary) -> String:
	if combatant["frozenActions"] > 0 or int(combatant.get("openActions", 0)) > 0:
		return OPEN
	if combatant["shield"] > 0:
		return GUARDED
	return combatant["guard"]


# Open for damage and conditions: frozen by a Time Pearl or held Open by a
# Stun L5 (openActions); else Guarded while
# a Shield pool lasts; else its own guard state is Open.
static func is_open(_cp: Dictionary, combatant: Dictionary) -> bool:
	if combatant["frozenActions"] > 0 or int(combatant.get("openActions", 0)) > 0:
		return true
	if combatant["shield"] > 0:
		return false
	return combatant["guard"] == OPEN


# Target goes Open and its next Guard action fails (it stays Open through
# it); on one already Open only the Guard failure is set.
static func _feint(cp: Dictionary, actor_idx: int, target_idx: int, move_id: String, beats: Array) -> void:
	var target: Dictionary = cp["combatants"][target_idx]
	target["guard"] = OPEN
	target["guardFailed"] = true
	var bonuses: Array = level_effects(move_id)["damageBonusPct"]
	target["feintPct"] = int(bonuses[move_level(cp["combatants"][actor_idx], move_id)])
	_beat(cp, beats, "feint", actor_idx, target_idx, move_id, {})


# Open target → loses its next params.actions actions (multiActions from
# multiActionLevel; its guard state stays as it was); a Guarded target
# shrugs it off, unless the stunner's per-level guardedChance gets through;
# Stun L5 also holds the target Open for openActions of its action slots
# (R§3.7b Removal, Move levels).
static func _stun(cp: Dictionary, actor_idx: int, target_idx: int, move_id: String, m: Dictionary, rng: RandomNumberGenerator, beats: Array) -> void:
	var target: Dictionary = cp["combatants"][target_idx]
	var fx := level_effects(move_id)
	var level := move_level(cp["combatants"][actor_idx], move_id)
	var through := false
	if m["condition"] == CONDITION_TARGET_OPEN and not is_open(cp, target):
		through = rng.randf() < float(fx["guardedChance"][level])
		if not through:
			_beat(cp, beats, "fizzle", actor_idx, target_idx, move_id, {})
			return
	var lost := int(m["params"]["actions"])
	if level >= int(fx["multiActionLevel"]):
		lost = maxi(lost, int(fx["multiActions"]))
	target["actionsLost"] += lost
	if level >= int(fx["openLevel"]):
		target["openActions"] = maxi(int(target.get("openActions", 0)), int(fx["openActions"]))
	_beat(cp, beats, "stunThrough" if through else "stun", actor_idx, target_idx, move_id, {})


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


# Damage rolls within the attacker's range: full on an Open
# target, round(roll × chipMultiplier) (min 1) on a Guarded one; a crit
# doubles the final figure (R§3.7b Damage), then the attacker's anger scales
# it (anger_factor()). Under Be a Lady the roll is the
# attacker's max and the crit chance its ladyCrit (R§3.7b Damage). An
# evade (evade_chance()) misses outright, before any roll.
static func _strike(cp: Dictionary, actor_idx: int, target_idx: int, move_id: String, rng: RandomNumberGenerator, beats: Array, free := false) -> void:
	var combatants: Array = cp["combatants"]
	var actor: Dictionary = combatants[actor_idx]
	var target: Dictionary = combatants[target_idx]
	var forced := _take_forced_hit(cp, actor_idx, target_idx)
	var evade := 0.0 if not forced.is_empty() else evade_chance(cp, actor, target)
	if evade > 0.0 and rng.randf() < evade:
		_beat(cp, beats, "evade", actor_idx, target_idx, move_id, {})
		return
	var lady := has_lady(cp, actor)
	var roll_range := damage_range(cp, actor_idx)
	var fx := level_effects(MOVE_STRIKE)
	var strike_level := move_level(actor, MOVE_STRIKE)
	var roll := rng.randi_range(roll_range[0], roll_range[1])
	var guarded: bool = not is_open(cp, target)
	if not guarded and _autoguards(cp, target_idx, rng):
		guarded = true
		_beat(cp, beats, "autoguard", target_idx, actor_idx, "feint", {})
	var dmg := roll
	if not guarded and int(target["feintPct"]) > 0:
		dmg = GameState.round_epsilon(roll * (100 + int(target["feintPct"])) / 100.0)
	if guarded:
		dmg = maxi(1, GameState.round_epsilon(roll * chip_multiplier(actor, target)))
	var crit_chance: float = float(actor["ladyCrit"]) if lady else float(_data()["critChance"][actor["level"]])
	if strike_level >= int(fx["critLevel"]):
		crit_chance += float(fx["critBonus"])
	var crit := rng.randf() < crit_chance
	if actor_idx == PLAYER_INDEX and _pearl_crits(cp):
		crit = true
	if not forced.is_empty():
		crit = bool(forced.get("crit", true))
		guarded = false
		dmg = roll
		if bool(forced.get("ko", false)):
			dmg = int(target["hp"]) + int(target["shield"])
	elif guarded and _guard_blocks(target, rng):
		_beat(cp, beats, "block", actor_idx, target_idx, move_id, { "dmg": 0, "hpAfter": target["hp"] })
		_retaliate(cp, actor_idx, target_idx, rng, beats, free)
		return
	if crit:
		dmg *= 2
	dmg = GameState.round_epsilon(dmg * anger_factor(actor, true))
	_deal_damage(cp, actor_idx, target_idx, dmg, "chip" if guarded else "hit", move_id, beats, {
		"roll": roll, "crit": crit, "guarded": guarded, "lady": lady,
	})
	_retaliate(cp, actor_idx, target_idx, rng, beats, free)


# Whether an Open `target` whose last resolved action was a Feint treats this
# hit as Guarded: its Feint level's autoguardChance (Feint passives).
static func _autoguards(cp: Dictionary, target_idx: int, rng: RandomNumberGenerator) -> bool:
	var target: Dictionary = cp["combatants"][target_idx]
	if target["lastMove"] != MOVE_FEINT:
		return false
	if _take_demo_proc(cp, "autoguard", target_idx):
		return true
	var chance := float(level_effects(MOVE_FEINT)["autoguardChance"][move_level(target, MOVE_FEINT)])
	return chance > 0.0 and rng.randf() < chance


# Feint L5 retaliation: after a Strike lands on a standing `target` whose last
# resolved action was a Feint, retaliateChance to Strike the attacker back
# free (no action spent). A free Strike never retaliates; it counts as a
# Strike use for the retaliator's move XP.
static func _retaliate(cp: Dictionary, attacker_idx: int, target_idx: int, rng: RandomNumberGenerator, beats: Array, free: bool) -> void:
	var target: Dictionary = cp["combatants"][target_idx]
	var fx := level_effects(MOVE_FEINT)
	if free or target["koed"] or target["lastMove"] != MOVE_FEINT or move_level(target, MOVE_FEINT) < int(fx["retaliateLevel"]):
		return
	if not _take_demo_proc(cp, "retaliate", target_idx) and rng.randf() >= float(fx["retaliateChance"]):
		return
	_beat(cp, beats, "retaliate", target_idx, attacker_idx, MOVE_STRIKE, {})
	var first := beats.size()
	_strike(cp, target_idx, attacker_idx, MOVE_STRIKE, rng, beats, true)
	if beats.size() > first:
		_gain_move_xp(cp, target_idx, MOVE_STRIKE, FIZZLE_KINDS.has(beats[first]["kind"]), beats)


# Whether a Guarded `target`'s Guard level fully blocks this hit: Guard L5's
# first hit each round (spent), else Guard L3's blockChance.
static func _guard_blocks(target: Dictionary, rng: RandomNumberGenerator) -> bool:
	var fx := level_effects(MOVE_GUARD)
	var level := move_level(target, MOVE_GUARD)
	if level >= int(fx["firstHitLevel"]) and not target.get("firstHitSpent", false):
		target["firstHitSpent"] = true
		return true
	return level >= int(fx["blockLevel"]) and rng.randf() < float(fx["blockChance"])


# The chance `target` evades a Strike from `actor`: its evadeChance, less
# Be a Lady's evadeCutPerTier per ladyTier on the attacker, floored at 0;
# none while it has actions to lose (stunned, frozen) (R§3.7b Evade).
static func evade_chance(cp: Dictionary, actor: Dictionary, target: Dictionary) -> float:
	if int(target["actionsLost"]) > 0:
		return 0.0
	var chance := float(target.get("evadeChance", 0.0))
	if has_lady(cp, actor):
		chance -= float(_data()["items"]["beALady"]["params"]["evadeCutPerTier"]) * int(actor.get("ladyTier", 0))
	return maxf(0.0, chance)


# `dmg`, scaled by the target's anger (anger_factor()), drains its Shield
# pool 1:1 before its HP (R§3.7b Damage); beats `kind` with dmg, absorbed and
# hpAfter, then the KO if it drops (an ally's own failsafe can hold it on
# 1 hp instead, _ally_failsafe()).
static func _deal_damage(cp: Dictionary, actor_idx: int, target_idx: int, dmg: int, kind: String, move_id: String, beats: Array, extra: Dictionary) -> void:
	var target: Dictionary = cp["combatants"][target_idx]
	dmg = GameState.round_epsilon(dmg * anger_factor(target, false))
	var absorbed: int = mini(target["shield"], dmg)
	target["shield"] -= absorbed
	target["hp"] = maxi(0, target["hp"] - (dmg - absorbed))
	# Before its Rewind a scripted fight can't be won or lost: only the
	# script's allies fall. A demo fight drops no one.
	# Nor can a pearl-locked one be won before its pearl.
	if target["hp"] == 0 and (is_demo(cp) or (_script_pre(cp) and target["side"] != SIDE_ALLY) or (target["side"] == SIDE_ENEMY and _pearl_pending(cp))):
		target["hp"] = 1
	var fields := { "dmg": dmg, "absorbed": absorbed, "hpAfter": target["hp"] }
	fields.merge(extra)
	_beat(cp, beats, kind, actor_idx, target_idx, move_id, fields)
	if target["hp"] == 0 and not _ally_failsafe(cp, target_idx, beats):
		target["koed"] = true
		_beat(cp, beats, "ko", actor_idx, target_idx, move_id, {})
		_check_outcome(cp)


# Applies an item's effect at `power` from the action's loadout slot, and
# spends the slot (R§3.7b Items); a Dial cast takes 1 of
# its Dial's charge instead (R§3.7b Dial Complications), and a kit action
# spends its reserved unit. A kit or ally item that fizzles whole
# (_item_fizzles()) spends nothing: the unit stays (R§3.7b Table 5). Item damage ignores
# guard. A multi-target unit (R§3.7b Items) Blasts every living opponent,
# Shields or heals the actor and every living teammate, and puts its Pan
# status on every living opponent not already under one.
static func _use_item(cp: Dictionary, actor_idx: int, action: Dictionary, m: Dictionary, rng: RandomNumberGenerator, beats: Array) -> void:
	var combatants: Array = cp["combatants"]
	var actor: Dictionary = combatants[actor_idx]
	var slot: Dictionary
	if action.has("kit"):
		slot = { "power": int(action["power"]), "multi": false }
	elif action.has("dial"):
		slot = actor["dial"]["casts"][int(action["dial"])]
	else:
		slot = actor["loadout"][int(action["slot"])]
	if (action.has("kit") or actor["side"] == SIDE_ALLY) and _item_fizzles(cp, actor_idx, action, m, bool(slot.get("multi", false))):
		if action.has("kit"):
			_kit_move(cp[action["kit"]], action["move"], str(int(action["tier"])), "reserved", "items")
		_beat(cp, beats, "fizzle", actor_idx, int(action["target"]), action["move"], {})
		return
	if action.has("kit"):
		_kit_move(cp[action["kit"]], action["move"], str(int(action["tier"])), "reserved", "used")
	elif action.has("dial"):
		actor["dial"]["charge"] -= 1
		actor["dial"]["spent"].append(int(slot["sourceIndex"]))
	else:
		slot["used"] = true
	var power: int = slot["power"]
	var multi: bool = slot.get("multi", false)
	var move_id: String = action["move"]
	match m["effect"]:
		ITEM_FREEZE:
			_beat(cp, beats, "timePearl", actor_idx, -1, move_id, { "affected": _living_opponents(cp, actor_idx) })
			for e in _living_opponents(cp, actor_idx):
				combatants[e]["actionsLost"] += power
				combatants[e]["frozenActions"] = combatants[e]["actionsLost"]
		ITEM_BLACK_HOLE:
			_beat(cp, beats, "blackHole", actor_idx, -1, move_id, { "affected": _living_opponents(cp, actor_idx) })
			var lost: int = int(slot.get("lost", int(m["params"]["actionsBase"]) + floori(power / float(m["params"]["powerPerAction"]))))
			for e in _living_opponents(cp, actor_idx):
				_deal_damage(cp, actor_idx, e, power, "pull", move_id, beats, {})
				combatants[e]["actionsLost"] += lost
				if cp["outcome"] != null:
					return
		ITEM_BLAST:
			actor["fleeBoost"] = float(m["params"]["fleeChance"])
			var targets: Array = _living_opponents(cp, actor_idx) if multi else [_retarget(cp, actor_idx, int(action["target"]))]
			for target in targets:
				if target >= 0 and not combatants[target]["koed"]:
					_deal_damage(cp, actor_idx, target, power, "blast", move_id, beats, {})
					if cp["outcome"] != null:
						return
					_maybe_disarm(cp, actor_idx, target, move_id, m["params"], rng, beats)
		ITEM_SHIELD:
			var shielded := int(action["target"]) if action.has("kit") else actor_idx
			for target in (_team(cp, actor_idx) if multi else [shielded]):
				combatants[target]["shield"] = maxi(combatants[target]["shield"], power)
				combatants[target]["shieldMax"] = combatants[target]["shield"]
			if shielded == actor_idx:
				_beat(cp, beats, "shield", actor_idx, -1, move_id, {})
			else:
				_beat(cp, beats, "shieldOther", actor_idx, shielded, move_id, {})
		ITEM_HEAL:
			for target in (_team(cp, actor_idx) if multi else [int(action["target"])]):
				var patient: Dictionary = combatants[target]
				if patient["koed"]:
					_beat(cp, beats, "fizzle", actor_idx, target, move_id, {})
					continue
				var healed: int = mini(power, patient["hpMax"] - patient["hp"])
				patient["hp"] += healed
				_beat(cp, beats, "healSelf" if target == actor_idx else "heal", actor_idx, target, move_id, { "amount": healed, "hpAfter": patient["hp"] })
		ITEM_POWDER:
			# +1 action from this round on: longRounds rounds at power >=
			# longPowerMin, else rounds. A second Powder extends, never stacks.
			var params: Dictionary = m["params"]
			var rounds: int = int(params["longRounds"]) if power >= int(params["longPowerMin"]) else int(params["rounds"])
			actor["powderUntil"] = maxi(actor["powderUntil"], int(cp["round"]) + rounds - 1)
			actor["powderUsed"] = true
			# An ally's round is planned up front: the action Powder adds this
			# round gets an ally-AI move of its own.
			if actor["side"] == SIDE_ALLY:
				var plan: Array = actor["plan"]
				if plan.size() < actions_this_round(cp, actor_idx):
					plan.append(_ally_action(cp, actor_idx, plan.size(), plan.size() + 1, [], rng))
			_beat(cp, beats, "powder", actor_idx, -1, move_id, {})
		ITEM_SIGHT:
			# Sight covers the `power` rounds after this one (planning them
			# reads their targets/damage and the round after's plans); it's
			# always the player's, whoever breathes it in.
			var seer: Dictionary = combatants[PLAYER_INDEX]
			seer["sightUntil"] = maxi(seer["sightUntil"], int(cp["round"]) + power)
			_beat(cp, beats, "sight" if actor_idx == PLAYER_INDEX else "sightGiven", actor_idx, -1, move_id, {})
		ITEM_LADY:
			var running_tier: int = int(actor.get("ladyTier", 0)) if has_lady(cp, actor) else 0
			actor["ladyTier"] = maxi(running_tier, int(slot["tier"]))
			actor["ladyUntil"] = maxi(actor["ladyUntil"], int(cp["round"]) + power - 1)
			actor["ladyCrit"] = float(m["params"]["critChance"])
			_beat(cp, beats, "lady", actor_idx, -1, move_id, {})
		ITEM_PANIC, ITEM_RAPTURE, ITEM_ANGER, ITEM_FURY:
			var targets := _pan_targets(cp, actor_idx, int(action["target"]), multi)
			if targets.is_empty():
				_beat(cp, beats, "fizzle", actor_idx, int(action["target"]), move_id, {})
			for target in targets:
				_apply_pan_status(combatants[target], m["effect"], slot)
				_beat(cp, beats, m["effect"], actor_idx, target, move_id, {})
		ITEM_WORMHOLE:
			# Player only: the fight ends fled, no roll, no parting shot.
			_beat(cp, beats, "wormhole", actor_idx, -1, move_id, {})
			if actor_idx == PLAYER_INDEX:
				cp["outcome"] = "fled"


# Whether the item `action` lands on nobody: a single-target heal or Shield
# aimed at a KO'd friendly, or a Pan item with no one to take its status.
static func _item_fizzles(cp: Dictionary, actor_idx: int, action: Dictionary, m: Dictionary, multi: bool) -> bool:
	var aimed := int(action["target"])
	if m["effect"] in [ITEM_HEAL, ITEM_SHIELD]:
		return not multi and aimed >= 0 and cp["combatants"][aimed]["koed"]
	if m["effect"] in PAN_EFFECTS:
		return _pan_targets(cp, actor_idx, aimed, multi).is_empty()
	return false


# Who a Pan item from `actor_idx` lands on: every living opponent not under
# a Pan status for a multi unit; else the aimed one (retargeted off a KO),
# [] when that one's already under one (it refuses).
static func _pan_targets(cp: Dictionary, actor_idx: int, aimed: int, multi: bool) -> Array:
	var combatants: Array = cp["combatants"]
	var free := _living_opponents(cp, actor_idx).filter(func(e): return not has_pan_status(combatants[e]))
	if multi:
		return free
	var target := _retarget(cp, actor_idx, aimed)
	return [target] if free.has(target) else []


# Sets the Pan item `effect`'s status from `unit` (a loadout slot or Dial
# cast): Panic or Pan's Rapture for its power in actions; Panger/
# Pandemonium's anger for two phases of phaseActions at pctPerTier × its
# tier percent (a Dial cast's own angerPct).
static func _apply_pan_status(combatant: Dictionary, effect: String, unit: Dictionary) -> void:
	match effect:
		ITEM_PANIC:
			combatant["panicActions"] = int(unit["power"])
		ITEM_RAPTURE:
			combatant["raptureActions"] = int(unit["power"])
		_:
			var anger: Dictionary = _data()["anger"]
			combatant["angerActions"] = 2 * int(anger["phaseActions"])
			combatant["angerPct"] = int(unit.get("angerPct", int(anger["pctPerTier"]) * int(unit["tier"])))
			combatant["fury"] = effect == ITEM_FURY


# A Blast that leaves an enemy standing disarms it at disarmChance: its
# weapon's attack bonus goes for the fight and its ability locks for
# disarmLockRounds round boundaries (R§3.7b Table 4).
static func _maybe_disarm(cp: Dictionary, actor_idx: int, target_idx: int, move_id: String, params: Dictionary, rng: RandomNumberGenerator, beats: Array) -> void:
	var target: Dictionary = cp["combatants"][target_idx]
	if target["koed"] or target["side"] != SIDE_ENEMY or rng.randf() >= float(params["disarmChance"]):
		return
	var weapon = target["weapon"]
	if weapon is Dictionary:
		target["attackMin"] -= int(weapon["min"])
		target["attackMax"] -= int(weapon["max"])
		target["weapon"] = null
	if target["ability"] is Dictionary:
		target["ability"]["lockedTurns"] = int(params["disarmLockRounds"])
	target["disarmed"] = true
	_beat(cp, beats, "disarm", actor_idx, target_idx, move_id, {})


# Loss once the player is down with no friendly standing or queued; win once
# every enemy is down with none queued (R§3.7b KO and outcome).
static func _check_outcome(cp: Dictionary) -> void:
	var combatants: Array = cp["combatants"]
	if combatants[PLAYER_INDEX]["koed"] and _standing(cp, SIDE_ALLY) == 0 and cp.get(QUEUE_KEYS[SIDE_ALLY], []).is_empty():
		cp["outcome"] = "loss"
		return
	if _standing(cp, SIDE_ENEMY) == 0 and cp.get(QUEUE_KEYS[SIDE_ENEMY], []).is_empty():
		cp["outcome"] = "win"


# One beat: { round, kind, actor, target, move, text, turnActor, turnIndex }
# plus `extra`; turnActor/turnIndex name the timeline position whose action
# produced it. Once that action resolves each of its beats also carries
# "marks" (stage_marks() after it) and the actor's carry "actorGuard". The line's "self" variant is used when the player is the
# actor (or, for a KO, the one going down).
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
		"moveName": extra.get("moveName", ""),
		"level": extra.get("level", 0),
	})
	if extra.get("crit", false):
		text += lines["crit"]
	if extra.get("absorbed", 0) > 0:
		text += lines["absorb"].format({ "absorbed": extra["absorbed"] })
	var beat := {
		"round": cp["round"], "kind": kind, "actor": actor, "target": target, "move": move_id,
		"text": text[0].to_upper() + text.substr(1),
		"turnActor": int(cp["cursor"]["actor"]), "turnIndex": int(cp["cursor"]["index"]),
	}
	beat.merge(extra)
	var note := _coach_note(cp, beats, "%s.%s" % [variant, kind])
	if note != "":
		beat["coachNote"] = note
	beats.append(beat)


# The coach's line explaining a beat this round: coach.notes["<round>"]
# ["<variant>.<kind>"] (variant as beatLines: "self" when the player is the
# subject), a line or a list of lines for the key's successive beats that
# round, each shown once; "" for none.
static func _coach_note(cp: Dictionary, beats: Array, key: String) -> String:
	if not coach_active(cp):
		return ""
	var entry: Variant = cp["coach"].get("notes", {}).get(str(cp["round"]), {}).get(key, "")
	var lines: Array = entry if entry is Array else [entry]
	var shown := 0
	for beat in cp["log"] + beats:
		if int(beat["round"]) == int(cp["round"]) and lines.has(beat.get("coachNote", null)):
			shown += 1
	return str(lines[shown]) if shown < lines.size() else ""


# ── Rewind ───────────────────────────────────────────────────────────────

# Saves the fight as it stands at a decision point, before the pick.
static func _push_snapshot(cp: Dictionary, stack_id: String) -> void:
	var frame := {}
	for key in cp.keys():
		if key != "snapshots" and key != "roundFrames":
			frame[key] = cp[key]
	Snapshots.push(stack_id, cp["snapshots"], frame)


# Restores the fight `cp` to the previous decision point with that pick
# undone (across a round boundary, that round's plans come back too). Move
# XP stays earned, so each owned fighter's move levels come back from its
# record, not the snapshot.
static func rewind_pick(cp: Dictionary) -> Dictionary:
	var frame = Snapshots.pop_newest(cp["snapshots"])
	if frame == null:
		return { "ok": false, "reason": "Nothing to rewind." }
	_apply_frame(cp, frame)
	return { "ok": true }


# Puts a saved frame's keys back on `cp`; each owned fighter's move levels
# come back from its record.
static func _apply_frame(cp: Dictionary, frame: Dictionary) -> void:
	for key in frame.keys():
		cp[key] = frame[key]
	for fighter in cp["combatants"]:
		var owner = fighter.get("moveOwner")
		if owner is String:
			fighter["moveLevels"] = MoveLevels.levels_of(owner)


# Saves the fight as it stands at a round's first decision point (or, from
# open_fight(), before its first action) onto `cp`'s round frames: the
# opening frame is kept for good, then the newest top-tier-Rewind-depth many.
# `rng_state` overrides the frame's rngState when the fight's stream is
# running ahead of cp["rngState"].
static func push_round_frame(cp: Dictionary, rng_state: Variant = null) -> void:
	var frame := {}
	for key in cp.keys():
		if key != "snapshots" and key != "roundFrames":
			frame[key] = cp[key]
	if rng_state != null:
		frame["rngState"] = rng_state
	var frames: Array = cp.get("roundFrames", [])
	cp["roundFrames"] = frames
	frames.append(GameState.deep_copy(frame))
	var kept: int = GameData.RECIPES["rewind"]["effectPower"].size() - 1
	while frames.size() > 1 + kept:
		frames.remove_at(1)


# Whether a round frame older than the fight's current round start exists, or
# a pick has been made since: something a rewind can undo.
static func can_rewind_rounds(cp: Dictionary) -> bool:
	return not cp["snapshots"].is_empty() or cp.get("roundFrames", []).size() > 1


# Drops the round frames of rounds the fight has been put back before.
static func prune_round_frames(cp: Dictionary) -> void:
	var frames: Array = cp.get("roundFrames", [])
	while frames.size() > 1 and int(frames[-1]["round"]) > int(cp["round"]):
		frames.pop_back()


# Restores the fight `cp` `depth` rounds back: to the round-start frame of
# round `cp.round - depth`, or the oldest kept frame if that's older, or the
# opening frame outright when `to_start`. The per-pick snapshots go (they
# lie ahead of the restored position); a restore to the opening frame
# resolves round 1 on to the player's first position again. Returns { ok,
# replayed, logKept: the log entries the restored frame holds, any past them
# that replay's, restored: with replayed, a copy of the fight as it stood
# before the replay }.
static func rewind_rounds(cp: Dictionary, depth: int, to_start: bool) -> Dictionary:
	var frames: Array = cp.get("roundFrames", [])
	if frames.is_empty():
		return { "ok": false, "reason": "Nothing to rewind." }
	var index := 0
	if not to_start:
		for i in range(frames.size()):
			if int(frames[i]["round"]) <= int(cp["round"]) - depth:
				index = i
	var scripted_start := to_start and _script_pre(cp)
	var frame: Dictionary = GameState.deep_copy(frames[index])
	_apply_frame(cp, frame)
	cp["snapshots"] = []
	cp["roundFrames"] = frames.slice(0, index + 1)
	if scripted_start:
		_begin_script_post(cp)
	var result := { "ok": true, "replayed": cp.has("atOpen"), "logKept": cp["log"].size() }
	if result["replayed"]:
		cp.erase("atOpen")
		var restored := {}
		for key in cp.keys():
			if key != "snapshots" and key != "roundFrames":
				restored[key] = cp[key]
		result["restored"] = GameState.deep_copy(restored)
		var rng := RandomNumberGenerator.new()
		rng.state = cp["rngState"]
		var beats: Array = []
		_advance(cp, rng, beats)
		_record(cp, beats)
		cp["rngState"] = rng.state
	return result
