# 04 — Lab notebook shows only the current step's chunk

**What to build:** In the lab view, the notebook currently shows too much of its page. It should show only the first chunk of the notebook page, holding the instructions for the current step. The rest of the page is hidden entirely: it isn't collapsed or scrollable. As the step changes, that chunk shows the new step's instructions.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/hq_lab_bench.gd` (docked notebook geometry, step strip, _NOTEBOOK_BUTTON_ROW, docked book page), `systems/lab.gd`, `data/hq_visuals.json` (notebook art/regions).

**Status:** ready-for-agent

- [ ] Only the first chunk of the notebook page is visible in the lab view
- [ ] That chunk shows the current step's instructions and updates as the step advances
- [ ] Nothing else from the page can be seen or scrolled to
- [ ] Existing lab tests pass

On-device check: run a lab recipe through 2+ steps and confirm only the top chunk with the current step shows.
