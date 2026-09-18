extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")

# hq-diorama ticket 05, docs/hq-diorama-vision.md §8: the door sub-view,
# reached from hq.gd's "security" zone tap (see tests/test_hq_screen.gd's
# own "hq_security_zone_tap_navigates_to_the_hq_door_screen" and
# "..._opens_defend_instead_while_a_raid_is_pending"). Cases below are the
# direct port of the old modal_layer.gd "hq_security_list" modal cases
# (hq-diorama ticket 02) onto this screen -- same system calls, same
# assertions, minus the Modal.open()/Modal.close() plumbing a full-bleed
# screen doesn't have.
#
# HqDoorScreen.new() is safe to call _ready() on directly without adding it
# to a live scene tree, same reasoning tests/test_hq_floorplan.gd already
# relies on for HqFloorplanScreen.


func run() -> void:
	run_case("hq_door_shows_a_buy_button_for_an_available_uninstalled_security_option", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000

		var screen := HqDoorScreen.new()
		screen._ready()

		for security_id in GameData.HOME_SECURITY.keys():
			var sec: Dictionary = GameData.HOME_SECURITY[security_id]
			if sec["minTier"] != GameState.state["home"]["tier"]:
				continue
			assert_true(NodeQuery.label_texts(screen).any(func(t: String): return t.ends_with(sec["name"])), "%s's name must render" % security_id)

		screen.free()
	)

	run_case("hq_door_buy_button_installs_security_same_as_the_old_direct_row", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		var bedsit_security_id: String = GameData.HOME_SECURITY.keys().filter(func(k): return GameData.HOME_SECURITY[k]["minTier"] == "bedsit")[0]
		var cost: int = GameData.HOME_SECURITY[bedsit_security_id]["cost"]

		var screen := HqDoorScreen.new()
		screen._ready()

		NodeQuery.find_button(screen, "£%d" % cost).pressed.emit()

		assert_true(GameState.state["home"]["security"].has(bedsit_security_id), "tapping the buy button must install the security option, unchanged from the old direct row")

		screen.free()
	)

	run_case("hq_door_installed_security_shows_installed_not_a_buy_button", func():
		GameState.reset()
		var bedsit_security_id: String = GameData.HOME_SECURITY.keys().filter(func(k): return GameData.HOME_SECURITY[k]["minTier"] == "bedsit")[0]
		GameState.state["home"]["security"].append(bedsit_security_id)

		var screen := HqDoorScreen.new()
		screen._ready()

		var cost: int = GameData.HOME_SECURITY[bedsit_security_id]["cost"]
		assert_true(NodeQuery.find_button(screen, "£%d" % cost) == null, "an installed slot must not still show a buy button")
		assert_true(NodeQuery.label_texts(screen).has("Installed"), "an installed slot must show the Installed label")

		screen.free()
	)

	run_case("hq_door_locked_security_option_shows_locked_not_a_buy_button", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		# "ward" requires safehouse (data/home.json) -- a fresh bedsit-tier
		# game must show it locked, not purchasable.
		GameState.state["home"]["tier"] = "bedsit"

		var screen := HqDoorScreen.new()
		screen._ready()

		var ward_cost: int = GameData.HOME_SECURITY["ward"]["cost"]
		assert_true(NodeQuery.find_button(screen, "£%d" % ward_cost) == null, "a locked slot must not show a buy button")
		assert_true(NodeQuery.label_texts(screen).has("Locked"), "a locked slot must show the Locked label")

		screen.free()
	)

	run_case("hq_door_back_button_returns_to_hq", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq_door"

		var screen := HqDoorScreen.new()
		screen._ready()

		NodeQuery.find_button(screen, "‹ Back").pressed.emit()
		assert_eq(GameState.state["currentScreen"], "hq", "Back must return to the HQ room, not the phone home grid")

		screen.free()
	)
