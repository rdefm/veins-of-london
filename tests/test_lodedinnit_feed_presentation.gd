extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")


static func _entry(seq: int, comments: Array, body: String) -> Dictionary:
	return {
		"postId": "status:hired", "seq": seq, "authorKind": "individual", "author": "marcia",
		"day": 1, "block": 0, "likes": 12, "comments": comments, "text": body,
	}


static func _open_feed(phone: PhoneScreen) -> void:
	GameState.state["flags"]["bizA1JamesJoined"] = true
	GameState.state["phoneNav"]["app"] = "lodedinnit"
	phone._ready()
	(phone.find_child(LodedInnitApp.FEED_TAB_NODE_NAME, true, false) as Button).pressed.emit()


func run() -> void:
	run_case("empty_feed_keeps_intro_and_empty_message", func():
		GameState.reset()
		var phone := PhoneScreen.new()
		_open_feed(phone)
		var intro := phone.find_child(LodedInnitApp.FEED_INTRO_NODE_NAME, true, false)
		assert_true(intro != null)
		assert_true(NodeQuery.label_texts(intro).has("Network activity"))
		assert_true(NodeQuery.label_texts(intro).has("The people doing the work, and the people saying they are."))
		assert_true(NodeQuery.label_texts(phone).has("Nothing on your feed yet. Posts arrive as the day goes on."))
		assert_eq(phone.find_children(LodedInnitApp.FEED_CARD_NODE_NAME, "PanelContainer", true, false).size(), 0)
		var root := phone.find_child(LodedInnitApp.ROOT_NODE_NAME, true, false)
		assert_eq((root.get_child(2) as ScrollContainer).vertical_scroll_mode, ScrollContainer.SCROLL_MODE_SHOW_NEVER)
		phone.free()
	)

	run_case("single_post_has_dark_social_card_and_zero_comments", func():
		GameState.reset()
		var entry := _entry(1, [], "A long post that needs to wrap cleanly on a narrow phone screen. The work continues after the first line, with enough detail to cross several lines.")
		GameState.state["hiring"]["feed"].append(entry)
		var phone := PhoneScreen.new()
		_open_feed(phone)
		var card := phone.find_child(LodedInnitApp.FEED_CARD_NODE_NAME, true, false) as PanelContainer
		var style := card.get_theme_stylebox("panel") as StyleBoxFlat
		assert_eq(style.bg_color, Color("#303034"))
		assert_eq(style.border_color, Color("#45454b"))
		assert_eq(style.corner_radius_top_left, 14)
		assert_eq(style.get_content_margin(SIDE_LEFT), 14.0)
		assert_eq(style.get_content_margin(SIDE_TOP), 14.0)
		var labels := NodeQuery.label_texts(card)
		var view := LodedInnitFeed.card(entry)
		assert_true(labels.has(view["name"]))
		assert_true(labels.has("%s · %s" % [view["meta"], view["time"]]))
		var body := phone.find_child(LodedInnitApp.FEED_BODY_NODE_NAME, true, false) as Label
		assert_eq(body.text, view["body"])
		assert_eq(body.get_theme_font_size("font_size"), 12)
		assert_eq(body.custom_minimum_size.x, 0.0)
		var engage := phone.find_child(LodedInnitApp.FEED_ENGAGEMENT_NODE_NAME, true, false)
		assert_eq(NodeQuery.label_texts(engage), ["12", "likes", "0", "comments"])
		assert_eq(phone.find_children(LodedInnitApp.FEED_COMMENT_NODE_NAME, "PanelContainer", true, false).size(), 0)
		phone.free()
	)

	run_case("one_comment_uses_singular_count", func():
		GameState.reset()
		GameState.state["hiring"]["feed"].append(_entry(1, ["dot:c01"], "One reply."))
		var phone := PhoneScreen.new()
		_open_feed(phone)
		var engage := phone.find_child(LodedInnitApp.FEED_ENGAGEMENT_NODE_NAME, true, false)
		assert_eq(NodeQuery.label_texts(engage), ["12", "likes", "1", "comment"])
		assert_eq(phone.find_children(LodedInnitApp.FEED_COMMENT_NODE_NAME, "PanelContainer", true, false).size(), 1)
		phone.free()
	)

	run_case("two_comments_render_below_counts_with_author_emphasis", func():
		GameState.reset()
		var entry := _entry(1, ["dot:c01", "priya:c02"], "A short update.")
		GameState.state["hiring"]["feed"].append(entry)
		var phone := PhoneScreen.new()
		_open_feed(phone)
		var engage := phone.find_child(LodedInnitApp.FEED_ENGAGEMENT_NODE_NAME, true, false)
		assert_eq(NodeQuery.label_texts(engage), ["12", "likes", "2", "comments"])
		var comments := phone.find_children(LodedInnitApp.FEED_COMMENT_NODE_NAME, "PanelContainer", true, false)
		assert_eq(comments.size(), 2)
		var view_comments: Array = LodedInnitFeed.card(entry)["comments"]
		for i in comments.size():
			var panel := comments[i] as PanelContainer
			assert_eq((panel.get_theme_stylebox("panel") as StyleBoxFlat).border_width_left, 2)
			var author := panel.get_child(0).get_child(0) as Label
			assert_eq(author.text, "%s:" % view_comments[i]["author"])
			assert_true(author.has_theme_font_override("font"))
			assert_eq((panel.get_child(0).get_child(1) as Label).text, view_comments[i]["text"])
		phone.free()
	)
