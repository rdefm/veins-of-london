# 02 — Top bar + notifications merge into a persistent dot-matrix board

**What to build:** `scenes/components/top_bar.gd` (day/time-blocks, cash,
bag button) and `scenes/components/notification_toast.gd` (currently a
cream/amber card per notification, styled via `_style_row()`/
`_CATEGORY_COLOURS`) merge into one electronic dot-matrix departure/
platform board per `docs/ui-vision.md` §5 — amber-on-black pixel
characters, the kind on a real train or Tube indicator board. Build the
rendering as a custom `_draw()`-based grid against a small hardcoded
bitmap-font table (covering just the character set the status line and
notification text actually use), the same "the engine can't render this
glyph, hand-draw it" precedent `scenes/components/ore_glyphs.gd` already
sets for the ore symbols — no font asset is sourced or bundled.

The status line renders as the board's larger top row; up to 2 unseen
notifications render as smaller numbered rows below ("1st ...", "2nd
..."), styled after a real multi-line Tube departure board. Stay **two
logical components** (mounted together, not merged into one file/class) so
notifications don't disappear if the status line ever needs to hide
independently on some future screen. When the board's text changes,
characters may briefly scramble through other glyphs before settling —
in scope. Steady-state per-dot flicker (constant strobing even when the
text is static) is optional and may be dropped if costly; the frame, font
and amber-on-black colour reading correctly as a real Tube board is the
priority.

The merged board becomes **unconditionally visible on every in-game
screen** except `title`/`intro` (no player state exists yet to show
there) — update `scenes/Main.gd`'s `TOP_BAR_HIDDEN_SCREENS` (currently
`["title", "intro", "map", "hq_floorplan", "hq_door", "hq_lab_bench",
"hq_dial"]`) to drop everything but `title`/`intro`. This is a deliberate
override of `hq-diorama-vision.md` §3.3's old "top bar auto-hides on
full-bleed sub-views" rule (already amended in that doc to match). The
nav dock's own hide-on-full-bleed behaviour is **unchanged** by this
ticket.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] A shared dot-matrix rendering component exists (custom `_draw()`, own bitmap-font table) and is used by both the status line and the notification rows
- [ ] Status line (day/time-blocks, cash, bag button) and up to 2 unseen notifications render as one visual board, amber-on-black
- [ ] Notification rows keep today's queue/fade/dismiss/combat-suppression behaviour (`Notify.dismiss(id)`, `MAX_VISIBLE`, `state.combat.active` suppression) — this ticket changes rendering, not notification logic
- [ ] Board text scrambles briefly through other glyphs when it changes (day/time tick, cash change, new notification); steady per-dot flicker may be skipped
- [ ] `Main.gd`'s `TOP_BAR_HIDDEN_SCREENS` reduced to `["title", "intro"]` — the board now shows on `map` and every HQ full-bleed sub-view
- [ ] Nav dock hide-on-full-bleed behaviour is unchanged
- [ ] `tests/test_notification_toast.gd` updated for the new rendering; new `tests/test_top_bar.gd` added (none exists today)
