class_name Consumables
extends RefCounted

# The two out-of-combat healing uses: healingSalve (a 2-day heal-over-time
# timer TimeSystem.daily_tick() ticks down) and healingBurst (an instant
# heal).


# Refreshes rather than stacks: using a second salve while one is already
# active resets the timer to 2 days at the new activation's daily amount.
static func use_healing_salve() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("healingSalve") <= 0:
		return { "ok": false, "reason": "No healing salve." }

	var power = Crafting.use_one("healingSalve")
	player["healingSalveDaysLeft"] = 2
	player["healingSalveDailyAmount"] = power
	# PROSE-REVIEW: new salve-activation notification, drafted against CONTENT-GUIDE.md's tone bible.
	Notify.push("Salve applied. Healing %s HP a day for 2 days." % str(power), Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	return { "ok": true }


# Out of combat (a fight's items play through its loadout, R§3.7b): heals
# the player off shared inventory.
static func use_healing_burst() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	if Crafting.inventory_qty("healingBurst") <= 0:
		return { "ok": false, "reason": "No healing burst." }
	var power = Crafting.use_one("healingBurst")
	var old_hp: int = player["hp"]
	player["hp"] = mini(player["hp"] + power, player["hpMax"])
	var healed: int = player["hp"] - old_hp
	# PROSE-REVIEW: new healing-burst result line, drafted against CONTENT-GUIDE.md's tone bible.
	Notify.push("You down a healing burst — +%d HP. %d/%d HP." % [healed, player["hp"], player["hpMax"]], Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	return { "ok": true }
