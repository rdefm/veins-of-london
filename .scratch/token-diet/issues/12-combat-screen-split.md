# 12 — Combat screen split

**What to build:** The combat screen script becomes an orchestrator over two new components: a stage component owning the backdrop, subject slots, keypose/attack/hit/ko tweens, effect sheets and art-independent flourishes; and a command-dock component owning the Dial, complication card and Attack/Item/Leg-it actions. The screen keeps turn flow, director bridging and band sync. Every fight looks and plays exactly as now; the existing combat-screen and director tests pass.

**Blocked by:** 04 — Comment strip: scenes/screens/.

**Relevant files:** `scenes/screens/combat.gd`, new `scenes/components/combat_stage.gd` and `scenes/components/combat_command_dock.gd`, `scenes/components/combat_director.gd`, `scenes/components/dial_widget.gd`, `scenes/components/turn_order_strip.gd`, `systems/combat.gd`, `data/combat_visuals.json` (read only), `tests/test_combat_screen.gd`, `tests/test_combat_director.gd`, `scripts/debug_combat_dial_screenshot.gd`, `scripts/debug_combat_fan_screenshot.gd`, `CODEMAP.md`. Visual contract: `docs/combat-animation-vision.md`.

**Status:** ready-for-agent

- [ ] Combat screen script ≤ 900 lines; stage and dock components each own their node tree and expose a small typed interface.
- [ ] All beats, rewinds, poses and dock interactions behave identically (existing tests pass; screenshot debug scripts still run).
- [ ] Syntax check and full test suite green; CODEMAP updated.
- [ ] Human on-device check: one full fight incl. item use, complication cast, rewind, ko.
