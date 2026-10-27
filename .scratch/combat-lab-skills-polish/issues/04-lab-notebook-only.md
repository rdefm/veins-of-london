# 04 — Lab notebook only, no instruction modal

**What to build:** The Lab view currently shows the notebook plus a separate box/modal with instructions. Show only the notebook. The instruction text is already in the notebook, so drop the modal's text. Any buttons the modal had move into the notebook, styled in the notebook's look (not standard UI buttons).

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/hq_lab_bench.gd` (live Lab screen: plate, notebook, recipe book/page, docked book during Craft), `scenes/components/lab_gauges.gd` (book's band track), `systems/lab.gd` (actions the buttons call — no changes expected), `docs/ui-vision.md` (notebook/visual family), `.scratch/lab-port/spec.md`.

**Status:** ready-for-agent

- [ ] No instruction box/modal shown alongside the notebook in any Lab state
- [ ] Every action the modal offered is reachable from inside the notebook
- [ ] Those buttons match the notebook styling
- [ ] Screen still mutates nothing directly — buttons call Lab system funcs
