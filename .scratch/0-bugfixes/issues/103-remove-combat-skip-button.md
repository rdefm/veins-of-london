# 103 — Remove the combat Skip button

**What to build:** During combat animations, a "Skip" button/card flickers into the action deck and back out as each animated beat plays. Remove this button entirely — no replacement skip mechanic is wanted. If removing it leaves any skip-only wiring dead elsewhere (e.g. a director-level skip method used by nothing else), note it for a follow-up rather than expanding this ticket's scope to a broader cleanup.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] The Skip button/card never appears in the combat action deck, including during animated beats.
- [ ] No visual flicker or layout jump in the action deck where Skip used to conditionally appear.
- [ ] Any skip-only code left newly dead as a result is flagged in the ticket's comments (not necessarily removed, unless trivial).
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file.
- [ ] Manual check noted for the human: play through a combat encounter with animations, confirm no Skip button ever appears.
