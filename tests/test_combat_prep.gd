extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# Every combat entry path parks in state.combatPrep before any cost, roll or
# first turn; Fight commits, Cancel (planned only) restores.


static func _faction_vein() -> Dictionary:
	return {
		"id": "fv_test", "factionId": "firm", "oreType": "physics", "growth": 30,
		"security": "warded", "alarmUpgrades": [],
		"location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch",
		"siteId": "s_test", "hospitability": { "tier": "fair", "bonuses": [] },
		"rampantDays": 0,
	}


static func _player_vein() -> Dictionary:
	return Fixtures.player_vein("pv_test", "s_player", "shoreditch", "life", 30, "fair")


func run() -> void:
	run_case("vein_raid_prepares_without_spending_then_cancel_restores", func():
		GameState.reset()
		var vein := _faction_vein()
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein(vein["siteId"], vein)]
		GameState.state["currentScreen"] = "map"
		var district_before: String = GameState.state["world"]["currentDistrict"]

		assert_true(Raiding.prepare_raid(vein, ["archie"])["ok"])
		assert_eq(GameState.state["currentScreen"], CombatPrep.SCREEN)
		assert_eq(GameState.state["combatPrep"]["kind"], CombatPrep.KIND_VEIN_RAID)
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0, "no block spent in prep")
		assert_eq(GameState.state["event"], null, "no raid event / stealth roll in prep")
		assert_true(not GameState.state["combat"]["active"])

		assert_true(CombatPrep.cancel())
		assert_eq(GameState.state["combatPrep"], null)
		assert_eq(GameState.state["currentScreen"], "map")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0)
		assert_eq(GameState.state["world"]["currentDistrict"], district_before, "cancel leaves the district alone")
	)

	run_case("vein_raid_fight_spends_the_block_and_starts_the_raid_event", func():
		GameState.reset()
		var vein := _faction_vein()
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein(vein["siteId"], vein)]
		Contacts.force_recruit("archie")
		GameState.state["contacts"]["archie"]["relation"] = 100
		Raiding.prepare_raid(vein, ["archie"])

		var result := CombatPrep.commit()

		assert_true(result["ok"])
		assert_eq(GameState.state["combatPrep"], null)
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1)
		assert_eq(GameState.state["event"]["eventId"], Raiding.RAID_EVENT_ID)
		assert_eq(GameState.state["event"]["context"]["ally_ids"], ["archie"])
	)

	run_case("prepare_raid_refuses_without_blocks", func():
		GameState.reset()
		var vein := _faction_vein()
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein(vein["siteId"], vein)]
		for i in range(TimeSystem.BLOCKS_PER_DAY):
			GameState.state["world"]["timeBlocksDone"].append("b%d" % i)
		assert_true(not Raiding.prepare_raid(vein)["ok"])
		assert_eq(GameState.state["combatPrep"], null)
	)

	run_case("stockpile_raid_prepares_then_fight_starts_the_event", func():
		GameState.reset()
		GameState.state["intel"][Shares.PLAYER]["firm"] = Intel.level_at(Intel.STOCKPILE_LOCATION)
		assert_true(Raiding.prepare_stockpile_raid("firm")["ok"])
		assert_eq(GameState.state["combatPrep"]["kind"], CombatPrep.KIND_STOCKPILE_RAID)
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0)
		assert_eq(GameState.state["event"], null)

		assert_true(CombatPrep.commit()["ok"])
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1)
		assert_eq(GameState.state["event"]["eventId"], Raiding.STOCKPILE_RAID_EVENT_ID)
	)

	run_case("vein_defend_keeps_the_raid_queued_until_fight", func():
		GameState.reset()
		var vein := _player_vein()
		vein["alarmUpgrades"] = ["alarm"]
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }]

		assert_true(Raiding.prepare_defend("pv_test"))
		assert_eq(GameState.state["currentScreen"], CombatPrep.SCREEN)
		assert_eq(GameState.state["world"]["pendingDefendRaids"].size(), 1, "raid still queued in prep")
		assert_true(not GameState.state["combat"]["active"])

		assert_true(CombatPrep.cancel())
		assert_eq(GameState.state["world"]["pendingDefendRaids"].size(), 1, "cancel leaves it queued")

		Raiding.prepare_defend("pv_test")
		assert_true(CombatPrep.commit()["ok"])
		assert_eq(GameState.state["world"]["pendingDefendRaids"].size(), 0)
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_DEFEND_VEIN)
		assert_eq(GameState.state["currentScreen"], "combat")
	)

	run_case("arrival_defend_prepares_instead_of_starting_combat", func():
		GameState.reset()
		var vein := _player_vein()
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }]

		assert_true(Raiding.maybe_prepare_defend("shoreditch"))
		assert_eq(GameState.state["combatPrep"]["kind"], CombatPrep.KIND_VEIN_DEFEND)
		assert_true(not GameState.state["combat"]["active"])
		assert_true(not Raiding.maybe_prepare_defend("elsewhere"))
	)

	run_case("hq_defend_prepares_and_fight_clears_the_pending_raid", func():
		GameState.reset()
		assert_true(not Home.prepare_defend(), "nothing pending")
		GameState.state["home"]["pendingRaid"] = true
		assert_true(Home.prepare_defend())
		assert_true(GameState.state["home"]["pendingRaid"], "still pending in prep")
		assert_true(not GameState.state["combat"]["active"])

		assert_true(CombatPrep.commit()["ok"])
		assert_true(not GameState.state["home"]["pendingRaid"])
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_HOME_ALARM_DEFEND)
	)

	run_case("forced_encounters_have_no_cancel_and_commit_to_combat", func():
		var cases := {
			CombatPrep.KIND_MUGGING: Combat.CONTEXT_MUGGING,
			CombatPrep.KIND_ARCHIE_DEAL_MUGGING: Combat.CONTEXT_ARCHIE_DEAL_MUGGING,
			CombatPrep.KIND_STREET_MUGGING: Combat.CONTEXT_EVENT_MUGGING,
			CombatPrep.KIND_HOME_RAID: Combat.CONTEXT_HOME_RAID,
		}
		for kind in cases.keys():
			GameState.reset()
			CombatPrep.request(kind)
			assert_true(GameState.state["combatPrep"]["forced"], kind)
			assert_true(not GameState.state["combat"]["active"], "%s: no fight before Fight" % kind)
			assert_true(not CombatPrep.cancel(), "%s: no cancel route" % kind)
			assert_eq(GameState.state["currentScreen"], CombatPrep.SCREEN)
			assert_true(CombatPrep.commit()["ok"])
			assert_eq(GameState.state["combat"]["context"], cases[kind], kind)
	)

	run_case("mugged_sale_keeps_its_cut_pending_through_prep", func():
		GameState.reset()
		GameState.state["pendingSaleCut"] = 40
		CombatPrep.request(CombatPrep.KIND_MUGGING, { "veinIncluded": false })
		assert_eq(GameState.state["pendingSaleCut"], 40, "consequence stands")
		assert_true(not CombatPrep.cancel())
	)

	run_case("debug_fight_prepares_and_cancels_free", func():
		GameState.reset()
		CombatPrep.request(CombatPrep.KIND_DEBUG, {
			"context": Combat.CONTEXT_RAID, "locationKey": "", "valueTier": 1,
			"guards": 1, "templateKey": "", "allyIds": [],
		})
		assert_true(not GameState.state["combatPrep"]["forced"])
		assert_true(CombatPrep.cancel())
		assert_true(not GameState.state["combat"]["active"])

		CombatPrep.request(CombatPrep.KIND_DEBUG, {
			"context": Combat.CONTEXT_RAID, "locationKey": "", "valueTier": 1,
			"guards": 1, "templateKey": "", "allyIds": [],
		})
		assert_true(CombatPrep.commit()["ok"])
		assert_true(GameState.state["combat"]["active"])
	)

	run_case("participants_list_you_with_equipped_units_allies_and_foe", func():
		GameState.reset()
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "rewind", "tier": 2 }
		Contacts.force_recruit("archie")
		CombatPrep.request(CombatPrep.KIND_MUGGING)
		var rows := CombatPrep.participants(CombatPrep.pending())

		assert_eq(rows[0]["role"], "you")
		assert_eq(rows[0]["units"], [{ "recipe": "rewind", "tier": 2 }])
		assert_eq(rows[1]["name"], "Archie")
		assert_eq(rows[1]["role"], "ally")
		assert_eq(rows[rows.size() - 1]["role"], "foe")
	)

	run_case("loadout_warning_names_participants_with_empty_slot_and_stock_only", func():
		GameState.reset()
		Contacts.force_recruit("archie")
		CombatPrep.request(CombatPrep.KIND_MUGGING)
		assert_eq(CombatPrep.loadout_warning_names(CombatPrep.pending()), [], "no stock -> no warning")

		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var names := CombatPrep.loadout_warning_names(CombatPrep.pending())
		assert_true(names.has("You"), "player empty slot + stock")

		for i in range(Loadout.slot_count()):
			GameState.state["player"]["loadout"]["slots"][i] = { "recipe": "rewind", "tier": 1 }
		assert_true(not CombatPrep.loadout_warning_names(CombatPrep.pending()).has("You"), "full slots -> no player warning")
	)

	run_case("change_loadout_round_trips_to_the_same_pending_encounter_uncommitted", func():
		GameState.reset()
		GameState.state["currentScreen"] = "map"
		CombatPrep.request(CombatPrep.KIND_MUGGING)
		var before: Dictionary = GameState.state["combatPrep"].duplicate(true)
		assert_true(CombatPrep.change_loadout())
		assert_true(CombatPrep.is_editing_loadout())
		assert_eq(GameState.state["currentScreen"], "phone")
		assert_eq(GameState.state["phoneNav"]["app"], "profile")
		assert_true(not GameState.state["combat"]["active"], "nothing committed")

		CombatPrep.finish_loadout_edit()
		assert_true(not CombatPrep.is_editing_loadout())
		assert_eq(GameState.state["currentScreen"], CombatPrep.SCREEN)
		assert_eq(GameState.state["combatPrep"], before, "same pending encounter")
	)

	run_case("recruit_pool_offers_only_eligible_combat_recruits", func():
		GameState.reset()
		for id in ["archie", "james"]:
			Contacts.force_recruit(id)
			GameState.state["contacts"][id]["relation"] = 100
		assert_eq(CombatPrep.recruit_pool(CombatPrep.KIND_VEIN_DEFEND).size(), 2)
		GameState.state["contacts"]["archie"]["koCooldownUntilDay"] = GameState.state["world"]["day"] + 3
		assert_eq(CombatPrep.recruit_pool(CombatPrep.KIND_VEIN_DEFEND), ["james"], "KO cooldown hides archie")
		assert_eq(CombatPrep.recruit_pool(CombatPrep.KIND_MUGGING), [], "scripted fights offer no choice")
		assert_eq(CombatPrep.recruit_pool(CombatPrep.KIND_DEBUG), [])
	)

	run_case("raid_recruits_toggle_and_reorder_then_fight_in_that_order", func():
		GameState.reset()
		for id in ["archie", "james"]:
			Contacts.force_recruit(id)
			GameState.state["contacts"][id]["relation"] = 100
		var vein := _faction_vein()
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein(vein["siteId"], vein)]
		Raiding.prepare_raid(vein)
		assert_eq(CombatPrep.chosen_recruits(CombatPrep.KIND_VEIN_RAID, CombatPrep.pending()["args"]), [], "raids start with nobody chosen")

		assert_true(CombatPrep.toggle_recruit("archie"))
		assert_true(CombatPrep.toggle_recruit("james"))
		assert_true(CombatPrep.move_recruit("james", -1))
		assert_true(not CombatPrep.move_recruit("james", -1), "already first")
		assert_eq(CombatPrep.pending()["args"]["allyIds"], ["james", "archie"])
		assert_true(CombatPrep.toggle_recruit("archie"))
		assert_true(CombatPrep.toggle_recruit("archie"))
		assert_eq(CombatPrep.pending()["args"]["allyIds"], ["james", "archie"], "re-added recruit goes last")

		CombatPrep.commit()
		assert_eq(GameState.state["event"]["context"]["ally_ids"], ["james", "archie"])
	)

	run_case("vein_defend_orders_recruits_then_partners_then_guards", func():
		GameState.reset()
		for id in ["archie", "james"]:
			Contacts.force_recruit(id)
		var vein := _player_vein()
		vein["alarmUpgrades"] = ["alarm"]
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }]
		Raiding.prepare_defend("pv_test")
		assert_eq(CombatPrep.pending()["args"]["allyIds"].size(), 2, "defence opens with every eligible recruit")
		CombatPrep.toggle_recruit("archie")
		CombatPrep.toggle_recruit("archie")
		assert_eq(CombatPrep.pending()["args"]["allyIds"], ["james", "archie"])

		CombatPrep.commit()
		var combat: Dictionary = GameState.state["combat"]
		var names: Array = []
		for ally in combat["allies"] + combat["allyQueue"]:
			names.append(ally["name"])
		assert_eq(names.slice(0, 2), ["James", "Archie"])
	)

	run_case("hq_defend_takes_chosen_recruits_and_unchosen_stay_home", func():
		GameState.reset()
		for id in ["archie", "james"]:
			Contacts.force_recruit(id)
		GameState.state["home"]["pendingRaid"] = true
		Home.prepare_defend()
		CombatPrep.toggle_recruit("archie")
		CombatPrep.commit()
		var combat: Dictionary = GameState.state["combat"]
		var ids: Array = []
		for ally in combat["allies"] + combat["allyQueue"]:
			ids.append(ally.get("contactId", ""))
		assert_eq(ids, ["james"])
	)

	run_case("a_recruit_who_goes_ineligible_in_prep_is_dropped_at_fight", func():
		GameState.reset()
		Contacts.force_recruit("james")
		GameState.state["home"]["pendingRaid"] = true
		Home.prepare_defend()
		GameState.state["contacts"]["james"]["koCooldownUntilDay"] = GameState.state["world"]["day"] + 2
		assert_eq(CombatPrep.recruit_options(CombatPrep.pending()), [])
		CombatPrep.commit()
		assert_eq(GameState.state["combat"]["allies"].size(), 0)
	)

	run_case("mugging_roster_ignores_recruit_choice", func():
		GameState.reset()
		Contacts.force_recruit("james")
		CombatPrep.request(CombatPrep.KIND_MUGGING)
		assert_true(not CombatPrep.toggle_recruit("james"))
		assert_eq(CombatPrep.recruit_options(CombatPrep.pending()), [])
	)

	run_case("pending_prep_round_trips_save_load", func():
		GameState.reset()
		CombatPrep.request(CombatPrep.KIND_MUGGING, { "veinIncluded": true })
		var saved: Dictionary = JSON.parse_string(JSON.stringify(GameState.state))
		var restored: Dictionary = SaveManager.backfill_defaults(saved)

		assert_eq(restored["combatPrep"]["kind"], CombatPrep.KIND_MUGGING)
		assert_eq(restored["combatPrep"]["args"]["veinIncluded"], true)
		assert_eq(restored["combatPrep"]["forced"], true)
		assert_eq(restored["currentScreen"], CombatPrep.SCREEN)
	)

	run_case("old_saves_without_combat_prep_load_clean", func():
		GameState.reset()
		var saved: Dictionary = GameState.state.duplicate(true)
		saved.erase("combatPrep")
		assert_eq(SaveManager.backfill_defaults(saved)["combatPrep"], null)
	)
