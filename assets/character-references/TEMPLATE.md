# Character reference template

Per character in `assets/character-references/<Name>/`:

| File | Purpose |
|---|---|
| `<Name>_reference.png` | Master. Front view. Judge's cast reference. |
| `<Name>_side.png` | True profile, facing screen-left. |
| `<Name>_back.png` | Facing away. |
| `<Name>_spec.md` | Locked identity details (hair, face, build, outfit, signature items). Pasted into every prompt. |

## Image rules (all three views)
- Same canvas size, same pixel scale, same foot line, full body, feet visible.
- Plain flat white background, no shadow, no ground, no props, no text.
- Neutral standing, arms relaxed at sides (not in pockets), neutral expression, mouth closed.
- House pixel-art style and palette. Expressions and poses come from shot prompts, not the sheet.

## Order
1. Front = `<Name>_reference.png` (approved first).
2. Side: attach front. 3. Back: attach front (and side if drift).

## Prompt (replace <VIEW>, <SPEC>)
```
Attach: <Name>_reference.png (identity and style).
Pixel-art character turnaround, <VIEW> view of the same character. Full body, standing straight, arms relaxed at his/her sides, neutral expression, mouth closed. Plain flat white background, no shadow, no ground, no props, no text. Same pixel size, palette and proportions as the attached reference; same height and feet position in the frame.
Identity (do not change): <SPEC>.
View: <front: facing camera | side: true 90-degree profile, facing screen-left | back: facing directly away, no face visible>.
Match the attached front image exactly; only the viewing angle changes.
```

## QA before accepting
- Face matches `<Name>_reference.png`.
- Outfit details agree across views (pocket side, collar, laces, hem).
- Same height and foot line.
- Back view shows no front-facing features.
