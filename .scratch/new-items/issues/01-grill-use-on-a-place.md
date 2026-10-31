# 01 — Grill: "use on a place" UI for vein and HQ items

Status: needs-triage
Type: grilling

**Question:** Should items that target a place (Root Feed, Good Year on a vein; Deadweight on HQ or a vein stockpile) share one "use on a place" UI pattern in the Vein list and Home screens, or should everything stay in the Bag with a target picker?

Explore with the human (grilling skill), then record the decision under `## Answer`. Points to cover:
- Where the player expects to find the action: on the place (vein row / HQ zone) or on the item (Bag).
- Whether one shared pattern (e.g. a `targetedItems` list read by both screens) beats per-screen handling.
- How an active boost is shown on the place afterwards (until-day, power).
- Mobile tap budget: steps from "I have Root Feed" to "it's on the vein".
- Whether future targeted items (contacts, districts) should fit the same pattern.

**Relevant files:** `.scratch/new-items/brainstorm.md` (§6 Tier C, §8 Q4), `CODEMAP.md` (Bag, Vein list, Home screens), `docs/ui-vision.md`, `docs/REFERENCE.md` §3.12 (raid loss), `systems/cultivating.gd`.

## Comments
