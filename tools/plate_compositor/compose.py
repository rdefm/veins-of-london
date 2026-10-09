"""Composite character sprites onto a blank reference plate so they read as part of the room.

Usage (from repo root):
    python tools/plate_compositor/compose.py tools/plate_compositor/shots/<file>.json [--out DIR] [--sheet]

Pipeline per shot: grid-lock (work at the plate's native pixel size) -> palette-lock (plate
palette + each actor's key colours) -> perspective scale from floor position -> contact shadow
-> light tint (ambient, floor AO, rim per light, selective outline) -> occluders painted back
in depth order -> nearest-neighbour upscale. See README.md for the rationale and limits.
"""
import argparse
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


class Plate:
    def __init__(self, cfg: dict, actor_sprites: list[str]):
        self.cfg = cfg
        self.scale = cfg["scale"]
        full = Image.open(ROOT / cfg["image"]).convert("RGB")
        self.W, self.H = full.width // self.scale, full.height // self.scale
        native = full.resize((self.W, self.H), Image.BOX)
        n = cfg["plate_colours"]
        # octree keeps small saturated props (crates, signs) that median-cut averages away
        method = {"mediancut": Image.Quantize.MEDIANCUT, "octree": Image.Quantize.FASTOCTREE}[cfg.get("quantize", "mediancut")]
        q = native.quantize(colors=n, method=method, dither=Image.Dither.NONE)
        pal = [np.array(q.getpalette()[: n * 3]).reshape(-1, 3)]
        for path in sorted(set(actor_sprites)):
            pal.append(self._cast_colours(path, cfg["cast_colours"]))
        self.pal = np.vstack(pal).astype(float)
        self.base = self.snap(np.asarray(native).astype(float))
        self.occluders = [(self._occluder_mask(o), o["depth_y"]) for o in cfg["occluders"]]

    @staticmethod
    def _cast_colours(path: str, n: int) -> np.ndarray:
        a = np.asarray(Image.open(ROOT / path).convert("RGBA"))
        px = a[a[..., 3] >= 128][:, :3][::8]   # opaque pixels only
        im = Image.fromarray(px.reshape(1, -1, 3).astype(np.uint8))
        q = im.quantize(colors=n, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
        return np.array(q.getpalette()[: n * 3]).reshape(-1, 3)

    def _occluder_mask(self, occ: dict) -> np.ndarray:
        m = Image.new("L", (self.W, self.H), 0)
        d = ImageDraw.Draw(m)
        for s in occ["shapes"]:
            if "ellipse" in s:
                d.ellipse(s["ellipse"], fill=255)
            elif "rect" in s:
                d.rectangle(s["rect"], fill=255)
            elif "line" in s:
                d.line(s["line"], fill=255, width=s.get("width", 1))
            elif "polygon" in s:
                d.polygon([tuple(p) for p in s["polygon"]], fill=255)
        return np.asarray(m) > 0

    def snap(self, rgb: np.ndarray) -> np.ndarray:
        flat = rgb.reshape(-1, 3).astype(float)
        d = ((flat[:, None, :] - self.pal[None]) ** 2).sum(2)
        return self.pal[d.argmin(1)].reshape(rgb.shape)

    def load_sprite(self, path: str, feet_y: int, flip: bool) -> np.ndarray:
        im = Image.open(ROOT / path).convert("RGBA")
        im = im.crop(im.split()[3].getbbox())
        # standing height from floor position: eye line sits on the horizon
        h = round((feet_y - self.cfg["horizon_y"]) / self.cfg["eye_frac"])
        w = round(im.width * h / im.height)
        im = im.resize((w, h), Image.BOX)
        if flip:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
        a = np.asarray(im).astype(float)
        a[..., 3] = (a[..., 3] >= 128) * 255
        return a

    def load_cutout(self, path: str) -> np.ndarray:
        """Plate-sized cut-out from extract.py, block-averaged to native px (alpha-weighted)."""
        s = self.scale
        a = np.asarray(Image.open(ROOT / path).convert("RGBA")).astype(float)
        a = a[: self.H * s, : self.W * s].reshape(self.H, s, self.W, s, 4)
        alpha = a[..., 3] / 255.0
        wsum = alpha.sum((1, 3))
        rgb = (a[..., :3] * alpha[..., None]).sum((1, 3)) / np.maximum(wsum, 1e-6)[..., None]
        out = np.zeros((self.H, self.W, 4))
        out[..., :3] = rgb
        out[..., 3] = (wsum / (s * s) >= 0.5) * 255
        return out

    def light_sprite(self, spr: np.ndarray, x0: int, y0: int) -> np.ndarray:
        rgb, op = spr[..., :3].copy(), spr[..., 3] > 0
        h, w = op.shape
        ys = slice(max(0, y0), min(self.H, y0 + h))
        xs = slice(max(0, x0), min(self.W, x0 + w))
        amb = self.base[ys, xs].reshape(-1, 3).mean(0)
        rgb = rgb * 0.88 + (rgb * amb / 255.0) * 0.12 * 2.0
        rgb *= np.linspace(1.0, 0.82, h)[:, None, None]   # floor ambient occlusion
        cx, cy = x0 + w / 2, y0 + h * 0.4
        for light in self.cfg["lights"]:
            (lx, ly), col, strength = light["xy"], light["rgb"], light["strength"]
            dx, dy = lx - cx, ly - cy
            dist = math.hypot(dx, dy)
            sx, sy = round(dx / dist * 1.4), round(dy / dist * 1.4)
            shifted = np.zeros_like(op)
            src = op[max(0, sy):h + min(0, sy), max(0, sx):w + min(0, sx)]
            shifted[max(0, -sy):h - max(0, sy), max(0, -sx):w - max(0, sx)] = src
            rim = op & ~shifted   # edge pixels facing this light
            fall = strength * min(1.0, 90 / dist) * 0.55
            rgb[rim] = rgb[rim] * (1 - fall) + np.array(col) * fall
        pad = np.pad(op, 1)
        inner = pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]
        rgb[op & ~inner] *= 0.6   # selective outline: darkened own colour
        out = spr.copy()
        out[..., :3] = np.clip(rgb, 0, 255)
        return out

    def shadow(self, canvas: np.ndarray, fx: int, fy: int, w: int) -> None:
        m = Image.new("L", (self.W, self.H), 0)
        ImageDraw.Draw(m).ellipse((fx - w * 0.42, fy - 2, fx + w * 0.32, fy + 2), fill=255)
        sel = np.asarray(m) > 0
        canvas[sel] = self.snap(canvas[sel] * 0.68)

    def compose(self, shot: dict) -> Image.Image:
        canvas = self.base.copy()
        layers = []
        for a in shot["actors"]:
            if "cutout" in a:   # already posed, scaled and lit by the AI; placed where it was cut
                spr = self.load_cutout(a["cutout"])
                feet_y = int(np.nonzero(spr[..., 3].any(1))[0].max())
                layers.append((feet_y, "cutout", (spr, a)))
                continue
            spr = self.load_sprite(a["sprite"], a["feet_y"], a.get("flip", False))
            h, w = spr.shape[:2]
            layers.append((a["feet_y"], "actor", (spr, a["feet_x"] - w // 2, a["feet_y"] - h, a)))
        for mask, depth in self.occluders:
            layers.append((depth, "occ", mask))
        for _, kind, data in sorted(layers, key=lambda t: t[0]):   # painter's order by floor depth
            if kind == "occ":
                canvas[data] = self.base[data]
                continue
            if kind == "cutout":
                spr, a = data
                on = spr[..., 3] > 0
                if a.get("shadow"):
                    xs = np.nonzero(on.any(0))[0]
                    self.shadow(canvas, int(xs.mean()), depth, len(xs))
                canvas[on] = spr[..., :3][on]
                continue
            spr, x0, y0, a = data
            self.shadow(canvas, a["feet_x"], a["feet_y"], spr.shape[1])
            lit = self.light_sprite(spr, x0, y0)
            h, w = lit.shape[:2]
            cy0, cy1 = max(0, y0), min(self.H, y0 + h)
            cx0, cx1 = max(0, x0), min(self.W, x0 + w)
            part = lit[cy0 - y0:cy1 - y0, cx0 - x0:cx1 - x0]
            on = part[..., 3] > 0
            region = canvas[cy0:cy1, cx0:cx1]
            region[on] = part[..., :3][on]
        img = Image.fromarray(self.snap(canvas).astype(np.uint8))
        return img.resize((self.W * self.scale, self.H * self.scale), Image.NEAREST)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("shots")
    ap.add_argument("--out", default=str(ROOT / ".scratch/plate-compositor"))
    ap.add_argument("--sheet", action="store_true", help="also write a side-by-side review sheet")
    args = ap.parse_args()

    spec = json.loads(Path(args.shots).read_text())
    plate_cfg = json.loads((HERE / "plates" / f"{spec['plate']}.json").read_text())
    sprites = [a.get("sprite") or a["cutout"] for s in spec["shots"] for a in s["actors"]]
    plate = Plate(plate_cfg, sprites)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    results = []
    for shot in spec["shots"]:
        img = plate.compose(shot)
        img.save(out / f"{shot['id']}.png")
        results.append((shot.get("label", shot["id"]), img))
        print("wrote", out / f"{shot['id']}.png")

    if args.sheet:
        pw = 468
        ph = round(pw * results[0][1].height / results[0][1].width)
        sheet = Image.new("RGB", ((pw + 10) * len(results) - 10, ph + 30), (20, 20, 24))
        d = ImageDraw.Draw(sheet)
        for i, (label, img) in enumerate(results):
            sheet.paste(img.resize((pw, ph), Image.LANCZOS), (i * (pw + 10), 30))
            d.text((i * (pw + 10) + 6, 8), label, fill=(240, 240, 240))
        sheet.save(out / f"{Path(args.shots).stem}_sheet.png")
        print("wrote", out / f"{Path(args.shots).stem}_sheet.png")


if __name__ == "__main__":
    main()
