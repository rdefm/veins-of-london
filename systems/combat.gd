class_name Combat
extends RefCounted

# Fights on the Open/Guarded round rules (R§3.7b; CombatRounds is the rules
# core): every context's setup on state.combat, picks, Dial casts, Rewind,
# XP and exit routing. Static funcs only.

# Named constants for combat.context; a typo becomes a push_error instead of
# a silent mis-route.
const CONTEXT_RAID: String = "raid"
const CONTEXT_MUGGING: String = "mugging"
const CONTEXT_EVENT_MUGGING: String = "event_mugging"
# A hostile faction's squad ambushing the player mid-action; resumes the
# still-active intro event, Ambush.resolve() settles relation and grudge.
const CONTEXT_FACTION_AMBUSH: String = "faction_ambush"
const CONTEXT_HOME_RAID: String = "home_raid"
# A later HQ raid defended from its alarm (Home.trigger_defend()); no quest
# dialogue, Home owns the win/loss consequence (R§3.8).
const CONTEXT_HOME_ALARM_DEFEND: String = "home_alarm_defend"
const CONTEXT_EVENT_RAID: String = "event_raid"
const CONTEXT_DEFEND_VEIN: String = "defend_vein"
# Archie's own deal going wrong; resolves via ArchieDeals.resolve_mugging(),
# and a loss (not just a win) needs its own exit_combat() handling.
const CONTEXT_ARCHIE_DEAL_MUGGING: String = "archie_deal_mugging"
# An event's scripted fight (start_scripted_fight()); exits back to its event.
const CONTEXT_SCRIPTED: String = "scripted"
# A practice fight at the calc gym (Sparring.spar()).
const CONTEXT_SPAR: String = "spar"

const CANONICAL_CONTEXTS: Array[String] = [
	CONTEXT_SPAR,
	CONTEXT_RAID, CONTEXT_MUGGING, CONTEXT_EVENT_MUGGING, CONTEXT_FACTION_AMBUSH,
	CONTEXT_HOME_RAID, CONTEXT_EVENT_RAID, CONTEXT_DEFEND_VEIN,
	CONTEXT_ARCHIE_DEAL_MUGGING, CONTEXT_HOME_ALARM_DEFEND, CONTEXT_SCRIPTED,
]

# Contexts that are a mugging or ambush in flavour (no vein at stake) rather than a
# raid; shared with scenes/screens/combat.gd's win-line/label logic.
const NON_LETHAL_MUGGING_CONTEXTS: Array[String] = [CONTEXT_MUGGING, CONTEXT_EVENT_MUGGING, CONTEXT_ARCHIE_DEAL_MUGGING, CONTEXT_FACTION_AMBUSH]

# Contexts fought in the player's own flat (no vein at stake); shared with
# scenes/screens/combat.gd's win-line/label logic.
const HOME_CONTEXTS: Array[String] = [CONTEXT_HOME_RAID, CONTEXT_HOME_ALARM_DEFEND]

# R§2 combat.locationKey for the two home contexts -- home isn't a district.
const HOME_LOCATION_KEY := "home"

# Contexts the debug combat setup may pick: their exit_combat() handlers need
# no active event and apply no story consequence (defend_vein with no
# activeDefendRaid is a no-op), so a throwaway fight can't corrupt a save.
const DEBUG_SETUP_CONTEXTS: Array[String] = [CONTEXT_RAID, CONTEXT_MUGGING, CONTEXT_DEFEND_VEIN]

# recipeKeys a loaded Dial Complication casts in a fight (as a round item,
# _round_dial()); rejuvenation/beALady/healingSalve have no in-combat cast,
# and a rewind cast pays for round_rewind() instead.
const COMBAT_COMPLICATION_RECIPES: Array[String] = ["timePearl", "enhancementPowder", "blast", "shield", "blackHole", "healingBurst", "prophetsBreath", "wormhole", "panic", "panger", "pandemonium", "pansRapture"]

# PROSE-REVIEW: loadout-row block reasons.
const REASON_SLOT_EMPTY := "Empty."
const REASON_SLOT_REACTIVE := "Fires on its own."
const REASON_NOTHING_TO_UNDO := "Nothing to undo yet."

# R§3.7b speed rule. MUGGER_SPEED: the mugger has no data/enemies.json
# template of its own (generated procedurally below), so its speed lives
# here. DEFAULT_TEMPLATE_SPEED: default for a template that omits `speed`.
const MUGGER_SPEED := 11
const DEFAULT_TEMPLATE_SPEED := 10
# R§1.10: a Strike's miss chance on any enemy that doesn't author its own.
const DEFAULT_EVADE_CHANCE := 0.2
# R§3.7b table 1: the mugger's archetype, plain and harder (a vein in the
# sale), and its stage sprite template; the home raider's sprite template.
const MUGGER_ARCHETYPE := "mugger"
const HARD_MUGGER_ARCHETYPE := "muggerV2"
const MUGGER_TEMPLATE_KEY := "mugger"
const HOME_RAIDER_TEMPLATE_KEY := "homeRaidRaider"

# The round fight's Rewind stack id (Snapshots cap).
const ROUND_SNAPSHOT_STACK := "combat"
# R§3.7b XP: one Combat XP lump per round fight, by outcome.
const ROUND_XP_WIN := 30
const ROUND_XP_LOSS := 3
const ROUND_XP_FLED := 0
# PROSE-REVIEW: a loadout unit with no round-fight item (R§3.7b Items).
const REASON_ROUND_ITEM_PENDING := "Not usable in this kind of fight yet."
# PROSE-REVIEW: a rewind unit's loadout row (it pays for the Rewind command).
const REASON_SLOT_REWIND := "Spent by Rewind."
const REASON_NO_REWIND := "No rewind available."
# How round_rewind() is paid: a loadout rewind unit, a Dial rewind cast, or
# whichever there is (the unit first).
const REWIND_PAY_ANY := ""
const REWIND_PAY_LOADOUT := "loadout"
const REWIND_PAY_DIAL := "dial"
# A spar's house-rules Rewind: free and unlimited.
const REWIND_PAY_FREE := "free"
# PROSE-REVIEW: the house Rewind outside a spar.
const REASON_NO_HOUSE_RULES := "House rules only apply at the gym."
# R§3.7b Rewind: the fight transcript's lines for a Rewind, a Failsafe and an
# ally's rewind; LINE_ALLY_REWIND takes the ally's name.
const LINE_REWIND := "⟲ Time unspools. The moment resets. Only you remember."
const LINE_FAILSAFE := "⚑ Failsafe fires. Death, reversed -- administratively."
# PROSE-REVIEW: an ally's rewind line.
const LINE_ALLY_REWIND := "⟲ %s breaks a Rewind. You're still standing."

# R§3.7a: Combat Skill's training XP per gym / workout session.
const COMBAT_XP_PER_GYM_SESSION := 30
const COMBAT_XP_PER_WORKOUT_SESSION := 10

# R§3.7a "Roster generation": ENEMY_INSTANCE_VARIANCE is the per-instance
# hp/attack variance band for spawned mugger/guard entries (draft, not
# balance-final); SQUAD_MAX is how many fighters per side are active at once
# (the player counts toward the friendly SQUAD_MAX). Extra fighters wait in
# combat.enemyQueue / combat.allyQueue.
const ENEMY_INSTANCE_VARIANCE := 0.15
const SQUAD_MAX := 3

# R§3.7a "Player KO": the player's hp once a fight they were KO'd in settles
# (an ally-won victory or a loss), as a fraction of hpMax.
const PLAYER_KO_HP_FRACTION := 0.1

# The data/enemies.json raidGuards key whose spawned entries carry a
# `variant` (a GameData.TERRITORIAL_VARIANTS key, or the fallback template).
const SCRAPPER_TEMPLATE_KEY := "territorialScrapper"
const SCRAPPER_FALLBACK_VARIANT := "default"


static func is_canonical_context(context: String) -> bool:
	return CANONICAL_CONTEXTS.has(context)


# R§3.7a: rolls variance for one stat independently, called once per
# hp/attackMin/attackMax so same-archetype squadmates never match exactly.
static func _apply_instance_variance(base: float) -> int:
	return GameState.round_epsilon(base * Rng.randf_range(1.0 - ENEMY_INSTANCE_VARIANCE, 1.0 + ENEMY_INSTANCE_VARIANCE))


# A trade including a vein rolls a harder mugger encounter: a wider,
# higher-floor roster (2-4 vs. the default 1-3) at the harder archetype and
# level (R§3.7b tables 1-2). Draft, needs balance sign-off (see
# MUG_BASE_CHANCE_VEIN in economy.gd).
const HARD_MUGGER_MIN_COUNT := 2
const HARD_MUGGER_MAX_COUNT := 4


# `count` distinct entries off the single mugger archetype's base stats
# (hp 28, atk 4-10 per R§3.7a), each with independent variance. `harder`
# widens the roster and lifts archetype and level -- see HARD_MUGGER_* above.
static func generate_mugger(harder: bool = false) -> Array:
	var min_count: int = HARD_MUGGER_MIN_COUNT if harder else 1
	var max_count: int = HARD_MUGGER_MAX_COUNT if harder else 3
	var count: int = Rng.randi_range(min_count, max_count)
	var entries: Array = []
	for _i in range(count):
		entries.append(_spawn_mugger_instance(harder))
	return entries


static func _spawn_mugger_instance(harder: bool = false) -> Dictionary:
	var hp: int = _apply_instance_variance(28)
	return {
		"name": "A mugger",
		"hp": hp,
		"hpMax": hp,
		"attackMin": _apply_instance_variance(4),
		"attackMax": _apply_instance_variance(10),
		"isMugging": true,
		"weapon": null,
		"ability": null,
		"evadeChance": DEFAULT_EVADE_CHANCE,
		"speed": MUGGER_SPEED,
		"archetype": HARD_MUGGER_ARCHETYPE if harder else MUGGER_ARCHETYPE,
		"level": enemy_level("hardMugging" if harder else "mugging"),
		"template": MUGGER_TEMPLATE_KEY,
	}


# R§3.7b table 2: a context's fixed enemy level ("mugging", "hardMugging",
# "homeRaid", "homeAlarmDefend").
static func enemy_level(key: String) -> int:
	return int(GameData.ENEMY_LEVELS[key])


# R§3.7b table 2: a vein fight's enemy level off its combined magnitude --
# the level of the highest veinMagnitude row the magnitude reaches.
static func enemy_level_for_magnitude(magnitude: int) -> int:
	var level := 1
	for row in GameData.ENEMY_LEVELS["veinMagnitude"]:
		if magnitude >= int(row["magnitude"]):
			level = int(row["level"])
	return level


# R§3.7b table 2: a faction ambush's enemy level off the ambushing faction's
# Turf tier in `district_id`.
static func enemy_level_for_ambush(district_id: String, faction_id: String) -> int:
	return int(GameData.ENEMY_LEVELS["ambushTurf"][Turf.tier(district_id, faction_id)])


# The "N muggers stepped out" intro-line label; naming a roster is the
# caller's job, not generate_mugger()'s.
static func _mugger_intro_label(count: int) -> String:
	return "A mugger" if count == 1 else "%d muggers" % count


# Builds the {weapon, ability, evadeChance, speed, archetype} fields shared
# by every template-built enemy. evadeChance (R§1.10) defaults to
# DEFAULT_EVADE_CHANCE when a template omits the key.
static func _enemy_capabilities_from_template(template: Dictionary) -> Dictionary:
	var ability = null
	if template.has("ability"):
		ability = { "id": template["ability"], "lockedTurns": 0 }
	return {
		"weapon": template.get("weapon"),
		"ability": ability,
		"evadeChance": template.get("evadeChance", DEFAULT_EVADE_CHANCE),
		"speed": template.get("speed", DEFAULT_TEMPLATE_SPEED),
		"archetype": template["archetype"],
	}


# Debug-only in M0 (R§3.7); M0 has no NPC-claimed-vein storage, so callers
# supply a value tier/guards directly. value_tier is Cultivating.combined_magnitude()
# (R§3.4: value_tier blended with a vein's earned level), which sets every
# entry's level (R§3.7b table 2); guard_count (at least 1, no upper cap)
# entries roll independently from GameData.ENEMY_RAID_GUARDS unless
# `template_key` forces one template.
static func generate_raid_enemy(vein_id, value_tier: int, guards: int = 1, template_key: String = "") -> Array:
	var templates: Dictionary = GameData.ENEMY_RAID_GUARDS
	var guard_count: int = maxi(guards, 1)
	var entries: Array = []
	var used_variants: Array = []
	for _i in range(guard_count):
		var key: String = template_key
		if key == "" or not templates.has(key):
			key = Rng.rand_from(templates.keys())
		var entry := _spawn_guard_instance(templates[key], enemy_level_for_magnitude(value_tier))
		entry["template"] = key
		if key == SCRAPPER_TEMPLATE_KEY:
			entry["variant"] = _roll_scrapper_variant(used_variants)
		entries.append(entry)
	return entries


# A Territorial Scrapper's sprite set: a discovered territorial variant other
# than the player's own model, distinct within one fight until the pool runs
# out (`used` accumulates across the fight's scrappers). An empty pool falls
# back to the "default" stand-in template.
static func _roll_scrapper_variant(used: Array) -> String:
	var own_model: String = GameState.state["player"].get("model", "")
	var pool: Array = []
	for key in GameData.TERRITORIAL_VARIANTS:
		if key != own_model:
			pool.append(key)
	if pool.is_empty():
		return SCRAPPER_FALLBACK_VARIANT
	var fresh: Array = pool.filter(func(k: String) -> bool: return not used.has(k))
	var pick: String = Rng.rand_from(pool if fresh.is_empty() else fresh)
	used.append(pick)
	return pick


# The template's own stats with instance variance, at `level` (whose curves
# the round fight adds on, R§3.7b).
static func _spawn_guard_instance(template: Dictionary, level: int) -> Dictionary:
	var hp: int = _apply_instance_variance(template["hpBase"])
	var entry := {
		"name": template["name"],
		"hp": hp,
		"hpMax": hp,
		"attackMin": _apply_instance_variance(template["attackMin"]),
		"attackMax": _apply_instance_variance(template["attackMax"]),
		"isMugging": false,
		"level": level,
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
	# R§3.7a: unarmed base plus Combat Skill's attack bonus (level 1 is 0).
	var skill_bonus: int = GameData.COMBAT_ATTACK_BONUS_BY_LEVEL[player["combatSkill"]]
	return { "min": player["attackMin"] + skill_bonus, "max": player["attackMax"] + skill_bonus }


# Enemy side: base attack + the enemy's equipped weapon bonus, if any (the
# same weapon disarm_enemy() strips).
static func get_enemy_attack_range(enemy: Dictionary) -> Dictionary:
	var min_atk: int = enemy["attackMin"]
	var max_atk: int = enemy["attackMax"]
	var weapon = enemy.get("weapon")
	if weapon != null:
		min_atk += weapon["min"]
		max_atk += weapon["max"]
	return { "min": min_atk, "max": max_atk }


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


# Faction-ambush intro event's fight (Ambush): a weighted pick from the
# faction's data/enemies.json factionSquads, built from raidGuards templates,
# at the level of the faction's Turf tier in `district_id` (the ambush's;
# "" = the current district).
static func start_faction_ambush(faction_id: String, district_id: String = "") -> void:
	if district_id == "":
		district_id = GameState.state["world"]["currentDistrict"]
	var squads: Array = GameData.ENEMY_FACTION_SQUADS[faction_id]
	var total := 0.0
	for s in squads:
		total += float(s["weight"])
	var roll := Rng.randf() * total
	var squad: Dictionary = squads[-1]
	for s in squads:
		roll -= float(s["weight"])
		if roll < 0.0:
			squad = s
			break
	var level := enemy_level_for_ambush(district_id, faction_id)
	var enemies: Array = []
	for template_key in squad["enemies"]:
		var entry: Dictionary = generate_raid_enemy(null, 1, 1, template_key)[0]
		entry["level"] = level
		enemies.append(entry)
	# PROSE-REVIEW: ambush intro line.
	var log_lines := ["%s squad closes in. This was planned." % GameData.FACTIONS[faction_id]["shortName"]]
	_start_combat(CONTEXT_FACTION_AMBUSH, null, enemies, log_lines, "")
	GameState.state["combat"]["ambushFactionId"] = faction_id


# Called by combat_intro events via the start_home_raid_combat effect op.
# `mods` are the event's opening modifiers: enemyHpMult scales the raider's
# starting hp (hpMax unchanged); enemyFirst has every enemy act ahead of the
# player and allies at each action slot of round 1 (CombatRounds timeline
# order); pearlLock ({ item, enemyBelowHp, prompt, raiderCounters?,
# pearlCrits? }) keeps the raider up until the player plays that item, and
# below enemyBelowHp leaves it the only playable command (R§3.7b Pearl lock).
static func start_home_raid_combat(mods: Dictionary = {}) -> void:
	var opening: Dictionary = { "enemyFirst": true } if bool(mods.get("enemyFirst", false)) else {}
	if mods.get("pearlLock") is Dictionary:
		opening["pearlLock"] = mods["pearlLock"].duplicate(true)
	_start_combat(CONTEXT_HOME_RAID, null, [_home_raider_enemy(enemy_level("homeRaid"), float(mods.get("enemyHpMult", 1.0)))],
		["They're in the flat. You've got your hands. This is happening."],
		"homeRaidWon", [], null, {}, {}, opening)


# An event's scripted fight (R§3.7b Scripted fights), straight in with no
# prep screen and no way out. `script`: enemies / allies (fighter entries as
# _round_combatant() reads them, with `plans` -- one array of moves per
# round, cycled -- plus `sprite`, `slots` and pinned `moveLevels`), intro
# lines, enemyFirst, forcedHits ({ actor, target, crit?, ko? } by combatant
# index), lockBelowHp and prompt, post ({ allyPlans: { "<combatant index>":
# moves }, playerPlan: moves }), resumeCard, plus optional seed,
# playerLevel, locationKey and coach ({ lessons, allowed, notes } by round, R§3.7b
# Coach marks). With no lockBelowHp the fight plays as a normal one on its
# fixed plans (SCRIPT_OPEN) and resumes the event on any outcome; `practice`
# runs it under spar rules (Sparring.spar_block()).
static func start_scripted_fight(script: Dictionary) -> void:
	var roster := _scripted_roster(script)
	var block := {
		"phase": CombatRounds.SCRIPT_OPEN,
		"forcedHits": script.get("forcedHits", []).duplicate(true),
		"resumeCard": int(script["resumeCard"]),
	}
	if script.has("lockBelowHp"):
		block.merge({
			"phase": CombatRounds.SCRIPT_PRE,
			"lockBelowHp": int(script["lockBelowHp"]), "prompt": str(script["prompt"]),
			"post": script["post"].duplicate(true),
		}, true)
	var live := {
		"script": block,
		"enemyFirst": bool(script.get("enemyFirst", false)),
		"coach": script["coach"].duplicate(true) if script.has("coach") else null,
	}
	if bool(script.get("practice", false)):
		live["spar"] = Sparring.spar_block(GameState.state["player"]["loadout"]["slots"].duplicate(true))
	var location_key: String = str(script.get("locationKey", ""))
	_start_round_combat(CONTEXT_SCRIPTED, null, roster["enemies"], script.get("intro", []), "", roster["allies"],
		location_key if not location_key.is_empty() else null, roster["config"], live)


# An event's demo fight (R§3.7b Demo fights): the same fighter entries as a
# scripted fight, but the player sits it out and `rounds` rounds play a beat
# per demo_continue(), then the event resumes at `resumeCard`. `procs`
# ({ kind: "autoguard" | "retaliate", target }, by combatant index) each
# fire once whatever the dice say; `label` heads the screen; `coach` as a
# scripted fight's, its notes voicing over the beats.
static func start_demo_fight(script: Dictionary) -> void:
	var roster := _scripted_roster(script)
	var live := {
		"demo": {
			"rounds": int(script["rounds"]), "upTo": 0, "queue": [], "resumeCard": int(script["resumeCard"]),
			"procs": script.get("procs", []).duplicate(true), "label": str(script.get("label", "Sparring")),
		},
		"coach": script["coach"].duplicate(true) if script.has("coach") else null,
	}
	var location_key: String = str(script.get("locationKey", ""))
	_start_round_combat(CONTEXT_SCRIPTED, null, roster["enemies"], script.get("intro", []), "", roster["allies"],
		location_key if not location_key.is_empty() else null, roster["config"], live)


# A gym spar against the one fighter entry `foe` (Sparring.spar()); `spar` is
# its data block (combat.spar).
static func start_spar_fight(foe: Dictionary, spar: Dictionary) -> void:
	_start_round_combat(CONTEXT_SPAR, null, [foe], [Sparring.line("intro"), Sparring.line("houseRules")], "", [],
		null, { "fog": false }, { "spar": spar })


# `script`'s enemies and allies as fighter entries, and the round-combat
# config carrying their plans, for _start_round_combat().
static func _scripted_roster(script: Dictionary) -> Dictionary:
	var enemies: Array = []
	var enemy_plans: Array = []
	for spec in script["enemies"]:
		var entry: Dictionary = spec.duplicate(true)
		enemy_plans.append(entry.get("plans"))
		entry.erase("plans")
		entry["isMugging"] = false
		entry["archetype"] = str(entry.get("archetype", MUGGER_ARCHETYPE))
		entry["hp"] = int(entry.get("hp", entry["hpMax"]))
		enemies.append(entry)
	var allies: Array = []
	var ally_plans: Array = []
	for spec in script.get("allies", []):
		var entry: Dictionary = spec.duplicate(true)
		ally_plans.append(entry.get("plans"))
		entry.erase("plans")
		entry["hp"] = int(entry.get("hp", entry["hpMax"]))
		entry.merge({ "slots": [], "slotsUsed": [], "koed": false })
		allies.append(entry)
	var config := { "fog": false, "enemyPlans": enemy_plans, "allyPlans": ally_plans, "playerLevel": int(script.get("playerLevel", 0)) }
	if script.has("seed"):
		config["seed"] = int(script["seed"])
	return { "enemies": enemies, "allies": allies, "config": config }


# Called by Home.trigger_defend(): same raider, no onWin (Home resolves it).
# HQ guards join and spend home.guardKit (guard-kit spec §HQ guard kit).
static func start_home_alarm_defend_combat(ally_ids: Array = []) -> void:
	var log_lines := ["They're in the flat. You've got your hands. This is happening."]
	var allies: Array = []
	for contact_id in ally_ids:
		if Contacts.can_join_combat(contact_id):
			allies.append(Contacts.build_combat_ally(contact_id))
			# PROSE-REVIEW: recruit joining an HQ defence.
			log_lines.append("%s is in the flat with you." % Contacts.display_name(contact_id))
	_add_guard_allies(allies, Home.get_guard_count(), log_lines)
	var guard_kit := { "items": GuardKit.hq_active_units().duplicate(true), "used": {} }
	_start_combat(CONTEXT_HOME_ALARM_DEFEND, null, [_home_raider_enemy(enemy_level("homeAlarmDefend"))], log_lines,
		"", allies, null, {}, guard_kit)


static func _home_raider_enemy(level: int, hp_mult: float = 1.0) -> Dictionary:
	var raider: Dictionary = GameData.ENEMY_HOME_RAID_RAIDER
	var enemy := {
		"name": raider["name"], "hp": maxi(1, int(round(raider["hp"] * hp_mult))), "hpMax": raider["hp"],
		"attackMin": raider["attackMin"], "attackMax": raider["attackMax"],
		"isMugging": false, "level": level, "template": HOME_RAIDER_TEMPLATE_KEY,
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
	_add_hired_muscle(allies, log_lines)
	_start_combat(context, vein_id, enemies, log_lines, "raidWon", allies)


# A caught stockpile raid (events.gd "start_stockpile_raid_combat"): one
# enemy per stockpile guard (at least one), sharing the faction's defend kit
# as combat.raiderKit, in the stockpile's district. Runs as an event_raid, so
# a win resumes the event; combat.stockpileFactionId routes the settlement to
# Raiding.resolve_stockpile_fight().
static func start_stockpile_raid(faction_id: String, value_tier: int, guards: int, template_key: String = "", ally_ids: Array = []) -> void:
	var enemies := generate_raid_enemy(null, value_tier, guards, template_key)
	var log_lines := ["%s steps out to meet you." % _guard_group_name(enemies)]
	var allies := _gather_raid_allies(ally_ids, log_lines)
	_add_hired_muscle(allies, log_lines)
	_start_combat(CONTEXT_EVENT_RAID, null, enemies, log_lines, "raidWon", allies, Raiding.stockpile_district(faction_id), FactionSim.raider_kit(faction_id, "defend", enemies.size()))
	GameState.state["combat"]["stockpileFactionId"] = faction_id


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


# Firm muscle hired at the Raid button rides in the running raid event's context.
static func _add_hired_muscle(allies: Array, log_lines: Array) -> void:
	if Perks.muscle_available() and Perks.event_has_muscle():
		var muscle := Perks.muscle_ally()
		allies.append(muscle)
		log_lines.append("%s comes in behind you." % muscle["name"])


# The alarm-upgrade defend encounter, called by Raiding.maybe_trigger_defend()
# once the player travels into the vein's district within the pending
# window. onWin is "" -- a loss is handled by Raiding.resolve_defend_outcome().
# attacker_id's attack kit becomes the squad's shared item pool, sized by the
# full roster (FactionSim.raider_kit(); "" = none); see _enemy_try_item().
static func start_defend_vein(vein_id: String, value_tier: int, attacker_id: String = "", ally_ids: Variant = null) -> void:
	var enemies := generate_raid_enemy(vein_id, value_tier)
	var raider_kit: Dictionary = {} if attacker_id == "" else FactionSim.raider_kit(attacker_id, "attack", enemies.size())
	var log_lines := ["The alarm wasn't lying. %s is already there." % _guard_group_name(enemies)]
	# Act 2 T8a's pre-fight reminder (spec §5.1/§6.8a): one Nadia-voiced line,
	# prepended only for the vein col_a2_nadia_defend is watching, only once.
	if vein_id == GameState.state["collective"].get("nadiaDefendVeinId") and not GameState.state["flags"].get("colA2DefendReminderShown", false):
		log_lines.push_front("Nadia, in your ear: \"Go on then. That's what the Blast and the Shield were for — use them properly this time, not for luck.\"")
		GameState.state["flags"]["colA2DefendReminderShown"] = true
	var allies := _gather_defend_allies(log_lines, ally_ids)
	var vein = Cultivating.find_vein(vein_id)
	_add_guard_allies(allies, 0 if vein == null else Cultivating.vein_guard_count(vein), log_lines)
	var guard_kit: Dictionary = {} if vein == null else { "items": GuardKit.active_units(vein).duplicate(true), "used": {} }
	_start_combat(CONTEXT_DEFEND_VEIN, vein_id, enemies, log_lines, "", allies, null, raider_kit, guard_kit)


# Vein-defense fights: the preparation screen's chosen recruits, in chosen
# order, re-validated at start; null (no preparation) takes every eligible
# recruit in contact order. Generic over contact_id.
static func _gather_defend_allies(log_lines: Array, ally_ids: Variant = null) -> Array:
	var ids: Array = GameState.state["contacts"].keys() if ally_ids == null else ally_ids
	var allies: Array = []
	for contact_id in ids:
		if Contacts.can_join_combat(contact_id):
			allies.append(Contacts.build_combat_ally(contact_id))
			log_lines.append("%s peels off to help cover the vein." % Contacts.display_name(contact_id))
	return allies


# Guard-kit spec §Defend fight: one guard ally per guard joins `allies`, after
# contacts. A KO only lasts the fight -- no contactId, so
# nothing persistent is touched.
static func _add_guard_allies(allies: Array, guard_count: int, log_lines: Array) -> void:
	var joining: int = maxi(guard_count, 0)
	for i in range(joining):
		allies.append(build_guard_ally())
	if joining > 0:
		# PROSE-REVIEW: guards joining a defend fight.
		log_lines.append("Your guard steps up beside you." if joining == 1 else "Your %d guards step up beside you." % joining)


# Same shape as Contacts.build_combat_ally(), stats from guardKit.guardAlly.
static func build_guard_ally() -> Dictionary:
	var stats: Dictionary = GameData.GUARD_KIT["guardAlly"]
	return {
		"guardAlly": true,
		"name": stats["name"],
		"hp": int(stats["hpMax"]),
		"hpMax": int(stats["hpMax"]),
		"attackMin": int(stats["attackMin"]),
		"attackMax": int(stats["attackMax"]),
		"speed": int(stats["speed"]),
		"level": int(stats["level"]),
		"koed": false,
	}


# Debug-only (combat_setup_modal.gd, scripts/sim_combat_balance.gd): a live
# fight under any DEBUG_SETUP_CONTEXTS context from `setup`:
#   context; locationKey ("" derives it as normal, else overrides it so every
#   backdrop tier can be previewed); playerLevel (fight-only Combat Skill
#   level, 0 = the player's own); enemies, an Array of { template (a
#   debug_enemy_templates() key, "" a random raid guard), archetype ("" the
#   template's own), level }; allyIds, recruited contacts brought in; allies,
#   an Array of { level, slots } debug allies (allyBase stats, slots as real
#   { recipe, tier } units); seed / fog as _start_round_combat()'s config.
static func start_debug_combat(setup: Dictionary) -> void:
	var context := str(setup.get("context", CONTEXT_RAID))
	if not DEBUG_SETUP_CONTEXTS.has(context):
		push_error("Combat.start_debug_combat: context '%s' is not in DEBUG_SETUP_CONTEXTS" % context)
		return
	var enemies: Array = []
	var used_variants: Array = []
	for spec in setup.get("enemies", [{}]):
		enemies.append(_debug_enemy(spec, used_variants))
	var log_lines := ["%s steps out to meet you." % _guard_group_name(enemies)]
	var allies := _gather_raid_allies(setup.get("allyIds", []), log_lines)
	for spec in setup.get("allies", []):
		allies.append(_debug_ally(spec))
	var on_win := "raidWon" if context == CONTEXT_RAID else ""
	var location_key := str(setup.get("locationKey", ""))
	var config := { "playerLevel": int(setup.get("playerLevel", 0)) }
	for key in ["seed", "fog"]:
		if setup.has(key):
			config[key] = setup[key]
	_start_round_combat(context, "debug_combat_setup", enemies, log_lines, on_win, allies,
		location_key if not location_key.is_empty() else null, config)


# The debug setup's enemy templates: every raid guard, the mugger and the
# home raider.
static func debug_enemy_templates() -> Array:
	var keys: Array = GameData.ENEMY_RAID_GUARDS.keys()
	keys.append_array([MUGGER_TEMPLATE_KEY, HOME_RAIDER_TEMPLATE_KEY])
	return keys


static func _debug_enemy(spec: Dictionary, used_variants: Array) -> Dictionary:
	var key := str(spec.get("template", ""))
	if not debug_enemy_templates().has(key):
		key = Rng.rand_from(GameData.ENEMY_RAID_GUARDS.keys())
	var level := clampi(int(spec.get("level", 1)), 1, CombatRounds.level_max())
	var entry: Dictionary
	match key:
		MUGGER_TEMPLATE_KEY:
			entry = _spawn_mugger_instance()
			entry["level"] = level
		HOME_RAIDER_TEMPLATE_KEY:
			entry = _home_raider_enemy(level)
		_:
			entry = _spawn_guard_instance(GameData.ENEMY_RAID_GUARDS[key], level)
			entry["template"] = key
			if key == SCRAPPER_TEMPLATE_KEY:
				entry["variant"] = _roll_scrapper_variant(used_variants)
	var archetype := str(spec.get("archetype", ""))
	if GameData.COMBAT_ROUNDS["archetypes"].has(archetype):
		entry["archetype"] = archetype
	return entry


# A debug ally: allyBase's hp and attack at `level`, carrying `slots`.
static func _debug_ally(spec: Dictionary) -> Dictionary:
	var base: Dictionary = GameData.COMBAT_ROUNDS["allyBase"]
	return {
		"name": str(base["name"]), "hp": int(base["hpBase"]), "hpMax": int(base["hpBase"]),
		"attackMin": int(base["attackMin"]), "attackMax": int(base["attackMax"]),
		"level": int(spec.get("level", 1)), "slots": spec.get("slots", []).duplicate(true),
		"slotsUsed": [], "koed": false,
	}


# Every start_* opens its fight here, on the round rules. `opening` holds
# the fight's opening modifiers (enemyFirst).
static func _start_combat(context: String, vein_id, enemies: Array, log_lines: Array, on_win: String, allies: Array = [], location_key_override: Variant = null, raider_kit: Dictionary = {}, guard_kit: Dictionary = {}, opening: Dictionary = {}) -> void:
	if not is_canonical_context(context):
		push_error("Combat: unrecognized context '%s' — not in CANONICAL_CONTEXTS, exit_combat() will mis-route it." % context)
	var live := { "raiderKit": raider_kit, "guardKit": guard_kit }
	live.merge(opening)
	_start_round_combat(context, vein_id, enemies, log_lines, on_win, allies, location_key_override, {}, live)


static func _enter_combat_screen() -> void:
	GameState.state["currentScreen"] = "combat"
	EventBus.screen_changed.emit("combat")
	EventBus.state_changed.emit()
	# Sets currentScreen/emits screen_changed itself rather than via
	# Nav.go_to(), so it needs the same abandon-after-both-emits treatment,
	# since Raiding.maybe_trigger_defend() can fire this synchronously
	# mid-Sites.prospect()/Travel.travel_to() while a Map animation plays.
	MapEvents.abandon_playback()


# ── Round fights (R§3.7b) ────────────────────────────────────────────────


# Opens a round fight on state.combat: a CombatRounds fight dict holding
# the real player (hp, hpMax, attack range, Combat Skill level and its speed)
# and the spawned enemies (their own hp/attack/speed plus their level's
# bonuses, R§3.7b speed rule; their archetype's plan patterns), plus the live
# keys exit_combat() and the rest of the game read. The intro lines go to
# the combat ticker. `allies` (the start_*'s roster, in its order: chosen
# recruits, then guards/muscle) fill the friendly places after the player,
# the rest waiting in allyQueue; combat.allies keeps their live dicts, which
# _sync_round_allies() keeps level with their combatants. `config` is
# debug/test-only: seed (default off the global Rng stream), fog,
# playerLevel (the fight's Combat Skill level and its attack bonus and
# speed; 0 or absent = the player's own), and enemyPlans / enemyUnread /
# allyPlans as CombatRounds.start(). `live` is merged into
# the fight before it opens: raiderKit / guardKit (the shared kit pools
# exit_combat() settles) and opening modifiers (enemyFirst). The player's
# real loadout slots become its round-fight items, and an active Prophet's
# Breath or Be a Lady carries in for the whole fight (R§3.7b Carry-in).
static func _start_round_combat(context: String, vein_id, enemies: Array, log_lines: Array, on_win: String, allies: Array = [], location_key_override: Variant = null, config: Dictionary = {}, live: Dictionary = {}) -> void:
	var location_key: String = location_key_for(context, vein_id) if location_key_override == null else str(location_key_override)
	var player: Dictionary = GameState.state["player"]
	var combat := CombatRounds.new_state()
	combat.merge({
		"context": context, "veinId": vein_id,
		"enemies": enemies.slice(0, SQUAD_MAX), "enemyQueue": enemies.slice(SQUAD_MAX),
		"allies": allies.slice(0, SQUAD_MAX - 1), "allyQueue": allies.slice(SQUAD_MAX - 1),
		"locationKey": location_key,
		"onWin": on_win, "raiderKit": {}, "guardKit": {}, "slotsUsed": [],
		# The player's real loadout slots as each pick found them, so its
		# snapshot carries them back on a Rewind (_restore_round_snapshot()).
		"loadoutSlots": player["loadout"]["slots"].duplicate(true),
		# Dial rewind casts that paid for a Rewind, so a restore never hands
		# their charge back (_restore_round_snapshot()).
		"dialRewindsPaid": 0,
		"backdrop": { "context": context, "locationKey": location_key },
		"fog": bool(config.get("fog", true)),
		"transcript": log_lines.duplicate(),
	}, true)
	combat.merge(live, true)
	var skill: int = int(player["combatSkill"])
	var level_override := int(config.get("playerLevel", 0))
	var level: int = clampi(level_override if level_override > 0 else skill, 1, CombatRounds.level_max())
	var attack := get_attack_range()
	var level_shift: int = GameData.COMBAT_ATTACK_BONUS_BY_LEVEL[level] - GameData.COMBAT_ATTACK_BONUS_BY_LEVEL[skill]
	attack = { "min": attack["min"] + level_shift, "max": attack["max"] + level_shift }
	var combatants: Array = combat["combatants"]
	var fighter := CombatRounds.new_combatant(CombatRounds.SIDE_PLAYER,
		GameData.COMBAT_ROUNDS["playerBase"]["name"], level, int(player["hp"]), int(player["hpMax"]),
		attack["min"], attack["max"], int(GameData.COMBAT_SPEED_BY_LEVEL[level]))
	fighter["loadout"] = _round_loadout(player["loadout"]["slots"])
	fighter["dial"] = _round_dial("")
	fighter["moveOwner"] = ""
	fighter["moveLevels"] = MoveLevels.levels_of("")
	CombatRounds.carry_in(fighter, ActiveEffects.prophets_breath_active(), ActiveEffects.lady_level())
	# A demo fight's player is a spectator, down from the start.
	if combat["demo"] is Dictionary:
		fighter["koed"] = true
		combat["playerKoed"] = true
	combatants.append(fighter)
	var ally_plans: Array = config.get("allyPlans", [])
	var friends: Array = combat["allies"] + combat["allyQueue"]
	var ally_names: Array = friends.map(func(a): return str(a["name"]))
	for i in range(friends.size()):
		var ally := _round_ally_combatant(friends[i])
		# Two hired guards read "Hired Guard A", "Hired Guard B".
		if ally_names.count(ally_names[i]) > 1:
			ally["name"] = "%s %s" % [ally_names[i], char(65 + ally_names.slice(0, i).count(ally_names[i]))]
		ally["planOverride"] = ally_plans[i] if i < ally_plans.size() else null
		_seat_round_fighter(combatants, friends[i], ally, i < combat["allies"].size())
	var plans: Array = config.get("enemyPlans", [])
	var unread: Array = config.get("enemyUnread", [])
	var foes: Array = combat["enemies"] + combat["enemyQueue"]
	var names: Array = foes.map(func(e): return _round_enemy_name(e))
	for i in range(foes.size()):
		# Fight-scoped, so the stage tells an entrant from the fighter it replaces.
		foes[i]["rid"] = i
		var enemy := _round_enemy_combatant(foes[i])
		enemy["rid"] = i
		if names.count(names[i]) > 1:
			enemy["name"] = "%s %s" % [names[i], char(65 + names.slice(0, i).count(names[i]))]
		enemy["planOverride"] = plans[i] if i < plans.size() else null
		enemy["unreadOverride"] = unread[i] if i < unread.size() else null
		_seat_round_fighter(combatants, foes[i], enemy, i < combat["enemies"].size())
	CombatRounds.open_fight(combat, int(config.get("seed", Rng.randi_range(0, 0x7FFFFFFF))))
	GameState.state["combat"] = combat
	_settle_round_dials(combat)
	_sync_round_outcome(combat)
	TimingLog.begin(TimingLog.KIND_FIGHT, context)
	_enter_combat_screen()


# An active fighter joins the combatants; a queued one waits in its queue
# entry for CombatRounds's round-boundary admission (R§3.7b
# Reinforcements).
static func _seat_round_fighter(combatants: Array, entry: Dictionary, fighter: Dictionary, active: bool) -> void:
	if active:
		combatants.append(fighter)
	else:
		entry["fighter"] = fighter


# A mugger reads as its archetype ("the mugger"); any other template keeps
# its own name.
static func _round_enemy_name(entry: Dictionary) -> String:
	if entry.get("isMugging", false):
		return GameData.COMBAT_ROUNDS["archetypes"][entry["archetype"]]["name"]
	return str(entry["name"])


static func _round_enemy_combatant(entry: Dictionary) -> Dictionary:
	var attack := get_enemy_attack_range(entry)
	var enemy := _round_combatant(CombatRounds.SIDE_ENEMY, _round_enemy_name(entry), entry, attack["min"], attack["max"])
	enemy["archetype"] = entry["archetype"]
	# Every enemy plans from the squad's shared raider kit (R§3.7b Table 5).
	enemy["kit"] = CombatRounds.KIT_RAIDER
	# What a Blast's disarm can take (R§3.7b Table 4).
	var weapon = entry.get("weapon")
	enemy["weapon"] = weapon.duplicate() if weapon is Dictionary else null
	var ability = entry.get("ability")
	enemy["ability"] = ability.duplicate() if ability is Dictionary else null
	enemy["evadeChance"] = float(entry.get("evadeChance", 0.0))
	# A scrapper's sprite is its territorial variant; any other enemy's, its template.
	enemy["template"] = str(entry.get("variant", entry.get("template", "")))
	return enemy


# An ally at its R§3.7b table 3 level (the entry's `level`), with its stage
# sprite (its contact's; "" for a guard or muscle) and its real slots as
# round-fight items (plus any failsafe, its own reactive save), less any it
# refuses (loadout.allyExcluded). A guard ally plans from the shared guard
# kit (R§3.7b Table 5).
static func _round_ally_combatant(entry: Dictionary) -> Dictionary:
	var ally := _round_combatant(CombatRounds.SIDE_ALLY, str(entry["name"]), entry, int(entry["attackMin"]), int(entry["attackMax"]))
	ally["template"] = str(entry.get("sprite", entry.get("contactId", "")))
	ally["loadout"] = _round_loadout(entry.get("slots", []), GameData.LOADOUT["allyExcluded"], [CombatRounds.FAILSAFE])
	if entry.get("guardAlly", false):
		ally["kit"] = CombatRounds.KIT_GUARD
	var contact_id := str(entry.get("contactId", ""))
	if contact_id != "":
		ally["dial"] = _round_dial(contact_id)
		# A recruit's move levels and XP are its own; anyone else's roll per fight.
		if GameState.state["contacts"].has(contact_id):
			ally["moveOwner"] = contact_id
			ally["moveLevels"] = MoveLevels.levels_of(contact_id)
	return ally


# A combatant at the entry's level: its own hp, attack and speed plus that
# level's HP/attack bonuses and R§3.7b's speed rule.
static func _round_combatant(side: String, combatant_name: String, entry: Dictionary, attack_min: int, attack_max: int) -> Dictionary:
	var level: int = clampi(int(entry.get("level", 1)), 1, CombatRounds.level_max())
	var hp_bonus: int = GameData.COMBAT_HP_BONUS_BY_LEVEL[level]
	var attack_bonus: int = GameData.COMBAT_ATTACK_BONUS_BY_LEVEL[level]
	var speed_bonus: int = GameData.COMBAT_SPEED_BY_LEVEL[level] - GameData.COMBAT_SPEED_BY_LEVEL[1]
	var fighter := CombatRounds.new_combatant(side, combatant_name, level,
		int(entry["hp"]) + hp_bonus, int(entry["hpMax"]) + hp_bonus,
		attack_min + attack_bonus, attack_max + attack_bonus,
		int(entry.get("speed", DEFAULT_TEMPLATE_SPEED)) + speed_bonus)
	# A scripted fight pins its fighters' move levels.
	if entry.has("moveLevels"):
		for move_id in entry["moveLevels"].keys():
			fighter["moveLevels"][move_id] = int(entry["moveLevels"][move_id])
	return fighter


# The player's or a recruit's real slots { recipe, tier, multi? } as
# round-fight loadout entries at the unit's tier power (multi for a crafted
# multi-target or always-multi unit), each remembering its real slot
# (sourceSlot) for settlement; empty slots, units the round rules have no
# item for (bar `reactive` recipes, kept though never picked) and `excluded`
# recipes are left out.
static func _round_loadout(slots: Array, excluded: Array = [], reactive: Array = []) -> Array:
	var loadout: Array = []
	for i in range(slots.size()):
		var unit = slots[i]
		if unit is Dictionary and (CombatRounds.is_item(unit["recipe"]) or reactive.has(unit["recipe"])) and not excluded.has(unit["recipe"]):
			var tier := clampi(int(unit["tier"]), 1, CombatRounds.item_tier_max(unit["recipe"]))
			loadout.append({ "item": unit["recipe"], "tier": tier,
				"power": int(Crafting.effect_power(unit["recipe"], tier)), "used": false, "sourceSlot": i,
				"multi": bool(unit.get("multi", false)) or Crafting.is_always_multi(unit["recipe"]) })
	return loadout


# `owner_id`'s Dial ("" for the player's) as a round-fight dial view
# (CombatRounds.new_combatant()), or null for none: its charge, and a
# cast per loaded Complication with a round-fight item at what casting it
# would amount to now (R§3.7b Dial Complications, §3.5 Dial-level cast
# scaling): Time Pearl / Prophet's Breath power × targets + the level's
# turns, Panic / Pan's Rapture power + them, Black Hole its freeze as lost,
# Panger / Pandemonium angerPct scaled by the cast's magnitude, Enhancement
# Powder its power, the rest power × targets.
static func _round_dial(owner_id: String) -> Variant:
	var dial: Variant = Dial.dial_of(owner_id)
	if dial == null:
		return null
	var casts: Array = []
	var loaded: Array = dial["loadedComplications"]
	for i in range(loaded.size()):
		var key: String = loaded[i]["recipeKey"]
		if not COMBAT_COMPLICATION_RECIPES.has(key) or not CombatRounds.is_item(key):
			continue
		var amp := Dial.cast_magnitude(dial, loaded[i])
		var power: int = int(amp["power"]) * int(amp["targets"])
		var cast := { "item": key, "tier": int(loaded[i]["tier"]), "multi": bool(loaded[i].get("multi", false)), "sourceIndex": i }
		match key:
			"timePearl", "prophetsBreath":
				power += int(amp["turnBonus"])
			"panic", "pansRapture":
				power = int(amp["power"]) + int(amp["turnBonus"])
			"enhancementPowder":
				power = int(amp["power"])
			"blackHole":
				var params: Dictionary = CombatRounds.move(key)["params"]
				cast["lost"] = (int(params["actionsBase"]) + floori(int(amp["turnPower"]) / float(params["powerPerAction"]))) * int(amp["targets"]) + int(amp["turnBonus"])
			"panger", "pandemonium":
				cast["angerPct"] = GameState.round_epsilon(float(GameData.COMBAT_ROUNDS["anger"]["pctPerTier"]) * cast["tier"] * float(amp["magnitudeMult"]))
		cast["power"] = power
		casts.append(cast)
	return { "owner": owner_id, "charge": dial["currentCharge"], "regenCounter": int(dial.get("combatRegenTurnCounter", 0)),
		"casts": casts, "spent": [], "actions": 0 }


# Settles what the pick just resolved on each real Dial: every cast charges
# it and earns its XP through Dial.cast_complication(), then each of the
# owner's resolved actions is one combat turn of tier-5 Recharge regen
# (Dial.combat_turn_tick(), R§3.5).
static func _settle_round_dials(combat: Dictionary) -> void:
	for fighter in combat["combatants"]:
		var view: Variant = fighter.get("dial")
		if view is Dictionary:
			for index in view["spent"]:
				Dial.cast_complication(int(index), view["owner"])
			for _n in int(view.get("actions", 0)):
				Dial.combat_turn_tick(view["owner"])
			view["spent"] = []
			view["actions"] = 0


# Each fighter's dial view follows its real Dial (charge, and cast power
# after a level-up).
static func _refresh_round_dials(combat: Dictionary) -> void:
	for fighter in combat["combatants"]:
		if fighter.get("dial") is Dictionary:
			fighter["dial"] = _round_dial(fighter["dial"]["owner"])


# The player's round-fight loadout entry for real loadout slot `index`, or
# -1 when the slot's unit has no round-fight item.
static func _round_entry(combat: Dictionary, index: int) -> int:
	var loadout: Array = combat["combatants"][CombatRounds.PLAYER_INDEX]["loadout"]
	for i in range(loadout.size()):
		if int(loadout[i]["sourceSlot"]) == index:
			return i
	return -1


# Plays the unit in real loadout slot `index` at the round fight's paused
# player position (target -1: the item's default), as choose_move().
static func choose_item(index: int, target: int = -1) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"]:
		return { "ok": false, "reason": "Combat not active." }
	var reason := round_item_block_reason(index, target)
	if reason != "":
		return { "ok": false, "reason": reason }
	return _play_round_pick(combat, { "slot": _round_entry(combat, index), "target": target })


# Casts the player's loaded Complication `index` (player.dial
# .loadedComplications) at the round fight's paused player position (target
# -1: the item's default), as choose_move(): 1 action, guard state unchanged
# (R§3.7b Dial Complications); its charge and XP land as it resolves.
static func cast_round_complication(index: int, target: int = -1) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"]:
		return { "ok": false, "reason": "Combat not active." }
	var reason := round_cast_block_reason(index, target)
	if reason != "":
		return { "ok": false, "reason": reason }
	return _play_round_pick(combat, { "dial": _round_cast(combat, index), "target": target })


# Why the player's loaded Complication `index` can't be cast (at `target`,
# -1 for the default) in a round fight, or "" if it can.
static func round_cast_block_reason(index: int, target: int = -1) -> String:
	var dial: Variant = GameState.state["player"]["dial"]
	if dial == null:
		return "No Dial."
	var loaded: Array = dial["loadedComplications"]
	if index < 0 or index >= loaded.size():
		return "No such Complication."
	if loaded[index]["recipeKey"] == "rewind":
		return "Use Rewind for a rewind unit."
	var cast := _round_cast(GameState.state["combat"], index)
	if cast < 0:
		return "No combat effect for that unit."
	return CombatRounds.cast_block_reason(GameState.state["combat"], cast, target)


# The player's dial-view cast for loaded Complication `index`, or -1 when it
# has none.
static func _round_cast(combat: Dictionary, index: int) -> int:
	var view: Variant = combat["combatants"][CombatRounds.PLAYER_INDEX].get("dial")
	if not (view is Dictionary):
		return -1
	var casts: Array = view["casts"]
	return casts.find_custom(func(c): return int(c["sourceIndex"]) == index)


# Shows a demo fight's next beat, as CombatRounds.demo_continue() (the
# voiceover box's Continue). Returns { ok, beats, outcome } or
# { ok: false, reason } when no demo is on.
static func demo_continue() -> Dictionary:
	return _demo_play(CombatRounds.demo_continue)


# Shows the rest of a demo fight's round, as CombatRounds.demo_step().
# Returns as demo_continue().
static func demo_step() -> Dictionary:
	return _demo_play(CombatRounds.demo_step)


static func _demo_play(play: Callable) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or not CombatRounds.is_demo(combat):
		return { "ok": false, "reason": "No demo on." }
	var beats: Array = play.call(combat)
	_sync_round_outcome(combat)
	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats, "outcome": combat["outcome"] }


# Plays `move_id` at the round fight's paused player position (target -1:
# the move's default), as CombatRounds.play_pick(). Returns
# { ok, beats, outcome } or { ok: false, reason }; a pick whose KO a
# Failsafe or ally rewind undid returns no beats and "saved": its line.
static func choose_move(move_id: String, target: int = -1) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"]:
		return { "ok": false, "reason": "Combat not active." }
	return _play_round_pick(combat, { "move": move_id, "target": target })


static func _play_round_pick(combat: Dictionary, action: Dictionary) -> Dictionary:
	combat["loadoutSlots"] = GameState.state["player"]["loadout"]["slots"].duplicate(true)
	var result := CombatRounds.play_pick(combat, action, ROUND_SNAPSHOT_STACK)
	if not result["ok"]:
		return result
	_settle_round_dials(combat)
	var saved := _try_round_save(combat)
	if saved != "":
		result = { "ok": true, "beats": [], "outcome": combat["outcome"], "saved": saved }
	else:
		result["beats"].append_array(CombatRounds.continue_after_ko(combat))
		result["outcome"] = combat["outcome"]
		_settle_round_dials(combat)
		_keep_round_frame(combat)
	_sync_round_outcome(combat)
	EventBus.state_changed.emit()
	return result


# Frames the fight at its paused position when it has moved into a round no
# frame holds yet (CombatRounds.push_round_frame()), for a tiered Rewind.
static func _keep_round_frame(combat: Dictionary) -> void:
	if combat["outcome"] != null:
		return
	var frames: Array = combat.get("roundFrames", [])
	if not frames.is_empty() and int(frames[-1]["round"]) >= int(combat["round"]):
		return
	combat["loadoutSlots"] = GameState.state["player"]["loadout"]["slots"].duplicate(true)
	CombatRounds.push_round_frame(combat)


# R§3.7b Failsafe and guard-kit rewind: the player's KO in the pick just
# played is undone by the player's loadout Failsafe, else by the first
# ally left standing that holds a rewind (guard kit or recruit slot). Either
# restores the last-pick snapshot and stays spent. Returns the transcript line,
# or "" when nothing saved the player.
static func _try_round_save(combat: Dictionary) -> String:
	if not combat["combatants"][CombatRounds.PLAYER_INDEX]["koed"] or combat["snapshots"].is_empty():
		return ""
	var failsafe := Loadout.find_slot("failsafe")
	if failsafe >= 0:
		_restore_round_snapshot(combat)
		Loadout.consume(failsafe)
		return _push_round_line(combat, LINE_FAILSAFE)
	var allies: Array = combat["allies"]
	for i in range(allies.size()):
		var fighter := _round_ally_fighter(combat, i)
		if fighter["koed"] or not _uses_items(allies[i]) or not _guard_pool_has(_ally_item_pool(combat, allies[i]), "rewind"):
			continue
		_restore_round_snapshot(combat)
		var ally: Dictionary = combat["allies"][i]
		var pool := _ally_item_pool(combat, ally)
		_spend_guard_item(pool, "rewind")
		_sync_ally_slots(ally, pool)
		return _push_round_line(combat, LINE_ALLY_REWIND % fighter["name"])
	return ""


# Appends `line` to the fight's transcript.
static func _push_round_line(combat: Dictionary, line: String) -> String:
	combat["transcript"].append(line)
	return line


# Restores the round fight's newest snapshot whole (R§3.7b Rewind; with a
# `depth` of rounds, the round-start frame that far back, `to_start` the
# opening frame, see CombatRounds.rewind_rounds()), the
# player's real loadout slots and every real Dial's charge (and Recharge
# regen count) with it, so every unit and cast spent since comes back (cast
# XP stays earned) -- bar the
# units earlier Rewinds were paid with: the player's rewinds, Dial rewind
# casts and Failsafes, recruits' slot rewinds and the guard kit's rewinds,
# which only ever leave as payment. The caller spends whatever pays for
# this one. Returns { logKept, restored? } as CombatRounds.rewind_rounds()
# does (a single-pick undo keeps the whole restored log).
static func _restore_round_snapshot(combat: Dictionary, depth: int = 0, to_start: bool = false) -> Dictionary:
	var slots: Array = GameState.state["player"]["loadout"]["slots"]
	var slots_before: Array = slots.duplicate()
	var ally_slots_before: Array = combat["allies"].map(func(a: Dictionary) -> Array: return a.get("slots", []).duplicate())
	var kit_before: Dictionary = combat["guardKit"].duplicate(true)
	var dial_rewinds: int = int(combat.get("dialRewindsPaid", 0))
	var replayed := false
	var undo := {}
	if depth > 0:
		var restored: Dictionary = CombatRounds.rewind_rounds(combat, depth, to_start)
		replayed = bool(restored.get("replayed", false))
		undo["logKept"] = int(restored.get("logKept", combat["log"].size()))
		if restored.has("restored"):
			undo["restored"] = restored["restored"]
	else:
		CombatRounds.rewind_pick(combat)
		CombatRounds.prune_round_frames(combat)
		undo["logKept"] = combat["log"].size()
	var rewinds_since: int = dial_rewinds - int(combat.get("dialRewindsPaid", 0))
	combat["dialRewindsPaid"] = dial_rewinds
	for fighter in combat["combatants"]:
		var view: Variant = fighter.get("dial")
		if view is Dictionary:
			var dial: Dictionary = Dial.dial_of(view["owner"])
			dial["currentCharge"] = view["charge"] - (rewinds_since if view["owner"] == "" else 0)
			dial["combatRegenTurnCounter"] = int(view.get("regenCounter", 0))
	var kept: Array = combat["loadoutSlots"]
	for i in range(mini(slots.size(), kept.size())):
		slots[i] = kept[i].duplicate() if kept[i] is Dictionary else null
	_keep_paid(slots, slots_before, combat["slotsUsed"], ["rewind", "failsafe"])
	var allies: Array = combat["allies"]
	for i in range(mini(allies.size(), ally_slots_before.size())):
		if allies[i].has("slots"):
			var used: Array = allies[i].get("slotsUsed", [])
			allies[i]["slotsUsed"] = used
			_keep_paid(allies[i]["slots"], ally_slots_before[i], used, ["rewind"])
	for part in ["items", "used"]:
		if kit_before.has(part):
			var held: Variant = kit_before[part].get("rewind")
			if held is Dictionary:
				combat["guardKit"][part]["rewind"] = held
			else:
				combat["guardKit"][part].erase("rewind")
	if replayed:
		_settle_round_dials(combat)
	return undo


# Empties each of `slots` holding a `recipes` unit that `before` (the same
# slots before the restore) had already spent, recording it in `used`.
static func _keep_paid(slots: Array, before: Array, used: Array, recipes: Array) -> void:
	for i in range(mini(slots.size(), before.size())):
		if slots[i] is Dictionary and recipes.has(slots[i]["recipe"]) and before[i] == null:
			slots[i] = null
			if not used.has(i):
				used.append(i)


# Why the round fight's Rewind command can't run now, or "". `pay` is how it
# will be paid (REWIND_PAY_*).
static func round_rewind_block_reason(pay: String = REWIND_PAY_ANY) -> String:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return "Combat not active."
	if CombatRounds.is_demo(combat):
		return CombatRounds.DEMO_REASON
	if pay == REWIND_PAY_FREE and not CombatRounds.is_spar(combat):
		return REASON_NO_HOUSE_RULES
	if not CombatRounds.can_rewind_rounds(combat) and not CombatRounds.script_locked(combat):
		return REASON_NOTHING_TO_UNDO
	if pay == REWIND_PAY_FREE:
		return ""
	var has_unit := pay != REWIND_PAY_DIAL and Loadout.find_slot("rewind") >= 0
	var has_cast := pay != REWIND_PAY_LOADOUT and Dial.find_loaded_rewind_complication_index() >= 0
	if not has_unit and not has_cast:
		return REASON_NO_REWIND
	return ""


# Rounds a rewind unit of `tier` takes the fight back (the recipe's
# effectPower), and whether that is the fight's start (the top tier).
static func rewind_depth(tier: int) -> int:
	return int(Crafting.effect_power("rewind", tier))


static func rewind_goes_to_start(tier: int) -> bool:
	return rewind_depth(tier) >= GameData.RECIPES["rewind"]["effectPower"].size() - 1


# PROSE-REVIEW: how far a rewind unit of `tier` takes the fight, as the
# Rewind control shows it.
static func rewind_depth_text(tier: int) -> String:
	if rewind_goes_to_start(tier):
		return "to the start"
	var depth := rewind_depth(tier)
	return "back %d round%s" % [depth, "" if depth == 1 else "s"]


# The tier of the unit `pay` would spend, from the loadout rewind unit when
# there is one (and `pay` allows it), else the loaded Dial rewind
# Complication; 0 when neither.
static func rewind_pay_tier(pay: String = REWIND_PAY_ANY) -> int:
	var slot := Loadout.find_slot("rewind") if pay != REWIND_PAY_DIAL else -1
	if slot >= 0:
		return int(Loadout.slot(slot)["tier"])
	var cast := Dial.find_loaded_rewind_complication_index() if pay != REWIND_PAY_LOADOUT else -1
	if cast >= 0:
		return int(GameState.state["player"]["dial"]["loadedComplications"][cast]["tier"])
	return 0


# R§3.7b Rewind: back by the paying unit's tier depth in rounds (the top
# tier to the fight's start). Paid per `pay`: REWIND_PAY_LOADOUT a loadout rewind unit,
# REWIND_PAY_DIAL one charge of a loaded Dial rewind cast, REWIND_PAY_ANY
# the unit if there is one, else the Dial. Returns { ok, logKept, restored? }
# (as _restore_round_snapshot() returns them) or { ok: false, reason }.
static func round_rewind(pay: String = REWIND_PAY_ANY) -> Dictionary:
	var reason := round_rewind_block_reason(pay)
	if reason != "":
		return { "ok": false, "reason": reason }
	var combat: Dictionary = GameState.state["combat"]
	if pay == REWIND_PAY_FREE:
		var free_view := _restore_round_snapshot(combat, int(combat["spar"]["rewindRounds"]), false)
		_push_round_line(combat, LINE_REWIND)
		_sync_round_outcome(combat)
		EventBus.state_changed.emit()
		free_view["ok"] = true
		return free_view
	var slot := Loadout.find_slot("rewind") if pay != REWIND_PAY_DIAL else -1
	var tier := rewind_pay_tier(pay)
	var view := _restore_round_snapshot(combat, rewind_depth(tier), rewind_goes_to_start(tier))
	if slot >= 0:
		Loadout.consume(slot)
	else:
		Dial.cast_complication(Dial.find_loaded_rewind_complication_index())
		combat["dialRewindsPaid"] = int(combat.get("dialRewindsPaid", 0)) + 1
	_push_round_line(combat, LINE_REWIND)
	_sync_round_outcome(combat)
	EventBus.state_changed.emit()
	view["ok"] = true
	return view


# Why real loadout slot `index` can't be picked (at `target`, -1 for the
# default) in a round fight, or "" if it can.
static func round_item_block_reason(index: int, target: int = -1) -> String:
	var unit: Variant = Loadout.slot(index)
	if unit == null:
		return REASON_SLOT_EMPTY
	if unit["recipe"] == "failsafe":
		return REASON_SLOT_REACTIVE
	if unit["recipe"] == "rewind":
		return REASON_SLOT_REWIND
	var entry := _round_entry(GameState.state["combat"], index)
	if entry < 0:
		return REASON_ROUND_ITEM_PENDING
	return CombatRounds.item_block_reason(GameState.state["combat"], entry, target)


# The player's hp, spent loadout units and dial views follow the fight; a win dispatches
# onWin; a loss, or a win the allies finished after the player's KO, leaves
# the player on R§3.7a's KO hp.
static func _sync_round_outcome(combat: Dictionary) -> void:
	GameState.state["player"]["hp"] = int(combat["combatants"][CombatRounds.PLAYER_INDEX]["hp"])
	for entry in combat["combatants"][CombatRounds.PLAYER_INDEX]["loadout"]:
		if entry["used"] and Loadout.slot(int(entry["sourceSlot"])) != null:
			Loadout.consume(int(entry["sourceSlot"]))
	_refresh_round_dials(combat)
	_sync_round_allies(combat)
	match combat["outcome"]:
		"win":
			if combat.get("playerKoed", false):
				_settle_player_ko_hp()
			_dispatch_on_win()
		"loss":
			_settle_player_ko_hp()


# combat.allies[i]'s combatant: the fight's i-th ally combatant.
static func _round_ally_fighter(combat: Dictionary, i: int) -> Dictionary:
	return combat["combatants"][CombatRounds.side_indices(combat, CombatRounds.SIDE_ALLY)[i]]


# Each ally's live dict follows its combatant (_round_ally_fighter()): hp,
# a KO (its contact's cooldown starts in exit_combat(), so a Rewind can undo
# it) and the real slots its spent items came from, for exit_combat()'s
# settlement.
static func _sync_round_allies(combat: Dictionary) -> void:
	var allies: Array = combat["allies"]
	for i in range(allies.size()):
		var ally: Dictionary = allies[i]
		var fighter := _round_ally_fighter(combat, i)
		ally["hp"] = int(fighter["hp"])
		ally["koed"] = bool(fighter["koed"])
		var used: Array = ally.get("slotsUsed", [])
		for entry in fighter["loadout"]:
			if entry["used"] and not used.has(int(entry["sourceSlot"])):
				used.append(int(entry["sourceSlot"]))
		ally["slotsUsed"] = used


static func round_fight_xp(outcome) -> int:
	match outcome:
		"win":
			return ROUND_XP_WIN
		"loss":
			return ROUND_XP_LOSS
	return ROUND_XP_FLED


# R§2 combat.locationKey derivation: home contexts -> HOME_LOCATION_KEY;
# vein fights -> the fought vein's district (player's own vein first, then a
# faction site vein); everything else -> world.currentDistrict. A vein id
# that resolves to nothing yields "", which the stage's backdrop lookup
# treats as "no location plate".
static func location_key_for(context: String, vein_id) -> String:
	if HOME_CONTEXTS.has(context):
		return HOME_LOCATION_KEY
	if context == CONTEXT_RAID or context == CONTEXT_DEFEND_VEIN or context == CONTEXT_EVENT_RAID:
		if vein_id == null:
			return ""
		var vein: Variant = Cultivating.find_vein(str(vein_id))
		if vein == null:
			vein = Sites.find_faction_vein(str(vein_id))
		return "" if vein == null else str(vein.get("district", ""))
	return str(GameState.state["world"].get("currentDistrict", ""))


# R§3.7a: shared by the round fight's XP lump (exit_combat()) and train()'s
# gym-session XP -- same Progression.award_xp()/GameData.COMBAT_XP_LEVELS mechanism
# Cultivating.award_xp() already uses.
static func award_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	var on_level_up := func():
		# R§3.7a HP bonus: flat per-level delta on top of hpMax, so it
		# stacks with Home Gym's own flat bonus.
		var level: int = player["combatSkill"]
		var gain: int = GameData.COMBAT_HP_BONUS_BY_LEVEL[level] - GameData.COMBAT_HP_BONUS_BY_LEVEL[level - 1]
		player["hpMax"] += gain
		player["hp"] += gain
		Notify.push("Combat Skill up — now level %d." % level, Notify.CATEGORY_SUCCESS)
	Progression.award_xp(player, "combatXP", "combatSkill", GameData.COMBAT_XP_LEVELS, amount, on_level_up)


# R§3.7a read-only summary for the HQ gym modal. XP values are cumulative
# (COMBAT_XP_LEVELS thresholds); xpFloor/xpNext bound the current level's
# band. "stats" is the player's effective hpMax/attack range/speed now, plus
# R§3.7b actionsPerRound and critChance at that level;
# "nextStats" is the same after one more level (equal to "stats" at max).
static func skill_summary() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var level: int = player["combatSkill"]
	var levels: Array = GameData.COMBAT_XP_LEVELS
	var max_level: int = levels.size() - 1
	var is_max: bool = level >= max_level
	var next: int = level if is_max else level + 1
	var hp: Array = GameData.COMBAT_HP_BONUS_BY_LEVEL
	var atk: Array = GameData.COMBAT_ATTACK_BONUS_BY_LEVEL
	var attack := get_attack_range()
	var actions: Array = GameData.COMBAT_ROUNDS["actionsPerRound"]
	var crit: Array = GameData.COMBAT_ROUNDS["critChance"]
	var stats := {
		"hpMax": player["hpMax"],
		"attackMin": attack["min"],
		"attackMax": attack["max"],
		"speed": GameData.COMBAT_SPEED_BY_LEVEL[level],
		"actionsPerRound": int(actions[level]),
		"critChance": float(crit[level]),
	}
	var atk_gain: int = atk[next] - atk[level]
	var next_stats := {
		"hpMax": stats["hpMax"] + hp[next] - hp[level],
		"attackMin": stats["attackMin"] + atk_gain,
		"attackMax": stats["attackMax"] + atk_gain,
		"speed": GameData.COMBAT_SPEED_BY_LEVEL[next],
		"actionsPerRound": int(actions[next]),
		"critChance": float(crit[next]),
	}
	return {
		"level": level,
		"maxLevel": max_level,
		"isMax": is_max,
		"xp": player["combatXP"],
		"xpFloor": levels[level],
		"xpNext": levels[next],
		"stats": stats,
		"nextStats": next_stats,
	}


# The pool an ally draws from: a guard's shared combat.guardKit; a recruit's is
# built from its own equipped slots ({items, used}, one unit each); {} otherwise.
static func _ally_item_pool(combat: Dictionary, ally: Dictionary) -> Dictionary:
	if ally.get("guardAlly", false):
		return combat.get("guardKit", {})
	var items := {}
	for unit in ally.get("slots", []):
		if unit is Dictionary:
			var key: String = str(int(unit["tier"]))
			if not (items.get(unit["recipe"]) is Dictionary):
				items[unit["recipe"]] = {}
			items[unit["recipe"]][key] = int(items[unit["recipe"]].get(key, 0)) + 1
	return { "items": items, "used": {} } if not items.is_empty() else {}


# Empties the recruit slots whose unit the last pool use spent, marking them
# for settlement refill. Guards have no slots, so this is a no-op for them.
static func _sync_ally_slots(ally: Dictionary, pool: Dictionary) -> void:
	if ally.get("guardAlly", false) or not ally.has("slots"):
		return
	var used: Dictionary = pool.get("used", {})
	for recipe_key in used:
		for tier_key in used[recipe_key]:
			for _n in int(used[recipe_key][tier_key]):
				for i in ally["slots"].size():
					var unit: Variant = ally["slots"][i]
					if unit is Dictionary and unit["recipe"] == recipe_key and str(int(unit["tier"])) == tier_key:
						ally["slots"][i] = null
						if not ally["slotsUsed"].has(i):
							ally["slotsUsed"].append(i)
						break
	pool["used"] = {}


# A dial pool's "spend": casts the highest-tier loaded unit of recipe_key through
# Dial.cast_complication() (charge + XP) and returns its amplified power x targets.
# The cast is kept on pool.lastCast for the turn-bonus readers below.
static func _spend_dial_cast(pool: Dictionary, recipe_key: String, tier: int) -> int:
	var owner_id: String = pool["dialOwner"]
	var loaded: Array = Dial.dial_of(owner_id)["loadedComplications"]
	for i in range(loaded.size()):
		if loaded[i]["recipeKey"] == recipe_key and int(loaded[i]["tier"]) == tier:
			var cast: Dictionary = Dial.cast_complication(i, owner_id)
			pool["lastCast"] = cast
			return int(cast["power"]) * int(cast["targets"])
	return 0


static func _guard_pool_has(pool: Dictionary, recipe_key: String) -> bool:
	return GuardKit.unit_count({ recipe_key: pool.get("items", {}).get(recipe_key, {}) }) > 0


# Moves one unit of recipe_key from pool.items to pool.used, highest tier
# first, and returns its power: effectPower[tier].
static func _spend_guard_item(pool: Dictionary, recipe_key: String) -> int:
	var buckets: Dictionary = pool["items"][recipe_key]
	var tier_key: String = GuardKit.highest_tier_key(buckets)
	var left: int = int(buckets[tier_key]) - 1
	if left > 0:
		buckets[tier_key] = left
	else:
		buckets.erase(tier_key)
		if buckets.is_empty():
			pool["items"].erase(recipe_key)
	if not (pool["used"].get(recipe_key) is Dictionary):
		pool["used"][recipe_key] = {}
	pool["used"][recipe_key][tier_key] = int(pool["used"][recipe_key].get(tier_key, 0)) + 1
	if pool.has("dialOwner"):
		return _spend_dial_cast(pool, recipe_key, int(tier_key))
	var powers: Array = GameData.RECIPES[recipe_key]["effectPower"]
	return int(powers[clampi(int(tier_key), 1, powers.size() - 1)])


# Guards and recruits (allies with loadout slots) take part in item rules.
static func _uses_items(ally: Dictionary) -> bool:
	return ally.get("guardAlly", false) or ally.has("slots")


# After an ally-won victory or a loss the player wakes at PLAYER_KO_HP_FRACTION of hpMax.
static func _settle_player_ko_hp() -> void:
	var player: Dictionary = GameState.state["player"]
	player["hp"] = maxi(1, GameState.round_epsilon(player["hpMax"] * PLAYER_KO_HP_FRACTION))


static func _dispatch_on_win() -> void:
	var combat: Dictionary = GameState.state["combat"]
	var on_win: String = combat.get("onWin", "")
	match on_win:
		"muggingWon":
			pass  # paid out on exit -- _exit_mugging_win()
		"raidWon":
			_raid_won()
		"homeRaidWon":
			_apply_home_raid_outcome("win")
		_:
			pass


static func _raid_won() -> void:
	# M0 has no NPC-claimed-vein storage (M1's prospecting/sites system) --
	# nothing to transfer yet. Kept as a documented no-op so onWin dispatch
	# stays wireable once M1 lands (R§3.7).
	pass


# state.combat with no fight on: the keys exit_combat() and the rest of the
# game read off it between fights.
static func idle_state() -> Dictionary:
	return {
		"active": false, "context": CONTEXT_RAID, "veinId": null, "enemies": [],
		"locationKey": "", "log": [], "transcript": [], "outcome": null, "onWin": null, "snapshots": [],
		# Loadout slot indices spent this fight; exit_combat() refills them.
		"slotsUsed": [],
		# Allies fighting alongside the player this fight.
		"allies": [],
		# A defended raid's shared raider item pool (FactionSim.raider_kit()),
		# and the defended vein's shared guard kit pool; {} otherwise.
		"raiderKit": {}, "guardKit": {},
	}


# Tears down combat state and routes to the next screen (R§3.7): mugging-
# win routes home under the sale modal; home_raid routes into the matching debrief
# event (R§3.8); event_raid resumes the still-active event on a win, ends
# it on a loss; otherwise phone home, bag drawer opened on a raid win.
static func exit_combat() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	# A repeat call (double tap on the outcome button) finds the torn-down dict
	# and would route home over the screen the first call opened.
	if not combat["active"]:
		return { "nextScreen": null }
	var outcome = combat["outcome"]
	var context: String = combat["context"]
	TimingLog.end(TimingLog.KIND_FIGHT, context)
	var raider_items_used: Dictionary = combat.get("raiderKit", {}).get("used", {})
	var stockpile_faction_id: String = combat.get("stockpileFactionId", "")
	var ambush_faction_id: String = combat.get("ambushFactionId", "")
	var script_resume := -1
	if combat.get("script") is Dictionary:
		script_resume = int(combat["script"]["resumeCard"])
	elif CombatRounds.is_demo(combat):
		script_resume = int(combat["demo"]["resumeCard"])

	if CombatRounds.is_spar(combat):
		Sparring.settle(combat["spar"], outcome)
		GameState.state["combat"] = idle_state()
		SaveManager.autosave()
		EventBus.state_changed.emit()
		if context == CONTEXT_SCRIPTED:
			return _exit_scripted(script_resume)
		return _exit_default(outcome, context)

	if round_fight_xp(outcome) > 0:
		award_xp(round_fight_xp(outcome))
	for ally in combat["allies"]:
		if ally["koed"] and ally.has("contactId"):
			Contacts.knock_out(ally["contactId"], GameState.state["world"]["day"])
	Loadout.refill_used(combat.get("slotsUsed", []))
	Loadout.settle_allies(combat["allies"])
	# Hand any allies' ending hp back to persistent contact state
	# before the combat dict is torn down below.
	Contacts.replenish_after_combat(combat["allies"])
	# Guard-kit spec §Defend fight: units guards spent come off the vein's
	# (or HQ's) kit on any outcome, before a claim hands the rest to the attacker.
	var guard_used: Dictionary = combat.get("guardKit", {}).get("used", {})
	if not guard_used.is_empty() and context == CONTEXT_HOME_ALARM_DEFEND:
		GuardKit.remove_units(GameState.state["home"].get("guardKit", {}), guard_used)
		GuardKit.refill_hq(GuardKit.recipe_totals(guard_used))
	elif not guard_used.is_empty() and combat["veinId"] != null:
		var vein = Cultivating.find_vein(str(combat["veinId"]))
		if vein != null:
			GuardKit.remove_units(vein.get("guardKit", {}), guard_used)
			GuardKit.refill_vein(vein, GuardKit.recipe_totals(guard_used))

	GameState.state["combat"] = idle_state()
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
	if context == CONTEXT_SCRIPTED:
		return _exit_scripted(script_resume)
	if context == CONTEXT_FACTION_AMBUSH:
		Ambush.resolve(ambush_faction_id, outcome == "win")
		return _exit_event_mugging()
	if context == CONTEXT_HOME_RAID:
		return resolve_home_raid(outcome)
	if context == CONTEXT_HOME_ALARM_DEFEND:
		return _exit_home_alarm_defend(outcome)
	if context == CONTEXT_EVENT_RAID:
		if stockpile_faction_id != "":
			Raiding.resolve_stockpile_fight(stockpile_faction_id, outcome == "win", raider_items_used)
		return _exit_event_raid(outcome)
	if context == CONTEXT_DEFEND_VEIN:
		return _exit_defend_vein(outcome, raider_items_used)
	return _exit_default(outcome, context)


# Home beneath, sale modal on top: the modal opens only once the fight is
# over, so its own "Back to it" never leaves a live combat behind (R§3.7).
static func _exit_mugging_win() -> Dictionary:
	_route_phone_home()
	Economy.complete_mugged_sale()
	return { "nextScreen": "phone" }


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


# A scripted fight picks its event up again at the script's resume card.
static func _exit_scripted(resume_card: int) -> Dictionary:
	var event_state: Variant = GameState.state.get("event")
	if event_state is Dictionary:
		event_state["cardIndex"] = resume_card
	return _exit_event_mugging()


# Every "route home" destination below is the phone app grid. Hand-rolled
# rather than PhoneNav.route_home(): exit_combat() already guarantees one
# state_changed emit, so route_home() would fire a redundant second one.
static func _route_phone_home() -> void:
	GameState.state["currentScreen"] = "phone"
	EventBus.screen_changed.emit("phone")
	PhoneNav.go_home()


# The one home-raid outcome path, fought or not (events.gd's resolve_home_raid
# op skips the fight): applies the win/loss consequence, then opens the
# matching debrief event (R§3.8).
static func resolve_home_raid(outcome) -> Dictionary:
	_apply_home_raid_outcome(outcome)
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
static func _exit_defend_vein(outcome, raider_items_used: Dictionary) -> Dictionary:
	Raiding.resolve_defend_outcome(outcome == "win", raider_items_used)
	_route_phone_home()
	return { "nextScreen": "phone" }


# A raid win opens the bag drawer over the phone home grid so the loot is
# immediately visible.
static func _exit_default(outcome, context: String) -> Dictionary:
	_route_phone_home()
	if outcome == "win" and context == CONTEXT_RAID:
		Bag.open()
	return { "nextScreen": "phone" }


# R§3.8: a win sets the homeRaidWon flags; any other outcome halves carried
# orichalchum (floor). Only one pool (player.orichalchum) to lose -- see
# systems/home.gd.
static func _apply_home_raid_outcome(outcome) -> void:
	GameState.state["flags"]["homeRaidEventSeen"] = true
	if outcome == "win":
		GameState.state["flags"]["homeRaidWon"] = true
		return

	GameState.state["flags"]["homeRaidWon"] = false

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
