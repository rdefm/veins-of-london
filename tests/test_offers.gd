extends "res://tests/test_base.gd"

const OffersSystem := preload("res://systems/offers.gd")


func run() -> void:
	run_case("scripted_offer_snapshots_quote_and_acceptance_creates_contract", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		GameState.state["barometer"]["economic"] = "recession"
		var created: Dictionary = OffersSystem.create_scripted_offer("scripted_life_order")
		assert_true(created["ok"])
		var offer: Dictionary = created["offer"]
		assert_eq(offer["quote"]["unitValue"], 56, "£70 with recession's -20% modifier")
		assert_eq(offer["quote"]["payment"], 350, "5 × £56 × 1.25")
		GameState.state["barometer"]["economic"] = "boom"
		var accepted: Dictionary = OffersSystem.accept_offer(offer["id"])
		assert_true(accepted["ok"])
		assert_eq(OffersSystem.pending_offers().size(), 0)
		assert_eq(OffersSystem.active_contracts().size(), 1)
		assert_eq(accepted["contract"]["quote"]["payment"], 350, "acceptance never reprices")
		assert_eq(accepted["contract"]["dueDay"], 14, "scripted one-off uses authored deadline")
	)

	run_case("crafted_quote_weights_recipe_ore_modifiers_and_ignores_tier", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "stable"
		GameState.state["barometer"]["social"] = "stable"
		GameState.state["barometer"]["political"] = "stable"
		GameData.BAROMETER_STATES["economic"]["stable"]["effects"]["timePremium"] = 0.20
		var quote: Dictionary = OffersSystem.quote_for_request({ "kind": "consumable", "type": "healingBurst", "qty": 4 }, 2)
		assert_eq(quote["unitValue"], 198, "time/life 4:4 weights a +20% time premium equally")
		assert_eq(quote["payment"], 1040, "level 2 Sales adds 5% after the contract multiplier")
		GameData.BAROMETER_STATES["economic"]["stable"]["effects"].erase("timePremium")
	)

	run_case("random_offer_roll_is_passive_capped_and_expires", func():
		GameState.reset()
		assert_eq(OffersSystem.sales_skill(), 1)
		assert_eq(OffersSystem.random_offer_chance(), 0.20)
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "ops")
		GameState.state["contacts"]["archie"]["salesSkill"] = 10
		assert_eq(OffersSystem.random_offer_chance(), 0.60)
		var created: Dictionary = OffersSystem.create_offer(GameData.OFFER_TEMPLATES["random_time_ore"])
		assert_true(created["ok"])
		var offer: Dictionary = created["offer"]
		assert_true(offer["request"]["qty"] >= 4 and offer["request"]["qty"] <= 10)
		assert_true(offer["expiresDay"] >= 4 and offer["expiresDay"] <= 15)
		GameState.state["world"]["day"] = offer["expiresDay"]
		OffersSystem.expire_pending_offers()
		assert_eq(OffersSystem.pending_offers().size(), 0)
	)

	run_case("recurring_first_due_date_is_strictly_after_acceptance", func():
		GameState.reset()
		GameState.state["world"]["day"] = 8
		var created: Dictionary = OffersSystem.create_scripted_offer("scripted_physics_weekly")
		var accepted: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])
		assert_eq(accepted["contract"]["dueDay"], 15, "weekday 1 on day 8 repeats next week")
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
			"expiresAfterDays": 6, "deadlineAfterDays": 5,
			"request": { "types": [{ "kind": "ore", "type": "fate", "qty": 3 }, { "kind": "consumable", "type": "timePearl", "qty": 2 }] },
		})
		assert_true(created["ok"])
		var offer: Dictionary = created["offer"]
		var lines: Array = offer["quote"]["lines"]
		assert_eq(lines.size(), 2)
		assert_eq(lines[0]["unitValue"], 90, "fate base price under stable barometer")
		assert_eq(lines[1]["unitValue"], 120, "timePearl base price under stable barometer")
		assert_eq(offer["quote"]["liveValue"], 510, "3×90 + 2×120")
		assert_eq(offer["quote"]["payment"], 765, "510 × 1.25 × 1.20 (one extra type)")
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
