# 04 — Character kit + Archie's new poses (all 3 styles)

**What to build:** Grow the style mock-up generator from "Archie in three styles" into a small character kit, so new people can be made in chibi, adventure and retro styles from a config: body build (height, width, age stoop), hair (curly / short / thinning grey, colours), facial hair, glasses, outfit pieces and colours (jumper, jacket, waistcoat over shirt, trousers, shoes), plus per-character held props. Then give Archie, in all three styles, the poses the intro needs:
- holding a plastic Tesco bag (white/blue, an opened Amazon box shape inside) at his side
- lifting the bag-arm in a wave ("Alright chaps?")
- other hand slipping into his back pocket and coming out with a small vial
- a wrist flick releasing the vial (hand anchor for the throw)
- a walk cycle (legs frames, per ticket 02's rig format), bag handle wrapped round his hand

Regenerate `archie_chibi`, `archie_adventure`, `archie_retro`; existing frames keep their names so `archie_craft_chat2/3/4` still play.

**Blocked by:** 02 — Stage movement and cast steps (walk-cycle rig format).

**Relevant files:** `tools/stage_art/rig_archie_styles.py`, `tools/stage_art/build_style_mockups.py`, `tools/stage_art/raster.py`, `tools/stage_art/build_stage_assets.py` (`rig_manifest`), `tools/stage_art/preview_rig.py`, `data/stages/rigs/archie_*.json`, `assets/stages/rigs/archie_*/`, `assets/character-references/Archie/Archie_reference.png`, `CODEMAP.md` (tools + data/stages rows), `.scratch/stage-engine/ENGINE.md` (Rigs section)

**Status:** ready-for-agent

- [ ] Character configs drive all three styles; Archie is re-expressed as one config with no visual regression on his existing frames
- [ ] New Archie frames + actions (e.g. bag wave, pocket draw, flick) exist in all three Archie style rigs and a walk cycle is declared
- [ ] Preview sheet per style shows the new poses; stage data tests pass; `archie_craft_chat2/3/4` still play
- [ ] Human visual check of the preview sheets before tickets 05–07 build on the kit
