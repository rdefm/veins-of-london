# 05 — Bank transaction ids from a state counter, not the clock

**What to build:** Bank log entries get ids from a counter held in game state instead of the wall clock (`Time.get_ticks_usec()`), so two same-seed runs produce byte-identical state — which is what lets golden-hash checks prove perf refactors change nothing. Source: code review 2026-11-21 item 15 (`.scratch/code-review/recommendations.md`).

Zero gameplay change, and **the RNG stream must not shift**: `Bank.record()` currently draws `Rng.randi_range(1000, 999999)` for the id; keep exactly one equivalent draw per record (fold it into the id or discard it) so every later roll is unchanged. Ids must stay unique and stay strings. Old saves without the counter get it seeded past any existing id (or from the log length) so new ids never collide with saved ones. The counter is a primitive in the pure state tree; Rewind/snapshots carry it automatically.

Also tidy `.gitignore`: the Godot binary entries name 4.4 (`Godot_v4.4-stable_*`) while the target is 4.7 — generalise them (e.g. `Godot_v*-stable_*`) so any local engine binary is ignored.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/bank.gd` (`record()`, line ~13)
- `autoload/GameState.gd` (`new_game_state()` — where `bankLog` is seeded; add the counter beside it)
- `autoload/SaveManager.gd` (`backfill_defaults()` — seed the counter for old saves)
- anything reading bank entry `id` (grep `bankLog` in `scenes/` — e.g. the Bank phone app)
- `tests/` existing bank tests
- `.gitignore`
- REFERENCE.md §2 (state paths — confirm/record the new key's name with the human if §2 lists `bankLog`'s shape)

**Status:** ready-for-agent

- [ ] `Bank.record()` uses no clock; ids unique, strings, monotonic per save
- [ ] Same seed + same actions → identical `bankLog` across two runs (test)
- [ ] Exactly one `Rng` draw per record, as before (test: the next `Rng` value after N records matches the pre-change behaviour)
- [ ] Loading a save that has bank entries but no counter: new ids don't collide with existing ones (test)
- [ ] `.gitignore` binary pattern covers any Godot version
- [ ] Syntax check clean on touched files; full suite passes
- [ ] CODEMAP updated if bank.gd's description changes
