extends "res://tests/test_base.gd"

# Bugfixes ticket 05: the standalone Veins tab (home's "Veins" button ->
# VeinsScreen, scenes/screens/veins.gd) has its own vein action row and hit
# the exact same three-button HBoxContainer overflow bug as the Network
# Map's site sheet (tests/test_map_screen.gd) — same UI.hflow() fix, same
# regression coverage.


func run() -> void:
	run_case("charged_vein_action_row_wraps_instead_of_a_fixed_hbox", func():
		GameState.reset()
		var level_data: Dictionary = GameData.VEIN_LEVELS["1"]
		var vein := {
			"id": "v1", "oreType": "time", "level": 1, "levelLabel": level_data["label"],
			"devBar": 0, "charged": true, "chargeBlocks": level_data["rechargeBlocks"],
			"security": "none", "location": "Test Alley",
		}

		var screen := VeinsScreen.new()
		var card: Control = screen._build_vein_card(vein)
		var actions: Control = card.find_children("", "HFlowContainer", true, false)[0]

		assert_true(actions is HFlowContainer, "action row must wrap instead of a fixed-width HBoxContainer")
		assert_eq(actions.get_child_count(), 3, "Cultivate + Harvest (cautious) + Harvest (full) all present when charged")

		card.free()
		screen.free()
	)

	run_case("uncharged_vein_action_row_has_only_cultivate", func():
		GameState.reset()
		var level_data: Dictionary = GameData.VEIN_LEVELS["1"]
		var vein := {
			"id": "v1", "oreType": "time", "level": 1, "levelLabel": level_data["label"],
			"devBar": 0, "charged": false, "chargeBlocks": 0,
			"security": "none", "location": "Test Alley",
		}

		var screen := VeinsScreen.new()
		var card: Control = screen._build_vein_card(vein)
		var actions: Control = card.find_children("", "HFlowContainer", true, false)[0]

		assert_eq(actions.get_child_count(), 1, "only Cultivate present when uncharged")

		card.free()
		screen.free()
	)

	# vein-raiding ticket 09: seeding is only reachable via an unclaimed
	# site's Sites.attempt_seed() flow now — the Veins screen's standalone
	# "Seed a new vein" card (Cultivating.seed()'s only UI entry point) is
	# gone, so no code path here can create a site-less vein.
	run_case("no_standalone_seed_action_on_the_veins_screen", func():
		GameState.reset()

		var screen := VeinsScreen.new()
		screen._ready()

		var headings: Array = screen._content.find_children("", "Label", true, false)
		var has_seed_heading := false
		for h in headings:
			if String(h.text).contains("Seed a new vein"):
				has_seed_heading = true

		assert_true(not has_seed_heading, "no 'Seed a new vein' card should remain on the Veins screen")

		screen.free()
	)
