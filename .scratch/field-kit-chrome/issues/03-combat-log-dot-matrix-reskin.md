# 03 — Combat log reskinned onto the dot-matrix board

**What to build:** `scenes/screens/combat.gd`'s departure-board log (the
mid-fight "ticker" directly under the stage, per combat-presentation
ticket 21, and the post-combat outcome log) re-skins onto the same
dot-matrix rendering component ticket 02 builds, rather than its current
plain styling — reusing the shared renderer, not a second implementation.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Combat's mid-fight log renders via the shared dot-matrix component from ticket 02
- [ ] Log content/line count/scroll behaviour (~2-3 visible lines, per ticket 21) is unchanged — this is a rendering swap only
- [ ] Post-combat (outcome resolved) log rendering also uses the dot-matrix component
- [ ] `tests/test_combat_screen.gd` updated for the new rendering
