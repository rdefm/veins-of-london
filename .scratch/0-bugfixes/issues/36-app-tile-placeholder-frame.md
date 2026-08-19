# 36 — App tile placeholder frame (rounded square/circle + glyph)

**What to build:** `AppTile` (`scenes/components/app_tile.gd`) currently renders an icon *or* falls back to a bare text label with no visible container around it — no art exists yet at `res://assets/icons/apps/*.png` (confirmed empty, per the ticket-02 asset contract in `docs/adr/0003-app-icon-asset-contract.md`), so every tile in the phone's home-grid (`PhoneApps.apps()`, 7 entries) currently renders as floating text, not something that reads as a "phone app icon." Give `AppTile`'s `_frame` a permanent, always-visible background — a rounded square or circle (human's call on exact shape) drawn behind the icon/fallback-label layer, present whether or not real icon art has landed. This is the placeholder Richard's real icon art will eventually sit on top of, not a replacement for it — `load_icon()`'s existing fallback behaviour (text label when no PNG exists) is unchanged, it just now has a background to sit inside.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `_frame` always draws a background shape (rounded square or circle — human's call if unspecified) behind the icon/fallback-label, in both the locked and unlocked tint.
- [ ] Background renders identically whether or not real icon art exists at the asset-contract path — this is not conditional on `load_icon()` returning null.
- [ ] Locked tiles' existing padlock overlay (`Icons.draw_padlock`) still reads clearly on top of the new background.
- [ ] Badge dot (`_BadgeDot`) still reads clearly against the new background — reposition if the shape change makes its current corner position overlap awkwardly.
- [ ] No emoji, no `Icons.draw_*` used for the background shape itself (that's still reserved for map/legend glyphs plus the existing padlock exception) — a plain `_draw()`-based rounded rect or circle, or a `StyleBoxFlat`, either is fine.
- [ ] `tests/test_app_tile.gd` covers: background renders in normal state, locked state, with and without a real icon texture present.
- [ ] Since `AppTile` is shared by both the phone home-grid (`PhoneApps.apps()`) and the dock (`NavBar`, ticket 37), verify this doesn't break `tests/test_nav_bar.gd` or `tests/test_phone_home_grid.gd`.

**Human should check on-device:** the home-grid app icons now read as a grid of app tiles (background shape behind every letter/label), not a list of plain text buttons.
