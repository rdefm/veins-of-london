extends "res://tests/test_base.gd"

const OffersSystem := preload("res://systems/offers.gd")


func run() -> void:
	calendar_start_weekday = 0  # fixtures count days from a Monday day 1
	run_case("scripted_offer_snapshots_quote_and_acceptance_creates_contract", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		GameState.state["market"]["goods"]["ore"]["life"]["price"] = 56
		var created: Dictionary = OffersSystem.create_scripted_offer("scripted_life_order")
		assert_true(created["ok"])
		var offer: Dictionary = created["offer"]
		assert_eq(offer["quote"]["unitValue"], 56, "today's London quote, not base £88/10")
		assert_eq(offer["quote"]["payment"], 35, "5 × £56/10 × 1.25")
		GameState.state["market"]["goods"]["ore"]["life"]["price"] = 90
		var accepted: Dictionary = OffersSystem.accept_offer(offer["id"])
		assert_true(accepted["ok"])
		assert_eq(OffersSystem.pending_offers().size(), 0)
		assert_eq(OffersSystem.active_contracts().size(), 1)
		assert_eq(accepted["contract"]["signedQuote"]["payment"], 35, "acceptance never reprices")
		assert_eq(accepted["contract"]["dueDay"], 14, "scripted one-off uses authored deadline")
	)

	run_case("pending_price_is_locked_and_settlement_pays_the_signed_price", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "ops")
		GameState.state["market"]["goods"]["ore"]["life"]["price"] = 56
		var offer: Dictionary = OffersSystem.create_scripted_offer("scripted_life_order")["offer"]
		GameState.state["market"]["goods"]["ore"]["life"]["stock"] = 0
		Market.daily_reprice()
		assert_true(Market.quote("ore", "life") != 56, "the market moved")
		assert_eq(OffersSystem.pending_offers()[0]["quote"]["payment"], 35, "pending price ignores the reprice")
		var contract: Dictionary = OffersSystem.accept_offer(offer["id"])["contract"]
		assert_eq(contract["signedQuote"]["payment"], 35)
		Market.daily_reprice()
		GameState.state["player"]["orichalchum"]["life"] = 5
		var cash_before: int = GameState.state["player"]["cash"]
		Contracts.process_sales_deliveries()
		assert_eq(GameState.state["player"]["cash"], cash_before + 35, "settles at the signed price")
	)

	run_case("every_offer_template_expires_two_days_after_issue", func():
		for template_id in GameData.OFFER_TEMPLATES.keys():
			GameState.reset()
			GameState.state["world"]["day"] = 7
			var created: Dictionary = OffersSystem.create_offer(GameData.OFFER_TEMPLATES[template_id])
			assert_true(created["ok"], template_id)
			assert_eq(created["offer"]["expiresDay"], 9, template_id)
			GameState.state["world"]["day"] = 8
			OffersSystem.expire_pending_offers()
			assert_eq(OffersSystem.pending_offers().size(), 1, "%s still open the next day" % template_id)
			GameState.state["world"]["day"] = 9
			OffersSystem.expire_pending_offers()
			assert_eq(OffersSystem.pending_offers().size(), 0, "%s gone on day 2" % template_id)
	)

	run_case("crafted_quote_reads_the_items_london_quote_and_ignores_tier", func():
		GameState.reset()
		GameState.state["market"]["goods"]["consumable"]["healingBurst"]["price"] = 198
		var quote: Dictionary = OffersSystem.quote_for_request({ "kind": "consumable", "type": "healingBurst", "qty": 4 }, 2)
		assert_eq(quote["unitValue"], 198, "the item's own London quote")
		assert_eq(quote["payment"], 1040, "level 2 Sales adds 5% after the contract multiplier")
	)

	run_case("unit_value_follows_the_quote_after_a_reprice", func():
		GameState.reset()
		var before := OffersSystem.unit_value("ore", "time")
		GameState.state["market"]["goods"]["ore"]["time"]["stock"] = 0
		Market.daily_reprice()
		var after := OffersSystem.unit_value("ore", "time")
		assert_true(after > before, "a starved market lifts tomorrow's unit value")
		assert_eq(after, Market.quote("ore", "time"))
	)

	run_case("random_offer_roll_is_passive_capped_and_expires", func():
		GameState.reset()
		assert_eq(OffersSystem.sales_skill(), 1)
		assert_almost_eq(OffersSystem.random_offer_chance(), 0.5, 0.0001)
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "ops")
		GameState.state["contacts"]["archie"]["salesSkill"] = 10
		assert_almost_eq(OffersSystem.random_offer_chance(), 0.75, 0.0001)
		var created: Dictionary = OffersSystem.create_offer(GameData.OFFER_TEMPLATES["random_time_ore"])
		assert_true(created["ok"])
		var offer: Dictionary = created["offer"]
		assert_true(offer["request"]["qty"] >= 20 and offer["request"]["qty"] <= 200)
		assert_eq(offer["expiresDay"], 3, "issued day 1, expires 2 days later")
		GameState.state["world"]["day"] = offer["expiresDay"]
		OffersSystem.expire_pending_offers()
		assert_eq(OffersSystem.pending_offers().size(), 0)
	)

	run_case("random_offer_chance_rises_seven_points_per_sales_level_to_75", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "ops")
		var expected := [0.50, 0.57, 0.64, 0.71, 0.75, 0.75, 0.75, 0.75, 0.75]
		for level in range(1, 10):
			GameState.state["contacts"]["archie"]["salesSkill"] = level
			assert_almost_eq(OffersSystem.random_offer_chance(), expected[level - 1], 0.0001, "level %d" % level)
	)

	run_case("level_one_sales_averages_one_random_offer_every_two_days_with_the_questline_pending", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "ops")
		# Four scripted offers that never expire: they once filled PENDING_CAP
		# and blocked the roll entirely.
		for template_id in ["biz_starter_1", "biz_recurring_time_pearl", "biz_recurring_time_ore", "biz_recurring_life_ore"]:
			var scripted: Dictionary = OffersSystem.create_scripted_offer(template_id)
			assert_true(scripted["ok"], template_id)
			scripted["offer"]["expiresDay"] = 100000
		var issued := 0
		var days := 0
		for run in 10:
			Rng.set_seed(146 + run)
			for day in 60:
				GameState.state["world"]["day"] += 1
				GameState.state["contacts"]["archie"]["salesSkill"] = 1  # sourcing XP can't level him mid-run
				var before: int = GameState.state["sales"]["nextOfferId"]
				OffersSystem.daily_tick()
				issued += int(GameState.state["sales"]["nextOfferId"]) - before
				days += 1
		var mean_interval := float(days) / float(issued)
		assert_true(mean_interval >= 1.8 and mean_interval <= 2.2, "~1 offer per 2 days at 50%%/day, got every %.2f days" % mean_interval)
		assert_eq(OffersSystem.pending_offers().size() - OffersSystem.random_pending_count(), 4, "scripted offers still pending")
	)

	run_case("random_cap_counts_only_random_offers", func():
		GameState.reset()
		for template_id in ["biz_starter_1", "biz_recurring_time_pearl", "biz_recurring_time_ore", "biz_recurring_life_ore"]:
			OffersSystem.create_scripted_offer(template_id)
		assert_eq(OffersSystem.random_pending_count(), 0)
		for index in OffersSystem.PENDING_CAP:
			assert_true(OffersSystem.create_offer(GameData.OFFER_TEMPLATES["random_time_ore"])["ok"], "random %d" % index)
		assert_true(not OffersSystem.create_offer(GameData.OFFER_TEMPLATES["random_time_ore"])["ok"], "four randoms fill the cap")
	)

	run_case("recurring_contract_falls_due_on_monday_and_renews_to_the_next_monday", func():
		GameState.reset()
		GameState.state["world"]["day"] = 3  # WED
		var created: Dictionary = OffersSystem.create_scripted_offer("scripted_physics_weekly")
		var contract: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])["contract"]
		assert_eq(contract["dueDay"], 8, "WED day 3 -> MON day 8")
		assert_true(Calendar.is_monday(contract["dueDay"]))
		GameState.state["world"]["day"] = 8
		Contracts.daily_tick()
		assert_eq(contract["dueDay"], 15, "renewal lands on MON day 15")
	)

	run_case("recurring_first_due_date_is_strictly_after_acceptance", func():
		GameState.reset()
		GameState.state["world"]["day"] = 8
		var created: Dictionary = OffersSystem.create_scripted_offer("scripted_physics_weekly")
		var accepted: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])
		assert_eq(accepted["contract"]["dueDay"], 15, "MON day 8 repeats next MON")
	)

	run_case("staffed_sales_earns_source_xp_but_declining_or_expiry_adds_none", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "ops")
		var created: Dictionary = OffersSystem.create_offer(GameData.OFFER_TEMPLATES["random_time_ore"])
		assert_true(created["ok"])
		assert_eq(GameState.state["contacts"]["archie"]["salesXP"], 5)
		OffersSystem.decline_offer(created["offer"]["id"])
		assert_eq(GameState.state["contacts"]["archie"]["salesXP"], 5)
	)

	# ticket 32: mixed one-off quote/deadline math -- fate ore (£90) qty 3 +
	# timePearl (£120) qty 2, one extra type beyond the first. Built inline
	# rather than via data/offers.json: business-spec.md's "Open decisions"
	# defers the real scripted/random mixed-offer catalogue to tickets 33/34.
	run_case("mixed_oneoff_quotes_per_type_bonus_and_extends_deadline", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		var created: Dictionary = OffersSystem.create_offer({
			"id": "t_mixed_calc_order", "source": "scripted", "contractType": "oneOff",
			"deadlineAfterDays": 5,
			"request": { "types": [{ "kind": "ore", "type": "fate", "qty": 3 }, { "kind": "consumable", "type": "timePearl", "qty": 2 }] },
		})
		assert_true(created["ok"])
		var offer: Dictionary = created["offer"]
		var lines: Array = offer["quote"]["lines"]
		assert_eq(lines.size(), 2)
		assert_eq(lines[0]["unitValue"], 113, "fate base price (per 10) under stable barometer")
		assert_eq(lines[1]["unitValue"], 120, "timePearl base price under stable barometer")
		assert_eq(offer["quote"]["liveValue"], 274, "3 × £113/10 (34) + 2×120")
		assert_eq(offer["quote"]["payment"], 411, "274 × 1.25 × 1.20 (one extra type)")
		var accepted: Dictionary = OffersSystem.accept_offer(offer["id"])
		assert_true(accepted["ok"])
		assert_eq(accepted["contract"]["dueDay"], 17, "authored 5 days + 2 for the one extra type")
	)

	run_case("mixed_requests_are_rejected_for_recurring_contracts", func():
		GameState.reset()
		var created: Dictionary = OffersSystem.create_offer({
			"id": "t_mixed_recurring", "source": "scripted", "contractType": "recurring", "weekday": 1,
			"request": { "types": [{ "kind": "ore", "type": "life", "qty": 3 }, { "kind": "ore", "type": "fate", "qty": 3 }] },
		})
		assert_true(not created["ok"], "mixed requests are one-off only")
	)

	run_case("mixed_request_without_authored_qty_rolls_each_type_within_the_2_5_band", func():
		GameState.reset()
		var created: Dictionary = OffersSystem.create_offer({
			"id": "t_mixed_random", "source": "random", "contractType": "oneOff",
			"request": { "types": [{ "kind": "ore", "type": "life" }, { "kind": "ore", "type": "fate" }] },
		})
		assert_true(created["ok"])
		for line in created["offer"]["request"]["types"]:
			assert_true(int(line["qty"]) >= 2 and int(line["qty"]) <= 5, "mixed one-off per-type qty band is 2-5")
	)

	run_case("scripted_templates_carry_their_authored_counterparty", func():
		GameState.reset()
		var created: Dictionary = OffersSystem.create_scripted_offer("scripted_physics_weekly")
		assert_eq(created["offer"]["counterparty"], "firm")
		var accepted: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])
		assert_eq(accepted["contract"]["counterparty"], "firm", "accept copies the counterparty")
		for template in GameData.OFFER_TEMPLATES.values():
			if template["source"] == "scripted":
				assert_true(GameData.FACTIONS.has(template.get("counterparty", "")), "%s authors a counterparty" % template["id"])
	)

	run_case("small_offers_go_to_collective_or_firm_by_fit", func():
		GameState.reset()
		assert_eq(OffersSystem.small_counterparty({ "kind": "ore", "type": "life", "qty": 1 }), "collective")
		assert_eq(OffersSystem.small_counterparty({ "kind": "ore", "type": "emotion", "qty": 1 }), "collective")
		assert_eq(OffersSystem.small_counterparty({ "kind": "ore", "type": "physics", "qty": 1 }), "firm")
		assert_eq(OffersSystem.small_counterparty({ "kind": "consumable", "type": "enhancementPowder", "qty": 1 }), "collective", "an item counts as its ingredient ores")
		assert_eq(OffersSystem.small_counterparty({ "kind": "consumable", "type": "wormhole", "qty": 1 }), "firm", "time + physics fits the Firm")
		var factions: Dictionary = GameState.state["factions"]
		factions["collective"]["relation"] = 5
		factions["firm"]["relation"] = 10
		assert_eq(OffersSystem.small_counterparty({ "kind": "ore", "type": "time", "qty": 1 }), "firm", "no fit: better relation")
		factions["collective"]["relation"] = 20
		assert_eq(OffersSystem.small_counterparty({ "kind": "ore", "type": "time", "qty": 1 }), "collective")
		factions["firm"]["relation"] = 20
		var seen := {}
		for i in 40:
			seen[OffersSystem.small_counterparty({ "kind": "ore", "type": "fate", "qty": 1 })] = true
		assert_eq(seen.keys().size(), 2, "a relation tie rolls between the two")
		assert_true(seen.has("collective") and seen.has("firm"))
		var threshold: int = GameData.OFFER_COUNTERPARTY["smallOfferThreshold"]
		assert_eq(OffersSystem.pick_counterparty("", { "kind": "consumable", "type": "enhancementPowder", "qty": 1 }, threshold - 1), "collective", "below threshold: small rule, not consumers")
	)

	run_case("large_offers_weight_factions_by_identity", func():
		GameState.reset()
		var threshold: int = GameData.OFFER_COUNTERPARTY["smallOfferThreshold"]
		assert_eq(OffersSystem.identity_weights({ "kind": "ore", "type": "fate", "qty": 1 }), { "network": 1, "conclave": 1 })
		assert_eq(OffersSystem.identity_weights({ "kind": "consumable", "type": "enhancementPowder", "qty": 1 }), { "firm": 3, "guild": 1 })
		var seen := {}
		for i in 60:
			seen[OffersSystem.pick_counterparty("", { "kind": "ore", "type": "fate", "qty": 20 }, threshold)] = true
		assert_eq(seen.keys().size(), 2)
		assert_true(seen.has("network") and seen.has("conclave"), "ore goods go to factions crafting with that ore")
		assert_eq(OffersSystem.pick_counterparty("", { "kind": "consumable", "type": "blast", "qty": 20 }, threshold), "firm", "item goods go to consumers")
		GameState.state["factions"]["collective"]["relation"] = 30
		assert_eq(OffersSystem.pick_counterparty("", { "kind": "consumable", "type": "beALady", "qty": 20 }, threshold), "collective", "no consumer: small rule")
	)
