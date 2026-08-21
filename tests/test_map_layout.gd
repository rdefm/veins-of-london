extends "res://tests/test_base.gd"

# MapLayout — resolves map_layout.json's stopSlots against live state into
# concrete stop positions (M1.5 N3). Discovery-order occupancy: sites in
# state.world.sites' array order, veins-per-claimed-site in
# state.player.veins' array order (the extra vein from a saturated site's
# natural-vein bonus, D2).


func _unclaimed(id: String, district: String) -> Dictionary:
	return { "id": id, "district": district, "tier": "poor", "oreType": "physics", "bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null, "hasNaturalVein": false }


func _faction_claimed(id: String, district: String, faction_id: String = "collective") -> Dictionary:
	var s := _unclaimed(id, district)
	s["factionVein"] = { "id": "fv_" + id, "factionId": faction_id, "oreType": "physics", "growth": 20, "rampantDays": 0, "security": "none", "claimedOnDay": 1 }
	return s


func _claimed(id: String, district: String) -> Dictionary:
	var s := _unclaimed(id, district)
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
		var site := _claimed("s1", "camden")
		var seeded_vein := { "id": "v_seeded", "siteId": "s1" }
		var natural_vein := { "id": "v_natural", "siteId": "s1" }
		var items := MapLayout.build_stop_items([site], [seeded_vein, natural_vein])
		assert_eq(items.size(), 2, "one claimed site with 2 veins -> 2 stops, not 1")
		assert_eq(items[0]["vein"]["id"], "v_seeded")
		assert_eq(items[1]["vein"]["id"], "v_natural")
	)

	run_case("build_stop_items_ignores_veins_belonging_to_other_sites", func():
		var site := _claimed("s1", "camden")
		var other_vein := { "id": "v_other", "siteId": "s2" }
		var items := MapLayout.build_stop_items([site], [other_vein])
		assert_eq(items.size(), 0, "a claimed site with no matching vein contributes no stop")
	)

	run_case("build_stop_items_preserves_discovery_order_across_mixed_claim_states", func():
		var sites := [
			_unclaimed("s1", "camden"),
			_faction_claimed("s2", "camden"),
			_claimed("s3", "camden"),
		]
		var veins := [{ "id": "v3", "siteId": "s3" }]
		var items := MapLayout.build_stop_items(sites, veins)
		var ids: Array = []
		for item in items:
			ids.append(item["site"]["id"])
		assert_eq(ids, ["s1", "s2", "s3"], "stop items follow the sites array's (discovery) order")
	)

	run_case("assign_positions_maps_items_onto_slots_in_order", func():
		var items := [
			{ "kind": "unclaimed", "site": { "id": "a" }, "vein": null },
			{ "kind": "npc", "site": { "id": "b" }, "vein": null },
		]
		var slots := [[10, 20], [30, 40], [50, 60]]
		var assigned := MapLayout.assign_positions(items, slots)
		assert_eq(assigned.size(), 2)
		assert_eq(assigned[0]["position"], Vector2(10, 20))
		assert_eq(assigned[1]["position"], Vector2(30, 40))
	)

	run_case("assign_positions_clamps_overflow_onto_the_last_slot", func():
		# Defensive only — map_layout.json's siteCap+2 buffer (GameData-validated)
		# means real data should never actually hit this path.
		var items := [
			{ "kind": "unclaimed", "site": { "id": "a" }, "vein": null },
			{ "kind": "unclaimed", "site": { "id": "b" }, "vein": null },
			{ "kind": "unclaimed", "site": { "id": "c" }, "vein": null },
		]
		var slots := [[10, 20]]
		var assigned := MapLayout.assign_positions(items, slots)
		assert_eq(assigned.size(), 3)
		for a in assigned:
			assert_eq(a["position"], Vector2(10, 20), "every item beyond slot capacity clamps onto the last slot")
	)

	run_case("assign_positions_empty_slots_yields_no_stops", func():
		var items := [{ "id": "a", "kind": "unclaimed", "site": {}, "vein": null }]
		assert_eq(MapLayout.assign_positions(items, []), [])
	)

	run_case("assign_positions_id_is_vein_id_for_vein_stops_and_site_id_otherwise", func():
		var items := [
			{ "id": "ignored", "kind": "vein", "site": { "id": "site1" }, "vein": { "id": "vein1" } },
			{ "id": "ignored", "kind": "unclaimed", "site": { "id": "site2" }, "vein": null },
		]
		var assigned := MapLayout.assign_positions(items, [[0, 0], [1, 1]])
		assert_eq(assigned[0]["id"], "vein1")
		assert_eq(assigned[1]["id"], "site2")
	)

	run_case("assign_slots_reads_real_layout_and_state_in_discovery_order", func():
		GameState.reset()
		var unclaimed := _unclaimed("s1", "camden")
		var claimed_site := _claimed("s2", "camden")
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
