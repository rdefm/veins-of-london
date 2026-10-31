# 02 — Promote accepts "return" links

**What to build:** the storyboard tool (and `tools/promote_storyboard.js`, which runs the same code) can promote an event that sends play back to "where you were" after a detour — the raid pattern where every fight ends at a shared resume card whose conditional `then` dispatches on `sAt_*` flags back to the place the fight interrupted.

Today promote refuses these drafts: the loop check only permits a loop that closes on a choice card in walk order (so it can fail on a tension card like `s_resume` depending on DFS order), and any permitted back-edge is treated as a hub that must carry an `exit: true` option (`b5 · s_till: hub has no exit option`). raid_shop's middle is one 39-card strongly connected component through `s_resume`/`s_resume2`, so it can't be promoted at all; its live file has been hand-maintained.

Rule to implement:

- A **return link** is an entry of a branch's conditional `then` that targets a **choice** card which can reach the card carrying that `then` (i.e. it points back).
- Return links don't count as hubs: no exit option required on the target.
- The loop check ignores return links; every other edge must still form an acyclic graph (true loops not through a return link are still refused, as are hub rules for genuine hubs).
- A return link to a non-choice card is refused with a message naming the branch, the entry's condition and the target (the engine only allows backward gotos to choice cards).
- Promote lays out the non-return graph topologically as today and emits return links as backward card-key gotos in the conditional `goto` list. The engine already runs these as hub returns (drops choiceResults / jumps / toggles from the target on) — behaviour matches today's hand-maintained raid_shop.
- The tool's live loop guard (`guardCycle`) uses the same rule, so authoring a return link in the editor isn't blocked.

Known risk: this loosens the static loop check — a return that can repeat forever (e.g. a fight whose resume lands back on the same un-changed gate) passes promote. Note it in the spec; don't add a new lint for it in this ticket.

**Blocked by:** None — can start immediately

**Relevant files:**
- `tools/storyboard.html` — Draft model section: `findCycle`, `hasCycle`, `guardCycle`, `promoteDraft` (reach/back-edge walk, hub-exit check), `successors`, `resolveTarget`
- `tools/promote_storyboard.js`
- `tools/test_storyboard.js`
- `.scratch/COMPLETED/storyboard-editor_COMPLETED/spec.md` § Draft format
- `.scratch/COMPLETED/storyboard-loops_COMPLETED/issues/` (prior hub/back-edge decisions)
- `.claude/skills/implement-storyboard-event/SKILL.md` (§ 2 refusal list mentions `play can loop` / `hub has no forward exit`)
- `docs/REFERENCE.md` §3.9a "Goto"
- `.scratch/writing-revamp/raid-shop-proposal.md` (real-world fixture)

**Status:** ready-for-agent

- [ ] A draft with a conditional `then` returning to an earlier choice card (no exit option) promotes; output has a backward key goto in the card's conditional `goto`
- [ ] A loop that doesn't pass through a return link is still refused with `play can loop`
- [ ] A return link to a non-choice card is refused with a message naming branch, condition and target
- [ ] Genuine hubs (option `goto` back to a choice card) keep today's exit-option rule
- [ ] The editor's loop guard accepts authoring a return link
- [ ] Test-promoting `raid-shop-proposal.md` (to `--out` in a scratch path) gets past the loop/hub checks; any remaining refusal is a real content issue for ticket 03
- [ ] Spec § Draft format and the implement-storyboard-event skill's refusal list describe return links
