# 06 — HQ Train panel → generic chrome

**What to build:** `modal_layer.gd`'s `_build_hq_gym()` (the Train modal,
reached via HQ's Gym zone) re-skins with the same generic Family-4 chrome
as ticket 05's action cards — no bespoke object, no workout-app visual
mimicry (that idea was raised and explicitly scrapped in the
`docs/ui-vision.md` §5 session). This ticket is chrome only; the training
animation itself is tracked separately (`hq-diorama` ticket 08, still
open) and is not part of this ticket's scope.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Train modal (`_build_hq_gym()`) renders with the shared generic Family-4 chrome
- [ ] No bespoke object or workout-app styling is introduced
- [ ] Existing Train action behaviour (`Combat.train()`, stat display) unchanged — this is a rendering swap only
- [ ] `tests/test_modal_layer.gd` updated for the new styling
