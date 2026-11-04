extends "res://tests/test_base.gd"

# ToDo carousel app: paging, arrows at the ends, banner states and fallback.

static func _open() -> PhoneScreen:
	GameState.state["phoneNav"]["app"] = "todo"
	var phone := PhoneScreen.new()
	phone._ready()
	return phone


static func _node(phone: Node, node_name: String) -> Node:
	return phone.find_child(node_name, true, false)


func run() -> void:
	run_case("opens_on_default_page_and_pages_without_wrap", func():
		GameState.reset()
		var phone := _open()
		var pages := Todo.get_pages()
		assert_eq(_node(phone, "BannerTitle").text, pages[Todo.default_page_index()]["label"], "opens on most recently changed")
		var app: ToDoApp = phone.app_instance("todo")
		app._go(pages, 0)
		phone._refresh()
		assert_eq(_node(phone, "BannerPrev"), null, "no prev arrow on first page")
		assert_true(_node(phone, "BannerNext") != null, "next arrow on first page")
		app._go(pages, pages.size() - 1)
		phone._refresh()
		assert_eq(_node(phone, "BannerNext"), null, "no next arrow on last page")
		app._go(pages, pages.size())
		assert_eq(app._page_id, pages[pages.size() - 1]["id"], "does not wrap past the end")
		phone.free()
	)

	run_case("locked_page_shows_empty_text", func():
		GameState.reset()
		var phone := _open()
		var pages := Todo.get_pages()
		var app: ToDoApp = phone.app_instance("todo")
		var idx := -1
		for i in pages.size():
			if pages[i]["status"] == "placeholder":
				idx = i
		assert_true(idx >= 0, "fresh game has a placeholder page")
		app._go(pages, idx)
		phone._refresh()
		assert_eq(_node(phone, "BannerEmpty").text, pages[idx]["emptyText"])
		phone.free()
	)

	run_case("finished_page_is_stamped", func():
		GameState.reset()
		GameState.state["flags"]["prologueDone"] = true
		var phone := _open()
		var pages := Todo.get_pages()
		var app: ToDoApp = phone.app_instance("todo")
		for i in pages.size():
			if pages[i]["status"] == "done":
				app._go(pages, i)
		phone._refresh()
		assert_true(_node(phone, "BannerStamp") != null or Todo.get_pages().filter(func(p): return p["status"] == "done").is_empty(), "done page carries the stamp")
		phone.free()
	)

	run_case("banner_convention_path_wins_with_default_fallback", func():
		var app := ToDoApp.new()
		assert_true(app._banner_texture("tutorial") != null, "questline banner resolves")
		assert_true(app._banner_texture("no_such_questline") != null, "falls back to default")
	)
