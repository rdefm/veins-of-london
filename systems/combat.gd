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

const CANONICAL_CONTEXTS: Array[String] = [
	CONTEXT_RAID, CONTEXT_MUGGING, CONTEXT_EVENT_MUGGING,
	CONTEXT_HOME_RAID, CONTEXT_EVENT_RAID, CONTEXT_DEFEND_VEIN,
]

# Contexts that are a mugging in flavour (no vein at stake, "they leg it" on
# a win) rather than a raid — shared by the win-line/label logic here and
# in scenes/screens/combat.gd so a third mugging-flavoured context (should
# one ever exist) is one edit, not three.
const NON_LETHAL_MUGGING_CONTEXTS: Array[String] = [CONTEXT_MUGGING, CONTEXT_EVENT_MUGGING]


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
		"veinId": null,
		"isMugging": true,
	}


# Debug-only in M0 — R§3.7: "reachable in M0 only via debug; keep functions."
# M0 has no NPC-claimed-vein storage, so callers must supply level/guards
# directly rather than a real vein.
static func generate_raid_enemy(vein_id, vein_level: int, guards: int = 1, template_key: String = "") -> Dictionary:
	var templates: Dictionary = GameData.ENEMY_RAID_GUARDS
	var key: String = template_key
	if key == "" or not templates.has(key):
		key = Rng.rand_from(templates.keys())
	var template: Dictionary = templates[key]
	var guard_count: int = maxi(1, guards)
	var hp_scale: float = 1.0 + (vein_level - 1) * 0.3
	var hp: int = GameState.round_epsilon(template["hpBase"] * hp_scale * guard_count)
	var name: String = template["name"] if guard_count <= 1 else "%d× %s" % [guard_count, template["name"]]
	return {
		"name": name,
		"hp": hp,
		"hpMax": hp,
		"attackMin": template["attackMin"],
		"attackMax": template["attackMax"] + (vein_level - 1),
		"veinId": vein_id,
		"isMugging": false,
	}


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


static func start_mugging() -> void:
	var enemy := generate_mugger()
	_start_combat(CONTEXT_MUGGING, null, enemy,
		["%s step out of nowhere. They want what you're carrying." % enemy["name"]],
		"muggingWon")


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
		"veinId": null, "isMugging": false,
	}
	_start_combat(CONTEXT_HOME_RAID, null, enemy,
		["They're in the flat. You've got the crowbar. This is happening."],
		"homeRaidWon")


# Debug-only in M0 (see generate_raid_enemy). vein-raiding ticket 02: also
# called by events.gd's "start_raid_combat" op (a raid event card's "caught"
# branch), which passes context "event_raid" so exit_combat() below knows to
# resume the still-active event on a win instead of routing to inventory --
# every other caller keeps the original "raid" context and its behaviour.
static func start_raid(vein_id: String, vein_level: int, guards: int = 1, template_key: String = "", context: String = CONTEXT_RAID) -> void:
	var enemy := generate_raid_enemy(vein_id, vein_level, guards, template_key)
	_start_combat(context, vein_id, enemy,
		["%s steps out to meet you." % enemy["name"]],
		"raidWon")


# vein-raiding ticket 07: the alarm-upgrade defend encounter. Called by
# Raiding.maybe_trigger_defend() once the player travels into the target
# vein's district within the pending window. Reuses generate_raid_enemy()
# (same raid-guard enemy shape start_raid() above uses) rather than a bespoke
# enemy, per the ticket's "reusing Combat's start/outcome-handling machinery,
# no bespoke combat system". onWin is "" -- a win leaves the vein exactly as
# it was (nothing to dispatch); a loss is handled by
# Raiding.resolve_defend_outcome() from exit_combat() below, not here.
static func start_defend_vein(vein_id: String, vein_level: int) -> void:
	var enemy := generate_raid_enemy(vein_id, vein_level)
	# PROSE-REVIEW: new combat intro line, drafted against CONTENT-GUIDE.md's
	# tone bible (dry, administrative, one line).
	_start_combat(CONTEXT_DEFEND_VEIN, vein_id, enemy,
		["The alarm wasn't lying. %s is already there." % enemy["name"]],
		"")


static func _start_combat(context: String, vein_id, enemy: Dictionary, log_lines: Array, on_win: String) -> void:
	if not is_canonical_context(context):
		push_error("Combat: unrecognized context '%s' — not in CANONICAL_CONTEXTS, exit_combat() will mis-route it." % context)
	GameState.state["combat"] = {
		"active": true, "context": context, "veinId": vein_id, "enemy": enemy,
		"log": log_lines, "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": on_win, "snapshots": [],
	}
	GameState.state["currentScreen"] = "combat"
	EventBus.screen_changed.emit("combat")
	EventBus.state_changed.emit()


static func push_combat_snapshot() -> void:
	var combat: Dictionary = GameState.state["combat"]
	if combat["enemy"] == null:
		return
	var player: Dictionary = GameState.state["player"]
	var snap := {
		"playerHp": player["hp"],
		"enemyHp": combat["enemy"]["hp"],
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

	var attack_count := 1
	if combat["motionTurns"] > 0:
		attack_count = 3 if combat["motionPower"] >= 3 else 2
		var motion_label: String = "three times" if attack_count == 3 else "twice"
		combat["log"].append("Motion powder — you move %s as fast." % motion_label)

	var enemy: Dictionary = combat["enemy"]
	for i in range(attack_count):
		if enemy["hp"] <= 0:
			break
		var atk := get_attack_range()
		var dmg: int = Rng.randi_range(atk["min"], atk["max"])
		enemy["hp"] = maxi(0, enemy["hp"] - dmg)
		var frozen_note: String = " (enemy frozen)" if combat["frozenTurns"] > 0 else ""
		var hit_label: String = " (hit %d)" % (i + 1) if attack_count > 1 else ""
		combat["log"].append("You attack%s — %d damage%s. Enemy: %d/%d HP." % [hit_label, dmg, frozen_note, enemy["hp"], enemy["hpMax"]])
		if enemy["hp"] <= 0:
			combat["outcome"] = "win"
			combat["log"].append("They leg it. Good call on their part." if NON_LETHAL_MUGGING_CONTEXTS.has(combat["context"]) else "They go down. Vein is yours.")
			_dispatch_on_win()
			EventBus.state_changed.emit()
			return { "ok": true, "outcome": "win" }

	if combat["motionTurns"] > 0:
		combat["motionTurns"] -= 1
		if combat["motionTurns"] == 0:
			combat["log"].append("The powder wears off. Back to normal speed.")

	if combat["frozenTurns"] > 0:
		combat["frozenTurns"] -= 1
		if combat["frozenTurns"] == 0:
			combat["log"].append("The time effect wears off. They're coming back round.")
	else:
		enemy_attack()

	EventBus.state_changed.emit()
	return { "ok": true, "outcome": combat["outcome"] }


static func enemy_attack() -> void:
	var combat: Dictionary = GameState.state["combat"]
	if combat["outcome"] != null or combat["frozenTurns"] > 0:
		return

	var enemy: Dictionary = combat["enemy"]

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

	var dmg: int = Rng.randi_range(enemy["attackMin"], enemy["attackMax"])
	var player: Dictionary = GameState.state["player"]
	player["hp"] = maxi(0, player["hp"] - dmg)
	combat["log"].append("%s hits you for %d. You: %d/%d HP." % [enemy["name"], dmg, player["hp"], player["hpMax"]])
	if player["hp"] <= 0:
		combat["outcome"] = "loss"
		combat["log"].append("You're done. You come round somewhere unpleasant.")
		player["hp"] = GameState.round_epsilon(player["hpMax"] * 0.3)


static func flee() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }

	if Rng.chance(0.65):
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
	if player["inventory"]["timePearl"] <= 0:
		return { "ok": false, "reason": "No time pearls." }
	if combat["frozenTurns"] > 0:
		combat["log"].append("Already frozen. Save the pearl.")
		EventBus.state_changed.emit()
		return { "ok": false, "reason": "Already frozen." }

	player["inventory"]["timePearl"] -= 1
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
	if player["inventory"]["enhancementPowder"] <= 0:
		return { "ok": false, "reason": "No enhancement powder." }
	if combat["motionTurns"] > 0:
		combat["log"].append("Already moving fast. Wait for it to wear off.")
		EventBus.state_changed.emit()
		return { "ok": false, "reason": "Already moving fast." }

	player["inventory"]["enhancementPowder"] -= 1
	var power = Crafting.effect_power("enhancementPowder", player["craftingSkill"])
	combat["motionPower"] = power
	combat["motionTurns"] = 2 if power >= 3 else 1
	combat["log"].append("You rub the powder in. The world slows slightly around you. You feel very fast.")
	EventBus.state_changed.emit()
	return { "ok": true }


# Equipped non-rewind device (freeze/motion effect). Rewind devices are
# used via combat_rewind(), not this.
static func use_device() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["outcome"] != null:
		return { "ok": false, "reason": "Combat not active." }

	var player: Dictionary = GameState.state["player"]
	var device_id = player["equipment"]["device"]
	if device_id == null:
		return { "ok": false, "reason": "No device equipped." }

	var device = null
	for d in player["devicesCompleted"]:
		if d["id"] == device_id:
			device = d
			break
	if device == null:
		return { "ok": false, "reason": "Device not found." }

	var dt: Dictionary = GameData.DEVICES[device["type"]]
	if dt["effect"] == "rewind":
		return { "ok": false, "reason": "Use Rewind for a rewind device." }

	var activation := Devices.activate(device_id)
	if not activation["ok"]:
		return activation

	if dt["effect"] == "freeze":
		var power = Crafting.effect_power("timePearl", player["craftingSkill"])
		combat["frozenTurns"] += power
		var turn_word: String = "turn" if power == 1 else "turns"
		combat["log"].append("You activate the %s. Enemy frozen for %d %s." % [dt["name"], power, turn_word])
	elif dt["effect"] == "motion":
		var power = Crafting.effect_power("enhancementPowder", player["craftingSkill"])
		combat["motionTurns"] += 2
		combat["motionPower"] = power
		combat["log"].append("You activate the %s. Movement accelerated." % dt["name"])

	EventBus.state_changed.emit()
	return { "ok": true }


static func combat_rewind() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	if not combat["active"] or combat["snapshots"].is_empty():
		return { "ok": false, "reason": "Nothing to rewind." }

	var player: Dictionary = GameState.state["player"]
	var has_consumable: bool = player["inventory"]["rewind"] > 0
	var rewind_device = _find_equipped_rewind_device_with_charge()
	var has_device: bool = rewind_device != null

	if not has_consumable and not has_device:
		return { "ok": false, "reason": "No rewind available." }

	if has_consumable:
		player["inventory"]["rewind"] -= 1
	else:
		Devices.activate(rewind_device["id"])

	var snap: Dictionary = Snapshots.oldest(combat["snapshots"])
	Snapshots.clear(combat["snapshots"])

	player["hp"] = snap["playerHp"]
	combat["enemy"]["hp"] = snap["enemyHp"]
	var new_log: Array = snap["log"].duplicate()
	new_log.append("⟲ Time unspools. The moment resets. Only you remember.")
	combat["log"] = new_log
	combat["frozenTurns"] = snap["frozenTurns"]
	combat["motionTurns"] = snap["motionTurns"]
	combat["motionPower"] = snap["motionPower"]
	combat["outcome"] = null
	combat["evadeTurns"] = 2
	combat["evadeChance"] = 0.50

	EventBus.state_changed.emit()
	return { "ok": true }


static func _find_equipped_rewind_device_with_charge() -> Variant:
	var player: Dictionary = GameState.state["player"]
	var device_id = player["equipment"]["device"]
	if device_id == null:
		return null
	for d in player["devicesCompleted"]:
		if d["id"] == device_id:
			var dt: Dictionary = GameData.DEVICES[d["type"]]
			if dt["effect"] == "rewind" and d["chargesUsedToday"] < d["chargesPerDay"]:
				return d
			return null
	return null


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
# otherwise inventory on a raid win, home in every other case (loss/fled/
# mugging-loss-that-somehow-exits). Each branch below is a private helper
# (hygiene ticket 02) -- this func just tears down shared state and dispatches.
static func exit_combat() -> Dictionary:
	var combat: Dictionary = GameState.state["combat"]
	var outcome = combat["outcome"]
	var context: String = combat["context"]

	GameState.state["combat"] = {
		"active": false, "context": CONTEXT_RAID, "veinId": null, "enemy": null, "log": [],
		"outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": null, "snapshots": [],
	}
	SaveManager.autosave()  # R§6: autosave on combat exit

	if context == CONTEXT_MUGGING and outcome == "win":
		return _exit_mugging_win()
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


# event_mugging (D5): state.event is still active regardless of outcome
# — route back to the event screen so its scripted cards can resume.
static func _exit_event_mugging() -> Dictionary:
	GameState.state["currentScreen"] = "event"
	EventBus.screen_changed.emit("event")
	return { "nextScreen": "event" }


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
	GameState.state["currentScreen"] = "home"
	EventBus.screen_changed.emit("home")
	return { "nextScreen": "home" }


# defend_vein (vein-raiding ticket 07): Raiding owns the win/loss
# consequence (nothing on a win, the same whole-vein-loss transfer as the
# no-alarm path on a loss) -- this just tells it which happened, then
# routes home either way, same as every other non-raid context below.
static func _exit_defend_vein(outcome) -> Dictionary:
	Raiding.resolve_defend_outcome(outcome == "win")
	GameState.state["currentScreen"] = "home"
	EventBus.screen_changed.emit("home")
	return { "nextScreen": "home" }


static func _exit_default(outcome, context: String) -> Dictionary:
	var next_screen: String = "inventory" if (outcome == "win" and context == CONTEXT_RAID) else "home"
	GameState.state["currentScreen"] = next_screen
	EventBus.screen_changed.emit(next_screen)
	return { "nextScreen": next_screen }


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
		Notify.push("The raider took %d units of ore before fleeing." % lost)
