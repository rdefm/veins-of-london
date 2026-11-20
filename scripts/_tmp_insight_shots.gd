extends SceneTree

const OUT := "C:/Users/Richard/AppData/Local/Temp/claude/2966f5fc75e9c9f9/4d91110e-6366-4083-8935-c089d7b02afd/scratchpad/"


func _initialize() -> void:
	call_deferred("_run")


func _setup() -> void:
	var gs := root.get_node("GameState")
	gs.reset()
	gs.state["meta"]["reducedMotion"] = true  # pulse off so the icon is captured fully bright
	var player: Dictionary = gs.state["player"]
	player["senseSkill"] = 2
	gs.state["flags"]["dialGiftGranted"] = true
	gs.state["flags"]["canSellConsumables"] = true
	var dial: Dictionary = Dial.new_dial("collective_brolly")
	dial["level"] = 5
	dial["lenses"] = [{ "ore": "fate", "tier": 5 }]
	player["dial"] = dial
	player["orichalchum"]["time"] = 50
	player["orichalchum"]["physics"] = 20
	Crafting.inventory_add("blast", 2, 3)
	var market: Dictionary = gs.state["market"]
	market["goods"]["ore"]["time"]["stock"] = 300
	market["goods"]["ore"]["physics"]["stock"] = 6000
	market["goods"]["ore"]["fate"]["stock"] = 200
	print(MarketInsight.reads())


func _run() -> void:
	_setup()
	var gs := root.get_node("GameState")
	gs.state["phoneNav"]["app"] = "ticker"
	var phone := PhoneScreen.new()
	root.add_child(phone)
	(phone.app_instance("ticker") as TickerApp)._tab = TickerApp.STOCK_TAB
	phone._refresh()
	await _shot("market_app")
	root.remove_child(phone)
	phone.queue_free()

	_setup()
	Modal.open("sell_menu")
	var host := Control.new()
	host.size = Vector2(390, 844)
	root.add_child(host)
	host.add_child(ModalLayer.new())
	await _shot("trade_menu")
	quit(0)


func _shot(name: String) -> void:
	for i in 8:
		await process_frame
	root.get_texture().get_image().save_png(OUT + name + ".png")
	print("Saved ", name)
