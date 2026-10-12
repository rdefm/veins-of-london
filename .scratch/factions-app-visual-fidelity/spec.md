# The Register — visual fidelity pass

Status: approved for tickets (2026-10-12)

The [interactive mockup](../factions-app-redesign/mockup.html) is the visual reference. The [approved app spec](../playtest-2026-10-04/factions-app-spec.md) governs content and behaviour. Mockup figures, scenarios and incidental prose are illustrative; use live game state and existing mechanics.

The [first four implementation tickets](../factions-app-redesign/spec.md) are complete. This pass addresses the remaining presentation gap: the live app still inherits shared phone cards, buttons and labels in places where the mockup has its own dark Register styling. Scope app-specific styling to The Register so other phone apps keep their current appearance.

## Tickets

1. [Register shell and home](issues/01-register-shell-and-home.md)
2. [Dossier styling](issues/02-dossier-styling.md)
3. [London politics styling](issues/03-london-politics-styling.md)
4. [Market shares styling](issues/04-market-shares-styling.md)

Ticket 01 establishes the visual shell. Tickets 02–04 each depend on it and can then proceed independently.

## Shared acceptance

- Compare all four in-game views against the mockup at phone width, including a narrow viewport. Preserve the shared device frame and status bar.
- Preserve faction colours for identity, ore glyphs for ore identity, neutral ink for relation meters, and oxide orange for Register actions, selected controls and share fills.
- Preserve every existing value, gate, action effect, route and intel threshold. The mockup is not a source for mechanics or sample data.
- Run Godot 4.7 syntax checks for touched GDScript and the full test suite. Include phone screenshots or exact on-device visual checks in each implementation report.
