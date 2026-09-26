# Harrow's: every tier on the ladder as an estate-agent listing, in ladder
# order, each led by its photo (data/home.json tier `image`, placeholder when
# empty or unloadable). The current tier is the YOUR PLACE card (buy-out when
# rented, arrears balance and countdown while in arrears); any other listing
# opens its particulars: floor plan, the tier's `particulars` copy and the
# Rent/Buy offers, which appear only there (docs/hq-diorama-vision.md §7).
#
# PROSE-REVIEW: tenure, rent/buy, buy-out, room-wipe, arrears and photo-placeholder strings.
class_name PropertyApp
extends PhoneApp

const LISTING_NODE_PREFIX := "Listing_"
const PHOTO_NODE_PREFIX := "ListingPhoto_"
const PHOTO_PLACEHOLDER_NODE_PREFIX := "ListingPhotoPlaceholder_"
const PHOTO_HEIGHT := 180.0

# Tier id whose particulars are open; "" shows the listings. View state only.
var _open_tier_id: String = ""


static func listing_node_name(tier_id: String) -> String:
	return LISTING_NODE_PREFIX + tier_id


static func photo_node_name(tier_id: String) -> String:
	return PHOTO_NODE_PREFIX + tier_id


static func photo_placeholder_node_name(tier_id: String) -> String:
	return PHOTO_PLACEHOLDER_NODE_PREFIX + tier_id


func build(content: VBoxContainer) -> void:
	var tier_id: String = GameState.state["home"]["tier"]
	if _open_tier_id != "" and _open_tier_id != tier_id and GameData.HOME_TIERS.has(_open_tier_id):
		_build_particulars(content, _open_tier_id)
		return
	_open_tier_id = ""

	content.add_child(back_button())
	content.add_child(UI.heading("Harrow's"))
	for listed_id in GameData.HOME_TIER_ORDER:
		if listed_id == tier_id:
			content.add_child(_build_current_card())
		else:
			content.add_child(_build_listing_card(_move_caption(listed_id), listed_id))


func _move_caption(tier_id: String) -> String:
	var order: Array = GameData.HOME_TIER_ORDER
	return "MOVE DOWN" if order.find(tier_id) < order.find(GameState.state["home"]["tier"]) else "MOVE UP"


func _build_current_card() -> Control:
	var home: Dictionary = GameState.state["home"]
	var tier_id: String = home["tier"]
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
	var rented: bool = home["tenure"] == Home.TENURE_RENTED

	var c := UI.card()
	c["content"].add_child(_build_photo(tier_id))
	c["content"].add_child(UI.muted_label("YOUR PLACE"))
	c["content"].add_child(UI.heading(tier["name"], 14))
	c["content"].add_child(UI.muted_label(tier["description"]))
	c["content"].add_child(UI.label("Daily cost: £%d · Raid risk: %d%% · Rooms %d/%d" % [Home.current_bill_base(), raid_pct, home["rooms"].size(), tier["maxRooms"]]))
	c["content"].add_child(UI.muted_label("Rented." if rented else "Owned outright."))
	var countdown: Dictionary = Home.arrears_countdown()
	if not countdown.is_empty():
		c["content"].add_child(UI.label("Arrears: £%d" % countdown["arrears"]))
		for line in MorningAccounts.countdown_lines(countdown):
			c["content"].add_child(UI.muted_label(line))
	if rented and Home.can_buy_tier(tier_id):
		var price: int = Home.buy_price(tier_id)
		_add_purchase_button(c["content"], "Buy out for £%d" % price, price, Home.buy_out)
		c["content"].add_child(UI.muted_label("Then £%d/day in utilities. Rooms stay." % Home.bill_base_for(tier_id, Home.TENURE_OWNED)))
	_add_static_plan(c["content"], tier_id)
	return c["panel"]


# A listing is the card plus a flat overlay button covering it, so the whole
# card is the tap target and a scroll drag still cancels the press.
func _build_listing_card(caption: String, tier_id: String) -> Control:
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	var c := UI.card()
	c["content"].add_child(_build_photo(tier_id))
	c["content"].add_child(UI.muted_label(caption))
	c["content"].add_child(UI.heading(tier["name"], 14))
	c["content"].add_child(UI.muted_label(tier["description"]))
	c["content"].add_child(_tier_stats_label(tier_id))
	c["content"].add_child(UI.muted_label("Tap for particulars ›"))
	var tap := Button.new()
	tap.name = listing_node_name(tier_id)
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.pressed.connect(_open_particulars.bind(tier_id))
	c["panel"].add_child(tap)
	return c["panel"]


func _build_particulars(content: VBoxContainer, tier_id: String) -> void:
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	var on_rent: Callable = Home.rent_to.bind(tier_id)
	var on_buy: Callable = Home.buy_to.bind(tier_id)
	content.add_child(UI.button("‹ Listings", _open_particulars.bind("")))
	content.add_child(UI.muted_label(_move_caption(tier_id)))
	content.add_child(UI.heading(tier["name"]))
	_add_static_plan(content, tier_id)
	content.add_child(UI.label(tier["particulars"]))
	content.add_child(_tier_stats_label(tier_id))

	var c := UI.card()
	c["content"].add_child(UI.button("Rent for £%d/day" % Home.bill_base_for(tier_id, Home.TENURE_RENTED), _close_then.bind(on_rent)))
	if Home.can_buy_tier(tier_id):
		var price: int = Home.buy_price(tier_id)
		_add_purchase_button(c["content"], "Buy for £%d" % price, price, _close_then.bind(on_buy))
		c["content"].add_child(UI.muted_label("Then £%d/day in utilities." % Home.bill_base_for(tier_id, Home.TENURE_OWNED)))

	c["content"].add_child(UI.muted_label("Moving clears every installed room. No refunds."))
	var lost: Array[String] = []
	for security_id in Home.security_lost_moving_to(tier_id):
		lost.append(GameData.HOME_SECURITY[security_id]["name"])
	var guards: int = Home.guards_lost_moving_to(tier_id)
	if guards > 0:
		lost.append("%d guard%s" % [guards, "" if guards == 1 else "s"])
	if not lost.is_empty():
		c["content"].add_child(UI.muted_label("Left behind: %s." % ", ".join(lost)))
	content.add_child(c["panel"])


func _tier_stats_label(tier_id: String) -> Label:
	var raid_pct: int = int(round(Home.get_raid_chance_for_tier(tier_id) * 100))
	return UI.label("Raid risk: %d%% · Rooms %d" % [raid_pct, GameData.HOME_TIERS[tier_id]["maxRooms"]])


func _open_particulars(tier_id: String) -> void:
	_open_tier_id = tier_id
	refresh()


# The move changes which tier is YOUR PLACE, so the listings come back first.
func _close_then(action: Callable) -> void:
	_open_tier_id = ""
	action.call()
	refresh()


func _add_purchase_button(content: VBoxContainer, text: String, price: int, on_press: Callable) -> void:
	var b := UI.button(text, on_press)
	b.disabled = GameState.state["player"]["cash"] < price
	content.add_child(b)
	if b.disabled:
		content.add_child(UI.muted_label("Not enough cash. You have £%d." % GameState.state["player"]["cash"]))


# Plans are read-only here; rooms are bought on HQ's noticeboard (§7).
func _add_static_plan(content: VBoxContainer, tier_id: String) -> void:
	if FloorplanView.has_plan(tier_id):
		content.add_child(FloorplanView.build(tier_id))


# The tier's listing photo, cropped to fill the card width; a flat placeholder
# when data/home.json has no image for it or the path doesn't load.
func _build_photo(tier_id: String) -> Control:
	var path: String = GameData.HOME_TIERS[tier_id].get("image", "")
	if path != "" and ResourceLoader.exists(path):
		var photo := TextureRect.new()
		photo.name = photo_node_name(tier_id)
		photo.texture = load(path)
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		photo.clip_contents = true
		photo.custom_minimum_size = Vector2(0, PHOTO_HEIGHT)
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return photo
	var placeholder := PanelContainer.new()
	placeholder.name = photo_placeholder_node_name(tier_id)
	placeholder.custom_minimum_size = Vector2(0, PHOTO_HEIGHT)
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placeholder.add_theme_stylebox_override("panel", UI.bordered_panel_style(UI.COMMAND_ROW_RULE_COLOUR, UI.COMMAND_ROW_RULE_COLOUR, 4, 0, 0))
	var centre := CenterContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(UI.muted_label("Photos to follow."))
	placeholder.add_child(centre)
	return placeholder
