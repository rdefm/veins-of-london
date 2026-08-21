class_name StationBubble
extends RefCounted

# 10-map-interaction-model ticket 04: pure decision layer for the station
# (site/vein stop) tap bubble — the same "Node/Tween-side stays out of this"
# split systems/district_bubble.gd already documents for ticket 03. A tapped
# stop only gets Cultivate/Harvest here when it's a player-owned vein (a
# faction vein or an unclaimed site has neither); every other claim state
# just gets Manage, which map.gd routes into the existing site sheet
# unchanged — that sheet already knows how to render the Raid action for a
# faction vein and the Seed action for an unclaimed site (M1-LONDON.md §D2's
# claim-state rules), so this ticket doesn't need to reimplement either of
# those inline in the bubble.
#
# `stop`: one of MapCanvas's own _vein_stops/_faction_stops/_unclaimed_stops
# entries (systems/map_layout.gd's assign_positions shape) — carries "kind"
# ("vein"/"unclaimed"), "site", "vein" (null for "unclaimed"), and "owner"
# ("player", a faction id, or null).

const CULTIVATE_ID := "cultivate"
const HARVEST_CAUTIOUS_ID := "harvest_cautious"
const HARVEST_FULL_ID := "harvest_full"
const MANAGE_ID := "manage"


# { id, disabled, reason } per option, in display order — same shape
# DistrictBubble.district_options() returns; label text is map.gd's own job.
static func station_options(stop: Dictionary) -> Array:
	if stop["kind"] == "vein" and stop.get("owner") == "player":
		return _player_vein_options(stop["vein"])
	return [{ "id": MANAGE_ID, "disabled": false, "reason": "" }]


# Cultivate/Prune gating mirrors scenes/screens/map.gd's existing
# _build_vein_action_card row exactly (at-ceiling and Travel.can_afford
# gates, both Prune depths always offered per ticket 08) so a vein tapped on
# the diagram sees identical rules to the full-screen sheet, just surfaced
# as bubble options instead. Manage is always offered last, unconditionally
# — it's a pure navigation option (opens the sheet), never blocked.
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
		_prune_option(vein, HARVEST_CAUTIOUS_ID, GameData.VEIN_GROWTH["pruneLightDepth"], district),
		_prune_option(vein, HARVEST_FULL_ID, GameData.VEIN_GROWTH["pruneHardDepth"], district),
		{ "id": MANAGE_ID, "disabled": false, "reason": "" },
	]
	return options


# vein-growth-state ticket 08: always offered, never hidden — gated by
# Cultivating.prune_gate() (shared with map.gd's own inline Prune button, so
# the two surfaces can't drift apart on this rule) rather than a growth >
# neutral heuristic, since the two depths' cuts land differently: a vein
# just above neutral can still net a light prune a point or two while a
# hard prune's deeper cut (or vice versa, once terroir/hard-bonus rounding
# is in play) lands entirely at/below neutral. Each depth is therefore
# checked on its own projection, never a single shared comparison.
static func _prune_option(vein: Dictionary, id: String, depth: int, district: String) -> Dictionary:
	var gate: Dictionary = Cultivating.prune_gate(vein, depth, district)
	return { "id": id, "disabled": gate["disabled"], "reason": gate["reason"] }


# Dispatches a tapped bubble option to the same system calls the full-screen
# site sheet already uses (Cultivating.cultivate/prune / MapNav.select_site),
# and reports whether it counts as a success for MapCanvas.play_action_result()'s
# tween. Manage's `ok` is always true (opening the sheet has no fail state) —
# same as DistrictBubble.apply_option()'s View Veins branch. Prune's `ok` is
# just its own "ok" key, always true once dispatched here: pruning never
# rolls to succeed or fail (it's only ever offered here once _prune_option's
# gating lets the button through), so "the action ran" and "it worked" are
# the same thing there — map.gd's tween always plays the success pulse for
# it as a result.
#
# Cultivate is the one branch where `ok` deliberately isn't Cultivating.
# cultivate()'s own "ok" key: that key only means "the action was allowed to
# run at all" (the travel/time gate) — true even on a failed cultivate roll,
# since cultivate() still spends the block and shows its own cultivate_result
# modal either way. What map.gd's play_action_result() tween needs is the
# roll's own outcome, which cultivate() reports separately as "success" —
# present only once the action actually ran, so this falls back to "ok"
# (always false) for the blocked case, where there's no roll to have
# succeeded or failed.
static func apply_option(option_id: String, stop: Dictionary) -> Dictionary:
	match option_id:
		CULTIVATE_ID:
			var result := Cultivating.cultivate(stop["vein"]["id"])
			return { "ok": result.get("success", result.get("ok", false)) }
		HARVEST_CAUTIOUS_ID:
			var result := Cultivating.prune(stop["vein"]["id"], GameData.VEIN_GROWTH["pruneLightDepth"])
			return { "ok": result.get("ok", false) }
		HARVEST_FULL_ID:
			var result := Cultivating.prune(stop["vein"]["id"], GameData.VEIN_GROWTH["pruneHardDepth"])
			return { "ok": result.get("ok", false) }
		MANAGE_ID:
			MapNav.select_site(stop["site"]["id"])
			return { "ok": true }
		_:
			return { "ok": false }
