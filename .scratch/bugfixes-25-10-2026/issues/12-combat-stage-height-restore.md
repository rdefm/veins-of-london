# 12 — Combat stage back to full height; play-by-play takes room from the bottom half

**What to build:** Ticket 07 made the play-by-play box taller by shrinking the visual stage (sprites and background). Restore the stage to its height from before ticket 07. The play-by-play keeps its larger size, but takes that extra height from the bottom half (the command area) instead. The right-hand menu and the section panel must still fit and stay usable on a phone screen.

**Blocked by:** 11 — Combat main menu: compact right-hand column with icons and names.

**Relevant files:** `scenes/screens/combat_rounds.gd` (`_upper_region`, `_fit_stage_to_region`, stage/transcript/dock split), `scenes/components/combat_stage.gd`, `scenes/components/combat_transcript.gd`, `scenes/components/combat_command_dock.gd`. Pre-07 layout: `git show 8bf842a2^:scenes/screens/combat_rounds.gd`.

**Status:** ready-for-agent

- [ ] Stage box height matches its height before ticket 07
- [ ] Play-by-play box is no shorter than it is now
- [ ] The extra height comes out of the command area, not the stage
- [ ] Main menu entries and panel rows (incl. the full Fight move list) still fit and are tappable
- [ ] Existing combat tests pass

On-device check: an ordinary fight and the gym tutorial fight. The stage is its old size, the play-by-play is still readable, and every move can be tapped.
