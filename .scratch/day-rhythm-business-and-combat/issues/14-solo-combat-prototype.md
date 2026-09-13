# 14 — Solo combat prototype

**What to build:** A bounded playable experiment demonstrates readable four-action solo combat and reliable Rewind.

**Blocked by:** 13 — Combat prototype rules.

**Status:** ready-for-agent

- [ ] Implement ticket 13’s prototype rules using serializable combatant/turn-order state, committed intent, selected defence target/stance, two exertion marks and exhaustion.
- [ ] Demonstrate all four defensive matchups, action-consuming defence, dodged-Heavy fatigue and symmetric player/enemy exhaustion.
- [ ] Show action, target, damage range where relevant and timing; intents stay committed until resolved or visibly interrupted. Render resolved beats rather than predicting outcomes independently.
- [ ] Teach Heavy/Dodge/exhaustion with a brawler, Fast/Counter with a knife fighter, then Counter/Heavy with an enforcer.
- [ ] Rewind restores all introduced combat state; headless public-resolution tests verify matchups, timing, exhaustion and restoration.
- [ ] Keep production mechanics unchanged; record prototype assumptions and evidence, with portrait device QA and a human evaluation before considering production integration.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

