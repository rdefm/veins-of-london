# 102 — Experiments notebook: refine a known recipe with one tap

**What to build:** In the lab bench's Experiments notebook, each already-discovered recipe row gets an "experiment" / "refine to next level" action button. Tapping it on a known recipe immediately runs the next-level experiment using that recipe's already-established ore + apparatus combo — no picker, no extra steps. This is purely for recipes already discovered; starting an experiment for a recipe not yet discovered is out of scope here (see #109 — that flow is currently broken and being diagnosed separately).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Every discovered recipe row in the Experiments notebook shows an "experiment"/"refine" button.
- [ ] Tapping that button on a known recipe runs the next-level experiment immediately, using the recipe's established ore + apparatus combo, with no intermediate picker.
- [ ] The existing read-only recipe/pairings-tried information in the notebook is preserved alongside the new button.
- [ ] A recipe already at max level does not show a refine button that does nothing (either hidden, or disabled with a reason).
- [ ] Test coverage for the new auto-run path.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file.
- [ ] Manual check noted for the human: open the Experiments notebook with at least one discovered recipe, tap its refine button, confirm the experiment runs and the result is reflected without any picker appearing.
