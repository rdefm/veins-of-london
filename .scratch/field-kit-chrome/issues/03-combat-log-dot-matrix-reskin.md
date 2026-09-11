# 03 — Combat log reskinned onto the dot-matrix board

**What to build:** `scenes/screens/combat.gd`'s departure-board log splits
into two different destinations, per `docs/ui-vision.md` §5 (amended
2026-09-11):

- **Mid-fight ticker** (the "ticker" directly under the stage, per
  combat-presentation ticket 21): stops being its own component. Its
  lines route into the shared top dot-matrix board (ticket 02's merged
  status/notification board — `scenes/components/notification_toast.gd`)
  as notification rows, live, while combat is in progress.
  - This requires narrowing the board's combat-suppression rule
    (`notification_toast.gd`, `if GameState.state["combat"]["active"]:`
    at line 65): entries sourced from the combat log bypass suppression
    and render immediately; notifications from every other source keep
    today's behaviour — queue while `state.combat.active` is true, drain
    once combat ends.
  - The board only shows up to 2 unseen rows at a time (ticket 02's
    `MAX_VISIBLE`) — combat log lines compete for those same rows
    alongside any other live (non-suppressed) entry. No separate
    reserved slot for combat.
- **Post-combat outcome log** (the full recap shown once the fight
  resolves, alongside the outcome button, `_build_log(combat)` at up to 6
  lines): unchanged in destination — stays in the combat screen's own
  footer, not routed to the top board. It re-skins onto the shared
  dot-matrix rendering component ticket 02 builds (reusing the renderer,
  not a second implementation), same as originally scoped — only the
  mid-fight half of this ticket's original plan changed.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Mid-fight combat log lines (`_build_log`'s source data, previously rendered via `_build_command_deck()`'s `MID_FIGHT_LOG_LINES` sub-view) post to the top board's notification queue instead of rendering under the stage
- [ ] `notification_toast.gd`'s combat-suppression check is narrowed so combat-log-sourced entries render live during `state.combat.active`; all other notification sources still queue/drain unchanged
- [ ] Combat log entries respect the board's existing `MAX_VISIBLE` / numbered-row format — no bespoke combat-only row reserved
- [ ] Post-combat outcome log (`_sync_footer()`'s outcome branch, 6 lines) renders via the shared dot-matrix component from ticket 02, staying in the combat screen's own footer — this part is a rendering swap only, content/line-count/scroll behaviour unchanged
- [ ] `tests/test_combat_screen.gd` updated for both changes
- [ ] `tests/test_notification_toast.gd` updated for the narrowed suppression rule

## Comments

**2026-09-11:** Original scope (both mid-fight ticker and post-combat log
reskin onto the dot-matrix component as one *separate* under-stage
component) revised — the human asked for combat notifications to surface
in the top notification bar instead. See `docs/ui-vision.md` §5's
2026-09-11 amendment for the design rationale and the note left on ticket
02 below.
