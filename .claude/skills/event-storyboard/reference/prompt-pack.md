# prompts.md — the ChatGPT prompt pack

The user generates in ChatGPT by hand, so the pack must be copy-paste ready and explicit about attachments.

## Structure

```
# <eventId> prompt pack (board round N)

## Conversation A — <set name> (shots S1, S2, S4)
Attach: <style anchor>, <character refs…>
### A0 — style + cast primer (send first, once)
<primer>
### S1 — <title> (cards 1–2)
<shot prompt>
### S2 — …
## Conversation B — <set name> (…)
…
## Delta prompts (filled in during draft review)
```

- **One conversation per set/location.** Shots that share a location share a conversation, so the model keeps the set. Generate the widest shot of a set first; it defines the set for the rest.
- **Style anchor:** attach one existing shipped event image (best: from the neighbouring event in the same chain, else `assets/events/col_a1_intro/col_a1_intro_card1.png`) as "match this pixel-art technique and colour treatment, not its content".
- **Character refs:** attach `assets/character-references/<Name>/*.png` for everyone on screen. Once a shot of a character is approved, attach that draft as well for later shots.
- Order shots in a conversation by dependency, not card order, when a later card's shot establishes the set.

## Primer (A0)

```
We're making a sequence of still images for one scene of a pixel-art game set in
contemporary London. Every image in this conversation is the same scene and must
keep the same location, light, and characters.

Technique: genuine pixel art: visible pixel grid with roughly 4×4 screen pixels
per art pixel, limited palette, dithered shading, crisp hard edges, no
anti-aliasing, no painterly blur, no vector/cel-shaded linework. Match the
technique and colour treatment of the attached style image, not its content.
Mood: grounded, realistic London colour: brick, shopfront paint, wet pavement,
sodium and LED light. Vivid where the real city is, restrained elsewhere. No neon,
no fantasy glow.
Format: portrait 2:3 (1024×1536), full-bleed scene, no border, no text, no
logos, no UI, no captions. Any signs, screens, or paper show shapes, not letters.
Cast (attached references; keep faces, hair, build and clothes exactly):
- <Name>: <one-line visual summary from the reference>
The viewer ("you") never shows their face: off-camera, or from behind/partial.
Set: <location, time of day, weather, key light direction>.
Reply "ready". Don't generate yet.
```

## Shot prompt

```
Shot <id>: <framing, e.g. "medium close-up, eye level, slight low angle">.
Moment: <the frozen instant: who is doing what, gaze, expression>.
Composition: <foreground / midground / background; who is screen-left/right>.
Keep the faces, hands and <story prop> in the central area; the top and bottom
15% may be cropped, so put only sky/floor/set dressing there.
Not visible: <what must stay unseen>.
Light: <same as primer, or what changes>.
Same technique, palette and characters as before. Portrait 2:3.
```

## Delta prompt (draft revision)

```
Same image, change only: <specific changes>. Keep composition, characters,
light and pixel technique identical.
```

Keep prompts short. Image models follow the first few concrete constraints best and drift on long lists.
