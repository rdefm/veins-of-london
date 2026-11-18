"""Optional cleanup + crop QA for a generated event-card draft.

Snaps a generator's pseudo-pixel image to a true pixel grid (box downscale to
native size, optional colour quantise or palette snap, nearest-neighbour
upscale back by an integer factor) and writes a QA sheet showing the source,
the cleaned result, and the VN image-frame crop on three phone shapes.

Usage (repo root):
  python .claude/skills/event-storyboard/scripts/pixelize.py IN.png OUT_DIR
      [--scale 4] [--colors 48 | --palette data/palette.json | --no-quantize]
      [--export-scale N] [--mode mean|dominant] [--offset X Y]

Writes OUT_DIR/<stem>_native.png, <stem>_clean.png (native x export-scale,
default = --scale so it matches the source size) and <stem>_qa.png.
Nothing is written under assets/ — placing a file is a separate, explicit step.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..", "tools"))
import pixel_grid  # noqa: E402

# VN image frame = viewport height minus ~300px of chrome (top bar + 236px
# text panel + margins); width = viewport width. ADR 0005 / ART-BIBLE §3.
PHONES = [
    ("small 375x667", 375, 667 - 300, (230, 80, 60)),
    ("baseline 390x844", 390, 544, (240, 200, 40)),
    ("tall 412x915", 412, 915 - 300, (70, 170, 230)),
]


def cover_crop_box(src_w, src_h, frame_w, frame_h):
    """Centred aspect-cover crop (STRETCH_KEEP_ASPECT_COVERED)."""
    src_aspect, frame_aspect = src_w / src_h, frame_w / frame_h
    if src_aspect > frame_aspect:
        w = round(src_h * frame_aspect)
        x = (src_w - w) // 2
        return (x, 0, x + w, src_h)
    h = round(src_w / frame_aspect)
    y = (src_h - h) // 2
    return (0, y, src_w, y + h)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("out_dir")
    ap.add_argument("--scale", type=int, default=4, help="source px per art pixel")
    ap.add_argument("--colors", type=int, default=64)
    ap.add_argument("--palette", help="snap to this palette JSON instead of --colors")
    ap.add_argument("--no-quantize", action="store_true")
    ap.add_argument("--export-scale", type=int)
    ap.add_argument("--mode", choices=pixel_grid.LOCK_MODES, default="mean",
                    help="cell colour: box mean, or most common colour")
    ap.add_argument("--offset", type=int, nargs=2, default=(0, 0), metavar=("X", "Y"),
                    help="grid origin in source px")
    a = ap.parse_args()

    src = Image.open(a.src).convert("RGB")
    stem = os.path.splitext(os.path.basename(a.src))[0]
    os.makedirs(a.out_dir, exist_ok=True)

    offset = tuple(a.offset)
    if a.palette:
        pal, n = pixel_grid.load_palette(a.palette)
        colour = lambda im: pixel_grid.snap_to_palette_image(im, pal)  # noqa: E731
        note = f"palette {os.path.basename(a.palette)} ({n})"
    elif not a.no_quantize:
        colour = lambda im: pixel_grid.quantize_colours(im, a.colors)  # noqa: E731
        note = f"{a.colors} colours"
    else:
        colour = None
        note = "unquantised"
    if a.mode == "dominant" and colour:
        # colour-reduce at full res first so similar shades vote as one colour
        native = pixel_grid.grid_lock(colour(src), a.scale, "dominant", offset)
    else:
        native = pixel_grid.grid_lock(src, a.scale, a.mode, offset)
        native = colour(native) if colour else native
    native_size = native.size
    note += f", {a.mode}"
    export_scale = a.export_scale or a.scale
    clean = native.resize((native.width * export_scale, native.height * export_scale), Image.NEAREST)

    native.convert("RGBA").save(os.path.join(a.out_dir, f"{stem}_native.png"))
    clean.convert("RGBA").save(os.path.join(a.out_dir, f"{stem}_clean.png"))

    # QA sheet: source | cleaned with crop outlines | the three phone crops.
    panel_h = 600
    def fit(img):
        return img.resize((round(img.width * panel_h / img.height), panel_h), Image.NEAREST)

    overlay = clean.copy()
    draw = ImageDraw.Draw(overlay)
    crops = []
    for name, fw, fh, colour in PHONES:
        box = cover_crop_box(clean.width, clean.height, fw, fh)
        draw.rectangle(box, outline=colour, width=max(3, clean.width // 200))
        crops.append((name, clean.crop(box), colour))
    panels = [("source", fit(src)), (f"clean {native_size[0]}x{native_size[1]} {note}", fit(overlay))]
    panels += [(name, fit(img)) for name, img, _ in crops]
    gap, label_h = 12, 22
    sheet = Image.new("RGB", (sum(p.width for _, p in panels) + gap * (len(panels) + 1),
                              panel_h + label_h + gap * 2), (24, 24, 28))
    sd = ImageDraw.Draw(sheet)
    x = gap
    for label, p in panels:
        sheet.paste(p, (x, gap + label_h))
        sd.text((x, gap), label, fill=(230, 230, 230))
        x += p.width + gap
    qa = os.path.join(a.out_dir, f"{stem}_qa.png")
    sheet.save(qa)
    print(f"native {native_size} ({note}) -> {a.out_dir}; QA sheet {qa}")


if __name__ == "__main__":
    main()
