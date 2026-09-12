# 105 — Event screen action buttons need visible chrome at rest

**What to build:** The buttons at the bottom of the event screen (Rewind, choice options, Continue) currently have no visible fill or border at rest — only coloured text — so they read as plain text rather than tappable buttons. Give these buttons a visible fill/border at rest on the event screen specifically. Other screens using this same flat-at-rest button style (e.g. the Train buttons in modals) are intentionally out of scope and must not change.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Rewind, choice, and Continue buttons on the event screen have a visible fill/border at rest, not just on hover/press.
- [ ] The same flat-at-rest button style used elsewhere in the app (e.g. modal Train buttons) is unchanged.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file.
- [ ] Manual check noted for the human: open an event with choices, confirm all bottom buttons look like buttons at rest (not just plain coloured text).
