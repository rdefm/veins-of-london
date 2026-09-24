# 13 — Combat prototype rules

**What to build:** Specify a bounded four-action combat experiment with unambiguous resolution and resource rules.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

This ticket authorizes investigation, decision capture and only the explicitly bounded prototype described below. Unresolved rules require human input; ready-for-agent means work can begin, not that proposed mechanics are approved.

- [ ] Specify Fast/Heavy/Counter/Dodge matchups: Counter stops and retaliates against selected Fast; Heavy bypasses Counter; Dodge avoids selected Heavy; Fast can catch Dodge. Defence consumes an action.
- [ ] Resolve damage, retaliation, turn/speed ordering, stance duration/expiry and target death, interruptions, multiple strikes/targets and multi-action effects.
- [ ] Specify two-heavy prototype exertion/exhaustion: dodged Heavy adds fatigue; player/enemy symmetry; lost action only, no automatic critical bonus. Resolve consecutive swings, reset/recovery, available exhausted actions and freeze overlap.
- [ ] Define committed intent action, target, relevant damage range and resolution timing, including visible interruption rules and snapshot state.
- [ ] Establish item/extra-action resource budget and treatment of existing calc effects; no unapproved production effect changes.
- [ ] Record human-approved prototype-only parameters, scenario acceptance examples and experiment boundary. Production balance remains unchanged.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

