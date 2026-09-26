extends "res://tests/test_base.gd"

# tools/hq_region_mapper_logic.gd: the pure half of the HQ region mapper
# tool -- plate/region edits, hit testing, and the "rooms" block writer.

const DATA_PATH := "res://data/hq_visuals.json"


func run() -> void:
	run_case("rooms_block_round_trips_the_real_file_byte_for_byte", func():
		var text := FileAccess.get_file_as_string(DATA_PATH)
		var nl := "\r\n" if text.contains("\r\n") else "\n"
		var data: Dictionary = HqRegionMapperLogic.normalize(JSON.parse_string(text))
		var rebuilt := HqRegionMapperLogic.replace_rooms_block(text, HqRegionMapperLogic.serialize_rooms(data["rooms"], nl))
		assert_eq(rebuilt, text, "re-serializing unchanged rooms must leave the file untouched")
	)

	run_case("saved_polygon_reparses_and_leaves_lab_bench_untouched", func():
		var text := FileAccess.get_file_as_string(DATA_PATH)
		var data: Dictionary = HqRegionMapperLogic.normalize(JSON.parse_string(text))
		var plate := HqRegionMapperLogic.new_plate("res://assets/hq/studio_room.png", "timber_dark", Vector2i(390, 660))
		data["rooms"] = HqRegionMapperLogic.with_plate(data["rooms"], "studio", plate, GameData.HOME_TIER_ORDER)
		HqRegionMapperLogic.set_region_polygon(data["rooms"]["studio"], "rest", "Rest", [[10, 10], [120, 20], [100, 90]])
		var rebuilt := HqRegionMapperLogic.replace_rooms_block(text, HqRegionMapperLogic.serialize_rooms(data["rooms"], "\n"))
		var reparsed: Dictionary = HqRegionMapperLogic.normalize(JSON.parse_string(rebuilt))
		assert_eq(reparsed["rooms"]["studio"]["regions"]["rest"]["polygon"], [[10, 10], [120, 20], [100, 90]])
		assert_eq(reparsed["rooms"].keys(), ["bedsit", "studio"])
		assert_eq(reparsed["labBench"], data["labBench"])
		assert_eq(reparsed["meta"], data["meta"])
	)

	run_case("new_region_rect_is_the_polygon_bounding_box", func():
		var plate := HqRegionMapperLogic.new_plate("", "timber_dark", Vector2i(390, 660))
		HqRegionMapperLogic.set_region_polygon(plate, "lab", "Lab", [[50, 60], [150, 70], [120, 200]])
		var region: Dictionary = plate["regions"]["lab"]
		assert_eq([region["x"], region["y"], region["width"], region["height"]], [50, 60, 100, 140])
		assert_eq(region["label"], "Lab")
		assert_eq(region["image"], "")
	)

	run_case("region_with_a_sprite_keeps_its_sprite_rect", func():
		var plate := {"regions": {"rest": {"x": 95, "y": 335, "width": 180, "height": 149, "label": "Rest", "image": "res://x.png"}}}
		HqRegionMapperLogic.set_region_polygon(plate, "rest", "Rest", [[100, 340], [200, 340], [150, 450]])
		var region: Dictionary = plate["regions"]["rest"]
		assert_eq([region["x"], region["y"], region["width"], region["height"]], [95, 335, 180, 149])
		assert_true(region.has("polygon"))
	)

	run_case("regions_at_uses_the_polygon_when_present_else_the_rect", func():
		var regions := {
			"tri": {"x": 0, "y": 0, "width": 100, "height": 100, "polygon": [[0, 0], [100, 0], [0, 100]]},
			"box": {"x": 200, "y": 0, "width": 50, "height": 50},
		}
		assert_eq(HqDiorama.regions_at(regions, Vector2(10, 10)), ["tri"])
		assert_eq(HqDiorama.regions_at(regions, Vector2(90, 90)), [], "inside the bounding box but outside the triangle")
		assert_eq(HqDiorama.regions_at(regions, Vector2(220, 20)), ["box"])
	)

	run_case("room_images_follow_tier_order_and_skip_other_files", func():
		var files := PackedStringArray(["studio_room.png", "bedsit_room.png", "bedsit_external.png", "studio_room.png.import", "zzz_room.png"])
		var found := HqRegionMapperLogic.room_images(files, "res://assets/hq", ["bedsit", "studio", "flat"])
		assert_eq(found.map(func(t): return t["id"]), ["bedsit", "studio", "zzz"])
		assert_eq(found[1]["image"], "res://assets/hq/studio_room.png")
	)

	run_case("display_size_keeps_the_image_aspect_at_plate_width", func():
		assert_eq(HqRegionMapperLogic.display_size(Vector2i(964, 1631), 390), Vector2i(390, 660))
	)
