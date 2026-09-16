class_name VeinTrade
extends RefCounted

# The player's way to *choose* to stop owning a vein, by selling it to a
# faction. quote()/sell_to_faction() are the mechanism only -- which scene
# unlocks the Sell option and which faction(s) have a lane are content
# decisions made elsewhere. sell_to_faction() stays generic on faction_id --
# Hakim's handback reuses it at a forced price of 0.

const SELL_FACTION_ID := "collective"


# Barometer-effective price times terroir times a fixed per-unit rate,
# scaled by how far above/below neutral the vein's growth sits. A fresh
# seed (growth 20) prices at 0.4x, so flipping one straight off loses money
# against its seed cost -- deliberate, so no same-day-sale rule is needed
# to prevent seed-and-flip abuse.
static func quote(vein: Dictionary) -> int:
	var base_price: int = GameData.ORE_TYPES[vein["oreType"]]["basePrice"]
	var ore_price: int = Barometer.get_effective_ore_price(vein["oreType"], base_price)
	var terroir: float = Cultivating.terroir_yield_mult(vein)
	var growth_factor: float = float(vein["growth"]) / float(GameData.VEIN_GROWTH["neutral"])
	return GameState.round_epsilon(ore_price * terroir * GameData.VEIN_GROWTH["veinSaleBaseUnits"] * growth_factor)


# Removes the vein from state.player.veins and re-creates it on its own site
# as site.factionVein via Factions.create_faction_vein(). Stamps
# `soldByPlayer` so Objectives' vein_sold_to_faction evaluator can tell a
# player sale apart from a natural NPC claim or a rivalry capture.
#
# `price_override`: non-null only for Hakim's handback, which reuses this
# path at a forced £0. A forced price means the transfer isn't a genuine
# market sale, so `soldByPlayer` is left false -- otherwise a handback
# could silently satisfy col_a1_nadia_vein and misfire Nadia's dialogue
# over a vein she never touched.
static func sell_to_faction(vein_id: String, faction_id: String, price_override: Variant = null, contact_id: String = "") -> Dictionary:
	var is_handback: bool = price_override != null
	var vein: Variant = Cultivating.find_vein(vein_id)
	var price: int = price_override if is_handback else (quote(vein) if vein != null else 0)

	var result := transfer_to_faction(vein_id, faction_id, price, not is_handback, contact_id)
	if not result.get("ok", false):
		return result

	GameState.state["player"]["cash"] += price
	Bank.record(price, "Sold vein to %s" % faction_id.capitalize())
	EventBus.state_changed.emit()
	return { "ok": true, "price": price, "factionId": faction_id }


# Everything sell_to_faction() above does *except* paying the player.
# Split out so Archie's cut-and-risk lane (Economy.execute_sale) can move
# the vein immediately while the cash payout stays contingent on the
# mugging roll, settled later by Economy.complete_mugged_sale() or the
# non-mugged branch -- sell_to_faction() is just this plus an unconditional
# immediate payout for lanes with no risk attached.
static func transfer_to_faction(vein_id: String, faction_id: String, price: int, count_as_player_sale: bool, contact_id: String = "") -> Dictionary:
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein == null:
		return { "ok": false, "reason": "No such vein." }

	var site: Variant = Sites.find_site(vein["siteId"])
	if site == null:
		return { "ok": false, "reason": "Site not found." }

	var player: Dictionary = GameState.state["player"]
	player["veins"] = player["veins"].filter(func(v): return v["id"] != vein_id)
	Sites.release_vein_slot(vein)

	var faction_vein: Dictionary = Factions.create_faction_vein(faction_id, site, vein["growth"])
	faction_vein["soldByPlayer"] = count_as_player_sale
	site["claimed"] = false
	site["factionVein"] = faction_vein

	MapEvents.queue_seed_claim(site["district"], faction_vein["id"], faction_id)

	# A vein sale's price counts toward the selling faction's tradeProgress
	# like any other trade -- a no-op at price 0 (Hakim's handback). Relation
	# reflects the trade that happened, not what lands in pocket once a
	# mugging roll settles.
	RelationAccrual.accrue_faction(faction_id, price)
	# Same "a trade is a trade" reasoning, for whichever vendor's door this
	# sale went through ("" -- every non-vendor-door caller -- is a no-op).
	if contact_id != "":
		RelationAccrual.accrue_contact_trade(contact_id, price)

	Objectives.refresh()
	# Content-specific hook, same shape Sites.prospect() uses for
	# Collective.maybe_trigger_weather_beat() -- this generic sale lane
	# stays ignorant of which faction/objective it is.
	Collective.maybe_trigger_nadia_vein_done()
	EventBus.state_changed.emit()
	return { "ok": true }


# The exact inverse of sell_to_faction() above: a faction's own site vein
# stops being theirs and re-enters state.player.veins at the same quote()
# price, no cut and no mugging roll. Mirrors transfer_to_faction()'s
# bookkeeping in reverse -- deep_copy the faction vein wholesale (ownership
# changes hands, nothing about the vein itself resets), erase factionId,
# site["claimed"] flips true and site["factionVein"] to null.
#
# Collective.maybe_trigger_nadia_vein_done() is deliberately not called
# here: buying always clears site.factionVein, so it can never itself
# satisfy col_a1_nadia_vein's live-faction-owned-vein requirement.
static func buy_from_faction(vein_id: String, faction_id: String, contact_id: String = "") -> Dictionary:
	var site: Variant = _find_site_with_faction_vein(vein_id, faction_id)
	if site == null:
		return { "ok": false, "reason": "No such vein." }

	var faction_vein: Dictionary = site["factionVein"]
	var price: int = quote(faction_vein)
	var player: Dictionary = GameState.state["player"]
	if player["cash"] < price:
		return { "ok": false, "reason": "Not enough cash." }

	var player_vein: Dictionary = GameState.deep_copy(faction_vein)
	player_vein.erase("factionId")
	player["veins"].append(player_vein)

	site["claimed"] = true
	site["factionVein"] = null

	player["cash"] -= price
	Bank.record(-price, "Bought vein from %s" % faction_id.capitalize())

	MapEvents.queue_seed_claim(site["district"], faction_vein["id"], "player")

	# Same "a trade is a trade" reasoning as transfer_to_faction() -- relation
	# reflects trade volume regardless of which direction the vein moved.
	RelationAccrual.accrue_faction(faction_id, price)
	# Ditto, for the vendor whose door this buy-back went through ("" --
	# map.gd's direct Buy button has no contact conversation -- is a no-op).
	if contact_id != "":
		RelationAccrual.accrue_contact_trade(contact_id, price)

	Objectives.refresh()
	EventBus.state_changed.emit()
	return { "ok": true, "price": price, "factionId": faction_id }


static func _find_site_with_faction_vein(vein_id: String, faction_id: String) -> Variant:
	for site in Sites.sites_with_faction_vein(faction_id):
		if site["factionVein"]["id"] == vein_id:
			return site
	return null
