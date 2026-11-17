# Art style LoRA: trained style and character models (Phase 3)

Status: needs-info

Blocked by:
- the agreement gate in `.scratch/art-judge/spec.md` (the judge must be trustworthy to measure a LoRA), and
- evidence of a style ceiling: across the Phase 1 benchmark and the Phase 2 bake-off, judge style or character scores stay below the pass threshold for the best off-the-shelf backend.
Move to `ready-for-agent` only when both are met.

## Problem Statement

Reference-image generators (ChatGPT, and the APIs in Phase 2) treat the house style and the cast's look as hints, re-read every time from a few attached images. If they keep sliding toward smooth, anti-aliased, generic "AI pixel art", or redraw faces differently each time, then judging and retrying only filter a low hit-rate; they don't raise it. The style and the cast need to be built into the generator itself.

## Solution

Train small add-on models (LoRAs) on the game's own approved art:
- one **style LoRA** trained on approved event cards and plates;
- one **character LoRA** for each main cast member who appears often, trained on their master reference plus their approved drafts.

Use them as another image backend in the Phase 2 loop. Check them with the Phase 1 judge on the same benchmark shots, against the Phase 2 default backend, and adopt them only if they beat it.

## User Stories

1. As the art director, I want a training set built from approved art only (approved drafts, plates, master references), with captions, so that the model learns my current best style, not rejected attempts.
2. As the art director, I want to review and remove images from a training set before training, so that one off-model image doesn't get trained in.
3. As the art director, I want a minimum set size enforced (proposed: 20 images for style, 15 per character), so that undertrained LoRAs aren't produced and wrongly judged.
4. As the art director, I want one style LoRA and per-character LoRAs for the main cast, so that style and identity can be strengthened or weakened separately.
5. As the art director, I want the LoRA-backed generator exposed as a Phase 2 image backend, so that the same loop, judge, caps and review flow apply.
6. As the art director, I want the LoRA backend compared against the current default on the benchmark shots and scored by the judge, so that adopting it is based on evidence.
7. As the art director, I want trained LoRAs versioned with their training set and settings recorded, so that a regression can be traced and rolled back.
8. As the art director, I want retraining to be a deliberate, manual step after enough new approved art builds up, so that cost and drift stay under my control.
9. As the art director, I want the training cost and the per-image generation cost reported, so that I can compare total cost with Phase 2's default.
10. As the art director, I want training data and LoRA weights kept out of the public repo, so that the art set and models aren't published by accident.
11. As the art director, I want a character LoRA to be possible only for cast who have a master reference, so that new canon is never trained in.

## Implementation Decisions

- **First ticket is research/prototype, not build:**
  - choose the base model (Flux family or Qwen-Image are the leading candidates for pixel-art LoRAs);
  - choose where training runs (hosted training through fal or Replicate, or local ComfyUI if the user's GPU can handle it, which is currently unknown);
  - train one style LoRA on the existing approved art;
  - run it through the Phase 2 bake-off harness.
  The result decides whether character LoRAs are worth doing.
- **Dataset builder**: collects approved images from boards and feedback, crops and resizes them to the base model's training size, and writes captions. Captions describe content, not style, so the style is absorbed by the LoRA. It writes a dataset manifest; the images themselves go to a git-ignored location.
- **LoRA backend**: implements Phase 2's image backend interface. Supports a configured LoRA strength per style and per character, and combining them in one generation.
- **Registry**: a small, tracked file listing each LoRA's version, base model, dataset manifest hash, settings, storage location (outside the repo) and benchmark result.

## Testing Decisions

- Outward behaviour only. The dataset builder is tested at its CLI with fixture boards/feedback and fixture PNGs: only approved images are included, captions are written, minimum sizes are enforced, cast without a reference are refused, nothing is written into tracked asset folders.
- The LoRA backend is tested through the Phase 2 orchestrator seam with the fake backend recording that LoRA settings were passed through. Real training and inference are manual experiments, recorded in the registry.
- Prior art: Phase 1 judge CLI suite and Phase 2 orchestrator suite.

## Out of Scope

- Training for any asset class other than event cards and plates (combat sprites, HQ rooms, UI) until event art proves the approach.
- Automatic retraining.
- Fine-tuning full models.
- Hosting or sharing LoRAs publicly.

## Further Notes

- About 20–40 approved images is the usual minimum for a usable style LoRA. Phase 1 and 2 are also what produce that approved set.
- The user's machine is Windows 10 Home with an unknown GPU. Check whether it can do local training before choosing between local and hosted.
- Base model licences differ, some limiting commercial use. Check the licence of the chosen base model before anything shipped is generated with it.
