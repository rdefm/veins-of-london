# 07 — Lab bench: ore containers, selection, arming rule, both craft paths

**What to build:** The full craft flow on the bench, replacing `lab.gd`'s
picker→pairing→confirm entirely. Five ore containers at the ore stop, one
per type, each with three visual states (empty/some/plenty) driven by
count. Tap-to-select-then-tap-apparatus is the primary path; drag-and-drop
is a flourish that does the same thing, never the only route. A selected
ore chip communicates the cost it will incur. In crafting mode, an
apparatus only lights up when the current selection resolves to a known
recipe on that approach (`discovery: {types, approach}` from
`data/recipes.json`) — unknown combos are inert, no error, no ore spent. In
Experiments mode any legal selection arms any known approach, and the
Experiments notebook shows pairings already tried plus current recipe
levels — never an enumeration of all 15 type sets (`M3-CALC-DISCOVERY.md`
§8.0). Recipes mode supports both the book path (pick a known recipe +
quantity, ore stop becomes a receipt) and the manual path (select ore,
arrow to apparatus, craft quantity 1). Refine stays a book-page action, not
a fifth apparatus.

**Blocked by:** 06

**Status:** ready-for-agent

- [ ] Five ore containers with correct empty/some/plenty visual state per count
- [ ] Tap-to-select-then-tap-apparatus works as the always-available path
- [ ] Drag-and-drop performs the same selection, never required
- [ ] Selected ore chip shows the cost it will incur (probe cost or recipe ingredients)
- [ ] Crafting-mode apparatus lights up only for known recipes on that approach; unknown selections are inert with no side effects
- [ ] Experiments mode arms any known approach for any legal selection; notebook shows tried pairings + recipe levels, never a full type-set list
- [ ] Recipes book path: pick known recipe + quantity, ore stop is a receipt
- [ ] Recipes manual path: select ore, arrow to matching apparatus, craft quantity 1
- [ ] Refine remains a recipe-page action in the book, not a new apparatus
- [ ] Underlying crafting/bench/approach system calls and costs are unchanged
