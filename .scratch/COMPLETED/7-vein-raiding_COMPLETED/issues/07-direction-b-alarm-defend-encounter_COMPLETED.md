# 07 — Direction B: alarm defend encounter

**What to build:** Layer the alarm upgrade (ticket 05) onto ticket 06's raid-trigger resolution as the one case with player agency. When a vein selected for a Direction-B raid attempt has the alarm upgrade, don't resolve automatically off-screen: push a notification and let the player travel to that district (standard travel rules — normal 1 time-block cost for a different district, no separate countdown system) to trigger a **defend encounter**, a new combat context (new `combat.context` value, e.g. `"defend_vein"`, alongside existing `"raid"`/`"home_raid"`, reusing `Combat`'s `_start_combat`/outcome-handling machinery). Player arrives in time → defend combat: win = raid repelled, vein stays with the player, unchanged; lose = vein lost, same whole-vein-loss outcome as ticket 06's default path. If the player doesn't travel there before the raid attempt would otherwise resolve (or the vein has no alarm), it falls through to ticket 06's existing off-screen resolution unchanged.

**Blocked by:** 05, 06

**Status:** ready-for-agent

- [ ] Direction-B raid attempts against an alarmed vein push a notification and open a travel window instead of resolving immediately off-screen
- [ ] Travelling to the target district within that window triggers a defend combat (new combat context, reusing existing `Combat` start/outcome machinery — no bespoke combat system)
- [ ] Winning the defend combat leaves the vein with the player, fully unchanged
- [ ] Losing the defend combat produces the same whole-vein-loss outcome as ticket 06's default path (ownership converts to the attacking faction)
- [ ] Missing the travel window, or a vein with no alarm upgrade, falls through to ticket 06's existing off-screen auto-resolve unchanged
- [ ] Player is notified afterward in both cases (resolved off-screen, or after a defend-encounter loss) — win requires no separate notification beyond the initial alert (PRD: no decided positive-consequence-beyond-safety for a win)
- [ ] Tests cover: alarmed vein raid attempt does not auto-resolve immediately; travelling in time starts the defend combat; win preserves the vein; loss transfers it exactly as the no-alarm path would; missing the window falls through to auto-resolve
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes
