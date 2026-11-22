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
	var dial: Dictionary = Dial.new_dial()
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


# A running Prophet's Breath at `level`, `blocks_left` blocks from expiry
# (negative: already expired).
static func _breathe(level: int, blocks_left: int = 3) -> void:
	var effects: Array = GameState.state["player"]["activeEffects"]
	effects.clear()
	effects.append({ "item": ActiveEffects.PROPHETS_BREATH, "level": level, "expiresAtBlock": ActiveEffects.absolute_block() + blocks_left })


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

	# ── Prophet's Breath source ──

	run_case("breath_silent_when_not_running", func():
		_setup(0)
		assert_eq(MarketInsight._breath_reads(_projected({ "ore/time": 0.3 })), {}, "no Breath: silent")
		_breathe(3, -1)
		assert_eq(MarketInsight._breath_reads(_projected({ "ore/time": 0.3 })), {}, "expired Breath: silent")
		assert_eq(MarketInsight.read_for(MarketInsight.reads(), "ore", "time")["lines"], [], "reads(): no Breath lines")
	)

	run_case("breath_reads_every_good_with_a_band_round_the_projection", func():
		var widths: Array = GameData.ACTIVE_EFFECTS["prophetsBreath"]["marketBandByLevel"]
		for level in range(1, 6):
			_setup(0)
			_breathe(level)
			var projected := _projected({ "ore/time": 0.3 })
			var reads := MarketInsight._breath_reads(projected)
			for kind in projected:
				for good_type in projected[kind]:
					assert_eq(_lines(reads, kind, good_type).size(), 1, "lvl %d %s/%s reads" % [level, kind, good_type])
			var p := int(projected["consumable"]["blast"])
			var band := MarketInsight.breath_band(p)
			assert_true(int(band[0]) <= p and p <= int(band[1]), "lvl %d band contains projection" % level)
			assert_eq(band, [GameState.round_epsilon(p * (1.0 - float(widths[level]))), GameState.round_epsilon(p * (1.0 + float(widths[level])))], "lvl %d width" % level)
			var line: String = GameData.ACTIVE_EFFECTS["prophetsBreath"]["marketLine"]
			assert_eq(_lines(reads, "consumable", "blast"), [line % ("£%d–£%d" % band)], "lvl %d item line" % level)
			var ore_band := MarketInsight.breath_band(int(projected["ore"]["time"]))
			assert_eq(_lines(reads, "ore", "time"), [line % ("£%d–£%d/%d" % [ore_band[0], ore_band[1], Market.price_lot("ore")])], "lvl %d ore line per lot" % level)
		_setup(0)
		_breathe(1)
		var wide := MarketInsight.breath_band_width()
		_breathe(5)
		assert_true(MarketInsight.breath_band_width() < wide, "higher level narrower band")
	)

	run_case("breath_notable_follows_threshold", func():
		_setup(0)
		_breathe(2)
		var reads := MarketInsight._breath_reads(_projected({ "ore/time": 0.06, "ore/life": 0.02 }))
		assert_true(MarketInsight.read_for(reads, "ore", "time")["notable"], "6% notable")
		assert_true(not MarketInsight.read_for(reads, "ore", "life")["notable"], "2% spoken, not notable")
	)

	run_case("breath_and_fate_lines_sit_together", func():
		_setup(5)
		_breathe(2)
		var market: Dictionary = GameState.state["market"]
		market["goods"]["ore"]["fate"]["stock"] = 40
		var projected := Market.projected_quotes()
		assert_true(MarketInsight.is_notable(projected, "ore", "fate"), "setup: fate ore notable")
		var merged := MarketInsight.read_for(MarketInsight.reads(), "ore", "fate")
		assert_eq(merged["lines"].size(), 2, "Fate + Breath lines both present")
		assert_true(merged["notable"], "notable")
		var quiet := MarketInsight.read_for(MarketInsight.reads(), "consumable", "blast")
		assert_true(quiet["lines"].size() >= 1, "Breath speaks on every row")
	)

	run_case("breath_reads_write_no_state", func():
		_setup(5)
		_breathe(3)
		Market.record_supply("ore", "life", 50, "player")
		var before: Dictionary = GameState.deep_copy(GameState.state)
		MarketInsight.reads()
		assert_eq(GameState.state, before, "state deep-equal before/after")
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
		var spoken := MarketInsightIcon.make({ "lines": ["x"], "notable": false })
		assert_true(not spoken.disabled, "spoken icon tappable")
		assert_eq(spoken.get_theme_color("font_color"), GameData.PALETTE[MarketInsightIcon.SPOKEN_ID], "light red")
		spoken.free()
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
