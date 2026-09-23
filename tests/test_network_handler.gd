extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const EventPlay := preload("res://tests/support/event_play.gd")

# collective-act2 09, spec.md §5.3/§6.12: the Network handler's Targets
# (network_reveal_vulnerable_vein, timed networkIntel entries) and Sourcing
# (network_reveal_site) products, and the T12 meet that unlocks them.


func _seed_firm_vein(id: String, security: String) -> String:
	var vein := Fixtures.seed_faction_vein(id, 60, "firm")
	vein["security"] = security
	return vein["siteId"]


func _intel() -> Dictionary:
	return GameState.state["collective"]["networkIntel"]


func run() -> void:
	# ── Targets ───────────────────────────────────────────────────────────

	run_case("soft_vein_gets_a_timed_claim_bonus_that_expires_after_duration", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		var site_id := _seed_firm_vein("fv_soft", "basic")
		var day: int = GameState.state["world"]["day"]
		var result := NetworkHandler.buy_target(site_id, NetworkHandler.EFFECT_CLAIM_BONUS)
		assert_true(result["ok"] and result["vulnerable"], "a basic-lock vein should read as soft")
		assert_eq(_intel()[site_id]["expiresDay"], day + NetworkHandler.INTEL_DURATION_DAYS, "entry expires N days out")
		assert_eq(_intel()[site_id]["effect"], "claim_bonus", "claim_bonus entry written")
		assert_eq(NetworkHandler.claim_bonus(site_id), NetworkHandler.CLAIM_BONUS_MAGNITUDE, "bonus active on purchase day")

		GameState.state["world"]["day"] = day + NetworkHandler.INTEL_DURATION_DAYS - 1
		NetworkHandler.expire_intel()
		assert_eq(NetworkHandler.claim_bonus(site_id), NetworkHandler.CLAIM_BONUS_MAGNITUDE, "still active the day before expiry")

		GameState.state["world"]["day"] = day + NetworkHandler.INTEL_DURATION_DAYS
		assert_eq(NetworkHandler.claim_bonus(site_id), 0.0, "reads as lapsed on expiresDay even before the prune")
		NetworkHandler.expire_intel()
		assert_true(not (_intel().has(site_id)), "expire_intel prunes the lapsed entry")
	)

	run_case("hard_vein_is_a_paid_for_no", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		var site_id := _seed_firm_vein("fv_hard", "warded")
		var price := NetworkHandler.target_price(site_id)
		var relation_before: int = GameState.state["factions"]["network"]["relation"]
		var result := NetworkHandler.buy_target(site_id, NetworkHandler.EFFECT_CLAIM_BONUS)
		assert_true(result["ok"], "purchase goes through")
		assert_true(not (result["vulnerable"]), "a warded vein is not soft")
		assert_true(not (_intel().has(site_id)), "no entry written for a no")
		assert_eq(GameState.state["player"]["cash"], 100000 - price, "the no is still charged")
		assert_true(price > 0, "priced off VeinTrade.quote()")
		assert_true(GameState.state["factions"]["network"]["relation"] >= relation_before + NetworkHandler.RELATION_GAIN, "every transaction nudges Network relation")
		assert_true(Messages.latest_preview("handler") != "", "the answer lands in the handler thread")
	)

	run_case("target_purchase_feeds_the_network_trade_lane", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		var site_id := _seed_firm_vein("fv_lane", "none")
		var network: Dictionary = GameState.state["factions"]["network"]
		var progress_before: int = network["tradeProgress"]
		var relation_before: int = network["relation"]
		var price := NetworkHandler.target_price(site_id)
		var lane: Dictionary = RelationAccrual.LANES["network"]
		var points: int = mini(lane["dailyCap"], (progress_before + price) / lane["rate"])
		NetworkHandler.buy_target(site_id, NetworkHandler.EFFECT_CLAIM_BONUS)
		assert_eq(network["tradeProgress"], progress_before + price - points * lane["rate"], "price accrues on the network tradeProgress meter")
		assert_eq(network["relation"], relation_before + NetworkHandler.RELATION_GAIN + points, "flat nudge plus lane points")
	)

	run_case("unaffordable_target_charges_nothing", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 0
		var site_id := _seed_firm_vein("fv_broke", "none")
		var result := NetworkHandler.buy_target(site_id, NetworkHandler.EFFECT_CLAIM_BONUS)
		assert_true(not (result["ok"]), "no cash, no answer")
		assert_true(not (_intel().has(site_id)), "nothing written")
	)

	run_case("collective_veins_are_not_targets", func():
		GameState.reset()
		var own := Fixtures.seed_faction_vein("fv_own", 60, "collective")
		assert_true(not (own["siteId"] in NetworkHandler.target_site_ids()), "the Collective's own vein isn't offered")
		assert_true(not (NetworkHandler.buy_target(own["siteId"], NetworkHandler.EFFECT_CLAIM_BONUS)["ok"]), "nor sold")
	)

	run_case("claim_bonus_tilts_player_raid_and_collective_rivalry_only", func():
		GameState.reset()
		var site_id := _seed_firm_vein("fv_tilt", "none")
		var vein: Dictionary = Sites.find_site(site_id)["factionVein"]
		var attempt := { "attackerId": "collective", "defenderId": "firm", "veinSiteId": site_id }
		var guild_attempt := { "attackerId": "guild", "defenderId": "firm", "veinSiteId": site_id }
		var stealth_before := Raiding.stealth_success_chance(1, vein, 0.0)
		var rivalry_before := Factions.rivalry_success_chance(attempt)
		var guild_before := Factions.rivalry_success_chance(guild_attempt)
		NetworkHandler.reveal_vulnerable_vein(site_id, NetworkHandler.EFFECT_CLAIM_BONUS)
		assert_almost_eq(Raiding.stealth_success_chance(1, vein, 0.0), minf(stealth_before + NetworkHandler.CLAIM_BONUS_MAGNITUDE, 1.0), 0.0001, "player raid odds gain the flat bonus")
		assert_almost_eq(Factions.rivalry_success_chance(attempt), minf(rivalry_before + NetworkHandler.CLAIM_BONUS_MAGNITUDE, 1.0), 0.0001, "Collective rivalry odds gain the flat bonus")
		assert_almost_eq(Factions.rivalry_success_chance(guild_attempt), guild_before, 0.0001, "other attackers don't")
	)

	run_case("security_freeze_skips_upgrades_until_it_expires", func():
		GameState.reset()
		for site in GameState.state["world"]["sites"]:
			if site["factionVein"] != null and site["factionVein"]["factionId"] == "firm":
				site["factionVein"]["security"] = "guarded"
		GameState.state["factions"]["firm"]["resources"] = 100000
		var site_id := _seed_firm_vein("fv_freeze", "none")
		assert_true(NetworkHandler.reveal_vulnerable_vein(site_id, NetworkHandler.EFFECT_SECURITY_FREEZE), "an upgradable vein can be frozen")
		assert_true(NetworkHandler.is_security_frozen(site_id), "freeze active")
		Factions.apply_security_upgrades()
		assert_eq(Sites.find_site(site_id)["factionVein"]["security"], "none", "frozen site skipped")

		GameState.state["world"]["day"] += NetworkHandler.INTEL_DURATION_DAYS
		NetworkHandler.expire_intel()
		Factions.apply_security_upgrades()
		assert_eq(Sites.find_site(site_id)["factionVein"]["security"], "basic", "upgrades resume once the freeze lapses")
	)

	run_case("maxed_security_cannot_be_frozen", func():
		GameState.reset()
		var site_id := _seed_firm_vein("fv_max", "guarded")
		assert_true(not (NetworkHandler.reveal_vulnerable_vein(site_id, NetworkHandler.EFFECT_SECURITY_FREEZE)), "nothing left to delay")
		assert_true(not (_intel().has(site_id)), "no entry written")
	)

	run_case("network_reveal_vulnerable_vein_op_reads_site_id_from_effect", func():
		GameState.reset()
		var site_id := _seed_firm_vein("fv_op", "none")
		Events.apply_effects([{ "op": "network_reveal_vulnerable_vein", "site_id": site_id, "effect": "claim_bonus" }])
		assert_true(_intel().has(site_id), "op writes the entry")
	)

	# ── Sourcing ──────────────────────────────────────────────────────────

	run_case("network_reveal_site_reuses_roll_new_site_and_delivers_by_text", func():
		GameState.reset()
		var sites_before: int = GameState.state["world"]["sites"].size()
		Events.apply_effects([{ "op": "network_reveal_site", "oreType": "fate", "minTier": "rich" }])
		var sites: Array = GameState.state["world"]["sites"]
		assert_eq(sites.size(), sites_before + 1, "one site placed")
		var site: Dictionary = sites[-1]
		assert_eq(site["oreType"], "fate", "named ore type")
		assert_true(GameData.SITE_TIER_ORDER.find(site["tier"]) >= GameData.SITE_TIER_ORDER.find("rich"), "at least the named tier")
		var reference := Sites.roll_new_site(site["district"], site["tier"])
		assert_eq(site.keys(), reference.keys(), "same site shape as Sites.roll_new_site()")
		var pending := Messages.pending_for("handler")
		assert_eq(pending.size(), 1, "delivered as a handler pendingMessages entry")
		assert_eq(pending[0]["kind"], NetworkHandler.SOURCING_DELIVERY_EVENT, "delivery event kind")
		assert_eq(pending[0]["payload"]["site_id"], site["id"], "payload names the site")

		var src := FileAccess.get_file_as_string("res://systems/network_handler.gd")
		assert_true(src.contains("Sites.roll_new_site(") and src.contains("Sites.roll_tier("), "rolls through Sites, not its own copy")
		assert_true(not (src.contains("make_site_id")), "never builds a site dict itself")
	)

	run_case("min_tier_holds_across_many_rolls", func():
		GameState.reset()
		for i in range(20):
			var id := NetworkHandler.reveal_site("time", "saturated")
			if id == "":
				break
			assert_eq(Sites.find_site(id)["tier"], "saturated", "never below the named tier")
	)

	run_case("buy_sourcing_charges_quote_price_and_delivery_event_reveals", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		var price := NetworkHandler.sourcing_price("life", "fair")
		var comparable := VeinTrade.quote({ "oreType": "life", "growth": GameData.VEIN_GROWTH["neutral"], "hospitability": { "tier": "fair" } })
		assert_eq(price, comparable, "anchored to VeinTrade.quote() for a comparable vein")
		var result := NetworkHandler.buy_sourcing("life", "fair")
		assert_true(result["ok"], "order placed")
		assert_eq(GameState.state["player"]["cash"], 100000 - price, "charged")
		var entry: Dictionary = Messages.pending_for("handler")[0]
		Messages.resolve_pending(entry["id"])
		EventPlay.play_event(entry["kind"], entry["payload"])
		assert_true(Messages.pending_for("handler").is_empty(), "delivery consumed")
	)

	# ── T12 meet ──────────────────────────────────────────────────────────

	run_case("handler_meet_unlocks_the_handler", func():
		GameState.reset()
		GameState.state["flags"]["colA2SecondLossSeen"] = true
		EventPlay.play_event("col_a2_handler_meet")
		assert_true(GameState.state["flags"].get("networkHandlerUnlocked", false), "flag set")
		assert_true(GameState.state["contacts"]["handler"]["unlocked"], "handler contact unlocked")
		assert_true(Messages.latest_preview("handler") != "", "handler thread opened")
	)
