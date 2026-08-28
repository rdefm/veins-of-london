class_name Dial
extends RefCounted

# The Dial device mechanic, ticket 01: state shape, gift gate, and seeding.
# Static funcs only, same discipline as sites.gd/crafting.gd. Per
# .scratch/dial-device/spec.md -- this ticket only seeds an inert Dial (no
# Movement, no charge, no regen); Movement crafting/attunement (ticket 02)
# and onward own everything else the seeded shape leaves at zero/null.
#
# systems/devices.gd and data/devices.json stay live and untouched until
# ticket 07's cutover -- this module doesn't call into them and they don't
# call into this one.


static func seed_success_chance() -> float:
	var player: Dictionary = GameState.state["player"]
	# The "craftChance-style term": same shape as Crafting.craft_chance()
	# (baseSuccess + skill ramp + workshop bonus), but seeding has no
	# recipeKey to key a baseSuccess off of, so GameData.DIAL_SEED_BASE_
	# SUCCESS stands in for r.baseSuccess.
	var craft_term: float = min(0.95, GameData.DIAL_SEED_BASE_SUCCESS + (player["craftingSkill"] - 1) * 0.13 + Home.get_workshop_bonus())
	# The "cultChance-style term": Cultivating's own existing formula,
	# called directly -- reused, not reimplemented.
	var cult_term: float = Cultivating.get_cult_chance(player["cultivatingSkill"])
	return clampf((craft_term + cult_term) / 2.0, 0.05, 0.95)


# Single-roll risk model, same shape as Sites.attempt_seed: pay the full
# mixed five-ore-type cost, roll once, fail = cost gone, no partial state.
# Refused outright once player.dial is already non-null (no second Dial,
# ever) or the gift flag isn't set.
static func attempt_seed(haft_id: String) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] != null:
		return { "ok": false, "reason": "You already have a Dial." }
	if not GameState.state["flags"].get("dialGiftGranted", false):
		return { "ok": false, "reason": "You don't have the gift." }
	if not GameData.DIAL_HAFTS.has(haft_id):
		return { "ok": false, "reason": "Unknown haft." }

	var cost: Dictionary = GameData.DIAL_SEED_COST
	var orichalchum: Dictionary = player["orichalchum"]
	for ore_type in cost:
		if orichalchum.get(ore_type, 0) < cost[ore_type]:
			return { "ok": false, "reason": "Not enough calc." }

	# Deducted regardless of outcome -- the risk is real.
	for ore_type in cost:
		orichalchum[ore_type] = orichalchum.get(ore_type, 0) - cost[ore_type]

	var success: bool = Rng.chance(seed_success_chance())
	if success:
		player["dial"] = _new_dial(haft_id)

	EventBus.state_changed.emit()
	return { "ok": true, "success": success }


# Implementation Decisions, "Hafts": a trivial field write, no validation
# beyond "haft exists" -- there is no minimum-barrel-length check to
# implement (every whitelisted haft satisfies it by construction).
static func set_haft(haft_id: String) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if player["dial"] == null:
		return { "ok": false, "reason": "No Dial." }
	if not GameData.DIAL_HAFTS.has(haft_id):
		return { "ok": false, "reason": "Unknown haft." }

	player["dial"]["haftId"] = haft_id
	EventBus.state_changed.emit()
	return { "ok": true }


# Fully inert: no Movement seated, zero charge/regen/capacity. Later
# tickets (02 seats a Movement and gives the charge economy its real
# numbers; 06 gives level/xp their real growth curve) grow this from here,
# not this ticket.
static func _new_dial(haft_id: String) -> Dictionary:
	return {
		"level": 1,
		"xp": 0,
		"currentCharge": 0,
		"maxCharge": 0,
		"rechargeRate": 0,
		"capacityMax": 0,
		"movement": null,
		"loadedComplications": [],
		"haftId": haft_id,
	}
