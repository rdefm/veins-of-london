# 12 — Lab bench: books+ore-store half uses approved desk art

**What to build:** Drop the human-approved desk photo/render in as stop 0's
background as-is — no `pixelize.py` pass, no palette requantization; this
one asset is exempt from the ART-BIBLE pixel-art pipeline by explicit human
decision. Reposition the recipe/experiment notebook regions and the five
`ore_<oreTypeId>` container regions to actually sit over the art (books in
the lower portion, ore containers in the open desk space above them), still
rendering as placeholder boxes where no per-container sprite exists yet.

**Blocked by:** 11

**Status:** ready-for-agent

- [ ] Stop 0's background renders the approved desk image via
      `data/hq_visuals.json`'s `labBench` plate/region `image` field(s),
      unprocessed (not run through `tools/pixelize.py`)
- [ ] `notebookRecipes` / `notebookExperiments` regions repositioned to sit
      exactly over the two books in the art, each still ≥44×44
- [ ] Five `ore_<oreTypeId>` regions repositioned into the open desk space
      above the books, still passing `GameData._validate_hq_visuals()`
- [ ] Region alignment checked against the art using ticket 01's debug
      overlay; note the check (screenshot or description) in the task report
