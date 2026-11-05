# Test UI strings

Three test_modal_layer cases fail because authoring-04 reworded the HQ ore-readout rows ("shared N / stashed M" -> "Shared N / Stash M") and the tests assert the literal old text. Tests should not depend on hardcoded display strings: the UI exposes its text from one source (a format helper or data) and tests read that source or assert on structure/state instead.
