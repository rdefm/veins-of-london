# 06 — intro3: intro cards 1–6 staged in adventure style

**What to build:** `intro3` — identical to `intro2` (ticket 05) in event content, direction and ending, but every visual is in the adventure style: alley set, Vauxhall and the three buyers (James-based stander included) rendered lanky with hue-shifted 4-tone ramps, coloured sel-out outline and no dither, with `archie_adventure` as Archie. Reuse ticket 05's set/car/buyer generators via style configs rather than forking them; direction may differ only where proportions demand it (anchor offsets, walk distances).

**Blocked by:** 05 — intro2: intro cards 1–6 staged in chibi style.

**Relevant files:** everything listed in ticket 05, plus the set/car/buyer generator code and `data/stages/intro2.json` it produced; `tools/stage_art/char_kit.py` (`ADVENTURE` style) + `tools/stage_art/characters.py`

**Status:** ready-for-agent

- [ ] `intro3` in the Debug app event picker; cards 1–6 staged in adventure style, 7+ show images, inert ending
- [ ] No style mixing: set, car and all characters share the adventure rendering
- [ ] Stage data tests, full suite and check_all clean; fixture snapshot gets only the new entry; CODEMAP updated
- [ ] Screenshot harness frames per staged card; on-device check list in the report
