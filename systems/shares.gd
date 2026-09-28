class_name Shares
extends RefCounted

# Who produces London's calc (R§3.14). Daily buckets per producer per ore
# type for three tallies -- ore harvested, ore used in successful crafts
# (by ingredient weight) and contract deliveries per buyer faction -- kept
# SHARES_DAYS deep. Reads are pure: a producer's share of a tally over the
# current or prior SHARES_WINDOW_DAYS window. Static funcs only.

const TALLIES := ["ore", "craft", "deliveries"]
const PLAYER := "player"
const INDEPENDENTS := "independents"


# player, the five factions (data order), independents.
static func producers() -> Array:
	var ids: Array = [PLAYER]
	ids.append_array(GameData.FACTIONS.keys())
	ids.append(INDEPENDENTS)
	return ids


static func new_state() -> Dictionary:
	return { "days": [] }


# Today's bucket, created on first write: { day, ore:{producer:{type:n}},
# craft:{producer:{type:n}}, deliveries:{factionId:n} }.
static func _today_bucket() -> Dictionary:
	var days: Array = GameState.state["shares"]["days"]
	var day: int = GameState.state["world"]["day"]
	if not days.is_empty() and int(days[-1]["day"]) == day:
		return days[-1]
	var bucket := { "day": day, "ore": {}, "craft": {}, "deliveries": {} }
	days.append(bucket)
	return bucket


static func _add(tally: String, producer: String, ore_type: String, amount: int) -> void:
	if amount <= 0:
		return
	var by_producer: Dictionary = _today_bucket()[tally]
	if not by_producer.has(producer):
		by_producer[producer] = {}
	var by_type: Dictionary = by_producer[producer]
	by_type[ore_type] = int(by_type.get(ore_type, 0)) + amount


# Ore a producer harvested (prune, staff cultivator, faction prune).
static func record_ore(producer: String, ore_type: String, amount: int) -> void:
	_add("ore", producer, ore_type, amount)


# A successful craft's spent ore, { oreType: qty } -- each ingredient
# counts toward its own type by weight. Failed crafts are never recorded.
static func record_craft(producer: String, costs: Dictionary) -> void:
	for ore_type in costs:
		_add("craft", producer, ore_type, int(costs[ore_type]))


# A contract delivery's ore-equivalent quantity, credited to the buyer.
static func record_delivery(faction_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var deliveries: Dictionary = _today_bucket()["deliveries"]
	deliveries[faction_id] = int(deliveries.get(faction_id, 0)) + amount


# Rollover step: drops buckets older than SHARES_DAYS (today included).
static func roll_buckets() -> void:
	var shares: Dictionary = GameState.state["shares"]
	var oldest_kept: int = GameState.state["world"]["day"] - GameData.SHARES_DAYS + 1
	var kept: Array = []
	for bucket in shares["days"]:
		if int(bucket["day"]) >= oldest_kept:
			kept.append(bucket)
	shares["days"] = kept


# Days covered by a window: week 0 = the SHARES_WINDOW_DAYS ending today,
# week 1 = the window before it.
static func _window_range(week: int) -> Vector2i:
	var last: int = GameState.state["world"]["day"] - week * GameData.SHARES_WINDOW_DAYS
	return Vector2i(last - GameData.SHARES_WINDOW_DAYS + 1, last)


# Summed tally over a window: { producer: { oreType: n } }.
static func window_totals(tally: String, week: int = 0) -> Dictionary:
	var span := _window_range(week)
	var totals := {}
	for bucket in GameState.state["shares"]["days"]:
		var day: int = int(bucket["day"])
		if day < span.x or day > span.y:
			continue
		var by_producer: Dictionary = bucket[tally]
		for producer in by_producer:
			if not totals.has(producer):
				totals[producer] = {}
			var by_type: Dictionary = by_producer[producer]
			for ore_type in by_type:
				totals[producer][ore_type] = int(totals[producer].get(ore_type, 0)) + int(by_type[ore_type])
	return totals


# One producer's fraction (0..1) of an ore type's tally over a window; 0
# when nobody produced that type.
static func share(tally: String, producer: String, ore_type: String, week: int = 0) -> float:
	return _share_of(window_totals(tally, week), producer, ore_type)


static func _share_of(totals: Dictionary, producer: String, ore_type: String) -> float:
	var total := 0
	for by_type in totals.values():
		total += int(by_type.get(ore_type, 0))
	if total == 0:
		return 0.0
	return float(totals.get(producer, {}).get(ore_type, 0)) / float(total)


static func ore_share(producer: String, ore_type: String, week: int = 0) -> float:
	return share("ore", producer, ore_type, week)


static func crafting_share(producer: String, ore_type: String, week: int = 0) -> float:
	return share("craft", producer, ore_type, week)


# London overview: { producer: { oreType: fraction } } for every producer
# and ore type, over one tally ("ore" or "craft") and window.
static func overview(tally: String, week: int = 0) -> Dictionary:
	var totals := window_totals(tally, week)
	var table := {}
	for producer in producers():
		var row := {}
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			row[ore_type] = _share_of(totals, producer, ore_type)
		table[producer] = row
	return table


# A good's ore-equivalent quantity: calc 1:1; an item by the sum of its
# recipe's base ingredient weights.
static func ore_equivalent(kind: String, good_type: String, qty: int) -> int:
	if kind == "ore":
		return qty
	var weight := 0
	for ore_type in GameData.RECIPES[good_type]["ingredients"]:
		weight += int(GameData.RECIPES[good_type]["ingredients"][ore_type])
	return qty * weight


# Per-faction totals of a { factionId: n } bucket key over a window; a
# bucket without the key counts as empty.
static func _faction_totals(key: String, week: int) -> Dictionary:
	var span := _window_range(week)
	var totals := {}
	for bucket in GameState.state["shares"]["days"]:
		var day: int = int(bucket["day"])
		if day < span.x or day > span.y:
			continue
		var by_faction: Dictionary = bucket.get(key, {})
		for faction_id in by_faction:
			totals[faction_id] = int(totals.get(faction_id, 0)) + int(by_faction[faction_id])
	return totals


# Player contract deliveries per buyer faction over a window, ore-equivalent.
static func deliveries(week: int = 0) -> Dictionary:
	return _faction_totals("deliveries", week)


# Each faction's London buys over a window, ore-equivalent ("londonBuys").
static func london_buys(week: int = 0) -> Dictionary:
	return _faction_totals("londonBuys", week)


# Supplier share read A: player deliveries to the faction ÷ all player
# contract deliveries over the window; 0 when the player delivered nothing.
static func delivery_split(faction_id: String, week: int = 0) -> float:
	var totals := deliveries(week)
	var total := 0
	for amount in totals.values():
		total += int(amount)
	if total == 0:
		return 0.0
	return float(totals.get(faction_id, 0)) / float(total)


# Supplier share read B: player deliveries to the faction ÷ its total
# intake (those deliveries + its London buys) over the window; 0 when the
# faction took nothing in.
static func intake_share(faction_id: String, week: int = 0) -> float:
	var delivered: int = int(deliveries(week).get(faction_id, 0))
	var intake: int = delivered + int(london_buys(week).get(faction_id, 0))
	if intake == 0:
		return 0.0
	return float(delivered) / float(intake)
