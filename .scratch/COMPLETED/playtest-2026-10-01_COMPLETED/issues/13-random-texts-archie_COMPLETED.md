# 13 — Random texts: Archie

**What to build:** Archie sends occasional random texts via the general contact-texts system: humorous, character-revealing, endearing — the same feel as Owen's. ~8–12 texts, each with reply choices; some replies grant a small reward suited to him (relation, small cash, a sales tip). Availability gate: only once Archie is met; pause while unavailable. Must not collide with his deal texts (ticket 03 flow). Interval chosen so contacts don't crowd each other.

**Blocked by:** 11 — Generalise Owen's random texts.

**Relevant files:** generalised texts system + data from 11, `data/owen_texts.json` (tone reference), `docs/CONTENT-GUIDE.md`, `reference/london-orichalchum.html` (Archie's voice), `systems/archie_deals.gd`, `systems/contacts.gd`, CONTEXT.md.

**Status:** ready-for-agent

- [ ] Text pool + config for Archie; tests for gate and reward grants
- [ ] Tone per CONTENT-GUIDE: one dry line, no camera winks
- [ ] PROSE-REVIEW: all new Archie text
