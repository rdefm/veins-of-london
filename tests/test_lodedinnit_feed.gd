extends "res://tests/test_base.gd"


func run() -> void:
	run_case("no_posts_until_app_unlocks", func():
		GameState.reset()
		TimeSystem.run_staff_block()
		assert_eq(GameState.state["hiring"]["feed"].size(), 0)
	)

	run_case("one_post_per_block_with_rolled_likes_and_comments", func():
		_setup()
		for i in 5:
			TimeSystem.run_staff_block()
		var feed: Array = GameState.state["hiring"]["feed"]
		assert_eq(feed.size(), 5)
		for entry in feed:
			assert_eq(entry["authorKind"], "individual")
			assert_true(int(entry["likes"]) >= 2 and int(entry["likes"]) <= 40, "likes in range")
			assert_true(entry["comments"].size() <= 2, "0-2 comments")
			for ref in entry["comments"]:
				assert_true(String(ref).split(":")[0] != entry["author"], "commenter is another individual")
		assert_eq(LodedInnitFeed.entries()[0]["seq"], 5)
	)

	run_case("no_repeat_until_author_pool_exhausted", func():
		_setup()
		for i in 45:
			TimeSystem.run_staff_block()
		var by_author := {}
		for entry in GameState.state["hiring"]["feed"]:
			var list: Array = by_author.get(entry["author"], [])
			list.append(entry["postId"])
			by_author[entry["author"]] = list
		for author in by_author:
			var first_pool: Array = by_author[author].slice(0, 6)
			var unique := {}
			for id in first_pool:
				unique[id] = true
			assert_eq(unique.size(), first_pool.size(), "%s first pool has no repeats" % author)
		for author in GameState.state["hiring"]["feedUsed"]:
			assert_true(GameState.state["hiring"]["feedUsed"][author].size() < 6, "pool resets when spent")
	)

	run_case("feed_caps_at_fifty", func():
		_setup()
		for i in 60:
			TimeSystem.run_staff_block()
		var feed: Array = GameState.state["hiring"]["feed"]
		assert_eq(feed.size(), 50)
		assert_eq(feed[-1]["seq"], 60)
	)

	run_case("badge_counts_posts_after_feed_seen_and_clears", func():
		_setup()
		for i in 3:
			TimeSystem.run_staff_block()
		assert_eq(LodedInnitFeed.unseen_count(), 3)
		LodedInnitFeed.mark_seen()
		assert_eq(LodedInnitFeed.unseen_count(), 0)
		TimeSystem.run_staff_block()
		assert_eq(LodedInnitFeed.unseen_count(), 1)
	)

	run_case("same_seed_gives_same_feed", func():
		_setup()
		for i in 10:
			TimeSystem.run_staff_block()
		var first: Array = GameState.state["hiring"]["feed"].duplicate(true)
		_setup()
		for i in 10:
			TimeSystem.run_staff_block()
		assert_eq(GameState.state["hiring"]["feed"], first)
	)

	run_case("card_model_reads_state_and_trait_variant", func():
		_setup()
		var entry := {
			"postId": "saoirse:0", "seq": 1, "authorKind": "individual", "author": "saoirse",
			"day": 7, "block": 1, "likes": 12, "comments": ["dot:c01"],
		}
		GameState.state["hiring"]["feed"].append(entry)
		var view := LodedInnitFeed.card(entry)
		assert_eq(view["name"], "Saoirse Flynn")
		assert_eq(view["initials"], "SF")
		assert_eq(view["time"], "2d ago")
		assert_eq(view["likes"], 12)
		assert_eq(view["comments"], [{ "author": "Dot Mayhew", "text": "Good to hear the paperwork held." }])
		assert_true(view["body"].contains("Lisbon"), "distracted variant used")
		assert_true(view["meta"].contains("Open to work"))
	)

	run_case("each_status_change_emits_one_templated_post", func():
		_setup()
		Business.activate()
		GameState.state["home"]["rooms"] = ["veinStation", "lab"]
		GameState.state["business"]["float"] = 5000
		var feed: Array = GameState.state["hiring"]["feed"]
		Hiring.hire("marcia")
		assert_eq(feed.size(), 1)
		assert_eq(feed[-1]["postId"], "status:hired")
		assert_true(LodedInnitFeed.body_text(feed[-1]).contains("Marcia"), "name filled")
		assert_true(not LodedInnitFeed.body_text(feed[-1]).contains("{"), "no raw placeholders")
		Hiring.let_go("marcia")
		assert_eq(feed.size(), 2)
		assert_eq(feed[-1]["postId"], "status:letGo")
		Hiring.hire("tomasz")
		GameState.state["hiring"]["poach"]["tomasz"] = { "attempts": 1, "pending": { "factionId": "firm", "offer": 500, "expiresDay": 11 } }
		Hiring.decline_poach("tomasz")
		assert_eq(feed.size(), 4)
		assert_eq(feed[-1]["postId"], "status:poachedAway")
		assert_true(LodedInnitFeed.body_text(feed[-1]).contains(Hiring.faction_name("firm")), "employer filled")
		var seqs: Array = feed.map(func(e): return e["seq"])
		assert_eq(seqs, [1, 2, 3, 4])
	)

	run_case("market_flips_post_employed_and_open", func():
		_setup()
		GameData.HIRING_MARKET["flipChancePerDay"] = 1.0
		Hiring.roll_market_flips()
		var feed: Array = GameState.state["hiring"]["feed"]
		assert_eq(feed.size(), Hiring.candidate_ids().size())
		assert_true(feed.all(func(e): return e["postId"] == "status:employed"))
		feed.clear()
		Hiring.roll_market_flips()
		assert_true(feed.all(func(e): return e["postId"] == "status:open"))
	)

	run_case("status_posts_wait_for_the_app", func():
		GameState.reset()
		LodedInnitFeed.post_status("hired", "marcia")
		assert_eq(GameState.state["hiring"]["feed"].size(), 0)
	)

	run_case("old_save_backfills_feed_used", func():
		GameState.reset()
		var save: Dictionary = GameState.state.duplicate(true)
		save["hiring"].erase("feedUsed")
		assert_eq(SaveManager.backfill_defaults(save)["hiring"]["feedUsed"], {})
	)


func _setup() -> void:
	GameState.reset()
	Rng.set_seed(99)
	GameState.state["flags"]["bizA1JamesJoined"] = true
	GameState.state["world"]["day"] = 9
