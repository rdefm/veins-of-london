class_name Hiring
extends RefCounted

# LodedInnit hiring (R§3.10 "Hiring"): the fixed candidate roster
# (data/hiring.json candidates), each candidate's market status and its
# rollover flips, hiring or poaching into a free role-room seat, and letting
# a hire go. The first week's wage is prepaid from the pot, then the float;
# player cash only reaches it through a float top-up the player agreed to.
# Static funcs only.

const STATUS_OPEN := "open"
const STATUS_EMPLOYED := "employed"
const STATUS_OURS := "ours"


# Fresh state.hiring (hiring-spec §9): every candidate open.
static func new_state() -> Dictionary:
	var status := {}
	for candidate_id in GameData.HIRING_CANDIDATES:
		status[candidate_id] = _open_status(0)
	return { "status": status, "poach": {}, "feed": [], "feedSeen": 0, "feedUsed": {} }


static func _open_status(day: int) -> Dictionary:
	return { "state": STATUS_OPEN, "employer": null, "since": day }


# Adds a status entry for any candidate the save predates.
static func backfill(hiring: Dictionary) -> void:
	var fresh := new_state()
	for key in fresh:
		if not hiring.has(key):
			hiring[key] = fresh[key]
	for candidate_id in fresh["status"]:
		if not hiring["status"].has(candidate_id):
			hiring["status"][candidate_id] = fresh["status"][candidate_id]


# The app appears once James has joined, so the pot already runs.
static func is_app_unlocked() -> bool:
	return bool(GameState.state["flags"].get("bizA1JamesJoined", false))


# Candidate ids whose role is enabled, in data order.
static func candidate_ids() -> Array:
	var ids: Array = []
	for candidate_id in GameData.HIRING_CANDIDATES:
		var role: Dictionary = GameData.HIRING_ROLES.get(candidate(candidate_id)["role"], {})
		if role.get("enabled", false):
			ids.append(candidate_id)
	return ids


static func candidate(candidate_id: String) -> Dictionary:
	return GameData.HIRING_CANDIDATES.get(candidate_id, {})


static func role(candidate_id: String) -> Dictionary:
	return GameData.HIRING_ROLES[candidate(candidate_id)["role"]]


static func skill(candidate_id: String) -> String:
	return role(candidate_id)["skill"]


static func status(candidate_id: String) -> Dictionary:
	return GameState.state["hiring"]["status"][candidate_id]


# Their role skill: startLevel until hiring raises it, then whatever they
# have reached (kept after they leave).
static func level(candidate_id: String) -> int:
	var c: Dictionary = GameState.state["contacts"][candidate_id]
	return maxi(int(c["%sSkill" % skill(candidate_id)]), int(candidate(candidate_id)["startLevel"]))


static func level_cap(candidate_id: String) -> int:
	return Contacts.skill_cap(candidate_id, skill(candidate_id))


# round((baseWage + wagePerLevel × (level − startLevel)) × wageMult), where
# wageMult is their live wage entry's (hiring-spec §10 R2), else the poach
# premium while employed elsewhere, else 1.
static func weekly_wage(candidate_id: String) -> int:
	return GameState.round_epsilon(float(_formula_wage(candidate_id)) * _wage_mult(candidate_id))


static func _formula_wage(candidate_id: String) -> int:
	var data := candidate(candidate_id)
	return int(data["baseWage"]) + int(data["wagePerLevel"]) * (level(candidate_id) - int(data["startLevel"]))


static func _wage_mult(candidate_id: String) -> float:
	var wage: Dictionary = GameState.state["business"]["wages"].get(candidate_id, {})
	if not wage.is_empty() and not wage.get("leaving", false):
		return float(wage.get("wageMult", 1.0))
	if is_employed(candidate_id):
		return poach_mult()
	return 1.0


static func _trait_data(candidate_id: String) -> Dictionary:
	return GameData.HIRING_TRAITS.get(candidate(candidate_id).get("trait", ""), {})


# Chance a staffer skips their block action (0 for no trait).
static func trait_skip_chance(candidate_id: String) -> float:
	return float(_trait_data(candidate_id).get("skipChance", 0.0))


# Multiplier on role-skill XP (1 for no trait).
static func trait_xp_mult(candidate_id: String) -> float:
	return float(_trait_data(candidate_id).get("roleXpMult", 1.0))


# Rolls the skip chance; no Rng draw for a staffer without the trait.
static func trait_skips_block(candidate_id: String) -> bool:
	var chance := trait_skip_chance(candidate_id)
	return chance > 0.0 and Rng.chance(chance)


static func poach_mult() -> float:
	return 1.0 + float(GameData.HIRING_MARKET["poachPremium"])


static func poach_relation_cost() -> int:
	return int(GameData.HIRING_MARKET["poachRelationCost"])


static func is_employed(candidate_id: String) -> bool:
	return status(candidate_id)["state"] == STATUS_EMPLOYED


# The faction employing them, or null.
static func employer(candidate_id: String) -> Variant:
	return status(candidate_id)["employer"]


# Employer pool (hiring-spec §10 R5): every faction in state.factions, in
# state order.
static func employer_pool() -> Array:
	return GameState.state["factions"].keys()


# Rollover step (hiring-spec §4.1): every candidate not working for you
# flips between open and employed with chance flipChancePerDay; a new
# employer is a random faction from employer_pool().
static func roll_market_flips() -> void:
	var day: int = GameState.state["world"]["day"]
	var chance := float(GameData.HIRING_MARKET["flipChancePerDay"])
	var statuses: Dictionary = GameState.state["hiring"]["status"]
	for candidate_id in GameData.HIRING_CANDIDATES:
		var state: String = statuses[candidate_id]["state"]
		if state == STATUS_OURS or not Rng.chance(chance):
			continue
		if state == STATUS_EMPLOYED:
			var former: String = statuses[candidate_id]["employer"]
			statuses[candidate_id] = _open_status(day)
			LodedInnitFeed.post_status(LodedInnitFeed.STATUS_OPEN, candidate_id, former)
		else:
			var new_employer: String = Rng.rand_from(employer_pool())
			statuses[candidate_id] = { "state": STATUS_EMPLOYED, "employer": new_employer, "since": day }
			LodedInnitFeed.post_status(LodedInnitFeed.STATUS_EMPLOYED, candidate_id, new_employer)


# Re-reads a hire's weekly wage after a level-up; leavers and non-candidates
# are untouched.
static func refresh_wage(contact_id: String) -> void:
	if not GameData.HIRING_CANDIDATES.has(contact_id):
		return
	var wage: Dictionary = GameState.state["business"]["wages"].get(contact_id, {})
	if wage.is_empty() or wage.get("leaving", false):
		return
	wage["weekly"] = weekly_wage(contact_id)


static func has_free_seat(candidate_id: String) -> bool:
	var room_id: String = role(candidate_id)["room"]
	return Home.has_room(room_id) and Contacts.room_seats_used(room_id) < Home.room_seats(room_id)


# "" when hire() can go ahead (perhaps after a float top-up), else why not.
static func hire_block_reason(candidate_id: String) -> String:
	if not GameData.HIRING_CANDIDATES.has(candidate_id):
		return "No such candidate."
	if status(candidate_id)["state"] == STATUS_OURS:
		return "Already works for you."
	if not Business.is_pot_active():
		return "The business pot isn't running yet."
	var room_id: String = role(candidate_id)["room"]
	if not Home.has_room(room_id):
		return "Build the %s first." % GameData.HOME_ROOMS[room_id]["name"]
	if not has_free_seat(candidate_id):
		return "No free seat in the %s." % GameData.HOME_ROOMS[room_id]["name"]
	return ""


# Cash the float needs before the first week can be prepaid; 0 when pot +
# float already cover it.
static func top_up_needed(candidate_id: String) -> int:
	return Business.shortfall(weekly_wage(candidate_id))


# Hires a candidate into a free seat of their role room: the first week is
# prepaid from the pot, then the float. If pot + float are short, refused
# with { ok: false, topUp: X } unless top_up is true, in which case X moves
# from cash into the float first. An employed candidate is poached
# (hiring-spec §4.2): the poach premium becomes their permanent wageMult and
# their employer's relation drops by poachRelationCost. On success they are
# recruited, their role skill is raised to startLevel, they are seated, and
# their status becomes "ours".
static func hire(candidate_id: String, top_up: bool = false) -> Dictionary:
	var reason := hire_block_reason(candidate_id)
	if reason != "":
		return { "ok": false, "reason": reason }
	var weekly := weekly_wage(candidate_id)
	var needed := top_up_needed(candidate_id)
	if needed > 0 and not top_up:
		return { "ok": false, "reason": "Top up the float by £%d to cover this hire." % needed, "topUp": needed }
	var poached_from: Variant = employer(candidate_id) if is_employed(candidate_id) else null
	var paid := Business.prepay_hire_wage(candidate_id, weekly, needed, poach_mult() if poached_from != null else 1.0)
	if not paid["ok"]:
		return paid
	if poached_from != null:
		Factions.adjust_player_relation(poached_from, -poach_relation_cost())
	var c: Dictionary = GameState.state["contacts"][candidate_id]
	var start_level := int(candidate(candidate_id)["startLevel"])
	var skill_id := skill(candidate_id)
	if int(c["%sSkill" % skill_id]) < start_level:
		c["%sSkill" % skill_id] = start_level
		c["%sXP" % skill_id] = int(Contacts.xp_levels(skill_id)[start_level])
	c["unlocked"] = true
	c["recruited"] = true
	Contacts.assign_to_room(candidate_id, role(candidate_id)["room"])
	var day: int = GameState.state["world"]["day"]
	GameState.state["hiring"]["status"][candidate_id] = { "state": STATUS_OURS, "employer": null, "since": day }
	if poached_from != null:
		LodedInnitFeed.post_status(LodedInnitFeed.STATUS_HIRED_FROM, candidate_id, poached_from)
	else:
		LodedInnitFeed.post_status(LodedInnitFeed.STATUS_HIRED, candidate_id)
	Notify.push("%s starts in the %s today." % [Contacts.display_name(candidate_id), GameData.HOME_ROOMS[role(candidate_id)["room"]]["name"]], Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	return { "ok": true, "paid": weekly, "toppedUp": needed }


# Candidates working for you whose role room is room_id, in data order.
static func hires_for_room(room_id: String) -> Array:
	var ids: Array = []
	for candidate_id in GameData.HIRING_CANDIDATES:
		if status(candidate_id)["state"] == STATUS_OURS and role(candidate_id)["room"] == room_id:
			ids.append(candidate_id)
	return ids


# Lets a hire go (hiring-spec §4.2, §10 R3/R4): their seat is vacated, their
# cultivatorVeins released, their wage entry flagged leaving (the next
# payday settles it, then drops it), and they return to the market open.
# Their level is kept.
static func let_go(candidate_id: String) -> Dictionary:
	if not GameData.HIRING_CANDIDATES.has(candidate_id) or status(candidate_id)["state"] != STATUS_OURS:
		return { "ok": false, "reason": "Doesn't work for you." }
	_release(candidate_id, _open_status(GameState.state["world"]["day"]))
	LodedInnitFeed.post_status(LodedInnitFeed.STATUS_LET_GO, candidate_id)
	# PROSE-REVIEW: let-go notification.
	Notify.push("%s clears their desk." % Contacts.display_name(candidate_id))
	EventBus.state_changed.emit()
	return { "ok": true }


# Vacates the seat, releases cultivatorVeins, flags the wage entry leaving,
# drops any pending poach offer and sets the new market status.
static func _release(candidate_id: String, new_status: Dictionary) -> void:
	_poach_entry(candidate_id)["pending"] = null
	for vein_id in Rooms.cultivator_veins(candidate_id).duplicate():
		Rooms.unassign_vein(vein_id)
	GameState.state["cultivatorVeins"].erase(candidate_id)
	var c: Dictionary = GameState.state["contacts"][candidate_id]
	c["assignedRoom"] = null
	c["assignedRole"] = null
	c["recruited"] = false
	Business.mark_leaving(candidate_id)
	GameState.state["hiring"]["status"][candidate_id] = new_status


# --- Poaching (hiring-spec §4.3) ---

static func _poach_entry(candidate_id: String) -> Dictionary:
	var poach: Dictionary = GameState.state["hiring"]["poach"]
	if not poach.has(candidate_id):
		poach[candidate_id] = { "attempts": 0, "pending": null }
	return poach[candidate_id]


# The open offer { factionId, offer, expiresDay }, or {}.
static func pending_poach(candidate_id: String) -> Dictionary:
	var pending: Variant = _poach_entry(candidate_id)["pending"]
	return pending if pending is Dictionary else {}


# Hires with an unanswered offer, in data order.
static func pending_poach_ids() -> Array[String]:
	var ids: Array[String] = []
	for candidate_id in GameData.HIRING_CANDIDATES:
		if status(candidate_id)["state"] == STATUS_OURS and not pending_poach(candidate_id).is_empty():
			ids.append(candidate_id)
	return ids


# The weekly wage a faction offers: +poachOfferPct, never above counterCapPct
# over the current wage, so the player can always match it.
static func poach_offer_wage(candidate_id: String) -> int:
	var current := weekly_wage(candidate_id)
	var pct := minf(float(GameData.HIRING_MARKET["poachOfferPct"]), float(GameData.HIRING_MARKET["counterCapPct"]))
	return GameState.round_epsilon(float(current) * (1.0 + pct))


# Faction weight by the player's stance with it (poachStanceWeights).
static func _poach_weights() -> Dictionary:
	var weights: Dictionary = GameData.HIRING_MARKET["poachStanceWeights"]
	var result := {}
	for faction_id in employer_pool():
		var stance: String = GameState.state["factionStances"]["player"].get(faction_id, {}).get("stance", FactionAI.NEUTRAL)
		var weight := float(weights.get(stance, 0.0))
		if weight > 0.0:
			result[faction_id] = weight
	return result


static func _pick_poacher() -> String:
	var weights := _poach_weights()
	if weights.is_empty():
		return ""
	var total := 0.0
	for faction_id in weights:
		total += float(weights[faction_id])
	var roll := Rng.randf() * total
	var picked := ""
	for faction_id in weights:
		picked = faction_id
		roll -= float(weights[faction_id])
		if roll < 0.0:
			break
	return picked


# Rollover step: offers a full day unanswered resolve as refusals, then on a
# Monday gives each hire under the attempt cap a poachChance of a new offer.
static func daily_poach_tick() -> void:
	var day: int = GameState.state["world"]["day"]
	for candidate_id in pending_poach_ids():
		if day >= int(pending_poach(candidate_id)["expiresDay"]):
			decline_poach(candidate_id)
	if not Calendar.is_monday(day):
		return
	var chance := float(GameData.HIRING_MARKET["poachChance"])
	var max_attempts := int(GameData.HIRING_MARKET["maxPoachAttempts"])
	for candidate_id in GameData.HIRING_CANDIDATES:
		if status(candidate_id)["state"] != STATUS_OURS:
			continue
		var entry := _poach_entry(candidate_id)
		if entry["pending"] != null or int(entry["attempts"]) >= max_attempts or not Rng.chance(chance):
			continue
		var faction_id := _pick_poacher()
		if faction_id == "":
			continue
		entry["attempts"] = int(entry["attempts"]) + 1
		entry["pending"] = { "factionId": faction_id, "offer": poach_offer_wage(candidate_id), "expiresDay": day + 2 }
		# PROSE-REVIEW: poach alert notification.
		Notify.push("%s has an offer from %s." % [Contacts.display_name(candidate_id), faction_name(faction_id)])
	EventBus.state_changed.emit()


static func faction_name(faction_id: String) -> String:
	return GameData.FACTIONS.get(faction_id, {}).get("shortName", faction_id)


# PROSE-REVIEW: BizBrief poach alert.
static func poach_alert_label(candidate_id: String) -> String:
	var pending := pending_poach(candidate_id)
	return "%s: %s have offered £%d/wk (now £%d). Match it or they go." % [Contacts.display_name(candidate_id), faction_name(pending["factionId"]), int(pending["offer"]), weekly_wage(candidate_id)]


# Matches the offer: the wage becomes the offered amount and wageMult keeps it.
static func match_poach(candidate_id: String) -> Dictionary:
	var pending := pending_poach(candidate_id)
	if pending.is_empty() or status(candidate_id)["state"] != STATUS_OURS:
		return { "ok": false, "reason": "No offer to match." }
	var offer := int(pending["offer"])
	var wage: Dictionary = GameState.state["business"]["wages"].get(candidate_id, {})
	if not wage.is_empty():
		wage["wageMult"] = float(offer) / float(_formula_wage(candidate_id))
		wage["weekly"] = offer
	_poach_entry(candidate_id)["pending"] = null
	EventBus.state_changed.emit()
	return { "ok": true, "weekly": offer }


# Refuses the offer (or lets it lapse): the hire leaves for the faction.
static func decline_poach(candidate_id: String) -> Dictionary:
	var pending := pending_poach(candidate_id)
	if pending.is_empty() or status(candidate_id)["state"] != STATUS_OURS:
		return { "ok": false, "reason": "No offer to refuse." }
	var faction_id: String = pending["factionId"]
	_release(candidate_id, { "state": STATUS_EMPLOYED, "employer": faction_id, "since": GameState.state["world"]["day"] })
	LodedInnitFeed.post_status(LodedInnitFeed.STATUS_POACHED_AWAY, candidate_id, faction_id)
	# PROSE-REVIEW: poached-away notification.
	Notify.push("%s has gone to %s." % [Contacts.display_name(candidate_id), faction_name(faction_id)])
	EventBus.state_changed.emit()
	return { "ok": true, "factionId": faction_id }
