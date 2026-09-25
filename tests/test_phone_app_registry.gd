extends "res://tests/test_base.gd"

# scenes/phone_apps/phone_app_registry.gd: every PhoneNav app id (plus the
# debug app) maps to a PhoneApp subclass, so phone.gd's shell can dispatch
# any open app without its own match.


func run() -> void:
	run_case("every_PhoneNav_app_id_and_debug_has_a_registry_entry", func():
		var expected: Array[String] = PhoneNav.APPS.duplicate()
		expected.append("debug")
		for app_id in expected:
			assert_true(PhoneAppRegistry.REGISTRY.has(app_id), "registry has %s" % app_id)
	)

	run_case("every_registry_entry_instantiates_a_PhoneApp_with_build", func():
		for app_id in PhoneAppRegistry.REGISTRY.keys():
			var app = PhoneAppRegistry.REGISTRY[app_id].new()
			assert_true(app is PhoneApp, "%s is a PhoneApp" % app_id)
			assert_true(app.has_method("build"), "%s exposes build()" % app_id)
	)

	run_case("home_is_not_a_registry_entry_the_shell_owns_the_grid", func():
		assert_true(not PhoneAppRegistry.REGISTRY.has("home"), "home grid lives in the shell")
	)

	run_case("shell_instantiates_one_app_per_id_and_reuses_it_across_refreshes", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "todo"
		var phone := PhoneScreen.new()
		phone._ready()
		var first = phone.app_instance("todo")
		phone._refresh()
		assert_true(first == phone.app_instance("todo"), "same instance survives a refresh")
		assert_true(phone.app_instance("todo").shell == phone, "app knows its shell")
		phone.free()
	)

	run_case("messages_conversation_root_is_freed_when_the_shell_rebuilds_for_another_app", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		PhoneNav.select_conversation("des")
		var phone := PhoneScreen.new()
		phone._ready()
		var messages: MessagesApp = phone.app_instance("messages")
		var root: Control = messages._conversation_root
		assert_true(root != null and root.get_parent() == phone.device_shell.custom_mount, "conversation root mounts inside the device content area")
		assert_true(not phone.device_shell.content_scroll.visible, "shared scroll body hidden while a conversation is open")
		PhoneNav.go_home()
		assert_true(messages._conversation_root == null, "teardown clears the app's root ref")
		assert_true(root.is_queued_for_deletion(), "old root queued for free")
		assert_true(phone.device_shell.content_scroll.visible, "shared scroll body visible again on home")
		phone.free()
	)
