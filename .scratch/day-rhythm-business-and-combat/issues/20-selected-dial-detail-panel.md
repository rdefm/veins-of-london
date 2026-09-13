# 20 — Selected Dial detail panel

**What to build:** The grey panel beside the Dial describes the Complication selected on the umbrella's clock-face buttons.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Restyle the existing selected-Complication readout into a grey panel right of the Dial, above combat actions. It represents Dial selection, never enemy intent.
- [ ] Display existing Complication name, symbol, tier and existing player-facing effect description where available. Flag missing content rather than inventing effects or costs.
- [ ] Changing the selected loaded button updates the panel immediately without casting or spending resources. Preserve the existing dedicated activation trigger.
- [ ] Keep details consistent after refresh, casting, state changes and Rewind. Preserve meaningful No Dial/Empty handling without stale details.
- [ ] Preserve Dial art, charge indication and button/trigger hit regions.
- [ ] Support the existing action stack and ticket 19's grid; no dependency on four-action mechanics.
- [ ] Verify selection-to-panel updates and selection without casting headlessly. Check wrapping, long names, empty/no Dial and layout clearance at 390px portrait on-device.

## Delivery constraints

Use canonical Complication data and current visual families. Preserve effects and costs. Keep presentation outside systems and mutations outside screens; update ownership documentation when responsibilities change. Run required GDScript syntax checks and the full headless suite. Flag new prose with PROSE-REVIEW.
