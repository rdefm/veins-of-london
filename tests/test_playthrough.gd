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
# NPC-claim/NPC-abandonment (adr/0002) never permanently locks a district
# out of prospecting and that district-deck draws (D5) resolve, choice
# cards and all, without crashing. Formula-level coverage for all of that
# stays in test_sites.gd/test_district_deck.gd/test_district_events.gd —
# this file is integration-level only.


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
		faction_vein = { "id": "fv_" + id, "factionId": "collective", "oreType": "time", "level": 1, "devBar": 0, "security": "none", "claimedOnDay": faction_claimed_day }
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
	GameState.state["combat"]["enemy"]["hp"] = 1
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


func run() -> void:
	run_case("full_playthrough_tutorial_economy_ticks_and_save_roundtrip", func():
		GameState.reset()
		_assert_invariants("new game")

		# --- Tutorial (as T13), through M1's archie_cultivation ---
		_play_through_tutorial_and_unlock_prospecting()

		# --- Seed a vein (M0-style free-floating seed()), cultivate to Lv2, harvest ---
		GameState.state["player"]["orichalchum"]["time"] += 100
		var veins_before: int = GameState.state["player"]["veins"].size()
		var seed_seed := _find_seed_for(300, func():
			return Cultivating.seed("time").get("success", false)
		)
		assert_true(seed_seed != -1, "should find a successful seed roll")
		assert_eq(GameState.state["player"]["veins"].size(), veins_before + 1, "seeding should add a vein")
		_assert_invariants("post-seed")

		var new_vein: Dictionary = GameState.state["player"]["veins"][veins_before]
		var vein_id: String = new_vein["id"]
		# Push it right up to the Lv1->Lv2 threshold directly (formula
		# correctness is test_cultivating.gd's job), then force one
		# successful cultivate roll to cross it.
		new_vein["devBar"] = GameData.VEIN_LEVELS["1"]["devBarMax"] - 1
		var cult_seed := _find_seed_for(300, func():
			return Cultivating.cultivate(vein_id).get("success", false)
		)
		assert_true(cult_seed != -1, "should find a successful cultivate roll")
		var vein_after_cult: Dictionary = Cultivating.find_vein(vein_id)
		assert_eq(vein_after_cult["level"], 2, "vein should have reached Lv2")
		_assert_invariants("post-cultivate")

		vein_after_cult["charged"] = true
		var harvest_result := Cultivating.harvest_cautious(vein_id)
		assert_true(harvest_result["ok"], "harvest should succeed once charged")
		_assert_invariants("post-harvest")

		# --- Craft pearls ---
		GameState.state["player"]["orichalchum"]["time"] += 100
		var craft_seed := _find_seed_for(300, func():
			return Crafting.attempt_craft("timePearl").get("success", false)
		)
		assert_true(craft_seed != -1, "should find a successful craft roll")
		assert_true(GameState.state["player"]["inventory"]["timePearl"] > 0, "a successful craft should grant at least one pearl")
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
	# (greenwich/camden/hampstead — reachable only by paying D3's travel
	# block, unlike shoreditch/whitechapel which the tutorial already leaves
	# you in/near), gated behind archie_cultivation exactly as real play
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
			# (D3's travel-costs-a-block bookkeeping is test_sites.gd/test_
			# travel.gd's job — a multi-action, multi-district loop like this
			# one can cross a day boundary at any step, which resets
			# currentDistrict to shoreditch per D3, so re-asserting block
			# counts or currentDistrict here would just be flaky.)
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

			# --- harvest: charge it directly (recharge-block math is
			# test_cultivating.gd's job), then harvest cautiously ---
			var harvest_vein: Dictionary = Cultivating.find_vein(vein_id)
			harvest_vein["charged"] = true
			var harvest_result := Cultivating.harvest_cautious(vein_id)
			assert_true(harvest_result["ok"], "%s: harvest should succeed once charged" % district_id)
			assert_true(GameState.state["player"]["orichalchum"][harvest_result["oreType"]] > 0, "%s: harvest should grant ore" % district_id)
			_assert_invariants("%s: post-harvest" % district_id)

			# --- sell: in the district we're standing in (D3) ---
			var ore_type: String = harvest_result["oreType"]
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
	)

	# M1-LONDON-T08 (ticket 11), M1 exit criterion 4: siteCap + NPC-claim/
	# NPC-abandonment (D2, adr/0002) never permanently lock a district out of
	# prospecting, and district-deck draws (D5) — real content, not synthetic
	# test entries — resolve without crashing, across 20 seeds. The curve
	# math itself (probabilities, caps, floors) is test_sites.gd's job; this
	# is the integration proof that the whole loop holds up under repetition.
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
			var site_cap: int = GameData.DISTRICTS[district_id]["siteCap"]
			var sites: Array = [_make_site("soak_player_claimed", district_id, "fair", true, false)]
			for i in range(site_cap - 1):
				sites.append(_make_site("soak_npc_claimed_%d" % i, district_id, "poor", false, true, 1))
			GameState.state["world"]["sites"] = sites

			Rng.set_seed(seed)
			var ever_freed := false
			for day in range(2, 150):
				GameState.state["world"]["day"] = day
				Sites.roll_npc_claims()
				Sites.roll_npc_abandonment()
				var count: int = Sites.sites_in_district(district_id).size()
				assert_true(count <= site_cap, "seed %d, %s: siteCap must never be exceeded (day %d)" % [seed, district_id, day])
				assert_true(Sites.find_site("soak_player_claimed") != null, "seed %d, %s: the player-claimed slot is permanent (day %d)" % [seed, district_id, day])
				if count < site_cap:
					ever_freed = true
			assert_true(ever_freed, "seed %d, %s: NPC abandonment should free a slot within the simulated window" % [seed, district_id])
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
