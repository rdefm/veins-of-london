extends "res://tests/test_base.gd"


func run() -> void:
	run_case("sense_xp_pays_mind_a_fifth", func():
		GameState.reset()
		Sense.award_xp(50)
		assert_eq(GameState.state["player"]["mindXP"], 10, "50 Sense XP -> +10 Mind XP")
	)

	run_case("crafting_xp_pays_mind_after_the_multiplier", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		Crafting.award_crafting_xp(50)
		var final: int = player["craftingXP"]
		assert_eq(player["mindXP"], floori(final * 0.2), "Mind gets 20% of the final Crafting award")
	)

	run_case("cultivating_xp_pays_soul_a_fifth", func():
		GameState.reset()
		Cultivating.award_xp(30)
		assert_eq(GameState.state["player"]["soulXP"], 6, "30 Cultivating XP -> +6 Soul XP")
		assert_eq(GameState.state["player"]["mindXP"], 0, "Mind untouched")
	)

	run_case("move_xp_shares_floor_to_body", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		Progression.award_bucket_share("body", 10)
		assert_eq(player["bodyXP"], 2, "resolved move (10) -> +2 Body")
		Progression.award_bucket_share("body", 4)
		assert_eq(player["bodyXP"], 2, "fizzled move (4) -> +0 Body")
	)

	run_case("contact_xp_leaves_buckets_alone", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		for contact_id in GameState.state["contacts"]:
			Contacts.award_contact_xp(contact_id, "crafting", 50)
			Contacts.award_contact_xp(contact_id, "cultivating", 50)
		assert_eq(player["mindXP"], 0, "Mind unchanged")
		assert_eq(player["soulXP"], 0, "Soul unchanged")
		assert_eq(player["bodyXP"], 0, "Body unchanged")
	)

	run_case("bucket_levels_up_from_shared_xp", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		Sense.award_xp(400)
		assert_eq(player["mindXP"], 80, "400 Sense -> 80 Mind")
		assert_eq(player["mindSkill"], 2, "Mind levels at 80 shared XP")
	)
