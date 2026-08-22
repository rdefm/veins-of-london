# 51 — Map: prevent cross-faction line/station overlap

**What to build:** `systems/map_routing.gd` currently only avoids one thing when routing a faction's connector lines: crossing the river polyline (`elbow_path`/`_elbow_crosses_river`/`_segment_crosses_polyline`, `map_routing.gd:37-60`, picking whichever of two fixed elbow orientations avoids it "where trivially possible"). There is no collision-avoidance between one faction's lines and another faction's stops — each faction's line is built independently (`map_canvas.gd:730-827`, via `MapLayout.group_by_faction` + `MapRouting.build_line`) with no cross-faction geometry check. Extend the routing so a faction's connector lines never visually overlap another faction's stations/veins, using the same elbow-orientation-choice approach already used for river avoidance.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `MapRouting`'s elbow-path selection also checks candidate paths against other factions' stop positions (not just the river), picking an orientation that avoids passing through them "where trivially possible," matching the existing river-avoidance pattern.
- [ ] New test in the routing suite constructing a case where the naive elbow would cross another faction's stop, confirming the alternate orientation is chosen instead.
- [ ] Manual check noted for the human: play until multiple factions have adjacent territory and confirm no faction's line visibly crosses through another faction's stop icon.
