extends "res://tests/test_base.gd"

# scenes/components/contact_avatar.gd: image path lookup and the initials
# fallback when no headshot file exists.


func run() -> void:
	run_case("path_is_assets_contacts_id_png", func():
		assert_eq(ContactAvatar.path("archie"), "res://assets/contacts/archie.png"))

	run_case("missing_image_gives_null_texture", func():
		assert_true(ContactAvatar.texture("no_such_contact_xyz") == null))

	run_case("missing_image_falls_back_to_initials", func():
		var panel := ContactAvatar.build("no_such_contact_xyz", 36, 18, "AB",
				Color.BLACK, Color.WHITE, 11)
		assert_eq(panel.get_child_count(), 1)
		var label := panel.get_child(0) as Label
		assert_true(label != null, "fallback child is a Label")
		assert_eq(label.text, "AB")
		assert_eq(panel.custom_minimum_size, Vector2(36, 36))
		panel.free())
