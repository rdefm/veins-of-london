# Prompts — plates, then shots

The user generates in ChatGPT by hand, then runs the plate compositor (`tools/plate_compositor/README.md`). Every prompt on the board is copy-paste ready and names its attachments by exact file name. `prompts.md` is the approved board's prompts in generation order, nothing more.

## prompts.md structure

```
# <eventId> prompt pack (board round N)

## P1 — <plate name> (blank plate; used by S1, S3, S5)
Attach: <files>
<plate prompt>
Save as: assets/reference-plates/<name>_blank_plate.png   (upload on the plate's card)

## P1b — <variant name> (variant of P1; used by …)
…

## S1 — <title> (cards 1–2) · plate P1 · pose
Attach: <files>
<shot prompt>
Save as: <shot saveAs>   (upload on the shot's card; raw ChatGPT output → extract.py; not the card file)

## Delta prompts (filled in during draft review)
```

- **One ChatGPT conversation per plate.** Its shots go in the same conversation, after the plate.
- **Style anchor** (plate prompts only): one shipped event image from the neighbouring event in the chain, else `assets/events/col_a1_intro/col_a1_intro_card1.png`. Say "match its pixel-art technique and colour treatment, not its content".
- **Character refs:** the `*_biz_sprite_master.png` for everyone added. Once a shot of a character is approved, attach that draft too for later shots.
- **Props with game art:** attach it (crafted items: the `icon` in `data/recipes.json`).

## House lines (every plate prompt carries these)

```
Genuine pixel art: visible pixel grid with roughly 5×5 screen pixels per art
pixel, limited palette, dithered shading, crisp hard edges, no anti-aliasing, no
painterly blur, no vector/cel-shaded linework.
Grounded, realistic London colour: brick, shopfront paint, wet pavement, sodium
and LED light. Vivid where the real city is, restrained elsewhere. No neon, no
fantasy glow.
Portrait 2:3 (1024×1536), full-bleed, no border. No people, not even distant
background figures (extras are added per shot). No text, letters,
numbers or logos unless vital to the scene (then give the exact words): signs,
number plates, screens and paper show shapes only.
Keep the floor area clear in the middle of the frame where people will stand;
the top and bottom 15% may be cropped, so only sky/ceiling/floor goes there.
```

## Plate prompt

```
Attach: <style anchor>.
A blank background plate for a pixel-art game scene: <location>, <time, weather>.
Camera: <position, height, lens feel, where it looks>.
Set: <foreground / midground / background, screen-left / screen-right landmarks>.
Light: <each source, its side, colour>.
<house lines>
```

## Shot prompt (pose)

```
Attach: <plate>_blank_plate.png, <Name>_biz_sprite_master.png[, prop art].
Using the room in <plate>_blank_plate.png, add <who> <where, by plate landmark>,
<pose>, <gaze/expression>, <props>. <Second character…>
Same pixel-art style and scale as the room. Change nothing else in the room.
Keep the exact image size.
```

Ask for 3–4 variations; pick one; cut out with `extract.py`.

## Delta prompt (draft revision)

```
Same image, change only: <specific changes>. Keep everything else identical.
```
