class_name Bank
extends RefCounted

# Transaction log for player.cash mutations (bugfixes-38: the Bank app,
# "Reynard's"). Static funcs only. Mirrors systems/notify.gd's
# append-and-evict-from-front shape exactly (see LOG_CAP) -- every direct
# player.cash mutation in the codebase calls record() alongside itself, so
# this is a complete history from turn one, not a partial one assembled
# ticket-by-ticket later.
#
# Entries are pure data (id, amount, label, day) -- no Node/Timer/Callable,
# same purity contract as `notifications` (state purity underlies save/
# snapshot/Rewind). Display-only, per the ticket: no interest, loans, or
# transfers live here or anywhere else.

const LOG_CAP := 50


static func record(amount: int, label: String) -> void:
	var id := str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))
	var day: int = GameState.state["world"]["day"]
	var entry := { "id": id, "amount": amount, "label": label, "day": day }
	var log: Array = GameState.state["bankLog"]
	log.append(entry)
	while log.size() > LOG_CAP:
		log.remove_at(0)
	EventBus.state_changed.emit()
