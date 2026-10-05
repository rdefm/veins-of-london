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

# Contexts fought in the player's own flat (no vein at stake); shared with
# scenes/screens/combat.gd's win-line/label logic.
const HOME_CONTEXTS: Array[String] = [CONTEXT_HOME_RAID, CONTEXT_HOME_ALARM_DEFEND]

# R§2 combat.locationKey for the two home contexts -- home isn't a district.
const HOME_LOCATION_KEY := "home"

# Contexts the debug combat setup may pick: their exit_combat() handlers need
# no active event and apply no story consequence (defend_vein with no
# activeDefendRaid is a no-op), so a throwaway fight can't corrupt a save.
const DEBUG_SETUP_CONTEXTS: Array[String] = [CONTEXT_RAID, CONTEXT_MUGGING, CONTEXT_DEFEND_VEIN]

# Beat "kind" vocabulary (same named-constant precedent as CONTEXT_*) so a
# typo errors instead of silently mismatching the director's switch.
const BEAT_PLAYER_ATTACK := "player_attack"
const BEAT_ALLY_ATTACK := "ally_attack"
const BEAT_ALLY_HEAL := "ally_heal"
const BEAT_ALLY_CAST := "ally_cast"
const BEAT_ENEMY_ATTACK := "enemy_attack"
const BEAT_ENEMY_EVADE := "enemy_evade"
const BEAT_ENEMY_ITEM := "enemy_item"
const BEAT_PLAYER_EVADE := "player_evade"
const BEAT_ABILITY_UNLOCKED := "ability_unlocked"
const BEAT_FROZEN_WEARS_OFF := "frozen_wears_off"
const BEAT_ENEMY_FROZEN := "enemy_frozen"
const BEAT_ENEMY_COWER := "enemy_cower"
const BEAT_ENEMY_FLEE := "enemy_flee"
const BEAT_ENEMY_RAPTURE := "enemy_rapture"
const BEAT_USE_PANIC := "use_panic"
const BEAT_USE_RAPTURE := "use_rapture"
const BEAT_USE_PANGER := "use_panger"
const BEAT_USE_PANDEMONIUM := "use_pandemonium"
const BEAT_ENEMY_FURY_ATTACK := "enemy_fury_attack"
const BEAT_ENEMY_ANGER_END := "enemy_anger_end"
const BEAT_ALLY_KO := "ally_ko"
const BEAT_REINFORCEMENT_ENTER := "reinforcement_enter"
const BEAT_PLAYER_KO := "player_ko"
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
# Panic: each affected enemy turn, independently, cower (turn lost) or run off.
const PANIC_FLEE_CHANCE := 0.5
# Panger / Pandemonium: enemy.anger = {turns, pct, fury}. The first
# ANGER_PHASE_TURNS enemy turns deal +pct% / take -pct%, the next
# ANGER_PHASE_TURNS the reverse; pct = ANGER_PCT_PER_TIER x the unit's tier.
const ANGER_PHASE_TURNS := 2
const ANGER_PCT_PER_TIER := 25

# recipeKeys with a defined combat effect; cast_complication() refuses
# anything else (rejuvenation/beALady/the Pan recipes/healingSalve have no
# in-combat mechanic; rewind casts via combat_rewind()'s own fallback).
const COMBAT_COMPLICATION_RECIPES: Array[String] = ["timePearl", "enhancementPowder", "blast", "shield", "blackHole", "healingBurst", "prophetsBreath", "wormhole", "panic", "panger", "pandemonium", "pansRapture"]

# R§3.7 ally-targetable table + R§2 selection: what each command/effect
# may target. "enemy" needs selection.type == "enemy"; "self" is refused
# while an ally is selected; "ally" heals the selected ally, else the
# player; "untargeted" ignores selection (flee, AoE, Rewind).
const TARGETING_ENEMY := "enemy"
const TARGETING_SELF := "self"
const TARGETING_ALLY := "ally"
const TARGETING_UNTARGETED := "untargeted"
const PAN_STATUS_RECIPES: Array[String] = ["panic", "panger", "pandemonium", "pansRapture"]

const COMMAND_TARGETING := {
	"attack": TARGETING_ENEMY,
	"timePearl": TARGETING_ENEMY,
	"blast": TARGETING_ENEMY,
	"panic": TARGETING_ENEMY,
	"panger": TARGETING_ENEMY,
	"pandemonium": TARGETING_ENEMY,
	"pansRapture": TARGETING_ENEMY,
	"enhancementPowder": TARGETING_SELF,
	"shield": TARGETING_SELF,
	"prophetsBreath": TARGETING_SELF,
	"healingBurst": TARGETING_ALLY,
	"blackHole": TARGETING_UNTARGETED,
	"wormhole": TARGETING_UNTARGETED,
	"rewind": TARGETING_UNTARGETED,
	"flee": TARGETING_UNTARGETED,
}
# PROSE-REVIEW: selection-rejection reasons.
const REASON_SLOT_EMPTY := "Empty."
const REASON_SLOT_REACTIVE := "Fires on its own."
const REASON_NOTHING_TO_UNDO := "Nothing to undo yet."
const REASON_SHIELD_UP := "Shield already up."
const REASON_SELECT_ENEMY := "Select an enemy first."
const REASON_SELF_ONLY := "That one's only for you."

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
# (at least 1, no upper cap) entries roll independently from
# GameData.ENEMY_RAID_GUARDS unless `template_key` forces one template.
static func generate_raid_enemy(vein_id, value_tier: int, guards: int = 1, template_key: String = "") -> Array:
	var templates: Dictionary = GameData.ENEMY_RAID_GUARDS
	var guard_count: int = maxi(guards, 1)
	var entries: Array = []
	var used_variants: Array = []
	for _i in range(guard_count):
		var key: String = template_key
		if key == "" or not templates.has(key):
			key = Rng.rand_from(templates.keys())
		var entry := _spawn_guard_instance(templates[key], value_tier)
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
		["They're in the flat. You've got your hands. This is happening."],
		"homeRaidWon")


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
	_start_combat(CONTEXT_HOME_ALARM_DEFEND, null, [_home_raider_enemy()], log_lines,
		"", allies, null, {}, guard_kit)


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


# A caught stockpile raid (events.gd "start_stockpile_raid_combat"): one
# enemy per stockpile guard (at least one), sharing the faction's defend kit
# as combat.raiderKit, in the stockpile's district. Runs as an event_raid, so
# a win resumes the event; combat.stockpileFactionId routes the settlement to
# Raiding.resolve_stockpile_fight().
static func start_stockpile_raid(faction_id: String, value_tier: int, guards: int, template_key: String = "", ally_ids: Array = []) -> void:
	var enemies := generate_raid_enemy(null, value_tier, guards, template_key)
	var log_lines := ["%s steps out to meet you." % _guard_group_name(enemies)]
	var allies := _gather_raid_allies(ally_ids, log_lines)
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


# The alarm-upgrade defend encounter, called by Raiding.maybe_trigger_defend()
# once the player travels into the vein's district within the pending
# window. onWin is "" -- a loss is handled by Raiding.resolve_defend_outcome().
# attacker_id's attack kit becomes the squad's shared item pool, sized by the
# full roster (FactionSim.raider_kit(); "" = none); see _enemy_try_item().
# partner_ids: partner factions
# sending a fighter (Partners.defence_helpers), joining after contacts.
static func start_defend_vein(vein_id: String, value_tier: int, attacker_id: String = "", partner_ids: Array = [], ally_ids: Variant = null) -> void:
	var enemies := generate_raid_enemy(vein_id, value_tier)
	var raider_kit: Dictionary = {} if attacker_id == "" else FactionSim.raider_kit(attacker_id, "attack", enemies.size())
	var log_lines := ["The alarm wasn't lying. %s is already there." % _guard_group_name(enemies)]
	# Act 2 T8a's pre-fight reminder (spec §5.1/§6.8a): one Nadia-voiced line,
	# prepended only for the vein col_a2_nadia_defend is watching, only once.
	if vein_id == GameState.state["collective"].get("nadiaDefendVeinId") and not GameState.state["flags"].get("colA2DefendReminderShown", false):
		log_lines.push_front("Nadia, in your ear: \"Go on then. That's what the Blast and the Shield were for — use them properly this time, not for luck.\"")
		GameState.state["flags"]["colA2DefendReminderShown"] = true
	var allies := _gather_defend_allies(log_lines, ally_ids)
	for faction_id in partner_ids:
		allies.append(build_partner_ally(faction_id))
		log_lines.append(Partners.join_line(faction_id))
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
# contacts and partner helpers. A KO only lasts the fight -- no contactId, so
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
		"koed": false,
	}


# A partner faction's fighter (R§3.10 "Partners"): guardAlly stats under the
# faction's helper name. No contactId (a KO lasts the fight) and no
# guardAlly flag (it doesn't draw on the vein's guard kit).
static func build_partner_ally(faction_id: String) -> Dictionary:
	var ally := build_guard_ally()
	ally.erase("guardAlly")
	ally["name"] = Partners.helper_name(faction_id)
	ally["partnerFactionId"] = faction_id
	return ally


# Debug-only (combat_setup_modal.gd): raid-guard roster under any
# DEBUG_SETUP_CONTEXTS context, with an optional locationKey override so every
# backdrop tier can be previewed. location_key == "" derives it as normal.
static func start_debug_combat(context: String, location_key: String, value_tier: int, guards: int, template_key: String, ally_ids: Array) -> void:
	if not DEBUG_SETUP_CONTEXTS.has(context):
		push_error("Combat.start_debug_combat: context '%s' is not in DEBUG_SETUP_CONTEXTS" % context)
		return
	var enemies := generate_raid_enemy("debug_combat_setup", value_tier, guards, template_key)
	var log_lines := ["%s steps out to meet you." % _guard_group_name(enemies)]
	var allies := _gather_raid_allies(ally_ids, log_lines)
	var on_win := "raidWon" if context == CONTEXT_RAID else ""
	_start_combat(context, "debug_combat_setup", enemies, log_lines, on_win, allies,
		location_key if not location_key.is_empty() else null)


static func _start_combat(context: String, vein_id, enemies: Array, log_lines: Array, on_win: String, allies: Array = [], location_key_override: Variant = null, raider_kit: Dictionary = {}, guard_kit: Dictionary = {}) -> void:
	if not is_canonical_context(context):
		push_error("Combat: unrecognized context '%s' — not in CANONICAL_CONTEXTS, exit_combat() will mis-route it." % context)
	# Every roster entry needs koed regardless of which start_* path built
	# it -- one chokepoint (speed is already set at construction time).
	# `rid` is a fight-scoped identity, so a Rewind can tell which fighter holds
	# a slot after reinforcements substituted in.
	for i in range(enemies.size()):
		enemies[i]["koed"] = false
		enemies[i]["rid"] = i
	# The player holds one of the friendly SQUAD_MAX places; the rest of both
	# rosters wait in order (R§3.7a "Reinforcements").
	var ally_queue: Array = allies.slice(SQUAD_MAX - 1) if allies.size() > SQUAD_MAX - 1 else []
	var enemy_queue: Array = enemies.slice(SQUAD_MAX) if enemies.size() > SQUAD_MAX else []
	allies = allies.slice(0, SQUAD_MAX - 1)
	enemies = enemies.slice(0, SQUAD_MAX)
	GameState.state["combat"] = {
		"active": true, "context": context, "veinId": vein_id, "enemies": enemies,
		"enemyQueue": enemy_queue, "allyQueue": ally_queue,
		"locationKey": location_key_for(context, vein_id) if location_key_override == null else str(location_key_override),
		# R§2: player/ally/enemy selection. Defaults to the first enemy.
		"selection": { "type": "enemy", "index": 0 },
		"log": log_lines, "outcome": null, "frozenTurns": 0, "frozenSkipped": [], "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": on_win, "snapshots": [],
		"allies": allies,
		"raiderKit": raider_kit,
		# Guard-kit spec §Defend fight: the vein's active kit as a shared
		# guard pool, { items, used } by recipe and tier; {} elsewhere.
		"guardKit": guard_kit,
		# Every beat _log() threads since the oldest snapshot still on the stack
		# was pushed; see combat_rewind()'s "beat queue in reverse" use of it.
		"beatsSinceSnapshot": [],
		"slotsUsed": [],
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


# The validity query every command and the dock/Bag share: "" when
# `command_key` (a COMMAND_TARGETING key) may resolve against the current
# combat.selection, else the rejection reason. Never redirects an
# enemy-only command to a fallback enemy (R§2).
static func selection_block_reason(command_key: String) -> String:
	var selection_type: String = GameState.state["combat"]["selection"]["type"]
	match COMMAND_TARGETING.get(command_key, TARGETING_UNTARGETED):
		TARGETING_ENEMY:
			return "" if selection_type == "enemy" else REASON_SELECT_ENEMY
		TARGETING_SELF:
			return REASON_SELF_ONLY if selection_type == "ally" else ""
	return ""


# The dock item row's gate: "" when loadout slot `index` can be used right
# now, else why not. Failsafe is reactive (fires on a lethal hit), never
# pressed; Rewind needs a snapshot to restore to.
static func slot_block_reason(index: int) -> String:
	var unit: Variant = Loadout.slot(index)
	if unit == null:
		return REASON_SLOT_EMPTY
	var recipe_key: String = unit["recipe"]
	if recipe_key == "failsafe":
		return REASON_SLOT_REACTIVE
	if recipe_key == "rewind":
		return "" if not GameState.state["combat"]["snapshots"].is_empty() else REASON_NOTHING_TO_UNDO
	if recipe_key == "shield" and GameState.state["player"]["shieldPool"] > 0:
		return REASON_SHIELD_UP
	if Loadout.slot_is_multi(index):
		return ""
	return selection_block_reason(recipe_key)


# The selected ally when selection.type == "ally" and that ally is still
# standing, else -1 -- the player is the fallback target for ally-eligible
# effects (R§3.7 ally-targetable table).
static func selected_ally_index(combat: Dictionary) -> int:
	var selection: Dictionary = combat["selection"]
	if selection["type"] != "ally":
		return -1
	var idx: int = selection["index"]
	if idx < 0 or idx >= combat["allies"].size() or combat["allies"][idx]["koed"]:
		return -1
	return idx


# Raises ally.hp by `amount`, capped at ally.hpMax; returns HP actually
# gained.
static func heal_ally(ally: Dictionary, amount: int) -> int:
	var old_hp: int = ally["hp"]
	ally["hp"] = mini(ally["hp"] + amount, ally["hpMax"])
	return ally["hp"] - old_hp


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
		# Whole focused fighter plus the waiting queue, so a Rewind can undo a
		# reinforcement substitution at that slot.
		"enemy": focused.duplicate(true),
		"enemyQueue": combat.get("enemyQueue", []).duplicate(true),
		"selection": combat["selection"].duplicate(),
		"log": combat["log"].duplicate(),
		"frozenTurns": combat["frozenTurns"],
		"frozenSkipped": combat.get("frozenSkipped", []).duplicate(),
		"motionTurns": combat["motionTurns"],
		"motionPower": combat["motionPower"],
		# Per-ally Enhancement Powder state, index-aligned with combat.allies,
		# so a restored turnCursor's ally extras match their motionTurns.
		"allyMotion": combat["allies"].map(func(a: Dictionary) -> Dictionary:
			return { "motionTurns": int(a.get("motionTurns", 0)), "motionPower": int(a.get("motionPower", 0)) }),
		"evadeTurns": combat["evadeTurns"],
		"evadeChance": combat["evadeChance"],
		# R§3.7a: parked cursor position at this decision point, so a
		# restore resumes at the same queued player-type entry rather than
		# losing its place in the round.
		"turnCursor": combat["turnCursor"].duplicate(true),
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

	# A guard's Enhancement Powder (ally.motionTurns > 0) inserts that ally's
	# extra entries after its own slot, same counts as the player's.
	for i in range(allies.size()):
		var ally: Dictionary = allies[i]
		if ally["koed"] or int(ally.get("motionTurns", 0)) <= 0:
			continue
		var ally_pos := -1
		for q in range(queue.size()):
			if queue[q]["type"] == "ally" and queue[q]["index"] == i:
				ally_pos = q
				break
		if ally_pos == -1:
			continue
		var ally_attack_count: int = 3 if int(ally.get("motionPower", 0)) >= 3 else 2
		for _n in range(ally_attack_count - 1):
			queue.insert(ally_pos + 1, { "type": "ally", "index": i, "speed": ally.get("speed", 0), "extra": true })

	# A KO'd player has left the fight: no slot, no Motion extras.
	if combat.get("playerKoed", false):
		queue = queue.filter(func(e): return e["type"] != "player")
	return queue


# Whether a round's queue carried Motion extras for the player (index -1)
# or for ally `index` -- only then does that combatant's motionTurns tick.
static func _round_spent_motion(queue: Array, type: String, index: int = -1) -> bool:
	for queued_entry in queue:
		if queued_entry.get("extra", false) and queued_entry["type"] == type and (type == "player" or queued_entry["index"] == index):
			return true
	return false


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
			var boundary_beats_start: int = beats.size() if beats != null else 0
			# Only decrement when the round that's ending actually spent the
			# buff (its queue carries Motion-inserted "extra" slots) -- not
			# whenever motionTurns happens to be >0. Activating Motion mid-
			# round (an item use) sets motionTurns after this round's queue
			# was already built without extras, so it takes effect starting
			# next round; decrementing here too would expire it before it
			# ever granted an extra attack, including at the very first
			# round of a fight (queue starts empty, no round has run yet).
			if _round_spent_motion(cursor["queue"], "player") and combat["motionTurns"] > 0:
				combat["motionTurns"] -= 1
				if combat["motionTurns"] == 0:
					_log(combat, beats, "The powder wears off. Back to normal speed.", BEAT_MOTION_END, {})
			var allies: Array = combat["allies"]
			for i in range(allies.size()):
				var ally: Dictionary = allies[i]
				if int(ally.get("motionTurns", 0)) > 0 and _round_spent_motion(cursor["queue"], "ally", i):
					ally["motionTurns"] -= 1
					if ally["motionTurns"] == 0:
						# PROSE-REVIEW: guard Enhancement Powder wear-off line.
						_log(combat, beats, "%s's powder wears off." % ally["name"], BEAT_MOTION_END, { "actorType": "ally", "actorIndex": i })
			cursor["queue"] = build_turn_queue(combat)
			cursor["index"] = 0
			cursor["round"] += 1
			if combat["motionTurns"] > 0:
				var motion_label: String = "three times" if combat["motionPower"] >= 3 else "twice"
				_log(combat, beats, "Motion powder — you move %s as fast." % motion_label, BEAT_MOTION_ANNOUNCE, {})
			_stamp_occurrence(beats, boundary_beats_start, null)
			continue

		var entry: Dictionary = cursor["queue"][cursor["index"]]
		if entry["type"] == "player":
			# The player was KO'd after this round's queue was built: their
			# remaining slots are skipped, never parked on.
			if not combat.get("playerKoed", false):
				return
			cursor["index"] += 1
			continue

		var turn_beats_start: int = beats.size() if beats != null else 0
		cursor["index"] += 1
		cursor["inTurn"] = true
		match entry["type"]:
			"ally":
				var allies: Array = combat["allies"]
				if entry["index"] < allies.size() and not allies[entry["index"]]["koed"]:
					_ally_turn(combat, allies[entry["index"]], entry["index"], beats)
			"enemy":
				var enemies: Array = combat["enemies"]
				if entry["index"] < enemies.size() and not enemies[entry["index"]]["koed"]:
					_enemy_turn(combat, enemies[entry["index"]], entry["index"], beats)
		cursor.erase("inTurn")
		_stamp_occurrence(beats, turn_beats_start, _project_occurrence(entry, cursor["round"], cursor["index"] - 1))

		# A failsafe restore swapped in the snapshot's cursor, already parked
		# at its player decision point -- the rest of this round never ran.
		if combat["outcome"] != null or not is_same(combat["turnCursor"], cursor):
			return


# Tags every beat from `from` onward that isn't tagged yet with the turn
# occurrence that produced it (a project_queue()-shaped entry), or null for
# a round-boundary beat that belongs to no turn -- lets the turn-order strip
# advance in step with playback (docs/combat-animation-vision.md §2.4
# Reflow). Beats share their Dictionary with combat.beatsSinceSnapshot, so
# Rewind's reversed replay carries the same tag.
static func _stamp_occurrence(beats: Variant, from: int, occurrence: Variant) -> void:
	if beats == null:
		return
	for i in range(from, beats.size()):
		if not beats[i].has("occurrence"):
			beats[i]["occurrence"] = occurrence


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
	var cursor: Dictionary = combat["turnCursor"]
	# Every still-untagged trailing beat is this command's own -- anything
	# prime_decision_point() produced was already tagged by the engine.
	if beats != null and cursor["index"] < cursor["queue"].size():
		var from: int = beats.size()
		while from > 0 and not beats[from - 1].has("occurrence"):
			from -= 1
		_stamp_occurrence(beats, from, _project_occurrence(cursor["queue"][cursor["index"]], cursor["round"], cursor["index"]))
	cursor["index"] += 1
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
# `from_round_start` also includes the current round's already-resolved
# occurrences -- the turn-order strip's playback needs the whole committed
# round to lay out turns that resolved but haven't been played back yet.
# A koed combatant's unresolved slots are dropped (the engine skips them);
# once combat.outcome is set nothing is coming, so the plain read is empty.
static func project_queue(combat: Dictionary, from_round_start: bool = false) -> Array:
	var cursor: Dictionary = combat["turnCursor"]
	var projected: Array = []
	if combat.get("outcome") != null and not from_round_start:
		return projected

	for i in range(0 if from_round_start else cursor["index"], cursor["queue"].size()):
		var entry: Dictionary = cursor["queue"][i]
		if i >= cursor["index"] and _entry_koed(combat, entry):
			continue
		projected.append(_project_occurrence(entry, cursor["round"], i))

	# Mirrors advance_to_next_decision()'s own round-boundary tick, but
	# against a duplicated dict so the real combat state is never mutated
	# by a read. Only decrements a projected motionTurns when the ending
	# round's own queue actually carried a Motion-inserted "extra" slot --
	# same reasoning as the real tick (see that function's own comment).
	var projected_combat: Dictionary = combat.duplicate()
	if _round_spent_motion(cursor["queue"], "player") and combat["motionTurns"] > 0:
		projected_combat["motionTurns"] = combat["motionTurns"] - 1
	var projected_allies: Array = combat["allies"].duplicate(true)
	for i in range(projected_allies.size()):
		if int(projected_allies[i].get("motionTurns", 0)) > 0 and _round_spent_motion(cursor["queue"], "ally", i):
			projected_allies[i]["motionTurns"] -= 1
	projected_combat["allies"] = projected_allies

	var next_round: Array = build_turn_queue(projected_combat)
	for i in range(next_round.size()):
		projected.append(_project_occurrence(next_round[i], cursor["round"] + 1, i))

	return projected


static func _entry_koed(combat: Dictionary, entry: Dictionary) -> bool:
	if entry["type"] == "player":
		return combat.get("playerKoed", false)
	var roster: Array = combat["allies"] if entry["type"] == "ally" else combat["enemies"]
	var idx: int = entry["index"]
	return idx < 0 or idx >= roster.size() or roster[idx]["koed"]


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
# band. "stats" is the player's effective hpMax/attack range/speed now;
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
	var stats := {
		"hpMax": player["hpMax"],
		"attackMin": attack["min"],
		"attackMax": attack["max"],
		"speed": GameData.COMBAT_SPEED_BY_LEVEL[level],
	}
	var atk_gain: int = atk[next] - atk[level]
	var next_stats := {
		"hpMax": stats["hpMax"] + hp[next] - hp[level],
		"attackMin": stats["attackMin"] + atk_gain,
		"attackMax": stats["attackMax"] + atk_gain,
		"speed": GameData.COMBAT_SPEED_BY_LEVEL[next],
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
	var blocked: String = selection_block_reason("attack")
	if not blocked.is_empty():
		return { "ok": false, "reason": blocked }

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
	_stamp_hp_after(combat, beat)
	beats.append(beat)
	# Mirrors every threaded beat onto a rolling accumulator combat_rewind()
	# hands back (reversed) for replay, cleared only when
	# _restore_from_snapshot() consumes it -- purely cosmetic (GameState is
	# already correctly restored by then).
	combat["beatsSinceSnapshot"].append(beat)


# A damaging beat carries its target's hp right after the hit
# ("hpAfter"), so playback drives the bar and KO per beat, not from the
# fully-resolved state.
static func _stamp_hp_after(combat: Dictionary, beat: Dictionary) -> void:
	if int(beat.get("dmg", 0)) <= 0:
		return
	var target_type: String = beat.get("targetType", "")
	var index: int = int(beat.get("targetIndex", -1))
	var target: Dictionary = {}
	if target_type == "player":
		target = GameState.state["player"]
	elif target_type == "ally" and index >= 0 and index < combat["allies"].size():
		target = combat["allies"][index]
	elif target_type == "enemy" and index >= 0 and index < combat["enemies"].size():
		target = combat["enemies"][index]
	if not target.is_empty():
		beat["hpAfter"] = int(target["hp"])


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
	var attack_extra: Dictionary = { "actorType": "player", "targetType": "enemy", "targetIndex": target_index }
	var shield_note := _hit_enemy(enemy, Rng.randi_range(atk["min"], atk["max"]), attack_extra)
	var frozen_note: String = " (enemy frozen)" if combat["frozenTurns"] > 0 else ""
	if motion_boosted:
		attack_extra["motionBoosted"] = true
	_log(combat, beats, "You attack — %d damage%s%s. Enemy: %d/%d HP." % [attack_extra["dmg"], shield_note, frozen_note, enemy["hp"], enemy["hpMax"]], BEAT_PLAYER_ATTACK, attack_extra)
	_maybe_win_from_direct_damage(combat, enemy, beats)


# One atomic ally turn: Dial cast, else an equipped item (guard kit pool or a
# recruit's own slots), else attack the player's focused enemy. Same evade/damage shape as the
# player's own attack. `ally_index` is only needed to stamp onto the beat.
static func _ally_turn(combat: Dictionary, ally: Dictionary, ally_index: int, beats: Variant = null) -> void:
	if ally.get("contactId", "") != "":
		Dial.combat_turn_tick(ally["contactId"])
	if _ally_try_cast(combat, ally, ally_index, beats):
		return
	if _ally_try_item(combat, ally, ally_index, beats):
		return

	var enemy: Dictionary = _focused_enemy(combat)
	var target_index: int = _enemy_action_index(combat)

	if Rng.chance(enemy.get("evadeChance", 0.0)):
		_log(combat, beats, "%s swings at %s — they dodge." % [ally["name"], enemy["name"]], BEAT_ENEMY_EVADE,
			{ "actorType": "ally", "actorIndex": ally_index, "targetType": "enemy", "targetIndex": target_index })
		return

	var ally_extra: Dictionary = { "actorType": "ally", "actorIndex": ally_index, "targetType": "enemy", "targetIndex": target_index }
	var shield_note := _hit_enemy(enemy, Rng.randi_range(ally["attackMin"], ally["attackMax"]), ally_extra)
	_log(combat, beats, "%s hits %s for %d%s. Enemy: %d/%d HP." % [ally["name"], enemy["name"], ally_extra["dmg"], shield_note, enemy["hp"], enemy["hpMax"]], BEAT_ALLY_ATTACK, ally_extra)
	_maybe_win_from_direct_damage(combat, enemy, beats)


# An ally holding a Dial (contacts.<id>.dial) casts a loaded Complication
# instead of attacking, on the same triggers/targets as a guard's items
# (_guard_try_item). A cast spends one Dial charge and awards Dial XP; power
# scales with the Dial's Movement and level (Dial.cast_complication()). Loaded
# Rewind is never cast by an ally.
static func _ally_try_cast(combat: Dictionary, ally: Dictionary, ally_index: int, beats: Variant) -> bool:
	var pool: Dictionary = _ally_dial_pool(ally)
	return _guard_try_item(combat, ally, ally_index, beats, pool)


# {} when the ally has no Dial, no charge, or nothing castable loaded; else an
# item-pool-shaped view of the loaded Complications plus the owner's id.
static func _ally_dial_pool(ally: Dictionary) -> Dictionary:
	var owner_id: String = ally.get("contactId", "")
	var dial: Variant = Dial.dial_of(owner_id) if owner_id != "" else null
	if dial == null or dial["currentCharge"] < 1:
		return {}
	var items := {}
	for entry in dial["loadedComplications"]:
		if entry["recipeKey"] == "rewind":
			continue
		var key: String = str(int(entry["tier"]))
		if not (items.get(entry["recipeKey"]) is Dictionary):
			items[entry["recipeKey"]] = {}
		items[entry["recipeKey"]][key] = int(items[entry["recipeKey"]].get(key, 0)) + 1
	return { "items": items, "used": {}, "dialOwner": owner_id } if not items.is_empty() else {}


# Guard-kit spec §Defend fight: a guard ally spends one unit of the shared
# combat.guardKit pool instead of attacking, on the first rule that applies:
# Healing Burst on the most-hurt friendly below ALLY_HEAL_THRESHOLD_FRACTION;
# Prophet's Breath when the player is that hurt with no evade up; Shield on
# the most-hurt of player and guard allies with no shield up; Black Hole
# (every enemy, as the player's) then Time Pearl when 2+ enemies stand and none are frozen;
# Blast on the lowest-hp enemy; Enhancement Powder on itself, once per guard
# per fight (extra queue entries from the next round). Failsafe fires from
# _enemy_attack_ally(), Rewind from _try_guard_rewind().
static func _ally_try_item(combat: Dictionary, ally: Dictionary, ally_index: int, beats: Variant) -> bool:
	var pool: Dictionary = _ally_item_pool(combat, ally)
	if not _guard_try_item(combat, ally, ally_index, beats, pool):
		return false
	_sync_ally_slots(ally, pool)
	return true


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


static func _guard_try_item(combat: Dictionary, ally: Dictionary, ally_index: int, beats: Variant, pool: Dictionary) -> bool:
	if pool.is_empty():
		return false
	var player: Dictionary = GameState.state["player"]
	var cast_extra: Dictionary = { "actorType": "ally", "actorIndex": ally_index }

	if _guard_pool_has(pool, "healingBurst"):
		var target: Dictionary = _most_hurt_friendly(combat)
		if not target.is_empty():
			var healed_entry: Dictionary = player if target["type"] == "player" else combat["allies"][target["index"]]
			var old_hp: int = healed_entry["hp"]
			healed_entry["hp"] = mini(healed_entry["hp"] + _spend_guard_item(pool, "healingBurst"), healed_entry["hpMax"])
			var extra: Dictionary = _friendly_target_extra(cast_extra, target)
			extra["effectKey"] = "healingBurst"
			# PROSE-REVIEW: guard Healing Burst line.
			_log(combat, beats, "%s cracks a Healing Burst over %s. +%d HP." % [ally["name"], _guard_target_word(combat, target, ally_index), healed_entry["hp"] - old_hp], BEAT_ALLY_CAST, extra)
			return true

	if _guard_pool_has(pool, "prophetsBreath") and player["hp"] > 0 and player["hp"] < player["hpMax"] * ALLY_HEAL_THRESHOLD_FRACTION and combat["evadeTurns"] <= 0:
		combat["evadeTurns"] = _spend_guard_item(pool, "prophetsBreath") + _pool_turn_bonus(pool)
		combat["evadeChance"] = 0.50
		var extra: Dictionary = cast_extra.duplicate()
		extra["effectKey"] = "prophetsBreath"
		# PROSE-REVIEW: guard Prophet's Breath line.
		_log(combat, beats, "%s holds a Prophet's Breath under your nose. You can see it coming." % ally["name"], BEAT_ALLY_CAST, extra)
		return true

	if _guard_pool_has(pool, "shield"):
		var target: Dictionary = _most_hurt_unshielded(combat)
		if not target.is_empty():
			var shielded: Dictionary = player if target["type"] == "player" else combat["allies"][target["index"]]
			shielded["shieldPool"] = _spend_guard_item(pool, "shield")
			var extra: Dictionary = _friendly_target_extra(cast_extra, target)
			extra["effectKey"] = "shield"
			# PROSE-REVIEW: guard Shield line.
			_log(combat, beats, "%s throws a shield over %s. %d absorption." % [ally["name"], _guard_target_word(combat, target, ally_index), shielded["shieldPool"]], BEAT_ALLY_CAST, extra)
			return true

	if combat["frozenTurns"] == 0 and _alive_enemy_count(combat) >= 2:
		if _guard_pool_has(pool, "blackHole"):
			var power := _spend_guard_item(pool, "blackHole")
			var extra: Dictionary = cast_extra.duplicate()
			extra["effectKey"] = "blackHole"
			# PROSE-REVIEW: guard Black Hole line.
			_log(combat, beats, "%s drops a black hole." % ally["name"], BEAT_ALLY_CAST, extra)
			_apply_black_hole_aoe(combat, power, _pool_black_hole_freeze(pool, power), beats)
			return true
		if _guard_pool_has(pool, "timePearl"):
			var turns := _spend_guard_item(pool, "timePearl") + _pool_turn_bonus(pool)
			combat["frozenTurns"] += turns
			var extra: Dictionary = cast_extra.duplicate()
			extra["effectKey"] = "timePearl"
			# PROSE-REVIEW: guard Time Pearl line.
			_log(combat, beats, "%s throws a time pearl. Enemies frozen for %d %s." % [ally["name"], turns, "turn" if turns == 1 else "turns"], BEAT_ALLY_CAST, extra)
			return true

	if _guard_pool_has(pool, "blast"):
		var target_index := _lowest_hp_enemy(combat)
		if target_index != -1:
			var enemy: Dictionary = combat["enemies"][target_index]
			var extra: Dictionary = cast_extra.duplicate()
			extra.merge({ "targetType": "enemy", "targetIndex": target_index, "effectKey": "blast" })
			var shield_note := _hit_enemy(enemy, _spend_guard_item(pool, "blast"), extra)
			# PROSE-REVIEW: guard Blast line.
			_log(combat, beats, "%s lets off a blast at %s — %d damage%s. %s: %d/%d HP." % [ally["name"], enemy["name"], extra["dmg"], shield_note, enemy["name"], enemy["hp"], enemy["hpMax"]], BEAT_ALLY_CAST, extra)
			_maybe_win_from_direct_damage(combat, enemy, beats)
			return true

	if _guard_pool_has(pool, "enhancementPowder") and not ally.get("powderUsed", false):
		var power := _spend_guard_item(pool, "enhancementPowder")
		ally["powderUsed"] = true
		ally["motionPower"] = power
		ally["motionTurns"] = 2 if power >= 3 else 1
		var extra: Dictionary = cast_extra.duplicate()
		extra["effectKey"] = "enhancementPowder"
		# PROSE-REVIEW: guard Enhancement Powder line.
		_log(combat, beats, "%s rubs in some powder. They're moving faster." % ally["name"], BEAT_ALLY_CAST, extra)
		return true

	return false


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


# Extra turns a Dial's last cast adds to a timed effect (0 for item pools).
static func _pool_turn_bonus(pool: Dictionary) -> int:
	return int(pool.get("lastCast", {}).get("turnBonus", 0))


# Black Hole freeze turns: the player's formula for a Dial cast, the guard's for an item.
static func _pool_black_hole_freeze(pool: Dictionary, power: int) -> int:
	var cast: Dictionary = pool.get("lastCast", {})
	if cast.is_empty():
		return 1 + int(floor(float(power) / 8.0))
	return (1 + int(floor(float(cast["turnPower"]) / 8.0))) * int(cast["targets"]) + int(cast["turnBonus"])


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


# Lowest hp fraction among the player (if standing, no shield up) and living
# guard allies with shieldPool 0 -- {type, index} or {} when none qualify.
static func _most_hurt_unshielded(combat: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_fraction: float = INF
	var player: Dictionary = GameState.state["player"]
	if player["hp"] > 0 and int(player["shieldPool"]) <= 0:
		best_fraction = float(player["hp"]) / float(player["hpMax"])
		best = { "type": "player", "index": -1 }
	var allies: Array = combat["allies"]
	for i in range(allies.size()):
		if allies[i]["koed"] or not _uses_items(allies[i]) or int(allies[i].get("shieldPool", 0)) > 0:
			continue
		var fraction: float = float(allies[i]["hp"]) / float(allies[i]["hpMax"])
		if fraction < best_fraction:
			best_fraction = fraction
			best = { "type": "ally", "index": i }
	return best


# Guards and recruits (allies with loadout slots) take part in item rules.
static func _uses_items(ally: Dictionary) -> bool:
	return ally.get("guardAlly", false) or ally.has("slots")


# Index of the living enemy with the lowest hp, or -1 when none stand.
static func _lowest_hp_enemy(combat: Dictionary) -> int:
	var best := -1
	var enemies: Array = combat["enemies"]
	for i in range(enemies.size()):
		if enemies[i]["koed"]:
			continue
		if best == -1 or enemies[i]["hp"] < enemies[best]["hp"]:
			best = i
	return best


static func _friendly_target_extra(cast_extra: Dictionary, target: Dictionary) -> Dictionary:
	var extra: Dictionary = cast_extra.duplicate()
	extra["targetType"] = target["type"]
	if target["type"] == "ally":
		extra["targetIndex"] = target["index"]
	return extra


static func _guard_target_word(combat: Dictionary, target: Dictionary, ally_index: int) -> String:
	if target["type"] == "player":
		return "you"
	if target["index"] == ally_index:
		return "themselves"
	return combat["allies"][target["index"]]["name"]


# Lowest hp fraction among the player (if standing) and non-koed allies,
# below ALLY_HEAL_THRESHOLD_FRACTION -- {type, index} or {} when nobody is.
static func _most_hurt_friendly(combat: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_fraction: float = ALLY_HEAL_THRESHOLD_FRACTION
	var player: Dictionary = GameState.state["player"]
	if player["hp"] > 0:
		var fraction: float = float(player["hp"]) / float(player["hpMax"])
		if fraction < best_fraction:
			best_fraction = fraction
			best = { "type": "player", "index": -1 }
	var allies: Array = combat["allies"]
	for i in range(allies.size()):
		if allies[i]["koed"]:
			continue
		var fraction: float = float(allies[i]["hp"]) / float(allies[i]["hpMax"])
		if fraction < best_fraction:
			best_fraction = fraction
			best = { "type": "ally", "index": i }
	return best


static func _alive_enemy_count(combat: Dictionary) -> int:
	var count := 0
	for enemy in combat["enemies"]:
		if not enemy["koed"]:
			count += 1
	return count


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
	var candidates: Array = [] if combat.get("playerKoed", false) else [-1]
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
# enemy's own queue slot. A frozen turn is a logged no-op -- the entry is
# still walked, it just doesn't attack. Each point of frozenTurns costs
# every living enemy one turn: frozenSkipped holds who has already lost a
# turn this rotation, and the pool drops by 1 once every living enemy has
# (or once an enemy comes round again, if a peer was KO'd before its skip).
static func _enemy_turn(combat: Dictionary, enemy: Dictionary, enemy_index: int, beats: Variant = null) -> void:
	if is_ability_locked(enemy):
		enemy["ability"]["lockedTurns"] -= 1
		if enemy["ability"]["lockedTurns"] == 0:
			_log(combat, beats, "%s's ability is back online." % enemy["name"], BEAT_ABILITY_UNLOCKED,
				{ "actorType": "enemy", "actorIndex": enemy_index })

	if not combat.has("frozenSkipped"):
		combat["frozenSkipped"] = []
	var exempt: bool = enemy.get("freezeExempt", false)
	# Nobody left for the freeze to land on: it lapses.
	if exempt and combat["frozenTurns"] > 0 and _all_living_enemies_skipped(combat):
		combat["frozenTurns"] = 1
		_end_freeze_rotation(combat, enemy_index, beats)
	if combat["frozenTurns"] > 0 and not exempt and combat["frozenSkipped"].has(enemy_index):
		_end_freeze_rotation(combat, enemy_index, beats)
	if combat["frozenTurns"] > 0 and not exempt:
		combat["frozenSkipped"].append(enemy_index)
		_log(combat, beats, "%s is frozen — no turn." % enemy["name"], BEAT_ENEMY_FROZEN,
			{ "actorType": "enemy", "actorIndex": enemy_index })
		if _all_living_enemies_skipped(combat):
			_end_freeze_rotation(combat, enemy_index, beats)
		return

	if _enemy_status_turn(combat, enemy, enemy_index, beats):
		return
	if not _enemy_fury_attack(combat, enemy, enemy_index, beats) and not _enemy_try_item(combat, enemy, enemy_index, beats):
		_resolve_enemy_attack(combat, enemy, enemy_index, beats)
	_tick_anger(combat, enemy, enemy_index, beats)


# Multiplier on damage `enemy` deals (dealing) or takes under Panger/
# Pandemonium: buffed phase +pct deals / -pct takes, debuffed phase the
# reverse. Floored at 0 (a >100% reduction is full immunity, not healing).
static func _anger_factor(enemy: Dictionary, dealing: bool) -> float:
	var anger: Variant = enemy.get("anger")
	if not (anger is Dictionary):
		return 1.0
	var buffed: bool = int(anger["turns"]) > ANGER_PHASE_TURNS
	var sign: float = 1.0 if buffed == dealing else -1.0
	return maxf(0.0, 1.0 + sign * float(anger["pct"]) / 100.0)


static func _scale_dealt(enemy: Dictionary, dmg: int) -> int:
	return GameState.round_epsilon(float(dmg) * _anger_factor(enemy, true))


# Pandemonium: the enemy swings at a random other living enemy instead of
# its enemies. False (normal attack) when not furious or no ally stands.
static func _enemy_fury_attack(combat: Dictionary, enemy: Dictionary, enemy_index: int, beats: Variant) -> bool:
	var anger: Variant = enemy.get("anger")
	if not (anger is Dictionary) or not bool(anger["fury"]):
		return false
	var candidates: Array = []
	for i in range(combat["enemies"].size()):
		var other: Dictionary = combat["enemies"][i]
		if i != enemy_index and not other["koed"]:
			candidates.append(i)
	if candidates.is_empty():
		return false
	var target_index: int = candidates[Rng.randi_range(0, candidates.size() - 1)]
	var target: Dictionary = combat["enemies"][target_index]
	var atk := get_enemy_attack_range(enemy)
	var extra: Dictionary = { "actorType": "enemy", "actorIndex": enemy_index, "targetType": "enemy", "targetIndex": target_index }
	var shield_note := _hit_enemy(target, _scale_dealt(enemy, Rng.randi_range(atk["min"], atk["max"])), extra)
	# PROSE-REVIEW: fury attack line.
	_log(combat, beats, "%s turns on %s — %d damage%s. %s: %d/%d HP." % [enemy["name"], target["name"], extra["dmg"], shield_note, target["name"], target["hp"], target["hpMax"]], BEAT_ENEMY_FURY_ATTACK, extra)
	_maybe_win_from_direct_damage(combat, target, beats)
	return true


# One of the enemy's own turns spent under Panger/Pandemonium.
static func _tick_anger(combat: Dictionary, enemy: Dictionary, enemy_index: int, beats: Variant) -> void:
	var anger: Variant = enemy.get("anger")
	if not (anger is Dictionary):
		return
	anger["turns"] = int(anger["turns"]) - 1
	if anger["turns"] <= 0:
		enemy.erase("anger")
		# PROSE-REVIEW: anger wears-off line.
		_log(combat, beats, "%s comes down, spent." % enemy["name"], BEAT_ENEMY_ANGER_END, { "actorType": "enemy", "actorIndex": enemy_index })


# Panic / Pan's Rapture on this enemy's own turn. True when the turn is
# spent: Rapture just idles; Panic rolls cower vs. run off, and running off
# is a defeat (hp 0 -> koed, win check, XP) the same as a kill.
static func _enemy_status_turn(combat: Dictionary, enemy: Dictionary, enemy_index: int, beats: Variant) -> bool:
	var actor: Dictionary = { "actorType": "enemy", "actorIndex": enemy_index }
	if int(enemy.get("raptureTurns", 0)) > 0:
		enemy["raptureTurns"] -= 1
		# PROSE-REVIEW: rapture idle line.
		_log(combat, beats, "%s is grinning at nothing. No attack." % enemy["name"], BEAT_ENEMY_RAPTURE, actor)
		return true
	if int(enemy.get("panicTurns", 0)) > 0:
		enemy["panicTurns"] -= 1
		if Rng.chance(PANIC_FLEE_CHANCE):
			# PROSE-REVIEW: panic flee line.
			_log(combat, beats, "%s bolts. Gone." % enemy["name"], BEAT_ENEMY_FLEE, actor)
			enemy["hp"] = 0
			_maybe_win_from_direct_damage(combat, enemy, beats)
		else:
			# PROSE-REVIEW: panic cower line.
			_log(combat, beats, "%s cowers, hands over their head." % enemy["name"], BEAT_ENEMY_COWER, actor)
		return true
	return false


# Raider kit heals, tried in this order.
const RAIDER_HEAL_ITEMS: Array[String] = ["healingBurst", "healingSalve"]


# A defended raid's raiders share combat.raiderKit (FactionSim.raider_kit()).
# On an enemy's turn, before attacking, the first of these that applies
# spends one kit item: a heal on the most-hurt living enemy below
# ALLY_HEAL_THRESHOLD_FRACTION; a Shield on itself while it has none up; a
# Blast on its attack target in place of the attack (no evade roll). Power is
# the recipe's effectPower at the spent unit's tier (highest tier first, as
# _spend_guard_item()). Spent units tally in raiderKit.used and leave the
# faction's stock at exit_combat()'s settlement.
static func _enemy_try_item(combat: Dictionary, enemy: Dictionary, enemy_index: int, beats: Variant) -> bool:
	var kit: Dictionary = combat.get("raiderKit", {})
	if kit.is_empty():
		return false

	for recipe_key in RAIDER_HEAL_ITEMS:
		if not _guard_pool_has(kit, recipe_key):
			continue
		var hurt_index := _most_hurt_enemy(combat)
		if hurt_index == -1:
			break
		var healed: Dictionary = combat["enemies"][hurt_index]
		var old_hp: int = healed["hp"]
		healed["hp"] = mini(healed["hpMax"], old_hp + _spend_guard_item(kit, recipe_key))
		var who: String = "themselves" if hurt_index == enemy_index else healed["name"]
		# PROSE-REVIEW: raider heal line.
		_log(combat, beats, "%s slaps a %s on %s. +%d HP." % [enemy["name"], GameData.RECIPES[recipe_key]["name"], who, healed["hp"] - old_hp], BEAT_ENEMY_ITEM,
			{ "actorType": "enemy", "actorIndex": enemy_index, "targetType": "enemy", "targetIndex": hurt_index, "effectKey": recipe_key })
		return true

	if _guard_pool_has(kit, "shield") and int(enemy.get("shieldPool", 0)) <= 0:
		enemy["shieldPool"] = _spend_guard_item(kit, "shield")
		# PROSE-REVIEW: raider shield line.
		_log(combat, beats, "%s gets a shield up. %d absorption." % [enemy["name"], enemy["shieldPool"]], BEAT_ENEMY_ITEM,
			{ "actorType": "enemy", "actorIndex": enemy_index, "targetType": "enemy", "targetIndex": enemy_index, "effectKey": "shield" })
		return true

	if _guard_pool_has(kit, "blast"):
		var power := _spend_guard_item(kit, "blast")
		var target_index: int = _pick_enemy_target(combat)
		if target_index == -1:
			_enemy_attack_player(combat, enemy, enemy_index, beats, power)
		else:
			_enemy_attack_ally(combat, enemy, combat["allies"][target_index], target_index, enemy_index, beats, power)
		return true

	return false


# Index of the living enemy with the lowest hp fraction below
# ALLY_HEAL_THRESHOLD_FRACTION, or -1 when none is that hurt.
static func _most_hurt_enemy(combat: Dictionary) -> int:
	var best := -1
	var best_fraction: float = ALLY_HEAL_THRESHOLD_FRACTION
	var enemies: Array = combat["enemies"]
	for i in range(enemies.size()):
		if enemies[i]["koed"]:
			continue
		var fraction: float = float(enemies[i]["hp"]) / float(enemies[i]["hpMax"])
		if fraction < best_fraction:
			best_fraction = fraction
			best = i
	return best


static func _end_freeze_rotation(combat: Dictionary, enemy_index: int, beats: Variant) -> void:
	combat["frozenTurns"] -= 1
	combat["frozenSkipped"] = []
	if combat["frozenTurns"] == 0:
		for enemy in combat["enemies"]:
			enemy.erase("freezeExempt")
		_log(combat, beats, "The time effect wears off. They're coming back round.", BEAT_FROZEN_WEARS_OFF,
			{ "actorType": "enemy", "actorIndex": enemy_index })


static func _all_living_enemies_skipped(combat: Dictionary) -> bool:
	for i in range(combat["enemies"].size()):
		var enemy: Dictionary = combat["enemies"][i]
		if not enemy["koed"] and not enemy.get("freezeExempt", false) and not combat["frozenSkipped"].has(i):
			return false
	return true


# blast_power > 0 is a raider kit Blast (_enemy_try_item()): fixed damage,
# no evade roll, still absorbed by the shield.
static func _enemy_attack_player(combat: Dictionary, enemy: Dictionary, enemy_index: int = 0, beats: Variant = null, blast_power: int = 0) -> void:
	if blast_power <= 0 and combat["evadeTurns"] > 0:
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

	var dmg: int = blast_power
	if dmg <= 0:
		var atk := get_enemy_attack_range(enemy)
		dmg = _scale_dealt(enemy, Rng.randi_range(atk["min"], atk["max"]))
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
	if blast_power > 0:
		beat_extra["effectKey"] = "blast"
		# PROSE-REVIEW: raider blast line.
		_log(combat, beats, "%s lets off a blast at you — %d damage%s. You: %d/%d HP." % [enemy["name"], dmg, shield_note, player["hp"], player["hpMax"]], BEAT_ENEMY_ITEM, beat_extra)
	else:
		_log(combat, beats, "%s hits you for %d%s. You: %d/%d HP." % [enemy["name"], dmg, shield_note, player["hp"], player["hpMax"]], BEAT_ENEMY_ATTACK, beat_extra)
	if player["hp"] <= 0:
		# A failsafe/rewind trigger rewrites combat.log wholesale, so this
		# path deliberately stays un-beaten -- rewind-as-animation is its
		# own, separate mechanism, not this linear beat queue.
		if _try_failsafe(combat, player):
			return
		if _try_guard_rewind(combat, player):
			return
		_player_ko(combat, player, beats)


# R§3.7a "Player KO": the player leaves the fight (hp stays 0 while it runs).
# The next queued ally takes the freed place; with no friendly left standing
# the fight is lost, otherwise the allies fight on until it resolves.
static func _player_ko(combat: Dictionary, player: Dictionary, beats: Variant) -> void:
	combat["playerKoed"] = true
	# PROSE-REVIEW: player KO line.
	_log(combat, beats, "You go down. It's up to them now.", BEAT_PLAYER_KO, { "targetType": "player" })
	var ally_queue: Array = combat.get("allyQueue", [])
	if not ally_queue.is_empty():
		var entrant: Dictionary = ally_queue.pop_front()
		combat["allies"].append(entrant)
		# PROSE-REVIEW: reinforcement entry line.
		_log(combat, beats, "%s steps in." % entrant["name"], BEAT_REINFORCEMENT_ENTER,
			{ "targetType": "ally", "targetIndex": combat["allies"].size() - 1 })
	clamp_selection(combat)
	_lose_if_no_friendlies(combat, beats)


# Only a KO'd player can lose here -- a standing player is never "out of friendlies".
static func _lose_if_no_friendlies(combat: Dictionary, beats: Variant) -> void:
	if not combat.get("playerKoed", false) or combat["outcome"] != null:
		return
	for ally in combat["allies"]:
		if not ally["koed"]:
			return
	if not combat.get("allyQueue", []).is_empty():
		return
	combat["outcome"] = "loss"
	_log(combat, beats, "You're done. You come round somewhere unpleasant.", BEAT_COMBAT_LOSS, {})
	_settle_player_ko_hp()


# After an ally-won victory or a loss the player wakes at PLAYER_KO_HP_FRACTION of hpMax.
static func _settle_player_ko_hp() -> void:
	var player: Dictionary = GameState.state["player"]
	player["hp"] = maxi(1, GameState.round_epsilon(player["hpMax"] * PLAYER_KO_HP_FRACTION))


# No evade. A guard kit Shield (ally.shieldPool) absorbs 1:1 before hp, and a
# guard that would be KO'd spends a pool Failsafe to stay up on 1 hp. KO sets
# the `koed` flag Combat's loops already check, and starts the contact's
# persistent cooldown via Contacts.knock_out().
# blast_power > 0: a raider kit Blast, as in _enemy_attack_player().
static func _enemy_attack_ally(combat: Dictionary, enemy: Dictionary, ally: Dictionary, ally_index: int, enemy_index: int = 0, beats: Variant = null, blast_power: int = 0) -> void:
	var dmg: int = blast_power
	if dmg <= 0:
		var atk := get_enemy_attack_range(enemy)
		dmg = _scale_dealt(enemy, Rng.randi_range(atk["min"], atk["max"]))
	var shield_note := ""
	var absorbed: int = mini(dmg, int(ally.get("shieldPool", 0)))
	if absorbed > 0:
		ally["shieldPool"] -= absorbed
		dmg -= absorbed
		shield_note = " (%d absorbed by shield)" % absorbed
	ally["hp"] = maxi(0, ally["hp"] - dmg)
	var beat_extra: Dictionary = { "actorType": "enemy", "actorIndex": enemy_index, "targetType": "ally", "targetIndex": ally_index, "dmg": dmg }
	if absorbed > 0:
		beat_extra["shieldAbsorbed"] = absorbed
	if blast_power > 0:
		beat_extra["effectKey"] = "blast"
		# PROSE-REVIEW: raider blast line.
		_log(combat, beats, "%s lets off a blast at %s — %d damage%s. %s: %d/%d HP." % [enemy["name"], ally["name"], dmg, shield_note, ally["name"], ally["hp"], ally["hpMax"]], BEAT_ENEMY_ITEM, beat_extra)
	else:
		_log(combat, beats, "%s hits %s for %d%s. %s: %d/%d HP." % [enemy["name"], ally["name"], dmg, shield_note, ally["name"], ally["hp"], ally["hpMax"]], BEAT_ENEMY_ATTACK, beat_extra)
	var item_pool: Dictionary = _ally_item_pool(combat, ally) if ally["hp"] <= 0 else {}
	if not item_pool.is_empty() and _guard_pool_has(item_pool, "failsafe"):
		_spend_guard_item(item_pool, "failsafe")
		_sync_ally_slots(ally, item_pool)
		ally["hp"] = 1
		# PROSE-REVIEW: guard Failsafe line.
		_log(combat, beats, "%s's failsafe fires. Back up on 1 HP." % ally["name"], BEAT_ALLY_CAST,
			{ "actorType": "ally", "actorIndex": ally_index, "effectKey": "failsafe" })
	if ally["hp"] <= 0:
		ally["koed"] = true
		_log(combat, beats, "%s is knocked out of the fight." % ally["name"], BEAT_ALLY_KO,
			{ "targetType": "ally", "targetIndex": ally_index })
		if ally.has("contactId"):
			Contacts.knock_out(ally["contactId"], GameState.state["world"]["day"])
		_admit_reinforcement(combat, "allies", ally_index, beats)
		clamp_selection(combat)
		_lose_if_no_friendlies(combat, beats)


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
	var cursor: Dictionary = combat["turnCursor"]

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

	# A failsafe fired by the parting shot already restored this decision
	# point; concluding it would spend the restored turn.
	if is_same(combat["turnCursor"], cursor):
		conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "outcome": combat["outcome"], "beats": beats }


static func use_time_pearl(slot: int = -1) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	var blocked: String = selection_block_reason("timePearl")
	if not blocked.is_empty():
		return { "ok": false, "reason": blocked }
	var slot_index: int = Loadout.find_slot("timePearl", slot)
	if slot_index < 0:
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

	var power = Loadout.consume(slot_index)
	combat["frozenTurns"] += power
	var turn_word: String = "turn" if power == 1 else "turns"
	_log(combat, beats, "You throw a time pearl. The air goes thick. Everything slows. (%d %s)" % [power, turn_word], BEAT_USE_TIME_PEARL, { "effectKey": "timePearl" })

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


static func use_enhancement_powder(slot: int = -1) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	var blocked: String = selection_block_reason("enhancementPowder")
	if not blocked.is_empty():
		return { "ok": false, "reason": blocked }
	var slot_index: int = Loadout.find_slot("enhancementPowder", slot)
	if slot_index < 0:
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

	var power = Loadout.consume(slot_index)
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
static func use_blast(slot: int = -1) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	var slot_index: int = Loadout.find_slot("blast", slot)
	if slot_index < 0:
		return { "ok": false, "reason": "No blast." }
	var multi: bool = Loadout.slot_is_multi(slot_index)
	var blocked: String = "" if multi else selection_block_reason("blast")
	if not blocked.is_empty():
		return { "ok": false, "reason": blocked }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	var power = Loadout.consume(slot_index)
	combat["blastFleeBoost"] = true
	# A multi-target blast hits every living enemy at full power.
	var target_indices: Array = []
	if multi:
		for i in range(combat["enemies"].size()):
			if not combat["enemies"][i]["koed"]:
				target_indices.append(i)
	else:
		target_indices.append(_enemy_action_index(combat))
	for target_index in target_indices:
		var enemy: Dictionary = combat["enemies"][target_index]
		var blast_extra: Dictionary = { "targetType": "enemy", "targetIndex": target_index, "effectKey": "blast" }
		var shield_note := _hit_enemy(enemy, int(power), blast_extra)
		_log(combat, beats, "You let off a blast — %d damage%s. Enemy: %d/%d HP." % [blast_extra["dmg"], shield_note, enemy["hp"], enemy["hpMax"]], BEAT_USE_BLAST, blast_extra)

		if Rng.chance(BLAST_DISARM_CHANCE):
			disarm_enemy(enemy, BLAST_DISARM_TURNS)
			_log(combat, beats, "The shove knocks their weapon loose.", BEAT_USE_DISARM, { "targetType": "enemy", "targetIndex": target_index })

		_maybe_win_from_direct_damage(combat, enemy, beats)

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


static func use_panic(slot: int = -1) -> Dictionary:
	return _use_pan_status("panic", "panicTurns", "No panic.", "You press the panic into their hands.", BEAT_USE_PANIC, slot)


static func use_pans_rapture(slot: int = -1) -> Dictionary:
	return _use_pan_status("pansRapture", "raptureTurns", "No rapture.", "You hand over the rapture. They take it gladly.", BEAT_USE_RAPTURE, slot)


static func _has_pan_status(enemy: Dictionary) -> bool:
	return int(enemy.get("panicTurns", 0)) > 0 or int(enemy.get("raptureTurns", 0)) > 0 or enemy.get("anger") is Dictionary


# The enemy.anger status a Panger / Pandemonium of `tier` sets.
static func _anger_status(tier: int, fury: bool) -> Dictionary:
	return { "turns": ANGER_PHASE_TURNS * 2, "pct": ANGER_PCT_PER_TIER * tier, "fury": fury }


static func use_panger(slot: int = -1) -> Dictionary:
	return _use_anger("panger", false, "No panger.", "You grind the anger in.", BEAT_USE_PANGER, slot)


static func use_pandemonium(slot: int = -1) -> Dictionary:
	return _use_anger("pandemonium", true, "No pandemonium.", "You bring the fury to the boil.", BEAT_USE_PANDEMONIUM, slot)


# Single target: sets enemy.anger at the unit's tier. A target already under
# any Pan status refuses another.
# PROSE-REVIEW: Panger / Pandemonium use lines and refusal reasons.
static func _use_anger(recipe_key: String, fury: bool, empty_reason: String, line: String, beat_kind: String, slot: int) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var blocked: String = selection_block_reason(recipe_key)
	if not blocked.is_empty():
		return { "ok": false, "reason": blocked }
	var slot_index: int = Loadout.find_slot(recipe_key, slot)
	if slot_index < 0:
		return { "ok": false, "reason": empty_reason }
	var enemy: Dictionary = _focused_enemy(combat)
	if _has_pan_status(enemy):
		return { "ok": false, "reason": "Already out of it." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	var tier: int = int(GameState.state["player"]["loadout"]["slots"][slot_index]["tier"])
	Loadout.consume(slot_index)
	enemy["anger"] = _anger_status(tier, fury)
	_log(combat, beats, "%s (%d%%)" % [line, enemy["anger"]["pct"]], beat_kind,
		{ "targetType": "enemy", "targetIndex": _enemy_action_index(combat), "effectKey": recipe_key })

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# Single-target, effectPower-at-tier turns on the selected enemy, counted
# down on that enemy's own turns (_enemy_status_turn()). A target already
# under either status refuses a second.
# PROSE-REVIEW: Panic / Pan's Rapture use lines and refusal reasons.
static func _use_pan_status(recipe_key: String, status_key: String, empty_reason: String, line: String, beat_kind: String, slot: int) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var blocked: String = selection_block_reason(recipe_key)
	if not blocked.is_empty():
		return { "ok": false, "reason": blocked }
	var slot_index: int = Loadout.find_slot(recipe_key, slot)
	if slot_index < 0:
		return { "ok": false, "reason": empty_reason }
	var enemy: Dictionary = _focused_enemy(combat)
	if _has_pan_status(enemy):
		return { "ok": false, "reason": "Already out of it." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	var turns: int = int(Loadout.consume(slot_index))
	enemy[status_key] = turns
	var target_index: int = _enemy_action_index(combat)
	_log(combat, beats, "%s (%d turn%s)" % [line, turns, "" if turns == 1 else "s"], beat_kind,
		{ "targetType": "enemy", "targetIndex": target_index, "effectKey": recipe_key })

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# Sets player.shieldPool, drained 1:1 by enemy_attack() above. Blocked
# while a pool is still active, same guard shape as use_time_pearl()'s.
static func use_shield(slot: int = -1) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	var slot_index: int = Loadout.find_slot("shield", slot)
	if slot_index < 0:
		return { "ok": false, "reason": "No shield." }
	var multi: bool = Loadout.slot_is_multi(slot_index)
	var blocked: String = "" if multi else selection_block_reason("shield")
	if not blocked.is_empty():
		return { "ok": false, "reason": blocked }
	if player["shieldPool"] > 0:
		combat["log"].append("Shield's already up. Save it.")
		EventBus.state_changed.emit()
		return { "ok": false, "reason": "Shield already active." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	var power = Loadout.consume(slot_index)
	player["shieldPool"] = power
	if multi:
		for ally in combat["allies"]:
			if not ally["koed"]:
				ally["shieldPool"] = maxi(int(ally.get("shieldPool", 0)), int(power))
	_log(combat, beats, "A shimmer folds around you. Shield up — %d absorption." % power, BEAT_USE_SHIELD, { "effectKey": "shield" })

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# Black Hole is the one AoE effect (R§3.7a): hits every non-koed enemy
# independently at full, un-diluted power. frozenTurns already costs every
# living enemy a turn per point, so the freeze is added once, not per hit.
# Each hit gets its own log line + beat, so the juice layer
# can play an effect per enemy in the fan, sequentially.
static func _apply_black_hole_aoe(combat: Dictionary, dmg: int, freeze_turns: int, beats: Variant = null) -> void:
	combat["frozenTurns"] += freeze_turns
	for i in range(combat["enemies"].size()):
		var enemy: Dictionary = combat["enemies"][i]
		if enemy["koed"]:
			continue
		var hit_extra: Dictionary = { "targetType": "enemy", "targetIndex": i, "effectKey": "blackHole" }
		var shield_note := _hit_enemy(enemy, dmg, hit_extra)
		_log(combat, beats, "%s takes %d damage%s, frozen %d turn(s). %s: %d/%d HP." % [enemy["name"], hit_extra["dmg"], shield_note, freeze_turns, enemy["name"], enemy["hp"], enemy["hpMax"]], BEAT_COMPLICATION_BLACK_HOLE_HIT, hit_extra)
		_maybe_win_from_direct_damage(combat, enemy, beats)


# Immediate damage plus frozenTurns, always additive regardless of source
# (stacks with Time Pearl or a prior Black Hole) -- no reuse guard. Turn
# count derives from effectPower, not a separate recipe schema field.
static func use_black_hole(slot: int = -1) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	var slot_index: int = Loadout.find_slot("blackHole", slot)
	if slot_index < 0:
		return { "ok": false, "reason": "No black hole." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	var power = Loadout.consume(slot_index)
	var freeze_turns: int = 1 + int(floor(float(power) / 8.0))
	# Per-enemy hit beats (via _apply_black_hole_aoe(), the same shared helper
	# cast_complication() uses) replace a single combined summary line.
	_log(combat, beats, "You drop a black hole.", BEAT_USE_BLACK_HOLE_ANNOUNCE, {})
	_apply_black_hole_aoe(combat, power, freeze_turns, beats)

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# Every hit on an enemy lands here: its shieldPool (a raider kit Shield, see
# _enemy_try_item()) absorbs 1:1 before hp, as the player's does. Stamps the
# hp damage onto the beat's `dmg` (plus `shieldAbsorbed` when the shield
# took some) and returns the log line's shield note.
static func _hit_enemy(enemy: Dictionary, dmg: int, extra: Dictionary) -> String:
	dmg = GameState.round_epsilon(float(dmg) * _anger_factor(enemy, false))
	var absorbed: int = mini(dmg, int(enemy.get("shieldPool", 0)))
	var note := ""
	if absorbed > 0:
		enemy["shieldPool"] -= absorbed
		extra["shieldAbsorbed"] = absorbed
		note = " (%d absorbed by shield)" % absorbed
	extra["dmg"] = dmg - absorbed
	enemy["hp"] = maxi(0, enemy["hp"] - extra["dmg"])
	return note


# Shared by player_attack/use_blast/use_black_hole -- all three can deal a
# lethal hit and need the same koed-flagging/win-check afterward. hp
# hitting 0 flags that entry koed and auto-clamps selection off a dead
# target; the fight ends only once every entry in combat.enemies is koed.
static func _maybe_win_from_direct_damage(combat: Dictionary, enemy: Dictionary, beats: Variant = null) -> void:
	if enemy["hp"] > 0:
		return
	enemy["koed"] = true
	_admit_reinforcement(combat, "enemies", _roster_index(combat["enemies"], enemy), beats)
	clamp_selection(combat)
	if not _all_enemies_koed(combat["enemies"]) or not combat.get("enemyQueue", []).is_empty():
		return
	combat["outcome"] = "win"
	var line: String = "They go down. Vein is yours."
	if NON_LETHAL_MUGGING_CONTEXTS.has(combat["context"]):
		line = "They leg it. Good call on their part."
	elif HOME_CONTEXTS.has(combat["context"]):
		line = "They're gone."
	_log(combat, beats, line, BEAT_COMBAT_WIN, {})
	if combat.get("playerKoed", false):
		_settle_player_ko_hp()
	_dispatch_on_win()


# A KO'd active fighter's place goes to the next same-side reinforcement,
# in the same index so selection and the turn queue point at the entrant.
# `roster_key` is "enemies" or "allies". An enemy entering mid-freeze is
# exempt from it until the freeze ends (_enemy_turn()); a fighter queued when
# an AoE lands is never in its target list. No-op with an empty queue.
static func _admit_reinforcement(combat: Dictionary, roster_key: String, index: int, beats: Variant = null) -> void:
	var queue: Array = combat.get("enemyQueue" if roster_key == "enemies" else "allyQueue", [])
	if queue.is_empty() or index < 0:
		return
	var entrant: Dictionary = queue.pop_front()
	if roster_key == "enemies" and combat["frozenTurns"] > 0:
		entrant["freezeExempt"] = true
	combat[roster_key][index] = entrant
	_substitute_turn_entries(combat, "enemy" if roster_key == "enemies" else "ally", index, entrant)
	# PROSE-REVIEW: reinforcement entry line.
	_log(combat, beats, "%s steps in." % entrant["name"], BEAT_REINFORCEMENT_ENTER,
		{ "targetType": "enemy" if roster_key == "enemies" else "ally", "targetIndex": index })


# R§3.7a "Reinforcements": swaps the KO'd fighter's unresolved queue entries
# (extras included) for one entrant occurrence placed by the entrant's own
# speed with build_turn_queue()'s tie-break (player > allies > enemies, then
# index). A KO'd fighter that had already acted leaves nothing to swap -- the
# entrant first acts in the next round's rebuilt queue. Entries before the
# first unresolved one are never touched; the player's parked entry counts as
# resolved while a player command is mid-flight (`inTurn` marks an engine-run
# ally/enemy turn, whose entry the cursor has already stepped past).
static func _substitute_turn_entries(combat: Dictionary, type: String, index: int, entrant: Dictionary) -> void:
	var cursor: Dictionary = combat["turnCursor"]
	var queue: Array = cursor["queue"]
	var start: int = cursor["index"]
	if not cursor.get("inTurn", false) and start < queue.size() and queue[start]["type"] == "player":
		start += 1
	var kept: Array = queue.slice(0, start)
	var rest: Array = []
	var had_base := false
	for i in range(start, queue.size()):
		var entry: Dictionary = queue[i]
		if entry["type"] == type and entry.get("index", -1) == index:
			had_base = had_base or not entry.get("extra", false)
			continue
		rest.append(entry)
	if had_base:
		var speed: int = entrant.get("speed", 0)
		var rank: int = 1 if type == "ally" else 2
		var pos: int = rest.size()
		for i in range(rest.size()):
			var other: Dictionary = rest[i]
			var other_rank: int = 0 if other["type"] == "player" else (1 if other["type"] == "ally" else 2)
			if other["speed"] < speed or (other["speed"] == speed and (other_rank > rank or (other_rank == rank and other.get("index", -1) > index))):
				pos = i
				break
		rest.insert(pos, { "type": type, "index": index, "speed": speed })
	cursor["queue"] = kept + rest


# Index of `fighter` by identity (two KO'd fighters can compare equal by value).
static func _roster_index(roster: Array, fighter: Dictionary) -> int:
	for i in range(roster.size()):
		if is_same(roster[i], fighter):
			return i
	return -1


static func _all_enemies_koed(enemies: Array) -> bool:
	for enemy in enemies:
		if not enemy["koed"]:
			return false
	return true


# Keeps combat.selection pointed at a living entry after a kill/KO -- a
# no-op when the currently-selected entry is still alive. R§2's KO-clamp
# rule: same-type first (next living ally/enemy in array order), else
# fall back to the next living enemy; never fires for type "player".
static func clamp_selection(combat: Dictionary) -> void:
	var selection: Dictionary = combat["selection"]
	if selection["type"] == "player":
		return
	var roster: Array = combat["allies"] if selection["type"] == "ally" else combat["enemies"]
	var idx: int = selection["index"]
	if idx >= 0 and idx < roster.size() and not roster[idx]["koed"]:
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
static func use_prophets_breath(slot: int = -1) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	var blocked: String = selection_block_reason("prophetsBreath")
	if not blocked.is_empty():
		return { "ok": false, "reason": blocked }
	var slot_index: int = Loadout.find_slot("prophetsBreath", slot)
	if slot_index < 0:
		return { "ok": false, "reason": "No prophet's breath." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	var power = Loadout.consume(slot_index)
	combat["evadeTurns"] = power
	combat["evadeChance"] = 0.50
	combat["log"].append("You take a lungful. For a few seconds, you can see it coming.")

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# Wormhole's combat half: guarantees flee()'s escape outright rather than
# boosting its roll (contrast Blast's blastFleeBoost, which still rolls).
# The map-travel half lives in Travel.travel_via_wormhole().
static func use_wormhole(slot: int = -1) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var slot_index: int = Loadout.find_slot("wormhole", slot)
	if slot_index < 0:
		return { "ok": false, "reason": "No wormhole." }

	var beats: Array = []
	if not prime_decision_point(combat, beats):
		EventBus.state_changed.emit()
		return { "ok": true, "beats": beats }
	push_combat_snapshot()

	Loadout.consume(slot_index)
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
	var multi: bool = bool(loaded[index].get("multi", false))
	var blocked: String = "" if multi else selection_block_reason(recipe_key)
	if not blocked.is_empty():
		return { "ok": false, "reason": blocked }

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

	if PAN_STATUS_RECIPES.has(recipe_key) and _has_pan_status(_focused_enemy(combat)):
		return { "ok": false, "reason": "Already out of it." }

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
			var total: int = int(power) * targets + int(cast["turnBonus"])
			combat["frozenTurns"] += total
			var turn_word: String = "turn" if total == 1 else "turns"
			_log(combat, beats, "You trigger %s. Enemy frozen for %d %s." % [recipe["name"], total, turn_word], BEAT_COMPLICATION_TIME_PEARL, { "effectKey": "timePearl" })
		"enhancementPowder":
			combat["motionPower"] = power
			combat["motionTurns"] = 2 if power >= 3 else 1
			_log(combat, beats, "You trigger %s. Movement accelerated." % recipe["name"], BEAT_COMPLICATION_MOTION, {})
		"blast":
			var dmg: int = int(power) * targets
			combat["blastFleeBoost"] = true
			var target_indices: Array = []
			if multi:
				for i in range(combat["enemies"].size()):
					if not combat["enemies"][i]["koed"]:
						target_indices.append(i)
			else:
				target_indices.append(_enemy_action_index(combat))
			for target_index in target_indices:
				var target: Dictionary = combat["enemies"][target_index]
				var blast_extra: Dictionary = { "targetType": "enemy", "targetIndex": target_index, "effectKey": "blast" }
				var shield_note := _hit_enemy(target, dmg, blast_extra)
				_log(combat, beats, "You trigger %s — %d damage%s. Enemy: %d/%d HP." % [recipe["name"], blast_extra["dmg"], shield_note, target["hp"], target["hpMax"]], BEAT_COMPLICATION_BLAST, blast_extra)
				if Rng.chance(BLAST_DISARM_CHANCE):
					disarm_enemy(target, BLAST_DISARM_TURNS)
					_log(combat, beats, "The shove knocks their weapon loose.", BEAT_COMPLICATION_DISARM, { "targetType": "enemy", "targetIndex": target_index })
				_maybe_win_from_direct_damage(combat, target, beats)
		"panic", "pansRapture":
			var turns: int = int(power) + int(cast["turnBonus"])
			var status_key: String = "panicTurns" if recipe_key == "panic" else "raptureTurns"
			var status_index: int = _enemy_action_index(combat)
			combat["enemies"][status_index][status_key] = turns
			# PROSE-REVIEW: Panic / Pan's Rapture Complication line.
			_log(combat, beats, "You trigger %s (%d turn%s)." % [recipe["name"], turns, "" if turns == 1 else "s"], BEAT_USE_PANIC if recipe_key == "panic" else BEAT_USE_RAPTURE,
				{ "targetType": "enemy", "targetIndex": status_index, "effectKey": recipe_key })
		"panger", "pandemonium":
			var anger_index: int = _enemy_action_index(combat)
			combat["enemies"][anger_index]["anger"] = _anger_status(int(cast["tier"]), recipe_key == "pandemonium")
			# PROSE-REVIEW: Panger / Pandemonium Complication line.
			_log(combat, beats, "You trigger %s (%d%%)." % [recipe["name"], combat["enemies"][anger_index]["anger"]["pct"]], BEAT_USE_PANGER if recipe_key == "panger" else BEAT_USE_PANDEMONIUM,
				{ "targetType": "enemy", "targetIndex": anger_index, "effectKey": recipe_key })
		"shield":
			player["shieldPool"] += int(power) * targets
			if multi:
				for ally in combat["allies"]:
					if not ally["koed"]:
						ally["shieldPool"] = int(ally.get("shieldPool", 0)) + int(power) * targets
			_log(combat, beats, "You trigger %s. Shield up — %d absorption." % [recipe["name"], player["shieldPool"]], BEAT_COMPLICATION_SHIELD, { "effectKey": "shield" })
		"blackHole":
			# AoE, ignores selection -- hits every non-koed enemy
			# independently at full power, same as use_black_hole() above.
			var dmg: int = int(power) * targets
			var freeze_turns: int = (1 + int(floor(float(cast["turnPower"]) / 8.0))) * targets + int(cast["turnBonus"])
			_log(combat, beats, "You trigger %s." % recipe["name"], BEAT_COMPLICATION_BLACK_HOLE_ANNOUNCE, {})
			_apply_black_hole_aoe(combat, dmg, freeze_turns, beats)
		"healingBurst":
			var ally_index: int = -1 if multi else selected_ally_index(combat)
			if multi:
				for standing in combat["allies"]:
					if not standing["koed"]:
						heal_ally(standing, int(power) * targets)
			if ally_index >= 0:
				var ally: Dictionary = combat["allies"][ally_index]
				var healed: int = heal_ally(ally, int(power) * targets)
				# PROSE-REVIEW: ally-targeted healing-burst Complication line.
				_log(combat, beats, "You trigger %s on %s — +%d HP. %d/%d HP." % [recipe["name"], ally["name"], healed, ally["hp"], ally["hpMax"]], BEAT_COMPLICATION_HEALING_BURST,
					{ "effectKey": "healingBurst", "targetType": "ally", "targetIndex": ally_index })
			else:
				var old_hp: int = player["hp"]
				player["hp"] = mini(player["hp"] + int(power) * targets, player["hpMax"])
				var healed: int = player["hp"] - old_hp
				_log(combat, beats, "You trigger %s — +%d HP. %d/%d HP." % [recipe["name"], healed, player["hp"], player["hpMax"]], BEAT_COMPLICATION_HEALING_BURST, { "effectKey": "healingBurst" })
		"prophetsBreath":
			combat["evadeTurns"] = int(power) * targets + int(cast["turnBonus"])
			combat["evadeChance"] = 0.50
			_log(combat, beats, "You trigger %s. For a few seconds, you can see it coming." % recipe["name"], BEAT_COMPLICATION_PROPHETS_BREATH, {})
		"wormhole":
			combat["outcome"] = "fled"
			_log(combat, beats, "You trigger %s. You fold the space between you and gone." % recipe["name"], BEAT_COMPLICATION_WORMHOLE, { "actorType": "player" })

	conclude_decision_point(combat, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "recipeKey": recipe_key, "power": power, "targets": targets, "beats": beats }


# Spends loadout slot `index` through its recipe's use_*(). A Rewind result
# carries "rewind": true -- its beats play in reverse.
static func use_slot(index: int) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var blocked: String = slot_block_reason(index)
	if not blocked.is_empty():
		return { "ok": false, "reason": blocked }
	match String(Loadout.slot(index)["recipe"]):
		"timePearl":
			return use_time_pearl(index)
		"enhancementPowder":
			return use_enhancement_powder(index)
		"blast":
			return use_blast(index)
		"shield":
			return use_shield(index)
		"blackHole":
			return use_black_hole(index)
		"panic":
			return use_panic(index)
		"pansRapture":
			return use_pans_rapture(index)
		"panger":
			return use_panger(index)
		"pandemonium":
			return use_pandemonium(index)
		"prophetsBreath":
			return use_prophets_breath(index)
		"wormhole":
			return use_wormhole(index)
		"healingBurst":
			return Consumables.use_healing_burst(combat["selection"].duplicate(), index)
		"rewind":
			var result: Dictionary = combat_rewind(index)
			result["rewind"] = true
			return result
	return { "ok": false, "reason": "No combat effect for that unit." }


static func combat_rewind(slot: int = -1) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["snapshots"].is_empty():
		return { "ok": false, "reason": "Nothing to rewind." }

	var player: Dictionary = GameState.state["player"]
	var slot_index: int = Loadout.find_slot("rewind", slot)
	var has_consumable: bool = slot_index >= 0
	var rewind_index: int = Dial.find_loaded_rewind_complication_index()
	var has_complication: bool = rewind_index >= 0

	if not has_consumable and not has_complication:
		return { "ok": false, "reason": "No rewind available." }

	if has_consumable:
		Loadout.consume(slot_index)
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
	_undo_enemy_substitution(combat, snap)
	var focused_enemy: Dictionary = combat["enemies"][snap["enemyIndex"]]
	focused_enemy["hp"] = snap["enemyHp"]
	focused_enemy["koed"] = focused_enemy["hp"] <= 0
	for status_key in ["panicTurns", "raptureTurns"]:
		focused_enemy[status_key] = int(snap.get("enemy", {}).get(status_key, 0))
	var snap_anger: Variant = snap.get("enemy", {}).get("anger")
	if snap_anger is Dictionary:
		focused_enemy["anger"] = snap_anger.duplicate()
	else:
		focused_enemy.erase("anger")
	var new_log: Array = snap["log"].duplicate()
	new_log.append("⟲ Time unspools. The moment resets. Only you remember.")
	combat["log"] = new_log
	combat["frozenTurns"] = snap["frozenTurns"]
	combat["frozenSkipped"] = snap.get("frozenSkipped", []).duplicate()
	combat["motionTurns"] = snap["motionTurns"]
	combat["motionPower"] = snap["motionPower"]
	var ally_motion: Array = snap.get("allyMotion", [])
	for i in range(mini(ally_motion.size(), combat["allies"].size())):
		combat["allies"][i]["motionTurns"] = ally_motion[i]["motionTurns"]
		combat["allies"][i]["motionPower"] = ally_motion[i]["motionPower"]
	combat["outcome"] = null
	combat["evadeTurns"] = 2
	combat["evadeChance"] = 0.50
	# R§3.7a: restores the cursor to the same parked player-type entry the
	# snapshot was pushed in front of -- a coherent decision point to resume.
	combat["turnCursor"] = snap["turnCursor"].duplicate(true)
	# Rewind restores only the focused enemy's hp (R§3.9) -- whoever else was
	# KO'd since the snapshot stays down, so the restored selection may need
	# the same KO-clamp a live KO gets.
	clamp_selection(combat)
	# The accumulator combat_rewind()/_try_failsafe() read for their "beat
	# queue in reverse" replay -- cleared here after combat_rewind() already
	# captured its own copy, so accumulation restarts from this state.
	combat["beatsSinceSnapshot"] = []


# If a reinforcement replaced the snapshot's focused enemy since, puts the
# original back in its slot and returns every fighter admitted into that slot
# to the waiting queue (rid order, snapshot state). Entrants that took other
# slots, and other slots' KOs, stay as they are (R§3.9 scope).
static func _undo_enemy_substitution(combat: Dictionary, snap: Dictionary) -> void:
	if not snap.has("enemy"):
		return
	var index: int = snap["enemyIndex"]
	var original: Dictionary = snap["enemy"]
	if combat["enemies"][index].get("rid", -1) == original.get("rid", -1):
		return
	var current_queue: Array = combat["enemyQueue"]
	var elsewhere: Array = []
	for i in range(combat["enemies"].size()):
		if i != index:
			elsewhere.append(combat["enemies"][i].get("rid", -1))
	var current_rids: Array = current_queue.map(func(f: Dictionary) -> int: return f.get("rid", -1))
	var restored: Array = current_queue.duplicate()
	for waiting in snap.get("enemyQueue", []):
		var rid: int = waiting.get("rid", -1)
		if not current_rids.has(rid) and not elsewhere.has(rid):
			restored.append(waiting.duplicate(true))
	restored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.get("rid", 0) < b.get("rid", 0))
	combat["enemyQueue"] = restored
	combat["enemies"][index] = original.duplicate(true)


# Checked the moment the player's hp would hit 0, before "loss" resolves
# -- a separate resource from Rewind, tried automatically. Requires a
# snapshot to restore to; with none available the loss proceeds normally.
static func _try_failsafe(combat: Dictionary, player: Dictionary) -> bool:
	var slot_index: int = Loadout.find_slot("failsafe")
	if slot_index < 0:
		return false
	if combat["snapshots"].is_empty():
		return false

	Loadout.consume(slot_index)
	# Unlike combat_rewind(), this skips the reverse-replay capture -- it
	# fires synchronously mid-round, and a second reverse playback would
	# race the enclosing round's forward one. GameState is still fully
	# restored; only the cosmetic animation is skipped.
	_restore_from_snapshot(combat, player)
	combat["log"].append("⚑ Failsafe fires. Death, reversed -- administratively.")
	return true


# Guard-kit spec §Decisions: after the player's Failsafe, a standing guard ally spends one guard kit Rewind unit to undo the
# lethal hit -- on every would-be KO while the pool has one. Same snapshot
# restore (and skipped reverse replay) as _try_failsafe().
static func _try_guard_rewind(combat: Dictionary, player: Dictionary) -> bool:
	if combat["snapshots"].is_empty():
		return false
	for ally in combat["allies"]:
		if ally["koed"] or not _uses_items(ally):
			continue
		var pool: Dictionary = _ally_item_pool(combat, ally)
		if not _guard_pool_has(pool, "rewind"):
			continue
		_spend_guard_item(pool, "rewind")
		_sync_ally_slots(ally, pool)
		_restore_from_snapshot(combat, player)
		# PROSE-REVIEW: guard kit Rewind line.
		combat["log"].append("⟲ %s breaks a Rewind. You're still standing." % ally["name"])
		return true
	return false


static func _dispatch_on_win() -> void:
	var combat: Dictionary = GameState.state["combat"]
	var on_win: String = combat.get("onWin", "")
	match on_win:
		"muggingWon":
			pass  # paid out on exit -- _exit_mugging_win()
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
# win routes home under the sale modal; home_raid routes into the matching debrief
# event (R§3.8); event_raid resumes the still-active event on a win, ends
# it on a loss; otherwise phone home, bag drawer opened on a raid win.
static func exit_combat() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	var outcome = combat["outcome"]
	var context: String = combat["context"]
	var raider_items_used: Dictionary = combat.get("raiderKit", {}).get("used", {})
	var stockpile_faction_id: String = combat.get("stockpileFactionId", "")

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

	GameState.state["combat"] = {
		"active": false, "context": CONTEXT_RAID, "veinId": null, "enemies": [],
		"locationKey": "",
		"selection": { "type": "enemy", "index": 0 }, "log": [],
		"outcome": null, "frozenTurns": 0, "frozenSkipped": [], "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": null, "snapshots": [],
		"allies": [], "raiderKit": {}, "guardKit": {},
		"beatsSinceSnapshot": [], "slotsUsed": [],
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
