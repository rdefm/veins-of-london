# 05 — Relaxed per-character stances

**What to build:** Replace the identical symmetric stance with per-character rest poses in `characters.py` config: elbows slightly bent, hands not mirror images, feet apart / one foot forward (contrapposto). Knife: wider, aggressive stance; mate: lean/weight on one leg; James: hands-in-pockets or loose; Archie: casual, bag hand relaxed. Kit reads stance overrides (rest hand targets, leg stance offsets) from config; regenerate all rigs.

**Blocked by:** 04 (tweens generated from final poses)

**Relevant files:** `tools/stage_art/characters.py`, `tools/stage_art/char_kit.py` (`POSE_L/R`, `legs_canvas`, `arm_pose`), build scripts, ENGINE.md

**Status:** ready-for-agent

- [ ] Each buyer reads as a different silhouette in a still frame (screenshot harness, human QA)
- [ ] All stage tests pass after regen
