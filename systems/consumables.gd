class_name Consumables
extends RefCounted

# The two healing effects that aren't gated to an active fight. healingSalve
# is strictly out-of-combat (a 2-day heal-over-time timer TimeSystem.
# daily_tick() ticks down); healingBurst works in or out of combat, so it
# lives here rather than in Combat, writing to the combat log when a fight
# is active or pushing a Notify otherwise.


# Refreshes rather than stacks: using a second salve while one is already
# active resets the timer to 2 days at the new activation's daily amount.
static func use_healing_salve() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("healingSalve") <= 0:
		return { "ok": false, "reason": "No healing salve." }

	Crafting.inventory_remove("healingSalve", 1)
	var power = Crafting.effect_power("healingSalve", player["craftingSkill"])
	player["healingSalveDaysLeft"] = 2
	player["healingSalveDailyAmount"] = power
	# PROSE-REVIEW: new salve-activation notification, drafted against CONTENT-GUIDE.md's tone bible.
	Notify.push("Salve applied. Healing %s HP a day for 2 days." % str(power), Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	return { "ok": true }


# `target` is a combat.selection-shaped `{type, index}`; an ally target
# (in combat only) heals that ally instead of the player, R§3.7's
# ally-targetable table. Any other target heals the player.
static func use_healing_burst(target: Dictionary = {}) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("healingBurst") <= 0:
		return { "ok": false, "reason": "No healing burst." }

	var combat: Dictionary = GameState.state["combat"]
	var ally_index: int = -1
	if target.get("type", "") == "ally":
		ally_index = int(target.get("index", -1))
		if not combat["active"] or ally_index < 0 or ally_index >= combat["allies"].size() or combat["allies"][ally_index]["koed"]:
			return { "ok": false, "reason": "Invalid target." }
	var beats: Array = []
	# In-combat, this resolves the cursor's parked player-type entry same as
	# every other combat command (R§3.7a) -- a snapshot per use, engine runs
	# forward afterward. Out of combat there's no cursor to prime/conclude.
	if combat["active"]:
		if not Combat.prime_decision_point(combat, beats):
			EventBus.state_changed.emit()
			return { "ok": true, "beats": beats }
		Combat.push_combat_snapshot()

	Crafting.inventory_remove("healingBurst", 1)
	var power = Crafting.effect_power("healingBurst", player["craftingSkill"])
	var line: String
	var beat_extra := { "effectKey": "healingBurst" }
	if ally_index >= 0:
		var ally: Dictionary = combat["allies"][ally_index]
		var ally_healed: int = Combat.heal_ally(ally, int(power))
		# PROSE-REVIEW: ally-targeted healing-burst result line.
		line = "You get a healing burst into %s — +%d HP. %d/%d HP." % [ally["name"], ally_healed, ally["hp"], ally["hpMax"]]
		beat_extra["targetType"] = "ally"
		beat_extra["targetIndex"] = ally_index
	else:
		var old_hp: int = player["hp"]
		player["hp"] = mini(player["hp"] + power, player["hpMax"])
		var healed: int = player["hp"] - old_hp
		# PROSE-REVIEW: new healing-burst result line, drafted against CONTENT-GUIDE.md's tone bible.
		line = "You down a healing burst — +%d HP. %d/%d HP." % [healed, player["hp"], player["hpMax"]]

	if combat["active"]:
		# Routed through Combat.append_beat() (not a plain combat["log"].append())
		# so this in-combat use produces a beat the director can play through,
		# same as every other in-combat consumable.
		Combat.append_beat(combat, beats, line, Combat.BEAT_USE_HEALING_BURST, beat_extra)
		Combat.conclude_decision_point(combat, beats)
	else:
		Notify.push(line, Notify.CATEGORY_SUCCESS)

	EventBus.state_changed.emit()
	return { "ok": true, "beats": beats }
