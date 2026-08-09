extends "res://tests/test_base.gd"

# MapEvents — the map event queue + playback sequencing (map-animations
# ticket 01). Node-side animation (camera pan, ring pulse, tick pop-in)
# lives in scenes/components/map_canvas.gd and isn't exercised here; this
# covers the pure-data queue/playback state machine it drives itself with.


func _unclaimed_site(id: String, district: String, ore_type: String = "time") -> Dictionary:
	return { "id": id, "district": district, "tier": "fair", "oreType": ore_type, "bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null, "hasNaturalVein": false }


func _claimed_site(id: String, district: String, ore_type: String = "time") -> Dictionary:
	var s := _unclaimed_site(id, district, ore_type)
	s["claimed"] = true
	return s


func _faction_claimed_site(id: String, district: String, faction_id: String, ore_type: String = "physics") -> Dictionary:
	var s := _unclaimed_site(id, district, ore_type)
	s["factionVein"] = { "id": "fv_" + id, "factionId": faction_id, "oreType": ore_type, "level": 1, "devBar": 0, "security": "none", "claimedOnDay": 1 }
	return s


func run() -> void:
	run_case("queue_discover_appends_a_discover_event_with_district_and_site_id", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		var event = MapEvents.current()
		assert_eq(event["type"], "discover")
		assert_eq(event["district"], "shoreditch")
		assert_eq(event["siteId"], "s1")
	)

	run_case("has_pending_false_on_a_fresh_game", func():
		GameState.reset()
		assert_true(not MapEvents.has_pending())
	)

	run_case("has_pending_true_once_something_is_queued", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		assert_true(MapEvents.has_pending())
	)

	run_case("pending_site_ids_lists_every_queued_site_in_order", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.queue_discover("camden", "s2")
		assert_eq(MapEvents.pending_site_ids(), ["s1", "s2"])
	)

	# ── seed_claim (ticket 02) ──────────────────────────────────────────

	run_case("queue_seed_claim_appends_a_seed_claim_event_with_district_vein_id_and_owner", func():
		GameState.reset()
		MapEvents.queue_seed_claim("shoreditch", "v1", "player")
		var event = MapEvents.current()
		assert_eq(event["type"], "seed_claim")
		assert_eq(event["district"], "shoreditch")
		assert_eq(event["veinId"], "v1")
		assert_eq(event["owner"], "player")
	)

	run_case("queue_seed_claim_owner_can_be_a_faction_id", func():
		GameState.reset()
		MapEvents.queue_seed_claim("camden", "v2", "firm")
		assert_eq(MapEvents.current()["owner"], "firm")
	)

	run_case("pending_vein_ids_lists_every_queued_vein_in_order", func():
		GameState.reset()
		MapEvents.queue_seed_claim("shoreditch", "v1", "player")
		MapEvents.queue_seed_claim("camden", "v2", "firm")
		assert_eq(MapEvents.pending_vein_ids(), ["v1", "v2"])
	)

	run_case("pending_site_ids_and_pending_vein_ids_only_pick_up_their_own_event_type", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.queue_seed_claim("camden", "v1", "player")
		assert_eq(MapEvents.pending_site_ids(), ["s1"], "seed_claim events have no siteId to collect")
		assert_eq(MapEvents.pending_vein_ids(), ["v1"], "discover events have no veinId to collect")
	)

	# ── charge (ticket 03) ──────────────────────────────────────────────

	run_case("queue_charge_appends_a_charge_event_with_district_and_vein_id", func():
		GameState.reset()
		MapEvents.queue_charge("shoreditch", "v1")
		var event = MapEvents.current()
		assert_eq(event["type"], "charge")
		assert_eq(event["district"], "shoreditch")
		assert_eq(event["veinId"], "v1")
	)

	run_case("pending_vein_ids_does_not_pick_up_charge_events", func():
		GameState.reset()
		MapEvents.queue_seed_claim("shoreditch", "v1", "player")
		MapEvents.queue_charge("shoreditch", "v2")
		# A "charge" event never hides its vein from the ordinary static
		# draw (see MapEvents.queue_charge's own comment) -- only
		# "seed_claim" vein ids belong in this list.
		assert_eq(MapEvents.pending_vein_ids(), ["v1"], "charge events have no reason to be in pending_vein_ids")
	)

	# ── drain (ticket 04) ────────────────────────────────────────────────

	run_case("queue_drain_appends_a_drain_event_with_district_and_vein_id", func():
		GameState.reset()
		MapEvents.queue_drain("shoreditch", "v1")
		var event = MapEvents.current()
		assert_eq(event["type"], "drain")
		assert_eq(event["district"], "shoreditch")
		assert_eq(event["veinId"], "v1")
	)

	run_case("pending_vein_ids_does_not_pick_up_drain_events", func():
		GameState.reset()
		MapEvents.queue_seed_claim("shoreditch", "v1", "player")
		MapEvents.queue_drain("shoreditch", "v2")
		# Same reasoning as "charge" above -- a "drain" event never hides its
		# vein from the ordinary static draw, only "seed_claim" vein ids
		# belong in this list.
		assert_eq(MapEvents.pending_vein_ids(), ["v1"], "drain events have no reason to be in pending_vein_ids")
	)

	# ── join_line (ticket 05) ────────────────────────────────────────────

	run_case("queue_join_line_appends_a_join_line_event_with_district_vein_id_and_owner", func():
		GameState.reset()
		var site := _claimed_site("s1", "shoreditch")
		GameState.state["world"]["sites"] = [site]
		GameState.state["player"]["veins"] = [{ "id": "v1", "siteId": "s1" }]

		MapEvents.queue_join_line("shoreditch", "v1", "player")
		var event = MapEvents.current()
		assert_eq(event["type"], "join_line")
		assert_eq(event["district"], "shoreditch")
		assert_eq(event["veinId"], "v1")
		assert_eq(event["owner"], "player")
	)

	run_case("queue_join_line_owner_can_be_a_faction_id", func():
		GameState.reset()
		var site := _faction_claimed_site("s1", "camden", "firm")
		GameState.state["world"]["sites"] = [site]

		MapEvents.queue_join_line("camden", site["factionVein"]["id"], "firm")
		assert_eq(MapEvents.current()["owner"], "firm")
	)

	run_case("pending_join_line_vein_ids_lists_every_queued_join_line_vein_in_order", func():
		GameState.reset()
		MapEvents.queue_join_line("shoreditch", "v1", "player")
		MapEvents.queue_join_line("camden", "v2", "firm")
		assert_eq(MapEvents.pending_join_line_vein_ids(), ["v1", "v2"])
	)

	run_case("pending_join_line_vein_ids_does_not_pick_up_seed_claim_charge_or_drain_events", func():
		GameState.reset()
		MapEvents.queue_seed_claim("shoreditch", "v1", "player")
		MapEvents.queue_charge("shoreditch", "v2")
		MapEvents.queue_drain("shoreditch", "v3")
		assert_eq(MapEvents.pending_join_line_vein_ids(), [])
	)

	run_case("pending_vein_ids_does_not_pick_up_join_line_events", func():
		GameState.reset()
		MapEvents.queue_seed_claim("shoreditch", "v1", "player")
		MapEvents.queue_join_line("shoreditch", "v2", "player")
		# join_line hides the vein from the routed LINE only (pending_join_
		# line_vein_ids), not from the ring (pending_vein_ids) -- only
		# seed_claim vein ids belong in this list.
		assert_eq(MapEvents.pending_vein_ids(), ["v1"])
	)

	# ── begin_playback: drains exactly once per Map-tab visit ─────────────

	run_case("begin_playback_returns_false_when_the_queue_is_empty", func():
		GameState.reset()
		assert_true(not MapEvents.begin_playback())
		assert_true(not MapEvents.is_playing())
	)

	run_case("begin_playback_starts_a_drain_and_marks_playing", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		assert_true(MapEvents.begin_playback())
		assert_true(MapEvents.is_playing())
	)

	run_case("begin_playback_is_a_no_op_while_already_playing", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.queue_discover("camden", "s2")
		assert_true(MapEvents.begin_playback())
		# A second "visit" arriving mid-drain (e.g. the Map tab re-navigated
		# to while events are still playing) must not restart the queue.
		assert_true(not MapEvents.begin_playback())
		assert_eq(MapEvents.current()["siteId"], "s1", "still on the first event, not restarted")
	)

	# ── advance: sequential ordering + skip-advances-to-next ──────────────

	run_case("advance_pops_the_current_event_and_moves_to_the_next_in_order", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.queue_discover("camden", "s2")
		MapEvents.begin_playback()
		assert_eq(MapEvents.current()["siteId"], "s1")
		MapEvents.advance()
		assert_eq(MapEvents.current()["siteId"], "s2", "events play strictly sequentially, never simultaneously")
	)

	run_case("advance_returns_true_while_more_events_remain", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.queue_discover("camden", "s2")
		MapEvents.begin_playback()
		assert_true(MapEvents.advance())
	)

	run_case("advance_returns_false_and_clears_playing_once_the_queue_empties", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.begin_playback()
		assert_true(not MapEvents.advance())
		assert_true(not MapEvents.is_playing())
		assert_true(not MapEvents.has_pending())
	)

	# advance() is exactly what a tap-skip calls (see MapCanvas._skip_current)
	# to snap the current event to its end state and move on immediately —
	# this is that behaviour's pure-state contract.
	run_case("skip_advances_to_next_behaves_like_advance", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.queue_discover("camden", "s2")
		MapEvents.queue_discover("soho", "s3")
		MapEvents.begin_playback()
		MapEvents.advance()  # simulated skip of s1
		assert_eq(MapEvents.current()["siteId"], "s2", "skip lands on the very next queued event")
		assert_true(MapEvents.is_playing(), "still draining — one more event queued behind it")
	)

	run_case("a_fresh_visit_after_the_queue_drains_is_a_no_op", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.begin_playback()
		MapEvents.advance()
		assert_true(not MapEvents.begin_playback(), "nothing queued — an empty-queue visit changes nothing")
	)

	# ── abandon_playback: recovering from MapCanvas being torn down mid-drain ──

	run_case("abandon_playback_clears_playing_without_touching_the_queue", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.queue_discover("camden", "s2")
		MapEvents.begin_playback()
		MapEvents.abandon_playback()
		assert_true(not MapEvents.is_playing())
		assert_eq(MapEvents.pending_site_ids(), ["s1", "s2"], "the queue itself is untouched — nothing was skipped or lost")
	)

	run_case("a_visit_after_an_abandoned_drain_resumes_the_same_unplayed_event", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		# e.g. a district-deck event fired mid-prospect and navigated away
		# from "map" while MapCanvas was still panning/animating s1 — see
		# MapCanvas._exit_tree().
		MapEvents.begin_playback()
		MapEvents.abandon_playback()
		assert_true(MapEvents.begin_playback(), "a later visit can start a fresh drain — not stuck forever")
		assert_eq(MapEvents.current()["siteId"], "s1", "resumes/replays the same event that got cut off, not skipped")
	)

	run_case("abandon_playback_is_a_no_op_when_nothing_was_playing", func():
		GameState.reset()
		MapEvents.abandon_playback()
		assert_true(not MapEvents.is_playing())
	)
