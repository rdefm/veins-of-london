# 14 — Dial widget pixel-art pass (per combat-animation-vision.md §2.5)

**What to build:** Replace `DialWidget`'s placeholder vector `_draw()`
(clock-face charge gauge, notched rotating bezel, fixed pointer) with the real
pixel-art diegetic prop `docs/combat-animation-vision.md` §2.5 specs, using the
same combat pixel-art pipeline (`tools/pixelize.py`) and asset conventions the
rest of the combat-presentation tickets use. Functional shape (rotate-to-select,
press-to-trigger, charge gauge) is unchanged — this is an art-only pass.

**Blocked by:** 13 (no point re-skinning a widget that doesn't reliably
render).

**Status:** ready-for-agent

- [ ] Real pixel art replaces the placeholder vector shapes for the Dial
      handle/bezel/charge-clock, per §2.5.
- [ ] Rotate (select), trigger (fire), and the charge gauge all still work
      identically to the placeholder — no functional/interaction change.
- [ ] Assets run through `tools/pixelize.py` per `docs/ART-BIBLE.md`.
- [ ] Confirmed on-device that the new art renders correctly and stays
      legible at combat-screen scale.
