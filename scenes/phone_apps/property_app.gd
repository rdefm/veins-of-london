# Harrow's: current HQ tier card plus the next tier's upgrade offer
# (docs/hq-diorama-vision.md §7).
class_name PropertyApp
extends PhoneApp


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Harrow's"))
	content.add_child(_build_current_card())
	content.add_child(_build_next_card())


func _build_current_card() -> Control:
	var home: Dictionary = GameState.state["home"]
	var tier: Dictionary = GameData.HOME_TIERS[home["tier"]]
	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))

	var c := UI.card()
	c["content"].add_child(UI.muted_label("YOUR PLACE"))
	c["content"].add_child(UI.heading(tier["name"], 14))
	c["content"].add_child(UI.muted_label(tier["description"]))
	c["content"].add_child(UI.label("Daily cost: £%d · Raid risk: %d%% · Rooms %d/%d" % [Home.current_bill_base(), raid_pct, home["rooms"].size(), tier["maxRooms"]]))
	_add_static_plan(c["content"], home["tier"])
	return c["panel"]


func _build_next_card() -> Control:
	var home: Dictionary = GameState.state["home"]
	var next_id: String = Home.get_next_tier_id(home["tier"])

	var c := UI.card()
	c["content"].add_child(UI.muted_label("NEXT UP"))

	if next_id == "":
		c["content"].add_child(UI.muted_label("Top of the ladder. Nowhere further to move."))
		return c["panel"]

	var next_tier: Dictionary = GameData.HOME_TIERS[next_id]
	var raid_pct: int = int(round(Home.get_raid_chance_for_tier(next_id) * 100))
	var cost: int = next_tier["upgradeCost"]

	c["content"].add_child(UI.heading(next_tier["name"], 14))
	c["content"].add_child(UI.muted_label(next_tier["description"]))
	# Moving up is a purchase, so the next tier's bill is its owned utilities.
	c["content"].add_child(UI.label("Daily cost: £%d · Raid risk: %d%% · Rooms %d" % [Home.bill_base_for(next_id, Home.TENURE_OWNED), raid_pct, next_tier["maxRooms"]]))
	_add_static_plan(c["content"], next_id)

	var b := UI.button("Move for £%d" % cost, func(): Home.upgrade_tier())
	b.disabled = GameState.state["player"]["cash"] < cost
	c["content"].add_child(b)
	if b.disabled:
		c["content"].add_child(UI.muted_label("Not enough cash."))

	return c["panel"]


# Listings show the tier's plan read-only; rooms are bought on HQ's noticeboard (§7).
func _add_static_plan(content: VBoxContainer, tier_id: String) -> void:
	if FloorplanView.has_plan(tier_id):
		content.add_child(FloorplanView.build(tier_id))
