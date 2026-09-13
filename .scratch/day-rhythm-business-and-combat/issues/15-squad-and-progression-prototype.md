# 15 — Squad and progression prototype

**What to build:** Extend the experiment to mixed threats and prepared late-game wave fights to evaluate tactical variety.

**Blocked by:** 14 — Solo combat prototype.

**Status:** ready-for-agent

- [ ] Show the opponent covered by defence plus all other incoming threats; demonstrate that single-target defence leaves other opponents dangerous.
- [ ] Evaluate mixed brawler/knife fighter/enforcer squads and whether dodge twice, heavy, repeat dominates across encounters.
- [ ] Compare an early build and a prepared late build against the same fixed-strength early enemy; ordinary enemies do not scale to erase progression.
- [ ] Exercise existing calc effects within the approved prototype budget; any new Shield, Time Pearl, Enhancement Powder or area-effect contract requires explicit specification before use.
- [ ] Stage selected multi-wave prototype fights and assess sustained solo power and portrait readability; do not turn routine encounters into waves.
- [ ] Introduce planned Grab/Bolt and Call only after the basic interaction is understandable and their prototype contracts are explicit.
- [ ] Record scenario results, remaining decisions and recommendation for separately scoped production work; test multi-opponent resolution and perform device QA.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

