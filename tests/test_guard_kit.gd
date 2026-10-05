extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const SeedSearch := preload("res://tests/support/seed_search.gd")
const SAVE_TEST_SLOT := 88


func run() -> void:
	run_case("stock_moves_units_of_one_tier_from_inventory_to_the_kit", func():
		var vein := _seed(1)
		Crafting.inventory_add("shield", 3, 2)
		Crafting.inventory_add("shield", 1, 1)
		var result := GuardKit.stock("v1", "shield", 3, 2)
		assert_true(result["ok"], result["reason"])
		assert_eq(vein["guardKit"], { "shield": { "3": 2 } })
		assert_eq(GameState.state["player"]["inventory"]["shield"].get("3", 0), 0, "tier-3 units left the inventory")
		assert_eq(GameState.state["player"]["inventory"]["shield"]["1"], 1, "other tiers untouched")
	)

	run_case("stock_refuses_items_off_the_allowlist", func():
		var vein := _seed(2)
		for recipe_key in ["healingSalve", "wormhole", "panic"]:
			Crafting.inventory_add(recipe_key, 1, 1)
			var before: Dictionary = GameState.deep_copy(GameState.state)
			assert_true(not GuardKit.stock("v1", recipe_key, 1, 1)["ok"], recipe_key + " refused")
			assert_eq(GameState.state, before, recipe_key + " left no change")
		assert_eq(vein["guardKit"], {})
	)

	run_case("stock_refuses_when_too_few_are_held_at_that_tier", func():
		_seed(2)
		Crafting.inventory_add("blast", 1, 1)
		Crafting.inventory_add("blast", 2, 5)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock("v1", "blast", 1, 2)["ok"])
		assert_eq(GameState.state, before)
	)

	run_case("stock_refuses_a_vein_that_isnt_the_players", func():
		_seed(1)
		Fixtures.seed_faction_vein("fv1", 50)
		Crafting.inventory_add("blast", 1, 1)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock("fv1", "blast", 1, 1)["ok"])
		assert_true(not GuardKit.stock("nope", "blast", 1, 1)["ok"])
		assert_eq(GameState.state, before)
	)

	run_case("stock_refuses_a_vein_with_no_guards", func():
		_seed(0)
		Crafting.inventory_add("blast", 1, 1)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock("v1", "blast", 1, 1)["ok"])
		assert_eq(GameState.state, before)
	)

	run_case("stock_refuses_an_over_capacity_result", func():
		var vein := _seed(1)  # capacity 2
		Crafting.inventory_add("blast", 1, 3)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock("v1", "blast", 1, 3)["ok"], "3 units into 2 slots refused")
		assert_eq(GameState.state, before)
		assert_true(GuardKit.stock("v1", "blast", 1, 2)["ok"], "exactly filling capacity is allowed")
		assert_eq(GuardKit.unit_count(vein["guardKit"]), 2)
		assert_true(not GuardKit.stock("v1", "blast", 1, 1)["ok"], "refused at capacity")
	)

	run_case("unstock_returns_units_to_inventory_at_their_tier", func():
		var vein := _seed(1)
		vein["guardKit"] = { "shield": { "3": 2 } }
		var result := GuardKit.unstock("v1", "shield", 3, 1)
		assert_true(result["ok"], result["reason"])
		assert_eq(vein["guardKit"], { "shield": { "3": 1 } })
		assert_eq(GameState.state["player"]["inventory"]["shield"]["3"], 1)
		assert_true(GuardKit.unstock("v1", "shield", 3, 1)["ok"])
		assert_eq(vein["guardKit"], {}, "emptied buckets are dropped")
	)

	run_case("unstock_works_over_capacity_and_with_no_guards", func():
		var vein := _seed(0)
		vein["guardKit"] = { "blast": { "1": 4 } }
		assert_true(GuardKit.unstock("v1", "blast", 1, 3)["ok"])
		assert_eq(vein["guardKit"], { "blast": { "1": 1 } })
		assert_eq(GameState.state["player"]["inventory"]["blast"]["1"], 3)
	)

	run_case("unstock_refuses_more_than_the_kit_holds", func():
		var vein := _seed(1)
		vein["guardKit"] = { "blast": { "1": 1 } }
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.unstock("v1", "blast", 1, 2)["ok"])
		assert_true(not GuardKit.unstock("v1", "blast", 2, 1)["ok"], "wrong tier")
		assert_eq(GameState.state, before)
	)

	run_case("active_units_takes_allowlist_order_then_highest_tier_first", func():
		var vein := _seed(2)  # capacity 4
		vein["guardKit"] = {
			"rewind": { "1": 1 },
			"shield": { "1": 1, "3": 1 },
			"blast": { "0": 1, "2": 1 },
		}
		assert_eq(GuardKit.active_units(vein), { "blast": { "2": 1, "0": 1 }, "shield": { "3": 1, "1": 1 } })
		assert_eq(GuardKit.active_units_of(vein["guardKit"], 1, 3), { "blast": { "2": 1, "0": 1 }, "shield": { "3": 1 } }, "kit-dict helper honours its own slots-per-guard")
	)

	run_case("dropping_a_guard_keeps_the_kit_but_makes_the_excess_inactive", func():
		var vein := _seed(2)
		Crafting.inventory_add("blast", 1, 4)
		assert_true(GuardKit.stock("v1", "blast", 1, 4)["ok"])
		assert_true(Cultivating.drop_vein_guard(vein))
		assert_eq(vein["guardKit"], { "blast": { "1": 4 } }, "kit intact")
		assert_eq(GuardKit.active_units(vein), { "blast": { "1": 2 } })
		Crafting.inventory_add("shield", 1, 1)
		assert_true(not GuardKit.stock("v1", "shield", 1, 1)["ok"], "refused while over capacity")
		assert_true(Cultivating.drop_vein_guard(vein))
		assert_eq(GuardKit.active_units(vein), {}, "0 guards: whole kit inactive")
	)

	run_case("stock_and_unstock_emit_state_changed", func():
		_seed(1)
		Crafting.inventory_add("blast", 1, 1)
		var hits := [0]
		var on_changed := func(): hits[0] += 1
		EventBus.state_changed.connect(on_changed)
		GuardKit.stock("v1", "blast", 1, 1)
		GuardKit.unstock("v1", "blast", 1, 1)
		EventBus.state_changed.disconnect(on_changed)
		assert_eq(hits[0], 2)
	)

	run_case("new_player_veins_carry_an_empty_guard_kit", func():
		var vein := Cultivating.make_vein("time", GameData.VEIN_GROWTH["seedGrowth"], "shoreditch", null, { "tier": "fair", "bonuses": [] })
		assert_eq(vein["guardKit"], {})
	)

	run_case("old_save_backfills_an_empty_kit_on_every_player_vein", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["player"]["veins"] = [Fixtures.player_vein_with(), Fixtures.player_vein_with({ "id": "v2" })]
		var result: Dictionary = SaveManager.backfill_defaults(save)
		for vein in result["player"]["veins"]:
			assert_eq(vein["guardKit"], {})
	)

	run_case("guard_kit_round_trips_through_save_and_load", func():
		var vein := _seed(2)
		vein["guardKit"] = { "shield": { "3": 2 }, "blast": { "0": 1 } }
		assert_true(SaveManager.save_to_slot(SAVE_TEST_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(SAVE_TEST_SLOT)["ok"])
		SaveManager.delete_slot(SAVE_TEST_SLOT)
		var loaded: Dictionary = Cultivating.find_vein("v1")
		assert_eq(loaded["guardKit"], { "shield": { "3": 2 }, "blast": { "0": 1 } })
		assert_eq(typeof(loaded["guardKit"]["shield"]["3"]), TYPE_INT)
	)


	run_case("summary_lists_units_per_item_in_allowlist_order", func():
		assert_eq(GuardKit.summary_text({ "shield": { "3": 2 }, "blast": { "1": 1 } }), "Blast ×1 · Shield ×2")
		assert_eq(GuardKit.summary_text({ "shield": { "1": 1, "3": 2 } }), "Shield ×3", "tiers sum per item")
		assert_eq(GuardKit.summary_text({}), "")
	)

	run_case("a_vein_kit_target_reads_and_moves_that_veins_kit", func():
		var vein := _seed(2)
		Crafting.inventory_add("shield", 2, 3)
		var target := { "kind": "vein", "veinId": "v1" }
		assert_eq(GuardKit.target_capacity(target), 4)
		assert_eq(GuardKit.target_guard_count(target), 2)
		assert_true(GuardKit.stock_target(target, "shield", 2, 3)["ok"])  # 3 of 4
		assert_eq(GuardKit.target_kit(target), { "shield": { "2": 3 } })
		assert_true(GuardKit.unstock_target(target, "shield", 2, 1)["ok"])
		assert_eq(vein["guardKit"], { "shield": { "2": 2 } })
	)

	run_case("kit_veins_lists_guarded_or_stocked_veins_only", func():
		_seed(1)
		var stocked := Fixtures.seed_vein("v2", 50)
		stocked["guardKit"] = { "blast": { "1": 1 } }
		var bare := Fixtures.seed_vein("v3", 50)
		bare["guardKit"] = {}
		var ids := GuardKit.kit_veins().map(func(v): return v["id"])
		assert_eq(ids, ["v1", "v2"], "guarded v1 and stocked-but-unguarded v2; bare v3 hidden")
	)

	# ── §Loss ───────────────────────────────────────────────────────────

	run_case("a_raid_claim_hands_the_whole_kit_to_the_attacker", func():
		var vein := _seed_loss_kit()
		var before := _faction_items("firm")
		Raiding.resolve_raid_outcome({ "success": true, "veinId": "v1", "siteId": vein["siteId"], "attackerId": "firm", "outcomeType": "claim" })
		assert_eq(Cultivating.find_vein("v1"), null, "claimed")
		var after := _faction_items("firm")
		assert_eq(int(after.get("blast", {}).get("2", 0)) - int(before.get("blast", {}).get("2", 0)), 3, "active and idle blasts at tier 2")
		assert_eq(int(after.get("shield", {}).get("1", 0)) - int(before.get("shield", {}).get("1", 0)), 1)
		var faction_vein: Dictionary = Sites.find_site(vein["siteId"])["factionVein"]
		assert_true(not faction_vein.has("guardKit"), "no guard kit on the faction vein")
		assert_true(faction_vein.get("kit", {}).is_empty(), "no factionVein.kit from it")
		assert_true(Fixtures.has_notification("Firm raided your vein in Shoreditch. It's theirs now. They took the guard kit."))
		assert_eq(GameState.state["player"]["inventory"].get("blast", {}), {}, "nothing came back")
	)

	run_case("a_raid_claim_on_an_empty_kit_adds_no_kit_line", func():
		var vein := _seed(1)
		Raiding.resolve_raid_outcome({ "success": true, "veinId": "v1", "siteId": vein["siteId"], "attackerId": "firm", "outcomeType": "claim" }, true)
		assert_true(Fixtures.has_notification("Too late — Firm took your vein in Shoreditch while the alarm was still ringing."))
	)

	run_case("a_raid_loot_leaves_the_kit_on_the_vein", func():
		var vein := _seed_loss_kit()
		Raiding.resolve_raid_outcome({ "success": true, "veinId": "v1", "siteId": vein["siteId"], "attackerId": "firm", "outcomeType": "loot" })
		assert_eq(vein["guardKit"], { "blast": { "2": 3 }, "shield": { "1": 1 } })
	)

	run_case("selling_the_vein_returns_the_kit_to_inventory", func():
		_seed_loss_kit()
		assert_true(VeinTrade.sell_to_faction("v1", "collective")["ok"])
		_assert_kit_back()
	)

	run_case("collapse_returns_the_kit_to_inventory", func():
		var seed := SeedSearch.find_seed_for(200, func():
			var vein := _seed_loss_kit()
			vein["growth"] = 0
			Cultivating.collapse_vein(vein)
			return GameState.state["player"]["veins"].is_empty()
		)
		assert_true(seed != -1, "should find a collapse hit within 200 tries")
		_assert_kit_back()
	)

	run_case("hakim_site_ruin_returns_the_kit_to_inventory", func():
		_seed_loss_kit()
		GameState.state["collective"]["hakimVeinId"] = "v1"
		assert_true(Collective.ruin_hakim_site())
		_assert_kit_back()
	)

	run_case("force_vein_loss_returns_the_kit_to_inventory", func():
		var vein := _seed_loss_kit()
		assert_true(Collective.force_vein_loss("v1", "firm"))
		_assert_kit_back()
		assert_true(not Sites.find_site(vein["siteId"])["factionVein"].has("guardKit"))
	)

	run_case("an_unknown_kit_target_is_empty_and_refuses_moves", func():
		_seed(2)
		Crafting.inventory_add("shield", 2, 1)
		var target := { "kind": "nowhere" }
		assert_eq(GuardKit.target_kit(target), {})
		assert_eq(GuardKit.target_capacity(target), 0)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock_target(target, "shield", 2, 1)["ok"])
		assert_eq(GameState.state, before)
	)

	run_case("old_save_backfills_an_empty_hq_kit", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["home"].erase("guardKit")
		assert_eq(SaveManager.backfill_defaults(save)["home"]["guardKit"], {})
	)

	run_case("hq_kit_round_trips_through_save_and_load", func():
		_seed_hq(1)
		GameState.state["home"]["guardKit"] = { "shield": { "3": 2 } }
		assert_true(SaveManager.save_to_slot(SAVE_TEST_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(SAVE_TEST_SLOT)["ok"])
		SaveManager.delete_slot(SAVE_TEST_SLOT)
		assert_eq(GameState.state["home"]["guardKit"], { "shield": { "3": 2 } })
		assert_eq(typeof(GameState.state["home"]["guardKit"]["shield"]["3"]), TYPE_INT)
	)

	run_case("hq_stock_fills_two_slots_per_guard_then_refuses", func():
		_seed_hq(1)
		Crafting.inventory_add("blast", 1, 4)
		assert_eq(GuardKit.hq_capacity(), 2)
		assert_true(GuardKit.stock_hq("blast", 1, 2)["ok"])
		assert_eq(GameState.state["home"]["guardKit"], { "blast": { "1": 2 } })
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock_hq("blast", 1, 1)["ok"], "full kit refuses")
		assert_eq(GameState.state, before)
	)

	run_case("hq_stock_refuses_off_allowlist_and_too_few_held", func():
		_seed_hq(2)
		Crafting.inventory_add("healingSalve", 1, 1)
		Crafting.inventory_add("blast", 1, 1)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock_hq("healingSalve", 1, 1)["ok"])
		assert_true(not GuardKit.stock_hq("blast", 1, 2)["ok"])
		assert_eq(GameState.state, before)
	)

	run_case("hq_stock_refuses_with_no_hq_guards_but_unstock_is_allowed", func():
		_seed_hq(0)
		GameState.state["home"]["guardKit"] = { "shield": { "2": 2 } }
		Crafting.inventory_add("blast", 1, 1)
		var before: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(not GuardKit.stock_hq("blast", 1, 1)["ok"])
		assert_eq(GameState.state, before)
		assert_true(GuardKit.unstock_hq("shield", 2, 2)["ok"])
		assert_eq(GameState.state["home"]["guardKit"], {})
		assert_eq(GameState.state["player"]["inventory"]["shield"]["2"], 2)
	)

	run_case("hq_kit_target_reads_and_moves_the_hq_kit", func():
		_seed_hq(2)
		Crafting.inventory_add("shield", 2, 3)
		var target := { "kind": "hq" }
		assert_eq(GuardKit.target_capacity(target), 4)
		assert_eq(GuardKit.target_guard_count(target), 2)
		assert_eq(GuardKit.target_name(target), "HQ")
		assert_true(GuardKit.stock_target(target, "shield", 2, 3)["ok"])
		assert_eq(GuardKit.target_kit(target), { "shield": { "2": 3 } })
		assert_true(GuardKit.unstock_target(target, "shield", 2, 1)["ok"])
		assert_eq(GameState.state["home"]["guardKit"], { "shield": { "2": 2 } })
	)

	run_case("dropping_an_hq_guard_keeps_the_kit_and_the_excess_goes_idle", func():
		_seed_hq(2)
		GameState.state["home"]["guardKit"] = { "blast": { "1": 5 } }
		assert_true(Home.drop_guard())
		assert_eq(GameState.state["home"]["guardKit"], { "blast": { "1": 5 } }, "kit kept")
		assert_eq(GuardKit.hq_active_units(), { "blast": { "1": 2 } })
		assert_true(GuardKit.unstock_hq("blast", 1, 5)["ok"], "over-capacity return allowed")
	)

	run_case("refill_restocks_only_spent_recipes_highest_tier_first_up_to_capacity", func():
		var vein := _seed(2)  # cap 4
		vein["guardKit"] = { "shield": { "1": 1 } }
		Crafting.inventory_add("blast", 1, 5)
		Crafting.inventory_add("blast", 3, 1)
		Crafting.inventory_add("shield", 2, 4)
		Crafting.inventory_add("timePearl", 1, 4)
		GuardKit.refill_vein(vein, { "blast": 3 })
		assert_eq(vein["guardKit"], { "shield": { "1": 1 }, "blast": { "3": 1, "1": 2 } }, "3 blasts, best tier first")
		assert_eq(GameState.state["player"]["inventory"]["blast"].get("1", 0), 3)
		assert_eq(GameState.state["player"]["inventory"]["shield"]["2"], 4, "unspent recipe untouched")
		GuardKit.refill_vein(vein, { "blast": 3 })
		assert_eq(GuardKit.unit_count(vein["guardKit"]), 4, "capped at 2 x guards")
	)

	run_case("refill_stops_when_inventory_runs_out", func():
		_seed_hq(3)
		GameState.state["home"]["guardKit"] = {}
		Crafting.inventory_add("blast", 1, 1)
		GuardKit.refill_hq({ "blast": 2, "shield": 2 })
		assert_eq(GameState.state["home"]["guardKit"], { "blast": { "1": 1 } })
	)

	run_case("hq_overflow_returns_lowest_tiers_and_conserves_units", func():
		_seed_hq(1)  # cap 2
		var kit := { "blast": { "1": 2, "3": 1 }, "shield": { "2": 2 } }
		var inventory := { "blast": { "1": 1 } }
		GuardKit.return_overflow(kit, 2, inventory)
		assert_eq(kit, { "blast": { "3": 1 }, "shield": { "2": 1 } })
		assert_eq(inventory, { "blast": { "1": 3 }, "shield": { "2": 1 } })
	)

	run_case("fought_vein_defence_refills_spent_units_after_exit", func():
		var vein := _seed(1)
		Crafting.inventory_add("blast", 1, 3)
		vein["guardKit"] = { "blast": { "2": 2 } }
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["context"] = Combat.CONTEXT_DEFEND_VEIN
		GameState.state["combat"]["veinId"] = "v1"
		GameState.state["combat"]["guardKit"] = { "items": { "blast": { "2": 1 } }, "used": { "blast": { "2": 1 } } }
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(Cultivating.find_vein("v1")["guardKit"], { "blast": { "2": 1, "1": 1 } }, "one blast refilled from inventory")
	)

# "v1" with 1 guard holding 3 tier-2 blasts (1 idle) and 1 tier-1 shield.
func _seed_loss_kit() -> Dictionary:
	var vein := _seed(1)
	vein["guardKit"] = { "blast": { "2": 3 }, "shield": { "1": 1 } }
	return vein


func _faction_items(faction_id: String) -> Dictionary:
	return GameState.deep_copy(GameState.state["factions"][faction_id]["holdings"]["items"])


func _assert_kit_back() -> void:
	assert_eq(Cultivating.find_vein("v1"), null, "vein gone")
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	assert_eq(inventory.get("blast", {}).get("2", 0), 3, "blasts back at tier 2")
	assert_eq(inventory.get("shield", {}).get("1", 0), 1, "shield back at tier 1")


# One player vein "v1" with `guards` guards (tier guard + extras).
func _seed(guards: int) -> Dictionary:
	GameState.reset()
	var vein := Fixtures.seed_vein("v1", 50)
	vein["guardKit"] = {}
	if guards > 0:
		vein["security"] = "guarded"
		vein["extraGuards"] = guards - 1
	return vein


# Fresh state with `guards` HQ guards and an empty HQ kit.
func _seed_hq(guards: int) -> void:
	GameState.reset()
	GameState.state["home"]["guardCount"] = guards
