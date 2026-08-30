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

# squad-combat ticket 01: every roster entry needs a speed field to satisfy
# the shape, but the turn queue that reads it doesn't land until ticket 02 --
# an explicit, undifferentiated placeholder, not a balance value.
const ENEMY_PLACEHOLDER_SPEED := 10


static func is_canonical_context(context: String) -> bool:
	return CANONICAL_CONTEXTS.has(context)


static func generate_mugger() -> Dictionary:
	var count: int = Rng.randi_range(1, 3)
	var name: String = "A mugger" if count == 1 else "%d muggers" % count
	return {
		"name": name,
		"hp": 28 * count,
		"hpMax": 28 * count,
		"attackMin": 4 + 2 * (count - 1),
		"attackMax": 10 + 3 * (count - 1),
		"isMugging": true,
		"weapon": null,
		"ability": null,
		"evadeChance": 0.0,
	}


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
	}


# Debug-only in M0 — R§3.7: "reachable in M0 only via debug; keep functions."
# M0 has no NPC-claimed-vein storage, so callers must supply a value tier/
# guards directly rather than a real vein.
# vein-growth-state ticket 03 §3: this parameter used to be a 1-5 vein
# "level" — it's a Cultivating.value_tier() (1-6) now, same shape, no
# formula change, just a name that no longer lies about what it holds.
static func generate_raid_enemy(vein_id, value_tier: int, guards: int = 1, template_key: String = "") -> Dictionary:
	var templates: Dictionary = GameData.ENEMY_RAID_GUARDS
	var key: String = template_key
	if key == "" or not templates.has(key):
		key = Rng.rand_from(templates.keys())
	var template: Dictionary = templates[key]
	var guard_count: int = maxi(1, guards)
	var hp_scale: float = 1.0 + (value_tier - 1) * 0.3
	var hp: int = GameState.round_epsilon(template["hpBase"] * hp_scale * guard_count)
	var name: String = template["name"] if guard_count <= 1 else "%d× %s" % [guard_count, template["name"]]
	var enemy := {
		"name": name,
		"hp": hp,
		"hpMax": hp,
		"attackMin": template["attackMin"],
		"attackMax": template["attackMax"] + (value_tier - 1),
		"isMugging": false,
	}
	enemy.merge(_enemy_capabilities_from_template(template))
	return enemy


static func get_attack_range() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var min_atk: int = player["attackMin"]
	var max_atk: int = player["attackMax"]
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
static func start_mugging() -> void:
	var enemy := generate_mugger()
	var log_lines := ["%s step out of nowhere. They want what you're carrying." % enemy["name"]]
	# PROSE-REVIEW: new ally-join log line, drafted against
	# CONTENT-GUIDE.md's tone bible.
	log_lines.append("Archie's deal, Archie's problem -- he wades in.")
	_start_combat(CONTEXT_MUGGING, null, enemy, log_lines, "muggingWon",
		[Contacts.build_combat_ally("archie")])


# bugfixes-95: the mugging that fires out of ArchieDeals.accept_deal() --
# his own deal, same always-ally reasoning start_mugging() above uses. onWin
# is "" (unlike start_mugging()'s "muggingWon") because both outcomes here
# need handling, not just the win — ArchieDeals.resolve_mugging() is called
# from exit_combat() for this context regardless of outcome, the same shape
# CONTEXT_DEFEND_VEIN's Raiding.resolve_defend_outcome() already uses.
static func start_archie_deal_mugging() -> void:
	var enemy := generate_mugger()
	var log_lines := ["%s step out of nowhere. They want what you're carrying." % enemy["name"]]
	# PROSE-REVIEW: new ally-join log line, drafted against
	# CONTENT-GUIDE.md's tone bible.
	log_lines.append("Archie's deal, Archie's problem -- he wades in.")
	_start_combat(CONTEXT_ARCHIE_DEAL_MUGGING, null, enemy, log_lines, "",
		[Contacts.build_combat_ally("archie")])


# District-event-triggered street mugging (M1-LONDON D5, e.g.
# camden_shakedown). Distinct context from "mugging" because there's no
# pendingSaleCut to settle — onWin is "" (no dispatch; see
# _dispatch_on_win()'s default case) and exit_combat() routes back to the
# still-active event screen rather than to the sale flow or home.
static func start_street_mugging() -> void:
	var enemy := generate_mugger()
	_start_combat(CONTEXT_EVENT_MUGGING, null, enemy,
		["%s want a word. This is about to get physical." % enemy["name"]],
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
	_start_combat(CONTEXT_HOME_RAID, null, enemy,
		["They're in the flat. You've got the crowbar. This is happening."],
		"homeRaidWon")


# Debug-only in M0 (see generate_raid_enemy). vein-raiding ticket 02: also
# called by events.gd's "start_raid_combat" op (a raid event card's "caught"
# branch), which passes context "event_raid" so exit_combat() below knows to
# resume the still-active event on a win instead of routing to inventory --
# every other caller keeps the original "raid" context and its behaviour.
static func start_raid(vein_id: String, value_tier: int, guards: int = 1, template_key: String = "", context: String = CONTEXT_RAID, ally_ids: Array = []) -> void:
	var enemy := generate_raid_enemy(vein_id, value_tier, guards, template_key)
	var log_lines := ["%s steps out to meet you." % enemy["name"]]
	var allies := _gather_raid_allies(ally_ids, log_lines)
	_start_combat(context, vein_id, enemy, log_lines, "raidWon", allies)


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
	var enemy := generate_raid_enemy(vein_id, value_tier)
	# PROSE-REVIEW: new combat intro line, drafted against CONTENT-GUIDE.md's
	# tone bible (dry, administrative, one line).
	var log_lines := ["The alarm wasn't lying. %s is already there." % enemy["name"]]
	var allies := _gather_defend_allies(log_lines)
	_start_combat(CONTEXT_DEFEND_VEIN, vein_id, enemy, log_lines, "", allies)


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


static func _start_combat(context: String, vein_id, enemy: Dictionary, log_lines: Array, on_win: String, allies: Array = []) -> void:
	if not is_canonical_context(context):
		push_error("Combat: unrecognized context '%s' — not in CANONICAL_CONTEXTS, exit_combat() will mis-route it." % context)
	# squad-combat ticket 01: every roster entry needs koed/speed regardless
	# of which of the six start_* paths built it -- one chokepoint rather
	# than duplicating this at each enemy-construction call site.
	enemy["koed"] = false
	enemy["speed"] = ENEMY_PLACEHOLDER_SPEED
	GameState.state["combat"] = {
		"active": true, "context": context, "veinId": vein_id, "enemies": [enemy],
		"focusedEnemyIndex": 0,
		"log": log_lines, "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": on_win, "snapshots": [],
		"allies": allies,
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


static func player_attack() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }

	push_combat_snapshot()
	# dial-device ticket 07: tier-5 Recharge Movement's in-combat regen ticks
	# once per player turn (Dial.combat_turn_tick() is a silent no-op for
	# every other Movement/no-Dial case).
	Dial.combat_turn_tick()

	var attack_count := 1
	if combat["motionTurns"] > 0:
		attack_count = 3 if combat["motionPower"] >= 3 else 2
		var motion_label: String = "three times" if attack_count == 3 else "twice"
		combat["log"].append("Motion powder — you move %s as fast." % motion_label)

	var enemy: Dictionary = _focused_enemy(combat)
	for i in range(attack_count):
		if enemy["hp"] <= 0:
			break
		var hit_label: String = " (hit %d)" % (i + 1) if attack_count > 1 else ""
		if Rng.chance(enemy.get("evadeChance", 0.0)):
			combat["log"].append("%s dodges%s — no damage." % [enemy["name"], hit_label])
			continue
		var atk := get_attack_range()
		var dmg: int = Rng.randi_range(atk["min"], atk["max"])
		enemy["hp"] = maxi(0, enemy["hp"] - dmg)
		var frozen_note: String = " (enemy frozen)" if combat["frozenTurns"] > 0 else ""
		combat["log"].append("You attack%s — %d damage%s. Enemy: %d/%d HP." % [hit_label, dmg, frozen_note, enemy["hp"], enemy["hpMax"]])
		_maybe_win_from_direct_damage(combat, enemy)
		if combat["outcome"] == "win":
			EventBus.state_changed.emit()
			return { "ok": true, "outcome": "win" }

	# 44-archie-combat-ally: allies act after the player's own attacks this
	# turn, and can finish the fight themselves -- same shared win-check
	# calc-effect-wiring-02's Blast/Black Hole already use for their own
	# direct-damage outside this loop.
	_allies_act(combat, enemy)
	_maybe_win_from_direct_damage(combat, enemy)
	if combat["outcome"] == "win":
		EventBus.state_changed.emit()
		return { "ok": true, "outcome": "win" }

	if combat["motionTurns"] > 0:
		combat["motionTurns"] -= 1
		if combat["motionTurns"] == 0:
			combat["log"].append("The powder wears off. Back to normal speed.")

	if is_ability_locked(enemy):
		enemy["ability"]["lockedTurns"] -= 1
		if enemy["ability"]["lockedTurns"] == 0:
			combat["log"].append("%s's ability is back online." % enemy["name"])

	if combat["frozenTurns"] > 0:
		combat["frozenTurns"] -= 1
		if combat["frozenTurns"] == 0:
			combat["log"].append("The time effect wears off. They're coming back round.")
	else:
		enemy_attack()

	EventBus.state_changed.emit()
	return { "ok": true, "outcome": combat["outcome"] }


# 44-archie-combat-ally: each ally still standing either patches themselves
# up (below the heal threshold, with stash left) or attacks the enemy --
# same evade/damage shape as the player's own attack, just against the
# shared enemy target. Runs after the player's own attacks each turn, once
# per ally, skipping the rest once the enemy is already dead.
static func _allies_act(combat: Dictionary, enemy: Dictionary) -> void:
	for ally in combat["allies"]:
		if ally["koed"] or enemy["hp"] <= 0:
			continue

		if ally["hp"] < ally["hpMax"] * ALLY_HEAL_THRESHOLD_FRACTION and ally["stash"] > 0:
			ally["stash"] -= 1
			ally["hp"] = mini(ally["hpMax"], ally["hp"] + ally["healAmount"])
			# PROSE-REVIEW: new ally self-heal log line, drafted against
			# CONTENT-GUIDE.md's tone bible.
			combat["log"].append("%s patches themselves up. %s: %d/%d HP." % [ally["name"], ally["name"], ally["hp"], ally["hpMax"]])
			continue

		if Rng.chance(enemy.get("evadeChance", 0.0)):
			# PROSE-REVIEW: new ally-miss log line.
			combat["log"].append("%s swings at %s — they dodge." % [ally["name"], enemy["name"]])
			continue

		var dmg: int = Rng.randi_range(ally["attackMin"], ally["attackMax"])
		enemy["hp"] = maxi(0, enemy["hp"] - dmg)
		# PROSE-REVIEW: new ally-attack log line.
		combat["log"].append("%s hits %s for %d. Enemy: %d/%d HP." % [ally["name"], enemy["name"], dmg, enemy["hp"], enemy["hpMax"]])


# 44-archie-combat-ally: the enemy's single attack now targets the player or
# one alive ally, uniform-random over whoever's still standing -- an ally
# absent from combat.allies (every non-defend-vein context) leaves this
# identical to the pre-ticket player-only behaviour.
static func _pick_enemy_target(combat: Dictionary) -> Variant:
	var alive_allies: Array = []
	for ally in combat["allies"]:
		if not ally["koed"]:
			alive_allies.append(ally)
	if alive_allies.is_empty():
		return null
	var candidates: Array = [null]
	candidates.append_array(alive_allies)
	return candidates[Rng.randi_range(0, candidates.size() - 1)]


static func enemy_attack() -> void:
	var combat: Dictionary = GameState.state["combat"]
	if combat["outcome"] != null or combat["frozenTurns"] > 0:
		return

	# squad-combat ticket 01: roster generation (N distinct entries) isn't
	# built until ticket 04 -- every fight here still has exactly one entry,
	# so "the acting enemy" is unambiguously index 0.
	var enemy: Dictionary = combat["enemies"][0]
	var target = _pick_enemy_target(combat)
	if target == null:
		_enemy_attack_player(combat, enemy)
	else:
		_enemy_attack_ally(combat, enemy, target)


static func _enemy_attack_player(combat: Dictionary, enemy: Dictionary) -> void:
	if combat["evadeTurns"] > 0:
		combat["evadeTurns"] -= 1
		if Rng.chance(combat["evadeChance"]):
			var evade_note: String
			if combat["evadeTurns"] > 0:
				evade_note = "%d evade turn%s left." % [combat["evadeTurns"], "" if combat["evadeTurns"] == 1 else "s"]
			else:
				evade_note = "Evade fades."
			combat["log"].append("%s swings — you're not there. %s" % [enemy["name"], evade_note])
			return

	var atk := get_enemy_attack_range(enemy)
	var dmg: int = Rng.randi_range(atk["min"], atk["max"])
	var player: Dictionary = GameState.state["player"]

	# calc-effect-wiring-02: Shield absorbs 1:1 out of player.shieldPool
	# before HP takes anything -- dmg <= pool drains the pool for zero
	# damage, dmg > pool empties the pool and passes the remainder through.
	var shield_note := ""
	if player["shieldPool"] > 0:
		var absorbed: int = mini(dmg, player["shieldPool"])
		player["shieldPool"] -= absorbed
		dmg -= absorbed
		if absorbed > 0:
			shield_note = " (%d absorbed by shield)" % absorbed

	player["hp"] = maxi(0, player["hp"] - dmg)
	combat["log"].append("%s hits you for %d%s. You: %d/%d HP." % [enemy["name"], dmg, shield_note, player["hp"], player["hpMax"]])
	if player["hp"] <= 0:
		if _try_failsafe(combat, player):
			return
		combat["outcome"] = "loss"
		combat["log"].append("You're done. You come round somewhere unpleasant.")
		player["hp"] = GameState.round_epsilon(player["hpMax"] * 0.3)


# 44-archie-combat-ally: no shield/evade/failsafe -- those are player-only
# resources. KO sets the `koed` flag Combat's own loops already check
# everywhere, and starts the contact's real (persistent) cooldown via
# Contacts.knock_out().
static func _enemy_attack_ally(combat: Dictionary, enemy: Dictionary, ally: Dictionary) -> void:
	var atk := get_enemy_attack_range(enemy)
	var dmg: int = Rng.randi_range(atk["min"], atk["max"])
	ally["hp"] = maxi(0, ally["hp"] - dmg)
	# PROSE-REVIEW: new enemy-hits-ally log line, drafted against
	# CONTENT-GUIDE.md's tone bible.
	combat["log"].append("%s hits %s for %d. %s: %d/%d HP." % [enemy["name"], ally["name"], dmg, ally["name"], ally["hp"], ally["hpMax"]])
	if ally["hp"] <= 0:
		ally["koed"] = true
		# PROSE-REVIEW: new ally-KO log line.
		combat["log"].append("%s is knocked out of the fight." % ally["name"])
		Contacts.knock_out(ally["contactId"], GameState.state["world"]["day"])


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

	if Rng.chance(flee_chance):
		combat["outcome"] = "fled"
		combat["log"].append("You back off sharpish. Probably the right call.")
	else:
		combat["log"].append("You try to leg it — they get a parting shot in.")
		enemy_attack()

	EventBus.state_changed.emit()
	return { "ok": true, "outcome": combat["outcome"] }


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
	combat["log"].append("You throw a time pearl. The air goes thick. Everything slows. (%d %s)" % [power, turn_word])
	EventBus.state_changed.emit()
	return { "ok": true }


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
	combat["log"].append("You rub the powder in. The world slows slightly around you. You feel very fast.")
	EventBus.state_changed.emit()
	return { "ok": true }


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
	enemy["hp"] = maxi(0, enemy["hp"] - power)
	# PROSE-REVIEW: new blast result-log line, drafted against CONTENT-GUIDE.md's tone bible.
	combat["log"].append("You let off a blast — %d damage. Enemy: %d/%d HP." % [power, enemy["hp"], enemy["hpMax"]])
	combat["blastFleeBoost"] = true

	if Rng.chance(BLAST_DISARM_CHANCE):
		disarm_enemy(enemy, BLAST_DISARM_TURNS)
		# PROSE-REVIEW: new disarm-on-blast log line.
		combat["log"].append("The shove knocks their weapon loose.")

	_maybe_win_from_direct_damage(combat, enemy)

	EventBus.state_changed.emit()
	return { "ok": true }


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
	# PROSE-REVIEW: new shield-activation log line.
	combat["log"].append("A shimmer folds around you. Shield up — %d absorption." % power)
	EventBus.state_changed.emit()
	return { "ok": true }


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
	var enemy: Dictionary = _focused_enemy(combat)
	enemy["hp"] = maxi(0, enemy["hp"] - power)
	var freeze_turns: int = 1 + int(floor(float(power) / 8.0))
	combat["frozenTurns"] += freeze_turns
	# PROSE-REVIEW: new black hole result-log line, drafted against CONTENT-GUIDE.md's tone bible.
	combat["log"].append("You drop a black hole — %d damage, and the wreckage folds in on itself. Enemy frozen %d turn(s)." % [power, freeze_turns])

	_maybe_win_from_direct_damage(combat, enemy)

	EventBus.state_changed.emit()
	return { "ok": true }


# calc-effect-wiring-02: shared by player_attack/use_blast/use_black_hole --
# all three can deal a lethal hit outside/inside the normal turn and need
# the same koed-flagging/win-check afterward.
# squad-combat ticket 01: hp hitting 0 now flags that one entry koed and
# auto-clamps focus off a dead target rather than ending the fight outright
# -- the fight itself only ends once every entry in combat.enemies is koed
# (behaviourally identical to the old single-enemy check for today's
# always-one-entry rosters; ticket 04's multi-entry rosters are what
# actually exercises the "not everyone's down yet" branch).
static func _maybe_win_from_direct_damage(combat: Dictionary, enemy: Dictionary) -> void:
	if enemy["hp"] > 0:
		return
	enemy["koed"] = true
	_clamp_focused_enemy_index(combat)
	if not _all_enemies_koed(combat["enemies"]):
		return
	combat["outcome"] = "win"
	combat["log"].append("They leg it. Good call on their part." if NON_LETHAL_MUGGING_CONTEXTS.has(combat["context"]) else "They go down. Vein is yours.")
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
	# PROSE-REVIEW: new guaranteed-flee log line, drafted against CONTENT-GUIDE.md's tone bible.
	combat["log"].append("You fold the space between you and gone. Clean exit -- no parting shot.")
	EventBus.state_changed.emit()
	return { "ok": true }


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
	# by design (PRD user story 16) -- with combat's single-enemy model,
	# "hit every target at full power" collapses to repeating the effect at
	# full, un-diluted power once per target against the one enemy present.
	#
	# PROSE-REVIEW: every "You trigger %s..." log line below is new,
	# Complication-flavoured phrasing (the old device-activation lines read
	# "You activate the %s...") drafted against CONTENT-GUIDE.md's tone bible.
	match recipe_key:
		"timePearl":
			var total: int = int(power) * targets
			combat["frozenTurns"] += total
			var turn_word: String = "turn" if total == 1 else "turns"
			combat["log"].append("You trigger %s. Enemy frozen for %d %s." % [recipe["name"], total, turn_word])
		"enhancementPowder":
			combat["motionPower"] = power
			combat["motionTurns"] = 2 if power >= 3 else 1
			combat["log"].append("You trigger %s. Movement accelerated." % recipe["name"])
		"blast":
			var dmg: int = int(power) * targets
			enemy["hp"] = maxi(0, enemy["hp"] - dmg)
			combat["log"].append("You trigger %s — %d damage. Enemy: %d/%d HP." % [recipe["name"], dmg, enemy["hp"], enemy["hpMax"]])
			combat["blastFleeBoost"] = true
			if Rng.chance(BLAST_DISARM_CHANCE):
				disarm_enemy(enemy, BLAST_DISARM_TURNS)
				combat["log"].append("The shove knocks their weapon loose.")
			_maybe_win_from_direct_damage(combat, enemy)
		"shield":
			player["shieldPool"] += int(power) * targets
			combat["log"].append("You trigger %s. Shield up — %d absorption." % [recipe["name"], player["shieldPool"]])
		"blackHole":
			var dmg: int = int(power) * targets
			enemy["hp"] = maxi(0, enemy["hp"] - dmg)
			var freeze_turns: int = (1 + int(floor(float(power) / 8.0))) * targets
			combat["frozenTurns"] += freeze_turns
			combat["log"].append("You trigger %s — %d damage, and the wreckage folds in on itself. Enemy frozen %d turn(s)." % [recipe["name"], dmg, freeze_turns])
			_maybe_win_from_direct_damage(combat, enemy)
		"healingBurst":
			var old_hp: int = player["hp"]
			player["hp"] = mini(player["hp"] + int(power) * targets, player["hpMax"])
			var healed: int = player["hp"] - old_hp
			combat["log"].append("You trigger %s — +%d HP. %d/%d HP." % [recipe["name"], healed, player["hp"], player["hpMax"]])
		"prophetsBreath":
			combat["evadeTurns"] = int(power) * targets
			combat["evadeChance"] = 0.50
			combat["log"].append("You trigger %s. For a few seconds, you can see it coming." % recipe["name"])
		"wormhole":
			combat["outcome"] = "fled"
			combat["log"].append("You trigger %s. You fold the space between you and gone." % recipe["name"])

	EventBus.state_changed.emit()
	return { "ok": true, "recipeKey": recipe_key, "power": power, "targets": targets }


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

	_restore_from_snapshot(combat, player)

	EventBus.state_changed.emit()
	return { "ok": true }


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
