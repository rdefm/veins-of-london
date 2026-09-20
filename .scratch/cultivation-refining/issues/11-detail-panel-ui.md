# 11 — Larger detail panel UI

**What to build:** The larger panel opened from the compact bubble's information area (ticket 09) shows yield, drift/upkeep, development chance, raid risk, and detailed actions, with clear visual distinction between earned level, character cultivation skill, and condition (these must never be conflated — condition is not a "cultivation level"). It must correctly present maximum-level veins (no more development rolls, but still harvestable/raid-exposed), the 120-ceiling case, and the level-1 emergency-collapse state.

Visual layout has not been pre-reviewed (per the source spec) — build it following the compact bubble's established conventions (segments, slim bar, non-color-only cues) and flag it for the human's normal on-device visual review rather than treating any particular layout as pre-approved.

**Blocked by:** 02, 06, 07, 09.

**Relevant files:**
- New detail-panel scene (owned by whichever screen hosts the bubble from ticket 09 — add to CODEMAP.md once created)
- `systems/cultivating.gd` (data sources: level, condition, drift rate, level-up chance, combined raid magnitude from ticket 02)

**Status:** ready-for-agent

- [ ] Panel shows yield, drift/upkeep, development chance, raid risk, and detailed actions
- [ ] Level, cultivation skill, and condition are visually and textually distinct — no label implies condition is a "cultivation level"
- [ ] Maximum-level veins clearly communicate they will not develop further, without hiding harvest/raid-relevant info
- [ ] 120-ceiling veins and level-1 emergency-collapse veins have distinct, correct presentations
- [ ] Device QA checklist (for the human): full visual/layout review, since design was not pre-approved
- [ ] PROSE-REVIEW: any new copy in this panel
