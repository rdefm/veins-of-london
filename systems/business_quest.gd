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

const OWEN_INTRO_KIND := "biz_a1_owen"
# PROSE-REVIEW: James's Beat 3 summons.
const OWEN_INTRO_TEXT := "Three orders, delivered in full. Come to the unit. There is someone you should meet, and I would rather not explain him twice."

const PARTNERSHIP_KIND := "biz_a1_partnership"
# PROSE-REVIEW: James's Beat 5 summons.
const PARTNERSHIP_TEXT := "Owen has made level two, and I hear you have put a workshop in. Come to the unit. I have something to say and I will only say it once."


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


# Beat 3: once Beat 2 is met (by any source), James texts the Owen
# introduction. Called after contract settlement, event completion and at
# rollover; bizA1OwenIntroQueued blocks re-firing permanently.
static func maybe_trigger_owen_intro() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("bizA1OwenIntroQueued", false) or not flags.get("bizA1MarketProven", false):
		return false
	flags["bizA1OwenIntroQueued"] = true
	Messages.queue_pending("james", OWEN_INTRO_KIND, OWEN_INTRO_TEXT)
	Objectives.refresh()
	return true


# Beat 5: once Beat 4 (Owen's level + a Workshop, both live) is met, James
# texts the partnership summons. Refreshes objectives first, since Owen's
# level-up and a room build are not otherwise objective boundaries. Called
# after every staff block, a room build, event completion and at rollover;
# bizA1PartnershipQueued blocks re-firing permanently.
static func maybe_trigger_partnership() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("bizA1PartnershipQueued", false) or not flags.get("bizA1OwenJoined", false):
		return false
	Objectives.refresh()
	if not flags.get("bizA1ApprenticeReady", false):
		return false
	flags["bizA1PartnershipQueued"] = true
	Messages.queue_pending("james", PARTNERSHIP_KIND, PARTNERSHIP_TEXT)
	Objectives.refresh()
	return true


# Beat 5 scene: James's crafting skill becomes constants.json
# business.jamesJoinCraftingSkill, with XP raised to that level's threshold
# so later XP levels him from there. Idempotent.
static func set_james_crafting_skill() -> void:
	var james: Dictionary = GameState.state["contacts"]["james"]
	var level: int = GameData.BUSINESS_JAMES_JOIN_CRAFTING_SKILL
	james["craftingSkill"] = level
	james["craftingXP"] = maxi(int(james["craftingXP"]), int(GameData.CRAFTING_XP_LEVELS[level]))


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
