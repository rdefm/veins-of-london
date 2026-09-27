# 114 — Apply symbol-glyph fallback across remaining menu screens

**What to build:** Wire ticket 113's fallback helper into every remaining call
site still rendering `ore["symbol"]`/`recipe["symbol"]` (or other tofu-prone
glyphs) as plain text: `scenes/components/bag_drawer.gd`, `scenes/components/
modal_layer.gd`, `scenes/screens/phone.gd`, `scenes/components/contact_cards.gd`,
`scenes/screens/hq.gd`, `scenes/screens/map.gd`, `scenes/screens/
guild_marketplace.gd`, `scenes/screens/vein_list.gd`, `scenes/screens/lab.gd`,
`systems/jobs.gd` — the same sweep `MapCanvas` already got. Sweep every listed
call site in this one ticket (blast radius is ~10 files, not large enough to
need its own batching).

**Blocked by:** 113.

**Status:** ready-for-agent

- [ ] Every listed call site renders ore/recipe symbols via the fallback
      helper instead of raw text.
- [ ] Verified (via an `OreGlyphs.font_covers_all_symbols()`-style check or
      on-device) that no symbol renders as a blank tofu box on Android across
      these screens.
- [ ] No visual regression on desktop/editor, where the bundled font may or
      may not already cover these glyphs (fallback should be a no-op there
      if the font already covers them).
- [ ] Existing tests for each touched screen still pass; no test asserts on
      the old raw-text rendering in a way that silently masks the switch.
