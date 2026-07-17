class_name Jobs
extends RefCounted

# James jobs per R§3.10 + §1.11 trust bands. Static funcs only. Unlocked
# by jamesMotionEventSeen (a UI-gating concern for T12, same as other
# unlockFlag-style flags — not re-enforced here).


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

	return {
		"recipeKey": recipe_key,
		"recipeName": recipe["name"],
		"symbol": recipe["symbol"],
		"qty": qty,
		"payPerItem": pay_per_item,
		"totalPay": pay_per_item * qty,
	}


static func offer_job() -> Dictionary:
	if GameState.state["flags"]["jamesJobActive"]:
		return { "ok": false, "reason": "A job is already active." }
	var job := generate_james_job()
	GameState.state["jamesJob"] = job
	GameState.state["flags"]["jamesJobActive"] = true
	EventBus.state_changed.emit()
	return { "ok": true, "job": job }


static func accept_job() -> Dictionary:
	var job = GameState.state["jamesJob"]
	if job == null:
		return { "ok": false, "reason": "No active job." }
	Notify.push("James wants %d× %s. Pay: £%d." % [job["qty"], job["recipeName"], job["totalPay"]])
	EventBus.state_changed.emit()
	return { "ok": true }


static func fulfil_job() -> Dictionary:
	var job = GameState.state["jamesJob"]
	if job == null:
		return { "ok": false, "reason": "No active job." }

	var inventory: Dictionary = GameState.state["player"]["inventory"]
	var have: int = inventory.get(job["recipeKey"], 0)
	if have < job["qty"]:
		return { "ok": false, "reason": "Not enough on hand.", "have": have, "need": job["qty"] }

	inventory[job["recipeKey"]] = have - job["qty"]
	GameState.state["player"]["cash"] += job["totalPay"]
	Contacts.award_relation("james", 5)
	GameState.state["flags"]["jamesJobActive"] = false
	GameState.state["jamesJob"] = null

	EventBus.state_changed.emit()
	return { "ok": true, "earned": job["totalPay"] }
