# 104 — Dial: movement descriptions + calc-type craft modal

**What to build:** The HQ Dial card's crafting section lets the player craft Movements but gives no explanation of what each of the 4 movement archetypes (Recharge, Capacitor, Impact, Spread) actually does. Rework the crafting section to show each archetype as its own block with its name and a new brief description of its effect, plus a "Craft" button. Tapping Craft for an archetype opens a modal listing the 5 calc (ore) types for the player to choose which one to craft with — replacing today's row of 5 ore-type buttons that each immediately attempt a craft with no confirmation step. Cost and success chance per calc type, currently shown inline, move into this modal alongside each option.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Each of the 4 movement archetypes displays its name and a new one-line description of what it does in combat.
- [ ] Each archetype has a Craft button; tapping it opens a modal listing all 5 calc types with their cost and success chance for that archetype.
- [ ] Selecting a calc type in the modal performs the same craft attempt (and shows the same success/failure feedback) as today's direct button did.
- [ ] Regression test covering: opening the modal for an archetype, selecting a calc type, and the craft attempt resolving the same way the old direct-button flow did.

PROSE-REVIEW: the 4 movement-archetype descriptions are new copy — draft against CONTENT-GUIDE.md's tone bible and flag for human review.
