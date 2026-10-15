# 01 — Prefactor: decouple combat UI components from live Combat

**What to build:** Make the live combat UI pieces (pixel stage, command dock, turn-order strip) drivable by a caller other than live combat, so the Combat Prototype can reuse them. Pure prefactor: live combat must look and behave exactly as before.

- Stage: any fallback effect target (e.g. Time Pearl's default) is supplied by the caller or the beat, not read from live combat state. Target taps keep emitting `subject_tapped`; nothing in the stage calls the live combat system to change selection.
- Command dock: besides today's live deck (Dial, Attack, loadout rows, Leg it), it can be configured with a generic list of rows, each with an icon kind, label, disabled flag/reason and callback, plus an optional footer row (e.g. Rewind). The Dial is optional in generic mode.
- Turn-order strip: it renders whatever entries it's handed. Building entries from live combat's projected queue stays available to the live screen but sits outside the rendering path, so a caller can supply its own entries (with its own intent text/image, status lines and HP).

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/combat_stage.gd` (`_default_effect_target`, `sync`, `_enemy_display_entries`), `scenes/components/combat_command_dock.gd` (`configure`, `_build_action_deck`, `_build_item_row`), `scenes/components/turn_order_strip.gd` (`build_entries`, `build_entries_for`, `configure`, `_telegraph_text_for`), `scenes/screens/combat.gd`, `tests/test_combat*.gd`, `CODEMAP.md`. REFERENCE.md §3.7a (live queue — unchanged).

**Status:** ready-for-agent

- [ ] Live combat screen behaviour unchanged; all existing combat tests pass.
- [ ] The stage never reads `GameState.state["combat"]` itself.
- [ ] The dock has a generic-rows mode, covered by a test that configures it without live combat state.
- [ ] The strip can be configured from caller-built entries, covered by a test without live combat state.
- [ ] CODEMAP rows updated for the three components.
