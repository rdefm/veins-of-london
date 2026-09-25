class_name BusinessQuest
extends RefCounted

# The business_empire questline's triggers and Archie's starter-offer chain
# (biz-act1 spec §"Questline and objectives", §"Starter and recurring offer
# catalogue"). Beats themselves are data/objectives.json entries evaluated by
# Objectives.refresh(); this owns only the side effects around them. Static
# funcs only, pure read/write over GameState.state.

const PROPOSITION_KIND := "biz_a1_proposition"
const MIN_VEINS := 2
const STARTER_TEMPLATES := ["biz_starter_1", "biz_starter_2", "biz_starter_3"]

# PROSE-REVIEW: Archie's proposition text.
const PROPOSITION_TEXT := "\"Two veins. That's not a hobby any more, that's supply. Come to James's — I'll explain there.\""


# Beat 1: two or more veins and Archie recruited, whatever the Collective
# progress. Called after every vein-count change and from TimeSystem.
# daily_tick() as a backstop; bizA1Proposed blocks re-firing permanently.
static func maybe_trigger_proposition() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("bizA1Proposed", false):
		return false
	if not GameState.state["contacts"].get("archie", {}).get("recruited", false):
		return false
	if GameState.state["player"]["veins"].size() < MIN_VEINS:
		return false

	flags["bizA1Proposed"] = true
	Messages.queue_pending("archie", PROPOSITION_KIND, PROPOSITION_TEXT)
	Objectives.refresh()
	return true


# The chain runs from the Beat 1 scene until Beat 2 is met by any source.
static func starter_chain_active() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	return flags.get("bizA1PropositionSeen", false) and not flags.get("bizA1MarketProven", false)


static func is_starter(template_id: String) -> bool:
	return STARTER_TEMPLATES.has(template_id)


# Issues the current starter when none is outstanding and its reissue day
# has come. Called after the Beat 1 scene completes and at rollover (after
# offer expiry). A full pending list makes it wait for a later call.
static func maybe_issue_starter() -> bool:
	if not starter_chain_active() or _starter_outstanding():
		return false
	var chain: Dictionary = GameState.state["businessQuest"]
	var reissue_day: Variant = chain["starterReissueDay"]
	if reissue_day != null and int(GameState.state["world"]["day"]) < int(reissue_day):
		return false
	var template_id: String = STARTER_TEMPLATES[posmod(int(chain["starterIndex"]), STARTER_TEMPLATES.size())]
	var created := Offers.create_scripted_offer(template_id)
	if not created["ok"]:
		return false
	chain["starterReissueDay"] = null
	var nudge: String = GameData.OFFER_TEMPLATES[template_id].get("nudge", "")
	if nudge != "":
		Messages.append("archie", "them", nudge)
	return true


# A starter offer or contract closed today: the next one (or a reissue of
# this one, unless it settled complete) comes one day later.
static func note_starter_closed(template_id: String, completed: bool) -> void:
	if not is_starter(template_id):
		return
	var chain: Dictionary = GameState.state["businessQuest"]
	if completed:
		chain["starterIndex"] = int(chain["starterIndex"]) + 1
	chain["starterReissueDay"] = int(GameState.state["world"]["day"]) + 1


static func _starter_outstanding() -> bool:
	for offer in Offers.pending_offers():
		if is_starter(offer.get("templateId", "")):
			return true
	for contract in Offers.active_contracts():
		if is_starter(contract.get("templateId", "")):
			return true
	return false
