class_name StationBubble
extends RefCounted

# Pure decision layer for the station (site/vein stop) tap bubble — same
# "Node/Tween-side stays out of this" split as systems/district_bubble.gd.
# A tapped stop only gets Cultivate/Prune here when it's a player-owned vein
# (a faction vein or an unclaimed site has neither); every other claim state
# just gets Manage, which map.gd routes into the site sheet — that sheet
# already renders Raid for a faction vein and Seed for an unclaimed site
# (M1-LONDON §D2's claim-state rules).
#
# `stop`: one of MapCanvas's _vein_stops/_faction_stops/_unclaimed_stops
# entries (map_layout.gd's assign_positions shape) — "kind"
# ("vein"/"unclaimed"), "site", "vein" (null for "unclaimed"), "owner"
# ("player", a faction id, or null).

const CULTIVATE_ID := "cultivate"
const PRUNE_LIGHT_ID := "prune_light"
const PRUNE_HARD_ID := "prune_hard"
const MANAGE_ID := "manage"


# { id, disabled, reason } per option, in display order — same shape
# DistrictBubble.district_options() returns; label text is map.gd's own job.
static func station_options(stop: Dictionary) -> Array:
	if stop["kind"] == "vein" and stop.get("owner") == "player":
		return _player_vein_options(stop["vein"])
	return [{ "id": MANAGE_ID, "disabled": false, "reason": "" }]


# Cultivate/Prune gating mirrors map.gd's _build_vein_action_card row
# exactly (at-ceiling and Travel.can_afford gates; both Prune depths always
# offered) so a diagram tap sees identical rules to the full-screen sheet.
# Manage is always offered last, unconditionally — pure navigation, never blocked.
static func _player_vein_options(vein: Dictionary) -> Array:
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

	var options: Array = [
		{ "id": CULTIVATE_ID, "disabled": cultivate_disabled, "reason": cultivate_reason },
		_prune_option(vein, PRUNE_LIGHT_ID, GameData.VEIN_GROWTH["pruneLightDepth"], district),
		_prune_option(vein, PRUNE_HARD_ID, GameData.VEIN_GROWTH["pruneHardDepth"], district),
		{ "id": MANAGE_ID, "disabled": false, "reason": "" },
	]
	return options


# Always offered, never hidden — gated by Cultivating.prune_gate() (shared
# with map.gd's inline Prune button so the two surfaces can't drift apart)
# rather than a growth > neutral heuristic, since the two depths' cuts land
# differently; each depth is checked on its own projection.
static func _prune_option(vein: Dictionary, id: String, depth: int, district: String) -> Dictionary:
	var gate: Dictionary = Cultivating.prune_gate(vein, depth, district)
	return { "id": id, "disabled": gate["disabled"], "reason": gate["reason"] }


# Dispatches a tapped bubble option to the same system calls the full-screen
# site sheet uses, and reports whether it counts as a success for
# MapCanvas.play_action_result()'s tween. Manage's `ok` is always true (no
# fail state). Prune's `ok` is just its own "ok" key — pruning never rolls
# to succeed/fail, so "the action ran" and "it worked" are the same thing.
# Cultivate is the one branch where `ok` deliberately isn't Cultivating.
# cultivate()'s own "ok" key, which only means the travel/time gate passed
# (true even on a failed roll) — the tween needs the roll's own outcome,
# reported as "success", falling back to "ok" (always false) when blocked
# and there's no roll at all.
static func apply_option(option_id: String, stop: Dictionary) -> Dictionary:
	match option_id:
		CULTIVATE_ID:
			var result := Cultivating.cultivate(stop["vein"]["id"])
			return { "ok": result.get("success", result.get("ok", false)) }
		PRUNE_LIGHT_ID:
			var result := Cultivating.prune(stop["vein"]["id"], GameData.VEIN_GROWTH["pruneLightDepth"])
			return { "ok": result.get("ok", false) }
		PRUNE_HARD_ID:
			var result := Cultivating.prune(stop["vein"]["id"], GameData.VEIN_GROWTH["pruneHardDepth"])
			return { "ok": result.get("ok", false) }
		MANAGE_ID:
			MapNav.select_site(stop["site"]["id"])
			return { "ok": true }
		_:
			return { "ok": false }
