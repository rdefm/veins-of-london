extends RefCounted

# Body of scripts/sim_faction_economy.gd (see there for usage).

const SETTLE_FROM := 31  # price range columns cover days SETTLE_FROM..end


func run(opts: Dictionary) -> void:
	GameState.reset()
	Rng.set_seed(opts["seed"])
	Factions.seed_day_one_veins()
	var ranges := {}
	var timeline: Array = []
	var churn := {}
	var harvest := {}
	var start_veins := _vein_counts()
	var days: int = opts["days"]
	for i in days:
		var world: Dictionary = GameState.state["world"]
		world["day"] += 1
		if opts["player"] > 0:
			Shares.record_ore(Shares.PLAYER, opts["playerOre"], opts["player"])
			Market.record_supply("ore", opts["playerOre"], opts["player"], Shares.PLAYER)
		if opts.has("political"):
			_hold_ticker("political", opts["political"])
		var owners_before := _vein_owners()
		TimeSystem.daily_tick()
		_tally_churn(churn, owners_before, _vein_owners())
		if world["day"] >= SETTLE_FROM:
			_track_ranges(ranges)
			_accumulate_harvest(harvest)
		if world["day"] % 10 == 0:
			timeline.append("day %d: %s" % [world["day"], _vein_counts()])
	print("== %d days, seed %d, player %d %s/day ==" % [days, opts["seed"], opts["player"], opts["playerOre"]])
	var ticker: Array = []
	for section in Barometer.SECTIONS:
		ticker.append(GameState.state["barometer"][section])
	print("Ticker now: %s" % ", ".join(ticker))
	print("\n-- faction veins (count, mean growth) --")
	print("day 0: %s" % start_veins)
	for line in timeline:
		print(line)
	print("\n-- vein churn over the run --")
	for faction_id in GameData.FACTIONS:
		print("%-11s %s" % [faction_id, churn.get(faction_id, {})])
	_print_harvest(harvest, days - SETTLE_FROM + 1)
	_print_prices(ranges)
	_print_shares("ore")
	_print_shares("craft")
	_print_factions()


# Pins a Ticker state active (war=N holds political war from day N on).
func _hold_ticker(section: String, state_id: String) -> void:
	Barometer.ensure_progress()
	var progress: Dictionary = GameState.state["barometer"]["progress"][section]
	for other in progress.keys():
		progress[other] = 0
	progress[state_id] = 100
	GameState.state["barometer"][section] = state_id


func _mult(kind: String, good_type: String) -> float:
	return float(Market.quote(kind, good_type)) / Market.base_price(kind, good_type)


func _track_ranges(ranges: Dictionary) -> void:
	for kind in Market.KINDS:
		for good_type in GameData.MARKET["goods"][kind]:
			var key: String = kind + ":" + good_type
			var mult := _mult(kind, good_type)
			var r: Array = ranges.get(key, [mult, mult])
			ranges[key] = [minf(r[0], mult), maxf(r[1], mult)]


# Adds today's ore-tally bucket into harvest { producer: { oreType: n } }.
func _accumulate_harvest(harvest: Dictionary) -> void:
	var days: Array = GameState.state["shares"]["days"]
	if days.is_empty() or int(days[-1]["day"]) != GameState.state["world"]["day"]:
		return
	var by_producer: Dictionary = days[-1]["ore"]
	for producer in by_producer:
		if not harvest.has(producer):
			harvest[producer] = {}
		for ore_type in by_producer[producer]:
			harvest[producer][ore_type] = int(harvest[producer].get(ore_type, 0)) + int(by_producer[producer][ore_type])


# Mean ore harvested per day over the settle window, per producer and type.
func _print_harvest(harvest: Dictionary, span: int) -> void:
	print("\n-- mean ore harvested/day, days %d+ --" % SETTLE_FROM)
	var header := "%-12s" % "producer"
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		header += "%9s" % ore_type
	print(header + "      all")
	var faction_totals := {}
	for producer in Shares.producers():
		var line := "%-12s" % producer
		var all := 0.0
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			var per_day: float = float(harvest.get(producer, {}).get(ore_type, 0)) / span
			all += per_day
			if GameData.FACTIONS.has(producer):
				faction_totals[ore_type] = float(faction_totals.get(ore_type, 0.0)) + per_day
			line += "%9.1f" % per_day
		print(line + "%9.1f" % all)
	var line := "%-12s" % "factions"
	var all := 0.0
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		all += float(faction_totals.get(ore_type, 0.0))
		line += "%9.1f" % float(faction_totals.get(ore_type, 0.0))
	print(line + "%9.1f" % all)


func _print_prices(ranges: Dictionary) -> void:
	print("\n-- London prices (x base; range = days %d+) --" % SETTLE_FROM)
	for kind in ["ore", "consumable"]:
		for good_type in GameData.MARKET["goods"][kind]:
			var r: Array = ranges.get(kind + ":" + good_type, [0.0, 0.0])
			print("%-18s base %4d  now %4d  %.2fx  range %.2f-%.2f  stock %d" % [
				good_type, Market.base_price(kind, good_type), Market.quote(kind, good_type),
				_mult(kind, good_type), r[0], r[1],
				int(GameState.state["market"]["goods"][kind][good_type]["stock"])])


func _print_shares(tally: String) -> void:
	print("\n-- %s share, last 7 days (%% of each ore type) --" % tally)
	var header := "%-12s" % "producer"
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		header += "%9s" % ore_type
	print(header)
	var totals := Shares.window_totals(tally)
	var table := Shares.overview(tally)
	for producer in table:
		var line := "%-12s" % producer
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			line += "%8.0f%%" % (100.0 * float(table[producer][ore_type]))
		print(line)
	var line := "%-12s" % "units/day"
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		var total := 0
		for by_type in totals.values():
			total += int(by_type.get(ore_type, 0))
		line += "%9.0f" % (total / float(GameData.SHARES_WINDOW_DAYS))
	print(line)


# { siteId: [factionId, growth] } for every faction vein.
func _vein_owners() -> Dictionary:
	var owners := {}
	for site in GameState.state["world"]["sites"]:
		if site["factionVein"] != null:
			owners[site["id"]] = [site["factionVein"]["factionId"], int(site["factionVein"]["growth"])]
	return owners


func _bump(churn: Dictionary, faction_id: String, key: String) -> void:
	if not churn.has(faction_id):
		churn[faction_id] = {}
	churn[faction_id][key] = int(churn[faction_id].get(key, 0)) + 1


# Per faction: claimed (new vein), died (collapse), lostTo<X> / wonFrom<X>
# (rivalry transfers).
func _tally_churn(churn: Dictionary, before: Dictionary, after: Dictionary) -> void:
	for site_id in before:
		var owner: String = before[site_id][0]
		if not after.has(site_id):
			_bump(churn, owner, "died")
		elif after[site_id][0] != owner:
			_bump(churn, owner, "lostTo_" + after[site_id][0])
			_bump(churn, after[site_id][0], "wonFrom_" + owner)
	for site_id in after:
		if not before.has(site_id):
			_bump(churn, after[site_id][0], "claimed")


# "<faction> <count>/<mean growth> <primary-ore count>p" per faction.
func _vein_counts() -> String:
	var parts: Array = []
	for faction_id in GameData.FACTIONS:
		var count := 0
		var primary := 0
		var growth := 0
		for site in GameState.state["world"]["sites"]:
			var vein: Variant = site["factionVein"]
			if vein != null and vein["factionId"] == faction_id:
				count += 1
				growth += int(vein["growth"])
				if vein["oreType"] == GameData.FACTIONS[faction_id]["primaryOre"]:
					primary += 1
		parts.append("%s %d/%d %dp" % [faction_id, count, growth / maxi(1, count), primary])
	return "  ".join(parts)


func _print_factions() -> void:
	print("\n-- factions --")
	var veins := {}
	for site in GameState.state["world"]["sites"]:
		if site["factionVein"] != null:
			var owner: String = site["factionVein"]["factionId"]
			veins[owner] = int(veins.get(owner, 0)) + 1
	for faction_id in GameData.FACTIONS:
		var faction: Dictionary = GameState.state["factions"][faction_id]
		var items := {}
		for recipe_key in faction["holdings"]["items"]:
			items[recipe_key] = FactionSim.item_held(faction_id, recipe_key)
		print("%-11s £%-6d veins %-3d ore %s items %s short %s" % [
			faction_id, int(faction["resources"]), int(veins.get(faction_id, 0)),
			faction["holdings"]["ore"], items, faction["shortfall"]])
