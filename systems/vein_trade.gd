class_name VeinTrade
extends RefCounted

# collective1-05, spec.md §5.6: the first way to *choose* to stop owning a
# vein. quote()/sell_to_faction() are the mechanism only -- which scene
# unlocks the Sell option (flags.veinSaleUnlocked, set by ticket 12's S9)
# and the fact that "collective" is the only faction with a lane in Act 1
# (systems/vein_list.gd targets SELL_FACTION_ID below as the buyer) are
# content decisions made elsewhere. sell_to_faction() itself stays generic
# on faction_id -- ticket 14's handback-to-Hakim reuses it at price 0.

const SELL_FACTION_ID := "collective"


# Barometer-effective price (Barometer.get_effective_ore_price, the same
# wrapper every other sale lane in the game uses) times terroir times the
# fixed per-unit rate, scaled by how far above/below neutral the vein's
# growth sits. Matches spec §8.3's worked table exactly (VEIN_SALE_BASE_UNITS
# = 35, GameData.VEIN_GROWTH.neutral = 50): a fresh seed (growth 20) prices
# at 0.4x, so flipping one straight off loses money against its 40-ore seed
# cost -- the deliberate "no same-day-sale rule needed" guard the spec calls
# out.
static func quote(vein: Dictionary) -> int:
	var base_price: int = GameData.ORE_TYPES[vein["oreType"]]["basePrice"]
	var ore_price: int = Barometer.get_effective_ore_price(vein["oreType"], base_price)
	var terroir: float = Cultivating.terroir_yield_mult(vein)
	var growth_factor: float = float(vein["growth"]) / float(GameData.VEIN_GROWTH["neutral"])
	return GameState.round_epsilon(ore_price * terroir * GameData.VEIN_GROWTH["veinSaleBaseUnits"] * growth_factor)


# Removes the vein from state.player.veins and re-creates it on its own site
# as site.factionVein via Factions.create_faction_vein() -- oreType and
# hospitability come from the site (which is where the sold vein got them
# from in the first place), growth is passed through unchanged. Stamps
# `soldByPlayer` so Objectives' vein_sold_to_faction evaluator (systems/
# objectives.gd) can tell a player sale apart from a natural NPC claim or a
# rivalry capture landing the same faction on the same ore type. price=0 is
# a valid, deliberate call (ticket 14's Hakim handback) -- no minimum-price
# guard here; the caller decides what to charge.
static func sell_to_faction(vein_id: String, faction_id: String) -> Dictionary:
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein == null:
		return { "ok": false, "reason": "No such vein." }

	var site: Variant = Sites.find_site(vein["siteId"])
	if site == null:
		return { "ok": false, "reason": "Site not found." }

	var price: int = quote(vein)

	var player: Dictionary = GameState.state["player"]
	player["veins"] = player["veins"].filter(func(v): return v["id"] != vein_id)
	player["cash"] += price
	Bank.record(price, "Sold vein to %s" % faction_id.capitalize())

	var faction_vein: Dictionary = Factions.create_faction_vein(faction_id, site, vein["growth"])
	faction_vein["soldByPlayer"] = true
	site["claimed"] = false
	site["factionVein"] = faction_vein

	MapEvents.queue_seed_claim(site["district"], faction_vein["id"], faction_id)

	# collective1-06, spec §8.4: a vein sale's price counts toward the
	# selling faction's tradeProgress exactly like any other trade -- a
	# no-op at price 0 (ticket 14's Hakim handback) and for factions
	# RelationAccrual.LANES doesn't configure a rate for.
	RelationAccrual.accrue_faction(faction_id, price)

	Objectives.refresh()  # collective1-05: boundary — vein sale completion
	EventBus.state_changed.emit()
	return { "ok": true, "price": price, "factionId": faction_id }
