# 05 — Beats 1–2: proposition and market proof

**What to build:** The ToDo "Business Empire" section becomes a live questline. When the player holds two veins (whatever their Collective progress, Archie recruited), Archie texts a proposition that leads into a scene where he takes the player to James, who demands proof of a reliable market and a serious investment. Archie can now take the Sales role. Beat 2 tracks fully completed BizBrief contracts (target 3; earlier completions count) while Archie feeds a chain of reliable starter offers, one at a time, reissuing a day later if one expires or is declined.

**Blocked by:** 01 — Founder roles, skill caps, Owen roster, save fix-ups

**Relevant files:** `systems/objectives.gd`, `systems/todo.gd` (`business_empire` placeholder), `systems/offers.gd` (`create_scripted_offer`, `daily_tick`, `expire_pending_offers`, `decline_offer`), `systems/messages.gd` (`queue_pending`), `systems/collective.gd` (trigger/backstop prior art), vein-count change points (`systems/sites.gd`, `systems/vein_trade.gd`, event completion, self-seed), `data/objectives.json`, `data/offers.json`, `data/events/`, `tests/test_objectives.gd`, `tests/test_todo.gd`, `tests/test_offers.gd`, `tests/test_collective.gd`; `docs/CONTENT-GUIDE.md`, `docs/CHARACTER-VOICE-GUIDE.md`, `docs/biz-act1-vision.md`; spec §"Questline and objectives", §"Starter and recurring offer catalogue".

**Status:** ready-for-agent

- [ ] `business_empire` questline replaces the ToDo placeholder
- [ ] Beat 1 trigger: ≥ 2 veins AND Archie recruited, independent of Collective; checked after any vein-count change and at rollover as backstop; permanent flag blocks re-fire
- [ ] Archie text via `Messages.queue_pending` → Beat 1 scene. Prose doesn't assume where the second vein came from; hourglass is an ordinary object; no Guild contracts/invitation/Dial reveal; mentions James keeps his side business
- [ ] Archie's Sales role available from Beat 2
- [ ] Beat 2 evaluator: live count of `settlement.complete == true` in `sales.contractHistory`; target 3; a completed recurring period counts as one
- [ ] ToDo shows progress toward 3
- [ ] Templates `biz_starter_1` (time ore ×4), `biz_starter_2` (timePearl ×3), `biz_starter_3` (life ore ×5), authored expiry/deadline, quote formula unchanged
- [ ] Starter chain: exactly one outstanding while Beat 2 unmet; next (or reissue) created one day after previous offer/contract closes; bypasses random roll and its slot; stops once Beat 2 met by any source
- [ ] Tests: Beat 1 fires at two veins with no Collective progress; three prior completions satisfy Beat 2 instantly; expired starter reissues after one day
- [ ] New prose flagged `PROSE-REVIEW:`; CODEMAP.md updated
