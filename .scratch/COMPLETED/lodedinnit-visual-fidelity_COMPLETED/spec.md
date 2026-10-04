# LodedInnit direction C visual fidelity

Status: ticketed

## Goal

Make the in-game LodedInnit match the **selected direction C** in `../lodedinnit/prototype-lodedinnit.html?variant=C`: B's compact People directory and profile, A's social-card Feed, and the plum/copper brand. The supplied screenshot is `current-people.png` in this directory. Compare at approximately 390 px phone width and a similar scroll position. Match composition, hierarchy, density, colours, typography, borders, and spacing; use live game data rather than the prototype's sample values or posts.

## Authority and exceptions

- `.scratch/lodedinnit-ui/spec.md` is the approved implementation spec. It overrides the prototype where they differ: Feed/People tabs **directly below the brand bar** on both tabs; Role, Ore specialism and Wage controls are all functional; no decorative `⋯` menu.
- Keep the existing game phone frame, status bar, bottom game navigation, unlock gate, state paths, and mechanics. The prototype's home indicator and external mockup switcher are presentation scaffolding.
- `docs/ui-vision.md` §10 owns the app-specific exception; `docs/REFERENCE.md` §2 and §3.10 own state, hiring and numbers. `docs/CONTENT-GUIDE.md` owns any new copy. Prototype names, prices, posts and copy are presentation examples, not canonical content.

## Visual contract

- App surface `#252528`; branded bar near `#3c3042`; plum `#81549a`; light plum `#dab8eb`; copper `#dda477`; primary ink near `#ededee`; secondary ink near `#999a9d`; rules near `#424246`. Use `data/palette.json` tokens for the three brand colours. Copper marks weekly wage/price, not every fact.
- Main app content uses compact sans typography, dark cards/sections, and subtle grey hairlines. No inherited amber buttons or near-black text inside this dark app.
- Full candidate and feed content must remain legible and usable at narrow phone width. Scrolling remains functional without a conspicuous visible scrollbar.
- Every ticket includes headless Godot 4.7 checks plus a short on-device comparison against direction C. The human performs visual QA.

## Tickets

1. Shared brand, ink and tab chrome — unblocks the three content surfaces.
2. People directory and controls — blocked by 01.
3. Feed social cards — blocked by 01.
4. Profile and hire surface — blocked by 01.

Tickets 02–04 have no dependency on one another. Each must land as a complete, demoable screen with working interactions.
