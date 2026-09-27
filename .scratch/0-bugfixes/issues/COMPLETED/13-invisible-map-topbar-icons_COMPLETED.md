# 13 — Hamburger and bag icons on the Map tab are invisible

**What to build:** On-device, the hamburger (`☰`) and bag (`🎒`) buttons in the Map tab's top bar (`scenes/screens/map.gd`) render as nothing visible — but they're still tappable. Root cause: non-ASCII/emoji glyphs don't render in the exported build's font (already confirmed elsewhere in the codebase — `scenes/components/icons.gd`'s own comment notes plain ASCII like `?` renders fine, unicode doesn't; that's why the vector-drawn `Icons` class exists at all). These two buttons are icon-only with no fallback text, so there's nothing to reveal a button is even there.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] The bag button uses the already-existing `Icons.draw_bag()` vector icon instead of the `🎒` emoji.
- [ ] The hamburger button uses a new 9th vector icon (three horizontal bars, same drawing style/scale conventions as the existing 8 `Icons` glyphs) instead of the `☰` glyph.
- [ ] `docs/M1.5-NETWORK-MAP.md`'s icon roster is updated to note the addition and why (non-ASCII glyphs don't render on-device — this is a deliberate, approved exception to the roster's original "exactly 8, nothing added" note, not scope creep).
- [ ] Both icons are visibly present and legible on-device at default and max map zoom.
- [ ] No other on-screen glyph in the app is left using a non-ASCII/emoji character without a fallback text label — spot-check the rest of the app (e.g. `combat.gd`'s `"🎒 Item"`, `top_bar.gd`'s `"🎒 Bag"`) and confirm those are fine because they already pair the glyph with visible text, so no further changes are needed there.
