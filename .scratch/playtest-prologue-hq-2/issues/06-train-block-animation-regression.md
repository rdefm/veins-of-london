# 06 — Train block animation still waits for the Gym menu to close (regression)

**What to build:** playtest-prologue-hq 10 was meant to fix this, but on the latest build pressing Train (dumbbells) in the HQ Gym still only plays the time-block animation after the player leaves the menu. The animation should play straight away with the Gym menu still open. Find out why the shipped fix doesn't hold on device.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/modals/hq_gym_modal.gd` (`_train_button`), `systems/combat.gd` (`train`), `scenes/components/top_bar.gd` (block animation), EventBus autoload; commit `33778524` (ticket 10 implementation).

**Status:** ready-for-agent

- [ ] Root cause of the on-device failure stated in the report (e.g. top bar covered by the modal, animation running but hidden, deferred redraw)
- [ ] Train plays the block animation immediately and visibly with the modal open
- [ ] Other block-spending actions unchanged
- [ ] Headless test covers the failure mode found (e.g. visibility or z-order with the modal open)
