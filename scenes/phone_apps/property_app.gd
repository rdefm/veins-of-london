# Harrow's: every tier on the ladder as an estate-agent listing, in ladder
# order, each led by its photo (data/home.json tier `image`, placeholder when
# empty or unloadable). Listings and particulars mount their own root under
# Harrow's brand chrome -- white surfaces, green/gold bar, serif headings --
# instead of the shared dark phone-app chrome (docs/ui-vision.md §10 "Harrow's exception").
# The current tier is the YOUR PLACE card (tenure, daily cost, raid risk,
# rooms, arrears balance and countdown, buy-out when rented, floor plan); any
# other listing opens its particulars: hero photo, terms, the tier's
# `particulars` copy, its static floor plan when it has one, and the Rent/Buy
# offers, which appear only there (docs/hq-diorama-vision.md §7).
#
# PROSE-REVIEW: tenure, rent/buy, buy-out, room-wipe, arrears, feed intro, photo-placeholder and floorplan-caption strings.
class_name PropertyApp
extends PhoneApp

const LISTING_NODE_PREFIX := "Listing_"
const PHOTO_NODE_PREFIX := "ListingPhoto_"
const PHOTO_PLACEHOLDER_NODE_PREFIX := "ListingPhotoPlaceholder_"
const FEED_ROOT_NODE_NAME := "HarrowsFeed"
const BRAND_BAR_NODE_NAME := "HarrowsBrandBar"
const PARTICULARS_ROOT_NODE_NAME := "HarrowsParticulars"
const PLAN_SECTION_NODE_NAME := "HarrowsFloorplan"
const PHOTO_HEIGHT := 180.0
const HERO_PHOTO_HEIGHT := 215.0

const BRAND_GREEN_FALLBACK := Color("#06472f")
const BRAND_GOLD_FALLBACK := Color("#efd079")
const PAPER := Color("#ffffff")
const INK := Color("#22201e")
const MUTED := Color("#686663")
const FACT_INK := Color("#454340")
const LINE := Color("#e7e4e0")
const SOFT := Color("#f7f6f4")
const PHOTO_FILL := Color("#d1c2af")
const SERIF_FONT_NAMES: PackedStringArray = ["Georgia", "Times New Roman", "Noto Serif", "DejaVu Serif", "serif"]

# Tier id whose particulars are open; "" shows the listings. View state only.
var _open_tier_id: String = ""
var _root: Control = null
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


func build(_content: VBoxContainer) -> void:
	var tier_id: String = GameState.state["home"]["tier"]
	if _open_tier_id != "" and _open_tier_id != tier_id and GameData.HOME_TIERS.has(_open_tier_id):
		_build_particulars(_open_tier_id)
		return
	_open_tier_id = ""
	_build_feed()


func teardown() -> void:
	if _root != null:
		if _root.get_parent() != null:
			_root.get_parent().remove_child(_root)
		_root.queue_free()
		_root = null


# Mounts Harrow's own root: brand bar over a white scrolling page. Returns the
# page column.
func _mount_root(root_name: String) -> VBoxContainer:
	_root = UI.vbox(0)
	_root.name = root_name
	shell.mount_custom_root(_root)
	_root.add_child(_build_brand_bar())

	var scroll := UI.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	scroll.add_theme_stylebox_override("panel", paper)
	_root.add_child(scroll)

	var page := UI.vbox(0)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)
	return page


func _build_feed() -> void:
	var feed := UI.vbox(16)
	feed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mount_root(FEED_ROOT_NODE_NAME).add_child(_margins(feed, 12, 0, 12, 16))

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
	body.add_child(_price_row(Home.weekly_bill_base(), "/ week rent" if rented else "/ week utilities"))
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
		body.add_child(_text("Then £%d/week in utilities. Rooms stay." % Home.weekly_bill_for(tier_id, Home.TENURE_OWNED), 12, MUTED))
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
	body.add_child(_price_row(Home.weekly_bill_for(tier_id, Home.TENURE_RENTED), "/ week rent"))
	var facts: Array[String] = []
	if Home.can_buy_tier(tier_id):
		facts.append("Buy £%d" % Home.buy_price(tier_id))
		if Home.sale_credit() > 0:
			facts.append_array(_trade_in_parts(tier_id))
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


# White bordered card: photo flush to the square top edge, then a padded
# body; only the bottom corners round. No clip_children: nested inside the
# phone display's clip it paints the card solid under gl_compatibility.
func _listing_shell(tier_id: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := UI.bordered_panel_style(PAPER, LINE, 6, 0, 0)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	panel.add_theme_stylebox_override("panel", style)
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


func _price_row(amount: int, unit: String, size: int = 20) -> Control:
	var row := UI.hbox(6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var figure := _text("£%d" % amount, size, INK, _bold_font())
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


# Harrow's action: green fill with white text, or white with a green outline
# when secondary; unaffordable reads as a muted outline with the shortfall
# beneath it.
func _add_brand_purchase_button(content: VBoxContainer, text: String, price: int, on_press: Callable, secondary: bool = false) -> void:
	var b := UI.button(text, on_press)
	b.custom_minimum_size = Vector2(0, 44)
	b.focus_mode = Control.FOCUS_NONE
	var fill := UI.bordered_panel_style(PAPER if secondary else brand_green(), brand_green(), 4, 12, 10)
	var outline := UI.bordered_panel_style(PAPER, LINE, 4, 12, 10)
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, fill)
	b.add_theme_stylebox_override("disabled", outline)
	for colour_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(colour_name, brand_green() if secondary else PAPER)
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


# Particulars, top to bottom as the mockup's detail view: hero photo, terms,
# fact cells, the tier's copy, its static plan when it has one, then the
# offer box with Rent/Buy and what the move costs.
func _build_particulars(tier_id: String) -> void:
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	var page := _mount_root(PARTICULARS_ROOT_NODE_NAME)

	var back := UI.button("← Back to listings", _open_particulars.bind(""))
	back.flat = true
	back.focus_mode = Control.FOCUS_NONE
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for colour_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back.add_theme_color_override(colour_name, brand_green())
	back.add_theme_font_size_override("font_size", 14)
	page.add_child(_margins(back, 10, 4, 10, 4))
	page.add_child(_build_photo(tier_id, HERO_PHOTO_HEIGHT))

	var body := UI.vbox(6)
	page.add_child(_margins(body, 18, 19, 18, 28))
	body.add_child(_text(_move_caption(tier_id), 11, brand_green(), _bold_font()))
	body.add_child(_text(tier["name"], 29, INK, _serif_font()))
	body.add_child(_text(tier["description"], 13, MUTED))
	body.add_child(_margins(_price_row(Home.weekly_bill_for(tier_id, Home.TENURE_RENTED), "/ week rent", 23), 0, 14, 0, 0))
	if Home.can_buy_tier(tier_id):
		body.add_child(_text("Or buy for £%d · then £%d/week in utilities" % [Home.buy_price(tier_id), Home.weekly_bill_for(tier_id, Home.TENURE_OWNED)], 13, MUTED))
	body.add_child(_margins(_detail_facts(tier_id), 0, 10, 0, 0))

	body.add_child(_subheading("Property description"))
	body.add_child(_text(tier["particulars"], 14, INK))
	if FloorplanView.has_plan(tier_id):
		body.add_child(_plan_section(tier_id))
	body.add_child(_margins(_offer_box(tier_id), 0, 14, 0, 0))


# Two centred cells split by a thin rule: spare rooms and raid risk.
func _detail_facts(tier_id: String) -> Control:
	var rooms: int = GameData.HOME_TIERS[tier_id]["maxRooms"]
	var cells := [
		["%d" % rooms, "spare room" if rooms == 1 else "spare rooms"],
		["%d%%" % int(round(Home.get_raid_chance_for_tier(tier_id) * 100)), "raid risk"],
	]
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = LINE
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", style)
	var row := UI.hbox(0)
	band.add_child(row)
	for i in cells.size():
		if i > 0:
			var divider := VSeparator.new()
			divider.add_theme_color_override("color", LINE)
			row.add_child(divider)
		var cell := UI.vbox(2)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for part in [_text(cells[i][0], 17, INK, _bold_font()), _text(cells[i][1], 11, MUTED)]:
			part.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(part)
		row.add_child(cell)
	return band


func _subheading(text: String) -> Control:
	return _margins(_text(text, 16, INK, _bold_font()), 0, 16, 0, 3)


# Read-only here; rooms are bought on HQ's noticeboard (docs/hq-diorama-vision.md §7).
func _plan_section(tier_id: String) -> Control:
	var section := UI.vbox(6)
	section.name = PLAN_SECTION_NODE_NAME
	section.add_child(_subheading("Floorplan"))
	section.add_child(FloorplanView.build(tier_id))
	var selectable: int = GameData.FLOORPLANS[tier_id]["slots"].size()
	section.add_child(_text("Bedroom plus %d selectable room%s. Room use is managed at home." % [selectable, "" if selectable == 1 else "s"], 12, MUTED))
	return section


# Soft-grey box: Rent (primary), Buy (secondary, disabled when unaffordable),
# then the move's losses.
func _offer_box(tier_id: String) -> Control:
	var style := StyleBoxFlat.new()
	style.bg_color = SOFT
	style.set_content_margin_all(16)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", style)
	var offer := UI.vbox(9)
	box.add_child(offer)

	var rent: int = Home.weekly_bill_for(tier_id, Home.TENURE_RENTED)
	var credit: int = Home.sale_credit()
	_add_brand_purchase_button(offer, "Rent for £%d/week" % rent, 0, _close_then.bind(Home.rent_to.bind(tier_id)))
	if credit > 0:
		offer.add_child(_text("Renting sells your %s: you receive £%d." % [_current_home_name(), credit], 12, MUTED))
	if Home.can_buy_tier(tier_id):
		var price: int = Home.buy_price(tier_id)
		_add_brand_purchase_button(offer, "Buy for £%d" % price, maxi(0, Home.net_buy_cost(tier_id)), _close_then.bind(Home.buy_to.bind(tier_id)), true)
		if credit > 0:
			var maths: Array[String] = ["£%d" % price]
			maths.append_array(_trade_in_parts(tier_id))
			offer.add_child(_text(" · ".join(maths), 12, MUTED))

	_add_room_carryover(offer, tier_id)
	var lost: Array[String] = []
	for security_id in Home.security_lost_moving_to(tier_id):
		lost.append(GameData.HOME_SECURITY[security_id]["name"])
	var guards: int = Home.guards_lost_moving_to(tier_id)
	if guards > 0:
		lost.append("%d guard%s" % [guards, "" if guards == 1 else "s"])
	if not lost.is_empty():
		offer.add_child(_text("Left behind: %s." % ", ".join(lost), 12, MUTED))
	return box


# What the move does to installed rooms (Home.room_carryover): rooms kept,
# then rooms/seats left behind with the half-price refund. Nothing when no
# rooms are installed.
# PROSE-REVIEW: Harrow's room carryover lines.
func _add_room_carryover(offer: VBoxContainer, tier_id: String) -> void:
	var plan: Dictionary = Home.room_carryover(tier_id)
	if not plan["kept"].is_empty():
		var kept: Array[String] = []
		for room_id in plan["kept"]:
			kept.append(GameData.HOME_ROOMS[room_id]["name"])
		offer.add_child(_text("Rooms moving with you: %s." % ", ".join(kept), 12, MUTED))
	var dropped: String = Home.room_drop_text(plan).strip_edges()
	if dropped != "":
		offer.add_child(_text(dropped, 12, MUTED))


# Trade-in maths for an owned home (R§3.3 "Tier moves"): the sale credit,
# then what the buy nets out to.
func _trade_in_parts(tier_id: String) -> Array[String]:
	var net: int = Home.net_buy_cost(tier_id)
	var parts: Array[String] = ["Sell your %s −£%d" % [_current_home_name(), Home.sale_credit()]]
	parts.append("You pay £%d" % net if net >= 0 else "You receive £%d" % -net)
	return parts


func _current_home_name() -> String:
	return String(GameData.HOME_TIERS[GameState.state["home"]["tier"]]["name"]).to_lower()


func _open_particulars(tier_id: String) -> void:
	_open_tier_id = tier_id
	refresh()


# The move changes which tier is YOUR PLACE, so the listings come back first.
func _close_then(action: Callable) -> void:
	_open_tier_id = ""
	action.call()
	refresh()


# Plans are read-only here; rooms are bought on HQ's noticeboard (§7).
func _add_static_plan(content: VBoxContainer, tier_id: String) -> void:
	if FloorplanView.has_plan(tier_id):
		content.add_child(FloorplanView.build(tier_id))


# The tier's listing photo, cropped to fill the card width; a flat placeholder
# when data/home.json has no image for it or the path doesn't load.
func _build_photo(tier_id: String, height: float = PHOTO_HEIGHT) -> Control:
	var path: String = GameData.HOME_TIERS[tier_id].get("image", "")
	if path != "" and ResourceLoader.exists(path):
		var photo := TextureRect.new()
		photo.name = photo_node_name(tier_id)
		photo.texture = load(path)
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		photo.clip_contents = true
		photo.custom_minimum_size = Vector2(0, height)
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return photo
	var placeholder := PanelContainer.new()
	placeholder.name = photo_placeholder_node_name(tier_id)
	placeholder.custom_minimum_size = Vector2(0, height)
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
