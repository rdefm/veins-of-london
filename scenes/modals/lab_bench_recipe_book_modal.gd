class_name LabBenchRecipeBookModal
extends RefCounted

# The Lab's recipe notebook (docs/hq-diorama-vision.md §5.2): ring-bound page
# with five ore side tabs, four found recipes per page. data is { ore, page };
# tapping an entry opens lab_bench_recipe_detail above it (modal_layer.gd
# draws the two together). Tab and page live in the modal data, so the book
# reopens where it was left.

const DETAIL_TYPE := "lab_bench_recipe_detail"
const ORE_ORDER := ["time", "physics", "life", "fate", "emotion"]
const PER_PAGE := 4
const DESCRIPTION_MAX_CHARS := 64

# Art-space (1024x1536) geometry of recipe-book-side-tabs-blank.png.
const TAB_CENTRES_Y := [262.0, 495.0, 728.0, 960.0, 1190.0]
const TAB_X := 947.0
const TAB_HIT := Vector2(125, 200)
const ENTRY_TOP := 205.0
const ENTRY_STEP := 290.0
const ENTRY_HEIGHT := 208.0


# One live ore glyph, centred in its control.
class _TabGlyph extends Control:
	var ore_type := ""
	var colour := Color.WHITE

	func _draw() -> void:
		OreGlyphs.draw(self, size * 0.5, ore_type, colour, size.x * 0.32)


static func build(container: VBoxContainer, data: Dictionary) -> void:
	var ore := selected_ore(data)
	var recipes := Bench.found_recipe_keys_for_ore(ore)
	var page := clamped_page(int(data.get("page", 0)), recipes.size())

	var book := RecipeBookPage.new()
	container.add_child(book)
	_build_tabs(book, ore, page)
	if recipes.is_empty():
		_build_empty_state(book, ore)
	else:
		var first := page * PER_PAGE
		for slot in range(mini(PER_PAGE, recipes.size() - first)):
			_build_entry(book, recipes[first + slot], slot, ore, page)

	container.add_child(_controls(ore, page, page_count(recipes.size())))


# Saved tab, else the first ore tab holding a found recipe, else time.
static func selected_ore(data: Dictionary) -> String:
	var saved: String = data.get("ore", "")
	if ORE_ORDER.has(saved):
		return saved
	for ore in ORE_ORDER:
		if not Bench.found_recipe_keys_for_ore(ore).is_empty():
			return ore
	return ORE_ORDER[0]


static func page_count(recipe_count: int) -> int:
	return maxi(1, ceili(recipe_count / float(PER_PAGE)))


static func clamped_page(page: int, recipe_count: int) -> int:
	return clampi(page, 0, page_count(recipe_count) - 1)


# First-sentence-ish excerpt of an existing description, cut on a word.
static func short_description(text: String) -> String:
	if text.length() <= DESCRIPTION_MAX_CHARS:
		return text
	var cut := text.substr(0, DESCRIPTION_MAX_CHARS)
	var space := cut.rfind(" ")
	if space > 0:
		cut = cut.substr(0, space)
	return cut.rstrip(" ,.;:-") + "..."


static func _build_tabs(book: RecipeBookPage, ore: String, page: int) -> void:
	for i in range(ORE_ORDER.size()):
		var tab_ore: String = ORE_ORDER[i]
		var centre_y: float = TAB_CENTRES_Y[i]
		var selected := tab_ore == ore

		var glyph := _TabGlyph.new()
		glyph.ore_type = tab_ore
		glyph.colour = MapPalette.ore_colour_in(tab_ore, false)
		glyph.modulate.a = 1.0 if selected else 0.55
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		book.place(glyph, Rect2(TAB_X - 55, centre_y - 55, 110, 110))

		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.accessibility_name = "%s tab" % GameData.ORE_TYPES[tab_ore]["name"]
		hit.set_meta("ore", tab_ore)
		hit.set_meta("selected", selected)
		var outline := StyleBoxFlat.new()
		outline.bg_color = Color(0, 0, 0, 0)
		if selected:
			outline.set_border_width_all(4)
			outline.border_color = RecipeBookPage.INK
		outline.set_corner_radius_all(6)
		for state in ["normal", "hover", "pressed", "focus"]:
			hit.add_theme_stylebox_override(state, outline)
		hit.pressed.connect(func(): Modal.open("lab_bench_recipe_book", { "ore": tab_ore, "page": 0 }))
		book.place(hit, Rect2(TAB_X - TAB_HIT.x * 0.5 + 6, centre_y - 72, TAB_HIT.x - 20, 144))


static func _build_empty_state(book: RecipeBookPage, ore: String) -> void:
	var label := _page_label("Nothing found for %s yet." % GameData.ORE_TYPES[ore]["name"].get_slice(" ", 0), RecipeBookPage.INK_MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_meta("empty_state", true)
	book.place(label, Rect2(240, 560, 560, 400), 40.0, 11)


static func _build_entry(book: RecipeBookPage, recipe_key: String, slot: int, ore: String, page: int) -> void:
	var recipe: Dictionary = GameData.RECIPES[recipe_key]
	var top := ENTRY_TOP + ENTRY_STEP * slot

	var icon := TextureRect.new()
	icon.texture = ItemIcons.texture(recipe_key)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	book.place(icon, Rect2(232, top + 20, 172, 168))

	var name_size := RecipeBookPage.fit_font(recipe["name"], 372.0, 44.0, 26.0)
	var name_label := _page_label(recipe["name"], RecipeBookPage.INK)
	name_label.clip_text = true
	book.place(name_label, Rect2(452, top + 8, 376, 56), name_size, 11)

	var description := _page_label(short_description(recipe["description"]), RecipeBookPage.INK_MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 3
	book.place(description, Rect2(452, top + 66, 376, 100), 28.0, 10)

	var stock := _page_label("Stock: %d" % Crafting.inventory_qty(recipe_key), RecipeBookPage.INK)
	book.place(stock, Rect2(452, top + 164, 376, 36), 26.0, 10)

	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.accessibility_name = recipe["name"]
	hit.set_meta("recipeKey", recipe_key)
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(RecipeBookPage.INK, 0.12)
	pressed_style.set_corner_radius_all(8)
	hit.add_theme_stylebox_override("pressed", pressed_style)
	hit.pressed.connect(func(): open_detail(recipe_key, ore, page))
	book.place(hit, Rect2(206, top, 626, ENTRY_HEIGHT))


static func _page_label(text: String, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", RecipeBookPage.font())
	label.add_theme_color_override("font_color", colour)
	return label


# Prev / page / Next / Close strip under the book.
static func _controls(ore: String, page: int, pages: int) -> Control:
	var panel := PanelContainer.new()
	MapCardStyle.style_panel(panel, 12, 0.0)
	var row := UI.hbox(6)
	panel.add_child(row)
	var prev := MapCardStyle.text_button("‹ Prev", func(): Modal.open("lab_bench_recipe_book", { "ore": ore, "page": page - 1 }), page <= 0)
	prev.accessibility_name = "Previous page"
	row.add_child(prev)
	var counter := UI.label("Page %d/%d" % [page + 1, pages])
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(counter)
	var next := MapCardStyle.text_button("Next ›", func(): Modal.open("lab_bench_recipe_book", { "ore": ore, "page": page + 1 }), page >= pages - 1)
	next.accessibility_name = "Next page"
	row.add_child(next)
	row.add_child(MapCardStyle.text_button("Close", func(): Modal.close()))
	return panel


static func open_detail(recipe_key: String, ore: String, page: int) -> void:
	Modal.open(DETAIL_TYPE, { "recipeKey": recipe_key, "bookOre": ore, "bookPage": page })
