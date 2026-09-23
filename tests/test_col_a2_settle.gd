extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const EventPlay := preload("res://tests/support/event_play.gd")

# collective-act2 11, spec.md §5.6/§6.14/§6.15/§7.4: the Act 2 gate,
# T14's spine reward (Hakim's text + the weak-vein branch of his intel
# roll), and T15's col_a2_closer delivery and on_complete.


func _meet_gate() -> void:
	var method_log: Dictionary = GameState.state["methodLog"]
	method_log["a2ContestedVein"] = "force"
	method_log["a2VulnerableSite"] = "lookout"
	method_log["a2HostileMember"] = "protected"
	GameState.state["flags"]["colA2HakimRetaken"] = true
	GameState.state["factions"]["collective"]["relation"] = 50


func _fill_hakim_intel_districts() -> void:
	var sites: Array = GameState.state["world"]["sites"]
	for district in Collective.HAKIM_INTEL_DISTRICTS:
		for i in range(GameData.DISTRICTS[district]["siteCap"]):
			sites.append(Fixtures.site("cap_%s_%d" % [district, i], "time", "poor", false, null, district))


func _soft_firm_vein(id: String) -> Dictionary:
	var vein := Fixtures.seed_faction_vein(id, 60, "firm")
	vein["security"] = "none"
	return vein


func _roll_until_hit() -> bool:
	for seed in range(300):
		Rng.set_seed(seed)
		if Collective.maybe_trigger_hakim_intel():
			return true
	return false


func run() -> void:
	# ── §7.4 gate ───────────────────────────────────────────────────────────

	run_case("act2_gate_needs_every_part", func():
		GameState.reset()
		_meet_gate()
		assert_true(Collective.act2_gate_met())
		for key in Collective.ACT2_METHOD_KEYS:
			GameState.reset()
			_meet_gate()
			GameState.state["methodLog"].erase(key)
			assert_true(not Collective.act2_gate_met(), "missing %s" % key)
		GameState.reset()
		_meet_gate()
		GameState.state["flags"]["colA2HakimRetaken"] = false
		assert_true(not Collective.act2_gate_met(), "vein not retaken")
		GameState.reset()
		_meet_gate()
		GameState.state["factions"]["collective"]["relation"] = 49
		assert_true(not Collective.act2_gate_met(), "relation 49")
	)

	# ── T14 ─────────────────────────────────────────────────────────────────

	run_case("spine_reward_fires_once_with_hakims_text", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 10
		assert_true(not Collective.maybe_trigger_a2_spine_reward(), "gate not met")
		_meet_gate()
		var before: int = GameState.state["messages"].get("hakim", []).size()
		assert_true(Collective.maybe_trigger_a2_spine_reward())
		assert_true(GameState.state["flags"]["colA2SpineReward"])
		assert_eq(GameState.state["messages"]["hakim"].size(), before + 1)
		assert_true(not Collective.maybe_trigger_a2_spine_reward(), "never twice")
		assert_eq(GameState.state["messages"]["hakim"].size(), before + 1)
	)

	run_case("spine_reward_fires_off_t13s_own_relation_award", func():
		GameState.reset()
		_meet_gate()
		GameState.state["flags"]["colA2HakimRetaken"] = false
		GameState.state["factions"]["collective"]["relation"] = 40
		var vein := Fixtures.seed_faction_vein("fv_hakim", 60, "firm")
		GameState.state["collective"]["hakimVeinId"] = vein["id"]
		GameState.state["player"]["cash"] = 1000000
		EventPlay.play_event_with_choices("col_a2_hakim_retake", [1])
		assert_true(GameState.state["flags"]["colA2HakimRetaken"])
		assert_true(GameState.state["flags"]["colA2SpineReward"], "Events.advance() checks the gate after T13's +15")
	)

	# ── §5.6 intel extension ────────────────────────────────────────────────

	run_case("hakim_intel_never_flags_a_weak_vein_before_t14", func():
		GameState.reset()
		GameState.state["flags"]["hakimIntelUnlocked"] = true
		GameState.state["world"]["day"] = 20
		_fill_hakim_intel_districts()
		_soft_firm_vein("fv_soft")
		assert_true(not _roll_until_hit(), "no fresh ground and no spine reward -- nothing to roll")
	)

	run_case("hakim_intel_flags_a_soft_enemy_vein_after_t14", func():
		GameState.reset()
		GameState.state["flags"]["hakimIntelUnlocked"] = true
		GameState.state["flags"]["colA2SpineReward"] = true
		GameState.state["world"]["day"] = 20
		_fill_hakim_intel_districts()
		_soft_firm_vein("fv_soft")
		var hard := Fixtures.seed_faction_vein("fv_hard", 60, "firm")
		hard["security"] = "warded"
		Fixtures.seed_faction_vein("fv_ours", 60, "collective")["security"] = "none"

		assert_true(_roll_until_hit())
		var pending := Messages.pending_for("hakim")
		assert_eq(pending.size(), 1)
		assert_eq(pending[0]["kind"], Collective.HAKIM_INTEL_WEAK_KIND)
		assert_eq(pending[0]["payload"]["site_id"], "site_fv_soft", "only the soft enemy vein qualifies")
		assert_true(not _roll_until_hit(), "an unread weak-vein text blocks another roll")

		Messages.resolve_pending(pending[0]["id"])
		EventPlay.play_event(Collective.HAKIM_INTEL_WEAK_KIND, pending[0]["payload"])
		assert_eq(NetworkHandler.claim_bonus("site_fv_soft"), NetworkHandler.CLAIM_BONUS_MAGNITUDE)
		assert_eq(GameState.state["collective"]["hakimIntelLastDay"], 20)
	)

	run_case("hakim_intel_rolls_both_branches_after_t14", func():
		var saw_site := false
		var saw_weak := false
		for seed in range(300):
			GameState.reset()
			GameState.state["flags"]["hakimIntelUnlocked"] = true
			GameState.state["flags"]["colA2SpineReward"] = true
			GameState.state["world"]["day"] = 20
			_soft_firm_vein("fv_soft")
			Rng.set_seed(seed)
			if Collective.maybe_trigger_hakim_intel():
				var kind: String = Messages.pending_for("hakim")[0]["kind"]
				saw_site = saw_site or kind == "col_hakim_intel"
				saw_weak = saw_weak or kind == Collective.HAKIM_INTEL_WEAK_KIND
		assert_true(saw_site and saw_weak, "site %s, weak %s" % [saw_site, saw_weak])
	)

	# ── T15 ─────────────────────────────────────────────────────────────────

	run_case("closer_queues_after_t14_and_completes_the_act", func():
		GameState.reset()
		assert_true(not Collective.maybe_trigger_a2_closer(), "no spine reward yet")
		GameState.state["flags"]["colA2SpineReward"] = true
		assert_true(Collective.maybe_trigger_a2_closer())
		assert_true(not Collective.maybe_trigger_a2_closer(), "already pending")
		var pending := Messages.pending_for("nadia")
		assert_eq(pending[0]["kind"], "col_a2_closer")

		Messages.resolve_pending(pending[0]["id"])
		EventPlay.play_event("col_a2_closer")
		assert_true(GameState.state["flags"]["colA2Complete"])
		assert_true(not Collective.maybe_trigger_a2_closer(), "never after colA2Complete")
	)

	run_case("daily_tick_delivers_t15_a_day_behind_t14", func():
		GameState.reset()
		_meet_gate()
		TimeSystem.daily_tick()
		assert_true(GameState.state["flags"]["colA2SpineReward"])
		assert_true(Messages.pending_for("nadia").filter(func(e): return e["kind"] == "col_a2_closer").is_empty(), "not the same tick")
		TimeSystem.daily_tick()
		assert_eq(Messages.pending_for("nadia").filter(func(e): return e["kind"] == "col_a2_closer").size(), 1)
	)
