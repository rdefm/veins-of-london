from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


OUT = Path(__file__).parent
S = 4
WHITE = "#F7F3FA"


def icon(kind):
    im = Image.new("RGBA", (128 * S, 128 * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    def rr(box, radius, fill):
        d.rounded_rectangle(tuple(round(v * S) for v in box), round(radius * S), fill=fill)

    def ellipse(box, fill):
        d.ellipse(tuple(round(v * S) for v in box), fill=fill)

    if kind in ("c", "d", "e", "f"):
        rr((3, 3, 125, 125), 23, "#81549A")
        if kind in ("c", "d"):
            bold = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 53 * S)
            first, first_x, top_y, bottom_y = "inn", 23 * S, 18 * S, 65 * S
        else:
            bold = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 61 * S)
            first, first_x, top_y, bottom_y = "in", 31 * S, 11 * S, 65 * S
        d.text((first_x, top_y), first, font=bold, anchor="lt", fill=WHITE)
        second_x = first_x
        if kind in ("d", "f"):
            first_width = d.textlength(first, font=bold)
            it_width = d.textlength("it", font=bold)
            second_x += round(first_width - it_width)
        d.text((second_x, bottom_y), "it", font=bold, anchor="lt", fill=WHITE)
    elif kind == "a":
        # Compact Li mark: square silhouette, broad baseline, separate dot.
        rr((3, 3, 125, 125), 23, "#81549A")
        rr((23, 30, 40, 100), 2, WHITE)
        rr((23, 84, 60, 100), 2, WHITE)
        rr((73, 53, 92, 100), 2, WHITE)
        ellipse((73, 27, 92, 46), "#DDA477")
    else:
        # Lowercase lo mark, retaining the existing name cue.
        rr((3, 3, 125, 125), 23, "#81549A")
        rr((22, 27, 41, 100), 2, WHITE)
        ellipse((56, 51, 105, 100), WHITE)
        ellipse((73, 68, 88, 84), "#81549A")
    return im.resize((128, 128), Image.Resampling.LANCZOS)


a = icon("a")
b = icon("b")
c = icon("c")
d = icon("d")
e = icon("e")
f = icon("f")
a.save(OUT / "option-a-li.png")
b.save(OUT / "option-b-lo.png")
c.save(OUT / "option-c-innit.png")
d.save(OUT / "option-d-innit-right.png")
e.save(OUT / "option-e-in-it-left.png")
f.save(OUT / "option-f-in-it-right.png")

font_b = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 24)
font = ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", 17)
font_s = ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", 14)
board = Image.new("RGB", (980, 410), "#16161D")
draw = ImageDraw.Draw(board)
draw.text((38, 27), "LodedInnit  /  launcher icon drafts", font=font_b, fill="#F7F3FA")
draw.text((38, 65), "Current", font=font, fill="#C2BACB")
draw.text((354, 65), "A  /  Li monogram", font=font, fill="#C2BACB")
draw.text((666, 65), "B  /  lo monogram", font=font, fill="#C2BACB")
current = Image.open(OUT / "option-e-in-it-left.png").convert("RGBA")
for im, x in ((current, 38), (a, 354), (b, 666)):
    preview = im.resize((192, 192), Image.Resampling.LANCZOS)
    board.paste(preview, (x, 105), preview)
    tile = im.resize((56, 56), Image.Resampling.LANCZOS)
    board.paste(tile, (x + 240, 184), tile)
    draw.text((x + 239, 247), "56 px", font=font_s, fill="#A9A1B1")
draw.text((38, 334), "Existing mark", font=font, fill="#F7F3FA")
draw.text((354, 334), "Closer silhouette; copper dot", font=font, fill="#F7F3FA")
draw.text((666, 334), "Closer silhouette; keeps Lo", font=font, fill="#F7F3FA")
board.save(OUT / "comparison.png")

stacked = Image.new("RGB", (980, 380), "#16161D")
sd = ImageDraw.Draw(stacked)
sd.text((38, 27), "LodedInnit  /  stacked wordmark", font=font_b, fill="#F7F3FA")
sd.text((38, 73), "Current", font=font, fill="#C2BACB")
sd.text((348, 73), "C  /  left aligned", font=font, fill="#C2BACB")
sd.text((658, 73), "D  /  right aligned", font=font, fill="#C2BACB")
for im, x in ((current, 38), (c, 348), (d, 658)):
    large = im.resize((192, 192), Image.Resampling.LANCZOS)
    stacked.paste(large, (x, 111), large)
    tile = im.resize((56, 56), Image.Resampling.LANCZOS)
    stacked.paste(tile, (x + 234, 185), tile)
    sd.text((x + 234, 248), "56 px", font=font_s, fill="#A9A1B1")
sd.text((348, 328), "Reads like a stacked wordmark", font=font, fill="#F7F3FA")
sd.text((658, 328), "More balanced as an icon", font=font, fill="#F7F3FA")
stacked.save(OUT / "comparison-stacked.png")

init_board = Image.new("RGB", (980, 380), "#16161D")
ib = ImageDraw.Draw(init_board)
ib.text((38, 27), "LodedInnit  /  in + it", font=font_b, fill="#F7F3FA")
ib.text((38, 73), "Current", font=font, fill="#C2BACB")
ib.text((348, 73), "E  /  left aligned", font=font, fill="#C2BACB")
ib.text((658, 73), "F  /  right aligned", font=font, fill="#C2BACB")
for im, x in ((current, 38), (e, 348), (f, 658)):
    large = im.resize((192, 192), Image.Resampling.LANCZOS)
    init_board.paste(large, (x, 111), large)
    tile = im.resize((56, 56), Image.Resampling.LANCZOS)
    init_board.paste(tile, (x + 234, 185), tile)
    ib.text((x + 234, 248), "56 px", font=font_s, fill="#A9A1B1")
init_board.save(OUT / "comparison-in-it.png")
