class_name MapStyle
extends RefCounted

# M1.5 §N4: pure re-styling math for the filter chip modes (Ownership ·
# Type · Growth · Security · Faction isolate). Consumes already-resolved
# values (colours incl. Map palette tokens, tier/security/growth band) and returns
# colours/widths/scales/booleans — never touches GameState or GameData,
# like systems/map_routing.gd. scenes/components/map_canvas.gd is the only
# caller. §N4 is explicit that filters ONLY re-style, never hide a stop or
# change tap behaviour, which is why nothing here touches tap targets.
#
# "Growth" mode fades everything outside the "risk" bands and ramps the
# fullness arc colour by Cultivating.combined_magnitude() (R§3.4: value_tier
# blended with a vein's earned level). fullness_fraction() below is the pure
# seam behind MapCanvas's external progress ring.

const FILTER_MODES: Array[String] = ["ownership", "type", "growth", "security", "faction"]

const CHARGE_FADE_ALPHA := 0.35
const BADGE_ENLARGE_SCALE := 1.5


static func is_valid_filter(mode: String) -> bool:
	return FILTER_MODES.has(mode)


# Type: "all lines/stubs desaturate to --muted." `muted` is the caller's
# resolved Map palette token.
static func line_colour(filter_mode: String, owner_colour: Color, muted: Color) -> Color:
	if filter_mode == "type":
		return muted
	return owner_colour


# Faction: picking a faction dims everything else and highlights just its
# line and owned stops. Owner is "player", a faction id, or "" for
# unclaimed/NPC; selected_faction_id "" means faction mode is active but
# nothing's been picked, so nothing is isolated.
static func is_faction_isolated(filter_mode: String, selected_faction_id: String) -> bool:
	return filter_mode == "faction" and selected_faction_id != ""


# Growth: a line/stub is never itself "at risk" — it fades uniformly
# whenever this filter is active. Faction: reuses CHARGE_FADE_ALPHA for
# every line whose owner isn't the isolated faction; selected_faction_id/
# owner default to "" so callers that don't pass them are unaffected.
static func line_alpha(filter_mode: String, selected_faction_id: String = "", owner: String = "") -> float:
	if filter_mode == "growth":
		return CHARGE_FADE_ALPHA
	if is_faction_isolated(filter_mode, selected_faction_id):
		return 1.0 if owner == selected_faction_id else CHARGE_FADE_ALPHA
	return 1.0


# Growth: per-stop alpha — full for a vein in a risk band (is_risk_band
# below), faded otherwise. NPC/unclaimed stops always pass at_risk=false.
# Faction: same isolate/fade split as line_alpha above, keyed on owner.
static func stop_alpha(filter_mode: String, at_risk: bool, selected_faction_id: String = "", owner: String = "") -> float:
	if filter_mode == "growth":
		return 1.0 if at_risk else CHARGE_FADE_ALPHA
	if is_faction_isolated(filter_mode, selected_faction_id):
		return 1.0 if owner == selected_faction_id else CHARGE_FADE_ALPHA
	return 1.0


# Type: fullness arcs recolour by ore type. Growth: arc ramp from `muted`
# (tier 1) to `foreground` (tier 6+), keyed on combined_magnitude, clamped
# to [0,1] here so a leveled-up vein past 6 still reads as full foreground.
static func vein_ring_colour(filter_mode: String, owner_colour: Color, ore_colour: Color, tier: int, muted: Color, foreground: Color) -> Color:
	match filter_mode:
		"type":
			return ore_colour
		"growth":
			var t: float = clampf(float(tier - 1) / 5.0, 0.0, 1.0)
			return muted.lerp(foreground, t)
		_:
			return owner_colour


# Fullness-ring thickness stays fixed in every filter. Growth already carries
# magnitude through colour and risk-band alpha; changing diameter would make
# otherwise identical stops read as different marker classes.
static func vein_ring_width(_filter_mode: String, _tier: int, base_width: float) -> float:
	return base_width


# Security only enlarges the padlock badge — there is no level badge to
# enlarge any more (growth replaced the old 1-6 level, R§3.4).
static func badge_scale(filter_mode: String) -> float:
	if filter_mode == "security":
		return BADGE_ENLARGE_SCALE
	return 1.0


# Security: "unsecured YOUR veins get a --danger dotted ring."
static func show_danger_ring(filter_mode: String, security: String) -> bool:
	return filter_mode == "security" and security == "none"


const RISK_BANDS: Array[String] = ["barren", "sparse", "wild", "rampant", "collapsed"]


static func is_risk_band(band_id: String) -> bool:
	return RISK_BANDS.has(band_id)


# ── growth fill ──────────────────────────────────────────────────────────
# The progress arc's one pure seam: how full a vein's stop reads, 0.0
# (growth 0) to 1.0 (growth at/above ceiling(vein)) — flat proportional
# sweep, no per-band scaling. ceiling is always > 0 (R§1.2), so no
# divide-by-zero guard is needed.
static func fullness_fraction(growth: int, ceiling: int) -> float:
	return clampf(float(growth) / float(ceiling), 0.0, 1.0)
