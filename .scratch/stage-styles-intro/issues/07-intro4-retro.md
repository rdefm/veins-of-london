# 07 — intro4: intro cards 1–6 staged in retro style

**What to build:** `intro4` — identical to `intro2` (ticket 05) in event content, direction and ending, but every visual is in the retro style: alley set, Vauxhall and the three buyers (James-based stander included) drawn at half resolution and doubled, 2 tones per material, hard black outline, with `archie_retro` as Archie. The set is also authored at half resolution so pixel density matches the characters. Reuse ticket 05's generators via style configs rather than forking them.

**Blocked by:** 05 — intro2: intro cards 1–6 staged in chibi style.

**Relevant files:** everything listed in ticket 05, plus the set/car/buyer generator code and `data/stages/intro2.json` it produced; `tools/stage_art/rig_archie_styles.py` (`RETRO` style, `scale` handling)

**Status:** ready-for-agent

- [ ] `intro4` in the Debug app event picker; cards 1–6 staged in retro style, 7+ show images, inert ending
- [ ] Set, car and characters all at the same doubled pixel density (no mixed pixel sizes)
- [ ] Stage data tests, full suite and check_all clean; fixture snapshot gets only the new entry; CODEMAP updated
- [ ] Screenshot harness frames per staged card; on-device check list in the report
