extends RefCounted
## The game's one colour palette (user, 18 Nov 2026): 2D screens and the 3D town take their colours
## from here, by name, never as new hex values. Drawn from the app icon (BonBon's pink pig face on
## mint, warm brown outline) and the UI mockups (cream dialogue box, dark teal ink, glossy green /
## blue / coral buttons). Guide: docs/guides/UI_STYLE.md (2D) and
## docs/guides/TOWN_DESIGN_BRIEF.md "Game palette and shop row" (3D).
##   const Palette := preload("res://scripts/core/game_palette.gd")
##   game.material_for(Palette.WALL_CREAM)

# --- Icon -----------------------------------------------------------------------------------
const PIG := Color("f9c6cf")          # BonBon's face
const BLUSH := Color("f99aa2")        # cheeks
const MINT := Color("b2ecdf")         # icon background
const OUTLINE := Color("6b2a10")      # icon outline

# --- UI (the same values as scripts/ui/bon_style.gd) -------------------------------------------
const INK := Color("16536a")          # titles and dialogue text (dark teal, never black)
const INK_SOFT := Color("3a8f9e")
const BROWN := Color("7a4a22")
const CREAM := Color("fdf4e3")        # dialogue box, pills, tiles
const CREAM_DEEP := Color("f6e7cc")
const RIM := Color("fffdf7")
const SKY := Color("dff3f4")
const GREEN := Color("45a83c")        # primary buttons (GREEN_BOTTOM)
const GREEN_LIGHT := Color("86d65e")  # (GREEN_TOP)
const BLUE := Color("2f87cf")         # back buttons, speaker tag (BLUE_BOTTOM)
const BLUE_LIGHT := Color("66bdf0")   # (BLUE_TOP)
const CORAL := Color("e0614f")        # (CORAL_BOTTOM)
const CORAL_LIGHT := Color("ff9b8a")  # (CORAL_TOP)
const SUN := Color("f7cf3f")          # daisy centres only
const LEAF := Color("8fd067")
const LEAF_DARK := Color("5aa83a")
const TERM := Color("d9661c")         # words to learn in a dialogue line

# --- Town: building surfaces -----------------------------------------------------------------
# A little deeper than the UI cream: sunlight brightens albedo, and walls must not glare white.
const WALL_CREAM := Color("f2e6cf")   # walls of every shop and house
const TRIM := Color("fbf5ea")         # sills, door jambs, sign boards, copings, awning stripes
const STONE := Color("c9b79c")        # base bands, door steps, planters
const IRON := Color("33454d")         # lamps, brackets, rails (dark teal-grey, not black)
const WOOD := Color("b97f4a")         # timber cladding, flower boxes
const WOOD_DARK := Color("7a4a22")    # cladding grooves, dark joinery (= BROWN)
const ROOF := Color("5b6670")         # flat roof tops

# --- Town: accents (one family per building: light, main, deep) -------------------------------
# Main colours awnings, canopies and signs; deep colours frames, pillars, parapets and roof edges;
# light colours emblems on a deep ground. All five share strength and brightness.
const ACCENTS := {
	"coral": [Color("ffc2b5"), Color("e0614f"), Color("b8463a")],   # UI coral
	"rose": [PIG, Color("e07a96"), Color("b44a6a")],                # BonBon pink
	"sky": [Color("a9d8f5"), Color("3d93d6"), Color("2a6aa8")],      # UI blue
	"meadow": [Color("bfe6a3"), Color("52b046"), Color("2f8a3a")],   # UI green
	"teal": [MINT, INK_SOFT, INK],                                   # icon mint, UI ink
}

static func accent(family: String, tone: int) -> Color:
	return ACCENTS[family][tone]
