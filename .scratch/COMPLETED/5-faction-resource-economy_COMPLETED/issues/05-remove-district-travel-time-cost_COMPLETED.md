# 05 — Remove district travel time cost

**Note:** unrelated to the faction resource economy PRD above — filed in this folder at explicit user request rather than its own feature folder.

**What to build:** Remove the extra time-block charge for acting outside the player's current district. Today, per `docs/M1-LONDON.md` "D3 — Travel (the one rule)", every districted action (prospect, seed, cultivate, harvest) targeting a district ≠ `state.world.currentDistrict` first consumes 1 extra block as travel (`Travel.ensure_district()`, `systems/travel.gd`), on top of the action's own block — shown in UI as e.g. "Harvest — 2 blocks (travel)" (`UI.block_cost_suffix`/`format_block_cost_label`, `scenes/components/ui.gd`). After this ticket, acting in a non-current district costs the same as acting in the current one — no surcharge. Selling is already unaffected today (it doesn't call `Travel` at all — no change needed there).

Because `docs/M1-LONDON.md` D3 is the canonical spec for this rule (per this project's constitution, code and docs must not diverge), update that section in the same change — don't leave the doc describing a charge the code no longer applies.

**Blocked by:** None — independent of the faction-resource-economy chain above, can land anytime

**Status:** ready-for-agent

- [ ] `Travel.blocks_needed()` no longer returns a nonzero travel surcharge for a cross-district target — moving to, or acting in, a different district costs the same blocks as acting in the current one.
- [ ] `Travel.ensure_district()` still sets `state.world.currentDistrict` to the acted-on district (that bookkeeping is unrelated to cost and stays), it just no longer spends an extra block to do so.
- [ ] The standalone Map tab "Travel" button (`Travel.travel_to()`) either becomes a free (0-block) district switch, or is removed as a distinct affordance if travel is no longer meaningfully separate from just acting in a district — implementer's call, document the reasoning.
- [ ] UI cost labels (`UI.block_cost_suffix` / `format_block_cost_label`, and any call sites in `scenes/screens/map.gd`) stop appending "(travel)" / the extra block — labels show the action's true (now unchanged-by-district) cost.
- [ ] `docs/M1-LONDON.md` D3 updated to describe the new no-surcharge rule, so the doc and code agree.
- [ ] `state.world.currentDistrict` still resets to home (`"shoreditch"`) on new day / rest — unchanged, unrelated to cost.
- [ ] Tests (`tests/test_travel.gd` and any cross-district assertions in `tests/test_cultivating.gd` / `tests/test_sites.gd`) updated to reflect free cross-district action costs.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes.

Human visual QA note: on-device, confirm a Cultivate/Harvest/Seed/Prospect button for a site in a district you're not currently in shows the same block cost as one in your current district, and no leftover "(travel)" text appears anywhere.
