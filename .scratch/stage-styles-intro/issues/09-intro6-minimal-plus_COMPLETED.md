# 09 — intro6: intro cards 1–6 staged in minimal_plus style

**What to build:** `intro6` — identical to `intro2` (ticket 05) in event content, direction and ending, but every visual is in the minimal_plus style: alley set, Vauxhall and the three buyers (James-based stander included) drawn at half resolution and doubled, 3-tone ramps, soft sel-out outline (each material's own darkest tone), slim build, 1x2 eyes, with `archie_minimal_plus` as Archie. The set is also authored at half resolution so pixel density matches the characters. Reuse ticket 05's generators via style configs rather than forking them; direction may differ only where proportions demand it (anchor offsets, walk distances).

**Blocked by:** 05 — intro2: intro cards 1–6 staged in chibi style.

**Relevant files:** everything listed in ticket 05, plus the set/car/buyer generator code and `data/stages/intro2.json` it produced; `tools/stage_art/char_kit.py` (`MINIMAL_PLUS` style, `StyleCanvas._render_selout`), `tools/stage_art/characters.py` (`JAMES`), `tools/stage_art/build_style_mockups.py`

**Status:** ready-for-agent

- [ ] `intro6` in the Debug app event picker; cards 1–6 staged in minimal_plus style, 7+ show images, inert ending
- [ ] Set, car and characters all at the same doubled pixel density and share the sel-out outline treatment (no style mixing)
- [ ] Stage data tests, full suite and check_all clean; fixture snapshot gets only the new entry; CODEMAP updated
- [ ] Screenshot harness frames per staged card; on-device check list in the report
