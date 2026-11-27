# 01 — HQ header "?" shows its glyph

**What to build:** The zone-labels help chip in the HQ header renders as a blank button on device. It must visibly show "?" (and "? ✓" when zone labels are on).

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/hq.gd` (help chip, ~l.79), `MapCardStyle.chip_button` (glyph/font/size handling).

**Status:** ready-for-agent

- [ ] HQ header chip shows "?" when labels off, "? ✓" when on
- [ ] Root cause found (font glyph, label clipping, or colour) and fixed at source, not by swapping the character
- [ ] Other `chip_button` users unaffected
