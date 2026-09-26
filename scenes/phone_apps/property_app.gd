# Harrow's: every tier on the ladder as an estate-agent listing, in ladder
# order, each led by its photo (data/home.json tier `image`, placeholder when
# empty or unloadable). The listings mount their own root under Harrow's brand
# chrome -- white surfaces, green/gold bar, serif headings -- instead of the
# shared dark phone-app chrome (docs/ui-vision.md §10 "Harrow's exception").
# The current tier is the YOUR PLACE card (tenure, daily cost, raid risk,
# rooms, arrears balance and countdown, buy-out when rented, floor plan); any
# other listing opens its particulars: floor plan, the tier's `particulars`
# copy and the Rent/Buy offers, which appear only there
# (docs/hq-diorama-vision.md §7).
#
# PROSE-REVIEW: tenure, rent/buy, buy-out, room-wipe, arrears, feed intro and photo-placeholder strings.
class_name PropertyApp
extends PhoneApp

const LISTING_NODE_PREFIX := "Listing_"
const PHOTO_NODE_PREFIX := "ListingPhoto_"
const PHOTO_PLACEHOLDER_NODE_PREFIX := "ListingPhotoPlaceholder_"
const FEED_ROOT_NODE_NAME := "HarrowsFeed"
const BRAND_BAR_NODE_NAME := "HarrowsBrandBar"
const PHOTO_HEIGHT := 180.0

const BRAND_GREEN_FALLBACK := Color("#06472f")
const BRAND_GOLD_FALLBACK := Color("#efd079")
const PAPER := Color("#ffffff")
const INK := Color("#22201e")
const MUTED := Color("#686663")
const FACT_INK := Color("#454340")
const LINE := Color("#e7e4e0")
const PHOTO_FILL := Color("#d1c2af")
const SERIF_FONT_NAMES: PackedStringArray = ["Georgia", "Times New Roman", "Noto Serif", "DejaVu Serif", "serif"]

# Tier id whose particulars are open; "" shows the listings. View state only.
var _open_tier_id: String = ""
var _feed_root: Control = null
var _serif: SystemFont = null
var _bold: FontVariation = null


static func listing_node_name(tier_id: String) -> String:
	return LISTING_NODE_PREFIX + tier_id


static func photo_node_name(tier_id: String) -> String:
	return PHOTO_NODE_PREFIX + tier_id


static func photo_placeholder_node_name(tier_id: String) -> String:
	return PHOTO_PLACEHOLDER_NODE_PREFIX + tier_id


static func brand_green() -> Color:
	return GameData.PALETTE.get("harrows_green", BRAND_GREEN_FALLBACK)


static func brand_gold() -> Color:
	return GameData.PALETTE.get("harrows_gold", BRAND_GOLD_FALLBACK)


func build(content: VBoxContainer) -> void:
	var tier_id: String = GameState.state["home"]["tier"]
	if _open_tier_id != "" and _open_tier_id != tier_id and GameData.HOME_TIERS.has(_open_tier_id):
		_build_particulars(content, _open_tier_id)
		return
	_open_tier_id = ""
	_build_feed()


func teardown() -> void:
	if _feed_root != null:
		if _feed_root.get_parent() != null:
			_feed_root.get_parent().remove_child(_feed_root)
		_feed_root.queue_free()
		_feed_root = null


func _build_feed() -> void:
	_feed_root = UI.vbox(0)
	_feed_root.name = FEED_ROOT_NODE_NAME
	shell.mount_custom_root(_feed_root)
	_feed_root.add_child(_build_brand_bar())

	var scroll := UI.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	scroll.add_theme_stylebox_override("panel", paper)
	_feed_root.add_child(scroll)

	var feed := UI.vbox(16)
	feed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_margins(feed, 12, 0, 12, 16))

	var intro := UI.vbox(6)
	intro.add_child(_text("Find your next place.", 26, INK, _serif_font()))
	intro.add_child(_text("%d properties across London" % GameData.HOME_TIER_ORDER.size(), 13, MUTED))
	feed.add_child(_margins(intro, 6, 20, 6, 0))

	var tier_id: String = GameState.state["home"]["tier"]
	for listed_id in GameData.HOME_TIER_ORDER:
		if listed_id == tier_id:
			feed.add_child(_build_current_card())
		else:
			feed.add_child(_build_listing_card(_move_caption(listed_id), listed_id))


# Green bar with a gold rule, the launcher icon's colours; its back returns
# to the phone home like every other app's.
func _build_brand_bar() -> Control:
	var style := StyleBoxFlat.new()
	style.bg_color = brand_green()
	style.border_color = brand_gold()
	style.border_width_bottom = 2
	style.content_margin_left = 16
	style.content_margin_right = 16
	var bar := PanelContainer.new()
	bar.name = BRAND_BAR_NODE_NAME
	bar.custom_minimum_size = Vector2(0, 56)
	bar.add_theme_stylebox_override("panel", style)

	var row := UI.hbox(8)
	bar.add_child(row)
	var back := UI.button("‹ Phone", func(): PhoneNav.go_home())
	back.flat = true
	back.focus_mode = Control.FOCUS_NONE
	for colour_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back.add_theme_color_override(colour_name, brand_gold())
	back.add_theme_font_size_override("font_size", 14)
	row.add_child(back)
	var brand := _text("Harrow's", 24, brand_gold(), _serif_font())
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(brand)
	var tagline := _text("LONDON PROPERTY", 10, brand_gold())
	tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
	tagline.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(tagline)
	for child in row.get_children():
		(child as Control).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return bar


func _move_caption(tier_id: String) -> String:
	var order: Array = GameData.HOME_TIER_ORDER
	return "MOVE DOWN" if order.find(tier_id) < order.find(GameState.state["home"]["tier"]) else "MOVE UP"


func _build_current_card() -> Control:
	var home: Dictionary = GameState.state["home"]
	var tier_id: String = home["tier"]
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
	var rented: bool = home["tenure"] == Home.TENURE_RENTED

	var card := _listing_shell(tier_id)
	var body: VBoxContainer = card["body"]
	body.add_child(_text("YOUR PLACE", 11, brand_green(), _bold_font()))
	_add_title(body, tier_id)
	body.add_child(_price_row(Home.current_bill_base(), "/ day rent" if rented else "/ day utilities"))
	body.add_child(_text("Rented." if rented else "Owned outright.", 13, MUTED))
	body.add_child(_facts(["Rooms %d/%d" % [home["rooms"].size(), tier["maxRooms"]], "Raid risk %d%%" % raid_pct]))
	var countdown: Dictionary = Home.arrears_countdown()
	if not countdown.is_empty():
		body.add_child(_text("Arrears: £%d" % countdown["arrears"], 15, INK, _bold_font()))
		for line in MorningAccounts.countdown_lines(countdown):
			body.add_child(_text(line, 13, MUTED))
	if rented and Home.can_buy_tier(tier_id):
		var price: int = Home.buy_price(tier_id)
		_add_brand_purchase_button(body, "Buy out for £%d" % price, price, Home.buy_out)
		body.add_child(_text("Then £%d/day in utilities. Rooms stay." % Home.bill_base_for(tier_id, Home.TENURE_OWNED), 12, MUTED))
	_add_static_plan(body, tier_id)
	return card["panel"]


# A listing is the card plus a flat overlay button covering it, so the whole
# card is the tap target and a scroll drag still cancels the press.
func _build_listing_card(caption: String, tier_id: String) -> Control:
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	var card := _listing_shell(tier_id)
	var body: VBoxContainer = card["body"]
	body.add_child(_text(caption, 11, brand_green(), _bold_font()))
	_add_title(body, tier_id)
	body.add_child(_price_row(Home.bill_base_for(tier_id, Home.TENURE_RENTED), "/ day rent"))
	var facts: Array[String] = []
	if Home.can_buy_tier(tier_id):
		facts.append("Buy £%d" % Home.buy_price(tier_id))
	var rooms: int = tier["maxRooms"]
	facts.append("%d spare room%s" % [rooms, "" if rooms == 1 else "s"])
	facts.append("Raid risk %d%%" % int(round(Home.get_raid_chance_for_tier(tier_id) * 100)))
	body.add_child(_facts(facts))

	var action := PanelContainer.new()
	action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action.add_theme_stylebox_override("panel", _rule_style(15, 13))
	action.add_child(_text("View particulars →", 14, brand_green(), _bold_font()))
	card["column"].add_child(action)

	var tap := Button.new()
	tap.name = listing_node_name(tier_id)
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.pressed.connect(_open_particulars.bind(tier_id))
	card["panel"].add_child(tap)
	return card["panel"]


# White bordered card: photo flush to the top edge, then a padded body.
func _listing_shell(tier_id: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	panel.add_theme_stylebox_override("panel", UI.bordered_panel_style(PAPER, LINE, 6, 0, 0))
	var column := UI.vbox(0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)
	column.add_child(_build_photo(tier_id))
	var body := UI.vbox(6)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_margins(body, 15, 14, 15, 15))
	return { "panel": panel, "column": column, "body": body }


func _add_title(body: VBoxContainer, tier_id: String) -> void:
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	body.add_child(_text(tier["name"], 22, INK, _serif_font()))
	body.add_child(_text(tier["description"], 13, MUTED))


func _price_row(amount: int, unit: String) -> Control:
	var row := UI.hbox(6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var figure := _text("£%d" % amount, 20, INK, _bold_font())
	figure.autowrap_mode = TextServer.AUTOWRAP_OFF
	figure.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(figure)
	var unit_label := _text(unit, 13, MUTED)
	unit_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	unit_label.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(unit_label)
	return row


# Fact line under a thin rule, as the mockup's `.facts` row.
func _facts(parts: Array[String]) -> Control:
	var rule := PanelContainer.new()
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.add_theme_stylebox_override("panel", _rule_style(0, 10, 0))
	var flow := UI.hflow(12)
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for part in parts:
		var fact := _text(part, 12, FACT_INK)
		fact.autowrap_mode = TextServer.AUTOWRAP_OFF
		fact.size_flags_horizontal = Control.SIZE_FILL
		flow.add_child(fact)
	rule.add_child(flow)
	return rule


func _rule_style(margin_h: int, margin_top: int, margin_bottom: int = -1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = LINE
	style.border_width_top = 1
	style.content_margin_left = margin_h
	style.content_margin_right = margin_h
	style.content_margin_top = margin_top
	style.content_margin_bottom = margin_top if margin_bottom < 0 else margin_bottom
	return style


# Harrow's primary action: green fill, white text; unaffordable reads as a
# muted outline with the shortfall beneath it.
func _add_brand_purchase_button(content: VBoxContainer, text: String, price: int, on_press: Callable) -> void:
	var b := UI.button(text, on_press)
	b.custom_minimum_size = Vector2(0, 44)
	b.focus_mode = Control.FOCUS_NONE
	var fill := UI.bordered_panel_style(brand_green(), brand_green(), 4, 12, 10)
	var outline := UI.bordered_panel_style(PAPER, LINE, 4, 12, 10)
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, fill)
	b.add_theme_stylebox_override("disabled", outline)
	for colour_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(colour_name, PAPER)
	b.add_theme_color_override("font_disabled_color", MUTED)
	b.disabled = GameState.state["player"]["cash"] < price
	content.add_child(b)
	if b.disabled:
		content.add_child(_text("Not enough cash. You have £%d." % GameState.state["player"]["cash"], 12, MUTED))


func _text(text: String, size: int, colour: Color, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	if font != null:
		l.add_theme_font_override("font", font)
	return l


func _margins(child: Control, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_constant_override("margin_left", left)
	m.add_theme_constant_override("margin_top", top)
	m.add_theme_constant_override("margin_right", right)
	m.add_theme_constant_override("margin_bottom", bottom)
	m.add_child(child)
	return m


# Editorial serif for Harrow's headings (docs/ui-vision.md §10 exception);
# falls back to the engine font where none of the names resolve.
func _serif_font() -> Font:
	if _serif == null:
		_serif = SystemFont.new()
		_serif.font_names = SERIF_FONT_NAMES
	return _serif


# The shared UI sans, emboldened, for prices, eyebrows and the action row.
func _bold_font() -> Font:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.8
	return _bold


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
	var fill := StyleBoxFlat.new()
	fill.bg_color = PHOTO_FILL
	placeholder.add_theme_stylebox_override("panel", fill)
	var centre := CenterContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caption := _text("Photos to follow.", 13, INK)
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	centre.add_child(caption)
	placeholder.add_child(centre)
	return placeholder
