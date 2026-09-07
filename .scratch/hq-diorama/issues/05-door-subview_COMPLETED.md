# 05 — Door sub-view

**What to build:** The front door zone opens a diegetic security view drawn
with visible fixture points — an empty lock plate, an empty bar bracket, a
bare camera mount, an unmarked ward panel. Installed security fills its
slot; uninstalled security is a visible absence you tap to buy, wired to
the existing security-purchase system calls. While a raid is pending, the
door renders in its hostile state in the room plate itself (ticket 02's
room), and tapping it opens Defend instead of this security view.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Door zone opens the diegetic security sub-view, full-bleed
- [ ] Each security slot (lock, bar, camera, ward) shows installed/empty state correctly
- [ ] Tapping an empty slot buys that security tier via existing system calls, unchanged mechanics
- [ ] Hostile-door state renders on the room plate when a raid is pending
- [ ] Tapping the door while hostile opens Defend, not the security sub-view
- [ ] `hq.gd`'s old inline security section is removed
