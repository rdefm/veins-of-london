extends "res://tests/test_base.gd"

# Market projection (Market.projected_quotes), the insight slot
# (MarketInsight) and its Fate gut-feeling source (R§3.13 "Insight").

const HAFT_ID := "collective_brolly"


# A clean player: no ore or items anywhere; a Fate Lens at `tier` (0 = none)
# and Sense `sense`.
static func _setup(tier: int, sense: int = 2) -> void:
	GameState.reset()
	var player: Dictionary = GameState.state["player"]
	for ore_type in player["orichalchum"]:
		player["orichalchum"][ore_type] = 0
	player["inventory"] = {}
	player["stash"]["orichalchum"] = {}
	player["stash"]["inventory"] = {}
	player["senseSkill"] = sense
	GameState.state["flags"]["dialGiftGranted"] = true
	var dial: Dictionary = Dial.new_dial(HAFT_ID)
	dial["level"] = 5
	dial["lenses"] = [] if tier <= 0 else [{ "ore": "fate", "tier": tier }]
	player["dial"] = dial


# Today's quotes with every good flat, then the listed moves applied as
# fractions: { "kind/good": fraction }.
static func _projected(moves: Dictionary) -> Dictionary:
	var projected := {}
	for kind in Market.KINDS:
		projected[kind] = {}
		for good_type in GameState.state["market"]["goods"][kind]:
			projected[kind][good_type] = Market.quote(kind, good_type)
	for key in moves:
		var parts: PackedStringArray = str(key).split("/")
		projected[parts[0]][parts[1]] = roundi(Market.quote(parts[0], parts[1]) * (1.0 + float(moves[key])))
	return projected


static func _lines(reads: Dictionary, kind: String, good_type: String) -> Array:
	return MarketInsight.read_for(reads, kind, good_type)["lines"]


static func _quotes() -> Dictionary:
	var quotes := {}
	for kind in Market.KINDS:
		quotes[kind] = {}
		for good_type in GameState.state["market"]["goods"][kind]:
			quotes[kind][good_type] = Market.quote(kind, good_type)
	return quotes


func run() -> void:
	var copy: Dictionary = GameData.DIAL_LENS["fateMarket"]

	# ── projection ──

	run_case("projection_equals_next_reprice_over_several_days", func():
		GameState.reset()
		var market: Dictionary = GameState.state["market"]
		market["goods"]["ore"]["time"]["stock"] = 40
		market["goods"]["ore"]["fate"]["stock"] = 4000
		var tiers: Dictionary = market["goods"]["consumable"]["timePearl"]["tiers"]
		for tier_key in tiers:
			tiers[tier_key] = 0
		market["goods"]["consumable"]["timePearl"]["stock"] = 0
		for day in 5:
			Market.record_supply("ore", "physics", 30 * (day + 1), "player")
			Market.record_demand("consumable", "blast", 2, "player")
			Market.record_supply("consumable", "healingSalve", 5, "player", 2)
			var projected := Market.projected_quotes()
			Market.daily_reprice()
			assert_eq(projected, _quotes(), "day %d: projection equals reprice" % day)
	)

	run_case("projection_writes_no_state", func():
		GameState.reset()
		Market.record_supply("ore", "life", 50, "player")
		Market.record_demand("consumable", "blast", 3, "player")
		var before: Dictionary = GameState.deep_copy(GameState.state)
		Market.projected_quotes()
		MarketInsight.reads()
		assert_eq(GameState.state, before, "state deep-equal before/after")
	)

	# ── Fate source gates ──

	run_case("fate_silent_without_lens_or_below_sense_world", func():
		var moves := { "ore/time": 0.3 }
		_setup(0, 5)
		assert_eq(MarketInsight._fate_reads(_projected(moves)), {}, "no Fate Lens: silent")
		_setup(5, 1)
		assert_eq(MarketInsight._fate_reads(_projected(moves)), {}, "Sense 1: silent")
		_setup(5, 2)
		assert_eq(_lines(MarketInsight._fate_reads(_projected(moves)), "ore", "time"), [copy["rising"]], "Sense 2: speaks")
	)

	run_case("fate_ignores_a_good_lens_in_pocket", func():
		_setup(0, 5)
		GameState.state["player"]["lensInventory"].append({ "ore": "fate", "tier": 5 })
		assert_eq(MarketInsight._fate_reads(_projected({ "ore/time": 0.3 })), {}, "unloaded Fate Lens: silent")
	)

	# ── held goods ──

	run_case("fate_held_goods_read_sell_soon_or_hold", func():
		_setup(1)
		GameState.state["player"]["orichalchum"]["time"] = 5
		GameState.state["player"]["stash"]["orichalchum"]["physics"] = 2
		Crafting.inventory_add("blast", 1, 1)
		var reads := MarketInsight._fate_reads(_projected({ "ore/time": -0.2, "ore/physics": 0.2, "consumable/blast": -0.1, "ore/life": 0.02 }))
		assert_eq(_lines(reads, "ore", "time"), [copy["heldFalling"]], "held fall: sell soon")
		assert_eq(_lines(reads, "ore", "physics"), [copy["heldRising"]], "stashed rise: hold")
		assert_eq(_lines(reads, "consumable", "blast"), [copy["heldFalling"]], "held item fall: sell soon")
		assert_eq(_lines(reads, "ore", "life"), [], "move under 5%: silent")
	)

	run_case("fate_held_reads_do_not_use_the_unheld_count", func():
		_setup(1)
		GameState.state["player"]["orichalchum"]["time"] = 5
		GameState.state["player"]["orichalchum"]["life"] = 5
		var reads := MarketInsight._fate_reads(_projected({ "ore/time": -0.2, "ore/life": 0.2, "ore/fate": 0.4 }))
		assert_eq(_lines(reads, "ore", "time").size() + _lines(reads, "ore", "life").size(), 2, "every held notable good reads")
		assert_eq(_lines(reads, "ore", "fate"), [copy["rising"]], "plus one unheld at tier 1")
	)

	# ── unheld goods by tier ──

	run_case("fate_unheld_reads_the_biggest_moves_by_tier", func():
		var moves := { "ore/time": 0.1, "ore/fate": -0.4, "consumable/blast": 0.25, "ore/life": -0.06 }
		var expected_counts: Array = GameData.DIAL_LENS["fateMarketReadsByTier"]
		for tier in range(1, 6):
			_setup(tier)
			var reads := MarketInsight._fate_reads(_projected(moves))
			var spoken := 0
			for kind in reads:
				spoken += reads[kind].size()
			assert_eq(spoken, int(expected_counts[tier]), "tier %d count" % tier)
		_setup(3)
		var reads := MarketInsight._fate_reads(_projected(moves))
		assert_eq(_lines(reads, "ore", "fate"), [copy["falling"]], "biggest |move| first, falling")
		assert_eq(_lines(reads, "consumable", "blast"), [copy["rising"]], "second biggest, rising")
		assert_eq(_lines(reads, "ore", "time"), [], "third not read at tier 3")
	)

	# ── insight slot ──

	run_case("reads_merge_sources_and_default_is_silent", func():
		_setup(0)
		var reads := MarketInsight.reads()
		assert_eq(MarketInsight.read_for(reads, "ore", "time"), { "lines": [], "notable": false }, "no source: nothing")
	)

	run_case("notable_threshold_is_five_percent_of_today", func():
		GameState.reset()
		assert_true(MarketInsight.is_notable(_projected({ "ore/time": 0.06 }), "ore", "time"), "6% notable")
		assert_true(not MarketInsight.is_notable(_projected({ "ore/time": 0.03 }), "ore", "time"), "3% not")
	)

	run_case("icon_grey_untappable_when_silent_and_pulses_when_notable", func():
		GameState.reset()
		GameState.state["meta"]["reducedMotion"] = false
		var quiet := MarketInsightIcon.make({ "lines": [], "notable": false })
		assert_true(quiet.disabled, "silent icon disabled")
		assert_eq(quiet.get_theme_color("font_disabled_color"), GameData.PALETTE[MarketInsightIcon.IDLE_ID], "grey")
		var loud := MarketInsightIcon.make({ "lines": ["x"], "notable": true })
		assert_true(not loud.disabled, "notable icon tappable")
		assert_eq(loud.get_theme_color("font_color"), GameData.PALETTE[MarketInsightIcon.NOTABLE_ID], "red")
		var tree := Engine.get_main_loop() as SceneTree
		var before := tree.get_processed_tweens().size()
		tree.root.add_child(quiet)
		assert_eq(tree.get_processed_tweens().size(), before, "silent icon does not pulse")
		tree.root.add_child(loud)
		assert_eq(tree.get_processed_tweens().size(), before + 1, "notable icon pulses")
		loud.pressed.emit()
		assert_true(loud.get_node_or_null("MarketInsightBubble") != null, "tap opens the bubble")
		quiet.free()
		loud.free()
	)

	run_case("trade_sheet_and_ticker_rows_carry_the_icon", func():
		_setup(0)
		GameState.state["player"]["orichalchum"]["time"] = 5
		var phone := PhoneScreen.new()
		phone._ready()
		var app := TickerApp.new()
		app.shell = phone
		app._tab = TickerApp.STOCK_TAB
		var content := VBoxContainer.new()
		app.build(content)
		assert_true(phone.find_child("TickerInsight_ore_time", true, false) != null, "ticker ore row has !")
		app.teardown()
		content.free()
		phone.free()
		var sheet := SellMenuView.new()
		sheet.refresh({})
		assert_true(sheet.find_child("TradeInsight_ore_time", true, false) != null, "trade sheet ore row has !")
		sheet.free()
	)
