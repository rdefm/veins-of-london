# 56 — District flavour text: vein-type hints

**What to build:** Each district's flavour text (`data/districts.json`) should tell the player which ore/vein types are more likely to be found there, so district choice reads as informative rather than purely atmospheric. Cross-reference each district's actual terroir/ore-type weighting (`docs/M1-LONDON.md` prospecting rules, `Sites.site_quality_mod` weighting per `systems/sites.gd:49-101`) so the hint is factually accurate, not just vibes.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Every district's flavour text updated to name its more-likely vein type(s), grounded in the actual data-driven weighting for that district (not invented).
- [ ] Prose follows `docs/CONTENT-GUIDE.md` tone rules — dry, no camera-winking, one line per idea.
- [ ] **PROSE-REVIEW**: flag this file's new/changed text for human audit per project convention (new prose is drafted against the tone bible, then human-reviewed).
- [ ] Manual check noted for the human: read through all district flavour text and confirm the vein-type hints read naturally and match actual in-game prospecting odds.
