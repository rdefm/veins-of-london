class_name MapStyle
extends RefCounted

# M1.5 N4: pure re-styling math for the filter chip modes (Ownership ·
# Type · Growth · Security, plus map-filters ticket 04's Faction isolate).
# Consumes already-resolved values (an ore colour, an owner colour, a
# vein's value tier/security/growth band) and returns colours/widths/
# scales/booleans/angles — never touches GameState or GameData itself, same
# purity discipline as systems/map_routing.gd. scenes/components/
# map_canvas.gd is the only caller; kept separate so the filter maths are
# unit-testable without a running scene tree. N4 is explicit that filters
# ONLY re-style — they never hide a stop or change what tapping it does,
# which is exactly why nothing here returns "hidden" or touches tap targets.
#
# vein-growth-state ticket 07: "Strength" and "Charge" merge into one
# "Growth" chip — the old 1-6 `level`/`charged` flag quartet is gone (see
# systems/cultivating.gd), replaced by `growth`/`value_tier`/growth bands.
# Growth mode fades everything outside the "risk" bands, ramps ring colour/
# width by value_tier (same ramp shape Strength used, just keyed on the new
# 1-6 magnitude), and the growth-gauge arc/track maths below are what
# replaced the old per-vein progress ring and level/countdown badges.

const FILTER_MODES: Array[String] = ["ownership", "type", "growth", "security", "faction"]

const MUTED_COLOUR := Color(0.541176, 0.541176, 0.541176)   # --muted #8a8a8a
const INK_COLOUR := Color(0.101961, 0.101961, 0.101961)     # --ink #1a1a1a
const DANGER_COLOUR := Color(0.607843, 0.137255, 0.207843)  # --danger #9b2335

const CHARGE_FADE_ALPHA := 0.35
const BADGE_ENLARGE_SCALE := 1.5


static func is_valid_filter(mode: String) -> bool:
	return FILTER_MODES.has(mode)


# Type: "all lines/stubs desaturate to --muted."
static func line_colour(filter_mode: String, owner_colour: Color) -> Color:
	if filter_mode == "type":
		return MUTED_COLOUR
	return owner_colour


# Faction: "picking a faction dims everything else and highlights just that
# faction's line and owned stops" -- an owner is "player", a faction id, or
# "" for an unclaimed/NPC element with no owner at all. selected_faction_id
# "" means faction mode is active but nothing's been picked yet (e.g. the
# drawer's "Faction" row was opened without a pick), in which case nothing
# is isolated -- every owner reads at full alpha, same as ownership.
static func is_faction_isolated(filter_mode: String, selected_faction_id: String) -> bool:
	return filter_mode == "faction" and selected_faction_id != ""


# Growth: a line/stub is never itself "at risk" — it fades uniformly
# whenever this filter is active, same as the old Charge filter's lines
# ("everything uncharged drops to 35% alpha"). Faction: reuses the same
# CHARGE_FADE_ALPHA value (per the ticket -- "rather than inventing a new
# fade value") for every line whose owner isn't the isolated faction;
# selected_faction_id/owner default to "" so every pre-existing call site
# (none of which pass them) is unaffected.
static func line_alpha(filter_mode: String, selected_faction_id: String = "", owner: String = "") -> float:
	if filter_mode == "growth":
		return CHARGE_FADE_ALPHA
	if is_faction_isolated(filter_mode, selected_faction_id):
		return 1.0 if owner == selected_faction_id else CHARGE_FADE_ALPHA
	return 1.0


# Growth: per-stop alpha — full for a vein sitting in one of the risk bands
# (barren/sparse/wild/rampant/collapsed, see is_risk_band below), faded
# otherwise (thinning/dormant/taking/lush -- the "nothing urgent" middle).
# NPC/unclaimed stops have no growth of their own, so callers always pass
# false for them and get the same fade as a mid-band vein. Faction: same
# isolate/fade split as line_alpha above, keyed on the stop's own owner
# ("player", a faction id, or "" for an unclaimed tick) rather than growth
# state -- default params keep every pre-existing call site unaffected.
static func stop_alpha(filter_mode: String, at_risk: bool, selected_faction_id: String = "", owner: String = "") -> float:
	if filter_mode == "growth":
		return 1.0 if at_risk else CHARGE_FADE_ALPHA
	if is_faction_isolated(filter_mode, selected_faction_id):
		return 1.0 if owner == selected_faction_id else CHARGE_FADE_ALPHA
	return 1.0


# Type: stop rings recolour by ore type. Growth: ring greyscale ramp from
# --muted (tier 1) to --ink (tier 6) -- same ramp shape the old Strength
# filter used, keyed on value_tier (1-6) instead of the retired 1-6 level.
static func vein_ring_colour(filter_mode: String, owner_colour: Color, ore_colour: Color, tier: int) -> Color:
	match filter_mode:
		"type":
			return ore_colour
		"growth":
			var t: float = clampf(float(tier - 1) / 5.0, 0.0, 1.0)
			return MUTED_COLOUR.lerp(INK_COLOUR, t)
		_:
			return owner_colour


# Growth: ring thickness 1.5 + tier*0.8 (same formula the old Strength
# filter used against level).
static func vein_ring_width(filter_mode: String, tier: int, base_width: float) -> float:
	if filter_mode == "growth":
		return 1.5 + tier * 0.8
	return base_width


# Security only enlarges the padlock badge -- the old Strength filter's
# level-badge enlarge no longer applies now that the 4 o'clock level badge
# is dropped entirely (vein-growth-state ticket 07).
static func badge_scale(filter_mode: String) -> float:
	if filter_mode == "security":
		return BADGE_ENLARGE_SCALE
	return 1.0


# Security: "unsecured YOUR veins get a --danger dotted ring."
static func show_danger_ring(filter_mode: String, security: String) -> bool:
	return filter_mode == "security" and security == "none"


# Growth: the per-stop days-to-wall label ("6↑"/"4↓") that replaces the old
# per-stop charge countdown ("2⏳") — only shown under the Growth filter,
# and only for a vein actually drifting toward a wall (direction 0, a vein
# sitting exactly at neutral, has nothing to count down). Direction is
# already-resolved by the caller (MapCanvas, from the vein's own growth vs.
# GameData.VEIN_GROWTH's neutral) rather than looked up here, keeping this
# function's inputs plain primitives like every other seam in this file.
static func countdown_label(filter_mode: String, days_remaining: int, direction: int) -> Variant:
	if filter_mode != "growth" or direction == 0 or days_remaining < 0:
		return null
	var arrow := "↑" if direction > 0 else "↓"
	return "%d%s" % [days_remaining, arrow]


# ── growth gauge (vein-growth-state ticket 07) ───────────────────────────
# The stop ring becomes a growth gauge: a faint full-circumference track
# (drawn by MapCanvas, no maths needed here) plus this arc overdrawn on top,
# swept from 12 o'clock -- clockwise (toward 3-6 o'clock) for growth above
# neutral, anticlockwise (toward 9-6 o'clock) for growth below it -- with
# length proportional to distance from neutral, capped at a half-circle (6
# o'clock) at either wall.

# A vein exactly at neutral (dormant band) or fully spent (collapsed) draws
# no arc at all -- "Dormant vein shows only the track" (ticket 07); a
# collapsed vein's track itself is rendered broken/faded instead, entirely
# by MapCanvas (see its own _draw_growth_track), not by anything here.
const NO_ARC_BANDS: Array[String] = ["dormant", "collapsed"]

const RISK_BANDS: Array[String] = ["barren", "sparse", "wild", "rampant", "collapsed"]


static func is_risk_band(band_id: String) -> bool:
	return RISK_BANDS.has(band_id)


# Returns null for the two no-arc bands above; otherwise {"start":float,
# "end":float} in Godot's draw_arc angle convention (0 = 3 o'clock,
# increasing = clockwise in this y-down screen space, so -PI/2 = 12
# o'clock) with start <= end always, regardless of which side of neutral
# the sweep falls on.
static func growth_arc_angles(growth: int, neutral: int, ceiling: int, band_id: String) -> Variant:
	if NO_ARC_BANDS.has(band_id):
		return null
	var twelve := -PI / 2.0
	if growth > neutral:
		var fraction: float = clampf(float(growth - neutral) / float(ceiling - neutral), 0.0, 1.0)
		return { "start": twelve, "end": twelve + fraction * PI }
	var fraction: float = clampf(float(neutral - growth) / float(neutral), 0.0, 1.0)
	return { "start": twelve - fraction * PI, "end": twelve }


# Risk cue lives on the arc's own texture, not a second ring: "serrated"
# (wild/rampant) draws thicker with a ragged outer edge; "gapped" (barren/
# sparse) draws thin, faded, broken into dashes; "plain" (thinning/taking/
# lush) is an ordinary continuous arc at the ring's own colour/width.
# Dormant/collapsed never reach this -- growth_arc_angles() above already
# returns null for them, so MapCanvas never asks for a texture.
static func arc_texture(band_id: String) -> String:
	if band_id == "wild" or band_id == "rampant":
		return "serrated"
	if band_id == "barren" or band_id == "sparse":
		return "gapped"
	return "plain"


static func arc_width_scale(band_id: String) -> float:
	if band_id == "wild" or band_id == "rampant":
		return 2.0
	if band_id == "barren" or band_id == "sparse":
		return 0.5
	return 1.0


static func arc_alpha_scale(band_id: String) -> float:
	if band_id == "barren" or band_id == "sparse":
		return 0.6
	return 1.0
