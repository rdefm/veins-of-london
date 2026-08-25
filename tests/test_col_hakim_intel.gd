extends "res://tests/test_base.gd"

# collective1-17, spec.md §5.8/§6.16: Hakim's repeatable post-Act-1 intel --
# Collective.maybe_trigger_hakim_intel()'s daily-tick roll (unlock gate,
# 3-day minimum gap, siteCap suppression, fair-or-better tier, Shoreditch/
# Whitechapel only), the col_hakim_intel event's on_complete (reveal_site,
# set_hakim_intel_day), and the daily_tick wiring test in
# tests/test_time_system.gd.


func _play_event(event_id: String, context: Dictionary = {}) -> void:
	Events.start_event(event_id, context)
	for i in range(GameData.EVENTS[event_id]["cards"].size()):
		Events.advance()


func _sites(district: String, count: int) -> Array:
	var sites: Array = []
	for i in range(count):
		sites.append({
			"id": "cap%d" % i, "district": district, "tier": "poor", "oreType": "time",
			"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null,
			"hasNaturalVein": false,
		})
	return sites


func run() -> void:
	# ── delivery: Collective.maybe_trigger_hakim_intel() (spec §5.8) ───────

	run_case("maybe_trigger_hakim_intel_is_false_when_not_unlocked", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		Rng.set_seed(1)
		var hit := false
		for i in range(50):
			if Collective.maybe_trigger_hakim_intel():
				hit = true
		assert_true(not hit, "hakimIntelUnlocked false must suppress every roll")
		assert_true(Messages.pending_for("hakim").is_empty())
	)

	run_case("maybe_trigger_hakim_intel_is_false_before_the_3_day_minimum_gap", func():
		GameState.reset()
		GameState.state["flags"]["hakimIntelUnlocked"] = true
		GameState.state["collective"]["hakimIntelLastDay"] = 5
		GameState.state["world"]["day"] = 7  # only 2 days since the last text
		var hit := false
		for seed in range(200):
			Rng.set_seed(seed)
			if Collective.maybe_trigger_hakim_intel():
				hit = true
				break
		assert_true(not hit, "day 7 is only 2 days after hakimIntelLastDay 5 -- the 3-day minimum must suppress every roll")
	)

	run_case("maybe_trigger_hakim_intel_is_eligible_exactly_3_days_after_the_last_text", func():
		var hit := false
		for seed in range(200):
			GameState.reset()
			GameState.state["flags"]["hakimIntelUnlocked"] = true
			GameState.state["collective"]["hakimIntelLastDay"] = 5
			GameState.state["world"]["day"] = 8  # exactly 3 days later
			Rng.set_seed(seed)
			if Collective.maybe_trigger_hakim_intel():
				hit = true
				break
		assert_true(hit, "day 8 is exactly 3 days after hakimIntelLastDay 5 -- should be eligible to roll within 200 tries")
	)

	run_case("maybe_trigger_hakim_intel_is_false_when_both_shoreditch_and_whitechapel_are_at_siteCap", func():
		GameState.reset()
		GameState.state["flags"]["hakimIntelUnlocked"] = true
		GameState.state["world"]["day"] = 20
		var shoreditch_cap: int = GameData.DISTRICTS["shoreditch"]["siteCap"]
		var whitechapel_cap: int = GameData.DISTRICTS["whitechapel"]["siteCap"]
		GameState.state["world"]["sites"] = _sites("shoreditch", shoreditch_cap) + _sites("whitechapel", whitechapel_cap)
		var hit := false
		for seed in range(200):
			Rng.set_seed(seed)
			if Collective.maybe_trigger_hakim_intel():
				hit = true
				break
		assert_true(not hit, "both districts at siteCap must suppress every roll, even a lucky 15% one")
	)

	run_case("maybe_trigger_hakim_intel_only_places_the_site_in_the_district_still_under_siteCap", func():
		var shoreditch_cap: int = GameData.DISTRICTS["shoreditch"]["siteCap"]
		var hit := false
		for seed in range(200):
			GameState.reset()
			GameState.state["flags"]["hakimIntelUnlocked"] = true
			GameState.state["world"]["day"] = 20
			GameState.state["world"]["sites"] = _sites("shoreditch", shoreditch_cap)  # shoreditch full, whitechapel open
			Rng.set_seed(seed)
			if Collective.maybe_trigger_hakim_intel():
				hit = true
				break
		assert_true(hit, "should still be able to roll within 200 tries with whitechapel open")
		var new_site: Variant = null
		for site in GameState.state["world"]["sites"]:
			if not site["id"].begins_with("cap"):
				new_site = site
		assert_true(new_site != null, "a new site should have been created")
		assert_eq(new_site["district"], "whitechapel", "shoreditch is at siteCap -- the new site must land in whitechapel")
	)

	run_case("maybe_trigger_hakim_intel_creates_a_site_fair_or_better_in_shoreditch_or_whitechapel", func():
		var seen_tiers: Dictionary = {}
		var seen_districts: Dictionary = {}
		for seed in range(400):
			GameState.reset()
			GameState.state["flags"]["hakimIntelUnlocked"] = true
			GameState.state["world"]["day"] = 20
			Rng.set_seed(seed)
			if Collective.maybe_trigger_hakim_intel():
				var pending := Messages.pending_for("hakim")
				assert_eq(pending.size(), 1)
				assert_eq(pending[0]["kind"], "col_hakim_intel")
				var site_id: String = pending[0]["payload"]["site_id"]
				var site: Variant = Sites.find_site(site_id)
				assert_true(site != null, "the payload's site_id must resolve to a real site")
				assert_true(not site["claimed"], "the gifted site must be unclaimed")
				assert_true(["fair", "rich", "saturated"].has(site["tier"]), "tier %s must be fair or better" % site["tier"])
				assert_true(["shoreditch", "whitechapel"].has(site["district"]), "district must be shoreditch or whitechapel")
				seen_tiers[site["tier"]] = true
				seen_districts[site["district"]] = true
		assert_true(seen_tiers.size() > 1, "400 seeds should turn up more than one eligible tier")
		assert_true(seen_districts.size() > 1, "400 seeds should turn up both eligible districts")
	)

	run_case("maybe_trigger_hakim_intel_does_not_double_queue_while_a_text_is_already_pending", func():
		GameState.reset()
		GameState.state["flags"]["hakimIntelUnlocked"] = true
		GameState.state["world"]["day"] = 20
		var fired := false
		for seed in range(200):
			Rng.set_seed(seed)
			if Collective.maybe_trigger_hakim_intel():
				fired = true
				break
		assert_true(fired, "sanity: should be able to fire once within 200 tries")
		assert_eq(Messages.pending_for("hakim").size(), 1)

		var hit_again := false
		for seed in range(200):
			Rng.set_seed(seed)
			if Collective.maybe_trigger_hakim_intel():
				hit_again = true
		assert_true(not hit_again, "an unread pending col_hakim_intel text must suppress further rolls")
		assert_eq(Messages.pending_for("hakim").size(), 1, "no second entry should ever be queued")
	)

	# ── on_complete: reveal_site + set_hakim_intel_day (spec §6.16) ────────

	run_case("col_hakim_intel_on_complete_queues_the_discover_map_event_for_the_gifted_site", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [{
			"id": "s1", "district": "whitechapel", "tier": "fair", "oreType": "life",
			"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null,
			"hasNaturalVein": false,
		}]

		_play_event("col_hakim_intel", { "site_id": "s1" })

		var event: Variant = MapEvents.current()
		assert_true(event != null, "on_complete should queue a discover map event")
		assert_eq(event["type"], "discover")
		assert_eq(event["district"], "whitechapel")
		assert_eq(event["siteId"], "s1")
	)

	run_case("col_hakim_intel_on_complete_updates_hakimIntelLastDay_to_today", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [{
			"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "life",
			"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null,
			"hasNaturalVein": false,
		}]
		GameState.state["world"]["day"] = 42
		GameState.state["collective"]["hakimIntelLastDay"] = 0

		_play_event("col_hakim_intel", { "site_id": "s1" })

		assert_eq(GameState.state["collective"]["hakimIntelLastDay"], 42)
	)

	run_case("col_hakim_intel_on_complete_navigates_back_to_phone", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [{
			"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "life",
			"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null,
			"hasNaturalVein": false,
		}]

		_play_event("col_hakim_intel", { "site_id": "s1" })

		assert_eq(GameState.state["currentScreen"], "phone")
	)

	# ── real delivery path: pendingMessages payload flows through Events.start_event ──

	run_case("the_pending_messages_payload_reaches_on_complete_the_same_way_phone_gd_drives_it", func():
		GameState.reset()
		GameState.state["flags"]["hakimIntelUnlocked"] = true
		GameState.state["world"]["day"] = 20
		var fired := false
		for seed in range(200):
			Rng.set_seed(seed)
			if Collective.maybe_trigger_hakim_intel():
				fired = true
				break
		assert_true(fired)

		var entry: Dictionary = Messages.pending_for("hakim")[0]
		Messages.resolve_pending(entry["id"])
		_play_event(entry["kind"], entry["payload"])

		var site: Variant = Sites.find_site(entry["payload"]["site_id"])
		assert_true(site != null)
		assert_eq(MapEvents.current()["siteId"], site["id"], "on_complete's reveal_site should resolve the real site via context, with no literal site_id in the JSON")
		assert_true(Messages.pending_for("hakim").is_empty(), "resolve_pending (the same tap-flow step phone.gd/contact_cards.gd use) already cleared the entry before the event started")
	)
