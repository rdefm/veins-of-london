# 04 — Sprite picker on New Game and Debug Start

**What to build:** Tapping **New Game** or **Debug Start** on the title screen first shows a character picker. It shows one discovered territorial variant at a time as its idle preview, with ◀ / ▶ arrows to cycle through them and a **Select** button. Selecting sets that variant as the player's sprite for the rest of the save, then carries on as before (intro event for New Game; the maximal-unlock state for Debug Start). Ticket 03's exclusion rule then keeps that variant off every enemy for the whole save.

Decisions (agreed with the human):
- **The choice is final** for the save. There's no way to change it later.
- **Previews only:** idle preview, arrows, and Select. No names, labels, or descriptions beyond what the button and navigation need.
- **Built as an overlay on the title screen, not a new screen id**, so REFERENCE.md §2.2's screen list doesn't change. (If the implementer finds a new screen id truly unavoidable, stop and ask.)
- **The screen doesn't mutate state:** the picker calls a system function (e.g. a small setter in an appropriate `systems/` file) that validates the key against the discovered variant list and writes `player.model`.
- **Order of operations:**
  - New Game: reset state → picker → set model → seed day-one veins → start `intro`.
  - Debug Start: picker → `DebugStart.apply()` → set model (or have apply accept the model). The chosen model must survive whatever reset DebugStart does.
- **Cancel / back:** returns to the title screen with no game started.
- Style follows `docs/ui-vision.md` for the title/menu family and uses existing components (e.g. `MapCardStyle.chip_button`) where possible.

**Blocked by:** 02 — Build territorial variant sprite sets from the folders.

**Relevant files:**
- `scenes/screens/title.gd` — `_on_new_game_pressed`, `_on_debug_start_pressed`, `_build`
- `systems/debug_start.gd` — `apply()`
- `autoload/GameState.gd` — `reset()`, `new_game_state()`
- `autoload/GameData.gd` — the discovered variant list (from ticket 02)
- `scenes/components/combat_stage.gd` — how idle frames are loaded, for reuse in the preview
- `docs/ui-vision.md` — the title/menu visual family
- `docs/REFERENCE.md` §2 STATE SCHEMA (`player.model`), §5 DEBUG START
- `tests/` — a test for the new setter, and a title-flow test if one exists
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] New Game and Debug Start both open the picker before anything else happens.
- [ ] The arrows cycle through every discovered variant (wrapping around); the preview shows that variant's idle image.
- [ ] Select sets `player.model` to the shown variant via a system function; an invalid key is refused (tested).
- [ ] After New Game → Select, the intro event starts as before. After Debug Start → Select, the debug state is applied and `player.model` still holds the chosen variant (tested).
- [ ] Back/cancel returns to the title with no state change.
- [ ] No screen code writes to `GameState.state` directly.
- [ ] The syntax check is clean, all tests pass, CODEMAP is updated, and any new UI strings are flagged `PROSE-REVIEW:` in the report.

**Human on-device check:** New Game → the picker appears → arrows cycle through 3 idle previews → Select → the intro plays. In the first fight, your character matches your pick and no scrapper looks like you. Repeat via Debug Start.
