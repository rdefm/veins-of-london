# 102 — Fix Des's map pin not appearing

**What to build:** The Notes app tells the player "Des is waiting on the map. He'll teach you to prospect," but no pin appears on the map for him. The pin data for this beat already exists and is gated on the same flags (`colA1DesMet` true, `colA1ProspectingTaught` false) that gate the Notes-app text, so structurally they should already be in sync — diagnose why they aren't (candidates: a flag being set/read inconsistently between the objectives system and the map-pins system, the pin's district not matching where the player is looking, or the pin rendering being dropped somewhere in the map canvas) and fix the actual divergence.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Reproduce end-to-end: reach the point where the Notes app shows the Des prospecting line, then confirm today no pin renders in Shoreditch.
- [ ] Root cause identified (the actual point where pin visibility diverges from Notes-text visibility) and fixed.
- [ ] Des's pin appears on the map whenever the corresponding Notes-app text is showing, and disappears when the flags say it shouldn't (matching the existing gating rules).
- [ ] Regression test covering pin-vs-notes-text flag-consistency for this beat.
