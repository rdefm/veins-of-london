extends "res://tests/test_base.gd"

# MapLayout — resolves map_layout.json's stopSlots against live state into
# concrete stop positions (M1.5 N3). Discovery-order occupancy: sites in
# state.world.sites' array order, veins-per-claimed-site in
# state.player.veins' array order (the extra vein from a saturated site's
# natural-vein bonus, D2).


func _unclaimed(id: String, district: String, slot_index: int = 0) -> Dictionary:
	return { "id": id, "district": district, "tier": "poor", "oreType": "physics", "bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null, "hasNaturalVein": false, "slotIndex": slot_index }


func _faction_claimed(id: String, district: String, faction_id: String = "collective", slot_index: int = 0) -> Dictionary:
	var s := _unclaimed(id, district, slot_index)
	s["factionVein"] = { "id": "fv_" + id, "factionId": faction_id, "oreType": "physics", "growth": 20, "rampantDays": 0, "security": "none", "claimedOnDay": 1 }
	return s


func _claimed(id: String, district: String, slot_index: int = 0) -> Dictionary:
	var s := _unclaimed(id, district, slot_index)
	s["claimed"] = true
	return s


func run() -> void:
	run_case("build_stop_items_unclaimed_site_is_one_unclaimed_stop", func():
		var items := MapLayout.build_stop_items([_unclaimed("s1", "camden")], [])
		assert_eq(items.size(), 1)
		assert_eq(items[0]["kind"], "unclaimed")
		assert_eq(items[0]["vein"], null)
	)

	run_case("build_stop_items_faction_claimed_site_is_one_vein_stop_owned_by_the_faction", func():
		var items := MapLayout.build_stop_items([_faction_claimed("s1", "camden", "firm")], [])
		assert_eq(items.size(), 1)
		assert_eq(items[0]["kind"], "vein")
		assert_eq(items[0]["owner"], "firm")
		assert_eq(items[0]["vein"]["factionId"], "firm")
	)

	run_case("build_stop_items_claimed_site_with_one_vein_is_one_vein_stop", func():
		var site := _claimed("s1", "camden")
		var vein := { "id": "v1", "siteId": "s1" }
		var items := MapLayout.build_stop_items([site], [vein])
		assert_eq(items.size(), 1)
		assert_eq(items[0]["kind"], "vein")
		assert_eq(items[0]["owner"], "player")
		assert_eq(items[0]["vein"]["id"], "v1")
	)

	run_case("build_stop_items_claimed_site_with_two_veins_is_two_vein_stops", func():
		# Saturated site's natural-vein bonus (D2): a claimed site can carry a
		# second vein. Both occupy their own stop, in player.veins array order.
		var site := _claimed("s1", "camden", 3)
		var seeded_vein := { "id": "v_seeded", "siteId": "s1" }
		# 52-map-vein-line-position-drift: only the *extra* (natural) vein
		# carries its own stamped slotIndex — the seeded vein has none and
		# falls back to the site's own slot, same as a single-vein claim.
		var natural_vein := { "id": "v_natural", "siteId": "s1", "slotIndex": 7 }
		var items := MapLayout.build_stop_items([site], [seeded_vein, natural_vein])
		assert_eq(items.size(), 2, "one claimed site with 2 veins -> 2 stops, not 1")
		assert_eq(items[0]["vein"]["id"], "v_seeded")
		assert_eq(items[0]["slotIndex"], 3, "the seeded vein reuses the site's own stamped slot")
		assert_eq(items[1]["vein"]["id"], "v_natural")
		assert_eq(items[1]["slotIndex"], 7, "the natural-vein bonus keeps its own separately-stamped slot")
	)

	run_case("build_stop_items_shows_a_surviving_sibling_vein_after_the_sites_other_vein_is_sold_to_a_faction", func():
		# 94-map-vein-slot-overflow-recurrence: a saturated site's natural-vein
		# bonus lives at the same siteId but its own stamped slotIndex,
		# independent of the site's *other* vein. Selling/raiding that other
		# vein away (VeinTrade.sell_to_faction, Raiding.resolve_raid_outcome's
		# claim branch) flips the site to factionVein-owned without touching
		# the bonus vein still sitting in player.veins -- before the fix, the
		# factionVein branch only ever emitted the faction's own stop, so the
		# still-live bonus vein silently vanished from the map (though a
		# district vein list, which just filters player.veins by siteId,
		# still counted it).
		var site := _faction_claimed("s1", "camden", "collective", 3)
		var surviving_natural_vein := { "id": "v_natural", "siteId": "s1", "slotIndex": 7 }
		var items := MapLayout.build_stop_items([site], [surviving_natural_vein])
		assert_eq(items.size(), 2, "the faction stop and the surviving sibling vein must both render")
		assert_eq(items[0]["owner"], "collective")
		assert_eq(items[0]["slotIndex"], 3)
		assert_eq(items[1]["vein"]["id"], "v_natural")
		assert_eq(items[1]["owner"], "player")
		assert_eq(items[1]["slotIndex"], 7, "the surviving sibling keeps its own separately-stamped slot")
	)

	run_case("build_stop_items_shows_a_surviving_sibling_vein_after_the_sites_other_vein_collapses_to_unclaimed", func():
		# Mirror of the faction case above: the site's *other* vein collapsing
		# (Cultivating.collapse_vein's player branch) resets claimed to false
		# without touching the sibling bonus vein either.
		var site := _unclaimed("s1", "camden", 3)
		var surviving_natural_vein := { "id": "v_natural", "siteId": "s1", "slotIndex": 7 }
		var items := MapLayout.build_stop_items([site], [surviving_natural_vein])
		assert_eq(items.size(), 2, "the unclaimed stop and the surviving sibling vein must both render")
		assert_eq(items[0]["kind"], "unclaimed")
		assert_eq(items[0]["slotIndex"], 3)
		assert_eq(items[1]["vein"]["id"], "v_natural")
		assert_eq(items[1]["owner"], "player")
		assert_eq(items[1]["slotIndex"], 7, "the surviving sibling keeps its own separately-stamped slot")
	)

	run_case("build_stop_items_ignores_veins_belonging_to_other_sites", func():
		var site := _claimed("s1", "camden")
		var other_vein := { "id": "v_other", "siteId": "s2" }
		var items := MapLayout.build_stop_items([site], [other_vein])
		assert_eq(items.size(), 0, "a claimed site with no matching vein contributes no stop")
	)

	run_case("build_stop_items_preserves_discovery_order_across_mixed_claim_states", func():
		var sites := [
			_unclaimed("s1", "camden", 0),
			_faction_claimed("s2", "camden", "collective", 1),
			_claimed("s3", "camden", 2),
		]
		var veins := [{ "id": "v3", "siteId": "s3" }]
		var items := MapLayout.build_stop_items(sites, veins)
		var ids: Array = []
		for item in items:
			ids.append(item["site"]["id"])
		assert_eq(ids, ["s1", "s2", "s3"], "stop items follow the sites array's (discovery) order")
	)

	run_case("assign_positions_maps_items_onto_slots_by_their_own_stamped_slotIndex", func():
		var items := [
			{ "kind": "unclaimed", "site": { "id": "a" }, "vein": null, "slotIndex": 0 },
			{ "kind": "npc", "site": { "id": "b" }, "vein": null, "slotIndex": 1 },
		]
		var slots := [[10, 20], [30, 40], [50, 60]]
		var assigned := MapLayout.assign_positions(items, slots)
		assert_eq(assigned.size(), 2)
		assert_eq(assigned[0]["position"], Vector2(10, 20))
		assert_eq(assigned[1]["position"], Vector2(30, 40))
	)

	run_case("assign_positions_keys_off_slotIndex_not_array_position", func():
		# 52-map-vein-line-position-drift: an item earlier in the input array
		# can carry a *higher* slotIndex than one after it (e.g. once an
		# earlier-discovered site has been removed and a later one hasn't) --
		# the returned position must follow the stamped slotIndex, not the
		# item's position in `items`.
		var items := [
			{ "kind": "unclaimed", "site": { "id": "a" }, "vein": null, "slotIndex": 2 },
			{ "kind": "unclaimed", "site": { "id": "b" }, "vein": null, "slotIndex": 0 },
		]
		var slots := [[10, 20], [30, 40], [50, 60]]
		var assigned := MapLayout.assign_positions(items, slots)
		assert_eq(assigned[0]["position"], Vector2(50, 60), "slotIndex 2 lands on the 3rd slot regardless of array position")
		assert_eq(assigned[1]["position"], Vector2(10, 20), "slotIndex 0 lands on the 1st slot regardless of array position")
	)

	run_case("assign_positions_clamps_overflow_onto_the_last_slot", func():
		# Defensive only — 87-map-slot-index-recycling means a removed stop's
		# slotIndex is recycled rather than lost, so real data should never
		# actually hit this path; it's the last-resort fallback if that
		# guarantee is ever violated, not a path normal churn can reach.
		var items := [
			{ "kind": "unclaimed", "site": { "id": "a" }, "vein": null, "slotIndex": 0 },
			{ "kind": "unclaimed", "site": { "id": "b" }, "vein": null, "slotIndex": 5 },
			{ "kind": "unclaimed", "site": { "id": "c" }, "vein": null, "slotIndex": 9 },
		]
		var slots := [[10, 20]]
		var assigned := MapLayout.assign_positions(items, slots)
		assert_eq(assigned.size(), 3)
		for a in assigned:
			assert_eq(a["position"], Vector2(10, 20), "every item beyond slot capacity clamps onto the last slot")
	)

	run_case("assign_positions_empty_slots_yields_no_stops", func():
		var items := [{ "id": "a", "kind": "unclaimed", "site": {}, "vein": null, "slotIndex": 0 }]
		assert_eq(MapLayout.assign_positions(items, []), [])
	)

	run_case("assign_positions_id_is_vein_id_for_vein_stops_and_site_id_otherwise", func():
		var items := [
			{ "id": "ignored", "kind": "vein", "site": { "id": "site1" }, "vein": { "id": "vein1" }, "slotIndex": 0 },
			{ "id": "ignored", "kind": "unclaimed", "site": { "id": "site2" }, "vein": null, "slotIndex": 1 },
		]
		var assigned := MapLayout.assign_positions(items, [[0, 0], [1, 1]])
		assert_eq(assigned[0]["id"], "vein1")
		assert_eq(assigned[1]["id"], "site2")
	)

	run_case("assign_slots_reads_real_layout_and_state_in_discovery_order", func():
		GameState.reset()
		var unclaimed := _unclaimed("s1", "camden", 0)
		var claimed_site := _claimed("s2", "camden", 1)
		GameState.state["world"]["sites"] = [unclaimed, claimed_site]
		GameState.state["player"]["veins"] = [{ "id": "v1", "siteId": "s2" }]

		var assigned := MapLayout.assign_slots("camden")
		var slots: Array = GameData.MAP_LAYOUT["districts"]["camden"]["stopSlots"]

		assert_eq(assigned.size(), 2)
		assert_eq(assigned[0]["id"], "s1")
		assert_eq(assigned[0]["kind"], "unclaimed")
		assert_eq(assigned[0]["position"], Vector2(slots[0][0], slots[0][1]))
		assert_eq(assigned[1]["id"], "v1", "claimed site's stop id is the vein's id, not the site's")
		assert_eq(assigned[1]["kind"], "vein")
		assert_eq(assigned[1]["position"], Vector2(slots[1][0], slots[1][1]))

		GameState.reset()
	)

	# ── 52-map-vein-line-position-drift regression coverage ────────────────
	# A stop's slot must stay fixed once assigned, across rebuilds/
	# re-renders, unless *that* stop's own underlying data genuinely
	# changes — an unrelated stop being discovered, claimed, or removed
	# elsewhere in the same district must never move it.

	run_case("assign_slots_rebuild_with_no_state_change_is_byte_identical", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_unclaimed("s1", "camden", 0), _claimed("s2", "camden", 1)]
		GameState.state["player"]["veins"] = [{ "id": "v1", "siteId": "s2" }]

		var first := MapLayout.assign_slots("camden")
		var second := MapLayout.assign_slots("camden")
		assert_eq(second, first, "re-running assign_slots against unchanged state must reproduce the exact same output")

		GameState.reset()
	)

	run_case("assign_slots_stop_position_is_stable_when_an_earlier_site_is_removed", func():
		# The routine, frequent trigger in real play: a prospect reroll or a
		# faction vein collapsing both delete a site from state.world.sites
		# outright (systems/sites.gd's _reroll_worst_unclaimed, systems/
		# cultivating.gd's collapse_vein). Before the fix, deleting s1 would
		# shift s3 from array position 2 down to 1, moving it onto s2's old
		# slot on the very next render.
		GameState.reset()
		var s1 := _unclaimed("s1", "camden", 0)
		var s2 := _unclaimed("s2", "camden", 1)
		var s3 := _unclaimed("s3", "camden", 2)
		GameState.state["world"]["sites"] = [s1, s2, s3]

		var before := MapLayout.assign_slots("camden")
		var s3_before: Vector2 = before[2]["position"]

		GameState.state["world"]["sites"] = [s2, s3]  # s1 removed, matching a real filter()-based delete
		var after := MapLayout.assign_slots("camden")
		var s3_after: Vector2
		for stop in after:
			if stop["id"] == "s3":
				s3_after = stop["position"]
		assert_eq(s3_after, s3_before, "s3's slot must not move just because an unrelated, earlier site was removed")

		GameState.reset()
	)

	run_case("assign_slots_stop_position_is_stable_when_a_saturated_sites_natural_vein_lands", func():
		# The other named candidate: Sites.attempt_seed() turns a claimed
		# site with hasNaturalVein into TWO stops instead of one the moment
		# it's claimed. Before the fix, that extra stop landing on an
		# earlier site would shift every later site's flattened index (and
		# therefore its slot) by one.
		GameState.reset()
		var s1 := _claimed("s1", "camden", 0)
		var s2 := _claimed("s2", "camden", 1)
		GameState.state["world"]["sites"] = [s1, s2]
		GameState.state["player"]["veins"] = [{ "id": "v1", "siteId": "s1" }, { "id": "v2", "siteId": "s2" }]

		var before := MapLayout.assign_slots("camden")
		var v2_before: Vector2
		for stop in before:
			if stop["id"] == "v2":
				v2_before = stop["position"]

		# s1 turns out to have a natural vein bonus; the new vein is
		# appended after v2 in player.veins array order (append order),
		# same as Sites.attempt_seed() would produce, and stamped with the
		# next slotIndex (Sites.next_slot_index()'s contract).
		GameState.state["player"]["veins"].append({ "id": "v1_natural", "siteId": "s1", "slotIndex": 2 })

		var after := MapLayout.assign_slots("camden")
		var v2_after: Vector2
		var natural_found := false
		for stop in after:
			if stop["id"] == "v2":
				v2_after = stop["position"]
			if stop["id"] == "v1_natural":
				natural_found = true
		assert_eq(v2_after, v2_before, "v2's slot must not move just because an unrelated, earlier site grew a second stop")
		assert_true(natural_found, "the natural-vein bonus stop should still appear")

		GameState.reset()
	)

	run_case("build_line_output_for_unaffected_veins_is_stable_when_an_earlier_site_is_removed", func():
		# Ticket 52's checklist explicitly names the routed *line*, not just
		# a stop's own position -- MapRouting.build_line() is a pure
		# function of the {id, pos} pairs MapLayout hands it, so once those
		# positions are stable (the tests above), the polyline it produces
		# for the same set of stops must be byte-identical too.
		GameState.reset()
		var s0 := _unclaimed("s0", "camden", 0)
		var s1 := _claimed("s1", "camden", 1)
		var s2 := _claimed("s2", "camden", 2)
		var s3 := _claimed("s3", "camden", 3)
		GameState.state["world"]["sites"] = [s0, s1, s2, s3]
		GameState.state["player"]["veins"] = [
			{ "id": "v1", "siteId": "s1" },
			{ "id": "v2", "siteId": "s2" },
			{ "id": "v3", "siteId": "s3" },
		]

		var home := MapLayout.home_anchor()
		var stops_before: Array = []
		for stop in MapLayout.assign_slots("camden"):
			if stop["kind"] == "vein":
				stops_before.append({ "id": stop["id"], "pos": stop["position"] })
		var line_before := MapRouting.build_line(home, stops_before)

		GameState.state["world"]["sites"] = [s1, s2, s3]  # s0 removed, matching a real filter()-based delete
		var stops_after: Array = []
		for stop in MapLayout.assign_slots("camden"):
			if stop["kind"] == "vein":
				stops_after.append({ "id": stop["id"], "pos": stop["position"] })
		var line_after := MapRouting.build_line(home, stops_after)

		assert_eq(stops_after, stops_before, "v1/v2/v3's ids and positions must be unaffected by s0's removal")
		assert_eq(line_after, line_before, "the routed line through unaffected veins must be byte-identical")

		GameState.reset()
	)

	run_case("district_anchor_and_home_anchor_return_vector2_from_data", func():
		var anchor := MapLayout.district_anchor("shoreditch")
		assert_true(anchor is Vector2, "district_anchor returns a Vector2")
		assert_eq(MapLayout.home_anchor(), anchor, "shoreditch is home base -- homeAnchor matches its district anchor")
	)

	run_case("river_path_converts_every_data_point_to_vector2", func():
		var path := MapLayout.river_path()
		assert_eq(path.size(), GameData.MAP_LAYOUT["riverPath"].size())
		assert_true(path[0] is Vector2)
	)

	run_case("faction_first_presence_anchor_picks_the_first_matching_district_in_key_order", func():
		assert_eq(MapLayout.faction_first_presence_anchor("collective"), MapLayout.district_anchor("shoreditch"), "shoreditch precedes whitechapel (both collective) in district key order")
		assert_eq(MapLayout.faction_first_presence_anchor("firm"), MapLayout.district_anchor("camden"), "camden precedes battersea (both firm) in district key order")
		assert_eq(MapLayout.faction_first_presence_anchor("guild"), MapLayout.district_anchor("greenwich"))
	)

	run_case("faction_first_presence_anchor_null_when_no_district_has_that_faction", func():
		assert_eq(MapLayout.faction_first_presence_anchor("not_a_real_faction"), null)
	)

	run_case("group_by_faction_groups_vein_stops_by_owner_in_input_order", func():
		var stops := [
			{ "id": "v1", "kind": "vein", "owner": "firm" },
			{ "id": "v2", "kind": "vein", "owner": "guild" },
			{ "id": "v3", "kind": "vein", "owner": "firm" },
		]
		var grouped := MapLayout.group_by_faction(stops)
		assert_eq(grouped.keys(), ["firm", "guild"], "one key per distinct faction owner, first-seen order")
		assert_eq(grouped["firm"].size(), 2, "both firm-owned stops land in the same group")
		assert_eq(grouped["firm"][0]["id"], "v1")
		assert_eq(grouped["firm"][1]["id"], "v3", "a faction's stops keep their input (discovery) order")
		assert_eq(grouped["guild"].size(), 1)
		assert_eq(grouped["guild"][0]["id"], "v2")
	)

	run_case("group_by_faction_excludes_player_owned_and_unclaimed_stops", func():
		var stops := [
			{ "id": "p1", "kind": "vein", "owner": "player" },
			{ "id": "u1", "kind": "unclaimed", "owner": null },
			{ "id": "v1", "kind": "vein", "owner": "firm" },
		]
		var grouped := MapLayout.group_by_faction(stops)
		assert_eq(grouped.keys(), ["firm"], "player-owned and unclaimed stops never form a faction group")
	)

	run_case("heavy_churn_of_diverging_sibling_veins_never_collides_slots_and_stays_in_sync_with_the_vein_list", func():
		# 94-map-vein-slot-overflow-recurrence: repeats the exact churn pattern
		# the fix above targets -- a claimed site with two live veins (the
		# saturated-site natural-vein bonus, D2) where only the *ordinary*
		# vein (no own slotIndex) gets sold off (VeinTrade.sell_to_faction),
		# leaving the natural-vein sibling still attached to a now-
		# factionVein-owned site -- enough rounds to run well past the
		# district's real (small) stopSlots buffer if either slot recycling
		# or the rendering fix regressed. Each round is fully retired before
		# the next starts (same "stay bounded, churn through it" discipline
		# as Sites' own next_slot_index_recycles_freed_slots... test) so this
		# is testing recycling/rendering under volume, not siteCap.
		GameState.reset()
		var district := "hampstead"
		var buffer_size: int = GameData.MAP_LAYOUT["districts"][district]["stopSlots"].size()
		var rounds: int = buffer_size * 3

		for i in range(rounds):
			var site_id := "s%d" % i
			var site_slot: int = Sites.next_slot_index(district)
			var site := {
				"id": site_id, "district": district, "tier": "saturated", "oreType": "time",
				"bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null,
				"hasNaturalVein": true, "slotIndex": site_slot,
			}
			GameState.state["world"]["sites"].append(site)

			var ordinary_vein := Cultivating.make_vein("time", 50, district, site_id, {})
			var natural_vein := Cultivating.make_vein("time", 50, district, site_id, {})
			natural_vein["slotIndex"] = Sites.next_slot_index(district)
			GameState.state["player"]["veins"].append(ordinary_vein)
			GameState.state["player"]["veins"].append(natural_vein)

			# Sell the ordinary vein only -- the site flips to factionVein-
			# owned while the natural-vein sibling stays a live player vein
			# on the same site.
			VeinTrade.sell_to_faction(ordinary_vein["id"], "collective")

			var assigned := MapLayout.assign_slots(district)
			var seen_positions := {}
			for stop in assigned:
				assert_true(not seen_positions.has(stop["position"]), "round %d: two live stops share a position" % i)
				seen_positions[stop["position"]] = true

			var natural_found := false
			for stop in assigned:
				if stop["id"] == natural_vein["id"]:
					natural_found = true
			assert_true(natural_found, "round %d: the surviving sibling vein must still render on the map" % i)

			# The actual "district's list view" (systems/vein_list.gd's own
			# veins()) vs. what the map renders for player-owned veins --
			# these must agree, not just "the one vein we're tracking shows
			# up somewhere."
			var rendered_player_vein_count := 0
			for stop in assigned:
				if stop["kind"] == "vein" and stop["owner"] == "player":
					rendered_player_vein_count += 1
			assert_eq(rendered_player_vein_count, VeinList.veins(district).size(), "round %d: district vein list count must match what the map renders" % i)

			# Retire the natural vein too (its own slot recycles), then the
			# site itself, so the next round starts from a clean slate --
			# Sites.release_slot_index() is the exact primitive every real
			# site-deletion path (collapse_vein's faction branch, prospect
			# reroll) calls.
			VeinTrade.sell_to_faction(natural_vein["id"], "collective")
			GameState.state["world"]["sites"] = GameState.state["world"]["sites"].filter(func(s): return s["id"] != site_id)
			Sites.release_slot_index(district, site_slot)

		var district_player_veins: Array = GameState.state["player"]["veins"].filter(func(v): return v["district"] == district)
		assert_eq(district_player_veins.size(), 0, "every round's veins were sold off -- none should remain")
		assert_true(GameState.state["world"]["sites"].filter(func(s): return s["district"] == district).is_empty(), "every round's site was retired -- none should remain")
		assert_eq(MapLayout.assign_slots(district), [], "nothing left to render once every round has been retired")

		GameState.reset()
	)
