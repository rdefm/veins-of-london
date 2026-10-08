"""Writes the intro mock-up's alley set and buyer rigs in one character-kit style.

    python tools/stage_art/build_intro_stage.py <style> [sheet_dir]

Outputs assets/stages/sets/alley_<style>/ + data/stages/sets/alley_<style>.json and,
for each buyer (knife, mate, james), assets/stages/rigs/<buyer>_<style>/ +
data/stages/rigs/<buyer>_<style>.json. Archie's style rig comes from
build_style_mockups.py. With sheet_dir, also writes intro_<style>.png: the set at
the stage's camera positions with the cast composited in.
"""
import sys
from pathlib import Path

from PIL import Image

import build_stage_assets as bsa
import char_kit as kit
import characters
import set_alley as al
from build_style_mockups import compose
from raster import upscale

BUYERS = ["knife", "mate", "james"]
VP_W, VP_H = 190, 254
FACE = dict(eyes="open", brows="knit", mouth="closed")


def preview(style, set_imgs, path):
    """Three static frames: Archie alone, the stand-off, the exit (cast + car where the stage puts them)."""
    rigs = {n: kit.build(style, characters.CHARACTERS[n]) for n in ["archie"] + BUYERS}
    beats = [
        (110, None, [("archie", 66, "right", dict(arm_l="bag", arm_r="rest", eyes="open", brows="normal", mouth="whistle"))]),
        (150, 200, [("archie", 66, "right", dict(arm_l="bag_wave_a", arm_r="pocket", eyes="open", brows="up", mouth="talk_b")),
                    ("mate", 104, "left", dict(arm_l="rest", arm_r="rest", **FACE)),
                    ("knife", 165, "left", dict(arm_l="rest", arm_r="knife", **FACE)),
                    ("james", 212, "left", dict(arm_l="rest", arm_r="rest", **FACE))]),
        (100, 200, [("archie", 35, "left", dict(arm_l="bag", arm_r="rest", eyes="open", brows="normal", mouth="closed")),
                    ("mate", 104, "left", dict(arm_l="rest", arm_r="rest", **FACE)),
                    ("knife", 165, "left", dict(arm_l="rest", arm_r="knife", eyes="down", brows="knit", mouth="closed")),
                    ("james", 212, "left", dict(arm_l="rest", arm_r="rest", **FACE))]),
    ]
    frames = [_frame(set_imgs, rigs, cam, car, cast) for (cam, car, cast) in beats]
    sheet = Image.new("RGBA", ((VP_W + 4) * len(frames), VP_H), (255, 255, 255, 255))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * (VP_W + 4), 0))
    upscale(sheet, 2).save(path)


def _frame(si, rigs, cam_x, car_x, cast):
    left = max(0, min(al.WORLD_W - VP_W, cam_x - VP_W // 2))
    top = VP_H - al.WORLD_H
    out = Image.new("RGBA", (VP_W, VP_H), (0, 0, 0, 255))

    def blit(img, x, y):
        layer = Image.new("RGBA", out.size, (0, 0, 0, 0))
        layer.paste(img, (int(x), int(y)))
        return Image.alpha_composite(out, layer)

    out = blit(si["far.png"], -round(left * al.FAR_P), top)
    out = blit(si["walker_a_1.png"], 14 - round(left * al.FAR_P) - al.WALK_W // 2, top + al.WALK_Y - al.WALK_H)
    out = blit(si["alley.png"], -left, top)
    out = blit(si["steam_2.png"], al.STEAM_POS[0] - left, top + al.STEAM_POS[1])
    out = blit(si["cat_0.png"], al.CAT_POS[0] - left, top + al.CAT_POS[1])
    if car_x is not None:
        car_pos = (car_x - al.CAR_W // 2 - left, top + al.FLOOR_Y + 2 - al.CAR_H)
        out = blit(si["car.png"], *car_pos)
    for (name, x, facing, pose) in cast:
        img = compose(rigs[name], pose)
        if facing == "left":
            img = img.transpose(Image.FLIP_LEFT_RIGHT)
            out = blit(img, x - (kit.W - kit.ORIGIN[0]) - left, top + al.FLOOR_Y - kit.ORIGIN[1])
        else:
            out = blit(img, x - kit.ORIGIN[0] - left, top + al.FLOOR_Y - kit.ORIGIN[1])
    out = blit(si["fore.png"], -round(left * al.FORE_P), top)
    g = si["glow.png"]
    for (x, y) in al.light_points():
        out = blit(g, x - left - g.width // 2, top + y - g.height // 2)
    return out


def main():
    style = kit.STYLES[sys.argv[1]]
    name = style["name"]
    set_id = "alley_" + name
    set_imgs = al.build(style)
    bsa.write_images(set_imgs, bsa.ROOT / "assets/stages/sets" / set_id)
    bsa.write_json(bsa.ROOT / ("data/stages/sets/%s.json" % set_id), al.manifest(style, set_id))
    for buyer in BUYERS:
        rid = "%s_%s" % (buyer, name)
        char = characters.CHARACTERS[buyer]
        bsa.write_images(kit.build(style, char), bsa.ROOT / "assets/stages/rigs" / rid)
        bsa.write_json(bsa.ROOT / ("data/stages/rigs/%s.json" % rid), kit.manifest(bsa.rig_manifest(), style, char, rid))
    if len(sys.argv) > 2:
        out = Path(sys.argv[2])
        out.mkdir(parents=True, exist_ok=True)
        preview(style, set_imgs, out / ("intro_%s.png" % name))


if __name__ == "__main__":
    main()
