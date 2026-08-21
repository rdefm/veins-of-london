class_name VeinList
extends RefCounted

# vein-growth-state ticket 09 (spec §6.2): pure decision layer for the vein
# list -- same "Node/Tween-side stays out of this" split systems/
# district_bubble.gd and systems/station_bubble.gd already draw for the map's
# other two vein-facing surfaces. scenes/screens/vein_list.gd only ever turns
# this into Controls; it never computes gating or dispatches itself.

const CULTIVATE_ID := "cultivate"
const PRUNE_LIGHT_ID := "prune_light"
const PRUNE_HARD_ID := "prune_hard"
const MANAGE_ID := "manage"


# Every player vein, optionally scoped to one district (null -- the HQ Vein
# Station entry point's "every district" scope) and one growth band (null --
# no filter, the district bubble's own default). Order matches
# state.player.veins' own order; no implicit sort, so district-scoped
# results still read in the same order the map's district panel lists them.
static func veins(district_id: Variant, band_id: Variant = null) -> Array:
	var result: Array = []
	for vein in GameState.state["player"]["veins"]:
		if district_id != null and vein["district"] != district_id:
			continue
		if band_id != null and Cultivating.growth_band(vein)["id"] != band_id:
			continue
		result.append(vein)
	return result


# { id, disabled, reason } per row action, in display order -- same shape
# DistrictBubble.district_options()/StationBubble.station_options() return.
# Cultivate/Prune gating is identical to the map sheet's own
# _build_vein_action_card and the station bubble (Cultivating.prune_gate() is
# the shared seam), so all three surfaces read the same rule. Manage is
# always offered, unconditionally, same as everywhere else it appears.
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

	return [
		{ "id": CULTIVATE_ID, "disabled": cultivate_disabled, "reason": cultivate_reason },
		{ "id": PRUNE_LIGHT_ID, "disabled": light_gate["disabled"], "reason": light_gate["reason"] },
		{ "id": PRUNE_HARD_ID, "disabled": hard_gate["disabled"], "reason": hard_gate["reason"] },
		{ "id": MANAGE_ID, "disabled": false, "reason": "" },
	]


# Dispatches to the same Cultivating functions (and therefore the same
# Travel.ensure_district call) the Map tab's site/vein sheet and station
# bubble already use -- a convenience layer over the existing rules, never a
# second code path. Manage opens the same site/vein sheet Manage opens
# everywhere else (MapNav.select_site, unchanged), then switches to the Map
# tab to show it, since the list is its own separate screen.
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
		_:
			return { "ok": false }
