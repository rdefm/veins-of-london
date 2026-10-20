class_name Sparring
extends RefCounted

# The calc gym's Spar (R§3.7b Spar): a practice round fight against an
# easy / even / hard partner scaled to the player's Combat Skill, fought with
# a free, unlimited Rewind. Nothing carries out of it but Combat XP: hp,
# loadout units and the Dial come back as they stood. The data is
# GameData.COMBAT_ROUNDS["spar"].
#
# state.flags.sparSessions counts sessions taken; the first `freeSessions`
# cost no £.


static func config() -> Dictionary:
	return GameData.COMBAT_ROUNDS["spar"]


static func line(key: String) -> String:
	return str(config()["lines"][key])


static func is_unlocked() -> bool:
	return bool(GameState.state["flags"].get(config()["unlockFlag"], false))


static func sessions_taken() -> int:
	return int(GameState.state["flags"].get("sparSessions", 0))


static func free_sessions_left() -> int:
	return maxi(0, int(config()["freeSessions"]) - sessions_taken())


# The £ the next session costs: 0 while free sessions remain.
static func next_fee() -> int:
	return 0 if free_sessions_left() > 0 else int(config()["fee"])


static func partner(partner_id: String) -> Dictionary:
	for entry in config()["partners"]:
		if entry["id"] == partner_id:
			return entry
	return {}


# The partner's level for a player of Combat Skill `skill`.
static func partner_level(entry: Dictionary, skill: int) -> int:
	return clampi(skill + int(entry["levelDelta"]), 1, CombatRounds.level_max())


# Why a session with `partner_id` can't start now, or "".
static func block_reason(partner_id: String) -> String:
	if not is_unlocked():
		return line("locked")
	if partner(partner_id).is_empty():
		return "No such partner."
	if GameState.state["combat"]["active"]:
		return "Already in a fight."
	if TimeSystem.is_time_exhausted():
		return line("noTime")
	if int(GameState.state["player"]["cash"]) < next_fee():
		return line("cantPay")
	return ""


# Spends a time block (and the fee once the free sessions are gone) and opens
# the fight. Returns { ok } or { ok: false, reason }.
static func spar(partner_id: String) -> Dictionary:
	var reason := block_reason(partner_id)
	if reason != "":
		return { "ok": false, "reason": reason }
	var player: Dictionary = GameState.state["player"]
	var entry := partner(partner_id)
	var fee := next_fee()
	player["cash"] -= fee
	GameState.state["flags"]["sparSessions"] = sessions_taken() + 1
	TimeSystem.advance_time_block()
	var level := partner_level(entry, int(player["combatSkill"]))
	var foe := {
		"name": str(entry["name"]), "hp": int(entry["hpMax"]), "hpMax": int(entry["hpMax"]),
		"attackMin": int(entry["attackMin"]), "attackMax": int(entry["attackMax"]),
		"speed": int(entry["speed"]), "level": level,
		"archetype": Combat.MUGGER_ARCHETYPE, "isMugging": false, "weapon": null, "ability": null,
	}
	Combat.start_spar_fight(foe, {
		"hpBefore": int(player["hp"]), "hpMaxBefore": int(player["hpMax"]),
		"slotsBefore": player["loadout"]["slots"].duplicate(true),
		"dialBefore": player["dial"].duplicate(true) if player["dial"] is Dictionary else null,
		"rewindRounds": int(config()["rewindRounds"]),
	})
	return { "ok": true }


# The Combat XP a spar ending in `outcome` earns.
static func xp_for(outcome) -> int:
	var xp := int(config()["xpBase"])
	if outcome == "win":
		xp += int(config()["xpWinBonus"])
	return xp


# Ends a spar (from Combat.exit_combat()): the XP, then hp, loadout units and
# the Dial back as they were before it. A level-up's hp gain is kept.
static func settle(spar_block: Dictionary, outcome) -> void:
	var player: Dictionary = GameState.state["player"]
	Combat.award_xp(xp_for(outcome))
	var hp_gain: int = int(player["hpMax"]) - int(spar_block["hpMaxBefore"])
	player["hp"] = mini(int(spar_block["hpBefore"]) + hp_gain, int(player["hpMax"]))
	player["loadout"]["slots"] = spar_block["slotsBefore"].duplicate(true)
	if spar_block["dialBefore"] is Dictionary:
		player["dial"] = spar_block["dialBefore"].duplicate(true)
