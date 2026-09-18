class_name Collective
extends RefCounted

# Des, Nadia and Hakim are three cosmetic doors onto one trade lane --
# identical price and *faction* relation via faction_id "collective",
# regardless of contact. What varies by vendor: a flavour line on completion
# (data/collective_barks.json) and that vendor's own personal relation below.

# DRAFT, pending human balance sign-off. Flat per-trade award to the vendor
# whose door the trade went through -- same "both fire" shape as
# Economy.execute_sale's Archie lane, but smaller since three vendors share one lane's volume.
const VENDOR_TRADE_RELATION_GAIN := 1


# Nadia's approved introductory order is a separate operation from the shared
# Collective cart: only this direct hand-off advances it. Economy still owns
# price, stock removal, payment and trade-side relation, so this has no time
# cost and cannot fork the faction-sale rules.
static func supply_nadia(qty: int) -> Dictionary:
	var runtime: Dictionary = GameState.state["objectives"].get("col_a1_nadia_supply", {})
	if qty <= 0:
		return { "ok": false, "reason": "Choose a positive quantity." }
	if not runtime.get("active", false) or runtime.get("complete", false):
		return { "ok": false, "reason": "Nadia's order is not accepting deliveries." }

	var params: Dictionary = GameData.OBJECTIVES["col_a1_nadia_supply"]["params"]
	var ore_type: String = params["oreType"]
	var stock: int = GameState.state["player"]["orichalchum"].get(ore_type, 0)
	if qty > stock:
		return { "ok": false, "reason": "Not enough calc in stock." }

	var result := Economy.execute_faction_sale(params["factionId"], [{ "kind": "ore", "type": ore_type, "qty": qty }], params["contactId"])
	if not result.get("ok", false):
		return result

	var progress: Dictionary = runtime["progress"]
	progress["delivered"] = mini(int(params["qty"]), int(progress.get("delivered", 0)) + qty)
	runtime["progress"] = progress
	GameState.state["objectives"]["col_a1_nadia_supply"] = runtime
	Objectives.refresh()
	EventBus.state_changed.emit()
	return result


static func nadia_supply_status() -> Dictionary:
	var params: Dictionary = GameData.OBJECTIVES["col_a1_nadia_supply"]["params"]
	var runtime: Dictionary = GameState.state["objectives"].get("col_a1_nadia_supply", {})
	var delivered: int = mini(int(params["qty"]), int(runtime.get("progress", {}).get("delivered", 0)))
	return { "delivered": delivered, "required": int(params["qty"]), "remaining": maxi(0, int(params["qty"]) - delivered), "oreType": params["oreType"] }


static func complete_trade(contact_id: String) -> Dictionary:
	var result := Economy.sell_to_faction_from_sell_state("collective", contact_id)
	# `ok`, not `earned > 0` -- a buy-heavy cart nets a zero/negative earned
	# even though a real trade happened.
	if result.get("ok", false):
		Messages.append(contact_id, "them", _next_bark(contact_id))
		Modal.open("sale_result", { "earned": result["earned"], "gross": result["earned"], "mugged": false })
		# The flat half of VENDOR_TRADE_RELATION_GAIN's "both fire" shape --
		# the tradeProgress-meter half already fired inside
		# sell_to_faction_from_sell_state() above.
		Contacts.award_relation(contact_id, VENDOR_TRADE_RELATION_GAIN)
	return result


# Sequential cursor over data/collective_barks.json's array for this
# contact -- every line is shown once before any repeats, then wraps.
# Deterministic (no Rng) since draw order carries no meaning here, only
# non-repetition does.
static func _next_bark(contact_id: String) -> String:
	var lines: Array = GameData.COLLECTIVE_BARKS.get(contact_id, [])
	if lines.is_empty():
		return ""
	var cursors: Dictionary = GameState.state["collective"]["barkCursors"]
	var index: int = cursors.get(contact_id, 0)
	if index >= lines.size():
		index = 0
	cursors[contact_id] = index + 1
	return lines[index]


# Lets the player report a qualifying col_a1_des_sites site to Des one ore type
# at a time, rather than only once both required types are unclaimed at once.
# Converts the site to a Collective vein immediately (Sites.seed_faction_vein()),
# which doubles as the double-report guard: a claimed site never re-matches "unclaimed".
static func report_des_site(ore_type: String) -> Dictionary:
	if not GameState.state["flags"].get("colA1DesThreadActive", false):
		return { "ok": false, "reason": "Thread not active." }

	var def: Dictionary = GameData.OBJECTIVES["col_a1_des_sites"]
	var params: Dictionary = def["params"]
	if not params.get("requireEachOreType", []).has(ore_type):
		return { "ok": false, "reason": "Not a required ore type." }

	var objective_id: String = def["id"]
	var objectives: Dictionary = GameState.state["objectives"]
	var runtime: Dictionary = objectives.get(objective_id, { "active": false, "complete": false, "progress": {} })
	var progress: Dictionary = runtime["progress"]
	var reported: Dictionary = progress.get("reportedSiteIds", {})
	if reported.has(ore_type):
		return { "ok": false, "reason": "Already reported." }

	var found: Variant = _find_qualifying_des_site(ore_type, params)
	if found == null:
		return { "ok": false, "reason": "No qualifying site." }

	Sites.seed_faction_vein(found, "collective")
	Factions.adjust_player_relation("collective", 6)

	reported[ore_type] = found["id"]
	progress["reportedSiteIds"] = reported
	runtime["progress"] = progress
	objectives[objective_id] = runtime

	Objectives.refresh()
	EventBus.state_changed.emit()
	return { "ok": true, "oreType": ore_type, "siteId": found["id"] }


# The first required ore type (in requireEachOreType order) that hasn't
# been reported yet and currently has a qualifying site -- "" if none does.
# ContactCards.build_des_report_action() uses this to decide whether to
# show the report action, sharing report_des_site()'s own qualifying-site
# scan so the button can never offer a report that call would reject.
static func next_reportable_des_ore_type() -> String:
	if not GameState.state["flags"].get("colA1DesThreadActive", false):
		return ""

	var def: Dictionary = GameData.OBJECTIVES["col_a1_des_sites"]
	var params: Dictionary = def["params"]
	var objective: Dictionary = GameState.state["objectives"].get(def["id"], {})
	var reported: Dictionary = objective.get("progress", {}).get("reportedSiteIds", {})

	for ore_type in params.get("requireEachOreType", []):
		if reported.has(ore_type):
			continue
		if _find_qualifying_des_site(ore_type, params) != null:
			return ore_type
	return ""


static func _find_qualifying_des_site(ore_type: String, params: Dictionary) -> Variant:
	for site in GameState.state["world"]["sites"]:
		if Objectives.site_matches_discovery_params(site, ore_type, params):
			return site
	return null


# Des's two location-agnostic "Firm as weather" beats. Called from Sites.prospect()
# ahead of DistrictDeck.maybe_trigger(); Rng-free, so firing never touches the
# deck's own seeded roll (a genuine early return, not a discarded draw).
# `new_site` is the site this prospect() call just created (null on an at-cap
# reroll). colA1SkirmishSeen/colA1IntimidationSeen double as a fired-beats
# counter: neither seen fires the first, only the first seen fires the second,
# both seen fires no more.
static func maybe_trigger_weather_beat(new_site: Variant) -> bool:
	if not GameState.state["flags"].get("colA1DesThreadActive", false):
		return false
	if new_site == null:
		return false

	var params: Dictionary = GameData.OBJECTIVES["col_a1_des_sites"]["params"]
	var ore_type: String = new_site["oreType"]
	if not params.get("requireEachOreType", []).has(ore_type):
		return false
	if not Objectives.site_matches_discovery_params(new_site, ore_type, params):
		return false

	if not GameState.state["flags"].get("colA1SkirmishSeen", false):
		Events.start_event("col_a1_firm_skirmish")
		return true

	if not GameState.state["flags"].get("colA1IntimidationSeen", false):
		Events.start_event("col_a1_firm_intimidation")
		return true

	return false


# Fires col_a1_nadia_done automatically the moment col_a1_nadia_vein's
# qualifying sale completes, called from VeinTrade.sell_to_faction() after
# Objectives.refresh(). colA1NadiaThreadDone (the event's own on_complete
# flag) permanently blocks re-firing on a later unrelated sale.
static func maybe_trigger_nadia_vein_done() -> bool:
	if GameState.state["flags"].get("colA1NadiaThreadDone", false):
		return false
	var objective: Dictionary = GameState.state["objectives"].get("col_a1_nadia_vein", {})
	if not objective.get("complete", false):
		return false

	Events.start_event("col_a1_nadia_done")
	return true


# The closing beat's delivery condition: all three thread-done flags plus the
# relation-25 gate, checked explicitly even though the threads' combined favour
# (37) already clears it with margin -- other relation hits (e.g. raiding.gd's
# CLAIM_RELATION_HIT) could otherwise drop a quested player back under the gate.
# Called from Events.advance() after any on_complete; colA1Complete blocks
# re-firing, and checking Hakim's pending entries blocks double-queueing.
static func maybe_trigger_closer() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA1DesThreadDone", false):
		return false
	if not flags.get("colA1NadiaThreadDone", false):
		return false
	if not flags.get("colA1HakimThreadDone", false):
		return false
	if flags.get("colA1Complete", false):
		return false
	if GameState.state["factions"]["collective"]["relation"] < 25:
		return false
	for entry in Messages.pending_for("hakim"):
		if entry["kind"] == "col_a1_closer":
			return false

	Messages.queue_pending("hakim", "col_a1_closer", "Are you about? Nothing's wrong. Come to the shop.")
	return true


# Act 2's own opening trigger (collective-act2 spec §6.1): "colA1Complete
# AND relation >= 25". Called from Events.advance() (colA1Complete only ever
# flips inside an event's on_complete, and relation is already >=25 at that
# instant per maybe_trigger_closer()'s own gate above) and from TimeSystem.
# daily_tick() as a backstop for the rare case relation dips below 25 again
# before col_a1_closer is actually played out. colA2Started blocks re-firing
# permanently once the text is sent.
static func maybe_trigger_act2_intro() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("colA2Started", false):
		return false
	if not flags.get("colA1Complete", false):
		return false
	if GameState.state["factions"]["collective"]["relation"] < 25:
		return false

	flags["colA2Started"] = true
	Messages.queue_pending("des", "col_a2_intro", "\"Get over here. Now. It's Hakim. He's all right — he's not all right, but he's not — just come.\"")
	return true


# Hakim's repeatable unprompted intel -- a free lead on unclaimed ground.
# Called from TimeSystem.daily_tick(). Districts + tiers weighted per
# HAKIM_INTEL_TIERS below.
const HAKIM_INTEL_CHANCE := 0.15
const HAKIM_INTEL_MIN_GAP_DAYS := 3
const HAKIM_INTEL_DISTRICTS: PackedStringArray = ["shoreditch", "whitechapel"]
# "fair or better" -- barren/poor excluded outright rather than rolled and
# rerolled, so the 15% chance always spends exactly one Rng draw.
const HAKIM_INTEL_TIERS: PackedStringArray = ["fair", "rich", "saturated"]


static func maybe_trigger_hakim_intel() -> bool:
	if not GameState.state["flags"].get("hakimIntelUnlocked", false):
		return false
	# Same double-queue guard as maybe_trigger_closer() above: a text the
	# player hasn't read yet shouldn't roll a second one.
	for entry in Messages.pending_for("hakim"):
		if entry["kind"] == "col_hakim_intel":
			return false

	var day: int = GameState.state["world"]["day"]
	var last_day: int = GameState.state["collective"]["hakimIntelLastDay"]
	if day - last_day < HAKIM_INTEL_MIN_GAP_DAYS:
		return false

	var eligible_districts := _eligible_hakim_intel_districts()
	if eligible_districts.is_empty():
		return false

	if not Rng.chance(HAKIM_INTEL_CHANCE):
		return false

	var district: String = Rng.rand_from(eligible_districts)
	var tier := _roll_hakim_intel_tier()
	var site := Sites.roll_new_site(district, tier)
	GameState.state["world"]["sites"].append(site)

	# PROSE-REVIEW: new SMS teaser drafted against CONTENT-GUIDE.md's tone
	# bible -- deliberately shorter than the event's own opening card
	# (spec §6.16), which the player reads a moment later.
	Messages.queue_pending("hakim", "col_hakim_intel", "\"Oi. Got something for you. Don't get excited.\"", { "site_id": site["id"] })
	return true


# Districts still under siteCap, of the two Hakim's intel is scoped to --
# spec §5.8: "suppressed if both Shoreditch and Whitechapel are at siteCap".
static func _eligible_hakim_intel_districts() -> Array:
	var eligible: Array = []
	for district_id in HAKIM_INTEL_DISTRICTS:
		var site_cap: int = GameData.DISTRICTS[district_id]["siteCap"]
		if Sites.sites_in_district(district_id).size() < site_cap:
			eligible.append(district_id)
	return eligible


# Weighted pick over HAKIM_INTEL_TIERS using the same GameData.SITE_TIER_
# WEIGHTS table Sites.roll_tier() draws from, restricted to "fair or
# better" -- mirrors Sites.roll_tier_from_weights()'s cumulative-weight
# walk without needing every GameData.SITE_TIER_ORDER key present.
static func _roll_hakim_intel_tier() -> String:
	var total: float = 0.0
	for tier in HAKIM_INTEL_TIERS:
		total += GameData.SITE_TIER_WEIGHTS[tier]

	var roll: float = Rng.randf() * total
	var cumulative: float = 0.0
	for tier in HAKIM_INTEL_TIERS:
		cumulative += GameData.SITE_TIER_WEIGHTS[tier]
		if roll < cumulative:
			return tier
	return HAKIM_INTEL_TIERS[-1]
