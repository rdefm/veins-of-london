extends "res://tests/test_base.gd"

# Background art loads (TexturePrefetch) and the path lookups combat prep and
# the stage share (CombatStage.backdrop_path / sheet_paths / prefetch_art,
# CombatPrep.likely_location_keys).

const BATTERSEA := "res://assets/combat/backdrops/battersea.png"
const STREET := "res://assets/combat/backdrops/street.png"


func run() -> void:
	run_case("take_loads_whether_or_not_it_was_requested", func():
		TexturePrefetch.release_all()
		assert_true(TexturePrefetch.take(BATTERSEA) != null, "an unrequested path loads synchronously")
		TexturePrefetch.request([BATTERSEA, "", "res://no/such.png", 7])
		assert_true(TexturePrefetch.take(BATTERSEA) != null, "a requested path is collected")
		assert_true(TexturePrefetch._requested.is_empty(), "nothing left uncollected; bad entries never requested")
	)

	run_case("release_all_collects_every_outstanding_request", func():
		TexturePrefetch.release_all()
		CombatStage.prefetch_art(["camden", "home", ""])
		TexturePrefetch.release_all()
		assert_true(TexturePrefetch._requested.is_empty(), "registry drained")
	)

	run_case("backdrop_path_location_then_context_then_none", func():
		assert_eq(CombatStage.backdrop_path("raid", "battersea"), BATTERSEA, "location plate first")
		assert_eq(CombatStage.backdrop_path("raid", ""), STREET, "context plate without a location plate")
		assert_eq(CombatStage.backdrop_path("spar", "nowhere"), "", "neither -> palette fill")
	)

	run_case("sheet_paths_reads_posed_images_or_one_sheet", func():
		assert_eq(CombatStage.sheet_paths({ "images": [BATTERSEA, "res://no/such.png"] }), [BATTERSEA], "missing posed files dropped")
		assert_eq(CombatStage.sheet_paths({ "image": BATTERSEA, "frameCount": 2 }), [BATTERSEA], "a sheet")
		assert_eq(CombatStage.sheet_paths({ "image": BATTERSEA, "frameCount": 0 }), [], "no frames, no sheet")
		assert_eq(CombatStage.sheet_paths({}), [], "empty entry")
	)

	run_case("likely_location_keys_cover_district_home_and_vein", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "camden"
		var keys: Array = CombatPrep.likely_location_keys({ "kind": CombatPrep.KIND_MUGGING, "args": {} })
		assert_eq(keys, ["", "camden", Combat.HOME_LOCATION_KEY], "current district, home and no-plate")
		var debug_keys: Array = CombatPrep.likely_location_keys({ "kind": CombatPrep.KIND_DEBUG, "args": { "locationKey": "soho" } })
		assert_true(debug_keys.has("soho"), "a debug override is included")
		var before: Dictionary = GameState.state.duplicate(true)
		CombatPrep.likely_location_keys({ "kind": CombatPrep.KIND_VEIN_RAID, "args": { "veinId": "no_such_vein" } })
		assert_eq(GameState.state, before, "a pure read")
	)
