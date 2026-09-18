class_name MapLayout
extends RefCounted

# Resolves data/map_layout.json's per-district stopSlots against live state
# into concrete stop positions for scenes/components/map_canvas.gd
# (docs/M1.5-NETWORK-MAP.md N3). Read-only, like systems/districts.gd.
#
# A "stop" isn't 1:1 with a site: an unclaimed or faction-claimed site is
# always one stop, but a player-claimed site can carry a second stop (its
# saturated-site bonus natural vein). map_layout.json's stopSlots buffer is
# siteCap*2 to cover every capped site double-stopping at once. Stops
# occupy slots in discovery order.


# Pure: turns a district's sites + the full player veins list into ordered
# stop items (no positions yet), kept separate from assign_slots() so tests
# can exercise discovery-order occupancy without touching GameData/GameState.
# "vein" stops carry an "owner" key ("player" or a faction id); both draw
# the same shape (circle), just in the owner's colour.
#
# Each item carries the "slotIndex" assign_positions() keys off of, not its
# position in this array, so a stop's slot stays fixed for its life
# regardless of what else changes in the district. A claimed site's second
# (bonus) vein stamps its own slotIndex since it's a separate stop needing
# its own permanent slot. Read via .get(...,0) so minimal test fixtures
# degrade to "everyone piles on slot 0" rather than crash.
static func build_stop_items(sites: Array, veins: Array) -> Array:
	var items: Array = []
	for site in sites:
		var site_id: String = site["id"]
		if site.get("factionVein") != null:
			items.append({ "kind": "vein", "site": site, "vein": site["factionVein"], "owner": site["factionVein"]["factionId"], "slotIndex": site.get("slotIndex", 0) })
			_append_surviving_bonus_veins(items, site, veins, site_id)
		elif site.get("claimed", false):
			for vein in veins:
				if vein.get("siteId") == site_id:
					items.append(_player_vein_stop(site, vein, vein.get("slotIndex", site.get("slotIndex", 0))))
		else:
			items.append({ "kind": "unclaimed", "site": site, "vein": null, "owner": null, "slotIndex": site.get("slotIndex", 0) })
			_append_surviving_bonus_veins(items, site, veins, site_id)
	return items


static func _player_vein_stop(site: Dictionary, vein: Dictionary, slot_index: int) -> Dictionary:
	return { "kind": "vein", "site": site, "vein": vein, "owner": "player", "slotIndex": slot_index }


# A site's two veins (the claimed one plus its saturated-site bonus) can
# diverge in ownership independently, so a stop keyed only on the site's
# top-level status can miss a live vein still attached to the same siteId.
# The "elif claimed" branch above doesn't need this — it already iterates
# every vein matching that site.
static func _append_surviving_bonus_veins(items: Array, site: Dictionary, veins: Array, site_id: String) -> void:
	for vein in veins:
		if vein.get("siteId") == site_id and vein.has("slotIndex"):
			items.append(_player_vein_stop(site, vein, vein["slotIndex"]))


# Pure: maps each stop item onto its slot's position, keyed by the item's
# own stamped "slotIndex" rather than its position in `items`. Clamps any
# slotIndex beyond the slot list onto the last slot — defensive only, since
# Sites.release_slot_index()/next_slot_index() recycle freed indices and
# keep a district's live stop count within the siteCap*2 buffer; this is
# the last-resort fallback if that guarantee is ever violated.
static func assign_positions(items: Array, slots: Array) -> Array:
	var result: Array = []
	if slots.is_empty():
		return result

	for item in items:
		var slot_index: int = mini(item["slotIndex"], slots.size() - 1)
		var slot = slots[slot_index]
		var id: String = item["vein"]["id"] if item["kind"] == "vein" else item["site"]["id"]
		result.append({
			"id": id,
			"position": Vector2(slot[0], slot[1]),
			"kind": item["kind"],
			"site": item["site"],
			"vein": item["vein"],
			"owner": item.get("owner"),
		})
	return result


# Wrapper: pulls real state and layout data for one district.
static func assign_slots(district_id: String) -> Array:
	var district_layout: Dictionary = GameData.MAP_LAYOUT.get("districts", {}).get(district_id, {})
	var slots: Array = district_layout.get("stopSlots", [])
	var sites := Sites.sites_in_district(district_id)
	var veins: Array = GameState.state["player"]["veins"]
	var items := build_stop_items(sites, veins)
	return assign_positions(items, slots)


# All districts' assigned stops in one call, keyed by district id — what
# MapCanvas rebuilds from on every state_changed.
static func assign_all_slots() -> Dictionary:
	var result: Dictionary = {}
	for district_id in GameData.DISTRICTS.keys():
		result[district_id] = assign_slots(district_id)
	return result


static func district_anchor(district_id: String) -> Vector2:
	var anchor: Array = GameData.MAP_LAYOUT["districts"][district_id]["anchor"]
	return Vector2(anchor[0], anchor[1])


static func home_anchor() -> Vector2:
	var anchor: Array = GameData.MAP_LAYOUT["homeAnchor"]
	return Vector2(anchor[0], anchor[1])


static func river_path() -> Array:
	var points: Array = GameData.MAP_LAYOUT["riverPath"]
	var result: Array = []
	for p in points:
		result.append(Vector2(p[0], p[1]))
	return result


# Groups already-positioned "vein" stops by owning faction id, excluding
# the player's own and "unclaimed" stops. map_canvas.gd builds one
# MapRouting.build_line() per faction from this. Pure.
static func group_by_faction(stops: Array) -> Dictionary:
	var result: Dictionary = {}
	for stop in stops:
		if stop["kind"] != "vein":
			continue
		var owner: String = stop.get("owner", "")
		if owner == "" or owner == "player":
			continue
		if not result.has(owner):
			result[owner] = []
		result[owner].append(stop)
	return result


# A faction's line starts from its first-presence district anchor: the
# first district (GameData.DISTRICTS key order) whose factionPresence
# matches. Null only on a data error — every canonical faction should
# have at least one presence district.
static func faction_first_presence_anchor(faction_id: String) -> Variant:
	for district_id in GameData.DISTRICTS.keys():
		var district: Dictionary = GameData.DISTRICTS[district_id]
		if district.get("factionPresence", "") == faction_id:
			return district_anchor(district_id)
	return null
