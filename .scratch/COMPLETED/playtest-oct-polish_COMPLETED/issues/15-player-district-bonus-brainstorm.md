# 15 — Player district bonuses + investments: brainstorm

**What to build:** A design brainstorm (grill session with the human), not code. Today, when a faction controls a district and the player meets its relation requirement, the player gets that faction's perks there. Nothing equivalent exists for districts the **player** controls. Flesh out:

- **Player district bonus:** when the player controls a district, the player sets that district's bonus. It should be variable: the player picks features or investments that decide what their controlled districts give.
- **Bigger investments:** a separate track, not tied to owning one particular district. Example from the human (explicitly a rough one): buy a security firm → security bonus in every district you control. The human has ideas here, so draw them out rather than proposing a finished system.
- **The split:** what belongs to the per-district bonus and what belongs to investments, and how the two interact.
- **Effect areas in scope:** local veins/sites (growth, yield, rolls), local danger/raids (ambush, raid defence, guard costs), prices/market (price mods, Sales offers), faction/politics (relation, threat, intel, Barometer).
- Open questions to settle: cost (£/calc/time), upkeep, re-choosing, what happens on losing control, how it surfaces on the district panel and in the Register, and how NPC factions read it (Threat).

Output: a design doc under `docs/` (or an ADR if a decision is architectural) for the human to approve. Per standing feedback, don't write choices as decided without the human's sign-off. Implementation tickets are cut only after approval.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/perks.gd`, `data/faction_perks.json`, `systems/turf.gd`, `systems/turf_panel.gd`, `scenes/screens/map.gd` (district panel Perks section), `scenes/components/contact_cards.gd` (Benefits ladder), `CONTEXT.md` (Turf, Threat, Stance), REFERENCE.md §3.1a Turf, `.scratch/COMPLETED/faction-benefits_COMPLETED/`

**Status:** ready-for-human

- [ ] Grill session held; human's investment ideas captured
- [ ] Design doc covers the player district bonus, investments, the split between them, and the open questions above
- [ ] Human approves the doc before any implementation ticket is written
