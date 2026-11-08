extends RefCounted

# Body of scripts/sim_faction_economy.gd (see there for usage).

const SETTLE_FROM := 31  # price range columns cover days SETTLE_FROM..end


# Returns the turf summary (see _turf_summary) so tests can assert on it;
# opts.quiet = 1 skips the report.
func run(opts: Dictionary) -> Dictionary:
	Rng.set_seed(opts["seed"])
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
	var clamp_days := {}
	var stock_sum := {}
	var short := {}
	var wallets := { "start": _wallets(), "mid": {}, "end": {} }
	var start_veins := _vein_counts()
	var days: int = opts["days"]
	# Autosaves from the rollover land in a throwaway folder, not real saves.
	var real_dirs := [SaveManager.saves_dir, SaveManager.autosave_dir]
	SaveManager.saves_dir = "user://sim_saves/"
	SaveManager.autosave_dir = "user://sim_autosave/"
	var diplo := { "lines": [], "events": [], "firsts": {}, "warEnds": {}, "minVeins": {} }
	var turf := { "flips": 0, "controllers": {}, "series": [], "minControl": {}, "minPresence": {}, "zeroSince": {}, "peakControl": {} }
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
		_track_turf(turf)
		if world["day"] == SETTLE_FROM - 1:
			wallets["mid"] = _wallets()
		if world["day"] >= SETTLE_FROM:
			_track_ranges(ranges, clamp_days)
			_accumulate_harvest(harvest)
			_accumulate_flows(flows)
			_track_stock(stock_sum)
			_track_shortfall(short)
		if world["day"] % 10 == 0:
			timeline.append("day %d: %s" % [world["day"], _vein_counts()])
	SaveManager.saves_dir = real_dirs[0]
	SaveManager.autosave_dir = real_dirs[1]
	var summary := _turf_summary(turf, days)
	if int(opts.get("quiet", 0)) != 0:
		return summary
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
	_print_clamp_days(clamp_days, days - SETTLE_FROM + 1)
	_print_stock(stock_sum, days - SETTLE_FROM + 1)
	wallets["end"] = _wallets()
	_print_shortfall_wallets(short, wallets, days - SETTLE_FROM + 1)
	_print_shares("ore")
	_print_shares("craft")
	_print_outside_crafts()
	_print_factions()
	_print_diplomacy(diplo, int(opts.get("every", 1)))
	_print_turf(turf, summary)
	return summary


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


func _track_ranges(ranges: Dictionary, clamp_days: Dictionary) -> void:
	var cfg: Dictionary = GameData.MARKET
	for kind in Market.KINDS:
		for good_type in GameData.MARKET["goods"][kind]:
			var key: String = kind + ":" + good_type
			var mult := _mult(kind, good_type)
			var r: Array = ranges.get(key, [mult, mult])
			ranges[key] = [minf(r[0], mult), maxf(r[1], mult)]
			var base := float(Market.base_price(kind, good_type))
			var price: int = Market.quote(kind, good_type)
			var c: Array = clamp_days.get(key, [0, 0])
			if price <= GameState.round_epsilon(base * cfg["priceMinMult"]):
				c[0] += 1
			if price >= GameState.round_epsilon(base * cfg["priceMaxMult"]):
				c[1] += 1
			clamp_days[key] = c


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
	# Supply by source comes from salesHistory[0] (today's cleared supply
	# tally: faction sales, moves and the player). Faction buys come from the
	# buy / demand-side move annotations.
	var history: Array = GameState.state["market"].get("salesHistory", [])
	var sold: Dictionary = {}
	if not history.is_empty() and int(history[0]["day"]) == day:
		sold = history[0]["supply"]
	var faction_buys := { "ore": {}, "consumable": {} }
	for note in GameState.state["market"].get("annotations", []):
		if int(note["day"]) != day:
			continue
		var is_buy: bool = note["kind"] == "buy" or (Market.MOVE_SIDES.get(note["kind"], "") == "demand")
		if not is_buy:
			continue
		var by_good: Dictionary = faction_buys[note["goodKind"]]
		by_good[note["good"]] = int(by_good.get(note["good"], 0)) + int(note["value"])
		_add_flow(flows, note["goodKind"], "-" + str(note["source"]), note["good"], float(note["value"]))
	for kind in Market.KINDS:
		for good_type in GameData.MARKET["goods"][kind]:
			var by_source: Dictionary = sold.get(kind, {}).get(good_type, {})
			for source in by_source:
				_add_flow(flows, kind, "+" + str(source), good_type, float(by_source[source]))
			_add_flow(flows, kind, "+independents", good_type, Market.independents_supply(kind, good_type))
			_add_flow(flows, kind, "-nameless", good_type, Market.civilian_demand(kind, good_type) * Market.demand_mult(kind, good_type))
			if kind == "ore":
				_add_flow(flows, kind, "-derived", good_type, Market.derived_ore_demand(good_type))


func _add_flow(flows: Dictionary, kind: String, key: String, good_type: String, qty: float) -> void:
	if not flows.has(kind):
		flows[kind] = {}
	if not flows[kind].has(key):
		flows[kind][key] = {}
	flows[kind][key][good_type] = float(flows[kind][key].get(good_type, 0.0)) + qty


# Per kind: a good x source table of mean daily flow (+ supply, - demand),
# net, and the named share of supply (factions + player vs Independents).
func _print_flows(flows: Dictionary, span: int) -> void:
	for kind in Market.KINDS:
		var goods: Array = GameData.MARKET["goods"][kind].keys()
		print("
-- London %s flows/day, days %d+ (+ supply, - demand) --" % ["ore" if kind == "ore" else "item", SETTLE_FROM])
		var by_key: Dictionary = flows.get(kind, {})
		var keys: Array = by_key.keys()
		keys.sort()
		var header := "%-18s" % "good"
		for key in keys:
			header += "%14s" % key
		print(header + "     net  named%")
		var totals := {}
		var named_all := 0.0
		var supply_all := 0.0
		for good_type in goods:
			var line := "%-18s" % good_type
			var net := 0.0
			var named := 0.0
			var supply := 0.0
			for key in keys:
				var per_day: float = float(by_key[key].get(good_type, 0.0)) / span
				totals[key] = float(totals.get(key, 0.0)) + per_day
				if key.begins_with("+"):
					net += per_day
					supply += per_day
					if key != "+independents":
						named += per_day
				else:
					net -= per_day
				line += "%14.1f" % per_day
			named_all += named
			supply_all += supply
			print(line + "%8.1f%7.0f%%" % [net, 100.0 * named / maxf(supply, 0.001)])
		var total_line := "%-18s" % "ALL"
		for key in keys:
			total_line += "%14.1f" % float(totals.get(key, 0.0))
		print(total_line + "%8s%7.0f%%" % ["", 100.0 * named_all / maxf(supply_all, 0.001)])


# Days each good sat on its price floor / ceiling (settle window).
func _print_clamp_days(clamp_days: Dictionary, span: int) -> void:
	print("\n-- days at min / max price, days %d+ (of %d) --" % [SETTLE_FROM, span])
	for kind in Market.KINDS:
		for good_type in GameData.MARKET["goods"][kind]:
			var c: Array = clamp_days.get(kind + ":" + good_type, [0, 0])
			print("%-18s min %3d  max %3d" % [good_type, c[0], c[1]])


# Mean and end stock per good, by tier. _stock_tiers is the single seam to
# widen once tiered stock exists: it returns { tierLabel: units }.
func _stock_tiers(kind: String, good_type: String) -> Dictionary:
	return { "all": float(GameState.state["market"]["goods"][kind][good_type]["stock"]) }


func _track_stock(stock_sum: Dictionary) -> void:
	for kind in Market.KINDS:
		for good_type in GameData.MARKET["goods"][kind]:
			var key: String = kind + ":" + good_type
			var tiers := _stock_tiers(kind, good_type)
			if not stock_sum.has(key):
				stock_sum[key] = {}
			for tier in tiers:
				stock_sum[key][tier] = float(stock_sum[key].get(tier, 0.0)) + float(tiers[tier])


func _print_stock(stock_sum: Dictionary, span: int) -> void:
	print("\n-- stock by good (mean over days %d+ / end) --" % SETTLE_FROM)
	for kind in Market.KINDS:
		for good_type in GameData.MARKET["goods"][kind]:
			var key: String = kind + ":" + good_type
			var ends := _stock_tiers(kind, good_type)
			var parts: Array = []
			for tier in ends:
				parts.append("%s %.0f/%.0f" % [tier, float(stock_sum.get(key, {}).get(tier, 0.0)) / span, float(ends[tier])])
			print("%-18s normal %4d  %s" % [good_type, int(Market._normal_stock(kind, good_type)), "  ".join(parts)])


# Per faction: mean item units short per day, days with any shortfall, and
# £ wallet at start / day SETTLE_FROM-1 / end with growth per day.
func _track_shortfall(short: Dictionary) -> void:
	for faction_id in GameData.FACTIONS:
		var entry: Dictionary = short.get(faction_id, { "units": 0, "days": 0, "byItem": {} })
		var faction_short: Dictionary = GameState.state["factions"][faction_id]["shortfall"]
		var units := 0
		for recipe_key in faction_short:
			units += int(faction_short[recipe_key])
			entry["byItem"][recipe_key] = int(entry["byItem"].get(recipe_key, 0)) + int(faction_short[recipe_key])
		entry["units"] = int(entry["units"]) + units
		entry["days"] = int(entry["days"]) + (1 if units > 0 else 0)
		short[faction_id] = entry


func _wallets() -> Dictionary:
	var wallets := {}
	for faction_id in GameData.FACTIONS:
		wallets[faction_id] = int(GameState.state["factions"][faction_id]["resources"])
	return wallets


func _print_shortfall_wallets(short: Dictionary, wallets: Dictionary, span: int) -> void:
	print("\n-- faction shortfalls (days %d+) and wallets --" % SETTLE_FROM)
	for faction_id in GameData.FACTIONS:
		var entry: Dictionary = short.get(faction_id, { "units": 0, "days": 0, "byItem": {} })
		var w_start: int = wallets["start"][faction_id]
		var w_mid: int = wallets["mid"].get(faction_id, w_start)
		var w_end: int = wallets["end"][faction_id]
		print("%-11s short %.1f units/day on %d/%d days  £ start %d  d%d %d  end %d  growth %+.1f/day  byItem %s" % [
			faction_id, float(entry["units"]) / span, entry["days"], span,
			w_start, SETTLE_FROM - 1, w_mid, w_end, float(w_end - w_mid) / span, entry["byItem"]])


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


# Units each faction made outside its own crafts / craftTargets, per good.
func _print_outside_crafts() -> void:
	print("
-- outside-craft units (whole run) --")
	for faction_id in GameData.FACTIONS:
		print("%-11s %s" % [faction_id, GameState.state["factions"][faction_id].get("outsideCrafted", {})])


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
			var first_key: String = observer + ">" + target + ":" + ("move:" if what == "move" else "") + entry["warnedBand"]
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
		var market_move: Variant = diplo["firsts"].get(faction_id + ">player:move:market")
		var raid_move: Variant = diplo["firsts"].get(faction_id + ">player:move:raid")
		print("%-11s warning %-4s market-warn %-4s first market move %-4s raid-warn %-4s first raid move %s" % [faction_id, warn, market, market_move, raid, raid_move])
	print("
war endings: %s" % diplo["warEnds"])
	print("min faction veins: %s" % diplo["minVeins"])


# ── Turf ────────────────────────────────────────────────────────────────

const TURF_ZERO_WINDOW := 30  # a faction with no turf this many days at the end is permanently out
const TURF_LEADER_MAX_SHARE := 0.6  # of districts, at the end; above = runaway


# control = districts a faction controls; presence = control or foothold.
func _turf_counts() -> Dictionary:
	var control := {}
	var presence := {}
	for faction_id in GameData.FACTIONS:
		control[faction_id] = 0
		presence[faction_id] = 0
	for district_id in GameState.state["turf"]:
		var entry: Dictionary = GameState.state["turf"][district_id]
		if entry.get("seeded", false):
			continue
		if control.has(entry["controller"]):
			control[entry["controller"]] += 1
		for contender in entry["tiers"]:
			if presence.has(contender):
				presence[contender] += 1
	return { "control": control, "presence": presence }


func _track_turf(turf: Dictionary) -> void:
	var day: int = GameState.state["world"]["day"]
	for district_id in GameState.state["turf"]:
		var entry: Dictionary = GameState.state["turf"][district_id]
		if entry.get("seeded", false):
			continue
		var now: String = entry["controller"]
		if turf["controllers"].has(district_id) and turf["controllers"][district_id] != now:
			turf["flips"] += 1
		turf["controllers"][district_id] = now
	var counts := _turf_counts()
	for faction_id in GameData.FACTIONS:
		var c: int = counts["control"][faction_id]
		var p: int = counts["presence"][faction_id]
		turf["minControl"][faction_id] = mini(int(turf["minControl"].get(faction_id, c)), c)
		turf["minPresence"][faction_id] = mini(int(turf["minPresence"].get(faction_id, p)), p)
		turf["peakControl"][faction_id] = maxi(int(turf["peakControl"].get(faction_id, c)), c)
		if p > 0:
			turf["zeroSince"].erase(faction_id)
		elif not turf["zeroSince"].has(faction_id):
			turf["zeroSince"][faction_id] = day
	turf["series"].append({ "day": day, "control": counts["control"], "presence": counts["presence"] })
	turf["last"] = counts


# { flips, finalControl, finalPresence, permanentZero: [faction], leader, leaderShare,
#   minControl, minPresence, peakControl, runaway: bool }
func _turf_summary(turf: Dictionary, days: int) -> Dictionary:
	var last: Dictionary = turf.get("last", { "control": {}, "presence": {} })
	var permanent_zero: Array = []
	for faction_id in turf["zeroSince"]:
		if days - int(turf["zeroSince"][faction_id]) + 1 >= TURF_ZERO_WINDOW:
			permanent_zero.append(faction_id)
	var leader := ""
	var best := -1
	for faction_id in last["control"]:
		if int(last["control"][faction_id]) > best:
			best = int(last["control"][faction_id])
			leader = faction_id
	var leader_share := float(best) / maxi(1, GameData.DISTRICTS.size())
	return {
		"flips": turf["flips"], "finalControl": last["control"], "finalPresence": last["presence"],
		"permanentZero": permanent_zero, "leader": leader, "leaderShare": leader_share,
		"minControl": turf["minControl"], "minPresence": turf["minPresence"], "peakControl": turf["peakControl"],
		"runaway": leader_share > TURF_LEADER_MAX_SHARE,
	}


func _print_turf(turf: Dictionary, summary: Dictionary) -> void:
	print("
-- turf (districts controlled / present; foothold counts as present) --")
	var series: Array = turf["series"]
	for i in series.size():
		if (i + 1) % 10 != 0:
			continue
		var parts: Array = []
		for faction_id in GameData.FACTIONS:
			parts.append("%s %d/%d" % [_party(faction_id), series[i]["control"][faction_id], series[i]["presence"][faction_id]])
		print("day %-3d %s" % [series[i]["day"], "  ".join(parts)])
	print("flips: %d" % summary["flips"])
	print("min control: %s" % summary["minControl"])
	print("min presence: %s" % summary["minPresence"])
	print("peak control: %s" % summary["peakControl"])
	print("final leader: %s holds %.0f%% of districts%s" % [summary["leader"], 100.0 * summary["leaderShare"], " (RUNAWAY)" if summary["runaway"] else ""])
	print("permanent zero-turf factions: %s" % [summary["permanentZero"]])
