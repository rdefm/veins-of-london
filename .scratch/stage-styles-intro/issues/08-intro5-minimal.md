# 08 — intro5: intro cards 1–6 staged in minimal style

**What to build:** `intro5` — identical to `intro2` (ticket 05) in event content, direction and ending, but every visual is in the minimal style: alley set, Vauxhall and the three buyers (James-based stander included) drawn at third resolution and tripled, flat 2-tone colour, no outline, dot eyes, with `archie_minimal` as Archie. The set is also authored at third resolution so pixel density matches the characters. Reuse ticket 05's generators via style configs rather than forking them; direction may differ only where proportions demand it (anchor offsets, walk distances).

**Blocked by:** 05 — intro2: intro cards 1–6 staged in chibi style.

**Relevant files:** everything listed in ticket 05, plus the set/car/buyer generator code and `data/stages/intro2.json` it produced; `tools/stage_art/char_kit.py` (`MINIMAL` style, `scale` 3, `outline: "none"`), `tools/stage_art/characters.py` (`JAMES`), `tools/stage_art/build_style_mockups.py`

**Status:** ready-for-agent

- [ ] `intro5` in the Debug app event picker; cards 1–6 staged in minimal style, 7+ show images, inert ending
- [ ] Set, car and characters all at the same tripled pixel density (no mixed pixel sizes)
- [ ] Characters stay readable against the dark night alley without an outline (adjust the set's backdrop tones if needed, not the style's outline)
- [ ] Stage data tests, full suite and check_all clean; fixture snapshot gets only the new entry; CODEMAP updated
- [ ] Screenshot harness frames per staged card; on-device check list in the report
