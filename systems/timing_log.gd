# Debug-only log of how long each event and fight takes in real play. Real-time
# stamps live in static vars here, outside GameState.state, so save and Rewind
# stay pure; the in-game day/block is read from state. Off in release builds.
class_name TimingLog
extends RefCounted

const KIND_EVENT := "event"
const KIND_FIGHT := "fight"
const EXPORT_PATH := "user://prologue_timing.csv"

# Finished entries: { id, kind, startMsec, endMsec, durationSec, startDay,
# startBlock, endDay, endBlock }. Open entries wait in _open until end().
static var entries: Array = []
static var _open: Array = []


static func enabled() -> bool:
	return OS.is_debug_build()


static func begin(kind: String, id: String) -> void:
	if not enabled():
		return
	var world: Dictionary = GameState.state["world"]
	_open.append({ "id": id, "kind": kind, "startMsec": Time.get_ticks_msec(),
		"startDay": int(world["day"]), "startBlock": int(world["timeBlock"]) })


# Closes the newest open entry of this kind (and id, when given).
static func end(kind: String, id: String = "") -> void:
	for i in range(_open.size() - 1, -1, -1):
		var entry: Dictionary = _open[i]
		if entry["kind"] != kind or (id != "" and entry["id"] != id):
			continue
		_open.remove_at(i)
		var world: Dictionary = GameState.state["world"]
		entry["endMsec"] = Time.get_ticks_msec()
		entry["durationSec"] = (int(entry["endMsec"]) - int(entry["startMsec"])) / 1000.0
		entry["endDay"] = int(world["day"])
		entry["endBlock"] = int(world["timeBlock"])
		entries.append(entry)
		return


static func clear() -> void:
	entries = []
	_open = []


static func total_seconds() -> float:
	var total := 0.0
	for entry in entries:
		total += float(entry["durationSec"])
	return total


static func summary_line(entry: Dictionary) -> String:
	return "%s %s  %.1fs  d%d b%d > d%d b%d" % [entry["kind"], entry["id"], float(entry["durationSec"]),
		entry["startDay"], entry["startBlock"], entry["endDay"], entry["endBlock"]]


static func to_csv() -> String:
	var lines: PackedStringArray = ["kind,id,start_sec,end_sec,duration_sec,start_day,start_block,end_day,end_block"]
	for entry in entries:
		lines.append("%s,%s,%.1f,%.1f,%.1f,%d,%d,%d,%d" % [entry["kind"], entry["id"],
			int(entry["startMsec"]) / 1000.0, int(entry["endMsec"]) / 1000.0, float(entry["durationSec"]),
			entry["startDay"], entry["startBlock"], entry["endDay"], entry["endBlock"]])
	lines.append("total,,,,%.1f,,,," % total_seconds())
	return "\n".join(lines) + "\n"


# Returns the path written, or "" on failure.
static func export_csv() -> String:
	var file := FileAccess.open(EXPORT_PATH, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(to_csv())
	return EXPORT_PATH
