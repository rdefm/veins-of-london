extends "res://tests/test_base.gd"

# Prologue timing log: entries made on event start/end and fight open/exit,
# kept outside GameState.state.


func run() -> void:
	run_case("event_start_and_completion_log_one_entry", func():
		GameState.reset()
		TimingLog.clear()
		var event_id: String = GameData.EVENTS.keys()[0]
		TimingLog.begin(TimingLog.KIND_EVENT, event_id)
		assert_eq(TimingLog.entries.size(), 0, "open entry is not listed yet")
		TimingLog.end(TimingLog.KIND_EVENT, event_id)

		assert_eq(TimingLog.entries.size(), 1, "one finished entry")
		var entry: Dictionary = TimingLog.entries[0]
		assert_eq(entry["kind"], "event", "kind")
		assert_eq(entry["id"], event_id, "id")
		assert_true(float(entry["durationSec"]) >= 0.0, "duration set")
		assert_eq(entry["startDay"], GameState.state["world"]["day"], "day stamped")
		assert_true(entry.has("endBlock"), "end block stamped")
		TimingLog.clear()
	)

	run_case("start_event_then_abandon_logs_an_event_entry", func():
		GameState.reset()
		TimingLog.clear()
		var event_id: String = GameData.EVENTS.keys()[0]
		Events.start_event(event_id)
		Events.abandon()

		assert_eq(TimingLog.entries.size(), 1, "abandon closes the entry")
		assert_eq(TimingLog.entries[0]["id"], event_id, "id")
		TimingLog.clear()
	)

	run_case("fight_open_and_exit_log_a_fight_entry", func():
		GameState.reset()
		TimingLog.clear()
		Combat.start_mugging()
		assert_eq(TimingLog.entries.size(), 0, "fight still open")
		Combat.exit_combat()

		assert_eq(TimingLog.entries.size(), 1, "exit closes the entry")
		assert_eq(TimingLog.entries[0]["kind"], "fight", "kind")
		TimingLog.clear()
	)

	run_case("state_tree_holds_no_timing_data_and_csv_has_total", func():
		GameState.reset()
		TimingLog.clear()
		TimingLog.begin(TimingLog.KIND_EVENT, "x")
		TimingLog.end(TimingLog.KIND_EVENT, "x")

		assert_true(not JSON.stringify(GameState.state).contains("startMsec"), "no real-time stamps in state")
		var csv := TimingLog.to_csv()
		assert_true(csv.contains("event,x,"), "row present")
		assert_true(csv.contains("total,"), "total row present")
		TimingLog.clear()
	)
