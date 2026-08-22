class_name Jobs
extends RefCounted

# James jobs per R§3.10 + §1.11 trust bands. Static funcs only. Unlocked
# by jamesMotionEventSeen (a UI-gating concern for T12, same as other
# unlockFlag-style flags — not re-enforced here).
#
# bugfixes-30: James offers jobs proactively (roll_daily_offer(), called
# from time_system.gd's daily tick) — there is no player-initiated "ask for
# work" anymore. Two job types share the jamesJob/jamesJobActive lifecycle,
# distinguished by job["type"]:
#   "flatPay" — spend a time block, get paid FLAT_PAY_AMOUNT flat. No
#     deadline (ticket only asked for one on the craft type).
#   "craft"   — the original generate_james_job() qty/recipe job, now with
#     a byDay deadline (DEADLINE_DAYS_PER_QTY per unit ordered), enforced
#     by expire_overdue_job() (also called from the daily tick).
# jamesJobAccepted tracks accept vs. still-just-offered, separately from
# jamesJobActive — needed now that an offer can sit unseen for a day or
# more before the player opens it (previously offer_job() opened the modal
# synchronously, so "active" and "offered-but-undecided" were the same
# instant).

const FLAT_PAY_AMOUNT := 300
const FLAT_PAY_LOW_CASH_THRESHOLD := 100
const FLAT_PAY_BASE_CHANCE := 0.15
const CRAFT_OFFER_CHANCE := 0.15
const DEADLINE_DAYS_PER_QTY := 2
const MISSED_DEADLINE_RELATION_PENALTY := -5


static func generate_james_job() -> Dictionary:
	var trust: int = GameState.state["contacts"]["james"]["relation"]
	var recipe_pool: Array[String] = ["timePearl"]
	if GameState.state["flags"]["enhancementUnlocked"]:
		recipe_pool.append("enhancementPowder")
	var recipe_key: String = Rng.rand_from(recipe_pool)
	var recipe: Dictionary = GameData.RECIPES[recipe_key]

	var min_qty: int
	var max_qty: int
	if trust <= 1:
		min_qty = 1
		max_qty = 3
	elif trust <= 3:
		min_qty = 3
		max_qty = 6
	else:
		min_qty = 5
		max_qty = 10

	var qty: int = Rng.randi_range(min_qty, max_qty)
	var pay_per_item: int = GameData.CONSUMABLE_PRICES[recipe_key]
	var day: int = GameState.state["world"]["day"]

	return {
		"type": "craft",
		"recipeKey": recipe_key,
		"recipeName": recipe["name"],
		"symbol": recipe["symbol"],
		"qty": qty,
		"payPerItem": pay_per_item,
		"totalPay": pay_per_item * qty,
		"byDay": day + qty * DEADLINE_DAYS_PER_QTY,
	}


static func generate_flat_pay_job() -> Dictionary:
	return { "type": "flatPay", "pay": FLAT_PAY_AMOUNT }


# Called from time_system.gd's daily_tick. Sequential roll, one offer max
# per day: type-1 (flat pay) first, its chance scaling to 100% once the
# player is nearly broke; type-2 (craft) only gets a roll if type-1 misses.
static func roll_daily_offer() -> void:
	if GameState.state["flags"]["jamesJobActive"]:
		return

	var cash: int = GameState.state["player"]["cash"]
	var flat_pay_chance: float = 1.0 if cash <= FLAT_PAY_LOW_CASH_THRESHOLD else FLAT_PAY_BASE_CHANCE
	if Rng.chance(flat_pay_chance):
		_set_offered_job(generate_flat_pay_job())
		return

	if Rng.chance(CRAFT_OFFER_CHANCE):
		_set_offered_job(generate_james_job())


static func _set_offered_job(job: Dictionary) -> void:
	GameState.state["jamesJob"] = job
	GameState.state["flags"]["jamesJobActive"] = true
	GameState.state["flags"]["jamesJobAccepted"] = false
	# PROSE-REVIEW: new daily-tick offer notification, drafted against CONTENT-GUIDE.md's tone bible.
	Notify.push("James has work going. Check Contacts.")
	EventBus.state_changed.emit()


static func decline_job() -> void:
	GameState.state["flags"]["jamesJobActive"] = false
	GameState.state["flags"]["jamesJobAccepted"] = false
	GameState.state["jamesJob"] = null
	EventBus.state_changed.emit()


static func accept_job() -> Dictionary:
	var job = GameState.state["jamesJob"]
	if job == null:
		return { "ok": false, "reason": "No active job." }

	GameState.state["flags"]["jamesJobAccepted"] = true
	if job["type"] == "flatPay":
		# PROSE-REVIEW: new accept notification for the flatPay job type, drafted against CONTENT-GUIDE.md's tone bible.
		Notify.push("James wants a hand for an afternoon. Pay: £%d." % job["pay"])
	else:
		Notify.push("James wants %d× %s. Pay: £%d." % [job["qty"], job["recipeName"], job["totalPay"]])
	EventBus.state_changed.emit()
	return { "ok": true }


static func fulfil_job() -> Dictionary:
	var job = GameState.state["jamesJob"]
	if job == null:
		return { "ok": false, "reason": "No active job." }

	if job["type"] == "flatPay":
		return _fulfil_flat_pay_job(job)
	return _fulfil_craft_job(job)


static func _fulfil_flat_pay_job(job: Dictionary) -> Dictionary:
	if TimeSystem.is_time_exhausted():
		return { "ok": false, "reason": "No time blocks left today." }

	# jamesJobActive/jamesJob/jamesJobAccepted must clear BEFORE
	# advance_time_block(): consuming the day's last block recurses into
	# daily_tick() -> Jobs.roll_daily_offer() same call, whose "one active
	# job at a time" guard would otherwise still see this (already-paid-out)
	# job as active and starve the new day's fresh offer roll.
	GameState.state["player"]["cash"] += job["pay"]
	Bank.record(job["pay"], "James job")
	Contacts.award_relation("james", 5)
	GameState.state["flags"]["jamesJobActive"] = false
	GameState.state["flags"]["jamesJobAccepted"] = false
	GameState.state["jamesJob"] = null
	TimeSystem.advance_time_block()

	Modal.open("james_job_complete", { "earned": job["pay"] })
	return { "ok": true, "earned": job["pay"] }


static func _fulfil_craft_job(job: Dictionary) -> Dictionary:
	var have: int = Crafting.inventory_qty(job["recipeKey"])
	if have < job["qty"]:
		Modal.open("james_job_short", { "job": job, "have": have })
		return { "ok": false, "reason": "Not enough on hand.", "have": have, "need": job["qty"] }

	Crafting.inventory_remove(job["recipeKey"], job["qty"])
	GameState.state["player"]["cash"] += job["totalPay"]
	Bank.record(job["totalPay"], "James job")
	Contacts.award_relation("james", 5)
	GameState.state["flags"]["jamesJobActive"] = false
	GameState.state["flags"]["jamesJobAccepted"] = false
	GameState.state["jamesJob"] = null

	Modal.open("james_job_complete", { "earned": job["totalPay"] })
	return { "ok": true, "earned": job["totalPay"] }


# Called from time_system.gd's daily_tick, after the day counter has
# advanced — a craft job whose byDay has now passed expires unfulfilled.
# Declining a job never costs relation (an active decision the player took
# deliberately); missing the deadline does, since the player let it lapse.
static func expire_overdue_job() -> void:
	var job = GameState.state["jamesJob"]
	if job == null or job["type"] != "craft":
		return
	if GameState.state["world"]["day"] <= job["byDay"]:
		return

	GameState.state["flags"]["jamesJobActive"] = false
	GameState.state["flags"]["jamesJobAccepted"] = false
	GameState.state["jamesJob"] = null
	Contacts.award_relation("james", MISSED_DEADLINE_RELATION_PENALTY)
	# PROSE-REVIEW: new missed-deadline notification, drafted against CONTENT-GUIDE.md's tone bible.
	Notify.push("James gave up waiting on his %s order. Not impressed." % job["recipeName"], Notify.CATEGORY_WARNING)
