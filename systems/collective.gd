class_name Collective
extends RefCounted

# collective1-07, spec §5.5/§7.2/§9.5: Des, Nadia and Hakim are three
# cosmetic doors onto one lane -- identical price and identical *faction*
# relation award, because both are already generic per-faction (systems/
# economy.gd's execute_faction_sale, systems/relation_accrual.gd's
# accrue_faction), driven here with faction_id "collective" regardless of
# which contact's Trade button opened the sell_menu. What does vary by
# vendor: a flavour line appended to their own conversation on completing a
# trade (data/collective_barks.json), drawn without repeats until each
# vendor's pool is exhausted -- and, per 109-collective-vendor-door-personal-
# relation below, that specific vendor's own personal relation.

# 109-collective-vendor-door-personal-relation: DRAFT, pending human balance
# sign-off -- flat per-trade award to the vendor whose door the trade went
# through, same "both fire" shape Economy.execute_sale's Archie lane already
# has (ARCHIE_SALE_RELATION_GAIN flat + RelationAccrual.accrue_archie's
# tradeProgress meter). Smaller than Archie's +2: three vendors share what
# would otherwise be one lane's volume, and unlike Archie's cut-and-mugging
# lane there's no risk here to offset.
const VENDOR_TRADE_RELATION_GAIN := 1


static func complete_trade(contact_id: String) -> Dictionary:
	var result := Economy.sell_to_faction_from_sell_state("collective", contact_id)
	# vein-trade-assets ticket 03: `ok`, not `earned > 0` -- a buy-heavy cart
	# nets a zero or negative `earned` (cash spent, not credited) even though
	# a real trade happened. sell_to_faction_from_sell_state() only returns
	# ok:false for a genuinely empty cart, and the Go button that calls this
	# is already disabled for that case, so this still can't fire on a no-op.
	if result.get("ok", false):
		Messages.append(contact_id, "them", _next_bark(contact_id))
		Modal.open("sale_result", { "earned": result["earned"], "gross": result["earned"], "mugged": false })
		# 109-collective-vendor-door-personal-relation: the flat half of the
		# "both fire" shape -- accrue_contact_trade's tradeProgress-meter
		# half already fired (once per item/vein leg) inside
		# sell_to_faction_from_sell_state() above, keyed on this same
		# contact_id.
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


# Lets the player report a qualifying col_a1_des_sites site to Des the
# moment it exists, one ore type at a time, rather than only ever
# converting once both required ore types are unclaimed simultaneously.
# Converts the site to a Collective vein immediately via Sites.
# seed_faction_vein(), so a site reported for one ore type carries a
# factionVein from this call onward and can never satisfy "unclaimed" for
# a later report -- the double-report/re-match guard falls out of
# site_matches_discovery_params()'s own unclaimed check rather than needing
# a separate "already used" set. progress["reportedSiteIds"] is cumulative
# across calls (never overwritten), so reporting fate then physics later
# (even once the fate site is long gone) still lands both.
#
# No-op (ok:false, nothing mutated) when: the thread isn't active yet,
# ore_type isn't one of col_a1_des_sites' requireEachOreType, it's already
# been reported, or no currently-qualifying site exists for it -- explicit
# failure over silent success/retry, so a caller can tell "nothing to
# report" apart from "reported".
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


# des-sites-partial-turnin ticket 02: the first required ore type (col_a1_
# des_sites' requireEachOreType, in order) that hasn't been reported yet and
# currently has a qualifying site -- "" if none does. ContactCards.
# build_des_report_action() calls this to decide whether to show "Tell Des
# about the ground" and which ore type pressing it will report, sharing the
# exact qualifying-site scan report_des_site() above uses so the button can
# never surface a report that call would then reject as "no qualifying site".
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


# collective1-09, spec §6.5/§6.6/§10.4: Des's two location-agnostic "Firm as
# weather" beats. Called from Sites.prospect() in place of
# DistrictDeck.maybe_trigger() -- checked first, and this whole function is
# Rng-free (a pure flags/site check), so when it fires the deck's own
# seeded roll is never touched at all that action: a genuine early return,
# not a discarded draw (§10.4's "must be asserted by a test").
#
# `new_site` is the site this same Sites.prospect() call just created (null
# on an at-cap reroll with nothing eligible) -- "qualifying" means it
# individually satisfies col_a1_des_sites' per-site criteria (ore type,
# tier, unclaimed; see Objectives.site_matches_discovery_params()), not
# that the objective as a whole is complete. colA1SkirmishSeen/
# colA1IntimidationSeen double as the "how many qualifying completions have
# we had" counter: neither seen yet -> this one fires S5; S5 already seen,
# S6 not yet -> this one fires S6; both seen -> no more weather beats.
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


# collective1-12, spec §6.10: S10 (col_a1_nadia_done) fires automatically the
# moment col_a1_nadia_vein's qualifying sale completes, not from an action
# bar -- called from VeinTrade.sell_to_faction() after Objectives.refresh(),
# same self-contained flags/objective inspection shape
# maybe_trigger_weather_beat() above uses (the generic caller hands over no
# state of its own to check). colA1NadiaThreadDone -- this event's own
# on_complete flag -- is what stops it firing again on a later, unrelated
# sale once col_a1_nadia_vein is complete: starting the event immediately
# navigates off whatever screen could call sell_to_faction() again, so in
# practice this can't re-enter before the player has played it through (or
# abandoned it), and once they have, this guard is permanent.
static func maybe_trigger_nadia_vein_done() -> bool:
	if GameState.state["flags"].get("colA1NadiaThreadDone", false):
		return false
	var objective: Dictionary = GameState.state["objectives"].get("col_a1_nadia_vein", {})
	if not objective.get("complete", false):
		return false

	Events.start_event("col_a1_nadia_done")
	return true


# collective1-16, spec §6.15/§10.4: S14's delivery condition -- all three
# thread-done flags plus the relation-25 gate, stated explicitly even though
# the gate is guaranteed by the +37 favour total the three threads award
# between them (bugfix, post-launch: spec §8.5 originally totalled 27,
# only 2 above the gate -- too tight in practice, since anything that dents
# collective relation elsewhere (e.g. raiding.gd's CLAIM_RELATION_HIT on a
# Collective-owned vein) could drop a fully-quested player back under 25
# with no way back in short of a trade grind. S1 +5, Des +6/ore-type (12),
# Nadia +10, Hakim +10 = 37, so the spine's "gate at 25" contract holds for
# the other four factions that inherit this engine. Called from Events.
# advance() right after any event's on_complete runs (see its own comment) --
# the one code path all three thread-resolution events' on_complete
# effects actually flow through. Guarded against re-queueing a duplicate
# text: colA1Complete (this event's own on_complete flag) blocks it once
# S14 has actually been played, and checking Hakim's existing pending
# entries blocks it from double-queueing between the moment all three flags
# land and the player actually opening the text.
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


# collective1-17, spec §5.8/§6.16: Hakim's repeatable unprompted intel --
# a free lead on unclaimed ground, the gift the Arc 2 handler later
# replaces with an invoice. Called from TimeSystem.daily_tick(). Both
# districts + tiers weighted per HAKIM_INTEL_TIERS below.
const HAKIM_INTEL_CHANCE := 0.15
const HAKIM_INTEL_MIN_GAP_DAYS := 3
const HAKIM_INTEL_DISTRICTS: PackedStringArray = ["shoreditch", "whitechapel"]
# "fair or better" per spec -- barren/poor excluded outright rather than
# rolled and rerolled, so the 15% chance always spends exactly one Rng draw.
const HAKIM_INTEL_TIERS: PackedStringArray = ["fair", "rich", "saturated"]


static func maybe_trigger_hakim_intel() -> bool:
	if not GameState.state["flags"].get("hakimIntelUnlocked", false):
		return false
	# Same double-queue guard maybe_trigger_closer() uses above: a text the
	# player hasn't read yet shouldn't roll a second one, even though
	# hakimIntelLastDay itself only advances on_complete (see its own
	# comment in GameState.new_game_state()).
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
