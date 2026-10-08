"""Cut a character out of an AI image that was generated on top of a blank plate.

Usage (from repo root):
    python tools/plate_compositor/extract.py tools/plate_compositor/poses/<pose>.json [--sheet]

The AI output drifts the whole background a little, so the cut keeps only pixels that
(a) sit inside the pose's rough `region` and (b) differ clearly from the true plate, then
cleans the mask (denoise, close gaps, largest connected shape, fill holes). The cut-out is
saved plate-sized and transparent, so its position in the room is built in.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def region_mask(size: tuple[int, int], region: dict) -> np.ndarray:
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    if "rect" in region:
        d.rectangle(region["rect"], fill=255)
    else:
        d.polygon([tuple(p) for p in region["polygon"]], fill=255)
    return np.asarray(m) > 0


def best_shift(plate: np.ndarray, ai: np.ndarray, keep_out: np.ndarray, r: int = 4) -> tuple[int, int]:
    """Small whole-image offset (AI outputs sometimes slide by a few px), judged outside the region."""
    best, best_err = (0, 0), None
    sample = ~keep_out
    sample[:r] = sample[-r:] = False
    sample[:, :r] = sample[:, -r:] = False
    ys, xs = np.nonzero(sample)
    pick = np.random.default_rng(0).choice(len(ys), min(40000, len(ys)), replace=False)
    ys, xs = ys[pick], xs[pick]
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            err = np.abs(ai[ys + dy, xs + dx] - plate[ys, xs]).sum(1).mean()
            if best_err is None or err < best_err:
                best, best_err = (dx, dy), err
    return best


def extract(spec: dict) -> tuple[Image.Image, dict]:
    plate_cfg = json.loads((HERE / "plates" / f"{spec['plate']}.json").read_text())
    plate_img = Image.open(ROOT / plate_cfg["image"]).convert("RGB")
    ai_img = Image.open(ROOT / spec["ai_image"]).convert("RGB")
    if ai_img.size != plate_img.size:
        ai_img = ai_img.resize(plate_img.size, Image.LANCZOS)
    plate = np.asarray(plate_img).astype(int)
    ai = np.asarray(ai_img).astype(int)

    region = region_mask(plate_img.size, spec["region"])
    dx, dy = best_shift(plate, ai, region)
    ai = np.roll(ai, (-dy, -dx), axis=(0, 1))

    diff = np.abs(ai - plate).sum(2)
    diff = ndimage.median_filter(diff, size=3)          # kill single-pixel drift speckle
    m = (diff > spec.get("threshold", 60)) & region
    m = ndimage.binary_opening(m, iterations=1)         # drop thin drift slivers
    m = ndimage.binary_closing(m, iterations=spec.get("close", 4))
    labels, n = ndimage.label(m)
    if n == 0:
        raise SystemExit("nothing differs from the plate inside the region")
    sizes = ndimage.sum(m, labels, range(1, n + 1))
    m = labels == (1 + int(np.argmax(sizes)))
    m = ndimage.binary_fill_holes(m) & region

    rgba = np.zeros(ai.shape[:2] + (4,), np.uint8)
    rgba[..., :3] = ai
    rgba[..., 3] = m * 255
    ys, xs = np.nonzero(m)
    info = {"shift": [dx, dy], "bbox": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
            "coverage": round(float(m.mean()), 4)}
    return Image.fromarray(rgba, "RGBA"), info


def review_sheet(spec: dict, cut: Image.Image) -> Image.Image:
    plate_cfg = json.loads((HERE / "plates" / f"{spec['plate']}.json").read_text())
    plate = Image.open(ROOT / plate_cfg["image"]).convert("RGB")
    ai = Image.open(ROOT / spec["ai_image"]).convert("RGB").resize(plate.size)
    # mask overlay: region outline + kept pixels tinted
    overlay = ai.copy()
    tint = Image.new("RGB", plate.size, (255, 0, 200))
    overlay = Image.composite(Image.blend(overlay, tint, 0.45), overlay, cut.split()[3])
    reg = spec["region"]
    d = ImageDraw.Draw(overlay)
    if "rect" in reg:
        d.rectangle(reg["rect"], outline=(0, 255, 255), width=3)
    else:
        d.polygon([tuple(p) for p in reg["polygon"]], outline=(0, 255, 255), width=3)
    checker = Image.new("RGB", plate.size)
    cd = ImageDraw.Draw(checker)
    for y in range(0, plate.height, 24):
        for x in range(0, plate.width, 24):
            cd.rectangle((x, y, x + 23, y + 23), fill=(70, 70, 76) if (x + y) // 24 % 2 else (110, 110, 118))
    checker.paste(cut, (0, 0), cut)
    final = plate.copy()
    final.paste(cut, (0, 0), cut)
    panels = [("AI output", ai), ("region + kept mask", overlay), ("cut-out", checker), ("on true plate", final)]
    pw = 468
    ph = round(pw * plate.height / plate.width)
    sheet = Image.new("RGB", ((pw + 10) * len(panels) - 10, ph + 30), (20, 20, 24))
    sd = ImageDraw.Draw(sheet)
    for i, (label, img) in enumerate(panels):
        sheet.paste(img.resize((pw, ph), Image.LANCZOS), (i * (pw + 10), 30))
        sd.text((i * (pw + 10) + 6, 8), label, fill=(240, 240, 240))
    return sheet


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("pose")
    ap.add_argument("--sheet", action="store_true", help="write a review sheet to --out")
    ap.add_argument("--out", default=str(ROOT / ".scratch/plate-compositor"))
    args = ap.parse_args()
    spec = json.loads(Path(args.pose).read_text())
    cut, info = extract(spec)
    dest = ROOT / spec["out"]
    dest.parent.mkdir(parents=True, exist_ok=True)
    cut.save(dest)
    print("wrote", dest, info)
    if args.sheet:
        out = Path(args.out)
        out.mkdir(parents=True, exist_ok=True)
        sheet_path = out / f"{Path(args.pose).stem}_extract_sheet.png"
        review_sheet(spec, cut).save(sheet_path)
        print("wrote", sheet_path)


if __name__ == "__main__":
    main()
