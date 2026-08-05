class_name MapStyle
extends RefCounted

# M1.5 N4: pure re-styling math for the 5 filter chip modes (Ownership ·
# Type · Strength · Charge · Security). Consumes already-resolved values
# (an ore colour, an owner colour, a vein's level/security/charge state)
# and returns colours/widths/scales/booleans — never touches GameState or
# GameData itself, same purity discipline as systems/map_routing.gd.
# scenes/components/map_canvas.gd is the only caller; kept separate so the
# filter maths are unit-testable without a running scene tree. N4 is
# explicit that filters ONLY re-style — they never hide a stop or change
# what tapping it does, which is exactly why nothing here returns
# "hidden" or touches tap targets.

const FILTER_MODES: Array[String] = ["ownership", "type", "strength", "charge", "security"]

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


# Charge: a line/stub is never itself "charged" — it fades uniformly
# whenever this filter is active, same as any other non-charged element
# ("everything uncharged drops to 35% alpha").
static func line_alpha(filter_mode: String) -> float:
	return CHARGE_FADE_ALPHA if filter_mode == "charge" else 1.0


# Charge: per-stop alpha — full for a charged vein, faded otherwise.
# NPC/unclaimed stops are never "charged", so callers always pass false
# for them and get the same fade as an uncharged vein.
static func stop_alpha(filter_mode: String, charged: bool) -> float:
	if filter_mode == "charge" and not charged:
		return CHARGE_FADE_ALPHA
	return 1.0


# Type: stop rings recolour by ore type. Strength: ring greyscale ramp
# from --muted (L1) to --ink (L6).
static func vein_ring_colour(filter_mode: String, owner_colour: Color, ore_colour: Color, level: int) -> Color:
	match filter_mode:
		"type":
			return ore_colour
		"strength":
			var t: float = clampf(float(level - 1) / 5.0, 0.0, 1.0)
			return MUTED_COLOUR.lerp(INK_COLOUR, t)
		_:
			return owner_colour


# Strength: ring thickness 1.5 + level*0.8.
static func vein_ring_width(filter_mode: String, level: int, base_width: float) -> float:
	if filter_mode == "strength":
		return 1.5 + level * 0.8
	return base_width


# Strength enlarges level badges; Security enlarges padlock badges.
# badge_kind is "level" or "security".
static func badge_scale(filter_mode: String, badge_kind: String) -> float:
	if badge_kind == "level" and filter_mode == "strength":
		return BADGE_ENLARGE_SCALE
	if badge_kind == "security" and filter_mode == "security":
		return BADGE_ENLARGE_SCALE
	return 1.0


# Security: "unsecured YOUR veins get a --danger dotted ring."
static func show_danger_ring(filter_mode: String, security: String) -> bool:
	return filter_mode == "security" and security == "none"


# Charge: "per-stop countdown badge '2⏳' = blocks until charged" — replaces
# the level badge for a stop that isn't charged yet. Null everywhere else
# (caller falls back to the ordinary level badge).
static func countdown_label(filter_mode: String, charged: bool, blocks_remaining: int) -> Variant:
	if filter_mode == "charge" and not charged:
		return "%d⏳" % blocks_remaining
	return null
