# 05 — HQ Dial loadout screen: fix seat-movement overlap

**What to build:** `scenes/screens/hq_dial.gd` — confirmed by screenshot:
once a Movement is seated, the loadout card (level/charge/capacity +
seated-Movement summary, `_build_top_block()`) grows tall enough to
visually overlap the dial art and the flanking Complication-housing tiles
sitting below/around it (e.g. the "Time Pearl..." housing label is cut off
behind the loadout card in the reported screenshot). Human direction: do
not shrink the dial image — refine the menu/card layout (e.g. scroll,
reflow, or reserve fixed space) so the loadout card and the housing tiles
never overlap the dial regardless of seated-Movement content length.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] With a Movement seated, the loadout card never visually overlaps the dial art or any Complication-housing tile
- [ ] Dial image stays at its current full size — no shrinking to make room
- [ ] Empty/inert state (no Movement seated) unaffected
- [ ] Verified via screenshot with a seated Movement present
