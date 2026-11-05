# Test card keys

Tests address event cards by raw index (`CHOICE_CARD := 12`, `seen.has(10)`, `cardIndex == N`), so inserting a card breaks them, and unbounded "advance until card N" loops hang the suite instead of failing. Cards already carry a stable `key`. Move tests onto keys, with capped walk helpers, and guard against regressions. Expand–migrate–contract: 01 adds the helpers, 02-04 migrate, 05 guards.
