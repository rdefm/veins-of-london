# 10 — Train: time-block animation plays at once

**What to build:** Pressing Train in the HQ Gym (dumbbells) plays the time-block spend animation straight away, with the Gym menu still open. Right now it only plays after the player leaves the menu.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/modals/hq_gym_modal.gd` (`_train_button`), `systems/combat.gd` (`train`), `scenes/components/top_bar.gd` (likely home of the block animation; confirm), EventBus autoload.

**Status:** ready-for-agent

- [ ] Train triggers the block animation immediately with the modal open
- [ ] Other block-spending actions unchanged
- [ ] Root cause noted in the report (e.g. animation deferred while a modal is open)
- [ ] Headless test where feasible: the animation trigger fires on Train without closing the modal
