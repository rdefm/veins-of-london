class_name ModalLayer
extends Control


var _dim: ColorRect
var _card: PanelContainer
var _scroll: ScrollContainer
var _card_content: VBoxContainer
var _trade_view: PanelContainer

const MAX_CARD_HEIGHT := 620.0

func _ready() -> void:
	UI.anchor_full_rect(self)
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	# Off the Map tab: every modal is the light vein-popover card (MapCardStyle).
	_card = PanelContainer.new()
	MapPalette.build_light(func(): MapCardStyle.style_panel(_card, 18, 0.16))
	UI.anchor_center(_card)
	add_child(_card)

	_scroll = UI.scroll_container()
	_scroll.custom_minimum_size = Vector2(330, 0)
	_card.add_child(_scroll)

	_card_content = UI.vbox(8)
	_card_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_card_content)

	_trade_view = preload("res://scenes/modals/sell_menu_view.gd").new()
	UI.anchor_full_rect(_trade_view)
	_trade_view.visible = false
	add_child(_trade_view)

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _on_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		_dismiss_modal()


func _dismiss_modal() -> void:
	var modal = GameState.state["modal"]
	if modal == null:
		return
	match modal.get("type", ""):
		"sell_menu":
			SellMenuModal.cancel()
		"james_job_offer":
			JamesJobOfferModal.decline()
		"sale_result":
			SaleResultModal.close()
		"archie_deal_result":
			ArchieDealResultModal.close()
		_:
			Modal.close()


func _refresh() -> void:
	var modal = GameState.state["modal"]
	visible = modal != null
	if modal == null:
		if _trade_view.visible:
			_trade_view.call("reset_ui")
		_trade_view.visible = false
		return
	if modal.get("type", "") == "sell_menu":
		_card.visible = false
		_trade_view.visible = true
		_trade_view.offset_top = UI.top_bar_clearance() + 8.0
		_trade_view.offset_bottom = -NavBar.BAR_HEIGHT
		_trade_view.call("refresh", modal.get("data", {}))
		return
	if _trade_view.visible:
		_trade_view.call("reset_ui")
	_trade_view.visible = false
	_card.visible = true

	for child in _card_content.get_children():
		child.queue_free()

	_build_modal_content(modal)

	_size_card_to_content()
	_size_card_to_content.call_deferred()


func _size_card_to_content() -> void:
	if _card_content.get_child_count() == 0:
		return
	var content_height: float = _card_content.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = minf(content_height, MAX_CARD_HEIGHT)


func _build_modal_content(modal: Dictionary) -> void:
	var type_id: String = modal.get("type", "")
	var data: Dictionary = modal.get("data", {})

	MapPalette.build_light(func():
		if ModalRegistry.REGISTRY.has(type_id):
			ModalRegistry.REGISTRY[type_id].build(_card_content, data)
			return
		_card_content.add_child(UI.heading(type_id))
		_card_content.add_child(UI.label("…"))
		_card_content.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))
	)
