extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const EventPlay := preload("res://tests/support/event_play.gd")

# collective-act2 10, spec.md §5.4/§6.13: the col_a2_hakim_retake event (force
# or buy), the col_a2_ruin_site op (Collective.ruin_hakim_site()), the
# Sites.attempt_seed() guard, and the Targets-purchase gate.

const RUIN_FLAG_SOURCE_DIRS: Array[String] = ["res://systems", "res://scenes", "res://autoload", "res://data"]


func _seed_firm_held_hakim_vein() -> Dictionary:
	var vein := Fixtures.seed_faction_vein("fv_hakim", 60, "firm")
	GameState.state["collective"]["hakimVeinId"] = "fv_hakim"
	return vein


func _collect_files(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_collect_files("%s/%s" % [dir_path, sub], out)
	for file in dir.get_files():
		if file.ends_with(".gd") or file.ends_with(".json") or file.ends_with(".tscn"):
			out.append("%s/%s" % [dir_path, file])


func run() -> void:
	# ── Sites.attempt_seed() guard ──────────────────────────────────────────

	run_case("attempt_seed_rejects_the_ruined_site_and_no_other", func():
		GameState.reset()
		var sites: Array = GameState.state["world"]["sites"]
		# Unclaimed on purpose, so only the ruinedByFirm guard can reject it.
		var ruined := Fixtures.site("s_ruined", "life", "fair")
		ruined["ruinedByFirm"] = true
		sites.append(ruined)
		sites.append(Fixtures.site("s_plain", "life", "fair"))
		GameState.state["player"]["orichalchum"]["life"] = GameData.SEED_ORE_COST * 2

		var rejected := Sites.attempt_seed("s_ruined")
		assert_true(not rejected["ok"], "the ruined site can't be seeded")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], GameData.SEED_ORE_COST * 2, "no ore spent on the ruined site")

		var accepted := Sites.attempt_seed("s_plain")
		assert_true(accepted["ok"], "an unflagged site seeds as normal: %s" % str(accepted))
	)

	# ── col_a2_ruin_site ────────────────────────────────────────────────────

	run_case("ruin_hakim_site_no_ops_unless_the_player_holds_the_vein", func():
		GameState.reset()
		var vein := _seed_firm_held_hakim_vein()
		assert_true(not Collective.ruin_hakim_site(), "still the Firm's")
		assert_eq(vein["factionId"], "firm")
		assert_true(not Sites.find_site("site_fv_hakim").get("ruinedByFirm", false))

		GameState.state["collective"]["hakimVeinId"] = null
		assert_true(not Collective.ruin_hakim_site())
	)

	# ── col_a2_hakim_retake ─────────────────────────────────────────────────

	run_case("force_retake_claims_then_ruins_the_site", func():
		GameState.reset()
		_seed_firm_held_hakim_vein()
		Fixtures.seed_vein("v_other", 40)
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		EventPlay.play_event_with_choices("col_a2_hakim_retake", [0])

		var site: Dictionary = Sites.find_site("site_fv_hakim")
		assert_true(Cultivating.find_vein("fv_hakim") == null, "the vein doesn't come back with the ground")
		assert_true(site["claimed"] and site["factionVein"] == null, "the site is the player's, empty")
		assert_true(site["ruinedByFirm"])
		assert_true(Cultivating.find_vein("v_other") != null, "other veins untouched")
		assert_true(not Sites.attempt_seed("site_fv_hakim")["ok"])
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before + 15)
		assert_true(GameState.state["flags"]["colA2HakimRetaken"])
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	run_case("buy_retake_pays_the_firm_then_ruins_the_site", func():
		GameState.reset()
		var vein := _seed_firm_held_hakim_vein()
		var price := VeinTrade.quote(vein)
		GameState.state["player"]["cash"] = price + 100

		EventPlay.play_event_with_choices("col_a2_hakim_retake", [1])

		assert_eq(GameState.state["player"]["cash"], 100, "bought at VeinTrade.quote()")
		assert_true(Cultivating.find_vein("fv_hakim") == null)
		assert_true(Sites.find_site("site_fv_hakim")["ruinedByFirm"])
		assert_true(GameState.state["flags"]["colA2HakimRetaken"])
	)

	# ── gate: Targets intel on Hakim's Firm-held vein ───────────────────────

	run_case("targets_purchase_on_hakims_vein_opens_the_retake", func():
		GameState.reset()
		_seed_firm_held_hakim_vein()
		Fixtures.seed_faction_vein("fv_elsewhere", 60, "firm")
		GameState.state["player"]["cash"] = 1000000

		assert_true(ContactCards.build_hakim_retake_action() == null, "closed before any intel")
		assert_true(NetworkHandler.buy_target("site_fv_elsewhere", NetworkHandler.EFFECT_CLAIM_BONUS)["ok"])
		assert_true(not GameState.state["flags"]["colA2HakimIntelBought"], "intel on another vein doesn't count")

		assert_true(NetworkHandler.buy_target("site_fv_hakim", NetworkHandler.EFFECT_CLAIM_BONUS)["ok"])
		assert_true(GameState.state["flags"]["colA2HakimIntelBought"])
		var action := ContactCards.build_hakim_retake_action()
		assert_true(action != null, "open once intel's bought")
		action.free()

		GameState.state["flags"]["colA2HakimRetaken"] = true
		assert_true(ContactCards.build_hakim_retake_action() == null, "closed after the retake")
	)

	# ── data validity: ruinedByFirm has exactly one setter ──────────────────

	run_case("ruined_by_firm_is_set_only_by_collective_ruin_hakim_site", func():
		var files: Array[String] = []
		for dir_path in RUIN_FLAG_SOURCE_DIRS:
			_collect_files(dir_path, files)
		var setter := RegEx.create_from_string("\\[\"ruinedByFirm\"\\]\\s*=[^=]|\"ruinedByFirm\"\\s*:")
		var setters: Array[String] = []
		for path in files:
			var text := FileAccess.get_file_as_string(path)
			var line_no := 0
			for line in text.split("\n"):
				line_no += 1
				if setter.search(line) != null:
					setters.append("%s:%d" % [path, line_no])
		assert_eq(setters.size(), 1, "exactly one ruinedByFirm setter: %s" % str(setters))
		assert_true(setters.size() == 1 and setters[0].begins_with("res://systems/collective.gd:"), "and it's Collective.ruin_hakim_site(): %s" % str(setters))
	)
