# 01 — Observation chip on unlocked options

**What to build:** On every event, an option unlocked or boosted by an observation shows a compact chip under its label instead of the full observation tier text: observation name · ore · pips (filled up to the tier reached, out of the tier needed), e.g. `Raid · Physics ●●○`. Pick options (qualifying ores) get chips the same way. The full tier text, "what it saw" and "what it did" stay in the ? modal only. Also: an option whose `requires` nests `observed` inside `all` (e.g. raid_shop "The cellar flap") currently gets no explainer at all — it must get its chip and modal lines too.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/observation.gd` (`explainers`, `explain_line`, `explain_modal_lines`), `scenes/screens/event.gd` (~L518 explain line on option button, `_build_choice_button`), `data/constants.json` (`OBSERVATION.explain` texts), `data/events/raid_shop.json` (s_front2 ~L300), `tests/test_observation.gd`, `tests/test_event_screen.gd`. REFERENCE §3.9d Observation, §3.9a Event choice checks. `docs/ui-vision.md` for chip styling.

**Status:** ready-for-agent

- [ ] Option button shows chip (obs name · ore · pips), no tier prose
- [ ] Unlock, boost and pick explainers all render as chips
- [ ] `observed` nested in `requires.all` produces an explainer (chip + modal lines)
- [ ] ? modal still shows full tier text
- [ ] Any new UI strings in data, flagged PROSE-REVIEW
- [ ] Tests cover nested-`all` explainer and chip data (tier reached / needed)
