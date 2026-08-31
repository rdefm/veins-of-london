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
# rivalry capture landing the same faction on the same ore type.
#
# `price_override` (ticket 14, spec §6.12): non-null only for Hakim's
# handback, which reuses this exact code path at a forced £0 rather than
# a separate mechanism. A forced price also means the transfer is not a
# genuine market sale, so `soldByPlayer` is left false for it -- otherwise
# a handback could silently satisfy col_a1_nadia_vein (factionId + oreType
# is all that objective checks) if the two ever shared an ore type, and
# misfire col_a1_nadia_done with Nadia's dialogue over a vein she never
# touched.
static func sell_to_faction(vein_id: String, faction_id: String, price_override: Variant = null) -> Dictionary:
	var is_handback: bool = price_override != null
	var vein: Variant = Cultivating.find_vein(vein_id)
	var price: int = price_override if is_handback else (quote(vein) if vein != null else 0)

	var result := transfer_to_faction(vein_id, faction_id, price, not is_handback)
	if not result.get("ok", false):
		return result

	GameState.state["player"]["cash"] += price
	Bank.record(price, "Sold vein to %s" % faction_id.capitalize())
	EventBus.state_changed.emit()
	return { "ok": true, "price": price, "factionId": faction_id }


# vein-trade-assets ticket 02: everything sell_to_faction() above does
# *except* paying the player -- the vein leaving player.veins, the site
# handoff, the faction-vein re-creation, the map event, tradeProgress
# accrual, and the objective/content boundary hooks. Split out so Archie's
# cut-and-risk lane (Economy.execute_sale) can move the vein immediately
# ("goods leave the player's hands as part of executing the sale", same as
# ore/consumables in that lane) while the cash payout itself stays
# contingent on the mugging roll, settled later by Economy.complete_mugged_sale()
# or the non-mugged branch -- sell_to_faction() above is just this plus an
# unconditional, immediate cash payout for lanes with no risk attached.
static func transfer_to_faction(vein_id: String, faction_id: String, price: int, count_as_player_sale: bool) -> Dictionary:
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

	# collective1-06, spec §8.4: a vein sale's price counts toward the
	# selling faction's tradeProgress exactly like any other trade -- a
	# no-op at price 0 (ticket 14's Hakim handback) and for factions
	# RelationAccrual.LANES doesn't configure a rate for. Accrued here,
	# unconditionally, same reasoning Economy.execute_sale's own
	# RelationAccrual.accrue_archie(gross) call uses for ore/consumables:
	# relation reflects the trade that happened, not what actually landed
	# in pocket once a mugging roll settles.
	RelationAccrual.accrue_faction(faction_id, price)

	Objectives.refresh()  # collective1-05: boundary — vein sale completion
	# collective1-12, spec §6.10: content-specific hook, same shape Sites.
	# prospect() uses for Collective.maybe_trigger_weather_beat() -- this
	# generic sale lane stays ignorant of which faction/objective it is.
	Collective.maybe_trigger_nadia_vein_done()
	EventBus.state_changed.emit()
	return { "ok": true }


# vein-trade-assets ticket 03: the exact inverse of sell_to_faction() above --
# a faction's own site vein stops being theirs and re-enters
# state.player.veins, at the same VeinTrade.quote() price the sell lane uses
# (no markup either direction), no cut and no mugging roll (the "no cut, no
# risk" rule the faction lane already applies to ore/items). Mirrors
# transfer_to_faction()'s bookkeeping in reverse -- Raiding.claim_vein()'s
# faction-to-player transfer is the closer precedent than sell_to_faction()
# itself: deep_copy the faction vein wholesale (growth/oreType/hospitability/
# security/alarmUpgrades/rampantDays/extraGuards carried over unchanged, same
# "ownership changes hands, nothing about the vein itself resets" convention),
# erase factionId, site["claimed"] flips to true and site["factionVein"] to
# null (claim_vein()'s own pair, not sell's claimed=false/factionVein=<new>).
# No soldByPlayer-equivalent stamp: Objectives' vein_sold_to_faction evaluator
# only cares whether a *player* sale is currently live on the site, and buying
# the vein back always clears site.factionVein regardless, so there's nothing
# for a marker to guard here.
#
# Collective.maybe_trigger_nadia_vein_done() is deliberately NOT called here
# -- it's a sale-completion hook (spec §6.10), and buying can never itself
# complete col_a1_nadia_vein (that objective requires a *live* faction-owned
# vein with soldByPlayer set; buying always clears site.factionVein instead).
static func buy_from_faction(vein_id: String, faction_id: String) -> Dictionary:
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

	# Same "a trade is a trade" reasoning transfer_to_faction()'s own call
	# uses -- relation/tradeProgress reflects trade volume with the faction,
	# regardless of which direction the vein moved.
	RelationAccrual.accrue_faction(faction_id, price)

	Objectives.refresh()  # boundary — vein purchase completion
	EventBus.state_changed.emit()
	return { "ok": true, "price": price, "factionId": faction_id }


static func _find_site_with_faction_vein(vein_id: String, faction_id: String) -> Variant:
	for site in Sites.sites_with_faction_vein(faction_id):
		if site["factionVein"]["id"] == vein_id:
			return site
	return null
