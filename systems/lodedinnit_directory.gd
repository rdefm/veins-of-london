# LodedInnit People directory projection: enabled-role groups in roster order,
# narrowed by Role and ore specialism, optionally wage-sorted within each group.
# Pure reads of Hiring; the app holds the filter/sort choice as view state.
class_name LodedInnitDirectory
extends RefCounted

const ALL := "all"
const WAGE_ROSTER := "roster"
const WAGE_DESC := "desc"
const WAGE_ASC := "asc"


# Next wage order on a tap: roster -> high to low -> low to high -> alternate.
static func next_wage_order(current: String) -> String:
	return WAGE_ASC if current == WAGE_DESC else WAGE_DESC


# [{ id, label }] -- All plus one plural entry per enabled role with candidates.
static func role_options() -> Array:
	var options: Array = [{ "id": ALL, "label": "All" }]
	for role_id in _enabled_role_ids():
		options.append({ "id": role_id, "label": "%ss" % GameData.HIRING_ROLES[role_id]["label"] })
	return options


# [{ id, label }] -- All plus the five canonical ores.
static func ore_options() -> Array:
	var options: Array = [{ "id": ALL, "label": "All" }]
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		options.append({ "id": ore_type, "label": ore_type.capitalize() })
	return options


# [{ role_id, label, ids }] -- groups with at least one match, role label plural.
static func groups(role_filter: String, ore_filter: String, wage_order: String) -> Array:
	var result: Array = []
	for role_id in _enabled_role_ids():
		if role_filter != ALL and role_filter != role_id:
			continue
		var ids: Array = []
		for candidate_id in Hiring.candidate_ids():
			if Hiring.candidate(candidate_id)["role"] == role_id and _matches_ore(candidate_id, ore_filter):
				ids.append(candidate_id)
		if wage_order != WAGE_ROSTER:
			ids = _sorted_by_wage(ids, wage_order == WAGE_DESC)
		if not ids.is_empty():
			result.append({ "role_id": role_id, "label": "%ss" % GameData.HIRING_ROLES[role_id]["label"], "ids": ids })
	return result


static func visible_count(group_list: Array) -> int:
	var total := 0
	for group in group_list:
		total += (group["ids"] as Array).size()
	return total


static func _enabled_role_ids() -> Array:
	var ids: Array = []
	for candidate_id in Hiring.candidate_ids():
		var role_id: String = Hiring.candidate(candidate_id)["role"]
		if not ids.has(role_id):
			ids.append(role_id)
	return ids


static func _matches_ore(candidate_id: String, ore_filter: String) -> bool:
	return ore_filter == ALL or (Hiring.candidate(candidate_id).get("specialities", []) as Array).has(ore_filter)


# Stable: equal wages keep roster order.
static func _sorted_by_wage(ids: Array, descending: bool) -> Array:
	var keyed: Array = []
	for i in ids.size():
		keyed.append({ "id": ids[i], "wage": Hiring.weekly_wage(ids[i]), "i": i })
	keyed.sort_custom(func(a, b):
		if a["wage"] != b["wage"]:
			return a["wage"] > b["wage"] if descending else a["wage"] < b["wage"]
		return a["i"] < b["i"])
	var sorted_ids: Array = []
	for entry in keyed:
		sorted_ids.append(entry["id"])
	return sorted_ids
