extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const EventPlay := preload("res://tests/support/event_play.gd")

# collective-act2 08, spec.md §5.4/§6.10/§6.11: the col_a2_force_vein_loss op
# (Collective.force_vein_loss()), T11's target pick, and the T10 -> T11
# delivery chain (Collective.maybe_trigger_a2_crack()).


func _site_of(vein_id: String) -> Variant:
	for site in GameState.state["world"]["sites"]:
		if site["factionVein"] != null and site["factionVein"]["id"] == vein_id:
			return site
	return null


func _play_pending(contact_id: String, kind: String) -> void:
	for entry in Messages.pending_for(contact_id):
		if entry["kind"] == kind:
			Messages.resolve_pending(entry["id"])
			EventPlay.play_event(kind, entry["payload"])
			return
	assert_true(false, "no pending %s from %s" % [kind, contact_id])


func _pending_count(contact_id: String, kind: String) -> int:
	var count := 0
	for entry in Messages.pending_for(contact_id):
		if entry["kind"] == kind:
			count += 1
	return count


func run() -> void:
	# ── col_a2_force_vein_loss ─────────────────────────────────────────────

	run_case("force_vein_loss_moves_exactly_the_named_collective_vein_to_the_firm", func():
		GameState.reset()
		Fixtures.seed_faction_vein("fv_hakim", 60)
		Fixtures.seed_faction_vein("fv_other", 60)

		assert_true(Collective.force_vein_loss("fv_hakim", "firm"))
		assert_eq(_site_of("fv_hakim")["factionVein"]["factionId"], "firm")
		assert_eq(_site_of("fv_other")["factionVein"]["factionId"], "collective", "only the named vein moves")
	)

	run_case("force_vein_loss_is_unconditional_whatever_the_veins_security", func():
		GameState.reset()
		var vein := Fixtures.seed_faction_vein("fv_hakim", 60)
		vein["security"] = "guarded"
		vein["extraGuards"] = 5

		assert_true(Collective.force_vein_loss("fv_hakim", "firm"))
		assert_eq(vein["factionId"], "firm")
	)

	run_case("force_vein_loss_no_ops_once_the_site_has_changed_hands", func():
		GameState.reset()
		var vein := Fixtures.seed_faction_vein("fv_hakim", 60, "guild")

		assert_true(not Collective.force_vein_loss("fv_hakim", "firm"))
		assert_eq(vein["factionId"], "guild", "someone else's vein is left alone")

		assert_true(not Collective.force_vein_loss("no_such_vein", "firm"))
		assert_true(not Collective.force_vein_loss(null, "firm"))
	)

	run_case("force_vein_loss_takes_a_player_vein_and_no_ops_on_a_repeat", func():
		GameState.reset()
		Fixtures.seed_vein("v_target", 40)
		Fixtures.seed_vein("v_other", 40)

		assert_true(Collective.force_vein_loss("v_target", "firm"))
		var site: Dictionary = Sites.find_site("site_v_target")
		assert_eq(site["factionVein"]["factionId"], "firm")
		assert_true(not site["claimed"])
		assert_true(Cultivating.find_vein("v_target") == null)
		assert_true(Cultivating.find_vein("v_other") != null, "only the named vein goes")

		assert_true(not Collective.force_vein_loss("v_target", "firm"), "already transferred -- no-op")
		assert_eq(site["factionVein"]["factionId"], "firm")
	)

	# ── T11's target ──────────────────────────────────────────────────────

	run_case("second_loss_targets_the_vein_nadia_had_defended", func():
		GameState.reset()
		Fixtures.seed_vein("v_defended", 40)
		var strong := Fixtures.seed_vein("v_strong", 40)
		strong["security"] = "guarded"
		GameState.state["collective"]["nadiaDefendVeinId"] = "v_defended"

		assert_eq(Collective.second_loss_target_id(), "v_defended")
	)

	run_case("second_loss_falls_back_to_the_highest_security_player_vein", func():
		GameState.reset()
		Fixtures.seed_vein("v_weak", 40)
		var strong := Fixtures.seed_vein("v_strong", 40)
		strong["security"] = "warded"
		Fixtures.seed_faction_vein("fv_guarded", 40)["security"] = "guarded"

		assert_eq(Collective.second_loss_target_id(), "v_strong", "mission never started")

		GameState.state["collective"]["nadiaDefendVeinId"] = "v_sold_since"
		assert_eq(Collective.second_loss_target_id(), "v_strong", "named vein no longer the player's")
	)

	run_case("second_loss_falls_back_to_the_collectives_own_veins_when_the_player_holds_none", func():
		GameState.reset()
		Fixtures.seed_faction_vein("fv_basic", 40)["security"] = "basic"
		Fixtures.seed_faction_vein("fv_guarded", 40)["security"] = "guarded"
		Fixtures.seed_faction_vein("fv_firm", 40, "firm")["security"] = "guarded"

		assert_eq(Collective.second_loss_target_id(), "fv_guarded", "highest-security Collective vein, never the Firm's")
	)

	# ── Hakim's handback keeps hakimVeinId pointing at his vein ─────────────

	run_case("hakim_handback_repoints_hakimVeinId_at_the_collectives_vein", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [Fixtures.site("s1", "emotion", "fair", true, null, "whitechapel")]
		GameState.state["player"]["veins"] = [Fixtures.player_vein("v1", "s1", "whitechapel", "emotion", 61, "fair")]
		GameState.state["collective"]["hakimVeinId"] = "v1"
		GameState.state["flags"]["colA1HakimRescued"] = true

		EventPlay.play_event("col_a1_hakim_done")

		var faction_vein: Dictionary = Sites.find_site("s1")["factionVein"]
		assert_eq(faction_vein["factionId"], "collective")
		assert_eq(GameState.state["collective"]["hakimVeinId"], faction_vein["id"])
	)

	# ── T10 -> T11 delivery chain ─────────────────────────────────────────

	run_case("crack_waits_for_the_checkpoint", func():
		GameState.reset()
		var hakim := Fixtures.seed_faction_vein("fv_hakim", 60)
		GameState.state["collective"]["hakimVeinId"] = "fv_hakim"

		assert_true(not Collective.maybe_trigger_a2_crack())
		assert_eq(hakim["factionId"], "collective")
	)

	run_case("crack_waits_while_another_act2_beat_is_pending", func():
		GameState.reset()
		Fixtures.seed_faction_vein("fv_hakim", 60)
		GameState.state["collective"]["hakimVeinId"] = "fv_hakim"
		GameState.state["flags"]["colA2CheckpointSeen"] = true
		Messages.queue_pending("nadia", "col_a2_checkpoint", "x")

		assert_true(not Collective.maybe_trigger_a2_crack())
		assert_true(not GameState.state["flags"].get("colA2HakimVeinLost", false))
	)

	run_case("hakim_vein_lost_then_second_loss_in_order", func():
		GameState.reset()
		var hakim := Fixtures.seed_faction_vein("fv_hakim", 60)
		GameState.state["collective"]["hakimVeinId"] = "fv_hakim"
		Fixtures.seed_vein("v_defended", 40)
		Fixtures.seed_vein("v_other", 40)
		GameState.state["collective"]["nadiaDefendVeinId"] = "v_defended"
		GameState.state["flags"]["colA2CheckpointSeen"] = true

		assert_true(Collective.maybe_trigger_a2_crack(), "T10 queues")
		assert_eq(hakim["factionId"], "firm", "the yard's gone by the time his text lands")
		assert_eq(_pending_count("hakim", Collective.HAKIM_VEIN_LOST_KIND), 1)

		assert_true(not Collective.maybe_trigger_a2_crack(), "T11 waits until T10's been read")
		assert_eq(_pending_count("nadia", Collective.SECOND_LOSS_KIND), 0)

		_play_pending("hakim", Collective.HAKIM_VEIN_LOST_KIND)
		assert_eq(GameState.state["currentScreen"], "phone")

		assert_true(Collective.maybe_trigger_a2_crack(), "T11 queues")
		assert_eq(_pending_count("nadia", Collective.SECOND_LOSS_KIND), 1)
		assert_true(Cultivating.find_vein("v_defended") != null, "second loss lands on T11's on_complete, not before")

		_play_pending("nadia", Collective.SECOND_LOSS_KIND)
		assert_true(GameState.state["flags"]["colA2SecondLossSeen"])
		assert_true(Cultivating.find_vein("v_defended") == null)
		assert_eq(Sites.find_site("site_v_defended")["factionVein"]["factionId"], "firm")
		assert_true(Cultivating.find_vein("v_other") != null)

		assert_true(not Collective.maybe_trigger_a2_crack(), "both beats done -- never again")
		assert_eq(_pending_count("hakim", Collective.HAKIM_VEIN_LOST_KIND) + _pending_count("nadia", Collective.SECOND_LOSS_KIND), 0)
	)
