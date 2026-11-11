# 05 — Posts tab: Reserve tray, tap a guard then a slot

**What to build:** the Reserve moves to the top of the Posts tab as a tray: header "Reserve · paid, on call" with "n ready · m out", then guard chips (avatar, short name, level badge). Training/injured guards show greyed with "Training Nd" / "Injured Nd" and can't be selected.

Tap a ready chip to select it (accent outline); every empty slot on HQ/vein cards turns into a highlighted "+ Post <name> here" target, and a hint line explains it. Tapping a target posts the guard through `Muscle.post` (the one posting function). Tapping the chip again, or posting, clears the selection. Full posts show no targets. Selection is screen-local, never in `GameState.state`. The Assign picker stays (empty-slot tap with nothing selected, and the vein panel).

Mockup: https://claude.ai/artifact/3F5zB6ctS4FBERj2k4SqDx (Posts artboard, Dee selected).

**Blocked by:** 04 — Posts tab: place cards with slots and score bar.

**Relevant files:** `scenes/screens/security.gd`, the guard_assign modal (`scenes/modals/`), `systems/muscle.gd` (`post`, `post_block_reason`, `reserve`, status from 01), `scenes/components/guard_widgets.gd`.

**Status:** ready-for-agent

- [ ] Tray lists Reserve; unavailable guards greyed and unselectable
- [ ] Select → targets → tap posts the guard; cancel by re-tapping
- [ ] Posting only via `Muscle.post`; selection not in state
- [ ] Empty-slot tap with no selection still opens Assign
- [ ] check_all clean; full suite green
- [ ] PROSE-REVIEW: tray header, hint line, target label
- [ ] On-device checklist in the report
