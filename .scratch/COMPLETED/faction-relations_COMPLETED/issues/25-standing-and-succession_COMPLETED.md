# 25 — Standing and succession

**What to build:** The player can influence who leads a faction. Standing moves from:
- favours kept for that member
- their personal questline steps
- player actions matching their outlook (aggression helps hawks, peace deals help doves)
- faction outcomes (losing a war hurts the leader)

Weights are TBD. When the non-leader's standing exceeds the leader's by `successionMargin` for N days, a succession incident fires and the leader changes. The faction's effective `aggressionPersonality` and pull-back relation baseline become the new leader's.

**Blocked by:** 24 — Key member model; 22 — Faction-specific favours; 23 — Faction incidents

**Relevant files:** `systems/key_members.gd`, `systems/diplomacy.gd` (favour kept → member), `systems/faction_ai.gd` (aggression personality, relation pull-back, war outcome), the incidents system from 23 (new `succession` trigger), `systems/time_system.gd`, placeholder succession event, `tests/test_key_members.gd`. REFERENCE.md §3.10, key members §.

**Status:** ready-for-agent

- [ ] Each standing source moves standing by its data weight
- [ ] Succession fires only after the margin holds for N days; the leader changes once
- [ ] The new leader's aggression and baseline take effect in FactionAI; the Speaker switches
- [ ] Placeholder card `PROSE-REVIEW`
