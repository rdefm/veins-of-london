class_name DistrictBubble
extends RefCounted

# Pure decision layer for the district tap bubble (Prospect / View Veins).
# The Prospect disabled/reason rules mirror scenes/screens/map.gd's
# _build_district_actions district-panel row exactly, so a district tapped
# on the diagram sees identical rules to the full-screen panel. Kept out of
# scenes/components/map_canvas.gd (Node/Tween-side, untestable headless) so
# gating/dispatch stays unit-testable without a live scene tree.

const PROSPECT_ID := "prospect"
const VIEW_VEINS_ID := "view_veins"
# Opens the vein list (systems/vein_list.gd) scoped to this district -- the
# district-bubble entry point (HQ's Vein Station room is the other).
const LIST_ID := "list_view"


# { id, disabled, reason } per option, in display order -- label text is the
# screen's own job (UI.format_block_cost_label etc.; systems/ never touches
# UI.*).
static func district_options(district_id: String) -> Array:
	var district: Dictionary = GameData.DISTRICTS[district_id]
	var site_cap: int = district.get("siteCap", 0)

	var prospect_disabled := true
	var prospect_reason := ""
	if site_cap <= 0:
		prospect_reason = "No prospecting here"
	elif not GameState.state["flags"]["cultivationTutorialSeen"]:
		prospect_reason = "Prospecting — see Archie first"
	elif not Travel.can_afford(district_id, 1):
		prospect_reason = "No blocks left today."
	else:
		prospect_disabled = false

	return [
		{ "id": PROSPECT_ID, "disabled": prospect_disabled, "reason": prospect_reason },
		{ "id": VIEW_VEINS_ID, "disabled": false, "reason": "" },
		{ "id": LIST_ID, "disabled": false, "reason": "" },
	]


# Dispatches a tapped bubble option to the same system calls the full-screen
# district panel uses, reporting success for MapCanvas.play_prospect_result()'s
# tween. `ok` for view_veins is always true (no fail state).
static func apply_option(option_id: String, district_id: String) -> Dictionary:
	match option_id:
		PROSPECT_ID:
			var result := Sites.prospect(district_id)
			return { "ok": result.get("ok", false) }
		VIEW_VEINS_ID:
			MapNav.select_district(district_id)
			return { "ok": true }
		LIST_ID:
			VeinListNav.open_for_district(district_id)
			Nav.go_to("vein_list")
			return { "ok": true }
		_:
			return { "ok": false }
