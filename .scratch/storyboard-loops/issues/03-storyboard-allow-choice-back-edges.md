# 03 — Storyboard: allow back-edges to choice cards

**What to build:** in the storyboard tool, an option outcome or card goto may link back to an earlier choice card. Cycles are still refused unless the closing edge targets a choice card. Loop edges are visibly marked on the card graph. Play-through (Prev, picked option, visited cards) works across repeat visits and replaces the "play order loops" cap with a sensible bounded check. Each option on a choice card gets a **Reselectable** tickbox (default off) writing `reselectable: true`.

**Blocked by:** 01 — Engine: backward goto to a choice card.

**Relevant files:** `tools/storyboard.html` (`findCycle` ~1280, `guardCycle` ~1297, card/branch order guard ~1307, `setCardGoto` ~1357, branch `then` ~1366, option outcome goto ~1447, play-through history ~917, play order cap ~1147, go-to-from-end ~3158, `OPTION_KEY_ORDER` ~479), `docs/writing-guide.md`.

**Status:** ready-for-agent

- [ ] Option -> earlier choice card link accepted; same link to a non-choice card refused with the existing error
- [ ] Loop edges drawn/marked distinctly
- [ ] Play-through can go hub -> answer -> hub -> exit and Prev walks back correctly
- [ ] Reselectable tickbox on each option of a choice card, persisted in the draft, default off
- [ ] Multi-card answer chain whose last card gotos the hub works
- [ ] Hand-edited drafts that already loop for other reasons still load
