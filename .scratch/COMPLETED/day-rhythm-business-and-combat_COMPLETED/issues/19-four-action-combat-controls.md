# 19 — Four-action combat controls

**What to build:** Choose four combat actions directly with visible matchup reminders; access Item and Leg it underneath.

**Blocked by:** 14 — Solo combat prototype (approved action resolution).

**Status:** ready-for-agent

- [ ] Replace Attack with a persistent 2×2 grid: Fast / Heavy, then Counter / Dodge. No expanding category menus.
- [ ] Show reminders: Fast — “Catches Dodge”; Heavy — “Bypasses Counter”; Counter — “Stops Fast”; Dodge — “Avoids Heavy”. Icons supplement labels.
- [ ] Invoke each matching system action against the selected eligible target using ticket 13's rules. Defence costs an action and covers the specified opponent; screens never resolve combat independently.
- [ ] Put Item and Leg it beneath the grid, preserving bag and escape behaviour and existing calc access. No newly dedicated Time Pearl shortcut is required.
- [ ] Respect turn, animation and eligibility locks; prevent duplicate submissions and show unavailable actions correctly.
- [ ] Fit beside the Dial with readable thumb targets, safe-area clearance and no overlap/tap-through at 390px portrait. Do not add an exhaustion meter, circle/arrows or recommended-action highlight through this ticket.
- [ ] Test routing, targeting and disabled states headlessly; verify the complete command area on-device.

## Delivery constraints

Follow ticket 13 and current visual families. Keep new mechanics within the bounded prototype until production integration is approved. Store copy in data and mutations in systems; update ownership documentation when needed. Run required GDScript syntax checks and the full headless suite.

PROSE-REVIEW: Four matchup reminder strings above.
