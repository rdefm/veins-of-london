extends "res://tests/test_base.gd"

# VeinTrade — collective1-05, spec.md §5.6/§8.3: quote()'s worked-example
# price table and sell_to_faction()'s transfer mechanics (removal from
# state.player.veins, faction-vein re-creation preserving growth/oreType/
# hospitability, the soldByPlayer marker Objectives' vein_sold_to_faction
# evaluator reads, the queued seed_claim map event, price-0 support for
# ticket 14's Hakim handback).


static func _site(id: String, district: String, ore_type: String, tier: String, bonuses: Array = []) -> Dictionary:
	return {
		"id": id, "district": district, "tier": tier, "oreType": ore_type,
		"bonuses": bonuses, "discoveredDay": 1, "claimed": true, "factionVein": null,
		"hasNaturalVein": false,
	}


static func _player_vein(id: String, site_id: String, district: String, ore_type: String, growth: int, tier: String, bonuses: Array = []) -> Dictionary:
	return {
		"id": id, "district": district, "oreType": ore_type, "growth": growth,
		"security": "none", "alarmUpgrades": [], "location": "Test Alley",
		"claimedOnDay": 1, "siteId": site_id, "hospitability": { "tier": tier, "bonuses": bonuses },
		"rampantDays": 0,
	}


# One player vein + its matching site, wired together, so sell_to_faction()
# can resolve vein.siteId -> Sites.find_site() the same way it does in the
# real game.
static func _seed_vein(growth: int, tier: String, ore_type: String = "life") -> Dictionary:
	var site := _site("s1", "shoreditch", ore_type, tier)
	var vein := _player_vein("v1", "s1", "shoreditch", ore_type, growth, tier)
	GameState.state["world"]["sites"] = [site]
	GameState.state["player"]["veins"] = [vein]
	return vein


# A faction-owned site vein, wired to its site, so buy_from_faction() can
# resolve site.factionVein -> Sites the same way it does in the real game.
static func _faction_seed_vein(growth: int, tier: String, ore_type: String = "life") -> Dictionary:
	var site := _site("s1", "shoreditch", ore_type, tier)
	site["claimed"] = false
	var vein := Factions.create_faction_vein("collective", site, growth)
	site["factionVein"] = vein
	GameState.state["world"]["sites"] = [site]
	GameState.state["player"]["veins"] = []
	return vein


func run() -> void:
	# ── quote() — spec §8.3's worked table, life calc (basePrice £70) ─────

	run_case("quote_fresh_seed_fair", func():
		GameState.reset()
		var vein := _seed_vein(20, "fair")
		assert_eq(VeinTrade.quote(vein), 980)
	)

	run_case("quote_fresh_seed_rich", func():
		GameState.reset()
		var vein := _seed_vein(20, "rich")
		assert_eq(VeinTrade.quote(vein), 1568)
	)

	run_case("quote_neutral_dormant_rich", func():
		GameState.reset()
		var vein := _seed_vein(50, "rich")
		assert_eq(VeinTrade.quote(vein), 3920)
	)

	run_case("quote_lush_85_fair", func():
		GameState.reset()
		var vein := _seed_vein(85, "fair")
		assert_eq(VeinTrade.quote(vein), 4165)
	)

	run_case("quote_lush_85_rich", func():
		GameState.reset()
		var vein := _seed_vein(85, "rich")
		assert_eq(VeinTrade.quote(vein), 6664)
	)

	run_case("quote_rampant_100_rich", func():
		GameState.reset()
		var vein := _seed_vein(100, "rich")
		assert_eq(VeinTrade.quote(vein), 7840)
	)

	run_case("quote_lush_85_saturated", func():
		GameState.reset()
		var vein := _seed_vein(85, "saturated")
		assert_eq(VeinTrade.quote(vein), 9996)
	)

	# ── sell_to_faction() ───────────────────────────────────────────────

	run_case("sell_to_faction_removes_the_vein_from_player_veins", func():
		GameState.reset()
		_seed_vein(50, "rich")

		VeinTrade.sell_to_faction("v1", "collective")

		assert_eq(GameState.state["player"]["veins"].size(), 0)
	)

	run_case("sell_to_faction_pays_the_quoted_price_into_player_cash", func():
		GameState.reset()
		var vein := _seed_vein(50, "rich")
		var cash_before: int = GameState.state["player"]["cash"]
		var price: int = VeinTrade.quote(vein)

		var result := VeinTrade.sell_to_faction("v1", "collective")

		assert_eq(result["price"], price)
		assert_eq(GameState.state["player"]["cash"], cash_before + price)
	)

	run_case("sell_to_faction_records_the_payment_in_the_bank_log", func():
		GameState.reset()
		_seed_vein(50, "rich")

		VeinTrade.sell_to_faction("v1", "collective")

		var log: Array = GameState.state["bankLog"]
		assert_eq(log.size(), 1)
		assert_true(log[0]["amount"] > 0)
	)

	run_case("sell_to_faction_creates_a_faction_vein_preserving_growth_oreType_and_hospitability", func():
		GameState.reset()
		_seed_vein(85, "rich", "fate")

		VeinTrade.sell_to_faction("v1", "collective")

		var site: Variant = Sites.find_site("s1")
		var faction_vein: Variant = site["factionVein"]
		assert_true(faction_vein != null)
		assert_eq(faction_vein["factionId"], "collective")
		assert_eq(faction_vein["oreType"], "fate")
		assert_eq(faction_vein["growth"], 85)
		assert_eq(faction_vein["hospitability"]["tier"], "rich")
	)

	run_case("sell_to_faction_stamps_soldByPlayer_on_the_new_faction_vein", func():
		GameState.reset()
		_seed_vein(50, "fair")

		VeinTrade.sell_to_faction("v1", "collective")

		var site: Variant = Sites.find_site("s1")
		assert_true(site["factionVein"]["soldByPlayer"], "Objectives.vein_sold_to_faction reads this marker")
	)

	run_case("sell_to_faction_unclaims_the_site", func():
		GameState.reset()
		_seed_vein(50, "fair")

		VeinTrade.sell_to_faction("v1", "collective")

		var site: Variant = Sites.find_site("s1")
		assert_true(not site["claimed"])
	)

	run_case("sell_to_faction_queues_a_seed_claim_map_event_for_the_buying_faction", func():
		GameState.reset()
		_seed_vein(50, "fair")

		VeinTrade.sell_to_faction("v1", "collective")

		var queue: Array = GameState.state["mapEvents"]["queue"]
		assert_eq(queue.size(), 1)
		assert_eq(queue[0]["type"], "seed_claim")
		assert_eq(queue[0]["district"], "shoreditch")
		assert_eq(queue[0]["owner"], "collective")
	)

	run_case("sell_to_faction_supports_a_price_of_zero_for_the_hakim_handback_path", func():
		GameState.reset()
		var vein := _seed_vein(20, "fair")  # a fresh seed still quotes > 0 normally
		# Force a zero quote by zeroing growth -- the transfer path itself
		# must not reject or special-case a £0 sale.
		vein["growth"] = 0
		var cash_before: int = GameState.state["player"]["cash"]

		var result := VeinTrade.sell_to_faction("v1", "collective")

		assert_true(result["ok"])
		assert_eq(result["price"], 0)
		assert_eq(GameState.state["player"]["cash"], cash_before)
		assert_eq(GameState.state["player"]["veins"].size(), 0, "the vein still transfers even at price 0")
	)

	run_case("sell_to_faction_price_override_forces_the_price_regardless_of_quote", func():
		GameState.reset()
		var vein := _seed_vein(85, "rich")  # quote() would price this well above 0
		assert_true(VeinTrade.quote(vein) > 0)
		var cash_before: int = GameState.state["player"]["cash"]

		var result := VeinTrade.sell_to_faction("v1", "collective", 0)

		assert_eq(result["price"], 0)
		assert_eq(GameState.state["player"]["cash"], cash_before)
	)

	run_case("sell_to_faction_price_override_does_not_stamp_soldByPlayer", func():
		GameState.reset()
		_seed_vein(61, "fair")

		VeinTrade.sell_to_faction("v1", "collective", 0)

		var site: Variant = Sites.find_site("s1")
		assert_true(not site["factionVein"]["soldByPlayer"], "a forced price marks a handback, not a market sale (ticket 14)")
	)

	run_case("sell_to_faction_without_a_price_override_still_stamps_soldByPlayer", func():
		GameState.reset()
		_seed_vein(50, "fair")

		VeinTrade.sell_to_faction("v1", "collective")

		var site: Variant = Sites.find_site("s1")
		assert_true(site["factionVein"]["soldByPlayer"])
	)

	# ── 87-map-slot-index-recycling ───────────────────────────────────────

	run_case("sell_to_faction_releases_the_veins_own_slot_when_it_has_one", func():
		GameState.reset()
		# Only the saturated-site natural-vein bonus ever carries its own
		# stamped slotIndex (Sites.attempt_seed()) -- simulated here by
		# stamping it directly onto the fixture.
		var vein := _seed_vein(50, "rich")
		vein["slotIndex"] = 6

		VeinTrade.sell_to_faction("v1", "collective")

		assert_eq(Sites.next_slot_index("shoreditch"), 6, "the sold vein's own stamped slot must be recycled")
	)

	run_case("sell_to_faction_frees_nothing_extra_when_the_vein_reuses_its_sites_slot", func():
		GameState.reset()
		# An ordinary vein (no own slotIndex) hands the site off with a new
		# factionVein rather than deleting it -- the site keeps its slot, so
		# nothing should land in the free pool at all.
		_seed_vein(50, "rich")

		VeinTrade.sell_to_faction("v1", "collective")

		assert_eq(GameState.state["world"]["mapSlotFreePool"].get("shoreditch", []), [], "no slot should have been released")
	)

	run_case("sell_to_faction_fails_for_an_unknown_vein_id", func():
		GameState.reset()
		_seed_vein(50, "fair")

		var result := VeinTrade.sell_to_faction("not_a_real_vein", "collective")

		assert_true(not result["ok"])
		assert_eq(GameState.state["player"]["veins"].size(), 1, "an unknown vein id must not touch the real veins")
	)

	# ── vein-trade-assets ticket 02: transfer_to_faction() split-out ───────
	# (sell_to_faction() above is now transfer_to_faction() + an immediate,
	# unconditional cash payout -- Archie's cut-and-risk lane, Economy.
	# execute_sale, calls transfer_to_faction() directly and defers the cash
	# to the mugging roll instead.)

	run_case("transfer_to_faction_moves_the_vein_and_recreates_it_as_a_faction_vein_without_paying_cash", func():
		GameState.reset()
		_seed_vein(50, "rich")
		var cash_before: int = GameState.state["player"]["cash"]

		var result := VeinTrade.transfer_to_faction("v1", "collective", 500, true)

		assert_true(result["ok"])
		assert_eq(GameState.state["player"]["veins"].size(), 0, "the vein still leaves player.veins")
		assert_eq(GameState.state["player"]["cash"], cash_before, "transfer_to_faction must not itself pay the player -- that's the caller's job")
		var site: Variant = Sites.find_site("s1")
		assert_true(site["factionVein"] != null)
		assert_eq(site["factionVein"]["factionId"], "collective")
	)

	run_case("transfer_to_faction_still_accrues_tradeProgress_on_the_given_price", func():
		GameState.reset()
		_seed_vein(50, "rich")

		VeinTrade.transfer_to_faction("v1", "collective", 500, true)

		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], 500, "accrual runs off the given price even though no cash changed hands yet")
	)

	run_case("transfer_to_faction_count_as_player_sale_false_does_not_stamp_soldByPlayer", func():
		GameState.reset()
		_seed_vein(50, "rich")

		VeinTrade.transfer_to_faction("v1", "collective", 0, false)

		var site: Variant = Sites.find_site("s1")
		assert_true(not site["factionVein"]["soldByPlayer"])
	)

	run_case("transfer_to_faction_fails_for_an_unknown_vein_id", func():
		GameState.reset()
		_seed_vein(50, "fair")

		var result := VeinTrade.transfer_to_faction("not_a_real_vein", "collective", 100, true)

		assert_true(not result["ok"])
		assert_eq(GameState.state["player"]["veins"].size(), 1, "an unknown vein id must not touch the real veins")
	)

	run_case("sell_to_faction_still_pays_cash_immediately_on_top_of_the_transfer", func():
		GameState.reset()
		var vein := _seed_vein(50, "rich")
		var price: int = VeinTrade.quote(vein)
		var cash_before: int = GameState.state["player"]["cash"]

		var result := VeinTrade.sell_to_faction("v1", "collective")

		assert_eq(result["price"], price)
		assert_eq(GameState.state["player"]["cash"], cash_before + price, "sell_to_faction's own immediate-payout behaviour is unchanged by the transfer_to_faction split")
	)

	# ── VeinList wiring ──────────────────────────────────────────────────

	run_case("vein_list_actions_for_omits_sell_when_veinSaleUnlocked_is_false", func():
		GameState.reset()
		var vein := _seed_vein(50, "fair")

		var ids: Array = VeinList.actions_for(vein).map(func(g): return g["id"])

		assert_true(not ids.has(VeinList.SELL_ID))
	)

	run_case("vein_list_actions_for_includes_sell_once_veinSaleUnlocked_is_true", func():
		GameState.reset()
		GameState.state["flags"]["veinSaleUnlocked"] = true
		var vein := _seed_vein(50, "fair")

		var ids: Array = VeinList.actions_for(vein).map(func(g): return g["id"])

		assert_true(ids.has(VeinList.SELL_ID))
	)

	# ── vein-trade-assets ticket 03: buy_from_faction() ─────────────────────

	run_case("buy_from_faction_adds_the_vein_to_player_veins", func():
		GameState.reset()
		var faction_vein := _faction_seed_vein(50, "rich")
		GameState.state["player"]["cash"] = 100000

		VeinTrade.buy_from_faction(faction_vein["id"], "collective")

		assert_eq(GameState.state["player"]["veins"].size(), 1)
		assert_eq(GameState.state["player"]["veins"][0]["id"], faction_vein["id"])
	)

	run_case("buy_from_faction_strips_the_factionId_field", func():
		GameState.reset()
		var faction_vein := _faction_seed_vein(50, "rich")
		GameState.state["player"]["cash"] = 100000

		VeinTrade.buy_from_faction(faction_vein["id"], "collective")

		assert_true(not GameState.state["player"]["veins"][0].has("factionId"))
	)

	run_case("buy_from_faction_preserves_growth_oreType_and_hospitability", func():
		GameState.reset()
		var faction_vein := _faction_seed_vein(85, "rich", "fate")
		GameState.state["player"]["cash"] = 100000

		VeinTrade.buy_from_faction(faction_vein["id"], "collective")

		var player_vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(player_vein["oreType"], "fate")
		assert_eq(player_vein["growth"], 85)
		assert_eq(player_vein["hospitability"]["tier"], "rich")
	)

	run_case("buy_from_faction_charges_the_quoted_price", func():
		GameState.reset()
		var faction_vein := _faction_seed_vein(50, "rich")
		GameState.state["player"]["cash"] = 100000
		var cash_before: int = GameState.state["player"]["cash"]
		var price: int = VeinTrade.quote(faction_vein)

		var result := VeinTrade.buy_from_faction(faction_vein["id"], "collective")

		assert_eq(result["price"], price)
		assert_eq(GameState.state["player"]["cash"], cash_before - price)
	)

	run_case("buy_from_faction_records_the_payment_in_the_bank_log", func():
		GameState.reset()
		var faction_vein := _faction_seed_vein(50, "rich")
		GameState.state["player"]["cash"] = 100000

		VeinTrade.buy_from_faction(faction_vein["id"], "collective")

		var log: Array = GameState.state["bankLog"]
		assert_eq(log.size(), 1)
		assert_true(log[0]["amount"] < 0)
	)

	run_case("buy_from_faction_claims_the_site_and_clears_the_faction_vein", func():
		GameState.reset()
		var faction_vein := _faction_seed_vein(50, "rich")
		GameState.state["player"]["cash"] = 100000

		VeinTrade.buy_from_faction(faction_vein["id"], "collective")

		var site: Variant = Sites.find_site("s1")
		assert_true(site["claimed"])
		assert_eq(site["factionVein"], null)
	)

	run_case("buy_from_faction_queues_a_seed_claim_map_event_for_the_player", func():
		GameState.reset()
		var faction_vein := _faction_seed_vein(50, "rich")
		GameState.state["player"]["cash"] = 100000

		VeinTrade.buy_from_faction(faction_vein["id"], "collective")

		var queue: Array = GameState.state["mapEvents"]["queue"]
		assert_eq(queue.size(), 1)
		assert_eq(queue[0]["type"], "seed_claim")
		assert_eq(queue[0]["district"], "shoreditch")
		assert_eq(queue[0]["owner"], "player")
	)

	run_case("buy_from_faction_accrues_tradeProgress_on_the_price", func():
		GameState.reset()
		# growth 10 on "fair" keeps the quote below RelationAccrual's 750
		# collective rate, so tradeProgress lands at the raw price with no
		# daily-cap rollover complicating the assertion (see
		# transfer_to_faction_still_accrues_tradeProgress_on_the_given_price's
		# own low-price choice for the same reason).
		var faction_vein := _faction_seed_vein(10, "fair")
		GameState.state["player"]["cash"] = 100000
		var price: int = VeinTrade.quote(faction_vein)
		assert_true(price < 750, "sanity: keep this test under the accrual rate")

		VeinTrade.buy_from_faction(faction_vein["id"], "collective")

		assert_eq(GameState.state["factions"]["collective"]["tradeProgress"], price)
	)

	run_case("buy_from_faction_fails_for_an_unknown_vein_id", func():
		GameState.reset()
		_faction_seed_vein(50, "rich")
		GameState.state["player"]["cash"] = 100000

		var result := VeinTrade.buy_from_faction("not_a_real_vein", "collective")

		assert_true(not result["ok"])
		assert_eq(GameState.state["player"]["veins"].size(), 0, "an unknown vein id must not touch real state")
	)

	run_case("buy_from_faction_rejects_when_cash_is_insufficient", func():
		GameState.reset()
		var faction_vein := _faction_seed_vein(85, "rich")
		var price: int = VeinTrade.quote(faction_vein)
		GameState.state["player"]["cash"] = price - 1

		var result := VeinTrade.buy_from_faction(faction_vein["id"], "collective")

		assert_true(not result["ok"])
		assert_eq(GameState.state["player"]["veins"].size(), 0, "a rejected purchase must not transfer the vein")
		var site: Variant = Sites.find_site("s1")
		assert_true(site["factionVein"] != null, "a rejected purchase must leave the faction vein in place")
	)

	run_case("vein_list_apply_option_sell_opens_the_quote_modal_without_selling_yet", func():
		GameState.reset()
		GameState.state["flags"]["veinSaleUnlocked"] = true
		_seed_vein(50, "rich")

		var result := VeinList.apply_option(VeinList.SELL_ID, "v1")

		assert_true(result["ok"])
		assert_eq(GameState.state["player"]["veins"].size(), 1, "opening the confirm modal must not itself sell the vein")
		assert_eq(GameState.state["modal"]["type"], "sell_vein_quote")
		assert_eq(GameState.state["modal"]["data"]["veinId"], "v1")
		assert_eq(GameState.state["modal"]["data"]["factionId"], "collective")
	)
