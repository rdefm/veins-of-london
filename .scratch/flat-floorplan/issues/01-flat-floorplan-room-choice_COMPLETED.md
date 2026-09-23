# 01 — Wire the Flat floorplan into Harrow's and HQ

**What to build:** The player can inspect the Flat's static plan in Harrow's, move in, tap the HQ noticeboard, choose the Flat's one selectable room, buy its use, and later replace that use at full price. The fixed bedroom stays unselectable. This is the first end-to-end property floorplan; later properties receive their own plans separately.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `.scratch/flat-floorplan/spec.md`; `assets/floorplans/flat.svg`; `docs/REFERENCE.md` §1.7, §2 home state, §3.3; `docs/hq-diorama-vision.md` §§6–7; `docs/ui-vision.md` §§5, 10; `data/home.json`; `systems/home.gd`; `scenes/screens/hq_floorplan.gd`; `scenes/phone_apps/property_app.gd`; `autoload/GameState.gd`; `tests/test_home.gd`; `tests/test_hq_floorplan.gd`; `CODEMAP.md`.

- [ ] Harrow's Flat listing displays the floorplan as a static preview; its current property/next property purchase flow still works.
- [ ] The HQ noticeboard opens the owned Flat's plan. Bedroom is fixed; tapping room 02 opens eligible uses with effect, price, and disabled reasons. The plan's touch region works at mobile size.
- [ ] Buying Workshop or Home Gym assigns it to room 02, charges once, applies its existing bonus, saves, and updates the plan. Locked, unaffordable, and duplicate choices cannot be bought.
- [ ] Replacing room 02 removes the previous use and its effects, charges the new full price with no refund, and remains atomic on failure. Home Gym HP changes remain valid when removed; any staffed room removed by this system automatically unassigns its contact.
- [ ] Moving to a higher property retains purchased room upgrades and their effects; new slots are empty. Existing saves with a room list load with their purchases intact. Save, snapshot, and Rewind still operate on pure data.
- [ ] Update canonical mechanics/state in `docs/REFERENCE.md` before implementation; update `CODEMAP.md` if file responsibilities change. Add meaningful system and screen tests, run touched-file Godot 4.7 checks and the full test suite, and flag on-device visual checks for the human.

## Comments

- Approved breakdown: one complete Flat ticket now; other properties after their floorplans exist.
