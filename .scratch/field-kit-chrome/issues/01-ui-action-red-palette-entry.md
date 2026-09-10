# 01 — `ui_action_red` palette entry

**What to build:** Add a new `ui_action_red` colour to `data/palette.json`
as its own group, following the same pattern `calc_gold` already uses —
the pillar-box/bus-red accent `docs/ui-vision.md` §6 reserves for ordinary
buttons/actions across Families 2–4. Candidate hex `#c8102e` is indicative
only; confirm the final value against the existing 42-colour set (don't
land a near-duplicate of an existing ramp entry) before locking it.
Regenerate the swatch (`tools/make_palette_swatch.py`) per ART-BIBLE §2's
documented process.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `data/palette.json` has a new `ui_action_red` entry (its own group, matching `calc_gold`'s shape)
- [ ] Final hex confirmed against the existing palette rather than assumed from the candidate
- [ ] `data/palette_swatch.png` regenerated via `tools/make_palette_swatch.py`
- [ ] `docs/ui-vision.md` §6/§9 updated to drop the "indicative, needs confirming" language once the hex is locked
