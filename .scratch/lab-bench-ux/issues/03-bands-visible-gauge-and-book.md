# 03 — Bands visible: on the live gauge, and clearer in the book

**What to build:** Two band-visibility problems in a manual Lab run:
1. The apparatus gauge popup never receives the step's band, so it draws an empty track even when the player knows the range. It must draw the step's known band exactly as the book shows it: exact band solid, vague band faded, a Prophet's Breath-revealed band as the true band; an unknown step shows no band.
2. The book's band tracks draw the band in a colour that barely reads on the dark card. Restyle the band (book and gauge share the drawing) so it clearly contrasts with the track and the card, in both light and dark palettes.

The band shown on the gauge is the one for the step the player is about to perform with that apparatus (the next matching known step); if none is known, no band.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/components/lab_gauges.gd` — `StepGauge._draw_track`, `band_low/band_high/band_vague`
- `scenes/screens/hq_lab_bench.gd` — `_build_gauge_card` (sets no band today), `_add_known_step` (book band)
- `systems/lab.gd` — `step_region`, `known_procedure`, `active_run`
- `scenes/components/map_card_style.gd`, `data/map_palette.json` — colour tokens if a new one is needed (no colours in code)
- `tests/test_hq_lab_bench.gd`

**Status:** ready-for-agent

- [ ] Gauge popup shows exact band solid for a known exact step
- [ ] Gauge shows faded band for a vague step; true band under Breath
- [ ] Gauge shows no band when the step isn't known
- [ ] Book and gauge band colour clearly visible on the dark card (and light mode)
- [ ] Tests assert the gauge's band values match `step_region` for the pending step
- [ ] On-device check listed in report
