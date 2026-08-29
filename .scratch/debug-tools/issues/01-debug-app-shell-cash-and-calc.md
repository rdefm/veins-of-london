# 01 — Debug app: phone tile, cash and calc adjusters

**What to build:** A new "Debug" app on the phone, visible only on a save that was started via the title screen's Debug Start button — never on a normally-started game. Opening it gives the player working controls to add cash and to add calc (orichalchum) of any of the five ore types. This ticket lands the app's shell (tile, visibility gate, screen scaffold) and its two simplest actions; tickets 02 and 03 add more actions to the same screen.

**Confirmed mechanics (from 2026-08-29 grill-me session — no open design questions, only UI-detail calls left to the implementer):**

- **Visibility gate:** a new persistent flag (e.g. `flags.debugStartUsed`), set `true` only inside `DebugStart.apply()` (`systems/debug_start.gd`) and never settable any other way. `phone.gd`'s app-tile list reads this flag to decide whether to render the Debug tile at all — a normally-started game never sees it, regardless of anything the player does in play.
- **Add money:** adjusts `player.cash` by a player-entered amount.
- **Add calc:** adjusts `player.orichalchum[ore_type]` by a player-entered amount, for a player-chosen ore type (`GameData.ORE_TYPES.keys()`).
- **Input style, layout, exact copy:** left to the implementer — this is a debug-only tool, not user-facing polish. Follow the phone app screen conventions already established elsewhere (e.g. `scenes/screens/bank_app.gd`-style single-screen layout) for consistency, but no PROSE-REVIEW needed since none of this copy is player-facing narrative.

**Where:** `systems/debug_start.gd` (new flag), `scenes/screens/phone.gd` (app tile list + visibility gate), a new debug app screen (naming/location matching how other phone apps are scened, e.g. alongside `bank_app.gd`), `autoload/GameState.gd` (flag default, `false`).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] New `debugStartUsed` (or equivalent) flag defaults `false` in `GameState.gd`'s flags dict, and `DebugStart.apply()` sets it `true` as part of its existing flag-forcing pass.
- [ ] A "Debug" app tile appears on the phone only when this flag is `true`; a normal New Game never shows it.
- [ ] The Debug app screen has a working "add money" control (arbitrary player-entered amount added to `player.cash`).
- [ ] The Debug app screen has a working "add calc" control (player picks an ore type and an amount, added to `player.orichalchum[type]`).
- [ ] Test coverage: flag defaults false and is only ever set by `DebugStart.apply()`; add-money and add-calc mutate the expected state fields by the expected amounts.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes.
- [ ] Manual check noted for the human: debug-start a game, confirm the Debug tile is visible and the two controls work; start a normal New Game and confirm the tile is absent.
