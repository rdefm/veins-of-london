# 05 — intro2: intro cards 1–6 staged in chibi style

**What to build:** A playable `intro2` event, fired from the Debug app's event picker, that is the intro with cards 1–6 performed live in the chibi style and cards 7+ showing their existing card images. It has an inert ending (no flags, tutorial stage or relation changes — just back to the phone, like `archie_craft_chat2`), and a card-1 label marking it as a style mock-up. Content, all chibi, side-on view:
- **Set:** night alley behind a chicken shop on Mile End Road — brick walls, back doors, bins, a lamp, wet ground, lit windows; generated like Spitalfields (layers, ambient life, lights) and matching the chibi rendering (flat 3-tone, dark outline).
- **Car:** grey Vauxhall hatchback, side-on, as a set object that drives in with headlights on and stops; its doors let the buyers appear.
- **Buyers (3 rigs):** the knife one (nearest; produces a Stanley knife), the mate (walks towards Archie and the bag), and the one who just stands there — based on James (`assets/character-references/James/James_reference.png`: older, wild thinning grey hair, glasses, navy waistcoat over pale blue shirt, grey trousers, brown shoes, a stern stillness). Not story-accurate; it's a style test.
- **Direction, cards 1–6:** Archie waiting with the bag, whistling (mouth); car arrives, three get out, Archie stops whistling; knife drawn, mate walks over, James stands; Archie's bag-wave while the other hand goes to his back pocket; the flick, vial arc, shatter, slow field, buyers slow, Archie walks briskly to the exit; "Coming, or what?" over his shoulder. Talk beats sized to each card's quoted text.

**Blocked by:** 01 — Partial stage coverage; 03 — Time-slow effect; 04 — Character kit + Archie's new poses.

**Relevant files:** `data/events/intro.json` (source cards; copy text verbatim), `data/events/archie_craft_chat2.json` (inert-copy precedent), `data/stages/archie_craft_chat2.json`, `tools/stage_art/set_spitalfields.py` + `tools/stage_art/build_stage_assets.py` (set generator pattern, required manifest keys), `tools/stage_art/char_kit.py` + `tools/stage_art/characters.py` (character kit from 04; `JAMES` config already drafted), `assets/events/intro/1.jpg`, `assets/events/intro/2.jpg` (mood reference for alley + car), `assets/character-references/James/James_reference.png`, `tests/fixtures/gamedata_pre_manifest_snapshot.gdvar` (insert the new event's entry only — don't regenerate the whole file, `var_to_str` reformats unrelated entries), `scripts/debug_stage_screenshot.gd`, `systems/debug_tools.gd` (`fire_event`), `CODEMAP.md`, `docs/CONTENT-GUIDE.md` (only the label line is new prose)

**Status:** ready-for-agent

- [ ] `intro2` appears in the Debug app event picker and plays end to end; cards 1–6 staged, 7–14 show their images
- [ ] Original `intro` is untouched; intro2's ending changes no game state beyond returning to the phone
- [ ] Stage data tests pass for intro2 (all frames/actions/props referenced exist)
- [ ] Windowed screenshot harness frames saved for each staged card (incl. the slow field)
- [ ] Full test suite + check_all clean; CODEMAP updated
- [ ] On-device check list in the report (car arrival, buyers' readability, James likeness, slow-mo read, Archie's exit)
