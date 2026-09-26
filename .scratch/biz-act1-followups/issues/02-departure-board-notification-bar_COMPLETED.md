# 02 — Top notification bar as a Tube/rail departure board

**What to build:** The top bar's dot-matrix notice area looks and behaves like a real London Tube/rail departure board.

- **Look:** a physical sign housing around the amber dot-matrix face (dark casing, metal frame, bolts/bezel feel). Build what code can do well (casing, bezel, inner shadow). Where code isn't practical or good enough (e.g. a proper frame bitmap), define an image slot with a code-drawn fallback and list it as an ART-REQUEST. Don't try to produce every asset.
- **One notification at a time:** new notifications queue. Each new message rolls up from below into the display line. A message too long to fit marquee-scrolls horizontally until the whole message has been shown. Each message holds 4s once fully shown, then the next queued one rolls up. When the queue is empty the latest notification stays on the board.
- **Tap:** opens the Phone's Notifications app (full log). During combat, tapping does nothing.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/top_bar.gd`, `scenes/components/dot_matrix_board.gd`, `scenes/components/dot_matrix_font.gd`, `systems/notify.gd`, `scenes/phone_apps/notifications_app.gd`, `scenes/screens/phone.gd` (app routing), `tests/test_dot_matrix_board.gd`, `docs/ui-vision.md`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] The board shows exactly one notification at a time. The display queue is presentation-only and never stored in `GameState.state`.
- [ ] Roll-up from below on each new message. Marquee scroll for overflow text so the whole message is shown. 4s hold. Then the next message.
- [ ] The latest notification stays displayed when nothing is queued.
- [ ] Tap opens the Notifications app. Tap is ignored while combat is active.
- [ ] Frame/casing is drawn in code, with an optional image slot and fallback. Required assets are listed as ART-REQUEST with sizes.
- [ ] Animation uses `create_tween()` / `_process`, with no G3 patterns. Headless tests cover queue order, hold timing, the latest-stays rule and the combat tap guard.
- [ ] On-device QA block in the report: look, roll-up, marquee, tap routing, combat no-op.
