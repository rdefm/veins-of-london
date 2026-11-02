# 13 — Root Feed + Good Year (cultivation boosts)

**What to build:** Used on one owned vein, via the targeting pattern decided in 12. Root Feed gives +1 growth step per day for N days. Good Year makes prune and harvest yields roll as if the terroir tier were one higher, for N days. Both go through the Cultivating daily tick (brainstorm §3.2, §4).

**Blocked by:** 12

**Relevant files:** `systems/cultivating.gd`, `systems/vein_list.gd`, `data/vein_growth.json`, `tests/test_cultivating.gd`; REFERENCE §3.4 Cultivating & pruning, §2.1 Vein dict.

**Status:** needs-info

- [ ] Boost state stored on the vein as pure data (`vein.boosts`)
- [ ] Effects apply only for the tier's days and then expire; tests at day boundaries
