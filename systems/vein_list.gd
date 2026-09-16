class_name VeinList
extends RefCounted

# Pure decision layer for the vein list (spec §6.2); scenes/screens/
# vein_list.gd only ever turns this into Controls, same split as
# systems/district_bubble.gd and systems/station_bubble.gd.

const CULTIVATE_ID := "cultivate"
const PRUNE_LIGHT_ID := "prune_light"
const PRUNE_HARD_ID := "prune_hard"
const MANAGE_ID := "manage"
const SELL_ID := "sell"


# Every player vein, optionally scoped to one district (null = every
# district) and one growth band (null = no filter). Preserves
# state.player.veins' own order.
static func veins(district_id: Variant, band_id: Variant = null) -> Array:
	var result: Array = []
	for vein in GameState.state["player"]["veins"]:
		if district_id != null and vein["district"] != district_id:
			continue
		if band_id != null and Cultivating.growth_band(vein)["id"] != band_id:
			continue
		result.append(vein)
	return result


# { id, disabled, reason } per row action, in display order. Cultivate/Prune
# gating goes through Cultivating.prune_gate(), the shared seam with the map
# sheet and station bubble, so all three surfaces read the same rule.
static func actions_for(vein: Dictionary) -> Array:
	var district: String = vein["district"]
	var at_ceiling: bool = vein["growth"] >= Cultivating.ceiling(vein)

	var cultivate_disabled := true
	var cultivate_reason := ""
	if at_ceiling:
		cultivate_reason = "Vein at ceiling"
	elif not Travel.can_afford(district, 1):
		cultivate_reason = "No blocks left today."
	else:
		cultivate_disabled = false

	var light_gate: Dictionary = Cultivating.prune_gate(vein, GameData.VEIN_GROWTH["pruneLightDepth"], district)
	var hard_gate: Dictionary = Cultivating.prune_gate(vein, GameData.VEIN_GROWTH["pruneHardDepth"], district)

	var actions := [
		{ "id": CULTIVATE_ID, "disabled": cultivate_disabled, "reason": cultivate_reason },
		{ "id": PRUNE_LIGHT_ID, "disabled": light_gate["disabled"], "reason": light_gate["reason"] },
		{ "id": PRUNE_HARD_ID, "disabled": hard_gate["disabled"], "reason": hard_gate["reason"] },
		{ "id": MANAGE_ID, "disabled": false, "reason": "" },
	]

	# spec §5.6: absent until flags.veinSaleUnlocked flips true, then always
	# enabled, no block cost or per-vein gate.
	if GameState.state["flags"].get("veinSaleUnlocked", false):
		actions.append({ "id": SELL_ID, "disabled": false, "reason": "" })

	return actions


# Dispatches through the same Cultivating/Travel calls the Map tab's site
# sheet and station bubble already use. Manage opens the same site/vein
# sheet elsewhere, then switches to the Map tab to show it.
static func apply_option(option_id: String, vein_id: String) -> Dictionary:
	match option_id:
		CULTIVATE_ID:
			var result := Cultivating.cultivate(vein_id)
			return { "ok": result.get("success", result.get("ok", false)) }
		PRUNE_LIGHT_ID:
			var result := Cultivating.prune(vein_id, GameData.VEIN_GROWTH["pruneLightDepth"])
			return { "ok": result.get("ok", false) }
		PRUNE_HARD_ID:
			var result := Cultivating.prune(vein_id, GameData.VEIN_GROWTH["pruneHardDepth"])
			return { "ok": result.get("ok", false) }
		MANAGE_ID:
			var vein: Variant = Cultivating.find_vein(vein_id)
			if vein == null:
				return { "ok": false }
			MapNav.select_site(vein["siteId"])
			Nav.go_to("map")
			return { "ok": true }
		SELL_ID:
			var vein: Variant = Cultivating.find_vein(vein_id)
			if vein == null:
				return { "ok": false }
			# Quote, then confirm (spec §5.6: "losing a vein must never be
			# one tap") -- the sale itself fires from the modal's Confirm button.
			Modal.open("sell_vein_quote", { "veinId": vein_id, "price": VeinTrade.quote(vein), "factionId": VeinTrade.SELL_FACTION_ID })
			return { "ok": true }
		_:
			return { "ok": false }
