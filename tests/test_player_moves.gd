extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


static func _fresh(intel: int = 100) -> void:
	GameState.reset()
	GameState.state["world"]["sites"] = []
	GameState.state["player"]["cash"] = 1000
	GameState.state["intel"] = { Shares.PLAYER: { "firm": intel } }
	Fixtures.seed_faction_vein("fv", 40, "firm")


func run() -> void:
	run_case("complaint freezes the vein, charges, hostile, drops relation", func():
		_fresh()
		var rel_before: int = GameState.state["factions"]["firm"]["relation"]
		var blocks_before := TimeSystem.blocks_left()
		var result := PlayerMoves.perform(PlayerMoves.MOVE_COMPLAINT, "firm", "site_fv")
		assert_true(result["ok"], "ok")
		assert_true(NetworkHandler.is_security_frozen("site_fv"), "frozen")
		assert_eq(GameState.state["player"]["cash"], 850)
		assert_eq(TimeSystem.blocks_left(), blocks_before - 1)
		assert_true(GameState.state["factions"]["firm"]["relation"] < rel_before, "relation dropped")
	)
	run_case("intel gate blocks, no charge", func():
		_fresh(0)
		var result := PlayerMoves.perform(PlayerMoves.MOVE_POLICE, "firm")
		assert_true(not result["ok"], "blocked")
		assert_eq(GameState.state["player"]["cash"], 1000)
	)
	run_case("police tip cuts faction sell income until it lapses", func():
		_fresh()
		assert_eq(PlayerMoves.sell_mult("firm"), 1.0)
		PlayerMoves.perform(PlayerMoves.MOVE_POLICE, "firm")
		assert_eq(PlayerMoves.sell_mult("firm"), 0.85)
		GameState.state["world"]["day"] += 8
		assert_eq(PlayerMoves.sell_mult("firm"), 1.0)
	)
	run_case("leak queues opposite pushes, headline, hits other factions", func():
		_fresh()
		var rel: int = Factions.get_relation("firm", "guild")
		PlayerMoves.perform(PlayerMoves.MOVE_LEAK, "firm")
		var pushes := Barometer.queued_pushes()
		assert_eq(pushes.size(), Barometer.leak_prefs("firm").size())
		assert_eq(pushes[0]["direction"], "pull", "economic boom push reversed")
		assert_eq(pushes[0]["strength"], 12)
		assert_true(Factions.get_relation("firm", "guild") < rel, "other-faction relation dropped")
		assert_true(GameState.state["barometer"]["headlines"].size() > 0, "headline")
	)
	run_case("move breaks a truce and answers a grudge", func():
		_fresh()
		Grudges.record("firm", "shoreditch")
		PlayerMoves.perform(PlayerMoves.MOVE_LEAK, "firm")
		assert_true(not Grudges.has_grudge("firm"), "grudge answered")
	)
	run_case("not a warmonger act", func():
		_fresh()
		PlayerMoves.perform(PlayerMoves.MOVE_POLICE, "firm")
		assert_eq(Warmonger.score(), 0.0, "warmonger score unchanged")
	)
