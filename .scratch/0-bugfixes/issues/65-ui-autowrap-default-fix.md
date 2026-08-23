# 65 — UI: fix vertical-text-per-letter bug at the root

**What to build:** Labels and buttons squeezed into a narrow container currently collapse to one character per line (seen recurring in the Lab's "Batch:" label and the Crafting/Experimenting section-tab buttons, after already being patched once in the Lab's quantity numeral via a one-off `autowrap_mode = OFF` override). Fix the shared UI helper's default autowrap behaviour so this class of bug can't recur anywhere it's used, then remove the now-redundant one-off overrides.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Shared label/button UI helper no longer defaults to word-smart autowrap in a way that collapses to one-character-per-line when squeezed narrow.
- [ ] The Lab's "Batch:" label no longer wraps vertically.
- [ ] The Crafting and Experimenting section-tab buttons no longer wrap vertically.
- [ ] Existing one-off `autowrap_mode = OFF` override(s) added to work around this bug are removed now that the shared default handles it.
- [ ] Regression sweep: check other screens using the same label/button helper (marketplace, HQ, phone apps) for any similarly narrow containers that were silently relying on the old default.
- [ ] Manual check noted for the human: open Lab (Crafting and Experimenting sections) and confirm all text renders horizontally, no single-character-per-line buttons/labels anywhere in the app.
