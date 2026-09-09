# 17 — HQ dial view: tap-to-load complication slots

**What to build:** The bottom tray/"Craft Components" dock is removed from
the Dial screen. The slot boxes overlaid on the umbrella (now exactly
`dial.capacityMax` of them, up to the new 4-max from ticket 14 — no separate
UI-only display cap) are the only way to manage loaded complications: each
shows "Empty" or the loaded recipe; tapping a filled box unloads it (existing
behaviour, unchanged); tapping an "Empty" box opens a new modal listing every
loadable crafted complication in stock, picking one loads it into that slot.
Slot boxes are repositioned toward the 2/4/8/10 o'clock corners of the clock
face (best-effort against the current art — ticket 19's art rework, if it
lands, may want a follow-up position tweak, out of scope here).

**Blocked by:** 14 (real slot count/flat cost the boxes and load gate now read)

**Status:** ready-for-agent

- [ ] Bottom tray + "Craft Components" dock removed from this screen
- [ ] Exactly `dial.capacityMax` slot boxes render (no separate 4-housing display cap, no "+N more loaded, not shown" overflow case)
- [ ] Tapping a filled slot unloads it (unchanged)
- [ ] Tapping an "Empty" slot opens a modal listing loadable complications; picking one loads it into that slot via `Dial.load_complication`
- [ ] Slot boxes repositioned near 2/4/8/10 o'clock around the clock face
- [ ] "Craft Components" (for crafting new complications, distinct from Movements) remains reachable from somewhere on this screen
- [ ] `tests/test_hq_dial.gd` updated for the new tap-to-modal flow
