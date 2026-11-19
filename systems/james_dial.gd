class_name JamesDial
extends RefCounted

# James's Dial chain (data/dial.json jamesQuest): each morning queues the next
# James summons whose gate is met, once each. evaluation -> repair -> offer ->
# player Dial creation. The evaluation fixes the repair's calc quote
# (flags.jamesDialCalcQty / jamesDialAttemptCost); the repair's pending payload
# carries calcPay, re-priced each morning so it matches sell_ore_at_market.

const EVALUATION := "james_dial_evaluation"
const REPAIR := "james_dial_repair"
const OFFER := "james_dial_offer"
const PLAYER_DIAL := "james_player_dial_creation"


static func daily_tick() -> void:
	maybe_queue_evaluation()
	maybe_queue_repair()
	refresh_repair_pay()
	_maybe_queue_after(OFFER, "jamesDialOfferQueued", "jamesDialRestored")
	_maybe_queue_after(PLAYER_DIAL, "jamesPlayerDialQueued", "jamesDialOfferSeen")


static func maybe_queue_evaluation() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("jamesDialEvaluationQueued", false) or not flags.get("jamesExperimentSeen", false):
		return false
	var skill := int(GameState.state["player"]["craftingSkill"])
	if skill < int(_quest()["minCraftingSkill"]):
		return false
	var attempt_cost := Dial.movement_calc_cost("recharge", skill)
	var calc_qty := attempt_cost * int(_quest()["repairAttempts"])
	flags["jamesDialEvaluationQueued"] = true
	flags["jamesDialAttemptCost"] = attempt_cost
	flags["jamesDialCalcQty"] = calc_qty
	Messages.queue_pending("james", EVALUATION, _text(EVALUATION), { "attemptCost": attempt_cost, "calcQty": calc_qty })
	return true


static func maybe_queue_repair() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("jamesDialRepairQueued", false) or not flags.get("jamesDialRepairRequested", false):
		return false
	var calc_qty := int(flags.get("jamesDialCalcQty", 0))
	if Stash.player_ore_qty(str(_quest()["repairOreType"])) < calc_qty:
		return false
	flags["jamesDialRepairQueued"] = true
	Messages.queue_pending("james", REPAIR, _text(REPAIR), repair_payload())
	return true


static func repair_payload() -> Dictionary:
	var flags: Dictionary = GameState.state["flags"]
	var calc_qty := int(flags.get("jamesDialCalcQty", 0))
	var ore_type := str(_quest()["repairOreType"])
	return {
		"calcQty": calc_qty,
		"attemptCost": int(flags.get("jamesDialAttemptCost", 0)),
		"calcPay": Market.line_total("ore", Market.quote("ore", ore_type), calc_qty),
	}


# Today's price for any still-pending repair summons.
static func refresh_repair_pay() -> void:
	for entry in GameState.state["pendingMessages"]:
		if entry["kind"] == REPAIR:
			entry["payload"] = repair_payload()


static func _maybe_queue_after(event_id: String, queued_flag: String, after_flag: String) -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get(queued_flag, false) or not flags.get(after_flag, false):
		return false
	flags[queued_flag] = true
	Messages.queue_pending("james", event_id, _text(event_id))
	return true


static func _quest() -> Dictionary:
	return GameData.DIAL_JAMES_QUEST


static func _text(event_id: String) -> String:
	return str(_quest()["texts"][event_id])
