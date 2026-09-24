# 13 — Combat prototype rules

**What to build:** Specify a bounded four-action combat experiment with unambiguous resolution and resource rules.

**Blocked by:** None — can start immediately.

**Status:** wontfix (deprecated — superseded by `13a-combat-prototype-rules-and-ui.md`, which consolidates this ticket's scope plus the 2026-09-13 UI agreement)

This ticket authorizes investigation, decision capture and only the explicitly bounded prototype described below. Unresolved rules require human input; ready-for-agent means work can begin, not that proposed mechanics are approved.

- [ ] Specify Fast/Heavy/Counter/Dodge matchups: Counter stops and retaliates against selected Fast; Heavy bypasses Counter; Dodge avoids selected Heavy; Fast can catch Dodge. Defence consumes an action.
- [ ] Resolve damage, retaliation, turn/speed ordering, stance duration/expiry and target death, interruptions, multiple strikes/targets and multi-action effects.
- [ ] Decide whether exhaustion belongs in the experiment. User questioned its visual and cognitive cost; the two-heavy requirement is reopened. No-exhaustion and a post-Dodge opening were recommendations, not approved replacements. If retained, settle fatigue, symmetry, recovery, lost actions and freeze overlap.
- [ ] Define committed intent action, target, relevant damage range and resolution timing, including visible interruption rules and snapshot state.
- [ ] Establish item/extra-action resource budget and treatment of existing calc effects; no unapproved production effect changes.
- [ ] Record human-approved prototype-only parameters, scenario acceptance examples and experiment boundary. Production balance remains unchanged.

## Agreed UI direction — 2026-09-13

- Four persistent buttons in a 2×2 grid: Fast / Heavy, then Counter / Dodge. No expanding Offensive/Defensive categories. Counter names the discussed parry.
- Reminders: Fast — “Catches Dodge”; Heavy — “Bypasses Counter”; Counter — “Stops Fast”; Dodge — “Avoids Heavy”. These are not a complete symmetrical rock-paper-scissors rule table.
- Top cards show current/max health numbers with bars, plus each attacker's committed intent and target. Preserve visibility of other threats.
- Item and Leg it sit underneath the four actions. Preserve bag, escape and calc behaviour; no new dedicated Time Pearl shortcut is approved.
- Grey panel right of Dial/umbrella shows the selected clock-face button's Complication, NOT enemy intent. Selection updates the panel without casting; preserve the dedicated activation trigger.
- Preserve current visual families and Dial art. No circle/arrows, recommended-action highlight, arena-art replacement or illustrative “After your action” timing is required.
- No exhaustion meter is authorized by this UI agreement; resolve exhaustion above separately. Do not invent a replacement vulnerability mechanic.
- UI delivery: tickets 18 (combatant cards), 19 (four-action controls), 20 (Dial selection detail).

## Comments

2026-09-13: User approved top-card health/intent/target, four buttons with matchup reminders, secondary actions below, and corrected the grey panel to show Dial selection. Exhaustion remains undecided. This clarification supersedes earlier mandatory exhaustion wording in the parent spec and prototype tickets until resolved here.

PROSE-REVIEW: Four matchup reminder strings require final copy audit.
## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

