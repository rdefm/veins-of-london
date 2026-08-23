extends "res://tests/test_base.gd"

# MapStyle — pure re-styling maths for the filter chip modes (M1.5 N4) and
# the growth-gauge glyph maths (vein-growth-state ticket 07).


func run() -> void:
	var owner := Color(0.784314, 0.529412, 0.227451)  # amber, stands in for PLAYER_COLOUR
	var ore := Color(0.2, 0.4, 0.9)  # arbitrary ore colour, distinct from owner/muted/ink

	# ── ownership (default) ─────────────────────────────────────────────
	run_case("ownership_leaves_everything_at_default", func():
		assert_eq(MapStyle.line_colour("ownership", owner), owner)
		assert_eq(MapStyle.line_alpha("ownership"), 1.0)
		assert_eq(MapStyle.stop_alpha("ownership", false), 1.0, "ownership never fades, even a not-at-risk stop")
		assert_eq(MapStyle.vein_ring_colour("ownership", owner, ore, 6), owner)
		assert_eq(MapStyle.vein_ring_width("ownership", 6, 2.5), 2.5)
		assert_eq(MapStyle.badge_scale("ownership"), 1.0)
		assert_true(not MapStyle.show_danger_ring("ownership", "none"), "danger ring is a security-filter-only thing")
	)

	# ── type ─────────────────────────────────────────────────────────────
	run_case("type_desaturates_lines_and_recolours_rings_by_ore", func():
		assert_eq(MapStyle.line_colour("type", owner), MapStyle.MUTED_COLOUR)
		assert_eq(MapStyle.vein_ring_colour("type", owner, ore, 3), ore, "type recolours the ring to the ore's own colour")
		assert_eq(MapStyle.vein_ring_width("type", 3, 2.5), 2.5, "type doesn't touch ring width")
	)

	# ── growth (ticket 07 — merges the old Strength and Charge chips) ────
	run_case("growth_ramps_ring_greyscale_and_width_by_value_tier", func():
		# Color.lerp(to, 1.0) isn't guaranteed bit-exact with `to` (float
		# rounding in from + (to-from)*weight), so compare channels within
		# an epsilon rather than with assert_eq's exact `!=`.
		var at_t1 := MapStyle.vein_ring_colour("growth", owner, ore, 1)
		assert_almost_eq(at_t1.r, MapStyle.MUTED_COLOUR.r, 0.001, "tier 1 -> muted (bottom of ramp)")
		assert_almost_eq(at_t1.g, MapStyle.MUTED_COLOUR.g, 0.001, "tier 1 -> muted (bottom of ramp)")
		assert_almost_eq(at_t1.b, MapStyle.MUTED_COLOUR.b, 0.001, "tier 1 -> muted (bottom of ramp)")

		var at_t6 := MapStyle.vein_ring_colour("growth", owner, ore, 6)
		assert_almost_eq(at_t6.r, MapStyle.INK_COLOUR.r, 0.001, "tier 6 -> ink (top of ramp)")
		assert_almost_eq(at_t6.g, MapStyle.INK_COLOUR.g, 0.001, "tier 6 -> ink (top of ramp)")
		assert_almost_eq(at_t6.b, MapStyle.INK_COLOUR.b, 0.001, "tier 6 -> ink (top of ramp)")

		var mid := MapStyle.vein_ring_colour("growth", owner, ore, 3)
		assert_true(absf(mid.r - MapStyle.MUTED_COLOUR.r) > 0.01 and absf(mid.r - MapStyle.INK_COLOUR.r) > 0.01, "tier 3 sits strictly between the ramp's ends")

		assert_almost_eq(MapStyle.vein_ring_width("growth", 1, 2.5), 2.3, 0.001, "1.5 + 1*0.8")
		assert_almost_eq(MapStyle.vein_ring_width("growth", 6, 2.5), 6.3, 0.001, "1.5 + 6*0.8")

		assert_eq(MapStyle.badge_scale("growth"), 1.0, "growth mode doesn't enlarge the security padlock -- the old level-badge enlarge is gone with the badge itself")
	)

	run_case("growth_fades_everything_outside_the_risk_bands", func():
		assert_eq(MapStyle.line_alpha("growth"), MapStyle.CHARGE_FADE_ALPHA, "lines are never individually 'at risk' -- always fade under this filter")
		assert_eq(MapStyle.stop_alpha("growth", true), 1.0, "a vein in a risk band stays full colour")
		assert_eq(MapStyle.stop_alpha("growth", false), MapStyle.CHARGE_FADE_ALPHA, "a vein outside the risk bands (or any npc/unclaimed stop) fades")
	)

	run_case("non_growth_filters_never_fade_stops_or_lines", func():
		for mode in ["ownership", "type", "security"]:
			assert_eq(MapStyle.line_alpha(mode), 1.0, mode)
			assert_eq(MapStyle.stop_alpha(mode, false), 1.0, mode)
	)

	run_case("is_risk_band_matches_barren_sparse_wild_rampant_collapsed_only", func():
		for band_id in ["barren", "sparse", "wild", "rampant", "collapsed"]:
			assert_true(MapStyle.is_risk_band(band_id), band_id)
		for band_id in ["thinning", "dormant", "taking", "lush"]:
			assert_true(not MapStyle.is_risk_band(band_id), band_id)
	)

	# ── security ─────────────────────────────────────────────────────────
	run_case("security_enlarges_padlocks_and_flags_unsecured_veins", func():
		assert_eq(MapStyle.badge_scale("security"), MapStyle.BADGE_ENLARGE_SCALE)
		assert_eq(MapStyle.badge_scale("growth"), 1.0, "only security enlarges the padlock badge")

		assert_true(MapStyle.show_danger_ring("security", "none"), "an unsecured vein gets the danger ring under this filter")
		assert_true(not MapStyle.show_danger_ring("security", "basic"), "a secured vein never gets it, even under this filter")
		assert_true(not MapStyle.show_danger_ring("ownership", "none"), "the danger ring is security-filter-only, regardless of security state")
	)

	run_case("is_valid_filter_matches_the_5_canonical_modes_only", func():
		for mode in MapStyle.FILTER_MODES:
			assert_true(MapStyle.is_valid_filter(mode))
		assert_true(not MapStyle.is_valid_filter("bogus"))
		assert_true(not MapStyle.is_valid_filter("strength"), "strength was merged into growth -- no longer a valid mode")
		assert_true(not MapStyle.is_valid_filter("charge"), "charge was merged into growth -- no longer a valid mode")
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

		assert_eq(MapStyle.stop_alpha("faction", true, "firm", "firm"), 1.0, "the selected faction's owned stop stays full alpha, at-risk or not")
		assert_eq(MapStyle.stop_alpha("faction", false, "firm", "firm"), 1.0)
		assert_eq(MapStyle.stop_alpha("faction", false, "firm", "player"), MapStyle.CHARGE_FADE_ALPHA, "the player's own vein fades under another faction's isolate")
		assert_eq(MapStyle.stop_alpha("faction", true, "firm", "player"), MapStyle.CHARGE_FADE_ALPHA, "even an at-risk player vein fades -- growth-mode's own alpha rule doesn't leak into faction mode")
		assert_eq(MapStyle.stop_alpha("faction", false, "firm", ""), MapStyle.CHARGE_FADE_ALPHA, "an unclaimed tick (no owner) fades -- it can never be 'the selected faction'")

		assert_eq(MapStyle.line_alpha("faction", "firm", "player"), MapStyle.line_alpha("growth"), "faction isolate reuses Growth's own fade value rather than a new one")
	)

	run_case("switching_away_from_faction_mode_restores_normal_styling", func():
		assert_eq(MapStyle.line_alpha("ownership", "firm", "player"), 1.0, "a stale selected_faction_id has no effect once filter_mode isn't 'faction'")
		assert_eq(MapStyle.stop_alpha("growth", false, "firm", "player"), MapStyle.CHARGE_FADE_ALPHA, "growth mode's own rule applies untouched, ignoring the stale faction selection")
		assert_eq(MapStyle.line_colour("ownership", MapStyle.MUTED_COLOUR), MapStyle.MUTED_COLOUR, "ownership's plain pass-through colour is unaffected by faction mode ever having been active")
	)

	# ── growth fill maths (bugfixes ticket 77) ───────────────────────────
	run_case("growth_fill_fraction_is_zero_at_growth_zero_and_one_at_the_ceiling", func():
		assert_eq(MapStyle.growth_fill_fraction(0, 100), 0.0, "empty vein -- no fill")
		assert_eq(MapStyle.growth_fill_fraction(100, 100), 1.0, "at the ceiling -- full")
		assert_eq(MapStyle.growth_fill_fraction(50, 100), 0.5, "halfway to the ceiling -- half full")
	)

	run_case("growth_fill_fraction_uses_the_veins_own_ceiling", func():
		assert_eq(MapStyle.growth_fill_fraction(120, 120), 1.0, "a wildCeiling vein's own 120 ceiling, not the default 100, is what fills it")
		assert_eq(MapStyle.growth_fill_fraction(60, 120), 0.5, "halfway to a 120 ceiling")
	)

	run_case("growth_fill_fraction_clamps_rather_than_overflowing_or_going_negative", func():
		assert_eq(MapStyle.growth_fill_fraction(150, 100), 1.0, "growth above ceiling still reads as full, not overfull")
		assert_eq(MapStyle.growth_fill_fraction(-10, 100), 0.0, "growth can't actually go negative, but the fraction still clamps defensively")
	)
