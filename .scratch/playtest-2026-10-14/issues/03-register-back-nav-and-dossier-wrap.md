# 03 — Register (factions app): working back navigation and dossier text wrap

**What to build:** In the Register phone app, the player can't get back after opening a faction dossier, Shares or Politics page (no usable back button), and some pages (Dossier after tapping a faction) render text one character per line, wasting space. Give every sub-page a visible bespoke in-app back control returning to the previous Register level (dossier → directory → home), and fix label width/wrap so dossier and other sub-page text uses full width. Audit all Register sub-pages (dossier, shares, politics, route rows) for the same two faults. Existing `_back_link` exists in code but isn't working on-device: diagnose why (hidden, scrolled off, colour, zero-width container) before adding another.

**Blocked by:** None — can start immediately

**Relevant files:** `scenes/phone_apps/factions_app.gd` (`_back_link`, `_build_dossier`, `_build_directory`, `_wrap`, `_text`, `_route_row`, `_select`), `scenes/phone_apps/phone_app.gd` (shared back/refresh), `systems/phone_nav.gd`, `docs/ui-vision.md`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Every Register sub-page has a visible, tappable back control; back from directory returns home
- [ ] Dossier and all sub-page text wraps at full content width (no 1-char columns), at phone width
- [ ] Headless check of nav state transitions where feasible; check_all clean
- [ ] Human check on-device: open each faction dossier, Shares, Politics; go back each time; read the text
