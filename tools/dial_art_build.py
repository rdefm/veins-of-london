"""Builds the Dial menu's component sprites and hand-made overlays on the native grid.

Writes into assets/hq/dial/ and assets/hq/dial/components/ (art spec
.scratch/ui-previews-dial/dial-art-spec.md §2.1-§2.2):
  - lens_time.png and movement_recharge.png (4-frame horizontal strip), grid-locked from the
    generated sources in .scratch/ui-previews-dial/sources/ at the `component_sizes` in
    data/dial_art.json (each sized to fill its module's inner top lip);
  - dial_stud_lit, slot_ghost_lens, chamber_blank, chamber_ring, dial_glow,
    lens_tier_<n>, movement_tier_<n>: drawn from code in palette colours;
  - comp_label_<recipeKey> (12x12): box downscale of assets/combat/icons/<recipeKey>.png,
    plus comp_label_placeholder for recipes with no icon;
  - dial_needle.png: the raw dial-needle.png art turned tip-up and box-downscaled to
    `components.needle_size`.
Every output has hard alpha (0 or 255), no soft edges.

Usage (repo root): python tools/dial_art_build.py
"""
import json
import math
import os

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SRC = os.path.join(ROOT, ".scratch", "ui-previews-dial", "sources")
OUT = os.path.join(ROOT, "assets", "hq", "dial")
COMP = os.path.join(OUT, "components")
ICONS = os.path.join(ROOT, "assets", "combat", "icons")


def palette():
    with open(os.path.join(ROOT, "data", "palette.json"), encoding="utf-8") as f:
        data = json.load(f)
    return {c["id"]: tuple(int(c["hex"][i:i + 2], 16) for i in (1, 3, 5)) + (255,) for c in data["colors"]}


def component_sizes():
    with open(os.path.join(ROOT, "data", "dial_art.json"), encoding="utf-8") as f:
        sizes = json.load(f)["component_sizes"]
    return sizes["lens"][0], sizes["movement_frame"][0]


P = palette()
LENS, MOVEMENT = component_sizes()
CLEAR = (0, 0, 0, 0)
LIT = (0xF4, 0xEF, 0xE0, 255)


def hard_alpha(img, cut=128):
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= cut else CLEAR
    return img


def fit_square(img, box, side):
    """Crop `box`, centre it on a transparent square, box-downscale to `side`."""
    part = img.crop(box)
    edge = max(part.width, part.height)
    sq = Image.new("RGBA", (edge, edge), CLEAR)
    sq.paste(part, ((edge - part.width) // 2, (edge - part.height) // 2))
    return hard_alpha(sq.resize((side, side), Image.BOX))


def alpha_runs(img):
    """Column ranges holding opaque pixels, left to right."""
    alpha = img.getchannel("A")
    runs, start = [], None
    for x in range(img.width):
        on = any(alpha.getpixel((x, y)) > 0 for y in range(img.height))
        if on and start is None:
            start = x
        if not on and start is not None:
            runs.append((start, x))
            start = None
    if start is not None:
        runs.append((start, img.width))
    return runs


def build_components():
    os.makedirs(COMP, exist_ok=True)
    lens = Image.open(os.path.join(SRC, "lens_time_gen.png")).convert("RGBA")
    fit_square(lens, lens.getbbox(), LENS).save(os.path.join(COMP, "lens_time.png"))

    strip = Image.open(os.path.join(SRC, "movement_recharge_gen.png")).convert("RGBA")
    runs = alpha_runs(strip)
    assert len(runs) == 4, "movement strip should hold 4 frames, found %d" % len(runs)
    frames = []
    for x0, x1 in runs:
        bbox = strip.crop((x0, 0, x1, strip.height)).getbbox()
        frames.append(fit_square(strip, (x0, bbox[1], x1, bbox[3]), MOVEMENT))
    out = Image.new("RGBA", (MOVEMENT * len(frames), MOVEMENT), CLEAR)
    for i, f in enumerate(frames):
        out.paste(f, (i * MOVEMENT, 0))
    out.save(os.path.join(COMP, "movement_recharge.png"))


def ellipse_cells(w, h):
    """(x, y) -> 'in' / 'edge' for a w x h pixel ellipse."""
    cx, cy, rx, ry = (w - 1) / 2, (h - 1) / 2, w / 2, h / 2
    inside = {(x, y) for y in range(h) for x in range(w) if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0}
    edge = {(x, y) for (x, y) in inside if any((x + dx, y + dy) not in inside for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    return inside, edge


def draw(w, h, cells):
    img = Image.new("RGBA", (w, h), CLEAR)
    for (x, y), col in cells.items():
        img.putpixel((x, y), col)
    return img


def build_overlays():
    inside, edge = ellipse_cells(6, 6)
    draw(6, 6, {c: (P["highlight_warm"] if c in edge else LIT) for c in inside}).save(os.path.join(OUT, "dial_stud_lit.png"))

    inside, edge = ellipse_cells(LENS, LENS)
    draw(LENS, LENS, {c: P["slate_pale"] for c in edge if (c[0] + c[1]) % 2 == 0}).save(os.path.join(OUT, "slot_ghost_lens.png"))

    inside, edge = ellipse_cells(22, 8)
    blank = {c: (P["outline_black"] if c in edge else P["slate_mid"]) for c in inside}
    for (x, y) in inside:
        if y == 2 and (x, y) not in edge:
            blank[(x, y)] = P["slate_light"]
    draw(22, 8, blank).save(os.path.join(OUT, "chamber_blank.png"))
    draw(22, 8, {c: LIT for c in edge}).save(os.path.join(OUT, "chamber_ring.png"))

    bayer = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    glow = {}
    for y in range(16):
        for x in range(16):
            d = (((x - 7.5) ** 2 + (y - 7.5) ** 2) ** 0.5) / 8.0
            if d < 1.0 and (1.0 - d) * 16 > bayer[y % 4][x % 4]:
                glow[(x, y)] = (255, 255, 255, 255)
    draw(16, 16, glow).save(os.path.join(OUT, "dial_glow.png"))

    # Tier marks: n notches along the Lens bezel's top, n jewels along the Movement's bottom rim.
    for n in range(1, 6):
        cells = {}
        for i in range(n):
            x = LENS // 2 - 2 * n + i * 4
            for dx in (0, 1):
                cells[(x + dx, 1)] = LIT
                cells[(x + dx, 2)] = P["neutral_light"]
        draw(LENS, LENS, cells).save(os.path.join(COMP, "lens_tier_%d.png" % n))
        cells = {}
        for i in range(n):
            x = MOVEMENT // 2 - n * 3 + i * 6
            for dx, dy, col in ((0, 0, P["brick_lit"]), (1, 0, P["brick_mid"]), (0, 1, P["brick_mid"]), (1, 1, P["brick_deep"])):
                cells[(x + dx, MOVEMENT - 5 + dy)] = col
        draw(MOVEMENT, MOVEMENT, cells).save(os.path.join(COMP, "movement_tier_%d.png" % n))


def build_needle():
    """dial_needle.png at `needle_size`, tip up, from the raw dial-needle.png art.

    The raw needle lies diagonally; its long axis (principal axis of the opaque pixels)
    is rotated to vertical, tip up (the narrow end), then box-downscaled to the native
    size. Prints the hub row band (the widest rows) to measure `needle_pivot` from.
    """
    with open(os.path.join(ROOT, "data", "dial_art.json"), encoding="utf-8") as f:
        w, h = json.load(f)["components"]["needle_size"]
    raw = Image.open(os.path.join(OUT, "dial-needle.png")).convert("RGBA")
    raw = raw.crop(raw.getbbox())
    pts = [(x, y) for y in range(raw.height) for x in range(raw.width) if raw.getpixel((x, y))[3] > 128]
    cx = sum(p[0] for p in pts) / len(pts)
    cy = sum(p[1] for p in pts) / len(pts)
    sxx = sum((p[0] - cx) ** 2 for p in pts)
    syy = sum((p[1] - cy) ** 2 for p in pts)
    sxy = sum((p[0] - cx) * (p[1] - cy) for p in pts)
    axis = math.degrees(0.5 * math.atan2(2 * sxy, sxx - syy))
    up = raw.rotate(axis + 90, resample=Image.BICUBIC, expand=True)
    up = up.crop(hard_alpha(up).getbbox())
    widths = [sum(1 for x in range(up.width) if up.getpixel((x, y))[3] >= 128) for y in range(up.height)]
    if sum(widths[:len(widths) // 3]) > sum(widths[-(len(widths) // 3):]):
        up = up.rotate(180)
    pad_w = round(up.height * w / h)
    padded = Image.new("RGBA", (pad_w, up.height), CLEAR)
    padded.paste(up, ((pad_w - up.width) // 2, 0))
    out = hard_alpha(padded.resize((w, h), Image.BOX))
    out.save(os.path.join(OUT, "dial_needle.png"))
    rows = [sum(1 for x in range(w) if out.getpixel((x, y))[3]) for y in range(h)]
    widest = max(rows)
    band = [y for y, n in enumerate(rows) if n == widest]
    print("needle hub rows %d-%d (pivot y = %.1f)" % (band[0], band[-1], (band[0] + band[-1] + 1) / 2.0))


def build_labels():
    with open(os.path.join(ROOT, "data", "recipes.json"), encoding="utf-8") as f:
        recipes = json.load(f)["recipes"]
    for key in list(recipes.keys()) + ["placeholder"]:
        src = os.path.join(ICONS, key + ".png")
        if not os.path.exists(src):
            continue
        icon = Image.open(src).convert("RGBA")
        hard_alpha(icon.resize((12, 12), Image.BOX)).save(os.path.join(COMP, "comp_label_%s.png" % key))


if __name__ == "__main__":
    build_components()
    build_overlays()
    build_labels()
    build_needle()
    print("dial art built ->", os.path.relpath(OUT, ROOT))
