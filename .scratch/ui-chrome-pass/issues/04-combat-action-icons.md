# 04 — Combat action icons

**What to build:** `combat.gd::_build_action_deck()` labels its three
cards with raw emoji characters (⚔ Attack, 🎒 Item, 🏃 Leg it). Confirmed
by screenshot: Attack's ⚔ (a Miscellaneous-Symbols-block character) renders
fine, but Item's 🎒 does not render at all (blank) — Godot's default font
setup very likely lacks the color-emoji glyphs needed for 🎒/🏃 (Supplementary
Multilingual Plane emoji). Replace all three with hand-drawn icons using
the existing `scenes/components/icons.gd` pattern (already used for
bag/phone/pin/etc.) rather than relying on emoji rendering.

Do this against the final card layout landed by ticket 03, not the current
one, to avoid re-placing icons twice.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] `icons.gd` gains drawn glyphs for Attack (crossed blades), Item (bag/pack), and Leg it (running figure or equivalent)
- [ ] `_build_action_card()` uses these instead of the raw emoji strings
- [ ] Icons render correctly (verified via screenshot or on-device) at the card size landed by ticket 03
- [ ] Skip icon disabled/dimmed state (existing `disabled` styling) still applies correctly with the new icons
