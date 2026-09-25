# 04 — Cultivation: ring animation replaces popups

**What to build:** Cultivating a vein no longer shows any popup (e.g. "Cultivation worked. Development bar +9"). Instead the growth ring on the vein's circle on the Map visibly animates to the new value. On level-up the ring fills completely, plays a pop, then resets to the vein's actual growth value after levelling. Every cultivation outcome loses its popup and gets an animation instead. Animation only — no mechanics change.

Note: the cultivating system currently opens the result modal itself; systems must not touch UI. Replace with an EventBus signal carrying the result that the Map listens to.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/cultivating.gd` (`Modal.open("cultivate_result", …)`), `autoload/EventBus.gd`, `scenes/components/map_canvas.gd`, `scenes/components/map_halos.gd`, `scenes/components/vein_bubble.gd`, `scenes/modals/cultivate_result_modal.gd`, `scenes/modals/modal_registry.gd`, `autoload/SaveManager.gd` (references the modal), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] No popup for any cultivation outcome
- [ ] Growth ring animates from old value to new value
- [ ] Level-up: ring fills, pops, then settles at the vein's post-level growth value
- [ ] System emits a signal instead of opening a modal
- [ ] Unused modal and registry entry removed
- [ ] Growth/level results unchanged (existing cultivation tests still pass)
