extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")

# Harrow's -- HQ tier stats and the rent/buy/buy-out/move-down
# actions, relocated off the HQ tab (docs/hq-diorama-vision.md §7). Same
# screen-level-tested-against-a-real-PhoneScreen-instance pattern as
# tests/test_phone_bank.gd.


func run() -> void:
	run_case("property_shows_the_current_tiers_stats", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 50 }  # nudges raid risk off the floor, deterministic
		GameState.state["phoneNav"]["app"] = "property"

		var phone := PhoneScreen.new()
		phone._ready()

		var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
		var texts := NodeQuery.label_texts(phone)
		for expected in ["YOUR PLACE", "£350", "/ week rent", "Rented.", "Rooms 0/0", "Raid risk %d%%" % raid_pct]:
			assert_true(texts.has(expected), "current bedsit card shows %s" % expected)

		phone.free()
	)

	run_case("property_shows_arrears_balance_and_countdown_only_while_in_arrears", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "flat"
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(not NodeQuery.label_texts(phone).any(func(t: String): return t.begins_with("Arrears")), "no arrears line when paid up")
		phone.free()

		GameState.state["home"]["arrears"] = 320
		GameState.state["home"]["arrearsWeeks"] = 1
		var before: Dictionary = GameState.deep_copy(GameState.state)
		phone = PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		for expected in ["Arrears: £320", "Interest starts in 7 days.", "Lose the Flat in 7 days."]:
			assert_true(texts.has(expected), "missing %s" % expected)
		assert_eq(GameState.state["home"], before["home"], "rendering only reads state")
		phone.free()

		GameState.state["home"]["tier"] = "bedsit"
		phone = PhoneScreen.new()
		phone._ready()
		texts = NodeQuery.label_texts(phone)
		assert_true(texts.has("Arrears: £320"))
		assert_true(not texts.any(func(t: String): return t.begins_with("Lose the")), "no downgrade countdown at the bedsit")
		phone.free()
	)

	run_case("property_current_daily_cost_follows_tenure", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "townhouse"
		GameState.state["phoneNav"]["app"] = "property"
		var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))

		GameState.state["home"]["tenure"] = "owned"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		for expected in ["£455", "/ week utilities", "Owned outright.", "Rooms 0/3", "Raid risk %d%%" % raid_pct]:
			assert_true(texts.has(expected), "owned townhouse shows %s" % expected)
		phone.free()

		GameState.state["home"]["tenure"] = "rented"
		phone = PhoneScreen.new()
		phone._ready()
		texts = NodeQuery.label_texts(phone)
		for expected in ["£1050", "/ week rent", "Rented."]:
			assert_true(texts.has(expected), "rented townhouse shows %s" % expected)
		assert_true(not texts.has("/ week utilities"), "no listing is priced in utilities")
		phone.free()
	)

	run_case("property_shows_the_next_tier_up_with_rent_and_buy_offers", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Studio"), "next tier's name (studio, the tier above bedsit) renders")
		var raid_pct: int = int(round(Home.get_raid_chance_for_tier("studio") * 100))
		for expected in ["£420", "Buy £80000", "0 spare rooms", "Raid risk %d%%" % raid_pct]:
			assert_true(texts.has(expected), "studio listing shows %s" % expected)
		assert_true(texts.has("1 spare room"), "the flat listing's single room reads singular")
		assert_true(NodeQuery.find_button(phone, "Rent for £420/week") == null, "offers live only in the particulars")
		assert_true(NodeQuery.find_button(phone, "Buy for £80000") == null, "offers live only in the particulars")

		_open_listing(phone, "studio")
		texts = NodeQuery.label_texts(phone)
		assert_true(NodeQuery.find_button(phone, "Rent for £420/week") != null, "rent offer previews studio's rent")
		assert_true(NodeQuery.find_button(phone, "Buy for £80000") != null, "buy offer shows studio's buyPrice")
		assert_true(texts.has("Or buy for £80000 · then £245/week in utilities"), "buy offer previews studio's owned bill override")
		assert_true(texts.has("Moving clears every installed room. No refunds."))

		phone.free()
	)

	run_case("property_flat_listing_shows_a_static_floorplan_with_no_room_controls", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "studio"
		GameState.state["phoneNav"]["app"] = "property"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_eq(_plans_of(phone, "flat").size(), 0, "the Flat listing (next tier from studio) shows no inline plan")
		_open_listing(phone, "flat")
		assert_eq(_plans_of(phone, "flat").size(), 1, "the Flat particulars show its plan")
		var section := phone.find_child(PropertyApp.PLAN_SECTION_NODE_NAME, true, false)
		assert_true(section != null, "the plan sits in its own Floorplan section")
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.find("Floorplan") > texts.find(GameData.HOME_TIERS["flat"]["particulars"]), "the plan follows the copy")
		assert_true(texts.find("Floorplan") < texts.find("Moving clears every installed room. No refunds."), "the offer box comes after the plan")
		assert_true(NodeQuery.find_button(phone, "Rent for £560/week") != null, "the Flat still offers its rent")
		assert_eq(phone.find_child(FloorplanView.slot_node_name(0), true, false), null, "the listing plan is static: no selectable slot")
		for room_id in GameData.HOME_ROOMS.keys():
			assert_true(NodeQuery.find_button(phone, "£%d" % GameData.HOME_ROOMS[room_id]["cost"]) == null, "Harrow's sells no room upgrades (%s)" % room_id)

		phone.free()
	)

	run_case("property_particulars_without_a_plan_omit_the_floorplan_section", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()
		for tier_id in GameData.HOME_TIER_ORDER:
			if tier_id == "bedsit":
				continue
			_open_listing(phone, tier_id)
			var has_section := phone.find_child(PropertyApp.PLAN_SECTION_NODE_NAME, true, false) != null
			assert_eq(has_section, FloorplanView.has_plan(tier_id), "%s plan section matches whether it has a plan" % tier_id)
			assert_eq(NodeQuery.label_texts(phone).has("Floorplan"), FloorplanView.has_plan(tier_id), "%s shows no empty Floorplan heading" % tier_id)
			NodeQuery.find_button(phone, "← Back to listings").pressed.emit()
		phone.free()
	)

	run_case("property_particulars_wear_harrows_chrome_with_hero_facts_and_copy", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()
		_open_listing(phone, "studio")
		assert_true(phone.find_child(PropertyApp.PARTICULARS_ROOT_NODE_NAME, true, false) != null, "particulars mount Harrow's own root")
		assert_eq(phone.find_child(PropertyApp.FEED_ROOT_NODE_NAME, true, false), null, "the feed root is gone")
		assert_true(not phone.device_shell.content_scroll.visible, "the shared dark column stays hidden")
		assert_true(phone.find_child(PropertyApp.BRAND_BAR_NODE_NAME, true, false) != null, "the brand bar stays over the particulars")
		var hero := phone.find_child(PropertyApp.photo_node_name("studio"), true, false) as Control
		assert_true(hero != null and hero.custom_minimum_size.y == PropertyApp.HERO_PHOTO_HEIGHT, "studio's photo leads as the hero")
		var texts := NodeQuery.label_texts(phone)
		var raid_pct: int = int(round(Home.get_raid_chance_for_tier("studio") * 100))
		for expected in ["Studio", GameData.HOME_TIERS["studio"]["description"], "£420", "/ week rent", "0", "spare rooms", "%d%%" % raid_pct, "raid risk", "Property description", GameData.HOME_TIERS["studio"]["particulars"]]:
			assert_true(texts.has(expected), "studio particulars show %s" % expected)
		phone.free()
	)

	run_case("property_buy_is_disabled_without_cash_and_rent_calls_rent_up", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100
		GameState.state["phoneNav"]["app"] = "property"

		var phone := PhoneScreen.new()
		phone._ready()
		_open_listing(phone, "studio")
		var buy_button := NodeQuery.find_button(phone, "Buy for £80000")
		assert_true(buy_button.disabled, "buy disabled without enough cash")
		assert_true(NodeQuery.label_texts(phone).has("Not enough cash. You have £100."), "particulars show the shortfall against cash")
		var rent_button := NodeQuery.find_button(phone, "Rent for £420/week")
		assert_true(not rent_button.disabled, "renting needs no cash up front")
		rent_button.pressed.emit()
		assert_eq(GameState.state["home"]["tier"], "studio")
		assert_eq(GameState.state["home"]["tenure"], "rented")
		assert_true(NodeQuery.find_button(phone, "← Back to listings") == null, "a move closes the particulars")
		assert_true(phone.find_child(PropertyApp.listing_node_name("bedsit"), true, false) != null, "back on the listings, the bedsit now a listing")
		assert_eq(phone.find_child(PropertyApp.listing_node_name("studio"), true, false), null, "the studio is now YOUR PLACE, not a listing")
		phone.free()

		GameState.reset()
		GameState.state["player"]["cash"] = 80000
		GameState.state["phoneNav"]["app"] = "property"
		phone = PhoneScreen.new()
		phone._ready()
		_open_listing(phone, "studio")
		NodeQuery.find_button(phone, "Buy for £80000").pressed.emit()
		assert_eq(GameState.state["home"]["tenure"], "owned", "buy button calls Home.buy_up")
		phone.free()
	)

	run_case("property_offers_buy_out_only_on_a_rented_buyable_tier", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_eq(NodeQuery.find_button(phone, "Buy out for £0"), null, "no buy-out at the bedsit")
		phone.free()

		GameState.state["home"]["tier"] = "flat"
		GameState.state["player"]["cash"] = 200000
		phone = PhoneScreen.new()
		phone._ready()
		assert_true(NodeQuery.label_texts(phone).has("Then £406/week in utilities. Rooms stay."))
		NodeQuery.find_button(phone, "Buy out for £200000").pressed.emit()
		assert_eq(GameState.state["home"]["tenure"], "owned")
		assert_eq(GameState.state["home"]["tier"], "flat")
		phone.free()

		phone = PhoneScreen.new()
		phone._ready()
		assert_eq(NodeQuery.find_button(phone, "Buy out for £200000"), null, "gone once owned")
		assert_true(NodeQuery.label_texts(phone).has("Owned outright."))
		phone.free()
	)

	run_case("property_move_down_offers_rent_only_to_the_bedsit_and_lists_lost_security", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(not NodeQuery.label_texts(phone).has("MOVE DOWN"), "no move-down card at the bedsit")
		phone.free()

		GameState.state["home"]["tier"] = "flat"
		GameState.state["home"]["security"] = ["lock", "cameras"]
		phone = PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("MOVE DOWN"))
		assert_true(texts.has("Studio"), "the flat's move-down is the studio")
		_open_listing(phone, "studio")
		texts = NodeQuery.label_texts(phone)
		assert_true(texts.has("MOVE DOWN"))
		assert_true(texts.has("Left behind: CCTV."))
		assert_true(NodeQuery.find_button(phone, "Buy for £80000") != null, "the studio can be bought on the way down")
		NodeQuery.find_button(phone, "Rent for £420/week").pressed.emit()
		assert_eq(GameState.state["home"]["tier"], "studio")
		assert_eq(GameState.state["home"]["security"], ["lock"])
		phone.free()

		phone = PhoneScreen.new()
		phone._ready()
		_open_listing(phone, "bedsit")
		assert_eq(NodeQuery.find_button(phone, "Buy for £0"), null, "the bedsit can't be bought")
		NodeQuery.find_button(phone, "Rent for £350/week").pressed.emit()
		assert_eq(GameState.state["home"]["tier"], "bedsit")
		assert_eq(GameState.state["home"]["security"], ["lock"])
		phone.free()
	)

	run_case("property_particulars_show_the_tiers_copy_and_back_returns_to_listings", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "flat"
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()
		var particulars: String = GameData.HOME_TIERS["townhouse"]["particulars"]
		assert_true(not NodeQuery.label_texts(phone).has(particulars), "particulars stay off the listings")

		_open_listing(phone, "townhouse")
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has(particulars), "townhouse particulars render")
		assert_true(not texts.has("YOUR PLACE"), "the detail view replaces the listings")
		assert_true(phone.find_child(PropertyApp.listing_node_name("studio"), true, false) == null)

		NodeQuery.find_button(phone, "← Back to listings").pressed.emit()
		texts = NodeQuery.label_texts(phone)
		assert_true(texts.has("YOUR PLACE"), "back returns to the listings")
		assert_true(not texts.has(particulars))
		assert_eq(GameState.state["home"]["tier"], "flat", "browsing changes nothing")
		phone.free()
	)

	run_case("property_every_tier_has_particulars", func():
		for tier_id in GameData.HOME_TIERS.keys():
			assert_true(str(GameData.HOME_TIERS[tier_id].get("particulars", "")) != "", "%s has particulars" % tier_id)
	)

	run_case("property_lists_every_tier_in_ladder_order_with_the_current_one_marked", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "flat"
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()

		var shown: Array = []
		for node in phone.find_children("ListingPhoto*", "", true, false):
			shown.append(String(node.name).trim_prefix(PropertyApp.PHOTO_PLACEHOLDER_NODE_PREFIX).trim_prefix(PropertyApp.PHOTO_NODE_PREFIX))
		assert_eq(shown, GameData.HOME_TIER_ORDER, "every tier leads with a photo or placeholder, in tierOrder")
		for tier_id in GameData.HOME_TIER_ORDER:
			var tap := phone.find_child(PropertyApp.listing_node_name(tier_id), true, false)
			if tier_id == "flat":
				assert_eq(tap, null, "YOUR PLACE is not a tappable listing")
			else:
				assert_true(tap != null, "%s is a tappable listing" % tier_id)
		var texts := NodeQuery.label_texts(phone)
		assert_eq(texts.count("YOUR PLACE"), 1, "exactly one card is marked as home")
		assert_eq(texts.count("MOVE DOWN"), 2, "bedsit and studio sit below the flat")
		assert_eq(texts.count("MOVE UP"), 4, "townhouse up to mansion sit above it")
		assert_true(texts.has("7 properties across London"), "the feed intro counts every tier")
		assert_eq(texts.count("View particulars →"), 6, "every listing but YOUR PLACE offers its particulars")
		assert_true(not texts.any(func(t: String): return t == "Buy £0"), "the rent-only bedsit lists no buy price")
		for tier_id in ["studio", "townhouse", "mansion"]:
			assert_true(texts.has("Buy £%d" % Home.buy_price(tier_id)), "%s lists its buy price" % tier_id)
		phone.free()
	)

	run_case("property_feed_wears_harrows_brand_chrome_and_back_returns_to_the_phone", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()

		var feed := phone.find_child(PropertyApp.FEED_ROOT_NODE_NAME, true, false)
		assert_true(feed != null, "the listings mount Harrow's own root")
		assert_true(not phone.device_shell.content_scroll.visible, "the shared dark content column is hidden under the feed")
		var bar := phone.find_child(PropertyApp.BRAND_BAR_NODE_NAME, true, false) as PanelContainer
		var bar_style := bar.get_theme_stylebox("panel") as StyleBoxFlat
		assert_eq(bar_style.bg_color, PropertyApp.brand_green(), "brand bar is Harrow's green")
		assert_eq(bar_style.border_color, PropertyApp.brand_gold(), "brand bar is ruled in Harrow's gold")
		assert_eq(PropertyApp.brand_green(), GameData.PALETTE["harrows_green"], "brand green comes from data/palette.json")
		var photo := phone.find_child(PropertyApp.photo_node_name("studio"), true, false) as Control
		var card_style := photo.get_parent().get_parent().get_theme_stylebox("panel") as StyleBoxFlat
		assert_eq(card_style.bg_color, PropertyApp.PAPER, "listing cards are white, not phone-OS dark")
		assert_eq(NodeQuery.find_button(phone, "‹ Back"), null, "the brand bar's back replaces the shared one")

		NodeQuery.find_button(phone, "‹ Phone").pressed.emit()
		assert_eq(GameState.state["phoneNav"]["app"], "home", "‹ Phone returns to the phone home")
		assert_true(phone.device_shell.content_scroll.visible, "the shared column is back for the home screen")
		phone.free()
	)

	run_case("property_other_phone_apps_keep_the_shared_dark_chrome", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bank"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_eq(phone.find_child(PropertyApp.FEED_ROOT_NODE_NAME, true, false), null)
		assert_true(phone.device_shell.content_scroll.visible, "Reynard's renders in the shared column")
		var panels := phone.device_shell.content.find_children("", "PanelContainer", true, false)
		assert_true(not panels.is_empty(), "Reynard's has a card")
		var dark := panels.any(func(p: PanelContainer):
			var s := p.get_theme_stylebox("panel") as StyleBoxFlat
			return s != null and s.bg_color == GameData.PALETTE["phone_bg_content"])
		assert_true(dark, "Reynard's cards keep the phone-OS content fill")
		phone.free()
	)

	run_case("property_listing_photo_loads_from_data_and_falls_back_to_a_placeholder", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "property"
		var original: String = GameData.HOME_TIERS["studio"]["image"]
		var phone := PhoneScreen.new()
		phone._ready()
		var photo := phone.find_child(PropertyApp.photo_node_name("studio"), true, false) as TextureRect
		assert_true(photo != null and photo.texture != null, "studio's shipped photo renders")
		phone.free()

		for broken in ["", "res://assets/hq/does_not_exist.png"]:
			GameData.HOME_TIERS["studio"]["image"] = broken
			phone = PhoneScreen.new()
			phone._ready()
			assert_eq(phone.find_child(PropertyApp.photo_node_name("studio"), true, false), null, "no photo for image '%s'" % broken)
			assert_true(phone.find_child(PropertyApp.photo_placeholder_node_name("studio"), true, false) != null, "placeholder for image '%s'" % broken)
			phone.free()
		GameData.HOME_TIERS["studio"]["image"] = original
	)

	run_case("property_owned_home_shows_trade_in_maths_and_net_affordability", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "flat"
		GameState.state["home"]["tenure"] = "owned"
		GameState.state["player"]["cash"] = 300000
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		for expected in ["Buy £800000", "Sell your flat −£200000", "You pay £600000", "You receive £120000"]:
			assert_true(texts.has(expected), "listings show %s" % expected)

		_open_listing(phone, "safehouse")
		texts = NodeQuery.label_texts(phone)
		assert_true(texts.has("£800000 · Sell your flat −£200000 · You pay £600000"), "particulars spell out the trade-in")
		assert_true(texts.has("Renting sells your flat: you receive £200000."), "rent option shows the sale credit")
		assert_true(NodeQuery.find_button(phone, "Buy for £800000").disabled, "net 600000 beats cash 300000")
		phone.free()

		phone = PhoneScreen.new()
		phone._ready()
		_open_listing(phone, "townhouse")
		var buy_button := NodeQuery.find_button(phone, "Buy for £500000")
		assert_true(not buy_button.disabled, "net 300000 is affordable though the price isn't")
		buy_button.pressed.emit()
		assert_eq(GameState.state["home"]["tier"], "townhouse")
		assert_eq(GameState.state["player"]["cash"], 0, "cash moves by the net amount")
		phone.free()
	)

	run_case("property_far_tier_particulars_rent_and_buy_jump_straight_there", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 1000
		GameState.state["phoneNav"]["app"] = "property"
		var phone := PhoneScreen.new()
		phone._ready()
		_open_listing(phone, "compound")
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has(GameData.HOME_TIERS["compound"]["particulars"]), "a far tier's particulars open")
		assert_true(texts.has("MOVE UP"))
		var buy_button := NodeQuery.find_button(phone, "Buy for £2000000")
		assert_true(buy_button != null and buy_button.disabled, "unaffordable buy is shown, disabled")
		assert_true(texts.has("Not enough cash. You have £1000."))
		NodeQuery.find_button(phone, "Rent for £4200/week").pressed.emit()
		assert_eq(GameState.state["home"]["tier"], "compound", "renting jumps five tiers in one move")
		assert_eq(GameState.state["home"]["tenure"], "rented")
		phone.free()

		GameState.state["player"]["cash"] = 200000
		phone = PhoneScreen.new()
		phone._ready()
		_open_listing(phone, "flat")
		assert_true(NodeQuery.label_texts(phone).has("MOVE DOWN"))
		NodeQuery.find_button(phone, "Buy for £200000").pressed.emit()
		assert_eq(GameState.state["home"]["tier"], "flat", "buying jumps three tiers down")
		assert_eq(GameState.state["home"]["tenure"], "owned")
		assert_eq(GameState.state["player"]["cash"], 0)
		phone.free()
	)

	run_case("property_is_reachable_from_the_app_grid_via_the_harrows_tile", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		var property_tile: AppTile = null
		for t in phone.find_children("", "AppTile", true, false):
			if (t as AppTile)._app_id == "property":
				property_tile = t
		assert_true(property_tile != null, "the app grid must include a Harrow's tile")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		property_tile._on_gui_input(event)

		assert_eq(GameState.state["phoneNav"]["app"], "property", "tapping the tile opens the property app via PhoneNav")

		phone.free()
	)


func _open_listing(phone: PhoneScreen, tier_id: String) -> void:
	var tap := phone.find_child(PropertyApp.listing_node_name(tier_id), true, false) as Button
	assert_true(tap != null, "listing for %s is tappable" % tier_id)
	if tap != null:
		tap.pressed.emit()


func _plans_of(phone: PhoneScreen, tier_id: String) -> Array:
	var texture := load("res://assets/floorplans/%s.svg" % tier_id)
	return phone.find_children("*", "TextureRect", true, false).filter(func(t): return t.texture == texture)
