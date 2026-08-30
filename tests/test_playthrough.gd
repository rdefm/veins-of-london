extends "res://tests/test_base.gd"

# M0-T14: seeded end-to-end playthrough — new game through the full
# tutorial (as T13), then a full economy loop, asserting invariants at
# every step rather than re-deriving formulas (those are covered by
# test_cultivating/test_crafting/test_economy/test_combat/test_events).
# scripts/soak.sh re-runs the whole suite 20 times for the R§ acceptance
# criterion ("green 20 consecutive runs across 20 seeds").
#
# M1-LONDON-T08 (ticket 11) extends this file with the M1 loop itself —
# prospect -> seed -> cultivate -> harvest -> sell via systems/sites.gd,
# across >=3 districts, gated behind the same archie_cultivation tutorial
# beat real play routes through — plus a 20-seed soak proving siteCap/
# NPC-claim (adr/0002) plus faction-vein growth-collapse (bugfixes-40
# removed the old separate NPC-abandonment roll; adr/0004) never
# permanently locks a district out of prospecting and that district-deck
# draws (D5) resolve, choice cards and all, without crashing.
# Formula-level coverage for all of that stays in
# test_sites.gd/test_district_deck.gd/test_district_events.gd — this file
# is integration-level only.


static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


# Same shape as test_sites.gd's/test_district_events.gd's own _make_site —
# kept here rather than shared across files since GDScript test files are
# standalone scripts with no import mechanism between them.
static func _make_site(id: String, district: String, tier: String, claimed: bool, faction_claimed: bool, faction_claimed_day: int = 1) -> Dictionary:
	var faction_vein: Variant = null
	if faction_claimed:
		faction_vein = { "id": "fv_" + id, "factionId": "collective", "oreType": "time", "growth": 20, "rampantDays": 0, "security": "none", "claimedOnDay": faction_claimed_day, "siteId": id, "hospitability": { "tier": "fair", "bonuses": [] } }
	return {
		"id": id, "district": district, "tier": tier, "oreType": "time",
		"bonuses": [], "discoveredDay": 1, "claimed": claimed, "factionVein": faction_vein,
		"hasNaturalVein": false,
	}


func _assert_invariants(label: String) -> void:
	var state: Dictionary = GameState.state
	assert_true(state["player"]["cash"] >= 0, "%s: cash should never go negative" % label)

	var hp: int = state["player"]["hp"]
	var hp_max: int = state["player"]["hpMax"]
	assert_true(hp >= 0 and hp <= hp_max, "%s: hp should stay within [0, hpMax]" % label)

	for key in GameState.new_game_state().keys():
		assert_true(state.has(key), "%s: state is missing top-level schema key '%s'" % [label, key])


func _force_win_active_combat() -> void:
	var attack_min: int = GameState.state["player"]["attackMin"]
	var attack_max: int = GameState.state["player"]["attackMax"]
	GameState.state["combat"]["enemies"][GameState.state["combat"]["focusedEnemyIndex"]]["hp"] = 1
	GameState.state["player"]["attackMin"] = 999
	GameState.state["player"]["attackMax"] = 999
	Rng.set_seed(1)
	Combat.player_attack()
	Combat.exit_combat()
	GameState.state["player"]["attackMin"] = attack_min
	GameState.state["player"]["attackMax"] = attack_max


# Shared by every case below: new game through the fixed tutorial beats
# (as T13) plus M1-LONDON D6's archie_cultivation, which is what actually
# flips cultivationTutorialSeen — real play triggers it by tapping the
# Whitechapel contact pin on the Network map (M1.5 T13, systems/map_pins.gd);
# driving it card-by-card here is the same idiom every other tutorial event
# in this file already uses.
func _play_through_tutorial_and_unlock_prospecting() -> void:
	for event_id in ["intro", "buyer", "james_meeting", "archie_craft_chat"]:
		Events.start_event(event_id)
		for i in range(GameData.EVENTS[event_id]["cards"].size()):
			Events.advance()
		_assert_invariants("post-%s" % event_id)
		# 83-contacts-archie-james-sms-port: buyer.json/james_meeting.json's
		# on_complete each queue the next beat as a real pendingMessages
		# entry for archie (ARCHIE_SMS_1's Continue, then the
		# archie_craft_chat trigger) -- real play resolves it via the card's
		# own Continue tap before the next event starts; mirror that here so
		# it doesn't sit unresolved and shadow archie_cultivation's own S1
		# entry below.
		for entry in Messages.pending_for("archie"):
			Messages.resolve_pending(entry["id"])

	Events.start_event("home_raid_intro")
	for i in range(GameData.EVENTS["home_raid_intro"]["cards"].size()):
		Events.advance()
	assert_true(GameState.state["combat"]["active"], "home_raid_intro should start combat")
	_force_win_active_combat()
	for i in range(GameData.EVENTS["home_raid_debrief_win"]["cards"].size()):
		Events.advance()
	_assert_invariants("post-home-raid")
	assert_eq(GameState.state["flags"]["tutorialStage"], "free", "tutorial should be complete")
	assert_true(GameState.state["flags"]["archiePartnerSeen"], "home-raid debrief should have set archiePartnerSeen")

	Events.start_event("archie_cultivation")
	for i in range(GameData.EVENTS["archie_cultivation"]["cards"].size()):
		Events.advance()
	assert_true(GameState.state["flags"]["cultivationTutorialSeen"], "archie_cultivation should unlock prospecting (D7 gating)")
	_assert_invariants("post-archie-cultivation")


# Drives whatever event is currently active (e.g. one fired by
# DistrictDeck.maybe_trigger off the back of Sites.prospect(), D5) to
# completion: forces a win on any combat that starts mid-event (event_
# mugging routes back to the still-active event per combat.gd's exit_
# combat), and always picks choice-card option 0. Deterministic and
# sufficient to prove "fires without crashing" — per-branch content
# correctness is test_district_events.gd's job, not this file's.
func _drive_active_event_to_completion() -> void:
	var guard := 0
	while GameState.state["event"] != null and guard < 50:
		guard += 1
		if GameState.state["combat"]["active"]:
			_force_win_active_combat()
		elif Events.is_awaiting_choice():
			Events.choose(0)
		else:
			Events.advance()
	assert_true(GameState.state["event"] == null, "a triggered district event should resolve well within 50 steps")


# collective1-18, spec.md §12.1: the Act 1 acceptance gate. Plays every
# scene's real event JSON card-by-card (same idiom every tests/test_col_a1_
# *.gd file already uses) up through S12 (col_a1_hakim_done) — the point
# where Collective.maybe_trigger_closer() (called from Events.advance()
# itself, see systems/collective.gd's comment) has just auto-queued S14 as a
# pendingMessages entry for Hakim — and asserts every §10.2 flag that's
# reachable by then. The two run_case()s below share this walk and diverge
# only on how they play S14 itself (joining outright vs. deferring).
#
# Phase 2's threads are driven through the real systems the spec calls out
# by name rather than shortcuts: Sites.prospect() (both for Des's two
# weather beats, S5/S6, which pre-empt the district deck per spec §10.4, and
# for the emotion site Nadia's vein sale needs), Economy sales (Collective.
# complete_trade(), the real Trade-button code path, for the three £-lane
# trades col_a1_nadia_supply needs), Cultivating.cultivate() (growing
# Hakim's handed-over vein from seed to the rescue threshold), and
# VeinTrade.sell_to_faction() (Nadia's vein sale, which also auto-starts
# S10).
func _play_collective_act1_through_all_three_threads() -> void:
	GameState.reset()
	_play_through_tutorial_and_unlock_prospecting()

	# ── S1: col_a1_intro, delivered via archie_cultivation's own pendingMessages entry ──
	var s1_pending: Array = Messages.pending_for("archie")
	assert_eq(s1_pending.size(), 1, "archie_cultivation should have queued exactly one pending entry")
	assert_eq(s1_pending[0]["kind"], "col_a1_intro")
	Messages.resolve_pending(s1_pending[0]["id"])
	Events.start_event("col_a1_intro")
	for i in range(GameData.EVENTS["col_a1_intro"]["cards"].size()):
		Events.advance()
	assert_true(GameState.state["contacts"]["des"]["unlocked"])
	assert_true(GameState.state["flags"]["colA1DesMet"])
	assert_true(GameState.state["flags"]["collectiveLaneUnlocked"])
	assert_eq(GameState.state["flags"]["colA1Stage"], "tuition")
	_assert_invariants("post-S1")

	# ── S2/S3: the prospecting/seeding tutorial (map-pin delivered; content driven directly) ──
	Events.start_event("col_a1_prospecting")
	for i in range(GameData.EVENTS["col_a1_prospecting"]["cards"].size()):
		Events.advance()
	assert_true(GameState.state["flags"]["colA1ProspectingTaught"])

	Events.start_event("col_a1_seeding")
	for i in range(GameData.EVENTS["col_a1_seeding"]["cards"].size()):
		Events.advance()
	assert_true(GameState.state["flags"]["colA1SeedingTaught"])
	_assert_invariants("post-S2-S3")

	# ── S4: col_a1_hub, delivered via Des's own pendingMessages entry from S3's on_complete ──
	var s4_pending: Array = Messages.pending_for("des")
	assert_eq(s4_pending.size(), 1)
	assert_eq(s4_pending[0]["kind"], "col_a1_hub")
	Messages.resolve_pending(s4_pending[0]["id"])
	Events.start_event("col_a1_hub")
	for i in range(GameData.EVENTS["col_a1_hub"]["cards"].size()):
		Events.advance()
	assert_true(GameState.state["contacts"]["nadia"]["unlocked"])
	assert_true(GameState.state["contacts"]["hakim"]["unlocked"])
	assert_eq(GameState.state["flags"]["colA1Stage"], "hub")
	assert_true(GameState.state["flags"]["colA1HubReached"])
	assert_true(GameState.state["flags"]["colA1DesThreadActive"])
	assert_true(GameState.state["flags"]["colA1ArchiePryAvailable"])
	Objectives.refresh()
	assert_true(GameState.state["objectives"]["col_a1_des_sites"]["active"])
	assert_true(GameState.state["objectives"]["col_a1_hakim_rescue"]["active"])
	_assert_invariants("post-S4")

	# ── S13: Archie's pry scene, "Push" branch — optional/missable, played here
	# so this walk also proves colA1AskedAboutDebt, per §10.2's flag list. ──
	Events.start_event("col_a1_archie_pry")
	Events.advance()  # narration -> Archie
	Events.advance()  # Archie -> choice
	Events.choose(1)  # Push -> hands off immediately into col_a1_archie_pry_debt
	while GameState.state["event"] != null:
		Events.advance()
	assert_true(GameState.state["flags"]["colA1AskedAboutDebt"])
	_assert_invariants("post-S13")

	# ── Des's thread: S5/S6 fire off real Sites.prospect() calls (spec §10.4) ──
	var fate_seed := _find_seed_for(500, func():
		var result := Sites.prospect("city")
		var site: Variant = result.get("site")
		return site != null and site["oreType"] == "fate" and GameData.SITE_TIER_ORDER.find(site["tier"]) >= GameData.SITE_TIER_ORDER.find("fair")
	)
	assert_true(fate_seed != -1, "should find a qualifying fate site in the City within 500 tries")
	assert_eq(GameState.state["event"]["eventId"], "col_a1_firm_skirmish", "S5 should auto-fire on the first qualifying site")
	_drive_active_event_to_completion()
	assert_true(GameState.state["flags"]["colA1SkirmishSeen"])
	_assert_invariants("post-S5")

	var physics_seed := _find_seed_for(500, func():
		var result := Sites.prospect("camden")
		var site: Variant = result.get("site")
		return site != null and site["oreType"] == "physics" and GameData.SITE_TIER_ORDER.find(site["tier"]) >= GameData.SITE_TIER_ORDER.find("fair")
	)
	assert_true(physics_seed != -1, "should find a qualifying physics site in Camden within 500 tries")
	assert_eq(GameState.state["event"]["eventId"], "col_a1_firm_intimidation", "S6 should auto-fire on the second qualifying site")
	_drive_active_event_to_completion()  # picks "Back off" (choice index 0)
	assert_eq(GameState.state["methodLog"]["firmFirstContact"], "backed_off")
	assert_true(GameState.state["flags"]["colA1IntimidationSeen"])
	_assert_invariants("post-S6")

	Objectives.refresh()
	assert_true(GameState.state["flags"]["colA1DesSitesFound"], "both qualifying sites together should complete col_a1_des_sites")

	Events.start_event("col_a1_des_report")
	for i in range(GameData.EVENTS["col_a1_des_report"]["cards"].size()):
		Events.advance()
	assert_true(GameState.state["flags"]["colA1DesThreadDone"])
	_assert_invariants("post-S7")

	# ── Nadia's thread: real Economy sales, then a real VeinTrade.sell_to_faction() ──
	Events.start_event("col_a1_nadia_meet")
	_drive_active_event_to_completion()
	assert_true(GameState.state["flags"]["colA1NadiaMet"])
	Objectives.refresh()  # stamps col_a1_nadia_supply's baseline before any trades happen
	assert_true(GameState.state["objectives"]["col_a1_nadia_supply"]["active"])

	GameState.state["player"]["orichalchum"]["emotion"] = 60
	for contact_id in ["des", "hakim", "nadia"]:
		GameState.state["sellState"]["ore_emotion"] = 10
		var trade_result := Collective.complete_trade(contact_id)
		assert_true(trade_result["ok"])
	assert_true(GameState.state["flags"]["colA1NadiaSupplied"], "3 trades of 10 emotion each, across all three Collective doors, should satisfy col_a1_nadia_supply")
	_assert_invariants("post-nadia-supply")

	Events.start_event("col_a1_nadia_vein")
	for i in range(GameData.EVENTS["col_a1_nadia_vein"]["cards"].size()):
		Events.advance()
	assert_true(GameState.state["flags"]["veinSaleUnlocked"])
	assert_true(GameState.state["flags"]["colA1NadiaAskSeen"])
	Objectives.refresh()
	assert_true(GameState.state["objectives"]["col_a1_nadia_vein"]["active"])

	GameState.state["player"]["orichalchum"]["emotion"] += 300
	var nadia_vein_site: Array = []
	var nadia_prospect_seed := _find_seed_for(500, func():
		var result := Sites.prospect("whitechapel")
		var site: Variant = result.get("site")
		if site == null or site["oreType"] != "emotion" or site["tier"] == "barren":
			return false
		nadia_vein_site.clear()
		nadia_vein_site.append(site)
		return true
	)
	assert_true(nadia_prospect_seed != -1, "should find an emotion site in Whitechapel within 500 tries")
	var nadia_site_id: String = nadia_vein_site[0]["id"]
	_drive_active_event_to_completion()
	_assert_invariants("post-nadia-vein-prospect")

	var nadia_vein_seed_roll := _find_seed_for(500, func():
		return Sites.attempt_seed(nadia_site_id).get("success", false)
	)
	assert_true(nadia_vein_seed_roll != -1, "should find a successful seed roll within 500 tries")
	var nadia_vein_id: String = GameState.state["player"]["veins"].filter(func(v): return v["siteId"] == nadia_site_id)[0]["id"]

	var sell_result := VeinTrade.sell_to_faction(nadia_vein_id, "collective")
	assert_true(sell_result["ok"])
	assert_eq(GameState.state["event"]["eventId"], "col_a1_nadia_done", "the qualifying vein sale should auto-start S10")
	_drive_active_event_to_completion()
	assert_true(GameState.state["flags"]["colA1NadiaThreadDone"])
	_assert_invariants("post-S10")

	# ── Hakim's thread: a real Cultivating.cultivate() loop from seed to the rescue threshold ──
	Events.start_event("col_a1_hakim_meet")
	_drive_active_event_to_completion()
	assert_true(GameState.state["flags"]["colA1HakimMet"])

	var hakim_vein_id: String = GameState.state["collective"]["hakimVeinId"]
	assert_true(hakim_vein_id != null and hakim_vein_id != "")
	var threshold: int = GameData.OBJECTIVES["col_a1_hakim_rescue"]["params"]["threshold"]
	var rescue_guard := 0
	while Cultivating.find_vein(hakim_vein_id)["growth"] < threshold and rescue_guard < 20:
		rescue_guard += 1
		var cult_seed := _find_seed_for(500, func():
			return Cultivating.cultivate(hakim_vein_id).get("success", false)
		)
		assert_true(cult_seed != -1, "should find a successful cultivate roll within 500 tries")
	assert_true(Cultivating.find_vein(hakim_vein_id)["growth"] >= threshold, "Hakim's vein should reach the rescue threshold within 20 successful cultivates")
	assert_true(GameState.state["flags"]["colA1HakimRescued"])
	_assert_invariants("post-hakim-cultivate")

	Events.start_event("col_a1_hakim_done")
	for i in range(GameData.EVENTS["col_a1_hakim_done"]["cards"].size()):
		Events.advance()
	assert_true(GameState.state["flags"]["colA1HakimThreadDone"])
	assert_true(GameState.state["flags"]["hakimIntelUnlocked"])
	_assert_invariants("post-S12")

	# ── Phase 3's gate: all three threads done + relation >= 25 (guaranteed by
	# the +27 favour total alone, per spec §8.5) auto-queues S14 for Hakim,
	# from inside col_a1_hakim_done's own advance() call (see systems/
	# collective.gd's maybe_trigger_closer() comment) ──
	assert_true(GameState.state["factions"]["collective"]["relation"] >= 25)
	var closer_pending: Array = Messages.pending_for("hakim")
	var found_closer := false
	for entry in closer_pending:
		if entry["kind"] == "col_a1_closer":
			found_closer = true
	assert_true(found_closer, "the closer should have auto-queued the instant all three threads completed")

	# Every §10.2 flag reachable before S14 itself has landed.
	var flags: Dictionary = GameState.state["flags"]
	for flag_name in ["colA1DesMet", "colA1ProspectingTaught", "colA1SeedingTaught", "colA1HubReached",
			"colA1DesThreadActive", "colA1DesSitesFound", "colA1DesThreadDone", "colA1SkirmishSeen",
			"colA1IntimidationSeen", "colA1NadiaMet", "colA1NadiaSupplied", "colA1NadiaAskSeen",
			"colA1NadiaThreadDone", "colA1HakimMet", "colA1HakimRescued", "colA1HakimThreadDone",
			"colA1ArchiePryAvailable", "colA1AskedAboutDebt", "collectiveLaneUnlocked",
			"veinSaleUnlocked", "hakimIntelUnlocked"]:
		assert_true(flags.get(flag_name, false), "flag %s should have landed by the end of phase 2" % flag_name)
	assert_true(not flags.get("colA1Complete", false), "S14 hasn't been played yet")


# Resolves the one pendingMessages entry of the given kind for a contact --
# both new S14 run_case()s below need this for the closer's own Hakim text.
func _resolve_pending_by_kind(contact_id: String, kind: String) -> void:
	for entry in Messages.pending_for(contact_id):
		if entry["kind"] == kind:
			Messages.resolve_pending(entry["id"])
			return
	assert_true(false, "no pending %s entry found for %s" % [kind, contact_id])


# Same choice-driving idiom as tests/test_col_a1_closer.gd's own
# _play_event_with_choices() -- not shared with it directly (per this file's
# own _make_site comment: standalone test scripts have no import mechanism
# between them), but at least not duplicated a second time within this file.
func _play_event_with_choices(event_id: String, choices: Array) -> void:
	Events.start_event(event_id)
	var choice_i := 0
	while GameState.state["event"] != null:
		if Events.is_awaiting_choice():
			Events.choose(choices[choice_i])
			choice_i += 1
		else:
			Events.advance()


func run() -> void:
	run_case("full_playthrough_tutorial_economy_ticks_and_save_roundtrip", func():
		GameState.reset()
		_assert_invariants("new game")

		# --- Tutorial (as T13), through M1's archie_cultivation ---
		_play_through_tutorial_and_unlock_prospecting()

		# --- Prospect + seed a vein via Sites.attempt_seed(), cultivate to Lv2, harvest ---
		GameState.state["player"]["orichalchum"]["time"] += 100
		var district_id: String = GameState.state["world"]["currentDistrict"]
		var found_site: Array = []
		var prospect_seed := _find_seed_for(500, func():
			var result := Sites.prospect(district_id)
			if not result["ok"] or result["site"] == null:
				return false
			if result["site"]["tier"] == "barren":
				return false
			found_site.clear()
			found_site.append(result["site"])
			return true
		)
		assert_true(prospect_seed != -1, "should find a non-barren prospect roll")
		var site_id: String = found_site[0]["id"]
		_drive_active_event_to_completion()  # D5: prospect can draw a district event
		_assert_invariants("post-prospect")

		var seed_seed := _find_seed_for(300, func():
			return Sites.attempt_seed(site_id).get("success", false)
		)
		assert_true(seed_seed != -1, "should find a successful seed roll")
		assert_true(Sites.find_site(site_id)["claimed"], "seeding should claim the site")
		_assert_invariants("post-seed")

		var seeded_veins: Array = GameState.state["player"]["veins"].filter(func(v): return v["siteId"] == site_id)
		assert_true(seeded_veins.size() >= 1, "seeding should create a vein tied to the site")
		var new_vein: Dictionary = seeded_veins[0]
		var vein_id: String = new_vein["id"]
		# Force one successful cultivate roll (formula correctness is
		# test_cultivating.gd's job).
		var cult_seed := _find_seed_for(300, func():
			return Cultivating.cultivate(vein_id).get("success", false)
		)
		assert_true(cult_seed != -1, "should find a successful cultivate roll")
		var vein_after_cult: Dictionary = Cultivating.find_vein(vein_id)
		assert_true(vein_after_cult["growth"] > GameData.VEIN_GROWTH["seedGrowth"], "a successful cultivate should raise growth above the seed value")
		_assert_invariants("post-cultivate")

		vein_after_cult["growth"] = 80
		var prune_result := Cultivating.prune(vein_id, GameData.VEIN_GROWTH["pruneLightDepth"])
		assert_true(prune_result["ok"], "prune should succeed on a wild vein")
		_assert_invariants("post-prune")

		# --- Craft pearls ---
		GameState.state["player"]["orichalchum"]["time"] += 100
		var craft_seed := _find_seed_for(300, func():
			return Crafting.attempt_craft("timePearl").get("success", false)
		)
		assert_true(craft_seed != -1, "should find a successful craft roll")
		assert_true(Crafting.inventory_qty("timePearl") > 0, "a successful craft should grant at least one pearl")
		_assert_invariants("post-craft")

		# --- Sell: force both a mugged and a non-mugged branch ---
		GameState.state["player"]["orichalchum"]["time"] += 50
		var no_mug_seed := _find_seed_for(300, func():
			var r := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 5 }])
			return r["ok"] and not r["mugged"]
		)
		assert_true(no_mug_seed != -1, "should find a non-mugged sale roll")
		_assert_invariants("post-sale-no-mug")

		GameState.state["player"]["orichalchum"]["time"] += 50
		var mug_seed := _find_seed_for(300, func():
			var r := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 5 }])
			return r["ok"] and r.get("mugged", false)
		)
		assert_true(mug_seed != -1, "should find a mugged sale roll")
		assert_true(GameState.state["combat"]["active"], "a mugged sale should start combat")
		_force_win_active_combat()
		_assert_invariants("post-sale-mugged")

		# --- Buy security ---
		GameState.state["player"]["cash"] += 10000
		var security_before: int = GameState.state["home"]["security"].size()
		var security_result := Home.add_security(GameData.HOME_SECURITY.keys()[0])
		assert_true(security_result["ok"], "should afford security after the cash top-up")
		assert_eq(GameState.state["home"]["security"].size(), security_before + 1, "security should be installed")
		_assert_invariants("post-buy-security")

		# --- Join no faction ---
		for faction_id in GameState.state["factions"].keys():
			assert_true(not GameState.state["factions"][faction_id]["joined"], "should not have joined any faction")

		# --- 10 daily ticks ---
		for i in range(10):
			TimeSystem.daily_tick()
			_assert_invariants("daily tick %d" % (i + 1))

		# --- Save/load mid-run round-trip ---
		var pre_save: Dictionary = GameState.deep_copy(GameState.state)
		var save_result := SaveManager.save_to_slot(0)
		assert_true(save_result["ok"], "save should succeed")
		GameState.reset()
		var load_result := SaveManager.load_from_slot(0)
		assert_true(load_result["ok"], "load should succeed")
		assert_eq(GameState.state, pre_save, "loaded state should exactly match the pre-save snapshot")
		SaveManager.delete_slot(0)
		_assert_invariants("post-save-load-roundtrip")
	)

	# M1-LONDON-T08 (ticket 11), M1 exit criterion 1's action chain: prospect
	# -> seed -> cultivate -> harvest -> sell, across 3 distinct districts
	# (greenwich/camden/hampstead — not the district the tutorial already
	# leaves you in/near, unlike shoreditch/whitechapel; D3: acting there
	# costs no more than acting at home, faction-resource-economy ticket 05),
	# gated behind archie_cultivation exactly as real play
	# routes through it. This drives systems/sites.gd's D2 actions directly
	# rather than through scenes/screens/map.gd — matching every other test
	# in this suite (none drive the scene tree; UI wiring is this project's
	# documented human-visual-QA territory, per CLAUDE.md's workflow rules)
	# — so it proves the action chain and its data, not the Map tab's button
	# wiring, which is a thin pass-through per D4's "screens... call system
	# functions... not one line [of logic]" doctrine.
	run_case("m1_loop_prospect_seed_cultivate_harvest_sell_across_three_districts", func():
		GameState.reset()
		_play_through_tutorial_and_unlock_prospecting()

		GameState.state["player"]["cash"] += 5000
		var ore: Dictionary = GameState.state["player"]["orichalchum"]
		for ore_type in GameData.ORE_TYPES.keys():
			ore[ore_type] = ore.get(ore_type, 0) + 300

		for district_id in ["greenwich", "camden", "hampstead"]:
			# --- prospect: find a non-barren (seedable) site ---
			# (D3's currentDistrict bookkeeping is test_sites.gd/test_travel.gd's
			# job — a multi-action, multi-district loop like this one can cross
			# a day boundary at any step, which resets currentDistrict to
			# shoreditch per D3, so re-asserting block counts or currentDistrict
			# here would just be flaky.)
			# found_site is a one-element holder, not a plain local: _find_seed_for's
			# Callable can't hand a value back through its bool return, but an
			# Array is a reference type, so mutating its contents (never
			# reassigning the variable itself) from inside the closure does
			# reach this outer scope — unlike GDScript's by-value capture of
			# plain locals.
			var found_site: Array = []
			var prospect_seed := _find_seed_for(500, func():
				var result := Sites.prospect(district_id)
				if not result["ok"] or result["site"] == null:
					return false
				if result["site"]["tier"] == "barren":
					return false
				found_site.clear()
				found_site.append(result["site"])
				return true
			)
			assert_true(prospect_seed != -1, "%s: should find a non-barren prospect roll within 500 tries" % district_id)
			var site_id: String = found_site[0]["id"]
			assert_eq(found_site[0]["district"], district_id, "the prospected site belongs to the target district")
			_drive_active_event_to_completion()  # D5: prospect can draw a district event
			_assert_invariants("%s: post-prospect" % district_id)

			# Exit criterion 3: site quality (tier/ore/bonuses) is visible before seeding.
			var site_before_seed: Dictionary = Sites.find_site(site_id)
			assert_true(GameData.SITE_TIER_WEIGHTS.has(site_before_seed["tier"]), "%s: tier is visible pre-seed" % district_id)
			assert_true(GameData.ORE_TYPES.has(site_before_seed["oreType"]), "%s: ore type is visible pre-seed" % district_id)

			# --- seed: claim the site ---
			var seed_seed := _find_seed_for(500, func():
				return Sites.attempt_seed(site_id).get("success", false)
			)
			assert_true(seed_seed != -1, "%s: should find a successful seed roll within 500 tries" % district_id)
			assert_true(Sites.find_site(site_id)["claimed"], "%s: seeding should claim the site" % district_id)
			# (attempt_seed doesn't call DistrictDeck.maybe_trigger — D5's
			# trigger is travel/prospect only — so no event-drive needed here.)
			_assert_invariants("%s: post-seed" % district_id)

			var seeded_veins: Array = GameState.state["player"]["veins"].filter(func(v): return v["siteId"] == site_id)
			assert_true(seeded_veins.size() >= 1, "%s: seeding should create a vein tied to the site" % district_id)
			var vein: Dictionary = seeded_veins[0]
			var vein_id: String = vein["id"]

			# --- cultivate: at least one successful session ---
			var cult_seed := _find_seed_for(500, func():
				return Cultivating.cultivate(vein_id).get("success", false)
			)
			assert_true(cult_seed != -1, "%s: should find a successful cultivate roll within 500 tries" % district_id)
			_assert_invariants("%s: post-cultivate" % district_id)

			# --- prune: push it above neutral directly (drift/band math is
			# test_cultivating.gd's job), then prune it ---
			var prune_vein: Dictionary = Cultivating.find_vein(vein_id)
			prune_vein["growth"] = 80
			var prune_result := Cultivating.prune(vein_id, GameData.VEIN_GROWTH["pruneLightDepth"])
			assert_true(prune_result["ok"], "%s: prune should succeed above neutral" % district_id)
			assert_true(GameState.state["player"]["orichalchum"][prune_result["oreType"]] > 0, "%s: prune should grant ore" % district_id)
			_assert_invariants("%s: post-prune" % district_id)

			# --- sell: in the district we're standing in (D3) ---
			var ore_type: String = prune_result["oreType"]
			var cash_before: int = GameState.state["player"]["cash"]
			var sell_seed := _find_seed_for(500, func():
				var have: int = GameState.state["player"]["orichalchum"].get(ore_type, 0)
				if have < 1:
					return false
				var r := Economy.execute_sale([{ "kind": "ore", "type": ore_type, "qty": 1 }])
				return r["ok"] and not r.get("mugged", true)
			)
			assert_true(sell_seed != -1, "%s: should find a non-mugged sale roll within 500 tries" % district_id)
			assert_true(GameState.state["player"]["cash"] >= cash_before, "%s: a non-mugged sale should never reduce cash" % district_id)
			_assert_invariants("%s: post-sell" % district_id)

		# --- neglect arm (spec §11 item 11): a vein left entirely alone (no
		# cultivate/prune) should drift down through the left-hand bands,
		# bottom out at growth 0, and eventually be removed by the collapse
		# roll (Cultivating.collapse_vein, spec §2.5) -- reverting its site to
		# unclaimed rather than deleting it outright the way a faction vein's
		# own collapse does (same roll, branches by owner) -- leaving that
		# site genuinely seedable again.
		# Drives this through Cultivating.drift_veins() directly rather than
		# TimeSystem.daily_tick(): daily_tick's own NPC-claim roll (step ⑤b)
		# runs immediately after drift/collapse (step ④) within the same
		# tick, so driving the vein to collapse via daily_tick would race an
		# NPC claim onto the site the instant it reverts to unclaimed -- a
		# real but unrelated mechanic already soak-tested elsewhere in this
		# file (m1_20_seed_soak...). drift_veins() is the exact function
		# daily_tick calls for growth/collapse, so this still exercises the
		# real system entry point.
		for ore_type in GameData.ORE_TYPES.keys():
			GameState.state["player"]["orichalchum"][ore_type] = GameState.state["player"]["orichalchum"].get(ore_type, 0) + 300

		var neglect_district := "battersea"
		var neglect_site: Array = []
		var neglect_prospect_seed := _find_seed_for(500, func():
			var result := Sites.prospect(neglect_district)
			if not result["ok"] or result["site"] == null:
				return false
			if result["site"]["tier"] == "barren":
				return false
			neglect_site.clear()
			neglect_site.append(result["site"])
			return true
		)
		assert_true(neglect_prospect_seed != -1, "neglect arm: should find a non-barren prospect roll within 500 tries")
		var neglect_site_id: String = neglect_site[0]["id"]
		_drive_active_event_to_completion()
		_assert_invariants("neglect: post-prospect")

		var neglect_seed_seed := _find_seed_for(500, func():
			return Sites.attempt_seed(neglect_site_id).get("success", false)
		)
		assert_true(neglect_seed_seed != -1, "neglect arm: should find a successful seed roll within 500 tries")
		var neglect_vein_id: String = GameState.state["player"]["veins"].filter(func(v): return v["siteId"] == neglect_site_id)[0]["id"]
		assert_eq(Cultivating.find_vein(neglect_vein_id)["growth"], GameData.VEIN_GROWTH["seedGrowth"], "neglect arm: freshly seeded vein starts at seedGrowth")
		_assert_invariants("neglect: post-seed")

		# Phase 1: left alone, drift it all the way down to growth 0. A seed
		# search (not a bare loop) because the very tick growth first clamps
		# to 0 also carries that tick's collapse roll (spec §2.5 -- no grace
		# period), so an unlucky same-day hit skips straight past the
		# "bottomed but still there" state this phase wants to witness; that
		# outcome is still spec-correct, just not what phase 1 is proving, so
		# retry with a fresh seed rather than accept it here.
		var bottom_seed := _find_seed_for(300, func():
			for i in range(60):
				Cultivating.drift_veins()
				var v: Variant = Cultivating.find_vein(neglect_vein_id)
				if v == null:
					return false
				if v["growth"] == 0:
					return true
			return false
		)
		assert_true(bottom_seed != -1, "neglect arm: an untouched vein should drift down to growth 0 within 60 days")
		assert_eq(Cultivating.find_vein(neglect_vein_id)["growth"], 0, "neglect arm: bottomed-out vein sits at exactly 0, not negative")
		_assert_invariants("neglect: post-bottom-out")

		# Phase 2: sitting at 0, the collapse roll (15%/day) should
		# eventually remove it -- P(never in 50 days) ~= 0.85^50, and this
		# itself is retried across up to 100 seeds, so failure here would
		# mean the roll isn't firing at all, not bad luck.
		var collapse_seed := _find_seed_for(100, func():
			for i in range(50):
				Cultivating.drift_veins()
				if Cultivating.find_vein(neglect_vein_id) == null:
					return true
			return false
		)
		assert_true(collapse_seed != -1, "neglect arm: a vein pinned at 0 should eventually be removed by the collapse roll")
		_assert_invariants("neglect: post-collapse")

		var reverted_site: Variant = Sites.find_site(neglect_site_id)
		assert_true(reverted_site != null, "neglect arm: the site itself survives removal -- it reverts, it isn't deleted")
		assert_eq(reverted_site["claimed"], false, "neglect arm: the site should revert to unclaimed on removal (a faction vein's collapse deletes its site outright instead)")

		var reseed_seed := _find_seed_for(500, func():
			return Sites.attempt_seed(neglect_site_id).get("success", false)
		)
		assert_true(reseed_seed != -1, "neglect arm: the reverted site should be seedable again within 500 tries")
		assert_true(Sites.find_site(neglect_site_id)["claimed"], "neglect arm: re-seeding should re-claim the site")
		_assert_invariants("neglect: post-reseed")
	)

	# M1-LONDON-T08 (ticket 11), M1 exit criterion 4: siteCap + NPC-claim
	# (D2, adr/0002) plus faction-vein growth-collapse (bugfixes-40/adr/0004
	# — the death path that replaced NPC-abandonment) never permanently lock
	# a district out of prospecting, and district-deck draws (D5) — real
	# content, not synthetic test entries — resolve without crashing, across
	# 20 seeds. The curve math itself (probabilities, caps, floors) is
	# test_sites.gd's job; this is the integration proof that the whole loop
	# holds up under repetition.
	run_case("m1_20_seed_soak_no_permanent_district_lockout_and_event_draws_dont_crash", func():
		var districts: Array[String] = ["greenwich", "camden", "hampstead", "battersea"]
		var events_driven := 0

		for seed in range(20):
			var district_id: String = districts[seed % districts.size()]

			GameState.reset()
			GameState.state["player"]["cash"] += 100000

			# adr/0002's motivating scenario (mirrored from test_sites.gd's
			# soak case, here run through the full prospect() action so its
			# district-deck draw also gets exercised): one permanent player-
			# claim plus every remaining siteCap slot NPC-claimed, so the
			# district starts fully maxed-out and locked to fresh prospecting.
			# Freeing a slot now drives entirely through Cultivating.
			# drift_veins() (step ④'s growth-collapse roll, same path a player
			# vein uses) since bugfixes-40 removed the separate NPC-
			# abandonment roll this soak used to drive through directly.
			var site_cap: int = GameData.DISTRICTS[district_id]["siteCap"]
			var sites: Array = [_make_site("soak_player_claimed", district_id, "fair", true, false)]
			for i in range(site_cap - 1):
				sites.append(_make_site("soak_npc_claimed_%d" % i, district_id, "poor", false, true, 1))
			GameState.state["world"]["sites"] = sites

			Rng.set_seed(seed)
			var ever_freed := false
			for day in range(2, 150):
				GameState.state["world"]["day"] = day
				Cultivating.drift_veins()
				Sites.roll_npc_claims()
				var count: int = Sites.sites_in_district(district_id).size()
				assert_true(count <= site_cap, "seed %d, %s: siteCap must never be exceeded (day %d)" % [seed, district_id, day])
				assert_true(Sites.find_site("soak_player_claimed") != null, "seed %d, %s: the player-claimed slot is permanent (day %d)" % [seed, district_id, day])
				if count < site_cap:
					ever_freed = true
			assert_true(ever_freed, "seed %d, %s: faction-vein growth-collapse should free a slot within the simulated window" % [seed, district_id])
			_assert_invariants("seed %d, %s: post-aging" % [seed, district_id])

			# The freed slot(s) should let prospecting create genuinely new
			# sites again — the first call after the aging loop is guaranteed
			# room (ever_freed asserted above), so it must produce a real new
			# site, not a no-op reroll; that's the actual non-lockout proof,
			# not just "the action returns ok" (prospect() returns ok:true
			# unconditionally whenever siteCap > 0, per systems/sites.gd).
			var count_before_refill: int = Sites.sites_in_district(district_id).size()
			var refill_result := Sites.prospect(district_id)
			assert_true(refill_result["ok"], "seed %d, %s: prospect should succeed once a slot is free" % [seed, district_id])
			assert_true(refill_result["site"] != null, "seed %d, %s: a freed slot must yield a genuinely new site, not a no-op" % [seed, district_id])
			assert_eq(Sites.sites_in_district(district_id).size(), count_before_refill + 1, "seed %d, %s: the freed slot's site count should grow by exactly one" % [seed, district_id])
			if GameState.state["event"] != null:
				events_driven += 1
			_drive_active_event_to_completion()
			_assert_invariants("seed %d, %s: post-refill-prospect" % [seed, district_id])

			# A few more, to also exercise D5's maybe_trigger (25%/prospect)
			# across real district-deck content once the district may be back
			# at siteCap (reroll branch) as well as still under it.
			for i in range(4):
				var result := Sites.prospect(district_id)
				assert_true(result["ok"], "seed %d, %s: prospect action itself should always succeed (block spent)" % [seed, district_id])
				assert_true(Sites.sites_in_district(district_id).size() <= site_cap, "seed %d, %s: prospect must never exceed siteCap" % [seed, district_id])
				if GameState.state["event"] != null:
					events_driven += 1
				_drive_active_event_to_completion()
				_assert_invariants("seed %d, %s: post-prospect %d" % [seed, district_id, i])

		# The real, non-tautological proof that D5's district-deck draws
		# actually fire (not just "would compile if they did"): across 20
		# seeds x 5 prospects each, at chance(0.25)/prospect, expected ~25
		# draws — assert at least one really happened and was resolved.
		assert_true(events_driven > 0, "the soak run should have driven at least one real district-deck event across 100 prospect calls")
	)

	# The soak above only *opportunistically* hits district events with a
	# choice card or mid-event combat (only camden_shakedown, D5 #3, has
	# both, and only 5/20 seeds even visit camden) — so prove that branch of
	# _drive_active_event_to_completion deterministically here, independent
	# of soak-run luck, the same way test_district_events.gd forces
	# camden_shakedown's mugging branch.
	run_case("district_event_driver_resolves_choice_cards_and_mid_event_combat", func():
		GameState.reset()
		var combat_seed := _find_seed_for(300, func():
			Events.start_event("camden_shakedown")
			Events.advance()  # narration
			Events.advance()  # speaker
			Events.choose(1)  # Refuse -> chance(0.4) of start_street_mugging
			return GameState.state["combat"]["active"]
		)
		assert_true(combat_seed != -1, "should find a seed where refusing camden_shakedown starts combat within 300 tries")
		assert_true(GameState.state["event"] != null, "the event should still be active while its combat branch resolves")

		_drive_active_event_to_completion()
		assert_eq(GameState.state["event"], null, "the generic driver should resolve the choice-triggered combat and finish the event")
		assert_true(not GameState.state["combat"]["active"], "combat should be torn down once resolved")
		_assert_invariants("post-camden-shakedown-combat-branch")
	)

	# collective1-18, spec.md §12.1: the Act 1 acceptance gate, join-outright
	# variant. Plays S14 with "Thank him" + "I'm in" and asserts every §10.2
	# flag lands, including the ones only S14 itself can set.
	run_case("collective_act1_full_playthrough_joins_the_collective_and_every_flag_lands", func():
		_play_collective_act1_through_all_three_threads()

		_resolve_pending_by_kind("hakim", "col_a1_closer")
		_play_event_with_choices("col_a1_closer", [0, 0])  # "Thank him", then "I'm in"

		assert_true(GameState.state["flags"]["colA1Complete"])
		assert_eq(GameState.state["flags"]["colA1Stage"], "complete")
		assert_true(GameState.state["flags"]["colA1Joined"])
		assert_true(GameState.state["factions"]["collective"]["joined"])
		assert_true(not GameState.state["flags"].get("colA1DeferredJoin", false), "joining outright must never set the deferred-join flag")
		_assert_invariants("post-S14-joined")

		# The full §10.2 flag list, this time including S14's own flags.
		var flags: Dictionary = GameState.state["flags"]
		for flag_name in ["colA1DesMet", "colA1ProspectingTaught", "colA1SeedingTaught", "colA1HubReached",
				"colA1DesThreadActive", "colA1DesSitesFound", "colA1DesThreadDone", "colA1SkirmishSeen",
				"colA1IntimidationSeen", "colA1NadiaMet", "colA1NadiaSupplied", "colA1NadiaAskSeen",
				"colA1NadiaThreadDone", "colA1HakimMet", "colA1HakimRescued", "colA1HakimThreadDone",
				"colA1ArchiePryAvailable", "colA1AskedAboutDebt", "colA1Complete", "colA1Joined",
				"collectiveLaneUnlocked", "veinSaleUnlocked", "hakimIntelUnlocked"]:
			assert_true(flags.get(flag_name, false), "flag %s should have landed" % flag_name)

		assert_true(GameState.state["objectives"]["col_a1_des_sites"]["complete"])
		assert_true(GameState.state["objectives"]["col_a1_nadia_supply"]["complete"])
		assert_true(GameState.state["objectives"]["col_a1_nadia_vein"]["complete"])
		assert_true(GameState.state["objectives"]["col_a1_hakim_rescue"]["complete"])
	)

	# collective1-18, spec.md §12.1/§6.15: the acceptance gate's second
	# variant — declining membership at S14 ("Insist on paying" + "Not yet")
	# must still leave the act complete and the deferred-join follow-up
	# (col_a1_deferred_join, spec §6.15's closing note) must grant membership
	# later, on the player's own initiative.
	run_case("collective_act1_declining_at_S14_defers_membership_until_the_deferred_join_follow_up", func():
		_play_collective_act1_through_all_three_threads()

		_resolve_pending_by_kind("hakim", "col_a1_closer")
		_play_event_with_choices("col_a1_closer", [1, 1])  # "Insist on paying", then "Not yet"

		assert_true(GameState.state["flags"]["colA1Complete"], "declining still completes the act")
		assert_eq(GameState.state["flags"]["colA1Stage"], "complete")
		assert_true(GameState.state["flags"]["colA1DeferredJoin"])
		assert_true(not GameState.state["flags"].get("colA1Joined", false), "declining must not join outright")
		assert_true(not GameState.state["factions"]["collective"]["joined"])
		_assert_invariants("post-S14-deferred")

		# The deferred-join follow-up: reachable from Des's action bar
		# (ContactCards.build_ask_des_joining_action(), per tests/
		# test_col_a1_closer.gd) whenever colA1DeferredJoin is set — driven
		# here as the event it starts, same idiom as every other thread-
		# resolution scene in this walk.
		Events.start_event("col_a1_deferred_join")
		for i in range(GameData.EVENTS["col_a1_deferred_join"]["cards"].size()):
			Events.advance()

		assert_true(GameState.state["flags"]["colA1Joined"], "the deferred-join follow-up should grant membership later")
		assert_true(GameState.state["factions"]["collective"]["joined"])
		_assert_invariants("post-deferred-join")
	)
