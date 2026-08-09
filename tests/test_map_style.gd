extends "res://tests/test_base.gd"

# MapStyle — pure re-styling maths for the 5 filter chip modes (M1.5 N4).


func run() -> void:
	var owner := Color(0.784314, 0.529412, 0.227451)  # amber, stands in for PLAYER_COLOUR
	var ore := Color(0.2, 0.4, 0.9)  # arbitrary ore colour, distinct from owner/muted/ink

	# ── ownership (default) ─────────────────────────────────────────────
	run_case("ownership_leaves_everything_at_default", func():
		assert_eq(MapStyle.line_colour("ownership", owner), owner)
		assert_eq(MapStyle.line_alpha("ownership"), 1.0)
		assert_eq(MapStyle.stop_alpha("ownership", false), 1.0, "ownership never fades, even an uncharged stop")
		assert_eq(MapStyle.vein_ring_colour("ownership", owner, ore, 6), owner)
		assert_eq(MapStyle.vein_ring_width("ownership", 6, 2.5), 2.5)
		assert_eq(MapStyle.badge_scale("ownership", "level"), 1.0)
		assert_eq(MapStyle.badge_scale("ownership", "security"), 1.0)
		assert_true(not MapStyle.show_danger_ring("ownership", "none"), "danger ring is a security-filter-only thing")
		assert_eq(MapStyle.countdown_label("ownership", false, 2), null)
	)

	# ── type ─────────────────────────────────────────────────────────────
	run_case("type_desaturates_lines_and_recolours_rings_by_ore", func():
		assert_eq(MapStyle.line_colour("type", owner), MapStyle.MUTED_COLOUR)
		assert_eq(MapStyle.vein_ring_colour("type", owner, ore, 3), ore, "type recolours the ring to the ore's own colour")
		assert_eq(MapStyle.vein_ring_width("type", 3, 2.5), 2.5, "type doesn't touch ring width")
	)

	# ── strength ─────────────────────────────────────────────────────────
	run_case("strength_ramps_ring_greyscale_and_width_by_level_enlarges_level_badge", func():
		# Color.lerp(to, 1.0) isn't guaranteed bit-exact with `to` (float
		# rounding in from + (to-from)*weight), so compare channels within
		# an epsilon rather than with assert_eq's exact `!=`.
		var at_l1 := MapStyle.vein_ring_colour("strength", owner, ore, 1)
		assert_almost_eq(at_l1.r, MapStyle.MUTED_COLOUR.r, 0.001, "level 1 -> muted (bottom of ramp)")
		assert_almost_eq(at_l1.g, MapStyle.MUTED_COLOUR.g, 0.001, "level 1 -> muted (bottom of ramp)")
		assert_almost_eq(at_l1.b, MapStyle.MUTED_COLOUR.b, 0.001, "level 1 -> muted (bottom of ramp)")

		var at_l6 := MapStyle.vein_ring_colour("strength", owner, ore, 6)
		assert_almost_eq(at_l6.r, MapStyle.INK_COLOUR.r, 0.001, "level 6 -> ink (top of ramp)")
		assert_almost_eq(at_l6.g, MapStyle.INK_COLOUR.g, 0.001, "level 6 -> ink (top of ramp)")
		assert_almost_eq(at_l6.b, MapStyle.INK_COLOUR.b, 0.001, "level 6 -> ink (top of ramp)")

		var mid := MapStyle.vein_ring_colour("strength", owner, ore, 3)
		assert_true(absf(mid.r - MapStyle.MUTED_COLOUR.r) > 0.01 and absf(mid.r - MapStyle.INK_COLOUR.r) > 0.01, "level 3 sits strictly between the ramp's ends")

		assert_almost_eq(MapStyle.vein_ring_width("strength", 1, 2.5), 2.3, 0.001, "1.5 + 1*0.8")
		assert_almost_eq(MapStyle.vein_ring_width("strength", 6, 2.5), 6.3, 0.001, "1.5 + 6*0.8")

		assert_eq(MapStyle.badge_scale("strength", "level"), MapStyle.BADGE_ENLARGE_SCALE)
		assert_eq(MapStyle.badge_scale("strength", "security"), 1.0, "strength only enlarges the level badge, not the padlock")
	)

	# ── charge ───────────────────────────────────────────────────────────
	run_case("charge_fades_everything_uncharged_and_shows_a_countdown_badge", func():
		assert_eq(MapStyle.line_alpha("charge"), MapStyle.CHARGE_FADE_ALPHA, "lines are never 'charged' -- always fade under this filter")
		assert_eq(MapStyle.stop_alpha("charge", true), 1.0, "a charged vein stays full colour")
		assert_eq(MapStyle.stop_alpha("charge", false), MapStyle.CHARGE_FADE_ALPHA, "an uncharged vein (or any npc/unclaimed stop) fades")

		assert_eq(MapStyle.countdown_label("charge", false, 2), "2⏳")
		assert_eq(MapStyle.countdown_label("charge", true, 0), null, "a charged vein keeps its ordinary level badge, not a countdown")
	)

	run_case("non_charge_filters_never_fade_stops_or_lines", func():
		for mode in ["ownership", "type", "strength", "security"]:
			assert_eq(MapStyle.line_alpha(mode), 1.0, mode)
			assert_eq(MapStyle.stop_alpha(mode, false), 1.0, mode)
	)

	# ── security ─────────────────────────────────────────────────────────
	run_case("security_enlarges_padlocks_and_flags_unsecured_veins", func():
		assert_eq(MapStyle.badge_scale("security", "security"), MapStyle.BADGE_ENLARGE_SCALE)
		assert_eq(MapStyle.badge_scale("security", "level"), 1.0, "security only enlarges the padlock, not the level badge")

		assert_true(MapStyle.show_danger_ring("security", "none"), "an unsecured vein gets the danger ring under this filter")
		assert_true(not MapStyle.show_danger_ring("security", "basic"), "a secured vein never gets it, even under this filter")
		assert_true(not MapStyle.show_danger_ring("ownership", "none"), "the danger ring is security-filter-only, regardless of security state")
	)

	run_case("is_valid_filter_matches_the_6_canonical_modes_only", func():
		for mode in MapStyle.FILTER_MODES:
			assert_true(MapStyle.is_valid_filter(mode))
		assert_true(not MapStyle.is_valid_filter("bogus"))
	)

	# ── faction isolate (map-filters ticket 04) ─────────────────────────────
	run_case("faction_mode_with_no_selection_isolates_nothing", func():
		assert_true(not MapStyle.is_faction_isolated("faction", ""), "opening Faction mode without picking one isolates nobody")
		assert_eq(MapStyle.line_alpha("faction", "", "player"), 1.0)
		assert_eq(MapStyle.line_alpha("faction", "", "firm"), 1.0)
		assert_eq(MapStyle.stop_alpha("faction", false, "", "player"), 1.0)
	)

	run_case("faction_mode_isolates_the_selected_faction_only", func():
		assert_true(MapStyle.is_faction_isolated("faction", "firm"))
		assert_true(not MapStyle.is_faction_isolated("ownership", "firm"), "isolation is faction-mode-only, regardless of a stale selection")

		assert_eq(MapStyle.line_alpha("faction", "firm", "firm"), 1.0, "the selected faction's own line stays full alpha")
		assert_eq(MapStyle.line_alpha("faction", "firm", "player"), MapStyle.CHARGE_FADE_ALPHA, "the player's own line fades like anything else not selected")
		assert_eq(MapStyle.line_alpha("faction", "firm", "guild"), MapStyle.CHARGE_FADE_ALPHA, "an unselected faction's line fades too")

		assert_eq(MapStyle.stop_alpha("faction", true, "firm", "firm"), 1.0, "the selected faction's owned stop stays full alpha, charged or not")
		assert_eq(MapStyle.stop_alpha("faction", false, "firm", "firm"), 1.0)
		assert_eq(MapStyle.stop_alpha("faction", false, "firm", "player"), MapStyle.CHARGE_FADE_ALPHA, "the player's own vein fades under another faction's isolate")
		assert_eq(MapStyle.stop_alpha("faction", true, "firm", "player"), MapStyle.CHARGE_FADE_ALPHA, "even a charged player vein fades -- charge-mode's own alpha rule doesn't leak into faction mode")
		assert_eq(MapStyle.stop_alpha("faction", false, "firm", ""), MapStyle.CHARGE_FADE_ALPHA, "an unclaimed tick (no owner) fades -- it can never be 'the selected faction'")

		assert_eq(MapStyle.line_alpha("faction", "firm", "player"), MapStyle.line_alpha("charge"), "faction isolate reuses Charge's own fade value rather than a new one")
	)

	run_case("switching_away_from_faction_mode_restores_normal_styling", func():
		assert_eq(MapStyle.line_alpha("ownership", "firm", "player"), 1.0, "a stale selected_faction_id has no effect once filter_mode isn't 'faction'")
		assert_eq(MapStyle.stop_alpha("charge", false, "firm", "player"), MapStyle.CHARGE_FADE_ALPHA, "charge mode's own rule applies untouched, ignoring the stale faction selection")
		assert_eq(MapStyle.line_colour("ownership", MapStyle.MUTED_COLOUR), MapStyle.MUTED_COLOUR, "ownership's plain pass-through colour is unaffected by faction mode ever having been active")
	)
