# 04 — Comment strip: scenes/screens/

**What to build:** Same discipline as ticket 03 applied to every screen script and the main scene script: current-behaviour comments only, rationale cites a vision/spec § rather than a ticket, file headers shrink to a few lines. The combat screen is the biggest single win (nearly half its lines are comments). Code untouched.

**Blocked by:** 01 — Comment + CODEMAP policy with lint.

**Relevant files:** all `scenes/screens/*.gd` plus `scenes/Main.gd`. Heaviest: `scenes/screens/combat.gd`, `scenes/screens/phone.gd`, `scenes/screens/map.gd`, `scenes/screens/hq_dial.gd`, `scenes/screens/hq_lab_bench.gd`, `scenes/screens/hq.gd`, `scenes/screens/hq_door.gd`, `scenes/screens/hq_floorplan.gd`, `scenes/screens/event.gd`. Vision docs to cite: `docs/ui-vision.md`, `docs/hq-diorama-vision.md`, `docs/combat-animation-vision.md`, `docs/M1.5-NETWORK-MAP.md`.

**Status:** ready-for-agent

- [ ] Diff touches only comment/blank lines in scenes/screens/ and scenes/Main.gd.
- [ ] Combined comment-line count across scenes/screens/ at most half of today's; `combat.gd` at most 400 comment lines.
- [ ] Every surviving *why* comment cites a doc §, ≤2 lines.
- [ ] Those files removed from the lint allowlist; syntax check and full test suite green.
