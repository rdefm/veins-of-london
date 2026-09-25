class_name HqDoorScreen
extends Control

const GRID_COLUMNS := 2
const TILE_MIN_WIDTH := 160.0
const TILE_LABEL_MAX_WIDTH := 130.0
static func _installed_count(home: Dictionary) -> int:
	var count: int = home["security"].size()
	if Home.get_guard_count() > 0:
		count += 1
	return count

func _ready() -> void:
	UI.anchor_full_rect(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in get_children():
		child.queue_free()
	# Off the Map tab: light card family (MapCardStyle).
	MapPalette.build_light(_build)


func _build() -> void:
	var sc := UI.scroll_container()
	add_child(sc)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", int(UI.top_bar_clearance()) + 16)
	margin.add_theme_constant_override("margin_bottom", int(UI.nav_bar_clearance()) + 16)
	sc.add_child(margin)

	var content := UI.vbox(8)
	margin.add_child(content)

	content.add_child(UI.back_button("hq"))

	var home: Dictionary = GameState.state["home"]
	content.add_child(UI.heading("Security (%d/%d)" % [_installed_count(home), GameData.HOME_SECURITY.size()]))

	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)

	for security_id in GameData.HOME_SECURITY.keys():
		grid.add_child(_build_security_slot(security_id))
func _tile_label(text: String, muted: bool = false) -> Label:
	var l: Label = UI.muted_label(text) if muted else UI.label(text)
	l.custom_minimum_size.x = minf(l.custom_minimum_size.x, TILE_LABEL_MAX_WIDTH)
	return l
func _build_security_slot(security_id: String) -> Control:
	var home: Dictionary = GameState.state["home"]
	var sec: Dictionary = GameData.HOME_SECURITY[security_id]
	var order: Array = GameData.HOME_TIER_ORDER
	var available: bool = order.find(home["tier"]) >= order.find(sec["minTier"])

	var discount: float = 0.7 if GameState.state["flags"]["securityContactUnlocked"] else 1.0
	var adj_cost: int = GameState.round_epsilon(sec["cost"] * discount)

	var stackable: bool = security_id == Home.GUARD_SECURITY_ID
	var count: int = Home.get_guard_count() if stackable else 0
	var installed: bool = count > 0 if stackable else home["security"].has(security_id)
	var label: String = sec["name"] if count == 0 else "%s ×%d" % [sec["name"], count]

	var c := MapCardStyle.card(12)
	c["panel"].custom_minimum_size.x = TILE_MIN_WIDTH
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var prefix := "✅ " if installed else ("🔒 " if not available else "")
	c["content"].add_child(_tile_label(prefix + label))
	var desc: String = sec["description"]
	if not available:
		desc += " Requires %s." % GameData.HOME_TIERS[sec["minTier"]]["name"]
	c["content"].add_child(_tile_label(desc, true))

	if not available:
		c["content"].add_child(_tile_label("Locked", true))
	elif installed and not stackable:
		c["content"].add_child(_tile_label("Installed", true))
	else:
		c["content"].add_child(MapCardStyle.text_button("£%d" % adj_cost, func(): Home.add_security(security_id), GameState.state["player"]["cash"] < adj_cost))

	return c["panel"]
