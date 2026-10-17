# 08 — Slice B: fog, hints and experimenting

**What to build:** Chart knowledge and discovery.
- **Fog:** regions the player hasn't found are fogged. Fog clears along the marker's path, and bottling anywhere inside an unfound region reveals it.
- **Hints:** the debug hint toggles from 01 grant Chart hints. Vague shows a fuzzy cloud near the bullseye. Exact marks the bullseye, or reveals an authored route segment.
- **Sharpening:** landing inside the fuzzy cloud 3 times sharpens it to exact.

Fog and knowledge state persist in the Chart slice, and Rewind rolls them back. See spec §Slice B "Knowledge" and "Experimenting".

**Blocked by:** 07 — Slice B: apparatus transforms.

**Relevant files:** `.scratch/lab-revamp/spec.md` §Slice B; chart system/screen/data/tests from 06–07.

**Status:** ready-for-agent

- [ ] Fog-cleared cells and found regions are stored as pure data. The trail clears fog, and bottling inside reveals the region.
- [ ] Vague clouds (always containing the bullseye) and exact markers/route segments are authored in data for all 3 recipes.
- [ ] Cloud landings ×3 → exact is tested. Rewind undoes it.
- [ ] Human check list: does discovery feel earned? Compare with Slice A.
