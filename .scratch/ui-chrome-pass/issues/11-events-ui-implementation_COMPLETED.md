# 11 — Implement new Events UI chrome

**What to build:** Re-skin `scenes/screens/event.gd` per the design spec
from ticket 10 (`docs/ui-vision.md` §11) — remove the hardcoded
`AMBER_COLOR`/`AMBER_BG`/`DANGER_COLOR` constants, wire tension's border to
the shared `MapStyle.DANGER_COLOUR`, wire craft's panel to the named
`calc_gold`/`calc_gold_light` palette entries, and recolour the action bar
(Continue/Rewind/choice buttons) to `ui_action_red`. Scroll behaviour
(bottom-anchored `ScrollContainer`, entries accumulate upward) is
unchanged.

**Scope grew during the §11 design session — two things beyond a pure
re-skin are folded into this ticket, per that session's own scope
decision (not split into a follow-up):**

1. **Persistent event image slot.** Add an optional `image` key to the
   card schema (any revealed entry, including a choice's synthetic
   resolution entry, may set an asset path or explicit `null` to clear).
   `event.gd` gains a fixed, non-scrolling image region between the top
   status board and the scrollable entry stack — fixed-height thumbnail
   (§11: indicative 160–180px, full content width, inset within the same
   16px margins as the entry cards, thin ink border), collapsing to zero
   height when no revealed entry has set an image. Computed by scanning
   `Events.revealed_cards()` for the last entry (up to the current
   position) that specifies `image` — no new field on `state.event`
   itself. Update `systems/events.gd`'s top-of-file schema comment to
   document the new `image` key.
2. **Bug fix:** `_build_card()`'s `match card["type"]` currently only
   renders the `speaker` field for `type:"speaker"` cards — a
   `type:"choice"` card's optional `speaker` field is silently dropped.
   Fix so choice cards with a `speaker` field render the name too.

**Blocked by:** 10

**Status:** ready-for-agent

- [ ] All six event card types (narration/speaker/tension/resolution/craft/choice) render per §11's table; no hardcoded amber/danger constants remain in `event.gd`
- [ ] Choice cards with a `speaker` field render the speaker name (bug fix above)
- [ ] Persistent image slot implemented: `image` key on any revealed entry, sticky until the next entry that specifies one, `null` clears it, zero-height when unset, Rewind-safe (derived from `cardIndex`, not new state)
- [ ] Scroll-to-bottom-on-new-card behaviour and action bar (Continue/Rewind/choice buttons, safe-area inset handling) unchanged
- [ ] Verified against at least one narration card, one choice card, one craft/resolution card, and one entry with an `image` set, on-device or via screenshot
- [ ] `tests/test_event_screen.gd` updated for the new styling and the image-slot behaviour
