# 120 — App icon rounded-rect masking

**What to build:** `AppTile` (`scenes/components/app_tile.gd`) currently suppresses its rounded `_background` panel whenever real icon art exists (`configure()`'s `_background.visible = active or not has_real_art`), on the assumption real art bakes in its own rounded corners. It doesn't — the four real-art tiles (`notes`, `bank`/Reynard's, `property`/Harrow's, `saveload`) are plain square PNGs, so their tiles render as square photos, not rounded app icons (see screenshot-phone.PNG). Make `AppTile` itself clip/mask the icon texture to a rounded-rect matching the frame, independent of whether the source art is square or pre-rounded — so any future icon art (baked-rounded or not) always renders correctly. Also bump `FRAME_CORNER_RADIUS` rounder so tiles read clearly as iOS/Android-style app icons rather than barely-rounded squares (human call on exact value — try ~22% of frame size, i.e. ~12px @ 56px dock frame / ~17px @ 76px large frame, and adjust to taste).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Icon texture (`_icon_rect`) is visually clipped/masked to the same rounded-rect shape as `_background`'s corner radius, for both dock (`FRAME_SIZE`) and large/home-grid (`LARGE_FRAME_SIZE`) tiles — square source art no longer shows square corners.
- [ ] `FRAME_CORNER_RADIUS` increased to read as a proper rounded-rect app icon (not a cosmetic no-op) — pick and record the actual value used.
- [ ] Masking approach doesn't regress the label-fallback chip (`_fallback_label` + `_background` path) — that path already uses the rounded `StyleBoxFlat` background and should look identical, just rounder.
- [ ] Locked-tile padlock overlay and badge dot still read clearly against the new radius/mask.
- [ ] `tests/test_app_tile.gd` covers: real-art tile with a texture larger than the frame renders without square corners overhanging the rounded shape (whatever assertion is feasible headless — e.g. verify a clip/mask node or material is applied — since pixel-level corner inspection isn't available in a headless test).
- [ ] Verify no regression in `tests/test_nav_bar.gd` / `tests/test_phone_home_grid.gd` (both consume `AppTile`).

**Human should check on-device:** Notes/Reynard's/Harrow's/Save-Load tiles on the phone home grid now look like real rounded app icons (no square corners bleeding past the rounded frame), and the rounder radius reads as intentional, not just "slightly less square."

---
Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
