extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")
const Fixtures := preload("res://tests/support/fixtures.gd")

# HQ Guard Kit screen (guard-kit spec §UI), reached from hq_door.gd.


func run() -> void:
	run_case("lists_guarded_and_stocked_veins_and_hides_bare_ones", func():
		_seed()
		var screen := HqGuardKitScreen.new()
		screen._ready()
		assert_true(_row(screen, "v1") != null, "guarded vein listed")
		assert_true(_row(screen, "v2") != null, "stocked unguarded vein listed")
		assert_true(_row(screen, "v3") == null, "bare vein hidden")
		assert_true(_row(screen, "v1").text.ends_with("Guard kit 1/2 · Shield ×1 ›"))
		assert_true(_row(screen, "v2").text.ends_with("Guard kit 1/0 · Blast ×1 · idle ›"))
		screen.free()
	)

	run_case("row_opens_the_stocking_sheet_and_the_list_refreshes", func():
		_seed()
		var screen := HqGuardKitScreen.new()
		screen._ready()
		_row(screen, "v1").pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "guard_kit")
		assert_eq(GameState.state["modal"]["data"]["target"], { "kind": "vein", "veinId": "v1" })
		Crafting.inventory_add("blast", 1, 1)
		assert_true(GuardKit.stock_target({ "kind": "vein", "veinId": "v1" }, "blast", 1, 1)["ok"])
		var texts := NodeQuery.button_texts(screen)
		assert_true(texts.any(func(t: String): return t.ends_with("Guard kit 2/2 · Blast ×1 · Shield ×1 ›")), "rebuilt on state_changed")
		screen.free()
	)

	run_case("empty_state_when_no_vein_qualifies", func():
		GameState.reset()
		var screen := HqGuardKitScreen.new()
		screen._ready()
		assert_true(NodeQuery.label_texts(screen).has("No guarded veins. Post a guard first."))
		screen.free()
	)

	run_case("hq_door_guard_kits_button_navigates_here_and_back_returns", func():
		GameState.reset()
		var door := HqDoorScreen.new()
		door._ready()
		NodeQuery.find_button(door, "Guard kits ›").pressed.emit()
		assert_eq(GameState.state["currentScreen"], "hq_guard_kit")
		door.free()
		var screen := HqGuardKitScreen.new()
		screen._ready()
		NodeQuery.find_button(screen, "‹ Back").pressed.emit()
		assert_eq(GameState.state["currentScreen"], "hq_door")
		screen.free()
	)

	run_case("hq_row_sits_on_top_and_opens_the_hq_sheet", func():
		_seed()
		GameState.state["home"]["guardCount"] = 1
		GameState.state["home"]["guardKit"] = { "blast": { "1": 4 } }
		var screen := HqGuardKitScreen.new()
		screen._ready()
		var hq_row := _row(screen, "hq")
		assert_eq(hq_row.text, "HQ\nGuard kit 4/2 · Blast ×4 · idle ›")
		var rows := screen.find_children("GuardKitRow_*", "Button", true, false)
		assert_eq(rows[0], hq_row, "HQ row first")
		hq_row.pressed.emit()
		assert_eq(GameState.state["modal"]["data"]["target"], { "kind": "hq" })
		screen.free()
	)

	run_case("hq_door_kit_row_opens_the_hq_sheet", func():
		GameState.reset()
		var door := HqDoorScreen.new()
		door._ready()
		var hq_row := _row(door, "hq")
		assert_eq(hq_row.text, "HQ\nGuard kit 0/0 · Empty ›")
		hq_row.pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "guard_kit")
		assert_eq(GameState.state["modal"]["data"]["target"], { "kind": "hq" })
		door.free()
	)


func _seed() -> void:
	GameState.reset()
	var guarded := Fixtures.seed_vein("v1", 50)
	guarded["security"] = "guarded"
	guarded["guardKit"] = { "shield": { "1": 1 } }
	var stocked := Fixtures.seed_vein("v2", 50)
	stocked["guardKit"] = { "blast": { "1": 1 } }
	var bare := Fixtures.seed_vein("v3", 50)
	bare["guardKit"] = {}


func _row(screen: Node, vein_id: String) -> Button:
	var found := screen.find_children("GuardKitRow_%s" % vein_id, "Button", true, false)
	return found[0] as Button if not found.is_empty() else null
