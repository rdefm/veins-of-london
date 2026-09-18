# Token diet

**Goal:** make future bugfixes, features and edits cheaper in tokens by cutting what an agent has to read to touch any one thing. No mechanics, formulas, data, or behaviour change anywhere in this effort — every ticket is behaviour-preserving and verified by the existing suite.

**Why:** survey (Sept 2026) found the architecture clean (0 screens mutating state, 0 systems touching nodes) but:
- systems/ 34% and scenes/ 36% comment lines; ~1,600 comment lines narrate ticket history ("ticket 11 merged...", "used to...", "no longer..."). `scenes/screens/combat.gd` is 46% comments, `scenes/components/map_canvas.gd` 45%.
- CODEMAP.md is 50KB (avg 190 chars/row, rows up to 3KB) despite its own 1–2 sentence rule; a previous cleanup (`agent-process-efficiency`) regrew.
- God files: combat.gd screen 2606, map_canvas 2330, modal_layer 1596 (23 modal types), phone.gd 1463 (~12 apps), GameData 1436.
- GameData hardcodes `EVENT_IDS` while `data/events/` is the real roster.
- Test helpers duplicated across 4–8 files each.

**Order:** policy + lint first (01) so nothing regrows; strip passes (02–05) before structural splits (06–13) so moved code is already lean and there are no merge conflicts; test helpers (14) any time.

**Out of scope:** deleting `combat_prototype` and root clutter (recommendation #3 of the survey) — separate decision.
