# 04 — Needle uses its sprite, angle shows charge

**What to build:** The Dial needle is currently a plain coloured rectangle, not the original needle art, and charge isn't readable. Replace it with the needle sprite, pivoting at the face centre; its angle keeps showing the charge fraction (min angle = empty, max = full) and animates on Wind/cast as now. An "X/Y" charge number sits clearly by the face so the count is unambiguous.

**Blocked by:** None — can start immediately.

**Relevant files:** `assets/hq/dial/dial-needle.png`, `scenes/components/dial_menu.gd` (`_needle`, `_set_needle`, `needle_rotation_degrees`, `_charge_label`), `data/dial_art.json` (needle size / pivot anchor), `docs/` Dial art spec §4.

**Status:** ready-for-agent

- [ ] Needle is the `dial-needle.png` sprite, pixel-crisp at integer zoom
- [ ] Pivot sits on the face centre; empty/full positions match NEEDLE_MIN/MAX
- [ ] Angle tracks charge fraction; existing sweep/open beats still play
- [ ] "X/Y" charge number legible on the overview
- [ ] Needle anchor measured into dial_art.json, not hard-coded
