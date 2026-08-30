extends "res://tests/test_base.gd"


func run() -> void:
	run_case("raid_chance_floors_at_0_002", func():
		GameState.reset()
		# bedsit raidBaseChance is 0.08, but stack heavy reduction to push
		# the raw formula well below the floor.
		GameState.state["home"]["security"] = ["lock", "cameras", "reinforcedDoor", "alarm", "guard", "ward"]
		var chance := Home.get_home_raid_chance()
		assert_almost_eq(chance, 0.002, 0.0001, "raid chance should floor at 0.002, never go negative")
	)

	run_case("raid_chance_uses_tier_base_security_and_carried_ore", func():
		GameState.reset()
		# M1-LONDON-T06: home.storedOre was merged into player.orichalchum —
		# carried ore is what a raid is risking now, there's no separate pool.
		GameState.state["player"]["orichalchum"] = { "time": 50 }
		# bedsit base 0.08, no security, +50*0.001 = 0.05 -> 0.13
		var chance := Home.get_home_raid_chance()
		assert_almost_eq(chance, 0.13, 0.0001, "0.08 base + 50*0.001 carried ore")
	)

	run_case("raid_spacing_skips_within_3_days", func():
		GameState.reset()
		GameState.state["world"]["day"] = 5
		GameState.state["home"]["lastRaidDay"] = 4
		GameState.state["player"]["orichalchum"] = { "time": 100 }
		Rng.set_seed(1)  # irrelevant — should bail before rolling
		Home.roll_daily_raid()
		assert_eq(GameState.state["home"]["lastRaidDay"], 4, "day 5 - lastRaidDay 4 < 3, should skip entirely")
	)

	run_case("raid_with_no_carried_ore_updates_lastRaidDay_but_loots_nothing", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		GameState.state["home"]["lastRaidDay"] = 0
		GameState.state["home"]["tier"] = "bedsit"
		# raidBaseChance for bedsit alone is 0.08, but force certainty via a
		# huge stored-ore-derived chance is not possible with empty ore, so
		# instead push chance toward 1 by relying on high base + fx isn't
		# available here; test the "no ore" branch directly by forcing the
		# roll through repeated seeds until it hits, bounded.
		var hit := false
		for seed in range(200):
			GameState.state["home"]["lastRaidDay"] = 0
			Rng.set_seed(seed)
			Home.roll_daily_raid()
			if GameState.state["home"]["lastRaidDay"] == 10:
				hit = true
				break
		assert_true(hit, "a raid should eventually hit across 200 seeds at bedsit's 0.08 base chance")
		assert_eq(GameState.state["player"]["orichalchum"], {}, "no carried ore to lose")
	)

	run_case("raid_loss_ratio_is_halved_by_safeRoom", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		GameState.state["home"]["lastRaidDay"] = 0
		GameState.state["player"]["orichalchum"] = { "time": 100 }
		GameState.state["home"]["rooms"] = ["safeRoom"]

		var seed := -1
		for candidate in range(300):
			var snapshot: Dictionary = GameState.deep_copy(GameState.state)
			Rng.set_seed(candidate)
			Home.roll_daily_raid()
			if GameState.state["home"]["lastRaidDay"] == 10:
				seed = candidate
				break
			GameState.state = snapshot

		assert_true(seed != -1, "should find a seed that triggers the raid within 300 tries")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 75, "floor(100*0.25) = 25 lost, 75 remain, with safeRoom")
	)

	run_case("raid_loss_ratio_is_full_without_safeRoom", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		GameState.state["home"]["lastRaidDay"] = 0
		GameState.state["player"]["orichalchum"] = { "time": 100 }

		var seed := -1
		for candidate in range(300):
			var snapshot: Dictionary = GameState.deep_copy(GameState.state)
			Rng.set_seed(candidate)
			Home.roll_daily_raid()
			if GameState.state["home"]["lastRaidDay"] == 10:
				seed = candidate
				break
			GameState.state = snapshot

		assert_true(seed != -1, "should find a seed that triggers the raid within 300 tries")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 50, "floor(100*0.50) = 50 lost, 50 remain, no safeRoom")
	)

	# ── 106-hq-raid-alarm-defend-flow ─────────────────────────────────────

	run_case("alarmed_hq_raid_queues_instead_of_resolving_immediately", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		GameState.state["home"]["lastRaidDay"] = 0
		GameState.state["home"]["security"] = ["alarm"]
		GameState.state["player"]["orichalchum"] = { "time": 100 }

		var seed := -1
		for candidate in range(300):
			var snapshot: Dictionary = GameState.deep_copy(GameState.state)
			Rng.set_seed(candidate)
			Home.roll_daily_raid()
			if GameState.state["home"]["lastRaidDay"] == 10:
				seed = candidate
				break
			GameState.state = snapshot

		assert_true(seed != -1, "should find a seed that triggers the raid within 300 tries")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 100, "an alarmed raid must not touch ore immediately -- it queues instead")
		assert_true(GameState.state["home"]["pendingRaid"], "a successful alarmed raid attempt must queue")

		var notifications: Array = GameState.state["notifications"]
		assert_eq(notifications.size(), 1, "queuing must push exactly one warning")
		assert_eq(notifications[0]["category"], Notify.CATEGORY_WARNING)
		assert_eq(notifications[0]["homeRaid"], true, "the warning must carry homeRaid meta for the Notifications app's Defend button")
		assert_eq(GameState.state["home"]["pendingRaidNotificationId"], notifications[0]["id"])
	)

	run_case("unalarmed_hq_raid_still_auto_resolves_with_no_pending_raid_queued", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		GameState.state["home"]["lastRaidDay"] = 0
		GameState.state["player"]["orichalchum"] = { "time": 100 }

		var seed := -1
		for candidate in range(300):
			var snapshot: Dictionary = GameState.deep_copy(GameState.state)
			Rng.set_seed(candidate)
			Home.roll_daily_raid()
			if GameState.state["home"]["lastRaidDay"] == 10:
				seed = candidate
				break
			GameState.state = snapshot

		assert_true(seed != -1, "should find a seed that triggers the raid within 300 tries")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 50, "no alarm installed -- resolves exactly as before (floor(100*0.50) lost)")
		assert_true(not GameState.state["home"]["pendingRaid"], "no alarm installed -- nothing should queue")
	)

	run_case("missed_defend_window_resolves_the_pending_raid_as_a_loss_on_the_next_tick", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		# Spacing gate blocks any *new* attempt this call (0 < 3) -- isolates
		# the expiry side of roll_daily_raid() from the fresh-roll side.
		GameState.state["home"]["lastRaidDay"] = 10
		GameState.state["home"]["security"] = ["alarm"]
		GameState.state["home"]["pendingRaid"] = true
		GameState.state["home"]["pendingRaidNotificationId"] = "n_stale"
		GameState.state["player"]["orichalchum"] = { "time": 100 }

		Home.roll_daily_raid()

		assert_eq(GameState.state["player"]["orichalchum"]["time"], 50, "a missed defend window resolves as a loss, same ratio as the no-alarm path (floor(100*0.50))")
		assert_true(not GameState.state["home"]["pendingRaid"], "the pending raid must be cleared once resolved")
		assert_eq(GameState.state["home"]["pendingRaidNotificationId"], null)
	)

	run_case("has_pending_raid_and_is_pending_raid_notification_reflect_the_queued_flag", func():
		GameState.reset()
		assert_true(not Home.has_pending_raid(), "sanity: nothing pending on a fresh game")

		GameState.state["home"]["pendingRaid"] = true
		GameState.state["home"]["pendingRaidNotificationId"] = "n1"
		assert_true(Home.has_pending_raid())
		assert_true(Home.is_pending_raid_notification("n1"))
		assert_true(not Home.is_pending_raid_notification("n2"), "a different notification id must not match")
	)

	run_case("trigger_defend_pops_the_pending_flag_and_starts_home_raid_combat", func():
		GameState.reset()
		GameState.state["home"]["pendingRaid"] = true
		GameState.state["home"]["pendingRaidNotificationId"] = "n1"

		var started := Home.trigger_defend()

		assert_true(started, "trigger_defend should report it started combat")
		assert_true(GameState.state["combat"]["active"], "tapping Defend must start combat immediately")
		assert_eq(GameState.state["combat"]["context"], "home_raid")
		assert_true(not GameState.state["home"]["pendingRaid"], "the pending raid must be popped from the queue")
		assert_eq(GameState.state["home"]["pendingRaidNotificationId"], null)
	)

	run_case("trigger_defend_is_a_no_op_when_nothing_is_pending", func():
		GameState.reset()
		var started := Home.trigger_defend()
		assert_true(not started, "trigger_defend should report false when there's nothing to defend")
		assert_true(not GameState.state["combat"]["active"], "no combat should start")
	)

	run_case("upgrade_tier_enforces_cash_and_advances_the_ladder", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100
		var poor_result := Home.upgrade_tier()
		assert_true(not poor_result["ok"], "should fail without enough cash")
		assert_eq(GameState.state["home"]["tier"], "bedsit", "tier unchanged on failed upgrade")

		GameState.state["player"]["cash"] = 5000
		var result := Home.upgrade_tier()
		assert_true(result["ok"], "flat costs 1200, should succeed with 5000 cash")
		assert_eq(GameState.state["home"]["tier"], "flat", "tier advances to flat")
		assert_eq(GameState.state["player"]["cash"], 5000 - 1200, "upgradeCost deducted")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "the failed attempt records nothing, only the successful upgrade records a bank transaction")
		assert_eq(bank_log[0]["amount"], -1200, "the recorded amount matches the upgrade cost")
	)

	run_case("add_security_enforces_minTier", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		# bedsit tier: lock's minTier is bedsit, guard's minTier is compound
		var lock_result := Home.add_security("lock")
		assert_true(lock_result["ok"], "bedsit-tier player should be able to install lock")
		var guard_result := Home.add_security("guard")
		assert_true(not guard_result["ok"], "bedsit-tier player should not be able to install guard (requires compound)")
		assert_eq(GameState.state["home"]["security"], ["lock"], "guard should not have been added")
	)

	run_case("add_security_no_count_cap_at_top_tier", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "compound"
		for security_id in GameData.HOME_SECURITY.keys():
			var result := Home.add_security(security_id)
			assert_true(result["ok"], "compound-tier player should be able to install %s with no count-based block" % security_id)
		assert_eq(GameState.state["home"]["security"].size(), GameData.HOME_SECURITY.size(), "all security upgrades should be installed")
	)

	run_case("add_security_applies_securityContactUnlocked_discount", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "safehouse"  # plenty of slots
		GameState.state["flags"]["securityContactUnlocked"] = true
		Home.add_security("ward")
		# ward costs 2000, discounted 2000*0.7 = 1400
		assert_eq(GameState.state["player"]["cash"], 100000 - 1400, "securityContactUnlocked should apply the 0.7x discount")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log[bank_log.size() - 1]["amount"], -1400, "the recorded amount matches the discounted cost, not the sticker cost")
	)

	run_case("add_room_enforces_minTier", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		# bedsit can't build workshop (requires flat+; also 0 room slots)
		var result := Home.add_room("workshop")
		assert_true(not result["ok"], "workshop requires flat tier, bedsit has 0 room slots and wrong tier")
	)

	run_case("add_room_enforces_minTier_even_with_a_free_slot", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"  # 1 free room slot, but below library's townhouse minTier
		var result := Home.add_room("library")
		assert_true(not result["ok"], "library requires townhouse+, flat has a free slot but wrong tier")
		assert_eq(GameState.state["home"]["rooms"], [], "no room should have been added")
	)

	run_case("add_room_body_bonus_applies_immediately", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "flat"
		GameState.state["player"]["hp"] = 95
		GameState.state["player"]["hpMax"] = 100
		Home.add_room("homeGym")
		assert_eq(GameState.state["player"]["hpMax"], 110, "homeGym grants +10 hpMax immediately")
		assert_eq(GameState.state["player"]["hp"], 105, "hp also gains 10 (95+10), within the new 110 cap")

		var bank_log: Array = GameState.state["bankLog"]
		assert_eq(bank_log.size(), 1, "building a room records one bank transaction")
		assert_eq(bank_log[0]["amount"], -GameData.HOME_ROOMS["homeGym"]["cost"], "the recorded amount matches the room's cost")
	)

	run_case("workshop_bonus_sums_installed_crafting_rooms", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "townhouse"
		GameState.state["home"]["rooms"] = ["workshop", "library"]
		var bonus := Home.get_workshop_bonus()
		assert_almost_eq(bonus, 0.16, 0.0001, "workshop 0.08 + library 0.08")
	)

	run_case("known_approaches_always_include_start_approaches_with_no_rooms", func():
		GameState.reset()
		GameState.state["home"]["rooms"] = []
		var known := Approaches.get_known()
		assert_true(known.has("heat"), "heat is start-known")
		assert_true(known.has("grinding"), "grinding is start-known")
		assert_true(not known.has("compression"), "compression requires workshop, not owned")
		assert_true(not known.has("distilling"), "distilling requires lab, not owned")
	)

	run_case("known_approaches_unlock_via_room_ownership", func():
		GameState.reset()
		GameState.state["home"]["rooms"] = ["workshop"]
		var known := Approaches.get_known()
		assert_true(known.has("compression"), "workshop owned -> compression known")
		assert_true(not known.has("distilling"), "lab not owned -> distilling still locked")

		GameState.state["home"]["rooms"] = ["workshop", "lab"]
		known = Approaches.get_known()
		assert_true(known.has("compression"), "workshop still owned -> compression known")
		assert_true(known.has("distilling"), "lab owned -> distilling known")
	)

	run_case("is_known_matches_get_known", func():
		GameState.reset()
		GameState.state["home"]["rooms"] = ["lab"]
		assert_true(Approaches.is_known("heat"), "heat always known")
		assert_true(Approaches.is_known("distilling"), "lab owned -> distilling known")
		assert_true(not Approaches.is_known("compression"), "workshop not owned -> compression locked")
	)
