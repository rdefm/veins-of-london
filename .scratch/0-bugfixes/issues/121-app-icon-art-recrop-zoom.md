# 121 — Re-crop/zoom app icon art to actual logo content

**What to build:** The four real-art icons at `assets/icons/apps/` (`notes.png`, `bank.png`, `property.png`, `saveload.png`) are large, full-bleed images (100KB–1.4MB) with the actual logo/glyph sitting inside a padded frame rather than filling it — they read as "a rectangular picture" instead of an app icon (see screenshot-phone.PNG: the clipboard/floppy-disk/crest art all sit small-and-centred inside a lot of dead space). Auto-crop each source image to the bounding box of its actual visible content (trim uniform background/whitespace margin), then re-scale to fill the 128×128 asset-contract canvas (`docs/adr/0003-app-icon-asset-contract.md`) edge-to-edge, preserving aspect ratio. Overwrite the files in place at the same contract paths — no id/path changes.

**Blocked by:** None — can start immediately (independent of 120), but land after 120 so the final rounded-mask shape is what you're judging the crop against, not raw squares.

**Status:** ready-for-agent

- [ ] Each of `notes.png`, `bank.png`, `property.png`, `saveload.png` re-cropped so its visible logo content fills the 128×128 canvas edge-to-edge (minimal/no uniform-background margin left), aspect ratio preserved, alpha channel intact.
- [ ] Format/size stays within the ADR 0003 contract: PNG with alpha, square, 128×128px source.
- [ ] Files overwritten at their existing contract paths (`res://assets/icons/apps/<app_id>.png`) — no renames, no new ids.
- [ ] Godot import settings (`.import` files) untouched/still valid after overwrite (Filter on, Mipmaps off per ADR 0003).
- [ ] Visual sanity check recorded in the ticket (before/after crop dimensions or a note on what margin was trimmed per file) since this is asset content, not something a headless test can assert.

**Human should check on-device:** the four real-art phone tiles (Notes, Reynard's, Harrow's, Save/Load) now show their logo/glyph filling the icon frame, not floating in a padded square.

---
Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
