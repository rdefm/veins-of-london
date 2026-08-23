extends "res://tests/test_base.gd"

# Ticket 12: tapping outside a modal (_dim's gui_input) must close it,
# running the same side effect as that modal's own Close/Cancel/Decline
# button — not a bare Modal.close() that would leave sellState half-applied
# or skip james_job_offer's Jobs.decline_job() bookkeeping.
#
# ModalLayer.new() is safe to call _ready() on directly without adding it to
# a live scene tree, same reasoning tests/test_map_controls.gd already
# relies on for MapControls: nothing _ready() touches (UI.*, EventBus,
# GameState) depends on get_tree()/get_viewport() having run.


func _synthetic_tap() -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	return event


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	return texts


static func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


func run() -> void:
	run_case("tap_outside_a_no_side_effect_modal_just_closes_it", func():
		GameState.reset()
		Modal.open("seed_result", { "success": true, "oreType": "time" })

		var layer := ModalLayer.new()
		layer._ready()
		layer._on_dim_gui_input(_synthetic_tap())

		assert_eq(GameState.state["modal"], null, "outside tap closes the modal")

		layer.free()
	)

	run_case("tap_outside_sell_menu_clears_sell_state_same_as_cancel", func():
		GameState.reset()
		GameState.state["sellState"] = { "ore_time": 2 }
		Modal.open("sell_menu")

		var layer := ModalLayer.new()
		layer._ready()
		layer._on_dim_gui_input(_synthetic_tap())

		assert_eq(GameState.state["modal"], null, "outside tap closes sell_menu")
		assert_eq(GameState.state["sellState"], {}, "sellState is cleared, same as tapping Cancel")

		layer.free()
	)

	run_case("tap_outside_james_job_offer_declines_the_job_same_as_decline", func():
		GameState.reset()
		var job := { "type": "craft", "recipeKey": "timePearl", "recipeName": "Time Pearl", "symbol": "⧖", "qty": 2, "payPerItem": 10, "totalPay": 20, "byDay": 10 }
		GameState.state["jamesJob"] = job
		GameState.state["flags"]["jamesJobActive"] = true
		Modal.open("james_job_offer", { "job": job })

		var layer := ModalLayer.new()
		layer._ready()
		layer._on_dim_gui_input(_synthetic_tap())

		assert_eq(GameState.state["modal"], null, "outside tap closes james_job_offer")
		assert_eq(GameState.state["flags"]["jamesJobActive"], false, "declining clears jamesJobActive, same as tapping Decline")
		assert_eq(GameState.state["jamesJob"], null, "declining clears jamesJob, same as tapping Decline")

		layer.free()
	)

	run_case("tap_outside_sale_result_navigates_to_phone_home_same_as_back_to_it", func():
		GameState.reset()
		Nav.go_to("hq")
		Modal.open("sale_result", { "mugged": false, "earned": 40 })

		var layer := ModalLayer.new()
		layer._ready()
		layer._on_dim_gui_input(_synthetic_tap())

		assert_eq(GameState.state["modal"], null, "outside tap closes sale_result")
		assert_eq(GameState.state["currentScreen"], "phone", "outside tap navs to phone home, same as tapping Back to it")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "should land on the grid itself, not whatever app was last open")

		layer.free()
	)

	# ── collective1-07: sell_menu's faction-lane branch ───────────────────

	run_case("faction_sell_menu_prices_via_the_faction_lane_not_archies_cut", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["player"]["orichalchum"]["time"] = 10
		Economy.adjust_sell_qty("ore_time", 3, 10)
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()

		assert_true(_label_texts(layer).has("Trade with The Collective"), "heading names the faction, not 'Find a buyer'")
		# time basePrice 60, collective relation 0 -> sell spread 0.45 -> 33/unit -> 3*33=99
		assert_true(_label_texts(layer).has("You'll get: £99"), "gross reflects the collective's price, not archie's basePrice/cut split")

		layer.free()
	)

	run_case("faction_sell_menu_go_button_sells_appends_a_bark_and_opens_sale_result", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["player"]["orichalchum"]["time"] = 10
		Economy.adjust_sell_qty("ore_time", 2, 10)
		Modal.open("sell_menu", { "factionId": "collective", "contactId": "des" })

		var layer := ModalLayer.new()
		layer._ready()

		var go_button := _find_button(layer, "Go — trade")
		assert_true(go_button != null, "faction sell menu has a Go button")
		go_button.pressed.emit()

		assert_eq(GameState.state["player"]["cash"], 40 + 66, "2 units at 33/unit credited, no cut")
		assert_eq(GameState.state["messages"]["des"].size(), 1, "completing the trade appends a bark to des's conversation")
		assert_eq(GameState.state["modal"]["type"], "sale_result", "sale_result reused for the faction lane, same as Archie's")

		layer.free()
	)

	run_case("non_press_input_on_the_dim_does_not_close_the_modal", func():
		GameState.reset()
		Modal.open("seed_result", { "success": true, "oreType": "time" })

		var layer := ModalLayer.new()
		layer._ready()

		var release := InputEventScreenTouch.new()
		release.pressed = false
		layer._on_dim_gui_input(release)

		assert_eq(GameState.state["modal"]["type"], "seed_result", "a release event doesn't dismiss the modal")

		layer.free()
	)
