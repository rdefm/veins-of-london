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
# flag) permanently blocks re-firing on a later unrelated sale. A sale made
# from a modal parks the event behind the sale confirmation (start_or_defer).
static func maybe_trigger_nadia_vein_done() -> bool:
	if GameState.state["flags"].get("colA1NadiaThreadDone", false):
		return false
	var objective: Dictionary = GameState.state["objectives"].get("col_a1_nadia_vein", {})
	if not objective.get("complete", false):
		return false

	Events.start_or_defer("col_a1_nadia_done")
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


# Act 2 T5's contested vein (spec §6.5): "a named Collective vein has been
# taken by the Firm since T3" is scripted rather than left to
# Factions.apply_rivalry_resolution()'s own odds, so col_a2_contested_vein's
# pin always has a real site for its Force/Buy back choice to resolve
# against -- the beat is deliberately abstract/teaching, per the spec, unlike
# T10-T11's precise losses. Called from Events.advance()'s post-on_complete
# idiom, same as maybe_trigger_act2_intro() above; contestedVeinSiteId blocks
# re-firing.
const CONTESTED_VEIN_DISTRICT := "camden"
const CONTESTED_VEIN_ORE := "physics"
const CONTESTED_VEIN_TIER := "fair"
const CONTESTED_VEIN_GROWTH := 65


static func maybe_trigger_a2_contested_vein_setup() -> bool:
	if not GameState.state["flags"].get("colA2Stage", false):
		return false
	if GameState.state["collective"]["contestedVeinSiteId"] != null:
		return false

	var site: Dictionary = Sites.spawn_unclaimed_site(CONTESTED_VEIN_DISTRICT, CONTESTED_VEIN_TIER, CONTESTED_VEIN_ORE)
	site["factionVein"] = Factions.create_faction_vein("firm", site, CONTESTED_VEIN_GROWTH)
	MapEvents.queue_seed_claim(site["district"], site["factionVein"]["id"], "firm")
	GameState.state["collective"]["contestedVeinSiteId"] = site["id"]
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
# DRAFT, playtest-pending: once colA2SpineReward is set, the share of
# successful rolls that flag a weak enemy-held vein rather than new ground.
const HAKIM_INTEL_WEAK_VEIN_SHARE := 0.5
const HAKIM_INTEL_WEAK_KIND := "col_hakim_intel_weak"


static func maybe_trigger_hakim_intel() -> bool:
	if not GameState.state["flags"].get("hakimIntelUnlocked", false):
		return false
	# Same double-queue guard as maybe_trigger_closer() above: a text the
	# player hasn't read yet shouldn't roll a second one.
	for entry in Messages.pending_for("hakim"):
		if entry["kind"] == "col_hakim_intel" or entry["kind"] == HAKIM_INTEL_WEAK_KIND:
			return false

	var day: int = GameState.state["world"]["day"]
	var last_day: int = GameState.state["collective"]["hakimIntelLastDay"]
	if day - last_day < HAKIM_INTEL_MIN_GAP_DAYS:
		return false

	var eligible_districts := _eligible_hakim_intel_districts()
	var weak_site_ids := _hakim_intel_weak_vein_site_ids()
	if eligible_districts.is_empty() and weak_site_ids.is_empty():
		return false

	if not Rng.chance(HAKIM_INTEL_CHANCE):
		return false

	# Past T14 (collective-act2 spec §5.6), the same roll may land on a weak
	# enemy-held vein instead of fresh ground.
	if not weak_site_ids.is_empty() and (eligible_districts.is_empty() or Rng.chance(HAKIM_INTEL_WEAK_VEIN_SHARE)):
		# PROSE-REVIEW: new SMS teaser, drafted against CONTENT-GUIDE.md.
		Messages.queue_pending("hakim", HAKIM_INTEL_WEAK_KIND, "\"Heard something. Not ground this time. Don't get excited.\"", { "site_id": Rng.rand_from(weak_site_ids) })
		return true

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


# Enemy-held veins genuinely soft right now (NetworkHandler's own honest
# test) and not already carrying a live claim bonus. Empty before T14.
static func _hakim_intel_weak_vein_site_ids() -> Array:
	if not GameState.state["flags"].get("colA2SpineReward", false):
		return []
	var ids: Array = []
	for site_id in NetworkHandler.target_site_ids():
		if NetworkHandler.is_vulnerable(site_id, NetworkHandler.EFFECT_CLAIM_BONUS) and NetworkHandler.claim_bonus(site_id) == 0.0:
			ids.append(site_id)
	return ids


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


# Act 2 T8a (spec §5.1/§6.8a): the player vein col_a2_nadia_defend watches --
# whichever vein already carries the Alarm upgrade if one does, else the
# lowest-raid-resist ("most exposed") vein, per the spec's own fallback
# order. exclude_id lets maybe_retarget_nadia_defend_vein() below rule out
# a vein that was just lost.
static func _pick_defend_vein_candidate(exclude_id: String = "") -> Variant:
	var most_exposed: Variant = null
	for vein in GameState.state["player"]["veins"]:
		if vein["id"] == exclude_id:
			continue
		if vein["alarmUpgrades"].has(Cultivating.ALARM_UPGRADE_ID):
			return vein
		if most_exposed == null or Cultivating.vein_raid_resist(vein) < Cultivating.vein_raid_resist(most_exposed):
			most_exposed = vein
	return most_exposed


# The col_a2_pick_nadia_defend_vein on_complete op's handler (col_a2_nadia_
# defend_brief's on_complete, spec §6.8a): picks and stamps the target once, when the brief scene resolves.
static func pick_nadia_defend_vein() -> void:
	var vein: Variant = _pick_defend_vein_candidate()
	GameState.state["collective"]["nadiaDefendVeinId"] = vein["id"] if vein != null else null


# T7 "make an example" (spec §6.7): provokes rather than deters -- for `days`
# days the Firm weights Collective-held veins `multiplier`x when picking a
# rivalry target. A later call overwrites rather than stacks.
static func provoke_firm(multiplier: float, days: int) -> void:
	GameState.state["collective"]["firmProvocation"] = {
		"multiplier": multiplier,
		"expiresDay": GameState.state["world"]["day"] + days,
	}


# Factions._pick_target_vein()'s per-candidate weight scale; 1.0 unless the
# Firm is the attacker, the Collective the defender, and provocation is live.
static func firm_target_multiplier(attacker_id: String, defender_id: String) -> float:
	if attacker_id != "firm" or defender_id != "collective":
		return 1.0
	var provocation: Variant = GameState.state["collective"].get("firmProvocation")
	if provocation == null or GameState.state["world"]["day"] >= int(provocation["expiresDay"]):
		return 1.0
	return float(provocation["multiplier"])


# Called from Raiding.resolve_raid_outcome() on every ownership-transferring
# loss. Spec §6.8a: "should re-target a different Collective vein rather
# than dead-end" if the vein col_a2_nadia_defend was watching is the one
# just lost -- a no-op for every other loss.
static func maybe_retarget_nadia_defend_vein(lost_vein_id: String) -> void:
	if GameState.state["collective"].get("nadiaDefendVeinId") != lost_vein_id:
		return
	var vein: Variant = _pick_defend_vein_candidate(lost_vein_id)
	GameState.state["collective"]["nadiaDefendVeinId"] = vein["id"] if vein != null else null


# Fires col_a2_nadia_defend_brief the instant col_a2_nadia_supplies completes
# (spec §5.1's "supplies before defend, not parallel" sequencing), called
# from Crafting.attempt_craft()'s success branch after Objectives.refresh(),
# same shape as maybe_trigger_nadia_vein_done() above. colA2DefendBriefed
# (the scene's own on_complete flag) blocks re-firing.
static func maybe_trigger_a2_nadia_defend_brief() -> bool:
	if GameState.state["flags"].get("colA2DefendBriefed", false):
		return false
	if not GameState.state["objectives"].get("col_a2_nadia_supplies", {}).get("complete", false):
		return false

	Events.start_event("col_a2_nadia_defend_brief")
	return true


# Act 2 T9 (spec §6.9): Nadia texts col_a2_checkpoint once all three T8
# missions are complete, or CHECKPOINT_FALLBACK_DAYS after the ledger
# started, whichever first -- so a player who does two of three still sees
# the beat. Also stamps state.collective.ledgerStartedDay the first time it
# sees colA2LedgerStarted (Events.advance() calls this straight after T8's
# on_complete). Called from Events.advance(), TimeSystem.daily_tick() and
# the two action boundaries a last mission can complete at (Raiding.
# resolve_defend_outcome(), VeinTrade.transfer_to_faction()).
const CHECKPOINT_FALLBACK_DAYS := 14
const CHECKPOINT_MISSIONS: PackedStringArray = ["col_a2_nadia_defend", "col_a2_nadia_reseed", "col_a2_nadia_supplies"]


static func maybe_trigger_a2_checkpoint() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA2LedgerStarted", false):
		return false
	award_a2_missions()
	var collective: Dictionary = GameState.state["collective"]
	var day: int = GameState.state["world"]["day"]
	if collective.get("ledgerStartedDay") == null:
		collective["ledgerStartedDay"] = day

	if flags.get("colA2CheckpointSeen", false):
		return false
	for entry in Messages.pending_for("nadia"):
		if entry["kind"] == "col_a2_checkpoint":
			return false
	var active_event: Variant = GameState.state["event"]
	if active_event != null and active_event["eventId"] == "col_a2_checkpoint":
		return false

	if not _all_checkpoint_missions_complete() and day - int(collective["ledgerStartedDay"]) < CHECKPOINT_FALLBACK_DAYS:
		return false

	# PROSE-REVIEW: new SMS teaser, drafted against CONTENT-GUIDE.md.
	Messages.queue_pending("nadia", "col_a2_checkpoint", "\"Come by when you've a minute. I've got numbers.\"")
	return true


# Act 2 relation award table (spec §7.3): +4 per T8 mission, once each, on
# completion. Objectives.refresh() never awards, so this runs at the action
# boundaries a mission can complete at: Crafting.attempt_craft() (supplies),
# and every maybe_trigger_a2_checkpoint() call site via that function.
const A2_MISSION_RELATION := 4


static func award_a2_missions() -> void:
	var awarded: Array = GameState.state["collective"]["a2MissionsAwarded"]
	var objectives: Dictionary = GameState.state["objectives"]
	for id in CHECKPOINT_MISSIONS:
		if awarded.has(id) or not objectives.get(id, {}).get("complete", false):
			continue
		awarded.append(id)
		Factions.adjust_player_relation("collective", A2_MISSION_RELATION)


# Spec §7.3: +2 Collective relation per won alarm-defend fight during Phases
# 1-2 (T4 resolved, T12 not yet), capped at +4 a day. The day's running total
# lives in world.relationAwardedToday, which daily_tick already clears.
const A2_DEFEND_RELATION := 2
const A2_DEFEND_DAILY_CAP := 4
const A2_DEFEND_AWARD_KEY := "a2AlarmDefend"


static func award_a2_defend_win() -> void:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA2HandlerDeferred", false) or flags.get("networkHandlerUnlocked", false):
		return
	var awarded_today: Dictionary = GameState.state["world"]["relationAwardedToday"]
	var already: int = awarded_today.get(A2_DEFEND_AWARD_KEY, 0)
	var points: int = mini(A2_DEFEND_RELATION, A2_DEFEND_DAILY_CAP - already)
	if points <= 0:
		return
	awarded_today[A2_DEFEND_AWARD_KEY] = already + points
	Factions.adjust_player_relation("collective", points)


static func _all_checkpoint_missions_complete() -> bool:
	var objectives: Dictionary = GameState.state["objectives"]
	for id in CHECKPOINT_MISSIONS:
		if not objectives.get(id, {}).get("complete", false):
			return false
	return true


# Act 2 T10/T11 (spec §5.4): the col_a2_force_vein_loss op -- a story-
# triggered, unrolled ownership transfer to to_faction. vein_id may name a
# player vein (Raiding.transfer_player_vein_to_faction(), the raid claim
# branch's bookkeeping) or a Collective-held faction vein (Factions.
# resolve_rivalry_outcome()'s transfer branch). Returns false, touching
# nothing, once the vein is neither the player's nor the Collective's.
static func force_vein_loss(vein_id: Variant, to_faction: String) -> bool:
	if vein_id == null:
		return false
	var player_vein: Variant = Cultivating.find_vein(vein_id)
	if player_vein != null:
		var player_site: Variant = Sites.find_site(player_vein["siteId"])
		if player_site == null or player_site["factionVein"] != null:
			return false
		Raiding.transfer_player_vein_to_faction(player_vein, player_site, to_faction)
		EventBus.state_changed.emit()
		return true

	for site in Sites.sites_with_faction_vein("collective"):
		var vein: Dictionary = site["factionVein"]
		if vein["id"] != vein_id:
			continue
		vein["factionId"] = to_faction
		Factions.adjust_relation("collective", to_faction, Factions.RIVALRY_RELATION_PENALTY)
		MapEvents.queue_seed_claim(site["district"], vein["id"], to_faction)
		EventBus.state_changed.emit()
		return true
	return false


# Act 2 T11's target (spec §4.2/§5.4): the vein col_a2_nadia_defend named,
# if it's still the player's; otherwise the Collective's highest-raid-resist
# vein -- the player's own first, the faction's if the player holds none.
static func second_loss_target_id() -> Variant:
	var defend_id: Variant = GameState.state["collective"].get("nadiaDefendVeinId")
	if defend_id != null and Cultivating.find_vein(defend_id) != null:
		return defend_id

	var candidates: Array = GameState.state["player"]["veins"]
	if candidates.is_empty():
		candidates = Sites.sites_with_faction_vein("collective").map(func(s): return s["factionVein"])
	var best: Variant = null
	for vein in candidates:
		if best == null or Cultivating.vein_raid_resist(vein) > Cultivating.vein_raid_resist(best):
			best = vein
	return best["id"] if best != null else null


# Act 2 T10 (spec §6.10): after T9, Hakim's vein goes -- the transfer lands
# the moment his text does, so the text reports a loss that's already real.
# T11 (spec §6.11) follows once T10 has been read, never alongside it. Both
# wait on the daily tick, so neither lands on top of the scene before it,
# and neither queues while another col_a2_ beat is pending or playing.
# colA2HakimVeinLost blocks T10 re-firing; T11's own colA2SecondLossSeen
# (plus the in-flight check while it's pending or playing) blocks T11.
const HAKIM_VEIN_LOST_KIND := "col_a2_hakim_vein_lost"
const SECOND_LOSS_KIND := "col_a2_second_loss"


static func maybe_trigger_a2_crack() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA2CheckpointSeen", false) or _a2_beat_in_flight():
		return false

	if not flags.get("colA2HakimVeinLost", false):
		flags["colA2HakimVeinLost"] = true
		force_vein_loss(GameState.state["collective"]["hakimVeinId"], "firm")
		# PROSE-REVIEW: spec §6.10's own line, lightly punctuated.
		Messages.queue_pending("hakim", HAKIM_VEIN_LOST_KIND, "\"They've had the yard. I'm — it's fine. Everyone's fine. Come by when you can.\"")
		return true

	if not flags.get("colA2SecondLossSeen", false):
		# PROSE-REVIEW: new SMS teaser, drafted against CONTENT-GUIDE.md.
		Messages.queue_pending("nadia", SECOND_LOSS_KIND, "\"Another one's gone. Need you here.\"")
		return true
	return false


# Act 2 T13's gate (spec §6.13): any Targets purchase on Hakim's vein while
# the Firm holds it, "no" answers included -- the intel entry itself expires,
# the gate doesn't. Called by NetworkHandler.buy_target().
static func note_targets_purchase(site_id: String) -> void:
	var site: Variant = Sites.find_site(site_id)
	if site == null or site["factionVein"] == null:
		return
	var vein: Dictionary = site["factionVein"]
	if vein["factionId"] == "firm" and vein["id"] == GameState.state["collective"]["hakimVeinId"]:
		GameState.state["flags"]["colA2HakimIntelBought"] = true


# The col_a2_ruin_site op (spec §5.4), fired right after T13's retake lands:
# Hakim's retaken vein leaves state.player.veins; its site stays claimed but empty, with
# ruinedByFirm barring Sites.attempt_seed(). No-ops (false) unless the player
# holds the vein at state.collective.hakimVeinId.
static func ruin_hakim_site() -> bool:
	var vein_id: Variant = GameState.state["collective"]["hakimVeinId"]
	if vein_id == null:
		return false
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein == null:
		return false
	var site: Variant = Sites.find_site(vein["siteId"])
	if site == null:
		return false

	var player: Dictionary = GameState.state["player"]
	player["veins"] = player["veins"].filter(func(v): return v["id"] != vein_id)
	Sites.release_vein_slot(vein)
	maybe_retarget_nadia_defend_vein(vein_id)
	site["claimed"] = true
	site["ruinedByFirm"] = true
	EventBus.state_changed.emit()
	return true


# Act 2's gate (spec §7.4): all three Phase 1 choices logged, Hakim's vein
# retaken, and Collective relation >= 50.
const ACT2_GATE_RELATION := 50
const ACT2_METHOD_KEYS: PackedStringArray = ["a2ContestedVein", "a2VulnerableSite", "a2HostileMember"]
const CLOSER_KIND := "col_a2_closer"


static func act2_gate_met() -> bool:
	var method_log: Dictionary = GameState.state["methodLog"]
	for key in ACT2_METHOD_KEYS:
		if method_log.get(key) == null:
			return false
	if not GameState.state["flags"].get("colA2HakimRetaken", false):
		return false
	return GameState.state["factions"]["collective"]["relation"] >= ACT2_GATE_RELATION


# T14 (spec §6.14): the silent spine reward, fired the moment the gate is
# met. colA2SpineReward is what opens the weak-vein branch of
# maybe_trigger_hakim_intel(). Called from Events.advance() (T13's +15 is
# the usual crossing) and TimeSystem.daily_tick() (relation accrued later).
static func maybe_trigger_a2_spine_reward() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if flags.get("colA2SpineReward", false) or not act2_gate_met():
		return false

	flags["colA2SpineReward"] = true
	# PROSE-REVIEW: spec §6.14's own line.
	Messages.append("hakim", "them", "\"Started keeping half an ear out further afield, since. Don't get excited, I'm still mostly hearing about washing machines.\"")
	return true


# T15 (spec §6.15): queued from TimeSystem.daily_tick() only, so it lands a
# day or more behind T14's text. colA2Complete (its on_complete) blocks
# re-firing; the in-flight check blocks double-queueing.
static func maybe_trigger_a2_closer() -> bool:
	var flags: Dictionary = GameState.state["flags"]
	if not flags.get("colA2SpineReward", false) or flags.get("colA2Complete", false):
		return false
	if _a2_beat_in_flight():
		return false

	# PROSE-REVIEW: new SMS teaser, drafted against CONTENT-GUIDE.md.
	Messages.queue_pending("nadia", CLOSER_KIND, "\"Everyone's at Hakim's tonight. Bring yourself.\"")
	return true


static func _a2_beat_in_flight() -> bool:
	var active_event: Variant = GameState.state["event"]
	if active_event != null and str(active_event["eventId"]).begins_with("col_a2_"):
		return true
	for entry in GameState.state["pendingMessages"]:
		if str(entry["kind"]).begins_with("col_a2_"):
			return true
	return false
