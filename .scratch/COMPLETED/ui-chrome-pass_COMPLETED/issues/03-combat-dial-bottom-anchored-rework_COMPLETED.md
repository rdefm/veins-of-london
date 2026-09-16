# 03 — Combat command-deck rework: bottom-anchored dial

**What to build:** `scenes/components/dial_widget.gd` currently renders
inside a fixed 130×170px clipped box (`VISIBLE_BOX_SIZE`), showing a crop
of the 220px umbrella-handle art, docked to the left of the action row
(`scenes/screens/combat.gd::_build_dial_and_actions_row()`). Human
direction (confirmed): the dial should become a large prop rising from
the bottom edge of the screen — same source art, not shrunk — with the
Attack/Item/Leg it action row and the Complication-detail card
(`_build_complication_detail()`) reflowing around/above it instead of
sitting in a fixed-width row beside it.

This also fixes a confirmed-by-screenshot bug in the current layout: the
Complication-detail card and the third action card ("Leg it") both run
off the right edge of the screen at 390px width — the row is not actually
width-constrained the way `_build_action_deck()`'s own comments assume.
The new layout must not reproduce this.

Exact geometry (tap-region placement for the dial's screws/trigger switch,
per `dial_widget.gd`'s own ART-REVIEW note) is not locked and needs
on-device eyeballing — this ticket owns getting it into a reasonable first
pass, not pixel-perfect final placement.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Dial renders large, anchored to the bottom of the screen, using the existing `dial_device_base.png` art at a size that reads as a real prop (not a small cropped box)
- [ ] Attack/Item/Leg it cards and the Complication-detail card are all fully visible on a 390-wide viewport — nothing clips or runs off-screen
- [ ] Dial's screw tap-targets (Complication housing select) and trigger switch remain tappable and correctly hit-test against the new layout
- [ ] Command-deck rebuild (`_build_command_deck()`/`_build_dial_and_actions_row()`) still runs on every `EventBus.state_changed` per existing pattern
- [ ] `tests/test_combat_screen.gd` and any `dial_widget` tests updated for the new layout/sizing
