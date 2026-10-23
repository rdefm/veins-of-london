# 11 — Vein card stays below the top bar

**What to build:** Tapping a vein near the top of the map (e.g. Hampstead) opens the vein card fully visible: its title row ("Hampstead · Life Orichalchum ›") is tappable and the full vein panel can be opened. The card's placement treats the top bar's bottom edge as the top limit — it flips below the pin or clamps so no part sits under the bar. Diagnosis: ticket 10 `## Comments` §1.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/vein_bubble.gd` (`_apply_position`), `systems/bubble_layout.gd` (`popup_position`, `EDGE_MARGIN`), `scenes/screens/map.gd` (`_on_station_tapped`, other bubble callers), `scenes/components/top_bar.gd`, `scenes/main.gd`; `.scratch/playtest-prologue-hq-2/vein-card-off-top.png`; tests: `tests/test_bubble_layout.gd` (or nearest existing).

**Status:** ready-for-agent

- [ ] `BubbleLayout` takes a top inset; with an anchor near the top, the panel's y ≥ inset + margin, or the card flips below the pin
- [ ] Unit test covers a tall card near the top with a non-zero inset
- [ ] Other `BubbleLayout` callers (station/district bubble) checked and given the same inset where affected
- [ ] On-device: Hampstead vein card fully visible, title row tappable
