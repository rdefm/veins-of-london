# 13 — Tutorial/quest prose patch

**What to build:** Tutorial/quest text explains that terroir determines a vein's maximum level (so the routine `Lv 2/4` display and filled/empty segments are self-explanatory afterward), condition's neutral 50, the 90+ development zone, how a streak gets interrupted, and the harvest-now-vs-develop-later tradeoff. Existing tutorial prose is patched per CONTENT-GUIDE.md rules (light patch, not a rewrite) rather than rewritten from scratch.

**Blocked by:** 09, 10, 11, 12 (prose should describe the UI as it actually shipped).

**Relevant files:**
- Existing tutorial/quest event JSON under `data/events/` (identify the specific tutorial-day files touching vein mechanics during implementation)
- `docs/CONTENT-GUIDE.md` (patch rules, tone bible)

**Status:** ready-for-agent

- [ ] Terroir-determines-max-level is explained once, early, so subsequent `Lv n/max` displays need no further label
- [ ] Condition's neutral 50, the 90+ zone, streak interruption, and the harvest-now/develop-later tradeoff are all explained
- [ ] Existing tutorial prose is patched, not rewritten, per CONTENT-GUIDE.md
- [ ] PROSE-REVIEW: this entire ticket's output, per project convention for new/patched prose
