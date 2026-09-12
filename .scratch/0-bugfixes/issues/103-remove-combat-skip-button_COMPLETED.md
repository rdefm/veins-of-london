# 103 — Remove the combat Skip button

**What to build:** During combat animations, a "Skip" button/card flickers into the action deck and back out as each animated beat plays. Remove this button entirely — no replacement skip mechanic is wanted. If removing it leaves any skip-only wiring dead elsewhere (e.g. a director-level skip method used by nothing else), note it for a follow-up rather than expanding this ticket's scope to a broader cleanup.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [x] The Skip button/card never appears in the combat action deck, including during animated beats.
- [x] No visual flicker or layout jump in the action deck where Skip used to conditionally appear.
- [x] Any skip-only code left newly dead as a result is flagged in the ticket's comments (not necessarily removed, unless trivial).
- [x] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file.
- [x] Manual check noted for the human: play through a combat encounter with animations, confirm no Skip button ever appears.

## Done

Removed the `_director.is_playing()` conditional in `_build_action_deck()` (scenes/screens/combat.gd) that added the "⏭ Skip" card, plus the two comments describing its literal-glyph exception. Also cleaned the stale doc comments referencing the removed card.

**Newly dead code (left in place per ticket scope, not removed):** `CombatDirector.skip_to_end()` in `scenes/components/combat_director.gd:95` had no other caller and is now unreachable. Left alone since it also mutates `_skip_requested` — not a trivial no-op deletion. `fast_forward_current_beat()` and `is_playing()` on the same class remain in use elsewhere (tap-to-fast-forward, combat screen redraw gating) and are unaffected.

**Manual check for the human:** play a combat encounter through to a round with animated beats and confirm no Skip card ever appears in the action deck, at any pacing setting.

Full test suite: 2275 passed, 8 failed — all 8 failures pre-exist on `hq-diorama` before this change (unrelated: archie debt-event prose, KO pose, and debug-screen relation-control counts), confirmed by re-running the suite against the unmodified tree.
