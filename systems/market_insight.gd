class_name MarketInsight
extends RefCounted

# The market row `!` (R§3.13 "Insight"): every source reads the shared
# projection (Market.projected_quotes) and returns lines per good, plus
# whether the good is notable (projected move >= insightNotableMove of today's
# quote). Sources sit side by side; none overrides another. Sources: Fate
# gut feeling, Prophet's Breath market read. Read-only.


# Every good with something to say:
# { kind: { good_type: { "lines": [String], "notable": bool } } }.
static func reads() -> Dictionary:
	var result := {}
	if not fate_active() and not breath_active():
		return result
	var projected := Market.projected_quotes()
	for source in [_fate_reads(projected), _breath_reads(projected)]:
		for kind in source:
			for good_type in source[kind]:
				var read: Dictionary = source[kind][good_type]
				var merged: Dictionary = result.get_or_add(kind, {}).get_or_add(good_type, { "lines": [], "notable": false })
				merged["lines"].append_array(read["lines"])
				merged["notable"] = merged["notable"] or read["notable"]
	return result


# One good's merged read out of reads(); empty lines when no source spoke.
static func read_for(reads_by_kind: Dictionary, kind: String, good_type: String) -> Dictionary:
	return reads_by_kind.get(kind, {}).get(good_type, { "lines": [], "notable": false })


# Projected move as a fraction of today's quote (0.0 at a quote of 0).
static func move_fraction(projected: Dictionary, kind: String, good_type: String) -> float:
	var today := Market.quote(kind, good_type)
	if today <= 0:
		return 0.0
	return float(int(projected[kind][good_type]) - today) / float(today)


static func is_notable(projected: Dictionary, kind: String, good_type: String) -> bool:
	return absf(move_fraction(projected, kind, good_type)) >= float(GameData.MARKET["insightNotableMove"])


# ── Fate gut feeling (R§1.4 Lenses, Fate world sight) ──

# A loaded Fate Lens at Sense >= senseGates.world.
static func fate_active() -> bool:
	return Lenses.has("fate") and Lenses.sense_unlocked("world")


# Notable moves only, direction only. Held goods (shared or stash, single or
# multi): a fall
# reads "sell soon", a rise "hold on". Unheld goods: the fateMarketReadsByTier
# biggest notable |moves| at the Lens tier.
static func _fate_reads(projected: Dictionary) -> Dictionary:
	var result := {}
	if not fate_active():
		return result
	var copy: Dictionary = GameData.DIAL_LENS["fateMarket"]
	var unheld: Array = []
	for kind in projected:
		for good_type in projected[kind]:
			if not is_notable(projected, kind, good_type):
				continue
			var rising := move_fraction(projected, kind, good_type) > 0.0
			if _held(kind, good_type):
				_add_line(result, kind, good_type, copy["heldRising" if rising else "heldFalling"])
			else:
				unheld.append({ "kind": kind, "type": good_type, "size": absf(move_fraction(projected, kind, good_type)), "rising": rising })
	unheld.sort_custom(func(a, b): return a["size"] > b["size"])
	var curve: Array = GameData.DIAL_LENS["fateMarketReadsByTier"]
	var count: int = int(curve[clampi(Lenses.tier_for("fate"), 0, curve.size() - 1)])
	for i in mini(count, unheld.size()):
		var pick: Dictionary = unheld[i]
		_add_line(result, pick["kind"], pick["type"], copy["rising" if pick["rising"] else "falling"])
	return result


static func _held(kind: String, good_type: String) -> bool:
	if kind == "ore":
		return Stash.player_ore_qty(good_type) > 0
	return Stash.player_item_qty(good_type) + Stash.player_item_qty(Crafting.inventory_key(good_type, true)) > 0


static func _add_line(result: Dictionary, kind: String, good_type: String, line: String) -> void:
	result.get_or_add(kind, {})[good_type] = { "lines": [line], "notable": true }


# ── Prophet's Breath market read (R§3.13 Insight) ──

static func breath_active() -> bool:
	return ActiveEffects.prophets_breath_active()


# Half-width of the band as a fraction of the projection, by the running
# Breath's level; 0.0 when none runs.
static func breath_band_width() -> float:
	var effect = ActiveEffects.find(ActiveEffects.PROPHETS_BREATH)
	if effect == null:
		return 0.0
	var table: Array = GameData.ACTIVE_EFFECTS[ActiveEffects.PROPHETS_BREATH]["marketBandByLevel"]
	return float(table[clampi(int(effect["level"]), 1, table.size() - 1)])


# [low, high] £ around a projected quote at the running Breath's width.
static func breath_band(projected_quote: int) -> Array:
	var width := breath_band_width()
	return [maxi(0, GameState.round_epsilon(projected_quote * (1.0 - width))), GameState.round_epsilon(projected_quote * (1.0 + width))]


# Every good reads its band; notable as the shared threshold says.
static func _breath_reads(projected: Dictionary) -> Dictionary:
	var result := {}
	if not breath_active():
		return result
	var line: String = GameData.ACTIVE_EFFECTS[ActiveEffects.PROPHETS_BREATH]["marketLine"]
	for kind in projected:
		var lot := Market.price_lot(kind)
		var suffix := "" if lot <= 1 else "/%d" % lot
		for good_type in projected[kind]:
			var band := breath_band(int(projected[kind][good_type]))
			var text := line % ("£%d–£%d%s" % [band[0], band[1], suffix])
			result.get_or_add(kind, {})[good_type] = { "lines": [text], "notable": is_notable(projected, kind, good_type) }
	return result
