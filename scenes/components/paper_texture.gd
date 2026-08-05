class_name PaperTexture
extends RefCounted

# M1.5 N6 asset 1: "1536x2048 PNG, aged cream (#f0ece2 family), subtle
# foxing/grain, NO linework, NO text... procedural noise over flat colour
# as placeholder" is explicitly acceptable when AI image generation isn't
# available, which it isn't in this environment. Rather than ship a huge
# pre-baked PNG, this generates a small deterministic noise tile at
# runtime (cheap: TILE_SIZE^2 pixels, once, not per frame) that
# map_canvas.gd draws tiled across the full paper background via
# draw_texture_rect(..., tile=true) — a placeholder texture, not a real
# asset file, matching N6's own "placeholder acceptable" wording.

const BASE_COLOUR := Color(0.941176, 0.925490, 0.886275)  # --paper #f0ece2, matches MapCanvas.PAPER_COLOUR
const TILE_SIZE := 128
const GRAIN_FREQUENCY := 0.15
const FOXING_FREQUENCY := 0.02
const GRAIN_STRENGTH := 0.02
const FOXING_STRENGTH := 0.05


static func generate_tile_image(seed_value: int = 1) -> Image:
	var grain := FastNoiseLite.new()
	grain.seed = seed_value
	grain.frequency = GRAIN_FREQUENCY
	grain.noise_type = FastNoiseLite.TYPE_PERLIN

	var foxing := FastNoiseLite.new()
	foxing.seed = seed_value + 1
	foxing.frequency = FOXING_FREQUENCY
	foxing.noise_type = FastNoiseLite.TYPE_PERLIN

	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGB8)
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			# Foxing only ever darkens (age spots), never brightens above
			# the base cream — minf clamps it to its shadow half only.
			var shift := grain.get_noise_2d(x, y) * GRAIN_STRENGTH + minf(foxing.get_noise_2d(x, y), 0.0) * FOXING_STRENGTH
			image.set_pixel(x, y, Color(
				clampf(BASE_COLOUR.r + shift, 0.0, 1.0),
				clampf(BASE_COLOUR.g + shift, 0.0, 1.0),
				clampf(BASE_COLOUR.b + shift, 0.0, 1.0),
			))
	return image


static func generate_tile_texture(seed_value: int = 1) -> ImageTexture:
	return ImageTexture.create_from_image(generate_tile_image(seed_value))
