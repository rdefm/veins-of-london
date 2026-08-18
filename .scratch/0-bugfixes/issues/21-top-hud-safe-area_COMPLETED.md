# 21 — Top HUD hidden under notch/front camera

**What to build:** The top bar (money, time, bag button) is hidden under the phone's front camera/notch on some devices. `TopBar` (`scenes/components/top_bar.gd`, `BAR_HEIGHT = 40.0`) anchors flush to the top edge with no safe-area inset. The Map screen's own local top bar (`scenes/screens/map.gd`'s `_build_top_bar()`) has the same problem. Use the safe-area helper from ticket 20 to inset both from the top.

**Blocked by:** 20 — safe-area inset helper must exist first.

**Status:** ready-for-agent

- [ ] `TopBar` top offset accounts for the OS top safe-area/notch inset via the ticket 20 helper.
- [ ] Map screen's local top bar (`map.gd::_build_top_bar()`) gets the same top inset treatment.
- [ ] Verified headless (syntax check) and manually noted for the human to confirm on-device on a notched phone: money/time/bag fully visible, not obscured by camera cutout, on both the standard top bar and the Map screen's top bar.
