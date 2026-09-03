class_name Combat
extends RefCounted

# Turn-based combat per R§3.7, plus rewind per R§3.9. Static funcs only.

# Canonical combat.context vocabulary (hygiene-03). Named constants replace
# the bare literals every call site used to spell out, so a typo becomes a
# push_error in _start_combat() instead of a silent mis-route in
# exit_combat()'s default fallback.
const CONTEXT_RAID: String = "raid"
const CONTEXT_MUGGING: String = "mugging"
const CONTEXT_EVENT_MUGGING: String = "event_mugging"
const CONTEXT_HOME_RAID: String = "home_raid"
const CONTEXT_EVENT_RAID: String = "event_raid"
const CONTEXT_DEFEND_VEIN: String = "defend_vein"
# bugfixes-95: Archie's own tag-along deal going wrong — distinct from
# CONTEXT_MUGGING (a normal Archie-lane sale) since a win/loss here resolves
# through ArchieDeals.resolve_mugging() rather than Economy.complete_mugged_sale(),
# and unlike CONTEXT_MUGGING a *loss* here still needs its own exit_combat()
# handling (clearing archieDealActive), not just the win.
const CONTEXT_ARCHIE_DEAL_MUGGING: String = "archie_deal_mugging"

const CANONICAL_CONTEXTS: Array[String] = [
	CONTEXT_RAID, CONTEXT_MUGGING, CONTEXT_EVENT_MUGGING,
	CONTEXT_HOME_RAID, CONTEXT_EVENT_RAID, CONTEXT_DEFEND_VEIN,
	CONTEXT_ARCHIE_DEAL_MUGGING,
]

# Contexts that are a mugging in flavour (no vein at stake, "they leg it" on
# a win) rather than a raid — shared by the win-line/label logic here and
# in scenes/screens/combat.gd so a third mugging-flavoured context (should
# one ever exist) is one edit, not three.
const NON_LETHAL_MUGGING_CONTEXTS: Array[String] = [CONTEXT_MUGGING, CONTEXT_EVENT_MUGGING, CONTEXT_ARCHIE_DEAL_MUGGING]

# combat-presentation ticket 04: beat "kind" vocabulary, same "named
# constant instead of a bare literal at every call site" precedent as
# CONTEXT_* above -- a typo becomes an unresolved-identifier error here
# instead of a beat whose kind silently never matches whatever a later
# ticket's director/juice-layer code switches on.
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

# combat-presentation ticket 05: cast_complication()'s own beat kinds (the
# Dial-cast path only -- use_blast()/use_black_hole()/use_time_pearl() and
# friends, the direct bag-inventory consumable path, still don't thread
# beats; see this file's own _log() comment).
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

# combat-presentation ticket 11, docs/combat-animation-vision.md §5: the
# direct bag-item consumable path (use_*()) gets its own beat kinds, parallel
# to BEAT_COMPLICATION_* above (the Dial-cast path) since the two paths log
# different phrasing -- but every beat either path produces for the same
# effect carries the same `effectKey` extra field (see each use_*()/
# cast_complication() branch below), so the screen's effect-sheet dispatch
# reads one field regardless of which path triggered it.
const BEAT_USE_TIME_PEARL := "use_time_pearl"
const BEAT_USE_MOTION := "use_motion"
const BEAT_USE_BLAST := "use_blast"
const BEAT_USE_DISARM := "use_disarm"
const BEAT_USE_SHIELD := "use_shield"
const BEAT_USE_BLACK_HOLE_ANNOUNCE := "use_black_hole_announce"
const BEAT_USE_WORMHOLE := "use_wormhole"
const BEAT_USE_HEALING_BURST := "use_healing_burst"

# calc-effect-wiring-02 combat-pattern consumables. Percentages/turns are
# placeholders per the ticket ("tune as needed"), not final balance.
const BLAST_FLEE_BOOST_CHANCE := 0.90
const BLAST_DISARM_CHANCE := 0.15
const BLAST_DISARM_TURNS := 2

# dial-device ticket 07: recipeKeys with a defined combat effect --
# cast_complication() refuses to cast anything else loaded in the Dial
# (rejuvenation/beALady/pansPrank/healingSalve have no in-combat mechanic;
# rewind is cast via combat_rewind()'s own fallback, not this).
const COMBAT_COMPLICATION_RECIPES: Array[String] = ["timePearl", "enhancementPowder", "blast", "shield", "blackHole", "healingBurst", "prophetsBreath", "wormhole"]

# 44-archie-combat-ally: below this fraction of hpMax, an ally spends their
# turn on their own stash instead of attacking (self-preservation over
# damage, since they have no player to hand a Healing Burst to).
const ALLY_HEAL_THRESHOLD_FRACTION := 0.4

# squad-combat ticket 02: R§3.7a's turn-order value. Mugger has no
# data/enemies.json template of its own (it's generated procedurally below),
# so its authored speed lives here instead. Both, like every other speed
# value in this ticket, are draft/needs balance sign-off per R§3.7a.
const MUGGER_SPEED := 11
# Default for any newly-authored enemy template that omits `speed` entirely
# -- same "documented default" precedent _enemy_capabilities_from_template()
# already sets for evadeChance (0.2).
const DEFAULT_TEMPLATE_SPEED := 10

# squad-combat ticket 05, R§3.7a: Combat Skill's two level-indexed effects'
# XP sources. Flat regardless of hit/miss/outcome (mirrors Dial.
# cast_complication()'s flat +10 -- taking a turn/casting is the "attempt",
# there's no separate success/fail split to award differently against).
const COMBAT_XP_PER_ATTACK_TURN := 5
const COMBAT_XP_PER_GYM_SESSION := 30

# squad-combat ticket 04, R§3.7a "Roster generation": per-instance hp/attack
# variance band for spawned mugger/guard entries -- DRAFT, needs balance
# sign-off, not a final number.
const ENEMY_INSTANCE_VARIANCE := 0.15
# R§3.7a's own squad-size cap -- also the ceiling generate_raid_enemy()
# clamps guard_count to below.
const SQUAD_MAX := 3


static func is_canonical_context(context: String) -> bool:
	return CANONICAL_CONTEXTS.has(context)


# squad-combat ticket 04, R§3.7a "Roster generation": rolls the applied
# variance for one stat independently -- called once per hp/attackMin/
# attackMax so same-archetype squadmates are never stat-for-stat identical.
static func _apply_instance_variance(base: float) -> int:
	return GameState.round_epsilon(base * Rng.randf_range(1.0 - ENEMY_INSTANCE_VARIANCE, 1.0 + ENEMY_INSTANCE_VARIANCE))


# vein-trade-assets ticket 02, spec: a trade including a vein rolls against
# a "harder-than-default" mugger encounter -- DRAFT/needs balance sign-off,
# flagged for review same as MUG_BASE_CHANCE_VEIN in economy.gd. Proposed as
# a wider, higher-floor roster (2-4 vs. the default 1-3) at 1.3x base
# stats, rather than a new archetype -- still "a mugger", just more of them
# and hitting harder, since there's a vein's worth of money on the table.
const HARD_MUGGER_MIN_COUNT := 2
const HARD_MUGGER_MAX_COUNT := 4
const HARD_MUGGER_STAT_SCALE := 1.3


# squad-combat ticket 04: `count` distinct entries off the single mugger
# archetype's base stats (hp 28, atk 4-10 per R§3.7a), each with independent
# variance -- replaces the old one `hp x count` blob. No new mugger
# archetype is introduced; every entry shares the same base stats.
# vein-trade-assets ticket 02: `harder` widens the roster to
# [HARD_MUGGER_MIN_COUNT, HARD_MUGGER_MAX_COUNT] and scales every instance's
# base stats by HARD_MUGGER_STAT_SCALE -- see those consts' doc above.
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


# squad-combat ticket 04: the "N muggers stepped out" intro-line label,
# pulled out of generate_mugger() itself now that naming a roster (vs. a
# single blob dict) is the caller's job, not the generator's.
static func _mugger_intro_label(count: int) -> String:
	return "A mugger" if count == 1 else "%d muggers" % count


# calc-effect-wiring-01: builds the {weapon, ability, evadeChance} capability
# fields shared by every enemy-construction path, from a raw template dict
# (JSON template or the hand-authored homeRaidRaider dict). evadeChance
# defaults to 20% when a template omits the key entirely — the documented
# default for any newly-authored enemy template (existing templates all
# specify 0 explicitly in data/enemies.json to preserve current combat math).
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


# Debug-only in M0 — R§3.7: "reachable in M0 only via debug; keep functions."
# M0 has no NPC-claimed-vein storage, so callers must supply a value tier/
# guards directly rather than a real vein.
# vein-growth-state ticket 03 §3: this parameter used to be a 1-5 vein
# "level" — it's a Cultivating.value_tier() (1-6) now, same shape, no
# formula change, just a name that no longer lies about what it holds.
# squad-combat ticket 04: `guard_count` (capped at SQUAD_MAX) distinct
# entries instead of one `hpBase x guard_count` blob -- each slot
# independently rolls a template from GameData.ENEMY_RAID_GUARDS unless
# `template_key` forces one template for every slot, and every entry gets
# its own hp/attackMin/attackMax variance (R§3.7a).
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


# squad-combat ticket 04: raid-intro group label for a spawned guard
# roster -- collapses same-named entries to "N× Name" (identical shape the
# old forced/single-template blob name used, so a forced-template or an
# incidentally-uniform roll reads exactly as before), and joins distinct
# names for a mixed-archetype squad (e.g. one Scrapper + one Vein Guard),
# which is newly possible now that each slot rolls its own template.
# PROSE-REVIEW: the "and"-joined mixed-squad case is new copy, drafted
# against CONTENT-GUIDE.md's tone bible.
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
	# squad-combat ticket 05, R§3.7a: Combat Skill's attack bonus applies
	# before the weapon bonus below -- level 1 is 0, so a fresh save reads
	# identically to pre-ticket combat math.
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
# weapon bonus, if any (calc-effect-wiring-01 — the weapon disarm strips).
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


# calc-effect-wiring-01 foundation for calc-effect-wiring-02's Blast: strips
# the enemy's weapon bonus outright and locks any ability out for `turns`
# player-attack turns (ticked down and re-announced in player_attack()).
static func disarm_enemy(enemy: Dictionary, turns: int) -> void:
	enemy["weapon"] = null
	if enemy.get("ability") != null:
		enemy["ability"]["lockedTurns"] = turns


# 68-archie-fights-when-mugged-via-archie-sale: this is the mugging that
# fires out of Economy.execute_sale()'s Archie lane (its only caller) --
# his own deal going wrong -- so he always fights here, bypassing
# Contacts.can_join_combat()'s recruited/kit/KO-cooldown gate entirely
# rather than being subject to it like every other ally-join site.
# vein-trade-assets ticket 02: `vein_included`, passed through by
# execute_sale from whether the batched sale that triggered this mugging
# had a vein in it, rolls generate_mugger()'s harder roster instead of the
# default one -- see HARD_MUGGER_* above.
static func start_mugging(vein_included: bool = false) -> void:
	var enemies := generate_mugger(vein_included)
	var log_lines := ["%s step out of nowhere. They want what you're carrying." % _mugger_intro_label(enemies.size())]
	if vein_included:
		# PROSE-REVIEW: new line, drafted against CONTENT-GUIDE.md's tone
		# bible -- flags that this crew is the harder vein-stakes roster
		# without spelling out the mechanic.
		log_lines.append("Word of a vein in the mix travels fast -- this lot came heavier.")
	# PROSE-REVIEW: new ally-join log line, drafted against
	# CONTENT-GUIDE.md's tone bible.
	log_lines.append("Archie's deal, Archie's problem -- he wades in.")
	_start_combat(CONTEXT_MUGGING, null, enemies, log_lines, "muggingWon",
		[Contacts.build_combat_ally("archie")])


# bugfixes-95: the mugging that fires out of ArchieDeals.accept_deal() --
# his own deal, same always-ally reasoning start_mugging() above uses. onWin
# is "" (unlike start_mugging()'s "muggingWon") because both outcomes here
# need handling, not just the win — ArchieDeals.resolve_mugging() is called
# from exit_combat() for this context regardless of outcome, the same shape
# CONTEXT_DEFEND_VEIN's Raiding.resolve_defend_outcome() already uses.
static func start_archie_deal_mugging() -> void:
	var enemies := generate_mugger()
	var log_lines := ["%s step out of nowhere. They want what you're carrying." % _mugger_intro_label(enemies.size())]
	# PROSE-REVIEW: new ally-join log line, drafted against
	# CONTENT-GUIDE.md's tone bible.
	log_lines.append("Archie's deal, Archie's problem -- he wades in.")
	_start_combat(CONTEXT_ARCHIE_DEAL_MUGGING, null, enemies, log_lines, "",
		[Contacts.build_combat_ally("archie")])


# District-event-triggered street mugging (M1-LONDON D5, e.g.
# camden_shakedown). Distinct context from "mugging" because there's no
# pendingSaleCut to settle — onWin is "" (no dispatch; see
# _dispatch_on_win()'s default case) and exit_combat() routes back to the
# still-active event screen rather than to the sale flow or home.
static func start_street_mugging() -> void:
	var enemies := generate_mugger()
	_start_combat(CONTEXT_EVENT_MUGGING, null, enemies,
		["%s want a word. This is about to get physical." % _mugger_intro_label(enemies.size())],
		"")


# Called by combat_intro events (T13) via the start_home_raid_combat effect op.
static func start_home_raid_combat() -> void:
	var raider: Dictionary = GameData.ENEMY_HOME_RAID_RAIDER
	var enemy := {
		"name": raider["name"], "hp": raider["hp"], "hpMax": raider["hp"],
		"attackMin": raider["attackMin"], "attackMax": raider["attackMax"],
		"isMugging": false,
	}
	enemy.merge(_enemy_capabilities_from_template(raider))
	_start_combat(CONTEXT_HOME_RAID, null, [enemy],
		["They're in the flat. You've got the crowbar. This is happening."],
		"homeRaidWon")


# Debug-only in M0 (see generate_raid_enemy). vein-raiding ticket 02: also
# called by events.gd's "start_raid_combat" op (a raid event card's "caught"
# branch), which passes context "event_raid" so exit_combat() below knows to
# resume the still-active event on a win instead of routing to inventory --
# every other caller keeps the original "raid" context and its behaviour.
static func start_raid(vein_id: String, value_tier: int, guards: int = 1, template_key: String = "", context: String = CONTEXT_RAID, ally_ids: Array = []) -> void:
	var enemies := generate_raid_enemy(vein_id, value_tier, guards, template_key)
	var log_lines := ["%s steps out to meet you." % _guard_group_name(enemies)]
	var allies := _gather_raid_allies(ally_ids, log_lines)
	_start_combat(context, vein_id, enemies, log_lines, "raidWon", allies)


# 45-archie-raid-assist: unlike _gather_defend_allies' auto-join-everyone
# (defending needs no offer/decline step), bringing an ally on a raid is the
# player's explicit choice made at the Raid button (map.gd) -- ally_ids is
# that choice, threaded here via Raiding.begin_raid() -> the vein_raid
# event's context -> events.gd's _start_raid_combat(). Re-validated against
# can_join_combat() here (not just the raid-initiation UI's own
# Contacts.can_assist_raid() check) since a time block or two passes between
# pressing Raid and combat actually starting -- relation/KO-cooldown/recruit
# state could have moved in that window.
static func _gather_raid_allies(ally_ids: Array, log_lines: Array) -> Array:
	var allies: Array = []
	for contact_id in ally_ids:
		if Contacts.can_join_combat(contact_id):
			allies.append(Contacts.build_combat_ally(contact_id))
			# PROSE-REVIEW: new ally-join log line, drafted against
			# CONTENT-GUIDE.md's tone bible.
			log_lines.append("%s comes in behind you." % Contacts.display_name(contact_id))
	return allies


# vein-raiding ticket 07: the alarm-upgrade defend encounter. Called by
# Raiding.maybe_trigger_defend() once the player travels into the target
# vein's district within the pending window. Reuses generate_raid_enemy()
# (same raid-guard enemy shape start_raid() above uses) rather than a bespoke
# enemy, per the ticket's "reusing Combat's start/outcome-handling machinery,
# no bespoke combat system". onWin is "" -- a win leaves the vein exactly as
# it was (nothing to dispatch); a loss is handled by
# Raiding.resolve_defend_outcome() from exit_combat() below, not here.
static func start_defend_vein(vein_id: String, value_tier: int) -> void:
	var enemies := generate_raid_enemy(vein_id, value_tier)
	# PROSE-REVIEW: new combat intro line, drafted against CONTENT-GUIDE.md's
	# tone bible (dry, administrative, one line).
	var log_lines := ["The alarm wasn't lying. %s is already there." % _guard_group_name(enemies)]
	var allies := _gather_defend_allies(log_lines)
	_start_combat(CONTEXT_DEFEND_VEIN, vein_id, enemies, log_lines, "", allies)


# 44-archie-combat-ally: vein-defense fights only -- every recruited contact
# with a combat kit joins automatically (no offer/decline step; per the
# ticket, defending shared interests doesn't need much trust or a choice).
# Generic over contact_id, so a future second recruit plugs in unmodified.
static func _gather_defend_allies(log_lines: Array) -> Array:
	var allies: Array = []
	for contact_id in GameState.state["contacts"].keys():
		if Contacts.can_join_combat(contact_id):
			allies.append(Contacts.build_combat_ally(contact_id))
			# PROSE-REVIEW: new ally-join log line, drafted against
			# CONTENT-GUIDE.md's tone bible.
			log_lines.append("%s peels off to help cover the vein." % Contacts.display_name(contact_id))
	return allies


static func _start_combat(context: String, vein_id, enemies: Array, log_lines: Array, on_win: String, allies: Array = []) -> void:
	if not is_canonical_context(context):
		push_error("Combat: unrecognized context '%s' — not in CANONICAL_CONTEXTS, exit_combat() will mis-route it." % context)
	# squad-combat ticket 01: every roster entry needs koed regardless of
	# which of the six start_* paths built it -- one chokepoint rather than
	# duplicating this at each enemy-construction call site. speed is set at
	# construction time instead (generate_mugger()'s MUGGER_SPEED, or
	# _enemy_capabilities_from_template()'s per-template value) -- ticket 02's
	# authored values, not a blanket placeholder. squad-combat ticket 04:
	# `enemies` is now the full roster (up to SQUAD_MAX distinct entries),
	# not a single dict wrapped in a list.
	for enemy in enemies:
		enemy["koed"] = false
	GameState.state["combat"] = {
		"active": true, "context": context, "veinId": vein_id, "enemies": enemies,
		"focusedEnemyIndex": 0,
		"log": log_lines, "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": on_win, "snapshots": [],
		"allies": allies,
		# combat-presentation ticket 11: every beat _log() threads since the
		# oldest snapshot still on the stack was pushed -- see that func's own
		# comment and combat_rewind()'s "beat queue in reverse" use of it.
		"beatsSinceSnapshot": [],
	}
	GameState.state["currentScreen"] = "combat"
	EventBus.screen_changed.emit("combat")
	EventBus.state_changed.emit()
	# 81-map-stuck-playback-flag: this is the sole combat-entry chokepoint,
	# and it sets currentScreen/emits screen_changed itself rather than going
	# through Nav.go_to() (bundling those two lines with state["combat"] setup
	# above as one atomic update) -- so it needs the exact same
	# abandon-after-both-emits treatment Nav.go_to() gives every other
	# navigation-away-from-map, for the exact same reason: Raiding.
	# maybe_trigger_defend() (the arrival-side hook for a pending vein-defend
	# raid) can fire this synchronously, mid-Sites.prospect()/Travel.travel_to(),
	# right after that same action queued a MapEvents animation still "playing"
	# on the Map screen it's about to be torn out from under. See Nav.go_to()'s
	# own comment for why this has to come after the emits, not before.
	MapEvents.abandon_playback()


# squad-combat ticket 01: the player's single-target actions (Attack,
# Blast, Black Hole, any non-AoE Complication) all resolve against this one
# entry -- pulled out since combat.enemies[combat.focusedEnemyIndex] was
# repeated verbatim at every one of those call sites.
static func _focused_enemy(combat: Dictionary) -> Dictionary:
	return combat["enemies"][combat["focusedEnemyIndex"]]


# combat-presentation ticket 02: the turn-order strip's swipe-to-target
# gesture calls this rather than writing combat.focusedEnemyIndex directly
# -- SCREENS never mutate GameState.state (project constitution's one-way
# data flow). Not a combat action (no snapshot push, no turn spent, no log
# line) -- purely a targeting choice, same as tapping a target used to be
# before this ticket.
static func set_focused_enemy(index: int) -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var enemies: Array = combat["enemies"]
	if index < 0 or index >= enemies.size() or enemies[index]["koed"]:
		return { "ok": false, "reason": "Invalid target." }
	combat["focusedEnemyIndex"] = index
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
		"focusedEnemyIndex": combat["focusedEnemyIndex"],
		"log": combat["log"].duplicate(),
		"frozenTurns": combat["frozenTurns"],
		"motionTurns": combat["motionTurns"],
		"motionPower": combat["motionPower"],
		"evadeTurns": combat["evadeTurns"],
		"evadeChance": combat["evadeChance"],
	}
	Snapshots.push("combat", combat["snapshots"], snap)


# squad-combat ticket 02, R§3.7a "Turn order": every non-koed combatant
# (player, living allies, living enemies), sorted by speed descending, ties
# broken player > allies (array order) > enemies (array order) -- no RNG in
# the sort. The tie-break is encoded by the fixed construction order below
# (player appended first, then allies/enemies in array order) plus an
# index-stable comparator, rather than relied on from Array.sort_custom
# (which Godot does not guarantee is a stable sort).
#
# Motion (motionTurns > 0) inserts attack_count - 1 extra player entries
# immediately after the player's own slot -- today's attack_count (2 at
# motionPower < 3, 3 at motionPower >= 3, matching the old in-place-loop
# thresholds exactly) is preserved so total damage output for a
# Motion-boosted round is unchanged, just spread across visible queue
# entries instead of a hidden per-attack multiplier.
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


# squad-combat ticket 05, R§3.7a: shared by player_attack()'s flat per-turn
# XP and Train()'s larger flat gym-session XP -- same
# Progression.award_xp()/GameData.COMBAT_XP_LEVELS mechanism crafting/
# cultivating skill already use (Cultivating.award_xp() is the precedent).
static func award_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	var on_level_up := func(): Notify.push("Combat Skill up — now level %d." % player["combatSkill"], Notify.CATEGORY_SUCCESS)
	Progression.award_xp(player, "combatXP", "combatSkill", GameData.COMBAT_XP_LEVELS, amount, on_level_up)


# squad-combat ticket 02: replaces the old round-synchronous body (player
# attacks, then every ally, then the one enemy, all inline in this func)
# with a walk over build_turn_queue()'s ordering -- each entry resolves as
# one atomic turn via _resolve_player_turn()/_ally_turn()/_enemy_turn()
# below, stopping the moment an outcome resolves (win, or a loss from an
# enemy who out-sped the player this round).
# combat-presentation ticket 04, docs/combat-animation-vision.md §8: also
# returns `beats`, an ordered Array of pure-data dictionaries, one per new
# log line this call appends (see _log() above) -- GameState.state itself
# gains no new schema (beats live only in this return value, threaded
# straight to whichever screen code called player_attack()), so save/load
# and Rewind are untouched by this ticket.
static func player_attack() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }

	push_combat_snapshot()
	# dial-device ticket 07: tier-5 Recharge Movement's in-combat regen ticks
	# once per player turn (Dial.combat_turn_tick() is a silent no-op for
	# every other Movement/no-Dial case).
	Dial.combat_turn_tick()

	# squad-combat ticket 05, R§3.7a: flat XP for taking a player turn --
	# once per player_attack() call, regardless of what this turn resolves to
	# (hit, miss, a kill, even a loss elsewhere in the same round) -- "taking
	# a turn" has no separate success/fail split to award differently against.
	award_xp(COMBAT_XP_PER_ATTACK_TURN)

	var beats: Array = []

	# combat-presentation ticket 11: captured BEFORE the end-of-round
	# decrement below, and stamped onto each player-attack beat itself
	# (_resolve_player_turn()'s own `motionBoosted` extra field) rather than
	# left for the screen to re-read live -- by the time beats actually
	# play back, player_attack() has already returned with motionTurns
	# decremented (sometimes to 0, ending the very round it boosted), so a
	# live re-read at playback time would silently miss the round it's
	# meant to describe. See CombatDirector's own top comment for why
	# beats must always be self-describing snapshots, never a live-state
	# lookup.
	var motion_active: bool = combat["motionTurns"] > 0

	# build_turn_queue() is a pure query (no state mutation) -- the
	# Motion-round announcement line is logged here instead, alongside every
	# other player_attack()-owned log line.
	if motion_active:
		var motion_label: String = "three times" if combat["motionPower"] >= 3 else "twice"
		_log(combat, beats, "Motion powder — you move %s as fast." % motion_label, BEAT_MOTION_ANNOUNCE, {})

	for entry in build_turn_queue(combat):
		match entry["type"]:
			"player":
				_resolve_player_turn(combat, beats, motion_active)
			"ally":
				var allies: Array = combat["allies"]
				if entry["index"] < allies.size() and not allies[entry["index"]]["koed"]:
					_ally_turn(combat, allies[entry["index"]], entry["index"], beats)
			"enemy":
				var enemies: Array = combat["enemies"]
				if entry["index"] < enemies.size() and not enemies[entry["index"]]["koed"]:
					_enemy_turn(combat, enemies[entry["index"]], entry["index"], beats)
		if combat["outcome"] != null:
			break

	# Whether this round consumed the last Motion turn doesn't affect
	# anything once the fight has already resolved (exit_combat() tears the
	# whole combat dict down regardless), so this always runs rather than
	# being skipped on an early win/loss the way the old inline version was.
	if combat["motionTurns"] > 0:
		combat["motionTurns"] -= 1
		if combat["motionTurns"] == 0:
			_log(combat, beats, "The powder wears off. Back to normal speed.", BEAT_MOTION_END, {})

	EventBus.state_changed.emit()
	return { "ok": true, "outcome": combat["outcome"], "beats": beats }


# combat-presentation ticket 04, docs/combat-animation-vision.md §8: appends
# `line` to combat.log and, when a live `beats` Array was threaded through
# (player_attack()/flee()'s parting shot/enemy_attack(), and -- combat-
# presentation ticket 05 -- cast_complication()), a matching pure-data beat
# carrying the same line plus whatever kind/detail fields the caller
# supplies. `beats` is null (not an empty Array) at every call site that
# doesn't need beats (use_blast()/use_black_hole()/use_time_pearl() and
# friends, the direct bag-inventory consumable path, which still call this
# via _maybe_win_from_direct_damage()'s shared win-check), so this stays a
# single no-op branch rather than a second logging path. No Node, Callable,
# or SpriteFrames reference ever enters a beat -- ids/numbers/strings only,
# resolved by the screen through its own combatant-lookup.
static func _log(combat: Dictionary, beats: Variant, line: String, kind: String, extra: Dictionary = {}) -> void:
	combat["log"].append(line)
	if beats == null:
		return
	var beat: Dictionary = { "kind": kind, "logLine": line }
	beat.merge(extra)
	beats.append(beat)
	# combat-presentation ticket 11, docs/combat-animation-vision.md §5:
	# "rewind/failsafe ... the beat queue in reverse" -- mirrors every
	# threaded beat onto a rolling accumulator combat_rewind() hands back
	# (reversed) for the director to replay, cleared only when
	# _restore_from_snapshot() actually consumes it. Not reset per-push
	# (see push_combat_snapshot()'s own comment) -- a known, accepted
	# imprecision against the 2-deep snapshot stack, since this is a purely
	# cosmetic replay layered on top of GameState already being fully
	# resolved to the correct restored state by the time it plays.
	combat["beatsSinceSnapshot"].append(beat)


# combat-presentation ticket 11: public entry point for a system outside
# this file (Consumables.use_healing_burst(), the one combat-usable
# consumable that lives elsewhere -- see that func's own top comment for
# why) to thread a beat through the exact same accumulator/beats-array
# convention every use_*() below uses, without reaching into _log() itself.
static func append_beat(combat: Dictionary, beats: Variant, line: String, kind: String, extra: Dictionary = {}) -> void:
	_log(combat, beats, line, kind, extra)


# One atomic player turn: a single attack against the focused enemy. Called
# once per player-type queue entry -- normally once a round, twice/three
# times on a Motion-boosted round (build_turn_queue()'s extra entries).
static func _resolve_player_turn(combat: Dictionary, beats: Variant = null, motion_boosted: bool = false) -> void:
	var enemy: Dictionary = _focused_enemy(combat)
	var target_index: int = combat["focusedEnemyIndex"]
	# combat-presentation ticket 11: `motionBoosted` -- stamped on this
	# beat (evade or landed hit alike) whenever this round is a Motion
	# round, so the screen's afterimage trail can key off the beat itself
	# rather than live state (see player_attack()'s own `motion_active`
	# comment). Only added when true -- every other beat kind/path stays
	# exactly as it was.
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


# 44-archie-combat-ally, squad-combat ticket 02: one atomic ally turn --
# patch up from stash below the heal threshold, or attack the player's
# focused enemy. Same evade/damage shape as the player's own attack.
# combat-presentation ticket 04: `ally_index` is the ally's own position in
# combat.allies -- the caller already has it (build_turn_queue()'s own
# "ally" entries carry it), needed here only to stamp it onto this turn's
# beat.
static func _ally_turn(combat: Dictionary, ally: Dictionary, ally_index: int, beats: Variant = null) -> void:
	var enemy: Dictionary = _focused_enemy(combat)
	var target_index: int = combat["focusedEnemyIndex"]

	if ally["hp"] < ally["hpMax"] * ALLY_HEAL_THRESHOLD_FRACTION and ally["stash"] > 0:
		ally["stash"] -= 1
		ally["hp"] = mini(ally["hpMax"], ally["hp"] + ally["healAmount"])
		# PROSE-REVIEW: new ally self-heal log line, drafted against
		# CONTENT-GUIDE.md's tone bible.
		_log(combat, beats, "%s patches themselves up. %s: %d/%d HP." % [ally["name"], ally["name"], ally["hp"], ally["hpMax"]], BEAT_ALLY_HEAL,
			{ "actorType": "ally", "actorIndex": ally_index, "amount": ally["healAmount"] })
		return

	if Rng.chance(enemy.get("evadeChance", 0.0)):
		# PROSE-REVIEW: new ally-miss log line.
		_log(combat, beats, "%s swings at %s — they dodge." % [ally["name"], enemy["name"]], BEAT_ENEMY_EVADE,
			{ "actorType": "ally", "actorIndex": ally_index, "targetType": "enemy", "targetIndex": target_index })
		return

	var dmg: int = Rng.randi_range(ally["attackMin"], ally["attackMax"])
	enemy["hp"] = maxi(0, enemy["hp"] - dmg)
	# PROSE-REVIEW: new ally-attack log line.
	_log(combat, beats, "%s hits %s for %d. Enemy: %d/%d HP." % [ally["name"], enemy["name"], dmg, enemy["hp"], enemy["hpMax"]], BEAT_ALLY_ATTACK,
		{ "actorType": "ally", "actorIndex": ally_index, "targetType": "enemy", "targetIndex": target_index, "dmg": dmg })
	_maybe_win_from_direct_damage(combat, enemy, beats)


# 44-archie-combat-ally: the enemy's single attack now targets the player or
# one alive ally, uniform-random over whoever's still standing -- an ally
# absent from combat.allies (every non-defend-vein context) leaves this
# identical to the pre-ticket player-only behaviour.
# combat-presentation ticket 04: returns combat.allies' own index instead of
# the ally dict itself (-1 sentinel for "attack the player") -- beats need a
# stable, ids-only target reference (no Node/Dictionary references belong in
# a beat), and Dictionary `==` in GDScript compares contents rather than
# identity, so returning the dict itself would risk a find()-style lookup
# elsewhere matching the wrong same-stat ally.
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


# Standalone entry point -- still called directly (not via the turn queue)
# by flee()'s failed-flee parting shot and by several tests that drive an
# enemy's attack in isolation. squad-combat ticket 01: roster generation (N
# distinct entries) isn't built until ticket 04 -- every fight here still
# has exactly one entry, so "the acting enemy" is unambiguously index 0.
# combat-presentation ticket 04: returns { "beats": beats } instead of void
# now (docs/combat-animation-vision.md §8) -- every existing call site
# either ignores the return value (a bare `Combat.enemy_attack()` statement)
# or, new in this ticket, flee()'s parting shot, which merges the returned
# beats into its own. Doesn't emit state_changed itself, same as before --
# every caller still owns that.
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


# squad-combat ticket 02: one atomic enemy turn for the turn queue -- the
# ability-lock/frozen bookkeeping the old player_attack() ran unconditionally
# once per call now runs specifically at this enemy's own queue slot instead.
# A frozen turn is a no-op-plus-decrement (same log line as today) rather
# than being skipped/removed from the queue -- the entry is still walked,
# it just doesn't attack.
# combat-presentation ticket 04: `enemy_index` is this enemy's own position
# in combat.enemies -- the caller already has it (build_turn_queue()'s own
# "enemy" entries carry it), needed here only to stamp it onto beats.
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

	# calc-effect-wiring-02: Shield absorbs 1:1 out of player.shieldPool
	# before HP takes anything -- dmg <= pool drains the pool for zero
	# damage, dmg > pool empties the pool and passes the remainder through.
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
		# combat-presentation ticket 11, §5: "shield ... cracks and sheds a
		# layer on each absorb" -- carried independently of `dmg` (which can
		# be 0 on a full absorb, and CombatDirector.beat_is_damaging()/
		# _play_juice() only fire for dmg > 0) so the crack still plays even
		# when nothing got through to the player's HP.
		beat_extra["shieldAbsorbed"] = absorbed
	_log(combat, beats, "%s hits you for %d%s. You: %d/%d HP." % [enemy["name"], dmg, shield_note, player["hp"], player["hpMax"]], BEAT_ENEMY_ATTACK, beat_extra)
	if player["hp"] <= 0:
		# combat-presentation ticket 04: a failsafe/rewind trigger rewrites
		# combat.log wholesale (_restore_from_snapshot() replaces the array,
		# it doesn't append) -- there is no single new line to pair a beat
		# with, so this path deliberately stays un-beaten rather than
		# emitting a beat whose logLine doesn't correspond to anything
		# beats-array consumers can find at a stable position. Rewind-as-
		# animation (vision doc §5: "the whole stage plays backward") is its
		# own, later mechanism, not this linear beat queue.
		if _try_failsafe(combat, player):
			return
		combat["outcome"] = "loss"
		_log(combat, beats, "You're done. You come round somewhere unpleasant.", BEAT_COMBAT_LOSS, {})
		player["hp"] = GameState.round_epsilon(player["hpMax"] * 0.3)


# 44-archie-combat-ally: no shield/evade/failsafe -- those are player-only
# resources. KO sets the `koed` flag Combat's own loops already check
# everywhere, and starts the contact's real (persistent) cooldown via
# Contacts.knock_out().
static func _enemy_attack_ally(combat: Dictionary, enemy: Dictionary, ally: Dictionary, ally_index: int, enemy_index: int = 0, beats: Variant = null) -> void:
	var atk := get_enemy_attack_range(enemy)
	var dmg: int = Rng.randi_range(atk["min"], atk["max"])
	ally["hp"] = maxi(0, ally["hp"] - dmg)
	# PROSE-REVIEW: new enemy-hits-ally log line, drafted against
	# CONTENT-GUIDE.md's tone bible.
	_log(combat, beats, "%s hits %s for %d. %s: %d/%d HP." % [enemy["name"], ally["name"], dmg, ally["name"], ally["hp"], ally["hpMax"]], BEAT_ENEMY_ATTACK,
		{ "actorType": "enemy", "actorIndex": enemy_index, "targetType": "ally", "targetIndex": ally_index, "dmg": dmg })
	if ally["hp"] <= 0:
		ally["koed"] = true
		# PROSE-REVIEW: new ally-KO log line.
		_log(combat, beats, "%s is knocked out of the fight." % ally["name"], BEAT_ALLY_KO,
			{ "targetType": "ally", "targetIndex": ally_index })
		Contacts.knock_out(ally["contactId"], GameState.state["world"]["day"])


# combat-presentation ticket 04: also returns `beats`, same shape as
# player_attack()'s (see its own comment) -- the failed-flee branch's
# parting shot is the one enemy_attack() call site that needs its beats
# threaded back out, so its own returned beats are appended onto this call's.
static func flee() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }

	# calc-effect-wiring-02: Blast's one-use flee boost. Not part of the
	# canonical combat-dict shape (see use_blast()) -- read defensively and
	# cleared here regardless of the roll's outcome ("for one use, then
	# clear" per the ticket), so it never survives past the next attempt.
	var flee_chance := 0.65
	if combat.get("blastFleeBoost", false):
		flee_chance = BLAST_FLEE_BOOST_CHANCE
		combat["blastFleeBoost"] = false

	var beats: Array = []

	if Rng.chance(flee_chance):
		combat["outcome"] = "fled"
		_log(combat, beats, "You back off sharpish. Probably the right call.", BEAT_FLEE_SUCCESS, {})
	else:
		_log(combat, beats, "You try to leg it — they get a parting shot in.", BEAT_FLEE_FAILED, {})
		var parting_shot: Dictionary = enemy_attack()
		beats.append_array(parting_shot.get("beats", []))

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

	Crafting.inventory_remove("timePearl", 1)
	var power = Crafting.effect_power("timePearl", player["craftingSkill"])
	combat["frozenTurns"] += power
	var turn_word: String = "turn" if power == 1 else "turns"
	var beats: Array = []
	_log(combat, beats, "You throw a time pearl. The air goes thick. Everything slows. (%d %s)" % [power, turn_word], BEAT_USE_TIME_PEARL, { "effectKey": "timePearl" })
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

	Crafting.inventory_remove("enhancementPowder", 1)
	var power = Crafting.effect_power("enhancementPowder", player["craftingSkill"])
	combat["motionPower"] = power
	combat["motionTurns"] = 2 if power >= 3 else 1
	# combat-presentation ticket 11: no effectKey/manifest sheet -- the
	# afterimage trail is a duplicate-sprite alpha ramp the screen triggers
	# directly off combat.motionTurns during the player's own subsequent
	# BEAT_PLAYER_ATTACK beats, not off this activation beat (see
	# scenes/screens/combat.gd's _on_beat_played()).
	var beats: Array = []
	_log(combat, beats, "You rub the powder in. The world slows slightly around you. You feel very fast.", BEAT_USE_MOTION, {})
	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# calc-effect-wiring-02: immediate damage, a one-use boost to the next
# flee() roll (cleared there regardless of outcome), and a small chance to
# disarm the enemy via ticket 01's Combat.disarm_enemy(). Free action, same
# shape as use_time_pearl/use_enhancement_powder above -- doesn't consume
# the turn that triggers enemy_attack().
static func use_blast() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("blast") <= 0:
		return { "ok": false, "reason": "No blast." }

	Crafting.inventory_remove("blast", 1)
	var power = Crafting.effect_power("blast", player["craftingSkill"])
	var enemy: Dictionary = _focused_enemy(combat)
	var target_index: int = combat["focusedEnemyIndex"]
	enemy["hp"] = maxi(0, enemy["hp"] - power)
	var beats: Array = []
	# PROSE-REVIEW: new blast result-log line, drafted against CONTENT-GUIDE.md's tone bible.
	_log(combat, beats, "You let off a blast — %d damage. Enemy: %d/%d HP." % [power, enemy["hp"], enemy["hpMax"]], BEAT_USE_BLAST,
		{ "targetType": "enemy", "targetIndex": target_index, "dmg": power, "effectKey": "blast" })
	combat["blastFleeBoost"] = true

	if Rng.chance(BLAST_DISARM_CHANCE):
		disarm_enemy(enemy, BLAST_DISARM_TURNS)
		# PROSE-REVIEW: new disarm-on-blast log line.
		_log(combat, beats, "The shove knocks their weapon loose.", BEAT_USE_DISARM, { "targetType": "enemy", "targetIndex": target_index })

	_maybe_win_from_direct_damage(combat, enemy, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# calc-effect-wiring-02: sets player.shieldPool, drained 1:1 by
# enemy_attack() above. Blocked while a pool is still active -- same
# "already active" guard shape as use_time_pearl()'s frozenTurns check.
static func use_shield() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("shield") <= 0:
		return { "ok": false, "reason": "No shield." }
	if player["shieldPool"] > 0:
		# PROSE-REVIEW: new "shield already active" block line.
		combat["log"].append("Shield's already up. Save it.")
		EventBus.state_changed.emit()
		return { "ok": false, "reason": "Shield already active." }

	Crafting.inventory_remove("shield", 1)
	var power = Crafting.effect_power("shield", player["craftingSkill"])
	player["shieldPool"] = power
	var beats: Array = []
	# PROSE-REVIEW: new shield-activation log line.
	_log(combat, beats, "A shimmer folds around you. Shield up — %d absorption." % power, BEAT_USE_SHIELD, { "effectKey": "shield" })
	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# squad-combat ticket 03: Black Hole is the one AoE effect (R§3.7a) --
# hits every non-koed enemy independently at full, un-diluted power, not
# combat.focusedEnemyIndex's single entry. Matches the Dial's Spread
# Movement no-per-target-dilution precedent below: hitting 3 enemies is 3x
# the total damage/freeze applied, once per enemy at full power. frozenTurns
# is one shared pool across the whole fight (ticket 02's turn queue), so N
# enemies hit adds freeze_turns once per enemy, not once total.
#
# combat-presentation ticket 05: `beats` (null by default, same convention
# as _log()) is threaded through by both cast_complication() and (ticket 11)
# use_black_hole() -- each hit gets its own log line + beat (kind
# BEAT_COMPLICATION_BLACK_HOLE_HIT, dmg + targetIndex + effectKey set), so
# the juice layer (ticket 05) and the effect-sheet dispatch (ticket 11) can
# play a hit-stop/damage-number/shake/flash/effect-sheet per enemy in the
# fan, sequentially, rather than all at once against no particular target.
# `_log()` itself is already null-safe for `beats` (it still appends the log
# line either way), so this always calls through it rather than branching.
static func _apply_black_hole_aoe(combat: Dictionary, dmg: int, freeze_turns: int, beats: Variant = null) -> void:
	for i in range(combat["enemies"].size()):
		var enemy: Dictionary = combat["enemies"][i]
		if enemy["koed"]:
			continue
		enemy["hp"] = maxi(0, enemy["hp"] - dmg)
		combat["frozenTurns"] += freeze_turns
		# PROSE-REVIEW: new per-enemy Black-Hole-hit log line, drafted against
		# CONTENT-GUIDE.md's tone bible.
		_log(combat, beats, "%s takes %d damage, frozen %d turn(s). %s: %d/%d HP." % [enemy["name"], dmg, freeze_turns, enemy["name"], enemy["hp"], enemy["hpMax"]], BEAT_COMPLICATION_BLACK_HOLE_HIT,
			{ "targetType": "enemy", "targetIndex": i, "dmg": dmg, "effectKey": "blackHole" })
		_maybe_win_from_direct_damage(combat, enemy, beats)


# calc-effect-wiring-02: immediate damage plus frozenTurns, always additive
# regardless of source (stacks with Time Pearl or a prior Black Hole) --
# no reuse guard. Turn count derives from effectPower rather than a new
# recipe schema field, per the ticket.
static func use_black_hole() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("blackHole") <= 0:
		return { "ok": false, "reason": "No black hole." }

	Crafting.inventory_remove("blackHole", 1)
	var power = Crafting.effect_power("blackHole", player["craftingSkill"])
	var freeze_turns: int = 1 + int(floor(float(power) / 8.0))
	var beats: Array = []
	# combat-presentation ticket 11: per-enemy hit beats (via
	# _apply_black_hole_aoe(), same shared helper cast_complication() already
	# uses) replace the old single combined summary line -- see that ticket's
	# own "plays its effect once per hit enemy, not once for the whole
	# screen" acceptance check.
	# PROSE-REVIEW: new black-hole-announce log line, drafted against CONTENT-GUIDE.md's tone bible.
	_log(combat, beats, "You drop a black hole.", BEAT_USE_BLACK_HOLE_ANNOUNCE, {})
	_apply_black_hole_aoe(combat, power, freeze_turns, beats)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# calc-effect-wiring-02: shared by player_attack/use_blast/use_black_hole --
# all three can deal a lethal hit outside/inside the normal turn and need
# the same koed-flagging/win-check afterward.
# squad-combat ticket 01: hp hitting 0 now flags that one entry koed and
# auto-clamps focus off a dead target rather than ending the fight outright
# -- the fight itself only ends once every entry in combat.enemies is koed
# (behaviourally identical to the old single-enemy check for today's
# always-one-entry rosters; ticket 04's multi-entry rosters are what
# actually exercises the "not everyone's down yet" branch).
static func _maybe_win_from_direct_damage(combat: Dictionary, enemy: Dictionary, beats: Variant = null) -> void:
	if enemy["hp"] > 0:
		return
	enemy["koed"] = true
	_clamp_focused_enemy_index(combat)
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


# squad-combat ticket 01: keeps combat.focusedEnemyIndex pointed at a living
# enemy after a kill -- a no-op when the currently-focused entry is still
# alive. With today's always-one-entry rosters this only ever lands on the
# just-killed entry itself (nothing else to clamp to); ticket 04's
# multi-entry rosters are what makes this actually move the focus.
static func _clamp_focused_enemy_index(combat: Dictionary) -> void:
	var enemies: Array = combat["enemies"]
	var idx: int = combat["focusedEnemyIndex"]
	if idx < enemies.size() and not enemies[idx]["koed"]:
		return
	for i in range(enemies.size()):
		if not enemies[i]["koed"]:
			combat["focusedEnemyIndex"] = i
			return


# calc-effect-wiring-03: Prophet's Breath grants the same evadeTurns/
# evadeChance fields Rewind grants (§3.9) -- sharing the fields means
# activating this while Rewind's grant is still active (or vice versa)
# simply overwrites both to the new activation's values, no stacking or
# reconciliation, per the ticket.
static func use_prophets_breath() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("prophetsBreath") <= 0:
		return { "ok": false, "reason": "No prophet's breath." }

	Crafting.inventory_remove("prophetsBreath", 1)
	var power = Crafting.effect_power("prophetsBreath", player["craftingSkill"])
	combat["evadeTurns"] = power
	combat["evadeChance"] = 0.50
	# PROSE-REVIEW: new prophet's-breath activation log line, drafted against CONTENT-GUIDE.md's tone bible.
	combat["log"].append("You take a lungful. For a few seconds, you can see it coming.")
	EventBus.state_changed.emit()
	return { "ok": true }


# calc-effect-wiring-03: Wormhole's combat half -- guarantees flee()'s
# escape outright rather than boosting its roll (contrast Blast's
# blastFleeBoost, which still rolls at a raised chance). Bypasses both the
# 0.65 roll and the enemy's free-attack-on-failed-flee entirely, per the
# ticket. The map-travel half lives in Travel.travel_via_wormhole().
static func use_wormhole() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }
	if Crafting.inventory_qty("wormhole") <= 0:
		return { "ok": false, "reason": "No wormhole." }

	Crafting.inventory_remove("wormhole", 1)
	combat["outcome"] = "fled"
	var beats: Array = []
	# PROSE-REVIEW: new guaranteed-flee log line, drafted against CONTENT-GUIDE.md's tone bible.
	_log(combat, beats, "You fold the space between you and gone. Clean exit -- no parting shot.", BEAT_USE_WORMHOLE, { "actorType": "player" })
	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }


# dial-device ticket 07: replaces use_device() -- casts a loaded Complication
# by its player.dial.loadedComplications index instead of activating a single
# equipped device. "rewind" is refused here (same shape as use_device()'s old
# rewind refusal) since it's cast via combat_rewind()'s own consumable/
# Complication fallback instead, not this. Every "already active" guard below
# runs BEFORE Dial.cast_complication() spends a charge, mirroring each
# use_*()'s own guard order -- a blocked cast must never cost a charge.
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
		# PROSE-REVIEW: new "already frozen" block line (Complication-flavoured
		# variant of use_time_pearl()'s "Save the pearl."), drafted against
		# CONTENT-GUIDE.md's tone bible.
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

	var cast: Dictionary = Dial.cast_complication(index)
	if not cast["ok"]:
		return cast

	var power = cast["power"]
	var targets: int = cast["targets"]
	var recipe: Dictionary = GameData.RECIPES[recipe_key]
	var enemy: Dictionary = _focused_enemy(combat)

	# targets > 1 (a tier-indexed Spread Movement) has no per-target dilution
	# by design (PRD user story 16) -- for a single-target effect (blast) this
	# collapses to repeating the effect at full, un-diluted power `targets`
	# times against the one focused enemy. blackHole (squad-combat ticket 03's
	# AoE effect) folds `targets` into its per-enemy power/freeze instead,
	# since it already hits every non-koed enemy independently regardless of
	# `targets` -- see _apply_black_hole_aoe().
	#
	# PROSE-REVIEW: every "You trigger %s..." log line below is new,
	# Complication-flavoured phrasing (the old device-activation lines read
	# "You activate the %s...") drafted against CONTENT-GUIDE.md's tone bible.
	#
	# combat-presentation ticket 05: every branch now logs through _log()
	# instead of a raw combat["log"].append(), so this cast returns a `beats`
	# array the screen can play back through CombatDirector the same way
	# player_attack()/enemy_attack()/flee() already do (ticket 04) -- the
	# Dial's Blast/Black Hole casts are exactly the "Blast, Black Hole
	# per-enemy hit" damaging beats the juice layer (§4.1) needs to hang a
	# hit-stop/damage-number/shake/flash on. blast/blackHole are the only
	# branches that set a `dmg` field (the juice layer keys off that field's
	# presence, not the beat's kind) -- the others are narrative-only beats.
	var beats: Array = []
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
			var target_index: int = combat["focusedEnemyIndex"]
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
			# squad-combat ticket 03: AoE, ignores focusedEnemyIndex -- hits every
			# non-koed enemy independently at full power (targets' Spread
			# Movement multiplier folded into that per-enemy power/freeze first,
			# same as use_black_hole() above).
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

	# combat-presentation ticket 11, docs/combat-animation-vision.md §5:
	# "rewind/failsafe: the whole stage plays backward — free, it is the
	# beat queue in reverse." Captured (and reversed) BEFORE
	# _restore_from_snapshot() clears combat.beatsSinceSnapshot -- the
	# screen replays these through the director in this order, purely
	# cosmetic (GameState is already restored to the correct pre-rewind
	# state by the time playback starts, same as every other beat queue in
	# this file).
	var replay_beats: Array = combat["beatsSinceSnapshot"].duplicate()
	replay_beats.reverse()

	_restore_from_snapshot(combat, player)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": replay_beats }


# calc-effect-wiring-03: the actual snapshot-restore mechanics, shared by
# combat_rewind() (above -- consumes a rewind consumable/device) and
# _try_failsafe() (below -- consumes failsafe instead). Neither the
# rewind-availability guard nor the resource deduction lives here; each
# caller owns its own.
static func _restore_from_snapshot(combat: Dictionary, player: Dictionary) -> void:
	var snap: Dictionary = Snapshots.oldest(combat["snapshots"])
	Snapshots.clear(combat["snapshots"])

	player["hp"] = snap["playerHp"]
	combat["focusedEnemyIndex"] = snap["focusedEnemyIndex"]
	# koed is kept in lockstep with hp here -- a rewound snapshot's hp is
	# always the pre-lethal value in practice (snapshots are pushed at the
	# start of every player turn), but this keeps the invariant true rather
	# than leaning on that.
	var focused_enemy: Dictionary = _focused_enemy(combat)
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
	# combat-presentation ticket 11: the accumulator combat_rewind() (and,
	# implicitly, _try_failsafe()) reads for its "beat queue in reverse"
	# replay -- cleared here, after combat_rewind() has already captured its
	# own copy above, so a fresh accumulation starts from this restored
	# state rather than double-counting into a future rewind.
	combat["beatsSinceSnapshot"] = []


# calc-effect-wiring-03: checked from enemy_attack() the moment the
# player's hp would hit 0, before the "loss" outcome resolves -- a
# separate resource from Rewind, tried first and automatically (no manual
# Use action exists for failsafe). Requires a snapshot to restore to, same
# as combat_rewind()'s own guard; with none available (e.g. hp hits 0 on a
# failed flee before any player_attack() has ever pushed one), failsafe
# can't do anything and the loss proceeds normally even with failsafe in
# stock.
static func _try_failsafe(combat: Dictionary, player: Dictionary) -> bool:
	if Crafting.inventory_qty("failsafe") <= 0:
		return false
	if combat["snapshots"].is_empty():
		return false

	Crafting.inventory_remove("failsafe", 1)
	# combat-presentation ticket 11: unlike combat_rewind(), this doesn't
	# capture/return combat.beatsSinceSnapshot for a reverse-beat replay --
	# _try_failsafe() fires synchronously mid-round, nested inside
	# player_attack()/enemy_attack()'s own still-in-flight beat queue (see
	# this func's own top comment), and that queue is already mid-playback
	# through the one CombatDirector instance by the time its beats reach
	# the screen. Kicking off a second, reverse playback here would race
	# the enclosing round's own forward playback on the same director.
	# GameState itself is still fully and correctly restored either way
	# (this call, same as combat_rewind()'s) -- only the cosmetic rewind
	# animation is out of scope for the automatic trigger.
	_restore_from_snapshot(combat, player)
	# PROSE-REVIEW: new failsafe auto-trigger log line, drafted against CONTENT-GUIDE.md's tone bible.
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
	# M0 has no NPC-claimed-vein storage (that's M1's prospecting/sites
	# system) — nothing to transfer yet. Kept as a documented no-op so the
	# onWin dispatch and start_raid() stay wireable once M1 lands, per
	# R§3.7's "reachable in M0 only via debug; keep functions."
	pass


# Tears down combat state and routes to the next screen. Per R§3.7's exit
# dispatch: mugging-win leaves the screen alone (sale_result modal is
# already showing); home_raid routes into the matching debrief event
# (R§3.8, wired by M0-T13's Events.start_event); event_raid (vein-raiding
# ticket 02) resumes the still-active event on a win, ends it on a loss;
# otherwise phone home in every case (loss/fled/mugging-loss-that-somehow-
# exits), with the bag drawer opened over it on a raid win (ticket 12: the
# old inventory screen that used to show the loot is retired). Each branch
# below is a private helper (hygiene ticket 02) -- this func just tears down
# shared state and dispatches.
static func exit_combat() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	var outcome = combat["outcome"]
	var context: String = combat["context"]

	# 44-archie-combat-ally: hand any allies' ending hp/stash back to
	# persistent contact state before the combat dict (and its allies array)
	# is torn down below.
	Contacts.replenish_after_combat(combat["allies"])

	GameState.state["combat"] = {
		"active": false, "context": CONTEXT_RAID, "veinId": null, "enemies": [],
		"focusedEnemyIndex": 0, "log": [],
		"outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": null, "snapshots": [],
		"allies": [],
		"beatsSinceSnapshot": [],
	}
	SaveManager.autosave()  # R§6: autosave on combat exit
	# The per-context handlers below only emit screen_changed (some don't
	# emit anything) -- NotificationToast (ticket 04) needs state_changed
	# specifically to know combat.active flipped false and drain its held
	# queue, so guarantee it fires here rather than depending on whichever
	# handler the outcome happens to route through.
	EventBus.state_changed.emit()

	if context == CONTEXT_MUGGING and outcome == "win":
		return _exit_mugging_win()
	if context == CONTEXT_ARCHIE_DEAL_MUGGING:
		return _exit_archie_deal_mugging(outcome)
	if context == CONTEXT_EVENT_MUGGING:
		return _exit_event_mugging()
	if context == CONTEXT_HOME_RAID:
		return _exit_home_raid(outcome)
	if context == CONTEXT_EVENT_RAID:
		return _exit_event_raid(outcome)
	if context == CONTEXT_DEFEND_VEIN:
		return _exit_defend_vein(outcome)
	return _exit_default(outcome, context)


static func _exit_mugging_win() -> Dictionary:
	return { "nextScreen": null }


# bugfixes-95: ArchieDeals.resolve_mugging() handles both outcomes (paying
# out + opening archie_deal_result only on a win, clearing archieDealActive
# either way) -- a win stays put (the modal it opens is already visible,
# same shape _exit_mugging_win() above uses for the normal Archie-sale
# mugging), a loss routes home immediately since there's nothing to show.
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


# Ticket 12: the home screen is retired -- every "route home" destination
# below is now the phone app grid, landing on its home view regardless of
# whatever app was last open. Deliberately hand-rolled rather than calling
# PhoneNav.route_home() (the shared helper every other retired-`home`
# call site uses): exit_combat() already guarantees one state_changed
# emit itself before dispatching here, matching the sibling handlers
# above/below that set currentScreen + emit screen_changed directly
# instead of going through Nav.go_to -- route_home() would fire a second,
# redundant state_changed on top of that.
static func _route_phone_home() -> void:
	GameState.state["currentScreen"] = "phone"
	EventBus.screen_changed.emit("phone")
	PhoneNav.go_home()


static func _exit_home_raid(outcome) -> Dictionary:
	_after_home_raid_combat(outcome)
	var debrief_id: String = "home_raid_debrief_win" if outcome == "win" else "home_raid_debrief_loss"
	Events.start_event(debrief_id)
	return { "nextScreen": "event" }


# event_raid (vein-raiding ticket 02): a raid event card's "caught"
# branch, via start_raid(..., "event_raid"). A win resumes the still-
# active event -- same event_mugging shape above -- so Continue moves on
# to whatever card the event authors next (ticket 03: the claim/loot
# choice), still on cardIndex from before combat interrupted it. A loss
# fails the raid outright: existing combat-loss handling (HP/consequences)
# already applied during combat itself, no new punishment here -- the
# event is simply cleared (there's no claim/loot to offer) and the player
# goes home, the same destination a losing plain "raid" already uses.
static func _exit_event_raid(outcome) -> Dictionary:
	if outcome == "win":
		GameState.state["currentScreen"] = "event"
		EventBus.screen_changed.emit("event")
		return { "nextScreen": "event" }
	GameState.state["event"] = null
	_route_phone_home()
	return { "nextScreen": "phone" }


# defend_vein (vein-raiding ticket 07): Raiding owns the win/loss
# consequence (nothing on a win, the same whole-vein-loss transfer as the
# no-alarm path on a loss) -- this just tells it which happened, then
# routes home either way, same as every other non-raid context below.
static func _exit_defend_vein(outcome) -> Dictionary:
	Raiding.resolve_defend_outcome(outcome == "win")
	_route_phone_home()
	return { "nextScreen": "phone" }


# A raid win used to route to the standalone inventory screen so the loot
# was immediately visible (R§3.7); that screen is retired (ticket 12), so a
# win now opens the bag drawer over the phone home grid instead -- same
# loot visibility, new location.
static func _exit_default(outcome, context: String) -> Dictionary:
	_route_phone_home()
	if outcome == "win" and context == CONTEXT_RAID:
		Bag.open()
	return { "nextScreen": "phone" }


# R§3.8: on loss, carried orichalchum is halved (floor). Previously also
# halved a separate home.storedOre pool — that field was merged into
# player.orichalchum (M1-LONDON-T06, see systems/home.gd), so there is
# only the one pool to lose now.
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


# ── Train (squad-combat ticket 05, R§3.7a) ──────────────────────────────
# HQ action, gated on the Home Gym room being built (independent of that
# room's own one-time +10 hpMax build bonus, GameData.HOME_ROOMS.homeGym --
# Home Gym is dual-purpose, not replaced). No separate cooldown: spending a
# time block, out of the player's three/day, is the only throttle, same
# currency every other block-consuming HQ action (Lab, veinStation, a James
# job fulfilment) already spends.

static func can_train() -> bool:
	return GameState.state["home"]["rooms"].has("homeGym")


static func train() -> Dictionary:
	if not can_train():
		return { "ok": false, "reason": "Build a Home Gym first." }
	if TimeSystem.is_time_exhausted():
		return { "ok": false, "reason": "No time blocks left today." }

	TimeSystem.advance_time_block()
	award_xp(COMBAT_XP_PER_GYM_SESSION)
	# PROSE-REVIEW: new Train-result notification, drafted against
	# CONTENT-GUIDE.md's tone bible (dry, one line).
	Notify.push("A session on the bar and the bag. You feel it tomorrow.", Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	return { "ok": true }
