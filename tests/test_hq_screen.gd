extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")
const UiSim := preload("res://tests/support/ui_sim.gd")

# hq-diorama ticket 02: HqScreen is now the single room plate
# (scenes/components/hq_diorama.gd rendering GameData.HQ_VISUALS["rooms"])
# instead of a scrolling card stack. Zone-dispatch tests below simulate a
# tap by building a synthetic InputEventScreenTouch at a region's own
# centre point (read from HqDiorama.region_rects(), never a hardcoded
# coordinate) and feeding it through hq._on_diorama_gui_input() -- the same
# path a real tap takes. What each destination actually renders (the old
# inline Security/Ore-store/Dial cards) is now covered by
# tests/test_modal_layer.gd's "hq_*" cases, since that's where the content
# moved to. Rooms (hq-diorama ticket 04) is the exception -- it's a
# full-bleed screen, not a Modal, so its own content is covered by
# tests/test_hq_floorplan.gd instead.


func run() -> void:
	run_case("hq_ready_starts_home_raid_intro_and_never_builds_the_normal_ui_when_pending_and_unseen", func():
		GameState.reset()
		GameState.state["flags"]["homeRaidEventPending"] = true
		GameState.state["flags"]["homeRaidEventSeen"] = false
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		assert_eq(GameState.state["currentScreen"], "event", "a qualifying HQ visit must start the event, same as the old home screen")
		assert_eq(GameState.state["event"]["eventId"], "home_raid_intro")
		assert_eq(hq.get_child_count(), 0, "the check must run before any room UI is ever added -- starting the event navigates away and this node is about to be freed")

		hq.free()
	)

	run_case("hq_ready_does_not_retrigger_once_the_event_has_been_seen", func():
		GameState.reset()
		# homeRaidEventPending stays true forever once set (per
		# systems/debug_start.gd's comment) -- homeRaidEventSeen is the only
		# thing gating a re-fire, so this is the true one-shot check.
		GameState.state["flags"]["homeRaidEventPending"] = true
		GameState.state["flags"]["homeRaidEventSeen"] = true
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_eq(GameState.state["currentScreen"], "hq", "already-seen must not start the event again")
		assert_true(hq._diorama != null, "the room plate must build once the one-shot has already fired")

		hq.free()
	)

	run_case("hq_ready_does_not_trigger_when_no_raid_is_pending", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_eq(GameState.state["currentScreen"], "hq", "a fresh game with nothing pending must render HQ normally")
		assert_true(hq._diorama != null, "the room plate must render on a normal HQ visit")

		hq.free()
	)

	# ── locked HQ: no room plate yet, Rest/Defend stay reachable ──────────

	# bugfixes ticket 104: the locked fallback used to show a plain "Locked"
	# heading with no visual link to the room -- it now paints the bedsit
	# plate's own background image (via a second, region-less HqDiorama, kept
	# out of hq._diorama since it isn't the tappable room view) behind the
	# same Rest/Defend/Back buttons.
	run_case("hq_locked_view_shows_the_bedsit_background_and_no_room_plate", func():
		GameState.reset()
		# homeUnlocked defaults false (autoload/GameState.gd) for the whole
		# pre-raid stretch of a fresh game.
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(hq._diorama == null, "the room plate has nothing to show while HQ is locked")
		var dioramas := hq.find_children("", "HqDiorama", true, false)
		assert_eq(dioramas.size(), 1, "the locked view must show exactly one background diorama")
		var background := dioramas[0] as HqDiorama
		assert_eq(background.region_rects().size(), 0, "the locked background must have no per-hotspot regions -- out of scope for this ticket")
		assert_eq(background._plate.get("image", ""), GameData.HQ_VISUALS["rooms"]["bedsit"]["image"], "the locked background must reuse the bedsit plate's own image")

		hq.free()
	)

	run_case("hq_rest_action_is_reachable_even_while_hq_is_locked", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(NodeQuery.find_button(hq, "Rest — next morning") != null, "Rest must render even on a locked HQ visit")

		hq.free()
	)

	run_case("hq_locked_view_shows_a_defend_button_while_a_raid_is_pending", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		GameState.state["home"]["pendingRaid"] = true
		GameState.state["home"]["pendingRaidNotificationId"] = "n1"

		var hq := HqScreen.new()
		hq._ready()

		var defend_button := NodeQuery.find_button(hq, "Defend")
		assert_true(defend_button != null, "Defend must render on the locked fallback while a raid is pending")

		defend_button.pressed.emit()

		assert_true(GameState.state["combat"]["active"], "tapping Defend should start combat immediately")
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_HOME_ALARM_DEFEND)
		assert_true(not GameState.state["home"]["pendingRaid"], "the pending raid should be popped from the queue")

		hq.free()
	)

	run_case("hq_locked_view_has_no_defend_button_when_nothing_is_pending", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(NodeQuery.find_button(hq, "Defend") == null, "Defend must not render with no raid pending")

		hq.free()
	)

	# hq-diorama ticket 02: the old HQ-screen Defend shortcut is intentionally
	# not carried into the normal (unlocked) room view -- §8's hostile-door
	# state is ticket 5's job, and a pending raid stays reachable via the
	# Notifications app's own Defend button in the meantime (phone.gd), so
	# this isn't a lost mechanic, just a removed redundant entry point.
	run_case("hq_room_view_has_no_defend_shortcut_even_while_a_raid_is_pending", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["home"]["pendingRaid"] = true
		GameState.state["home"]["pendingRaidNotificationId"] = "n1"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(NodeQuery.find_button(hq, "Defend") == null, "the room view has no Defend shortcut -- ticket 5's hostile-door state owns this now")

		hq.free()
	)

	# ── the room plate and its zones ──────────────────────────────────────

	run_case("hq_room_view_builds_a_diorama_sized_to_the_bedsit_plate", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		assert_true(hq._diorama != null, "sanity: the room plate must build")
		assert_eq(hq._diorama.size, Vector2(390, 660), "the diorama must be sized to the bedsit plate's own width/height")

		hq.free()
	)

	run_case("hq_room_view_falls_back_to_the_bedsit_plate_for_a_tier_with_no_manifest_entry_yet", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		# v1 (docs/hq-diorama-vision.md §10) ships only the bedsit plate --
		# a player already at a later tier (art not shipped yet) must still
		# get a navigable room, not a crash or a blank screen.
		GameState.state["home"]["tier"] = "townhouse"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(hq._diorama != null, "a tier with no manifest entry must still render a room, falling back to bedsit")
		assert_eq(hq._diorama.size, Vector2(390, 660), "the fallback must be the bedsit plate's own size")

		hq.free()
	)

	# hq-diorama ticket 09: the Dial is a full-bleed screen, not a Modal (see
	# tests/test_hq_dial.gd for what it renders).
	run_case("hq_dial_zone_tap_navigates_to_the_hq_dial_screen", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		UiSim.tap_zone(hq, "dial")
		assert_eq(GameState.state["currentScreen"], "hq_dial", "tapping the Dial zone must navigate to the loadout sub-view, no modal")
		assert_eq(GameState.state["modal"], null, "the Dial sub-view is not a modal")

		hq.free()
	)

	# hq-diorama ticket 06: the Lab zone now opens the diegetic bench
	# sub-view (docs/hq-diorama-vision.md §5) instead of lab.gd's old
	# picker/pairing screen -- see tests/test_hq_lab_bench.gd for that
	# screen's own coverage.
	run_case("hq_lab_zone_tap_navigates_to_the_hq_lab_bench_screen", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["currentScreen"] = "hq"
		GameState.state["labBenchNav"]["stop"] = "apparatus"

		var hq := HqScreen.new()
		hq._ready()

		UiSim.tap_zone(hq, "lab")

		assert_eq(GameState.state["currentScreen"], "hq_lab_bench", "tapping the Lab zone must open the bench sub-view")
		assert_eq(GameState.state["labBenchNav"]["stop"], "books_ore", "LabBenchNav.open() must land the bench on its own books+ore stop, same as any fresh visit (§5.1)")

		hq.free()
	)

	# hq-diorama ticket 05: the door is a full-bleed screen, not a Modal (see
	# tests/test_hq_door.gd for what it renders).
	run_case("hq_security_zone_tap_navigates_to_the_hq_door_screen", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		UiSim.tap_zone(hq, "security")
		assert_eq(GameState.state["currentScreen"], "hq_door", "tapping the Security zone must navigate to the door sub-view, no modal")
		assert_eq(GameState.state["modal"], null, "the door sub-view is not a modal")

		hq.free()
	)

	# §8: "while a raid is pending ... tapping it opens Defend instead of the
	# security list" -- Home.trigger_defend() is the same "start combat
	# directly" call the locked-view Defend button uses (see
	# "hq_locked_view_shows_a_defend_button_while_a_raid_is_pending" above).
	run_case("hq_security_zone_tap_opens_defend_instead_of_the_door_screen_while_a_raid_is_pending", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["home"]["pendingRaid"] = true
		GameState.state["home"]["pendingRaidNotificationId"] = "n1"

		var hq := HqScreen.new()
		hq._ready()

		UiSim.tap_zone(hq, "security")

		assert_true(GameState.state["combat"]["active"], "tapping the hostile door must start combat immediately, same as the Defend button")
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_HOME_ALARM_DEFEND)
		assert_true(not GameState.state["home"]["pendingRaid"], "the pending raid should be popped from the queue")
		assert_eq(GameState.state["currentScreen"], "combat", "Combat.start_home_alarm_defend_combat() navigates to the combat screen, not the door sub-view")
		assert_eq(GameState.state["modal"], null)

		hq.free()
	)

	# §8: a pending raid is announced through notifications; the room plate
	# itself stays as authored.
	run_case("hq_room_plate_leaves_the_security_label_unchanged_while_a_raid_is_pending", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["home"]["pendingRaid"] = true
		GameState.state["home"]["pendingRaidNotificationId"] = "n1"

		var hq := HqScreen.new()
		hq._ready()

		var rendered_region: Dictionary = hq._diorama._plate["regions"]["security"]
		assert_eq(rendered_region["label"], "Security", "a pending raid must not relabel the security region")

		hq.free()
	)

	# ── Studio and Flat plates (docs/hq-diorama-vision.md §3.1): zones baked into the art ─
	for tier in ["studio", "flat"]:
		run_case("hq_%s_tier_renders_its_own_plate_with_no_placeholder_boxes" % tier, func():
			GameState.reset()
			GameState.state["flags"]["homeUnlocked"] = true
			GameState.state["home"]["tier"] = tier

			var hq := HqScreen.new()
			hq._ready()

			assert_eq(hq._diorama._plate["image"], "res://assets/hq/%s_room.png" % tier)
			var regions: Dictionary = hq._diorama._plate["regions"]
			for region_id in regions:
				assert_true(not hq._diorama._should_draw_placeholder(region_id, regions[region_id]), "%s region '%s' must not draw a placeholder box" % [tier, region_id])

			hq.free()
		)

		run_case("hq_%s_rest_caption_sits_inside_the_bed_polygon" % tier, func():
			GameState.reset()
			GameState.state["flags"]["homeUnlocked"] = true
			GameState.state["home"]["tier"] = tier

			var hq := HqScreen.new()
			hq._ready()

			assert_eq(hq._diorama._captions.size(), 1, "sanity: only the rest region carries a caption")
			var caption: Label = hq._diorama._captions[0]
			assert_eq(caption.text, GameData.DAY_CLOCK["restLabel"])
			var centre := caption.position + Vector2(caption.size.x / 2.0, caption.get_minimum_size().y / 2.0)
			assert_eq(hq._diorama.zone_at(centre), "rest", "the rest caption's centre must fall on the bed's traced polygon")

			hq.free()
		)

		run_case("hq_%s_zone_taps_open_their_menus" % tier, func():
			var expectations := {
				"security": func(): return GameState.state["currentScreen"] == "hq_door",
				"lab": func(): return GameState.state["currentScreen"] == "hq_lab_bench",
				"dial": func(): return GameState.state["currentScreen"] == "hq_dial",
				"rooms": func(): return GameState.state["currentScreen"] == "hq_floorplan",
				"oreStore": func(): return GameState.state["modal"] != null and GameState.state["modal"]["type"] == "hq_ore_readout",
				"gym": func(): return GameState.state["modal"] != null and GameState.state["modal"]["type"] == "hq_gym",
				"rest": func(): return GameState.state["world"]["timeBlock"] == 0,
			}
			for zone_id in expectations:
				GameState.reset()
				GameState.state["flags"]["homeUnlocked"] = true
				GameState.state["home"]["tier"] = tier
				GameState.state["currentScreen"] = "hq"
				GameState.state["world"]["timeBlock"] = 2

				var hq := HqScreen.new()
				hq._ready()
				UiSim.tap_zone(hq, zone_id)
				assert_true(expectations[zone_id].call(), "tapping %s zone '%s' must open its menu" % [tier, zone_id])
				hq.free()
		)

		run_case("hq_%s_lock_installed_changes_nothing_on_the_plate" % tier, func():
			GameState.reset()
			GameState.state["flags"]["homeUnlocked"] = true
			GameState.state["home"]["tier"] = tier
			GameState.state["home"]["security"] = ["lock"]

			var hq := HqScreen.new()
			hq._ready()

			assert_eq(hq._diorama._plate["regions"]["security"], GameData.HQ_VISUALS["rooms"][tier]["regions"]["security"], "%s has no installedImage, so a lock must leave its security region as authored" % tier)

			hq.free()
		)

	# hq-diorama ticket 10: the Reinforced Lock is the first HQ visual that
	# varies with real per-save state (state.home.security) rather than tier
	# alone -- see hq.gd's _security_lock_installed_plate().
	run_case("hq_room_plate_shows_the_installed_lock_image_once_the_lock_is_bought", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["home"]["security"] = ["lock"]

		var hq := HqScreen.new()
		hq._ready()

		var rendered_region: Dictionary = hq._diorama._plate["regions"]["security"]
		var expected_image: String = GameData.HQ_VISUALS["rooms"]["bedsit"]["regions"]["security"]["installedImage"]
		assert_eq(rendered_region["image"], expected_image, "once 'lock' is installed, the security region must render installedImage instead of image")
		assert_eq(GameData.HQ_VISUALS["rooms"]["bedsit"]["regions"]["security"]["image"], "res://assets/hq/regions/bedsit_security.png", "the source manifest itself must be untouched -- GameData.HQ_VISUALS is loaded once at boot and must never be mutated")

		hq.free()
	)

	run_case("hq_room_plate_shows_the_empty_lock_image_before_the_lock_is_bought", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		var rendered_region: Dictionary = hq._diorama._plate["regions"]["security"]
		assert_eq(rendered_region["image"], "res://assets/hq/regions/bedsit_security.png", "with no lock installed, the security region must render the plain-door image")

		hq.free()
	)

	# hq-diorama ticket 04: the floorplan is a full-bleed screen, not a Modal
	# (see tests/test_hq_floorplan.gd for what it renders).
	run_case("hq_rooms_zone_tap_navigates_to_the_hq_floorplan_screen", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		UiSim.tap_zone(hq, "rooms")
		assert_eq(GameState.state["currentScreen"], "hq_floorplan", "tapping the Rooms zone must navigate to the floorplan sub-view, no modal")
		assert_eq(GameState.state["modal"], null, "the floorplan is not a modal")

		hq.free()
	)

	run_case("hq_ore_store_zone_tap_opens_the_hq_ore_readout_modal", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		UiSim.tap_zone(hq, "oreStore")
		assert_eq(GameState.state["modal"]["type"], "hq_ore_readout", "tapping the Ore store zone must open its destination readout modal, not a sub-view")

		hq.free()
	)

	run_case("hq_rest_zone_tap_performs_the_rest_action_directly_with_no_intermediate_view", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["world"]["day"] = 3
		GameState.state["world"]["timeBlock"] = 2
		GameState.state["player"]["hp"] = 50
		GameState.state["player"]["hpMax"] = 100

		var hq := HqScreen.new()
		hq._ready()

		UiSim.tap_zone(hq, "rest")

		assert_eq(GameState.state["modal"], null, "Rest must act directly, with no intermediate modal or view")
		assert_eq(GameState.state["world"]["day"], 4, "tapping Rest must advance the day, same as TimeSystem.do_rest()")
		assert_eq(GameState.state["world"]["timeBlock"], 0, "tapping Rest must reset the time block")
		# do_rest's daily_tick also fires passive regen (bugfixes-42): 50 + round(100*0.05) = 55,
		# then the rest heal itself: 55 + round(100*0.2) = 75.
		assert_eq(GameState.state["player"]["hp"], 75, "50 + passive regen 5 + rest heal 20 = 75, same as TimeSystem.do_rest()")

		hq.free()
	)

	run_case("hq_tapping_outside_every_region_opens_nothing", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		# The bedsit plate is 390x660 (data/hq_visuals.json); none of its
		# regions cover this corner (see that manifest's own region rects).
		hq._on_diorama_gui_input(UiSim.tap_at(Vector2(2, 2)))

		assert_eq(GameState.state["modal"], null, "a tap outside every region must not open anything")

		hq.free()
	)

	run_case("hq_non_press_input_on_the_diorama_does_nothing", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		# hq-diorama ticket 09: "dial" no longer opens a modal (it navigates to
		# the full-bleed hq_dial.gd screen instead) -- "oreStore" still does,
		# so this generic "release does nothing" check keeps using a
		# modal-opening zone to catch a regression.
		var release := InputEventScreenTouch.new()
		release.pressed = false
		release.position = hq._diorama.region_rects()["oreStore"].get_center()
		hq._on_diorama_gui_input(release)

		assert_eq(GameState.state["modal"], null, "a release event must not dispatch a zone tap")

		hq.free()
	)

	# hq-diorama ticket 02: Gym is wired into the bedsit plate despite §3.1's
	# own "First tier present" being "flat" -- a deliberate, human-approved
	# deviation (see hq.gd's own top-of-file comment and data/hq_visuals.
	# json's "gymDeviation" meta note). What the destination modal itself
	# renders (Train button/gating) is covered by tests/test_modal_layer.gd's
	# "hq_gym_*" cases, same split every other zone's destination content uses.
	run_case("hq_gym_zone_tap_opens_the_hq_gym_modal", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		UiSim.tap_zone(hq, "gym")
		assert_eq(GameState.state["modal"]["type"], "hq_gym", "tapping the Gym zone must open its destination modal")

		hq.free()
	)

	# ── debug region overlay (ticket 01) ───────────────────────────────────

	run_case("hq_debug_regions_button_toggles_the_diorama_overlay_and_survives_a_refresh", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		assert_true(not hq._diorama.is_debug_overlay_enabled(), "the debug overlay must default to off")

		NodeQuery.find_button(hq, "Debug regions").pressed.emit()
		assert_true(hq._diorama.is_debug_overlay_enabled(), "the Debug regions button must toggle the overlay on")

		hq._refresh()
		assert_true(hq._diorama.is_debug_overlay_enabled(), "the toggle must survive a same-session _refresh(), same as the old collapsible-section persistence pattern")

		hq.free()
	)

	# ── traced zone polygons (docs/hq-diorama-vision.md §3.2) ──────────────

	run_case("hq_studio_tap_inside_a_zone_polygon_routes_to_that_zone", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["home"]["tier"] = "studio"
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(hq._diorama._plate["regions"]["dial"].has("polygon"), "studio's Dial must carry a traced polygon for this case to mean anything")
		UiSim.tap_zone(hq, "dial")
		assert_eq(GameState.state["currentScreen"], "hq_dial", "a tap inside the Dial polygon must route to the Dial")

		hq.free()
	)

	run_case("hq_studio_tap_in_overlapping_boxes_but_outside_both_polygons_opens_nothing", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["home"]["tier"] = "studio"
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		var rects: Dictionary = hq._diorama.region_rects()
		var ids: Array = rects.keys()
		var gap := Vector2(-1, -1)
		for i in ids.size():
			for j in range(i + 1, ids.size()):
				var overlap: Rect2 = (rects[ids[i]] as Rect2).intersection(rects[ids[j]])
				for x in range(int(overlap.position.x), int(overlap.end.x)):
					for y in range(int(overlap.position.y), int(overlap.end.y)):
						if gap.x < 0 and hq._diorama.zone_at(Vector2(x, y)) == "":
							gap = Vector2(x, y)
		assert_true(gap.x >= 0, "some point where two studio boxes overlap must fall outside every polygon")

		hq._on_diorama_gui_input(UiSim.tap_at(gap))
		assert_eq(GameState.state["currentScreen"], "hq", "a tap in the boxes but outside every polygon must not navigate")
		assert_eq(GameState.state["modal"], null, "a tap in the boxes but outside every polygon must not open a modal")

		hq.free()
	)

	run_case("hq_bedsit_zones_without_polygons_hit_test_their_rects", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		var regions: Dictionary = hq._diorama._plate["regions"]
		for zone_id in regions:
			assert_true(not regions[zone_id].has("polygon"), "bedsit zone '%s' must have no polygon" % zone_id)
			var rect := HqDiorama.region_rect(regions[zone_id])
			assert_eq(hq._diorama.zone_at(rect.position), zone_id, "rect's top-left corner must hit '%s'" % zone_id)
			assert_eq(hq._diorama.zone_at(rect.get_center()), zone_id, "rect's centre must hit '%s'" % zone_id)
			assert_eq(hq._diorama.zone_at(rect.end - Vector2(0.5, 0.5)), zone_id, "rect's inner bottom-right must hit '%s'" % zone_id)

		hq.free()
	)
