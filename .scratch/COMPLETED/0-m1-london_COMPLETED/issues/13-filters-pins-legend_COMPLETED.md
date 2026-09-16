# 13 — Filters, pins, legend modal

**What to build:** the 5 filter chip modes (Ownership/Type/Strength/Charge/Security, per N4 — re-style only, never hide stops or change tap behaviour), the map pins (home, contact, Soho market padlocked-until-M4, "you are here"), and the legend modal (N5's "Network Reference").

**Blocked by:** 12.

**Status:** ready-for-agent

- [ ] All 5 filter modes implemented exactly per N4's re-styling rules; filter is UI-local state, not saved
- [ ] Pins render and tap correctly: home → HQ, contact pin → starts its event, Soho market pin padlocked, player-position ring on `currentDistrict`
- [ ] Legend modal ("Network Reference") lists the glyph grammar with one dry flavour line, drafted per tone bible, flagged `PROSE-REVIEW`
- [ ] Human visual QA: cycle all 5 filters on a save with varied vein levels/charge/security states; confirm no stops disappear and tap targets still work in every mode
- [ ] `godot --headless --check-only --script` clean on all touched files
