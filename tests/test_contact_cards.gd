extends "res://tests/test_base.gd"

# collective1-07: ContactCards' static builders return plain Controls with
# no scene-tree dependency, so they're testable directly -- same reasoning
# tests/test_modal_layer.gd gives for instantiating ModalLayer.new() without
# adding it to a live tree.


func run() -> void:
	# ── §7.1: the recruit row is suppressed, not shown-disabled ──────────

	run_case("build_recruit_row_returns_null_for_a_non_recruitable_contact", func():
		GameState.reset()
		for key in ["des", "nadia", "hakim"]:
			assert_eq(ContactCards.build_recruit_row(key), null, "%s's recruit row must not exist at all" % key)
	)

	run_case("build_recruit_row_is_unchanged_for_archie_and_james", func():
		GameState.reset()
		assert_true(ContactCards.build_recruit_row("archie") != null, "archie keeps a recruit row")
		GameState.state["contacts"]["james"]["unlocked"] = true
		assert_true(ContactCards.build_recruit_row("james") != null, "james keeps a recruit row")
	)

	# ── §5.5/§7.2: the Trade door ─────────────────────────────────────────

	run_case("build_trade_action_is_locked_before_collectiveLaneUnlocked", func():
		GameState.reset()
		var b := ContactCards.build_trade_action("des") as Button
		assert_eq(b.text, "🤝 Trade (not unlocked yet)")
		assert_true(b.disabled, "locked until flags.collectiveLaneUnlocked")
	)

	run_case("build_trade_action_opens_sell_menu_routed_to_the_collective_lane_once_unlocked", func():
		GameState.reset()
		GameState.state["flags"]["collectiveLaneUnlocked"] = true
		var b := ContactCards.build_trade_action("nadia") as Button
		assert_eq(b.text, "🤝 Trade")
		assert_true(not b.disabled)

		b.pressed.emit()

		assert_eq(GameState.state["modal"]["type"], "sell_menu")
		assert_eq(GameState.state["modal"]["data"], { "factionId": "collective", "contactId": "nadia" })
	)
