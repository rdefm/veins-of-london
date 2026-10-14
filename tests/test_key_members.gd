extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const FACTION_IDS := ["collective", "firm", "guild", "network", "conclave"]


func run() -> void:
	run_case("every_faction_has_key_members_a_speaker_gift_prefs_and_two_sample_favours", func():
		GameState.reset()
		for faction_id in FACTION_IDS:
			var members: Array = KeyMembers.members(faction_id)
			assert_true(not members.is_empty(), "%s has key members" % faction_id)
			var speaker := KeyMembers.speaker_for(faction_id)
			assert_true(members.any(func(m): return m["contactId"] == speaker), "%s speaker is one of its members" % faction_id)
			for m in members:
				assert_true(GameState.state["contacts"].has(m["contactId"]), "%s is a contact" % m["contactId"])
				assert_eq(m["giftPrefs"].size(), 2, "%s has two gift prefs" % m["id"])
				for item in m["giftPrefs"]:
					assert_true(GameData.RECIPES.has(item), "%s gift pref %s is a real item" % [m["id"], item])
			assert_true(GameData.FACTIONS[faction_id]["sampleFavours"].size() >= 2, "%s has sample favours" % faction_id)
	)

	run_case("speaker_for_resolves_each_faction_to_its_voice", func():
		GameState.reset()
		assert_eq(KeyMembers.speaker_for("collective"), "nadia")
		assert_eq(KeyMembers.speaker_for("network"), "handler")
		assert_eq(KeyMembers.speaker_for("firm"), "lusk")
		assert_eq(KeyMembers.speaker_for("guild"), "ingram")
		assert_eq(KeyMembers.speaker_for("conclave"), "fairweather")
		assert_eq(KeyMembers.faction_of("hakim"), "collective")
		assert_eq(KeyMembers.faction_of("archie"), "")
	)

	run_case("first_message_unlocks_a_new_key_member_with_their_intro_first", func():
		GameState.reset()
		assert_true(not GameState.state["contacts"]["lusk"]["unlocked"], "locked at start")
		assert_true(not Contacts.directory_ids().has("lusk"), "not in the directory yet")

		assert_true(KeyMembers.send("firm", "A word."), "sent")
		assert_true(GameState.state["contacts"]["lusk"]["unlocked"], "unlocked by the message")
		var thread: Array = GameState.state["messages"]["lusk"]
		assert_eq(thread.size(), 2, "intro then the message")
		assert_eq(thread[0]["text"], KeyMembers.member("lusk")["intro"])
		assert_eq(thread[1]["text"], "A word.")
		assert_eq(Contacts.display_name("lusk"), "Lusk")
		assert_true(Contacts.directory_ids().has("lusk"), "listed once unlocked")

		KeyMembers.send("firm", "Another.")
		assert_eq(GameState.state["messages"]["lusk"].size(), 3, "no second intro")
	)

	run_case("a_kind_queues_an_actionable_pending_message", func():
		GameState.reset()
		KeyMembers.send("conclave", "Call us.", "some_event", { "x": 1 })
		var pending := Messages.pending_for("fairweather")
		assert_eq(pending.size(), 1)
		assert_eq(pending[0]["kind"], "some_event")
		assert_eq(pending[0]["payload"], { "x": 1 })
	)

	run_case("a_quest_gated_speaker_stays_silent_until_its_questline_unlocks_them", func():
		GameState.reset()
		assert_true(not KeyMembers.send("collective", "Numbers."), "Nadia not met yet")
		assert_true(not GameState.state["contacts"]["nadia"]["unlocked"], "still locked")
		assert_true(not GameState.state["messages"].has("nadia"), "nothing sent")

		GameState.state["contacts"]["nadia"]["unlocked"] = true
		assert_true(KeyMembers.send("collective", "Numbers."), "speaks once met")
		assert_eq(GameState.state["messages"]["nadia"].size(), 1, "no intro for an existing contact")
	)

	run_case("directory_ids_is_sorted_by_display_name", func():
		GameState.reset()
		for contact_id in ["des", "handler", "james", "fairweather"]:
			GameState.state["contacts"][contact_id]["unlocked"] = true
		assert_eq(Contacts.directory_ids(), ["archie", "des", "fairweather", "handler", "james"])
	)


	run_case("every_faction_has_a_speaker_and_lieutenant_with_opposing_outlooks", func():
		GameState.reset()
		for faction_id in FACTION_IDS:
			var contenders := KeyMembers.contenders(faction_id)
			assert_eq(contenders.size(), 2, "%s has two contenders" % faction_id)
			assert_eq(contenders[0]["seat"], "speaker")
			assert_eq(contenders[1]["seat"], "lieutenant")
			assert_true(contenders[0]["outlook"] != contenders[1]["outlook"], "%s outlooks oppose" % faction_id)
			for m in contenders:
				assert_true(m["outlook"] in ["hawk", "dove"])
				assert_true(str(m["want"]) != "", "%s has a want" % m["id"])
				assert_true(m.has("aggressionMult") and m.has("relationBaseline"))
			assert_eq(contenders[0]["contactId"], GameData.FACTIONS[faction_id]["speaker"], "speaker leads at start")
		assert_eq(KeyMembers.member("hakim")["seat"], "member")
		assert_eq(KeyMembers.contenders("collective").map(func(m): return m["id"]), ["nadia", "des"])
		for contact_id in ["mercer", "wren", "courier", "pryce"]:
			assert_true(KeyMembers.member(contact_id).get("proseReview", false), "%s flagged" % contact_id)
	)

	run_case("new_game_has_standing_and_leader_and_speaker_follows_the_leader", func():
		GameState.reset()
		var col: Dictionary = GameState.state["factions"]["collective"]
		assert_eq(col["leader"], "nadia")
		assert_eq(col["standing"], { "nadia": 50, "des": 50 })
		col["leader"] = "des"
		assert_eq(KeyMembers.speaker_for("collective"), "des")
		assert_eq(KeyMembers.leader_of("collective"), "des")
	)

	run_case("old_saves_backfill_standing_and_leader_from_the_speaker", func():
		GameState.reset()
		var save := { "factions": { "firm": { "relation": 3 } } }
		SaveManager._migrate_key_member_standing(save)
		assert_eq(save["factions"]["firm"]["leader"], "lusk")
		assert_eq(save["factions"]["firm"]["standing"], { "lusk": 50, "mercer": 50 })
		save["factions"]["firm"]["standing"]["lusk"] = 80
		save["factions"]["firm"]["leader"] = "mercer"
		SaveManager._migrate_key_member_standing(save)
		assert_eq(save["factions"]["firm"]["standing"]["lusk"], 80, "kept")
		assert_eq(save["factions"]["firm"]["leader"], "mercer", "kept")
	)

	run_case("standing_sources_move_by_data_weights_and_clamp", func():
		GameState.reset()
		var w: Dictionary = GameData.FACTION_INCIDENTS["succession"]["weights"]
		KeyMembers.note_favour("mercer", true)
		assert_eq(KeyMembers.standing_of("mercer"), 50 + int(w["favourKept"]))
		KeyMembers.note_favour("mercer", false)
		assert_eq(KeyMembers.standing_of("mercer"), 50)
		KeyMembers.note_quest_step("firm_legitimacy")
		assert_eq(KeyMembers.standing_of("mercer"), 50 + int(w["questStep"]))
		assert_eq(KeyMembers.standing_of("lusk"), 50, "other member untouched")
		KeyMembers.note_player_act("firm", KeyMembers.ACT_HOSTILE)
		assert_eq(KeyMembers.standing_of("lusk"), 50 + int(w["hostileAct"]), "hawk gains")
		assert_eq(KeyMembers.standing_of("mercer"), 50 + int(w["questStep"]) - int(w["hostileAct"]), "dove loses")
		KeyMembers.note_player_act("firm", KeyMembers.ACT_PEACE)
		assert_eq(KeyMembers.standing_of("lusk"), 50 + int(w["hostileAct"]) - int(w["peaceDeal"]))
		KeyMembers.note_war_loss("firm")
		assert_eq(KeyMembers.standing_of("lusk"), 50 + int(w["hostileAct"]) - int(w["peaceDeal"]) + int(w["warLoss"]))
		for i in 20:
			KeyMembers.note_quest_step("firm_legitimacy")
		assert_eq(KeyMembers.standing_of("mercer"), 100, "clamped")
	)

	run_case("player_hostile_act_and_truce_feed_outlook_standing", func():
		GameState.reset()
		FactionAI.note_hostile_act(Shares.PLAYER, "firm")
		assert_true(KeyMembers.standing_of("lusk") > 50 and KeyMembers.standing_of("mercer") < 50)
		var lusk := KeyMembers.standing_of("lusk")
		var mercer := KeyMembers.standing_of("mercer")
		FactionAI.sign_truce(Shares.PLAYER, "firm", {})
		assert_true(KeyMembers.standing_of("lusk") < lusk and KeyMembers.standing_of("mercer") > mercer, "peace deal favours the dove")
	)

	run_case("succession_needs_margin_held_for_days_and_fires_once", func():
		GameState.reset()
		var cfg: Dictionary = GameData.FACTION_INCIDENTS["succession"]
		var firm: Dictionary = GameState.state["factions"]["firm"]
		firm["standing"]["mercer"] = 50 + int(cfg["margin"]) - 1
		for i in int(cfg["days"]) + 2:
			KeyMembers.daily_tick()
		assert_eq(KeyMembers.leader_of("firm"), "lusk", "below margin never fires")
		firm["standing"]["mercer"] = 50 + int(cfg["margin"])
		for i in int(cfg["days"]) - 1:
			KeyMembers.daily_tick()
		assert_eq(KeyMembers.leader_of("firm"), "lusk", "not before N days")
		firm["standing"]["mercer"] = 50
		KeyMembers.daily_tick()
		assert_eq(firm["succession"]["days"], 0, "margin lost resets the count")
		firm["standing"]["mercer"] = 50 + int(cfg["margin"])
		for i in int(cfg["days"]):
			KeyMembers.daily_tick()
		assert_eq(KeyMembers.leader_of("firm"), "mercer")
		assert_eq(KeyMembers.speaker_for("firm"), "mercer", "the Speaker switches")
		assert_eq([firm["succession"]["from"], firm["succession"]["to"]], ["lusk", "mercer"])
		for i in 10:
			KeyMembers.daily_tick()
		assert_eq(KeyMembers.leader_of("firm"), "mercer", "changes once")
		assert_eq(firm["succession"]["days"], 0)
	)

	run_case("succession_queues_the_incident_from_the_new_leader", func():
		GameState.reset()
		GameState.state["world"]["day"] = 20
		var firm: Dictionary = GameState.state["factions"]["firm"]
		firm["standing"]["mercer"] = 90
		firm["succession"]["challenger"] = "mercer"
		firm["succession"]["days"] = int(GameData.FACTION_INCIDENTS["succession"]["days"]) - 1
		KeyMembers.daily_tick()
		FactionIncidents.daily_tick()
		assert_eq(FactionIncidents.queued().size(), 1)
		assert_eq(FactionIncidents.queued()[0]["eventId"], "inc_succession")
		assert_eq(FactionIncidents.queued()[0]["context"]["to"], "mercer")
		assert_eq(GameState.state["pendingMessages"][0]["contactId"], "mercer")
	)

	run_case("new_leader_sets_effective_aggression_and_relation_baseline", func():
		GameState.reset()
		var base := float(GameData.FACTIONS["firm"]["aggressionPersonality"])
		assert_eq(FactionAI.personality("firm"), base, "initial leader leaves it unchanged")
		assert_eq(KeyMembers.baseline_shift("firm"), 0)
		var before := FactionAI.pair_recovery("firm", "guild")
		GameState.state["factions"]["firm"]["leader"] = "mercer"
		assert_true(absf(FactionAI.personality("firm") - base * 0.7 / 1.3) < 0.000001, "dove leader scales it")
		assert_eq(KeyMembers.baseline_shift("firm"), 20)
		assert_true(FactionAI.pair_recovery("firm", "guild") > before, "dove baseline pulls relations up")
	)

	run_case("inside_man_needs_personal_relation_and_an_annoyed_faction", func():
		GameState.reset()
		var at := int(GameData.FACTION_INCIDENTS["personal"]["insideManAt"])
		GameState.state["contacts"]["lusk"]["unlocked"] = true
		GameState.state["contacts"]["lusk"]["relation"] = at
		GameState.state["factions"]["firm"]["relation"] = FactionAI.warning_line("firm")
		assert_eq(KeyMembers.inside_man("firm"), "", "faction not annoyed")
		GameState.state["factions"]["firm"]["relation"] = FactionAI.warning_line("firm") - 1
		assert_eq(KeyMembers.inside_man("firm"), "lusk")
		GameState.state["contacts"]["lusk"]["relation"] = at - 1
		assert_eq(KeyMembers.inside_man("firm"), "", "not close enough")
	)

	run_case("inside_man_reopens_talks_past_the_cooldown", func():
		GameState.reset()
		GameState.state["contacts"]["lusk"]["unlocked"] = true
		GameState.state["contacts"]["lusk"]["relation"] = 100
		GameState.state["factions"]["firm"]["relation"] = -50
		GameState.state["factionWar"]["peaceCooldown"]["firm"] = 99
		GameState.state["factionWar"]["wars"].append({ "parties": [Shares.PLAYER, "firm"], "startDay": 0, "lastHostileDay": 0, "weariness": { Shares.PLAYER: 0.0, "firm": 0.0 } })
		assert_true(FactionAI.can_open_talks("firm")["ok"], "back channel skips the cooldown")
		GameState.state["contacts"]["lusk"]["relation"] = 0
		assert_true(not FactionAI.can_open_talks("firm")["ok"], "cooldown holds without the inside man")
	)

	run_case("inside_man_warns_of_planned_moves_once", func():
		GameState.reset()
		Fixtures.seed_vein("v1", 40, "physics")
		GameState.state["contacts"]["lusk"]["unlocked"] = true
		GameState.state["contacts"]["lusk"]["relation"] = 100
		GameState.state["factions"]["firm"]["relation"] = -80
		GameState.state["factions"]["firm"]["resources"] = 100000
		GameState.state["factionStances"]["player"]["firm"]["stance"] = FactionAI.HOSTILE
		GameState.state["factionEscalation"]["targets"]["firm"] = { "player": { "warnedBand": FactionAI.BAND_RAID, "lastMoveDay": -1 } }
		var plans := FactionAI.planned_moves(7).filter(func(p): return p["factionId"] == "firm" and p["targetId"] == Shares.PLAYER)
		assert_true(not plans.is_empty(), "a move is planned")
		KeyMembers.inside_man_tick()
		var count: int = GameState.state["messages"]["lusk"].size()
		assert_true(count > 0, "warned")
		KeyMembers.inside_man_tick()
		assert_eq(GameState.state["messages"]["lusk"].size(), count, "not repeated within repeatDays")
	)

	run_case("inside_man_leaks_intel_on_their_faction_to_the_player", func():
		GameState.reset()
		GameState.state["contacts"]["lusk"]["unlocked"] = true
		GameState.state["contacts"]["lusk"]["relation"] = 100
		GameState.state["factions"]["firm"]["relation"] = -50
		var cfg: Dictionary = GameData.FACTION_INCIDENTS["personal"]
		var saved: float = cfg["leakChance"]
		cfg["leakChance"] = 1.0
		var before := Intel.meter(Shares.PLAYER, "firm")
		KeyMembers.inside_man_tick()
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), before + int(cfg["leakAmount"]))
		GameState.state["contacts"]["lusk"]["relation"] = 0
		before = Intel.meter(Shares.PLAYER, "firm")
		KeyMembers.inside_man_tick()
		cfg["leakChance"] = saved
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), before, "no leak without an inside man")
	)

	run_case("offer_needs_closeness_a_trailing_contender_and_a_faction_vein", func():
		GameState.reset()
		var at := int(GameData.FACTION_INCIDENTS["personal"]["offerAt"])
		_seed_firm_vein()
		GameState.state["contacts"]["mercer"]["unlocked"] = true
		GameState.state["contacts"]["mercer"]["relation"] = at
		GameState.state["factions"]["firm"]["standing"]["mercer"] = 30
		assert_true(KeyMembers.can_offer("mercer"), "trailing lieutenant, close, vein present")
		GameState.state["contacts"]["mercer"]["relation"] = at - 1
		assert_true(not KeyMembers.can_offer("mercer"), "not close enough")
		GameState.state["contacts"]["mercer"]["relation"] = at
		GameState.state["factions"]["firm"]["standing"]["mercer"] = GameState.state["factions"]["firm"]["standing"]["lusk"]
		assert_true(not KeyMembers.can_offer("mercer"), "not below the leader")
		GameState.state["factions"]["firm"]["standing"]["mercer"] = 10
		GameState.state["contacts"]["lusk"]["unlocked"] = true
		GameState.state["contacts"]["lusk"]["relation"] = at
		assert_true(not KeyMembers.can_offer("lusk"), "the leader never offers")
		GameState.state["contacts"]["mercer"]["unlocked"] = false
		assert_true(not KeyMembers.can_offer("mercer"), "locked")
		GameState.state["contacts"]["mercer"]["unlocked"] = true
		for site in GameState.state["world"]["sites"]:
			site["factionVein"] = null
		assert_true(not KeyMembers.can_offer("mercer"), "no vein to hand over")
	)

	run_case("accepting_an_offer_hands_over_a_vein_and_shifts_relation_and_standing", func():
		GameState.reset()
		var cfg: Dictionary = GameData.FACTION_INCIDENTS["personal"]
		_seed_firm_vein()
		GameState.state["contacts"]["mercer"]["unlocked"] = true
		GameState.state["contacts"]["mercer"]["relation"] = 80
		GameState.state["factions"]["firm"]["relation"] = 0
		GameState.state["factions"]["firm"]["standing"]["mercer"] = 40
		var leader_before := KeyMembers.standing_of("lusk")
		assert_true(KeyMembers.accept_offer("mercer"))
		assert_true(Sites.sites_with_faction_vein("firm").is_empty(), "vein handed over")
		assert_true(not GameState.state["contacts"]["mercer"]["recruited"], "not recruited")
		assert_eq(GameState.state["factions"]["firm"]["relation"], -int(cfg["offerRelationHit"]))
		assert_eq(GameState.state["contacts"]["mercer"]["relation"], 80 + int(cfg["offerPersonalGain"]))
		assert_eq(KeyMembers.standing_of("mercer"), 40 + int(cfg["offerStandingGain"]))
		assert_eq(KeyMembers.standing_of("lusk"), leader_before - int(cfg["offerLeaderLoss"]))
		assert_true(not KeyMembers.accept_offer("mercer"), "no vein left")
	)

	run_case("offer_incident_fires_per_cooldown_and_accepting_plays_the_event_op", func():
		GameState.reset()
		_seed_firm_vein()
		GameState.state["contacts"]["mercer"]["unlocked"] = true
		GameState.state["contacts"]["mercer"]["relation"] = 100
		GameState.state["factions"]["firm"]["standing"]["mercer"] = 30
		FactionIncidents.daily_tick()
		var queued := FactionIncidents.queued().filter(func(q): return q["eventId"] == "inc_secret_offer")
		assert_eq(queued.size(), 1)
		assert_eq(queued[0]["context"]["contact_id"], "mercer")
		assert_eq(Messages.pending_for("mercer").size(), 1, "the member sends the notice")
		FactionIncidents.daily_tick()
		assert_eq(FactionIncidents.queued().filter(func(q): return q["eventId"] == "inc_secret_offer").size(), 1, "cooldown holds")
		var before := Sites.sites_with_faction_vein("firm").size()
		Events.apply_effects([{ "op": "accept_secret_offer" }], queued[0]["context"])
		assert_eq(Sites.sites_with_faction_vein("firm").size(), before - 1, "op ran")
	)


	run_case("offer_prize_follows_member_data_and_falls_back_when_unavailable", func():
		GameState.reset()
		_seed_firm_vein()
		assert_eq(KeyMembers.offer_prize("mercer"), "vein", "default prize is a vein")
		GameState.state["factions"]["collective"]["stockpile"]["district"] = ""
		assert_eq(KeyMembers.offer_prize("des"), "goods", "no stockpile to tip about; goods next")
		var held: Dictionary = GameState.state["factions"]["collective"]["holdings"].duplicate(true)
		GameState.state["factions"]["collective"]["stockpile"]["district"] = "hackney"
		assert_eq(KeyMembers.offer_prize("des"), "tip")
		GameState.state["factions"]["collective"]["holdings"] = held
		GameState.state["intel"][Shares.PLAYER]["collective"] = Intel.level_at(Intel.STOCKPILE_LOCATION)
		assert_eq(KeyMembers.offer_prize("des"), "goods", "location already known")
		for ore_type in GameState.state["factions"]["collective"]["holdings"]["ore"].keys():
			GameState.state["factions"]["collective"]["holdings"]["ore"][ore_type] = 0
		GameState.state["factions"]["collective"]["holdings"]["items"] = {}
		assert_eq(KeyMembers.offer_prize("des"), "", "nothing left, no vein")
	)

	run_case("goods_offer_moves_holdings_share_to_the_player", func():
		GameState.reset()
		_open_offer("des")
		GameState.state["factions"]["collective"]["stockpile"]["district"] = "hackney"
		GameState.state["intel"][Shares.PLAYER]["collective"] = Intel.level_at(Intel.STOCKPILE_LOCATION)
		GameState.state["factions"]["collective"]["holdings"]["ore"] = { "life": 40 }
		GameState.state["factions"]["collective"]["holdings"]["items"] = {}
		var share := float(GameData.FACTION_INCIDENTS["personal"]["offerGoodsShare"])
		var life_before := int(GameState.state["player"]["orichalchum"].get("life", 0))
		assert_true(KeyMembers.accept_offer("des"))
		assert_eq(FactionSim.ore_held("collective", "life"), 40 - floori(40.0 * share))
		assert_eq(int(GameState.state["player"]["orichalchum"]["life"]), life_before + floori(40.0 * share))
	)

	run_case("grateful_leader_tempers_aggression_stacks_decays_and_hostile_acts_cancel", func():
		GameState.reset()
		_seed_firm_vein()
		var f: Dictionary = GameState.state["factions"]["firm"]
		f["gratitude"] = { "mercer": 1.0 }
		assert_eq(KeyMembers.gratitude_scale("firm"), 1.0, "not leading: no effect")
		f["leader"] = "mercer"
		var one := KeyMembers.gratitude_scale("firm")
		assert_eq(one, float(GameData.FACTION_INCIDENTS["personal"]["gratitudeMult"]))
		f["gratitude"]["mercer"] = 2.0
		assert_true(KeyMembers.gratitude_scale("firm") < one, "stacks")
		KeyMembers.daily_tick()
		assert_true(float(f["gratitude"]["mercer"]) < 2.0, "decays")
		KeyMembers.note_player_act("firm", KeyMembers.ACT_HOSTILE)
		assert_eq(KeyMembers.gratitude_scale("firm"), 1.0, "hostile act cancels")
	)

	run_case("accepting_offers_counts_per_instigator", func():
		GameState.reset()
		_open_offer("des")
		GameState.state["factions"]["collective"]["stockpile"]["district"] = "hackney"
		assert_true(KeyMembers.accept_offer("des"))
		assert_eq(GameState.state["factions"]["collective"]["gratitude"]["des"], 1.0)
	)

	run_case("tip_offer_reveals_the_stockpile_for_the_existing_raid", func():
		GameState.reset()
		_open_offer("des")
		GameState.state["factions"]["collective"]["stockpile"]["district"] = "hackney"
		assert_true(not Raiding.can_raid_stockpile("collective"))
		assert_true(KeyMembers.accept_offer("des"))
		assert_true(Raiding.can_raid_stockpile("collective"), "raidable now")
		assert_eq(KeyMembers.offer_prize("des"), "goods", "tip spent; falls to next kind")
	)

# One firm vein on a single fixture site.
static func _seed_firm_vein() -> void:
	var vein := {
		"id": "fv_test", "factionId": "firm", "oreType": "physics", "growth": 10,
		"rampantDays": 0, "security": "none", "alarmUpgrades": [], "claimedOnDay": 1,
		"district": "shoreditch", "siteId": "test_site", "level": 3, "developmentStreak": 0,
		"hospitability": { "tier": "fair", "bonuses": [] },
	}
	GameState.state["world"]["sites"] = [Fixtures.site_with_vein("test_site", vein)]


static func _open_offer(contact_id: String) -> void:
	GameState.state["contacts"][contact_id]["unlocked"] = true
	GameState.state["contacts"][contact_id]["relation"] = 100
	var faction_id := KeyMembers.faction_of(contact_id)
	GameState.state["factions"][faction_id]["standing"][contact_id] = 10
