class_name Consumables
extends RefCounted

# calc-effect-wiring-02: the two healing effects that aren't gated to an
# active fight. healingSalve is strictly out-of-combat (a 2-day
# heal-over-time timer TimeSystem.daily_tick() ticks down); healingBurst
# works in or out of combat, so it lives here rather than in Combat, and
# writes its result line to the combat log when a fight is active or pushes
# a Notify otherwise. Static funcs only.


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


static func use_healing_burst() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("healingBurst") <= 0:
		return { "ok": false, "reason": "No healing burst." }

	Crafting.inventory_remove("healingBurst", 1)
	var power = Crafting.effect_power("healingBurst", player["craftingSkill"])
	var old_hp: int = player["hp"]
	player["hp"] = mini(player["hp"] + power, player["hpMax"])
	var healed: int = player["hp"] - old_hp
	# PROSE-REVIEW: new healing-burst result line, drafted against CONTENT-GUIDE.md's tone bible.
	var line := "You down a healing burst — +%d HP. %d/%d HP." % [healed, player["hp"], player["hpMax"]]

	var combat: Dictionary = GameState.state["combat"]
	if combat["active"]:
		combat["log"].append(line)
	else:
		Notify.push(line, Notify.CATEGORY_SUCCESS)

	EventBus.state_changed.emit()
	return { "ok": true }
