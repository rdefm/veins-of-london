extends RefCounted

# Body of scripts/sim_faction_economy.gd (see there for usage).

const SETTLE_FROM := 31  # price range columns cover days SETTLE_FROM..end


func run(opts: Dictionary) -> void:
	GameState.reset()
	Rng.set_seed(opts["seed"])
	GameData.FACTION_RIVALRY = int(opts.get("rivalry", 1)) != 0
	Factions.seed_day_one_veins()
	var ranges := {}
	var timeline: Array = []
	var churn := {}
	var harvest := {}
	var flows := {}
	# Every London trade becomes a "dump"/"buy" annotation, so flows can be
	# read back per source after each rollover.
	GameData.MARKET["annotations"]["dumpVolumeMult"] = 0.0
	GameData.MARKET["annotations"]["cap"] = 1000000
	var start_veins := _vein_counts()
	var days: int = opts["days"]
	var diplo := { "lines": [], "events": [], "firsts": {}, "warEnds": {}, "minVeins": {} }
	for i in days:
		var world: Dictionary = GameState.state["world"]
		world["day"] += 1
		if opts["player"] > 0:
			Shares.record_ore(Shares.PLAYER, opts["playerOre"], opts["player"])
			Market.record_supply("ore", opts["playerOre"], opts["player"], Shares.PLAYER)
		if opts.has("political"):
			_hold_ticker("political", opts["political"])
		var owners_before := _vein_owners()
		var diplo_before := _diplo_snapshot()
		TimeSystem.daily_tick()
		_tally_churn(churn, owners_before, _vein_owners())
		_track_diplomacy(diplo, diplo_before)
		if world["day"] >= SETTLE_FROM:
			_track_ranges(ranges)
			_accumulate_harvest(harvest)
			_accumulate_flows(flows)
		if world["day"] % 10 == 0:
			timeline.append("day %d: %s" % [world["day"], _vein_counts()])
	print("== %d days, seed %d, player %d %s/day, rivalry %s ==" % [days, opts["seed"], opts["player"], opts["playerOre"], GameData.FACTION_RIVALRY])
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
	_print_flows(flows, days - SETTLE_FROM + 1)
	_print_prices(ranges)
	_print_shares("ore")
	_print_shares("craft")
	_print_factions()
	_print_diplomacy(diplo, int(opts.get("every", 1)))


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


# Adds today's London ore flows into flows { "+source"/"-source": { oreType: n } }:
# supply (+) and demand (-) per trader from annotations, plus the
# Independents slice, civilian demand and derived (item-shortage) demand.
func _accumulate_flows(flows: Dictionary) -> void:
	var day: int = GameState.state["world"]["day"]
	var faction_buys := {}
	for note in GameState.state["market"].get("annotations", []):
		if int(note["day"]) != day or note["goodKind"] != "ore":
			continue
		if note["kind"] == "dump":
			_add_flow(flows, "+" + str(note["source"]), note["good"], float(note["value"]))
		elif note["kind"] == "buy":
			_add_flow(flows, "-" + str(note["source"]), note["good"], float(note["value"]))
			faction_buys[note["good"]] = int(faction_buys.get(note["good"], 0)) + int(note["value"])
	# The rollover has cleared today's tallies, so the Independents' buy
	# cover is rebuilt from the faction buy annotations.
	var cover := float(GameData.MARKET["independentsBuyCover"])
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		var slice: float = Market.independents_share("ore") * Market.civilian_demand("ore", ore_type)
		_add_flow(flows, "+independents", ore_type, slice + cover * int(faction_buys.get(ore_type, 0)))
		_add_flow(flows, "-civilian", ore_type, Market.civilian_demand("ore", ore_type))
		_add_flow(flows, "-derived", ore_type, Market.derived_ore_demand(ore_type))


func _add_flow(flows: Dictionary, key: String, ore_type: String, qty: float) -> void:
	if not flows.has(key):
		flows[key] = {}
	flows[key][ore_type] = float(flows[key].get(ore_type, 0.0)) + qty


func _print_flows(flows: Dictionary, span: int) -> void:
	print("
-- London ore flows/day, days %d+ (+ supply, - demand) --" % SETTLE_FROM)
	var header := "%-14s" % "source"
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		header += "%9s" % ore_type
	print(header)
	var keys: Array = flows.keys()
	keys.sort()
	var net := {}
	for key in keys:
		var line := "%-14s" % key
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			var per_day: float = float(flows[key].get(ore_type, 0.0)) / span
			net[ore_type] = float(net.get(ore_type, 0.0)) + (per_day if key.begins_with("+") else -per_day)
			line += "%9.1f" % per_day
		print(line)
	var line := "%-14s" % "net"
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		line += "%9.1f" % float(net[ore_type])
	print(line)


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


# ── Diplomacy timelines ─────────────────────────────────────────────────

const SHORT := { "collective": "col", "firm": "frm", "guild": "gld", "network": "net", "conclave": "ccl", "player": "you" }


# Escalation entries and war keys before today's rollover.
func _diplo_snapshot() -> Dictionary:
	var entries := {}
	var targets: Dictionary = GameState.state["factionEscalation"]["targets"]
	for observer in targets:
		for target in targets[observer]:
			entries[observer + ">" + target] = GameState.deep_copy(targets[observer][target])
	var war_keys := {}
	for war in FactionAI.wars():
		war_keys[FactionAI.war_key(war["parties"][0], war["parties"][1])] = war["parties"]
	return { "entries": entries, "wars": war_keys }


func _party(party: String) -> String:
	return SHORT.get(party, party)


# One timeline line per day plus events: warnings/moves (escalation entries
# whose lastMoveDay became today), wars started/ended (ended by truce,
# collapse = a faction side weak or veinless, or quiet), truces signed.
func _track_diplomacy(diplo: Dictionary, before: Dictionary) -> void:
	var day: int = GameState.state["world"]["day"]
	var targets: Dictionary = GameState.state["factionEscalation"]["targets"]
	for observer in targets:
		for target in targets[observer]:
			var entry: Dictionary = targets[observer][target]
			if int(entry["lastMoveDay"]) != day:
				continue
			var old: Dictionary = before["entries"].get(observer + ">" + target, { "warnedBand": "none" })
			var what: String = "warn(%s)" % entry["warnedBand"] if old["warnedBand"] != entry["warnedBand"] else "move"
			diplo["events"].append("day %d: %s > %s %s" % [day, _party(observer), _party(target), what])
			var first_key: String = observer + ">" + target + ":" + ("move" if what == "move" else entry["warnedBand"])
			if not diplo["firsts"].has(first_key):
				diplo["firsts"][first_key] = day
	var now_keys := {}
	for war in FactionAI.wars():
		var key := FactionAI.war_key(war["parties"][0], war["parties"][1])
		now_keys[key] = true
		if not before["wars"].has(key):
			diplo["events"].append("day %d: WAR %s-%s" % [day, _party(war["parties"][0]), _party(war["parties"][1])])
	for key in before["wars"]:
		if now_keys.has(key):
			continue
		var parties: Array = before["wars"][key]
		var how := "quiet"
		if FactionAI.in_truce(parties[0], parties[1]):
			how = "truce"
		else:
			for party in parties:
				if party != Shares.PLAYER and (FactionSim.is_weak(party) or Sites.sites_with_faction_vein(party).is_empty()):
					how = "collapse"
		diplo["warEnds"][how] = int(diplo["warEnds"].get(how, 0)) + 1
		diplo["events"].append("day %d: war %s-%s ends (%s)" % [day, _party(parties[0]), _party(parties[1]), how])
	for faction_id in GameData.FACTIONS:
		var count := Sites.sites_with_faction_vein(faction_id).size()
		diplo["minVeins"][faction_id] = mini(int(diplo["minVeins"].get(faction_id, count)), count)
	diplo["lines"].append(_diplo_line(day))


# "d12 | you: col 20N frm 31N ... | pairs: col-frm -50H ... | war col-frm w12/8 | truce ..."
func _diplo_line(day: int) -> String:
	var parts: Array = []
	for faction_id in GameData.FACTIONS:
		parts.append("%s %d%s" % [_party(faction_id), int(GameState.state["factions"][faction_id]["relation"]),
			FactionAI.player_stance(faction_id).substr(0, 1).to_upper()])
	var pairs: Array = []
	for pair in FactionAI._pairs():
		pairs.append("%s-%s %d%s" % [_party(pair[0]), _party(pair[1]), Factions.get_relation(pair[0], pair[1]),
			FactionAI.pair_stance(pair[0], pair[1]).substr(0, 1).to_upper()])
	var wars: Array = []
	for war in FactionAI.wars():
		var a: String = war["parties"][0]
		var b: String = war["parties"][1]
		wars.append("%s-%s %.0f/%.0f" % [_party(a), _party(b), float(war["weariness"].get(a, 0.0)), float(war["weariness"].get(b, 0.0))])
	var truces: Array = []
	for truce in FactionAI.truces():
		truces.append("%s-%s ->d%d" % [_party(truce["parties"][0]), _party(truce["parties"][1]), int(truce["endDay"])])
	var tired: Array = []
	for party in [Shares.PLAYER] + GameData.FACTIONS.keys():
		if FactionAI.weariness(party) > 0.0:
			tired.append("%s %.0f" % [_party(party), FactionAI.weariness(party)])
	return "d%-3d| %s | %s | war %s | weary %s | truce %s" % [day, " ".join(parts), " ".join(pairs),
		", ".join(wars), ", ".join(tired), ", ".join(truces)]


func _print_diplomacy(diplo: Dictionary, every: int) -> void:
	if every > 0:
		print("
-- diplomacy timeline (relation + stance initial; war weariness a/b) --")
		for i in diplo["lines"].size():
			if (i + 1) % every == 0:
				print(diplo["lines"][i])
	print("
-- diplomacy events --")
	for line in diplo["events"]:
		print(line)
	print("
-- first warning/move against you --")
	for faction_id in GameData.FACTIONS:
		var warn: Variant = diplo["firsts"].get(faction_id + ">player:warning")
		var market: Variant = diplo["firsts"].get(faction_id + ">player:market")
		var raid: Variant = diplo["firsts"].get(faction_id + ">player:raid")
		var move: Variant = diplo["firsts"].get(faction_id + ">player:move")
		print("%-11s warning %-4s market-warn %-4s raid-warn %-4s first move %s" % [faction_id, warn, market, raid, move])
	print("
war endings: %s" % diplo["warEnds"])
	print("min faction veins: %s" % diplo["minVeins"])
