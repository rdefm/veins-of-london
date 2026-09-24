# 04 — Dark nav dock on Map

**What to build:** With Map dark mode on, the bottom Phone/Map/HQ nav dock renders in a dark variant (Map palette chrome tokens) whenever the Map tab is showing. It returns to its normal look the moment the player navigates to Phone or HQ, and switches live when the toggle flips while on Map. With dark mode off, the dock looks the same as today everywhere.

**Blocked by:** 02

**Relevant files:** `scenes/components/nav_bar.gd`, `scenes/components/ui.gd`, `docs/ui-vision.md` §5 (nav dock row), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Live-tree test: with dark mode on, the dock uses dark tokens on Map and normal colours on Phone/HQ; it follows the toggle live on Map
- [ ] With dark mode off, the dock is unchanged on every screen
- [ ] Human check: the dock is dark and legible on Map, and normal on Phone/HQ; the active-tab accent is readable in dark
