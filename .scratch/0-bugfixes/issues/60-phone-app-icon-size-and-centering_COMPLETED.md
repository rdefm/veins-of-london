# 60 — Phone: app icon size + centering

**What to build:** On the Phone tab's app grid, increase the icon+label tile size and change the grid layout so it's centered rather than skewed left. Applies to the phone-as-home-screen app grid described in the D4/ticket-11 phone-OS-shell design (`docs/REFERENCE.md` §2, "the grid holds an icon+label tile per app").

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] App tile size increased on the phone home grid (locate the grid-building code in the phone screen scene/script).
- [ ] Grid container/layout changed so tiles are centered within the available width rather than left-aligned, at any tile count (including locked/greyed tiles, which stay in their permanent slots).
- [ ] Manual check noted for the human: view the phone home screen on-device and confirm icons are visibly larger and centered, with locked-app padlock tiles still rendering correctly in the new layout.
