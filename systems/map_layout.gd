class_name MapLayout
extends RefCounted

# M1.5 N3: resolves data/map_layout.json's per-district stopSlots against
# live state (state.world.sites + state.player.veins) into concrete stop
# positions for scenes/components/map_canvas.gd. Read-only — never mutates
# GameState, same discipline as systems/districts.gd.
#
# A "stop" is not 1:1 with a site: an unclaimed site is one stop, but a
# player-claimed site can carry two veins (a saturated site's bonus natural
# vein, D2) — that's exactly why map_layout.json's stopSlots buffer is
# siteCap+2, not siteCap+1. A faction-claimed site's vein is embedded
# directly on the site (faction-vein-ownership T01 — no natural-vein bonus
# for faction claims, so always exactly one stop). Stops occupy slots in
# discovery order: sites in state.world.sites' array order (append order =
# discovery order), and within a player-claimed site, its veins in
# state.player.veins' array order.


# Pure: turns a district's sites + the full player veins list into ordered
# stop items (no positions yet). Kept separate from assign_slots() so tests
# can exercise discovery-order occupancy without touching GameData/GameState.
# "vein" stops carry an "owner" key ("player" or a faction id) — N2's
# rendering grammar draws both the same way (circle, owner colour), just
# coloured differently; Chunk 2 (map rendering) is what actually wires that
# colouring up.
#
# 52-map-vein-line-position-drift: every item also carries the "slotIndex"
# assign_positions() now keys off of, instead of the item's position in
# this returned array. A site's own stamped slotIndex (Sites.
# next_slot_index(), set once at creation) covers the unclaimed/faction/
# first-player-vein case; a claimed site's *second* player vein (the
# saturated-site natural-vein bonus) carries its own stamped slotIndex
# (set at Sites.attempt_seed() time) rather than reusing the site's, since
# it's a genuinely separate stop needing its own permanent slot. Read via
# .get(...,0) rather than a bare [] lookup: plenty of test fixtures across
# the suite hand-build minimal site/vein dicts to exercise other systems
# entirely (never routed through Sites.roll_new_site()/attempt_seed()), and
# this must degrade to "everyone piles on slot 0" for them rather than
# crash — real gameplay sites always carry a real stamped value.
static func build_stop_items(sites: Array, veins: Array) -> Array:
	var items: Array = []
	for site in sites:
		if site.get("factionVein") != null:
			items.append({ "kind": "vein", "site": site, "vein": site["factionVein"], "owner": site["factionVein"]["factionId"], "slotIndex": site.get("slotIndex", 0) })
		elif site.get("claimed", false):
			for vein in veins:
				if vein.get("siteId") == site["id"]:
					var slot_index: int = vein.get("slotIndex", site.get("slotIndex", 0))
					items.append({ "kind": "vein", "site": site, "vein": vein, "owner": "player", "slotIndex": slot_index })
		else:
			items.append({ "kind": "unclaimed", "site": site, "vein": null, "owner": null, "slotIndex": site.get("slotIndex", 0) })
	return items


# Pure: maps each stop item onto its slot's position, keyed by the item's
# own stamped "slotIndex" (52-map-vein-line-position-drift) rather than its
# position in `items` — a stop's slot must stay fixed for its whole life
# regardless of what gets discovered, claimed, or removed elsewhere in the
# same district. Clamps any slotIndex beyond the slot list onto the last
# slot (defensive: map_layout.json's siteCap+2 buffer covers normal churn,
# GameData validates that buffer at boot, but slotIndex never gets reused
# once a stop is removed, so heavy churn over a long session can still run
# past it).
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


# multi-faction-line-routing (ticket 03): groups already-positioned "vein"
# stops (assign_slots'/assign_all_slots' output, flattened across
# districts) by owning faction id — the player's own stops and any
# "unclaimed" stops are excluded. scenes/components/map_canvas.gd uses this
# to build one MapRouting.build_line() per faction instead of the old
# single undifferentiated NPC stub. Pure — no GameState/GameData reads,
# same discipline as the rest of this module.
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


# N3: a faction's line starts from its first-presence district anchor —
# the first district (GameData.DISTRICTS' key order) whose factionPresence
# matches. Null if the faction has no presence anywhere (data error; every
# canonical faction should have at least one).
static func faction_first_presence_anchor(faction_id: String) -> Variant:
	for district_id in GameData.DISTRICTS.keys():
		var district: Dictionary = GameData.DISTRICTS[district_id]
		if district.get("factionPresence", "") == faction_id:
			return district_anchor(district_id)
	return null
