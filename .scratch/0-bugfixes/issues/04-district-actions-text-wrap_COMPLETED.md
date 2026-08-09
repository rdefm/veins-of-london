# 04 — District-panel action text wraps one letter per line

**What to build:** On a district panel, the text next to the Prospect action (e.g. "Prospecting — see Archie first", "No prospecting here", "Travel (already here)") currently renders one character per line, ballooning the row's height. It should wrap normally (word-wrap) like every other label in the app.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Open a district where prospecting is locked/unavailable/already-here — the adjacent status text reads as normal wrapped sentences, not a single-character column.
- [ ] The action row's height matches its actual text content (no oversized empty space).
- [ ] Check sibling rows built the same way (e.g. the Travel status label) for the same collapse and fix them too — this is a known failure mode elsewhere in the codebase (a label inside a horizontal row not given expand-fill sizing), so sweep the district panel's action row for every instance rather than patching one string.
