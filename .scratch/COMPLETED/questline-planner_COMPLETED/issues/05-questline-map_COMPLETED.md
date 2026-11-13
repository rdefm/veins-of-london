# 05 — Read-only questline map

**What to build:** opening a questline shows its quests as an automatically laid-out, top-to-bottom map, identical on every device.

- Layout: each quest's layer comes from its longest follows path, branches sit side by side, converging quests sit below their branches, and choice forks are marked.
- Nodes show the title, a state badge (◌ placeholder, ⚙ hard-coded, ● data-driven), four status pips, and the first event id plus "+N" for the others.
- Edges: parallel edges are solid. Choice edges are drawn as a forked/dashed fork with their label.
- A quest that follows a quest in another questline shows a "from <questline> ▸" stub at the top, and tapping the stub opens that questline.
- A wide map scrolls horizontally inside the map container only.
- Toolbar: the questline name, roll-ups, a "+ Quest" placeholder (wired in 07), and a filter that highlights quests where a chosen status category isn't done.

Layering, roll-ups and the filter are pure planning-model functions.

Gating marker decision (2026-11-13): the "⚙ extra gating" edge marker (spec story 21) is deferred to the quest-editor spec, because phase-1 planning data has no gating to show.

**Mockup:** https://claude.ai/artifact/2iHxNhNundq3VL5EiGMmvv, saved copy in `.scratch/questline-planner/mockup/` (see its README). Artboards: `QuestMap.dc.html` (node anatomy, edge styles, choice labels, stub, filter highlight/dim), `PhoneMap.dc.html` (phone toolbar, map box, legend), `Laptop.dc.html` (wide toolbar in one row). Build to match the mockup's layout, labels, controls and styling. Its quest content is sample data.

**Blocked by:** 04 — Quests tab: planning files and questline list.

**Relevant files:** `tools/storyboard.html` (planning-model section; existing flowchart SVG rendering, `buildGraph`/`placeLayout`, as reference only, since the map auto-lays out with no saved positions), `tools/test_storyboard.js`, `.scratch/questline-planner/spec.md` (§ The map, § Quests tab UI).

**Status:** ready-for-agent

- [ ] Human check: Map, nodes, edges, toolbar and filter match the mockup
- [ ] Node tests: layers for chains, parallel forks, choice forks, converges, and cross-questline follows; the category-not-done filter
- [ ] Stub tap opens the other questline
- [ ] Human check (phone and laptop): a hand-written test questline shows the same layout on both, the map scrolls sideways inside its box only, choice labels are legible, and the filter highlights the right nodes
