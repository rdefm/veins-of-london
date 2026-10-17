class_name LessonSession
extends RefCounted

# A locked lesson at the live bench (.scratch/recipe-acquisition/spec.md
# § Bench lesson session), opened by the start_lesson_session event op.
# state.lab.lesson is null, or { recipe, goalRank, hintRung, pool (ore type
# -> calc the lesson's runs draw on), failedRuns, met, returnScreen, lines
# (escalation key hintExact/talkThrough -> the line the bench shows instead
# of its own) }.
#
# While a lesson is open: the bench is docked on its recipe, runs draw calc
# from the pool instead of the player's stock (Lab.calc_available), the
# bench Rewind and the time-block Rewind are refused, and Nav.go_to only
# reaches the bench. Items and XP from every run go to the player. A failed
# run (rank below goalRank, cracked or abandoned) refills the pool to one
# run's cost and counts toward escalation (data/lab.json lesson): the hint
# rung exact at hintExactAfterFails, a talk-through showing every hidden
# step of the goal's rungs at talkThroughAfterFails. A run at goalRank or
# better marks the lesson met; resume() then closes it and returns to the
# paused event.


static func _cfg() -> Dictionary:
	return GameData.LAB.get("lesson", {})


static func lesson() -> Variant:
	return GameState.state["lab"].get("lesson")


static func is_open() -> bool:
	return lesson() != null


# True while the lesson's runs still draw on its pool: open and not yet met.
static func is_running() -> bool:
	return is_open() and not bool(lesson()["met"])


# Opens the lesson for a known (or here granted) recipe, teaching hintRung
# vague, and docks the bench on it. Refused while a lesson or run is open.
static func start(recipe_key: String, goal_rank: int, hint_rung: String = "", lines: Dictionary = {}) -> Dictionary:
	if is_open():
		return { "ok": false, "reason": "A lesson is already open." }
	if Lab.active_run() != null:
		return { "ok": false, "reason": "A run is already open." }
	if Lab.procedure_def(recipe_key).is_empty():
		return { "ok": false, "reason": "Unknown recipe." }
	Lab.grant_recipe(recipe_key)
	if not hint_rung.is_empty():
		RecipeKnowledge.grant_rung(recipe_key, hint_rung, "vague")
	GameState.state["lab"]["lesson"] = {
		"recipe": recipe_key, "goalRank": goal_rank, "hintRung": hint_rung,
		"pool": Lab.base_calc(recipe_key), "failedRuns": 0, "met": false,
		"returnScreen": "event" if GameState.state["event"] != null else "hq",
		"lines": lines.duplicate(),
	}
	Nav.go_to("hq_lab_bench")
	return { "ok": true }


static func pool() -> Dictionary:
	return lesson()["pool"]


# The open lesson's own line for an escalation key, or fallback.
static func line(key: String, fallback: String) -> String:
	if not is_open():
		return fallback
	return str(lesson().get("lines", {}).get(key, fallback))


# Why the open lesson refuses a run of this recipe, or "" when it allows it
# (or no lesson is open).
static func run_block_reason(recipe_key: String) -> String:
	if not is_open():
		return ""
	if bool(lesson()["met"]):
		return "Lesson done."
	if recipe_key != lesson()["recipe"]:
		return "Not this lesson's recipe."
	return ""


static func hint_exact_after() -> int:
	return int(_cfg().get("hintExactAfterFails", 3))


static func talk_through_after() -> int:
	return int(_cfg().get("talkThroughAfterFails", 6))


static func talk_through() -> bool:
	return is_open() and int(lesson()["failedRuns"]) >= talk_through_after()


# The ideal indices the talk-through shows exact: every hidden step of a
# rung whose ceiling is at or under the goal rank. [] before it opens.
static func talk_through_steps(recipe_key: String) -> Array:
	if not talk_through() or recipe_key != lesson()["recipe"]:
		return []
	var steps := []
	for rung in RecipeKnowledge.rungs():
		if rung != "base" and RecipeKnowledge.rung_ceiling(rung) <= int(lesson()["goalRank"]):
			steps.append_array(Lab.rung_steps(recipe_key, rung))
	return steps


# Called by the Lab once per finished, cracked or abandoned run while the
# lesson is running. Returns { met, failedRuns, hintExact, talkThrough }
# (hintExact/talkThrough true on the failure that crossed their threshold).
static func after_run(result: Dictionary) -> Dictionary:
	var s: Dictionary = lesson()
	var outcome := { "met": false, "failedRuns": int(s["failedRuns"]), "hintExact": false, "talkThrough": false }
	if result["outcome"] == "finished" and int(result["rank"]) >= int(s["goalRank"]):
		s["met"] = true
		s["pool"] = {}
		outcome["met"] = true
		EventBus.state_changed.emit()
		return outcome
	s["failedRuns"] = int(s["failedRuns"]) + 1
	s["pool"] = Lab.base_calc(s["recipe"])
	outcome["failedRuns"] = s["failedRuns"]
	if s["failedRuns"] == hint_exact_after() and not String(s["hintRung"]).is_empty():
		RecipeKnowledge.grant_rung(s["recipe"], s["hintRung"], "exact")
		outcome["hintExact"] = true
	if s["failedRuns"] == talk_through_after():
		outcome["talkThrough"] = true
	EventBus.state_changed.emit()
	return outcome


# Closes a met lesson and returns to the paused event (or the HQ when the
# lesson was opened from an event's on_complete).
static func resume() -> Dictionary:
	if not is_open() or not bool(lesson()["met"]):
		return { "ok": false, "reason": "Lesson not done." }
	var back: String = lesson()["returnScreen"]
	if back == "event" and GameState.state["event"] == null:
		back = "hq"
	GameState.state["lab"]["lesson"] = null
	Nav.go_to(back)
	return { "ok": true }
