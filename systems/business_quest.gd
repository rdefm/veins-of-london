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
# The Time Pearl order (from Beat 6), then the two ore orders the player picks
# from (from Beat 3).
const RECURRING_GUARANTEED := "biz_recurring_time_pearl"
const RECURRING_CHOICES := ["biz_recurring_time_ore", "biz_recurring_life_ore"]

# PROSE-REVIEW: Archie's proposition text.
const PROPOSITION_TEXT := "\"Two veins. That's not a hobby any more, that's supply. Come to James's — I'll explain there.\""

const OWEN_INTRO_KIND := "biz_a1_owen"
# PROSE-REVIEW: James's Beat 3 summons.
const OWEN_INTRO_TEXT := "Three orders, delivered in full. Come to the unit. There is someone you should meet, and I would rather not explain him twice."

const PARTNERSHIP_KIND := "biz_a1_partnership"
# PROSE-REVIEW: James's Beat 5 summons.
const PARTNERSHIP_TEXT := "Owen has made level two, and I hear you have put a workshop in. Come to the unit. I have something to say and I will only say it once."

const PRODUCTION_KIND := "biz_a1_production"
# PROSE-REVIEW: James's Beat 6 summons.
const PRODUCTION_TEXT := "You are on my books now, so you may as well see how I keep them. Come to the unit. Bring your phone."

const OWEN_CRAFT_KIND := "biz_owen_craft"
# PROSE-REVIEW: James's summons for Owen's crafting event.
const OWEN_CRAFT_TEXT := "Owen has been at my second bench. Come and see what he has made before I change my mind about letting him."

const CLOSING_KIND := "biz_a1_closing"
# PROSE-REVIEW: Archie's Beat 7 summons.
const CLOSING_TEXT := "\"Payday. Fifteen items sold and nobody held their hand. Come to the unit, I've got the numbers up.\""


# Beat 1: two or more of the player's own veins (Hakim's, at
# collective.hakimVeinId, never counts) and Archie recruited, whatever the
# Collective progress. Called after every vein-count change and from
# TimeSystem.daily_tick() as a backstop; bizA1Proposed blocks re-firing
# permanently.
static func maybe_trigger_proposition() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("bizA1Proposed", false):
		return false
	if not GameState.state["contacts"].get("archie", {}).get("recruited", false):
		return false
	if _own_vein_count() < MIN_VEINS:
		return false

	flags["bizA1Proposed"] = true
	Messages.queue_pending("archie", PROPOSITION_KIND, PROPOSITION_TEXT)
	Objectives.refresh()
	return true


static func _own_vein_count() -> int:
	var hakim_vein_id: Variant = GameState.state["collective"].get("hakimVeinId")
	var count := 0
	for vein in GameState.state["player"]["veins"]:
		if hakim_vein_id == null or vein["id"] != hakim_vein_id:
			count += 1
	return count


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


# Beat 6: once James has joined (Beat 5), James texts the Production
# summons. Called after event completion and at rollover;
# bizA1ProductionQueued blocks re-firing permanently.
static func maybe_trigger_production() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("bizA1ProductionQueued", false):
		return false
	if not flags.get("bizA1JamesJoined", false):
		return false
	flags["bizA1ProductionQueued"] = true
	Messages.queue_pending("james", PRODUCTION_KIND, PRODUCTION_TEXT)
	Objectives.refresh()
	return true


# Owen's crafting event (biz-act1 spec §"Owen's crafting event"): Owen
# cultivatingSkill ≥ 2, James recruited and a Workshop at home, all live.
# Not an Act 1 beat. Called after event completion and at rollover;
# bizOwenCraftQueued blocks re-firing permanently.
static func maybe_trigger_owen_craft() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("bizOwenCraftQueued", false):
		return false
	var contacts: Dictionary = GameState.state["contacts"]
	if int(contacts["owen"]["cultivatingSkill"]) < GameData.BUSINESS_OWEN_CRAFT_MIN_CULTIVATING:
		return false
	if not contacts["james"]["recruited"] or not GameState.state["home"]["rooms"].has("workshop"):
		return false
	flags["bizOwenCraftQueued"] = true
	Messages.queue_pending("james", OWEN_CRAFT_KIND, OWEN_CRAFT_TEXT)
	return true


# Archie's recurring offers: the two ore orders from Beat 3 (Owen joined),
# the Time Pearl order from the Beat 6 scene. All stop once the Beat 7
# closing is queued.
static func recurring_offer_active(template_id: String) -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("bizA1ClosingQueued", false):
		return false
	if template_id == RECURRING_GUARANTEED:
		return flags.get("bizA1ProductionSeen", false)
	if RECURRING_CHOICES.has(template_id):
		return flags.get("bizA1OwenJoined", false)
	return false


static func is_recurring_template(template_id: String) -> bool:
	return template_id == RECURRING_GUARANTEED or RECURRING_CHOICES.has(template_id)


# Issues each recurring offer that is active, not outstanding and whose
# reissue day has come. An ore choice is not reissued while either choice
# runs as a contract. A full pending list makes the rest wait for a later
# call. Called from the Beat 3 and Beat 6 scenes and at rollover (after
# offer expiry).
static func maybe_issue_recurring() -> void:
	var reissue := _recurring_reissue_days()
	var today: int = int(GameState.state["world"]["day"])
	var choice_running := false
	for contract in Offers.active_contracts():
		if RECURRING_CHOICES.has(contract.get("templateId", "")):
			choice_running = true
	for template_id in [RECURRING_GUARANTEED] + RECURRING_CHOICES:
		if not recurring_offer_active(template_id) or _template_outstanding(template_id):
			continue
		if RECURRING_CHOICES.has(template_id) and choice_running:
			continue
		if reissue.has(template_id) and today < int(reissue[template_id]):
			continue
		if not Offers.create_scripted_offer(template_id)["ok"]:
			return
		reissue.erase(template_id)


# A declined, expired or cancelled recurring offer is reissued one day
# later while it is active.
static func note_recurring_closed(template_id: String) -> void:
	if not recurring_offer_active(template_id):
		return
	_recurring_reissue_days()[template_id] = int(GameState.state["world"]["day"]) + 1


static func _recurring_reissue_days() -> Dictionary:
	var chain: Dictionary = GameState.state["businessQuest"]
	if not chain.has("recurringReissueDay"):
		chain["recurringReissueDay"] = {}
	return chain["recurringReissueDay"]


static func _template_outstanding(template_id: String) -> bool:
	for offer in Offers.pending_offers():
		if offer.get("templateId", "") == template_id:
			return true
	for contract in Offers.active_contracts():
		if contract.get("templateId", "") == template_id:
			return true
	return false


# Stamps the ledger length when Beat 6 is first seen met, so Beat 7 waits
# for the next payday record, the first to include its sales. Called after
# every settlement and from maybe_trigger_closing().
static func note_first_order_met() -> void:
	var chain: Dictionary = GameState.state["businessQuest"]
	if not GameState.state["flags"].get("bizA1FirstOrderDone", false) or chain.get("firstOrderLedgerSize") != null:
		return
	chain["firstOrderLedgerSize"] = GameState.state["business"]["ledger"].size()


# Beat 7: after Beat 6 is met and a payday has since been recorded, Archie
# texts the closing summons, carrying that record's numbers as the scene's
# context. Called at rollover after payday; bizA1ClosingQueued blocks
# re-firing permanently.
static func maybe_trigger_closing() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("bizA1ClosingQueued", false) or not flags.get("bizA1FirstOrderDone", false):
		return false
	note_first_order_met()
	var ledger: Array = GameState.state["business"]["ledger"]
	if ledger.size() <= int(GameState.state["businessQuest"]["firstOrderLedgerSize"]):
		return false
	flags["bizA1ClosingQueued"] = true
	Messages.queue_pending("archie", CLOSING_KIND, CLOSING_TEXT, closing_context(ledger.back()))
	Objectives.refresh()
	return true


# The Beat 7 scene's fill-ins, as display strings: the payday record's
# receipts, Owen's wage and the three shares.
static func closing_context(record: Dictionary) -> Dictionary:
	var wage := 0
	for expense in record["expenses"]:
		if expense["kind"] == "wage" and expense.get("contactId", "") == "owen":
			wage += int(expense["amount"])
	var shares: Dictionary = record["shares"]
	return {
		"receipts": "£%d" % int(record["receipts"]),
		"owenWage": "£%d" % wage,
		"playerShare": "£%d" % int(shares.get("player", 0)),
		"archieShare": "£%d" % int(shares.get("archie", 0)),
		"jamesShare": "£%d" % int(shares.get("james", 0)),
	}


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
