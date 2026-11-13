# 25 — Observation text variants by security profile

**What to build:** An observation tier's text can vary with the site's security profile and seeded details (20), so a read tells the player about this site: the fire escape it has, the camera it covers, the ward on its door (proposal §1.6). A tier carries an optional list of variants, each with a condition (the `requires` vocabulary, including `{security}`) and its own text, checked in order; the first match wins and the plain text is the fallback. Roll, tier and level are unchanged; only the shown text differs. Site memory replays the same variant on a later raid if the profile is unchanged, and the existing security-signature invalidation still re-rolls when it changes. This fills the space R§3.9d left for variants.

**Blocked by:** 20 — Site security profile.

**Relevant files:** `systems/observation.gd` (`rows()` ~L67/~L86, tier text ~L302, `site_memory()`), `systems/events.gd` (`condition_met()`), `tests/test_observation.gd`, `tests/test_event_content_lint.gd` (variant conditions are known conditions), `.scratch/raid-events/raid-variants-proposal.md` §1.6, REFERENCE.md §3.9d Observation.

**Status:** ready-for-agent

- [ ] Variant schema documented in R§3.9d
- [ ] Tests: matching variant shown, first match wins, fallback to the plain text; roll and level identical with and without variants; content lint flags an unknown variant condition
