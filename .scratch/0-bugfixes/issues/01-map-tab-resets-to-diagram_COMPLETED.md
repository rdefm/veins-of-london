# 01 — Map tab reopens on the network diagram, not the last-viewed district

**What to build:** Opening the Map tab always shows the Network diagram overview first, regardless of which district or site the player last drilled into on a previous visit. Drilling into a district (or a site/vein sheet) still works exactly as now, but that drill-down state doesn't survive leaving the Map tab — coming back always starts fresh at the diagram.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] From the diagram, tap into a district panel (and optionally a site/vein sheet), then switch to any other nav tab and back to Map — the diagram shows first, not the district panel.
- [ ] Tapping a district/site from the diagram still opens its panel/sheet normally within the same Map-tab visit (MapNav's drill-down navigation is unchanged).
- [ ] Existing map/nav tests continue to pass.
