class_name TurfPanel
extends RefCounted

# Pure decision layer for the district panel's Turf section. Returns display
# rows from state.turf (daily value) plus live vein counts; the screen only
# renders them. Row "section" slots ("contenders", "flip", "modifiers",
# "benefits", "harassment", "grudges") let later sections append rows without restructure.

const SECTIONS := ["contenders", "flip", "modifiers", "benefits", "harassment", "grudges"]

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
	# harassment: { id, faction, source_name, kind, label, escalation, veinId } -- ignored effects on your veins here.
	for row in Harassment.rows_for_district(district_id):
		row["source_name"] = contender_name(row["faction"])
		sections["harassment"].append(row)
	# grudges: { faction, source_name, daysLeft } -- unanswered scores to settle set in this district.
	for row in Grudges.rows_for_district(district_id):
		row["source_name"] = contender_name(row["faction"])
		sections["grudges"].append(row)
	return {
		"district": district_id,
		"status": status,
		"status_label": CONTESTED_LABEL if status == "contested" else "",
		"controller": controller,
		"sections": sections,
	}


const PRESENCE_LABELS := { "control": "Holds district · full", "foothold": "Foothold · half", "none": "No ground here" }
const LOCKED_SHOWN := 2


# Perks section rows: `here` cards only for factions with at least one vein in
# the district; `everywhere` covers every faction's global perks.
# { here: [{ faction, name, presence, presence_label, perks: [perk_row] }],
#   everywhere: [perk_row], locked_hidden: int }.
# perk_row: { faction_name, label, description, status, note, unlocked }; status is
# "active" | "half" | "idle" | "locked", note the unlock requirement / ground line.
static func perk_groups(district_id: String) -> Dictionary:
	var shares := Turf.shares(district_id)
	var counts := Turf.counts(GameState.state, district_id)
	var cards := []
	var everywhere_unlocked := []
	var everywhere_locked := []
	var order := 0
	for fid in GameData.FACTIONS.keys():
		var tier := Turf.tier(district_id, fid)
		var tiers_cfg := _perk_status_context(fid)
		tiers_cfg["ground"] = tier
		var turf_perks := []
		for row in Perks.district_benefit_rows(fid, district_id):
			var perk_row := _perk_row(fid, row, tiers_cfg)
			if row["scope"] == "turf":
				turf_perks.append(perk_row)
			elif row["unlocked"]:
				everywhere_unlocked.append(perk_row)
			else:
				everywhere_locked.append(perk_row)
		if not turf_perks.is_empty() and int(counts.get(fid, 0)) > 0:
			cards.append({
				"faction": fid,
				"name": contender_name(fid),
				"presence": tier,
				"presence_label": PRESENCE_LABELS.get(tier, PRESENCE_LABELS["none"]),
				"share": float(shares.get(fid, 0.0)),
				"order": order,
				"perks": turf_perks,
			})
		order += 1
	cards.sort_custom(func(a, b):
		var ga: bool = a["presence"] != Turf.TIER_NONE
		var gb: bool = b["presence"] != Turf.TIER_NONE
		if ga != gb:
			return ga
		if ga:
			var ca: bool = a["presence"] == Turf.TIER_CONTROL
			var cb: bool = b["presence"] == Turf.TIER_CONTROL
			if ca != cb:
				return ca
			if a["share"] != b["share"]:
				return a["share"] > b["share"]
		return a["order"] < b["order"])
	var shown_locked := everywhere_locked.slice(0, LOCKED_SHOWN)
	var hidden := everywhere_locked.slice(LOCKED_SHOWN)
	return {
		"here": cards,
		"everywhere": everywhere_unlocked + shown_locked,
		"everywhere_hidden": hidden,
		"locked_hidden": hidden.size(),
	}


static func _perk_status_context(faction_id: String) -> Dictionary:
	return {
		"tier": Perks.player_tier(faction_id),
		"relation": int(GameState.state["factions"][faction_id]["relation"]),
	}


static func _perk_row(faction_id: String, row: Dictionary, ctx: Dictionary) -> Dictionary:
	var perk: Dictionary = row["perk"]
	var status := "locked"
	var note := ""
	match row["here"]:
		"full":
			status = "active"
		"reduced":
			status = "half"
		_:
			if row["unlocked"]:
				status = "idle"
	if not row["unlocked"]:
		note = _needs_text(row["tier"], ctx)
	if row["scope"] == "turf" and ctx.get("ground", Turf.TIER_NONE) == Turf.TIER_NONE:
		note = (note + " " if note != "" else "") + "No ground held here yet."
	return {
		"faction_name": contender_name(faction_id),
		"label": perk["label"],
		"description": perk["description"],
		"status": status,
		"note": note,
		"unlocked": row["unlocked"],
	}


static func _needs_text(tier: String, ctx: Dictionary) -> String:
	var text := "Needs %s" % Perks.requirement_text(tier)
	match tier:
		"friendly":
			return "%s (you: %d)." % [text, ctx["relation"]]
		"partner":
			if ctx["tier"] == Perks.TIER_NONE:
				return "%s (you: relation %d)." % [text, ctx["relation"]]
			return "%s (you are %s)." % [text, Perks.tier_label(ctx["tier"])]
	return "%s." % text


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
