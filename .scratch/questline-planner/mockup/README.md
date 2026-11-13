# Questline planner — mockup

Live canvas: https://claude.ai/artifact/2iHxNhNundq3VL5EiGMmvv (private to the author; open it there to see it rendered).

This folder is a saved copy of the canvas's source, made 2026-11-13. Each `.dc.html` file is one artboard. They only render on the canvas, which supplies `support.js`, so read them here as markup: layout, labels, order and styling.

## What to match

The tickets in `../issues/` must build UI that matches these artboards. That means:

- layout and section order
- control labels and which controls exist
- node anatomy
- edge styles
- status pip shapes
- touch-target sizes (44px minimum)
- palette tokens (the storyboard's `:root` light/dark set)

Quest names, ids, statuses, counts, summaries and notes are sample data. Don't copy them into code or data.

## Artboards

| Artboard | Shows | Tickets |
|---|---|---|
| `Main.dc.html` | Phone questline list: grouped by ToDo page, rows with quest count and W/C/O/A roll-up bars, last-opened row outlined, "+ Questline", header save indicator, Quests tab beside the other tabs | 03, 04 |
| `PhoneMap.dc.html` | Phone map screen: "‹ Questlines", act name and page/act/count line, "+ Quest", roll-up pills, "Highlight not done" select, map scrolling inside its box, legend footer | 04, 05 |
| `QuestMap.dc.html` | The map itself. Nodes 156×92: badge + 2-line title, W/C/O/A pips, first event id "+N". Solid parallel edges, dashed accent choice edges with pill labels, dotted cross-questline stub. Filter: highlight = accent ring, done/n/a = dimmed. Selected = fg ring | 05 |
| `QuestSheet.dc.html` | Quest sheet content in spec order: title + id (lock when fixed), Summary, Events, Flow, Mechanics, Status (2×2 tiles), Notes | 06, 07, 08 |
| `PhoneSheet.dc.html` | Bottom sheet on phone: grabber, ✕, dimmed map behind, sheet scrolls | 06 |
| `Laptop.dc.html` | Wide screen, dark mode: header, tabs, toolbar in one row, map left, 400px side panel right | 03, 05, 06 |
| `States.dc.html` | "+ Branch" dialog, long-press status picker, "Follows…" multi-select (loop rows disabled as "would loop", other questlines listed separately), delete warning naming the reattach target, save indicator states, conflict banner with the unsaved change, server terminal output | 02, 04, 06, 07 |

Status pip shapes: todo = empty ring, doing = half-filled (accent), review = dot in ring (hold), done = solid (ok), n/a = dotted faded ring.
