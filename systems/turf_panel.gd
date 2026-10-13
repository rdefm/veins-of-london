class_name TurfPanel
extends RefCounted

# Pure decision layer for the district panel's Turf section. Returns display
# rows from state.turf (daily value) plus live vein counts; the screen only
# renders them. Row "section" slots ("contenders", "flip", "modifiers",
# "benefits", "harassment") let later sections append rows without restructure.

const SECTIONS := ["contenders", "flip", "modifiers", "benefits", "harassment"]

const TIER_LABELS := { "control": "Control", "foothold": "Foothold", "none": "" }
const CONTESTED_LABEL := "Contested"
const MODIFIER_LABELS := { "dangerAdj": "Danger", "priceAdj": "Prices", "raidOddsAdj": "Raid odds" }


static func contender_name(contender: String) -> String:
	if contender == Turf.PLAYER:
		return "You"
	return GameData.FACTIONS[contender]["shortName"]


# { district, status, sections: { section: [row] } } -- row shapes per section below.
static func build(district_id: String) -> Dictionary:
	var sections := {}
	for section in SECTIONS:
		sections[section] = []
	var entry: Dictionary = GameState.state["turf"].get(district_id, {})
	var shares: Dictionary = entry.get("shares", {})
	var tiers: Dictionary = entry.get("tiers", {})
	var controller: String = entry.get("controller", "")
	var counts := Turf.counts(GameState.state, district_id)

	# contenders: { contender, name, share_pct, veins, tier, tier_label }, biggest first.
	var ids: Array = shares.keys()
	ids.sort_custom(func(a, b): return float(shares[a]) > float(shares[b]) or (float(shares[a]) == float(shares[b]) and String(a) < String(b)))
	for contender in ids:
		var tier: String = tiers.get(contender, Turf.TIER_NONE)
		sections["contenders"].append({
			"contender": contender,
			"name": contender_name(contender),
			"share_pct": int(round(float(shares[contender]) * 100.0)),
			"veins": int(counts.get(contender, 0)),
			"tier": tier,
			"tier_label": TIER_LABELS.get(tier, ""),
		})

	var status := "unclaimed"
	if controller != "":
		status = "controlled"
	elif Turf.is_contested(district_id):
		status = "contested"
	var flip := _flip_row(counts, controller)
	if not flip.is_empty():
		sections["flip"].append(flip)

	for src in Turf.modifier_sources(district_id):
		sections["modifiers"].append({
			"label": MODIFIER_LABELS.get(src["key"], src["key"]),
			"value": src["value"],
			"source": src["source"],
			"source_name": contender_name(src["source"]),
		})
	# benefits: { perk_id, label, description, source, source_name, tier, tier_label, scale }.
	var active := Perks.active_global()
	for perk_entry in active:
		perk_entry["scale"] = 1.0
	active.append_array(Perks.active_turf(district_id))
	for perk_entry in active:
		sections["benefits"].append({
			"perk_id": perk_entry["perk"]["id"],
			"label": perk_entry["perk"]["label"],
			"description": perk_entry["perk"]["description"],
			"source": perk_entry["faction"],
			"source_name": contender_name(perk_entry["faction"]),
			"tier": perk_entry["tier"],
			"tier_label": Perks.tier_label(perk_entry["tier"]),
			"scale": perk_entry["scale"],
		})
	return {
		"district": district_id,
		"status": status,
		"status_label": CONTESTED_LABEL if status == "contested" else "",
		"controller": controller,
		"sections": sections,
	}


# Faction preview: { faction, name, tier, tier_label, perks: [{ tier, tier_label, unlocked, turf, label, description }] }.
static func faction_preview(faction_id: String) -> Dictionary:
	var tier := Perks.player_tier(faction_id)
	var perks := []
	for row in Perks.preview(faction_id):
		perks.append({
			"tier": row["tier"],
			"tier_label": Perks.tier_label(row["tier"]),
			"unlocked": row["unlocked"],
			"turf": row["perk"]["scope"] == "turf",
			"label": row["perk"]["label"],
			"description": row["perk"]["description"],
		})
	return {
		"faction": faction_id,
		"name": contender_name(faction_id),
		"tier": tier,
		"tier_label": Perks.tier_label(tier),
		"perks": perks,
	}


# Veins you need to take control (or the lead you can spare while holding it).
static func _flip_row(counts: Dictionary, controller: String) -> Dictionary:
	if counts.is_empty():
		return {}
	var margin := int(GameData.TURF["controlMargin"])
	var mine := int(counts.get(Turf.PLAYER, 0))
	if controller == Turf.PLAYER:
		var best_other := 0
		for contender in counts:
			if contender != Turf.PLAYER:
				best_other = maxi(best_other, int(counts[contender]))
		return { "kind": "spare", "veins": mine - best_other - margin }
	var rival := 0
	for contender in counts:
		if contender != Turf.PLAYER:
			rival = maxi(rival, int(counts[contender]))
	return { "kind": "need", "veins": maxi(1, rival + margin - mine) }
