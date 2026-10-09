# 03 — Natural walk

**What to build:**
- Kit walk cycle grows to 6–8 frames with a clear contact/passing/lift shape (`WALK` in `char_kit.py`).
- Walk frames advance by distance travelled, not time (`walk.stride_px` in manifest) so feet don't skate; first/last step eases with the move.
- 1 px body bob on passing frames (per-frame `walk.bob` list), slight forward lean (head tilt bias while walking).
- Arm swing: arm sprites rotate ±a few degrees about their shoulder pivot, opposite to the legs (`anchors.shoulder_l/_r` from the kit); held props swing with them. Arms in a non-rest pose (knife, bag wave) swing less (per-frame swing scale).
- Regenerate all kit rigs (5 styles × archie/james/knife/mate).

**Blocked by:** 01

**Relevant files:** `tools/stage_art/char_kit.py` (`WALK`, `legs_canvas`, `manifest`, `anchors`), `tools/stage_art/build_intro_stage.py`, `tools/stage_art/build_style_mockups.py`, `scenes/stage/stage_actor.gd`, `scenes/stage/stage_player.gd` (`_update_moves`), `tests/test_stage.gd` (`_walk_problems`), ENGINE.md

**Status:** ready-for-agent

- [ ] Walk frame index is a function of distance moved (tested)
- [ ] Rig validation covers new walk/shoulder keys
- [ ] Screenshot harness frames mid-walk for intro2/5/6 look right
- [ ] ENGINE.md updated
