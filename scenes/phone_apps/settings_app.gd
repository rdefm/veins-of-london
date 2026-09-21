class_name SettingsApp
extends PhoneApp

const Preferences := preload("res://systems/preferences.gd")


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Settings"))
	var motion := CheckButton.new()
	motion.text = GameData.DAILY_CYCLE["reducedMotionLabel"]
	motion.button_pressed = GameState.state["meta"].get("reducedMotion", false)
	motion.toggled.connect(Preferences.set_reduced_motion)
	content.add_child(motion)
	var vibrate := CheckButton.new()
	vibrate.text = "Vibrate for alarms"
	vibrate.button_pressed = GameState.state["meta"].get("vibrationEnabled", true)
	vibrate.toggled.connect(Preferences.set_vibration_enabled)
	content.add_child(vibrate)
