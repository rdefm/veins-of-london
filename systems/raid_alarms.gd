class_name RaidAlarms
extends RefCounted

# Read-only projection of actionable pending-defence state. The pending raid
# records remain the sole source of truth; this module gives Phone, TopBar and
# BizBrief one stable presentation/navigation contract without duplicating
# resolution state.


static func summary_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if Home.has_pending_raid():
		var notification_id: Variant = GameState.state["home"].get("pendingRaidNotificationId")
		rows.append({
			"id": "home:%s" % str(notification_id),
			"kind": "home",
			"title": "HQ",
			"district": "Home",
			"deadline": _deadline_label(),
			"consequence": "If undefended: carried calc may be stolen.",
		})

	for outcome in GameState.state["world"].get("pendingDefendRaids", []):
		var vein: Variant = Cultivating.find_vein(outcome.get("veinId", ""))
		if vein == null:
			continue
		var outcome_type: String = outcome.get("outcomeType", "claim")
		var consequence := "If undefended: the vein is taken."
		if outcome_type == "loot":
			consequence = "If undefended: up to %d calc stolen; growth −%d." % [Raiding.RAID_LOOT_ORE_QTY, Raiding.RAID_LOOT_PRUNE_DEPTH]
		var notification_id: String = str(outcome.get("notificationId", ""))
		var situation_id := notification_id if not notification_id.is_empty() else "%s:%s" % [outcome.get("siteId", ""), outcome.get("veinId", "")]
		rows.append({
			"id": "vein:%s" % situation_id,
			"kind": "vein",
			"veinId": vein["id"],
			"title": "%s vein · %s" % [GameData.ORE_TYPES[vein["oreType"]]["name"], vein["location"]],
			"district": GameData.DISTRICTS[vein["district"]]["name"],
			"deadline": _deadline_label(),
			"consequence": consequence,
		})
	return rows


static func count() -> int:
	return summary_rows().size()


static func has_unresolved() -> bool:
	return count() > 0


static func defend(situation_id: String) -> bool:
	for row in summary_rows():
		if row["id"] != situation_id:
			continue
		if row["kind"] == "home":
			return Home.trigger_defend()
		return Raiding.trigger_defend(row["veinId"])
	return false


# Confirmation invokes this operation, not a captured outcome dict -- it
# re-derives the live row, so a stale/duplicate response can't resolve a
# different raid or apply a second consequence.
static func leave_undefended(situation_id: String) -> bool:
	for row in summary_rows():
		if row["id"] != situation_id or row["kind"] != "vein":
			continue
		var notification_id := situation_id.trim_prefix("vein:")
		return Raiding.leave_undefended(row["veinId"], notification_id)
	return false


static func open() -> void:
	PhoneNav.open_app("alarms")


static func _deadline_label() -> String:
	return "By end of Day %d" % GameState.state["world"]["day"]
