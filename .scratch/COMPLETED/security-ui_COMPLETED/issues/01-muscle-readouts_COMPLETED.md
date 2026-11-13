# 01 — Muscle readouts for the Security UI

**What to build:** the read-only Muscle answers the redesigned Security screen needs, so screens never compute guard logic themselves. Visible on device straight away: the guard detail sheet's Train and Post blockers say *why* ("Training · back tomorrow", "Injured · 2d") instead of "Not available."

Readouts:
- Guard status: one of posted / reserve / training / injured, plus days left for training and injury.
- Block reasons for Train and Post that name the cause (training with days left, injured with days left) in place of the generic "Not available.". Other reasons unchanged.
- Roster counts: total, posted (available at HQ or a vein), ready (available in Reserve), out (training or injured).
- XP progress within the current level (fraction from this level's threshold to the next), and the XP one training session would give after trait multipliers.
- Security score split for a post: the hardware points and the guard points that make up the score (same formula as today's score, just returned in two parts; parts sum to the score).
- A guard's repel and fight multipliers vs an L1 guard (weight and trait effects), for display.

Mockup: https://claude.ai/artifact/3F5zB6ctS4FBERj2k4SqDx (Detail artboard).

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/muscle.gd` (`is_available`, `post_block_reason`, `train_block_reason`, `next_level_xp`, `award_xp`, `security_score`, `vein_security_score`, `hq_security_score`, `weight`, `repel_weight`, `trait_mult`), `scenes/modals/guard_detail_modal.gd`, `tests/test_muscle.gd`, `data/constants.json` (`muscle.score`, `muscle.training`, level table), `.scratch/muscle/spec.md` (Levels/XP/training, Security score).

**Status:** done

- [x] Status readout returns the right kind and days left for posted, reserve, training and injured guards
- [x] Train and Post block reasons name training / injury with days left; the guard detail sheet shows them
- [x] Roster counts match a seeded roster (posted + ready + out = total)
- [x] XP progress and training-XP preview respect thresholds and Quick study / Slow learner
- [x] Score split parts sum to `score_text`'s score for HQ and a vein
- [x] Tests in `tests/test_muscle.gd`; check_all clean; full suite green
- [x] PROSE-REVIEW: the new reason strings
