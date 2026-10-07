"""Writes the three Archie style rigs (character kit) and review sheets.

    python tools/stage_art/build_style_mockups.py [sheet_dir]

Outputs assets/stages/rigs/archie_<style>/*.png + data/stages/rigs/archie_<style>.json.
Swap one in by setting the actor's "rig" in a stage file, or pass the rig id to
scripts/debug_stage_screenshot.gd. With sheet_dir, also writes styles.png (the
archie rig against the three styles) and kit_<style>.png (every Archie pose and
walk frame, plus the kit's other characters).
"""
import sys
from pathlib import Path

from PIL import Image

import build_stage_assets as bsa
import char_kit as kit
import characters
import preview_rig
import rig_archie
from raster import upscale


def compose(imgs, pose):
    out = Image.new("RGBA", (kit.W, kit.H), (0, 0, 0, 0))
    legs = "legs_%s.png" % pose["legs"] if pose.get("legs", "base") != "base" else "legs.png"
    keys = ["shadow.png", legs, "torso.png", "head.png", "eyes_%s.png" % pose["eyes"],
            "brows_%s.png" % pose["brows"], "glasses.png", "mouth_%s.png" % pose["mouth"],
            "arm_r_%s.png" % pose["arm_r"], "arm_l_%s.png" % pose["arm_l"]]
    for key in keys:
        if key in imgs:
            out.alpha_composite(imgs[key])
    return out


def _tile(bg):
    return bg.crop((182, 300 - 159 - 9, 182 + 96, 300 - 159 - 9 + 168)).copy()


def _backdrop():
    return Image.open(bsa.ROOT / "assets/stages/sets/spitalfields/market.png").convert("RGBA")


def styles_sheet(path):
    rows = [rig_archie.build()] + [kit.build(st, characters.ARCHIE) for st in kit.STYLES.values()]
    bg = _backdrop()
    poses = preview_rig.POSES[:4]
    out = Image.new("RGBA", (kit.W * len(poses), kit.H * len(rows)), (0, 0, 0, 255))
    for j, imgs in enumerate(rows):
        for i, pose in enumerate(poses):
            tile = _tile(bg)
            tile.alpha_composite(compose(imgs, pose))
            out.alpha_composite(tile, (i * kit.W, j * kit.H))
    upscale(out, 2).save(path)


FACE = dict(eyes="open", brows="normal", mouth="closed")
KIT_POSES = [
    dict(arm_l="bag", arm_r="rest", **FACE),
    dict(arm_l="bag", arm_r="rest", eyes="open", brows="normal", mouth="whistle"),
    dict(arm_l="bag_wave_a", arm_r="rest", eyes="open", brows="up", mouth="talk_b"),
    dict(arm_l="bag_wave_b", arm_r="pocket", **FACE),
    dict(arm_l="bag_wave_a", arm_r="vial", eyes="open", brows="normal", mouth="smirk"),
    dict(arm_l="bag", arm_r="flick_back", eyes="down", brows="quirk", mouth="closed"),
    dict(arm_l="bag", arm_r="flick", **FACE),
    dict(arm_l="hold", arm_r="phone_low", eyes="wide", brows="up", mouth="agape"),
]
WALK_POSES = [dict(arm_l="bag", arm_r="rest", legs="walk_%d" % i, **FACE) for i in range(len(kit.WALK))]
OTHER_POSE = dict(arm_l="rest", arm_r="rest", eyes="open", brows="knit", mouth="closed")


def kit_sheet(style, path):
    bg = _backdrop()
    archie = kit.build(style, characters.ARCHIE)
    rows = [[(archie, p) for p in KIT_POSES],
            [(archie, p) for p in WALK_POSES]
            + [(kit.build(style, c), OTHER_POSE) for n, c in characters.CHARACTERS.items() if n != "archie"]]
    cols = max(len(r) for r in rows)
    out = Image.new("RGBA", (kit.W * cols, kit.H * len(rows)), (0, 0, 0, 255))
    for j, row in enumerate(rows):
        for i, (imgs, pose) in enumerate(row):
            tile = _tile(bg)
            tile.alpha_composite(compose(imgs, pose))
            out.alpha_composite(tile, (i * kit.W, j * kit.H))
    upscale(out, 2).save(path)


def main():
    for st in kit.STYLES.values():
        rid = "archie_" + st["name"]
        bsa.write_images(kit.build(st, characters.ARCHIE), bsa.ROOT / "assets/stages/rigs" / rid)
        bsa.write_json(bsa.ROOT / ("data/stages/rigs/%s.json" % rid), kit.manifest(bsa.rig_manifest(), st, characters.ARCHIE, rid))
    if len(sys.argv) > 1:
        out = Path(sys.argv[1])
        out.mkdir(parents=True, exist_ok=True)
        styles_sheet(out / "styles.png")
        for name, st in kit.STYLES.items():
            kit_sheet(st, out / ("kit_%s.png" % name))


if __name__ == "__main__":
    main()
