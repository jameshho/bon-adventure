extends RefCounted
## The game's small UI icons (dialogue choices, minigame buttons, Settings), drawn as white
## line art and tinted by the button's font colour. Kept as SVG text here and rasterised at
## runtime (Image.load_svg_from_string), so there are no image files to import and every
## icon scales crisply with the window. Use: button.icon = UiIcons.texture("trash", 28).
## Names: check, no, close, money, hand, trash, next, exit, retry, question, back, play (keep
## playing: the quit card's Stay), gear,
## box and box_checked (the Settings checkbox),
## and the detective tools look (magnifier), touch (pointing finger), ear, choose (target),
## squeeze (two arrows pressing a cushion) and lift (an arrow raising a box) (evidence game
## tools since 8 Nov 2026: squeeze, touch, lift),
## and the flight board's takeoff / landing (a runway line with an arrow leaving or reaching it),
## and star / book (the vocabulary journal's Saved and All tabs; down, its menus' arrow; 9 Nov 2026),
## and sun / moon / pause / minus / plus (the HUD clock, day_clock.gd, 9 Nov 2026),
## and the minigame picker's game icons cart / family / cloche / pencil / door / tiles / radar /
## bolt (game_launcher.gd, 10 Nov 2026),
## and police / person / screen (the bank teller game, 21 Nov 2026).

const _HEAD := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#ffffff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">'
const SHAPES := {
	"check": '<path d="M4 12.5l5 5L20 6.5"/>',
	"no": '<circle cx="12" cy="12" r="8.5"/><path d="M6 18L18 6"/>',
	"close": '<path d="M6 6l12 12M18 6L6 18"/>',
	"money": '<rect x="2.5" y="6" width="19" height="12" rx="2"/><circle cx="12" cy="12" r="2.8"/><path d="M6 9.5v5M18 9.5v5"/>',
	"hand": '<circle cx="15.5" cy="5.5" r="3"/><path d="M2.5 14.5h3l3.5 4.5h7.5l5-5.5c.6-.8-.3-2-1.3-1.4L16 15H11"/><path d="M5.5 14.5l2.7-2.4c.7-.6 1.6-.9 2.5-.9H14c1 0 1.6 1.2.9 2l-.9 1H10.5"/>',
	"trash": '<path d="M4 6.5h16M9.5 6.5V4h5v2.5M6.5 6.5l1 14h9l1-14M10 10v7M14 10v7"/>',
	"next": '<path d="M4 12h15M13 6l6 6-6 6"/>',
	"exit": '<path d="M14 4H5v16h9"/><path d="M10 12h11M17 8l4 4-4 4"/>',
	"retry": '<path d="M4.5 12a7.5 7.5 0 1 0 2.2-5.3"/><path d="M4 3.5v4.5h4.5"/>',
	"question": '<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.6 2.2c-.7.4-1.1 1-1.1 1.8v.5"/><circle cx="12" cy="17.2" r=".6" fill="#ffffff"/>',
	"back": '<path d="M20 12H5M11 6l-6 6 6 6"/>',
	"play": '<path d="M8 5.5v13l10.5-6.5z"/>',
	"look": '<circle cx="10" cy="10" r="6.5"/><path d="M15 15l6.5 6.5"/><path d="M7 8.5a3.5 3.5 0 0 1 3-2"/>',
	"touch": '<path d="M9 13V4.5a1.6 1.6 0 0 1 3.2 0V11"/><path d="M12.2 10.5a1.6 1.6 0 0 1 3.2 0v1"/><path d="M15.4 11.2a1.6 1.6 0 0 1 3.1.3v3.5c0 3.6-2.4 6.5-6 6.5h-1c-2.2 0-3.6-1-4.8-2.8L4 14.6c-.7-1 .5-2.4 1.6-1.6L9 15.5"/>',
	"ear": '<path d="M7 9a5.5 5.5 0 0 1 11 0c0 3.2-2.5 4.4-3.4 6.3-.8 1.8-1.2 3.7-3.6 4.2-1.8.4-3.2-.6-3.6-2"/><path d="M10 9.5a2.5 2.5 0 0 1 5 0c0 1.4-1.3 1.9-1.8 3"/>',
	"squeeze": '<path d="M12 2.5v5M9 5l3 3 3-3"/><path d="M12 21.5v-5M9 19l3-3 3 3"/><rect x="3.5" y="9.5" width="17" height="5" rx="2.5"/>',
	"lift": '<rect x="6.5" y="13.5" width="11" height="8" rx="1.5"/><path d="M12 11V2.5M8.5 6l3.5-3.5L15.5 6"/>',
	"choose": '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4"/><circle cx="12" cy="12" r=".8" fill="#ffffff"/>',
	"box": '<rect x="3" y="3" width="18" height="18" rx="3.5"/>',
	"box_checked": '<rect x="3" y="3" width="18" height="18" rx="3.5"/><path d="M7 12.5l3.5 3.5L17.5 8"/>',
	"takeoff": '<path d="M3 20.5h18"/><path d="M5 16.5L18 5"/><path d="M11 5h7v7"/>',
	"landing": '<path d="M3 20.5h18"/><path d="M5 4.5l12 11"/><path d="M17 9v6.5h-6.5"/>',
	"down": '<path d="M6 9.5l6 6 6-6"/>',
	"star": '<path d="M12 3.2l2.7 5.5 6.1.9-4.4 4.3 1 6.1L12 17.1l-5.4 2.9 1-6.1-4.4-4.3 6.1-.9z"/>',
	"book": '<path d="M12 6.5C10 5 7 4.6 3.5 5v13.2c3.5-.4 6.5.1 8.5 1.6 2-1.5 5-2 8.5-1.6V5C17 4.6 14 5 12 6.5z"/><path d="M12 6.5v13.3"/>',
	"gear": '<circle cx="12" cy="12" r="3.2"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/><circle cx="12" cy="12" r="6.3"/>',
	# The HUD clock (day_clock.gd, 9 Nov 2026): sun / moon by time of day, pause while stopped,
	# minus / plus for one hour earlier / later.
	"sun": '<circle cx="12" cy="12" r="4.2"/><path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.3 5.3l1.6 1.6M17.1 17.1l1.6 1.6M5.3 18.7l1.6-1.6M17.1 6.9l1.6-1.6"/>',
	"moon": '<path d="M19.5 14.5A8 8 0 1 1 9.5 4.5a6.5 6.5 0 0 0 10 10z"/>',
	"pause": '<path d="M9 6v12M15 6v12"/>',
	"minus": '<path d="M5.5 12h13"/>',
	"plus": '<path d="M12 5.5v13M5.5 12h13"/>',
	# Minigame picker tiles (game_launcher.gd, 10 Nov 2026): cart, family, cloche, pencil,
	# door, tiles, radar and bolt (with money, lift, takeoff, look and squeeze above).
	"cart": '<path d="M2.5 4h3l2.2 10.5h10.8l2-7.5H6.6"/><circle cx="9.5" cy="19" r="1.6"/><circle cx="17" cy="19" r="1.6"/>',
	"family": '<circle cx="8" cy="7" r="3"/><circle cx="17" cy="9" r="2.3"/><path d="M2.5 20v-2.5a5.5 5.5 0 0 1 11 0V20"/><path d="M14 20v-2a3.5 3.5 0 0 1 7.5 0v2"/>',
	"cloche": '<path d="M3 17.5h18"/><path d="M4.5 17.5a7.5 7.5 0 0 1 15 0"/><path d="M12 10V7.5M10.5 7.5h3"/><path d="M5 20.5h14"/>',
	"pencil": '<path d="M4 20l1.2-4.8L15.5 4.9a2 2 0 0 1 2.8 0l.8.8a2 2 0 0 1 0 2.8L8.8 18.8z"/><path d="M13.5 7l3.5 3.5"/>',
	"door": '<path d="M5.5 21V4a1 1 0 0 1 1-1h11a1 1 0 0 1 1 1v17"/><path d="M3 21h18"/><circle cx="15" cy="12.5" r=".9" fill="#ffffff"/>',
	"tiles": '<rect x="3.5" y="4" width="7.5" height="10.5" rx="1.5"/><rect x="13" y="9.5" width="7.5" height="10.5" rx="1.5"/><path d="M7.2 7.5v3.5M16.7 13v3.5M15 14.8h3.5"/>',
	"radar": '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><path d="M12 12l6.4-6.4"/><circle cx="15.5" cy="15" r="1" fill="#ffffff"/>',
	"map": '<path d="M3 6.5l6-2.5 6 2.5 6-2.5v13.5l-6 2.5-6-2.5-6 2.5z"/><path d="M9 4v13.5M15 6.5V20"/>',
	"bolt": '<path d="M13.5 2.5L5 13.5h6l-1.5 8 8.5-11h-6z"/>',
}

static var _cache: Dictionary = {}
	# The bank teller game (teller_session.gd, 21 Nov 2026): police (a badge shield with a star:
	# "Call the police"), person (a head and shoulders: look at the customer) and screen (a
	# desk monitor: look at the account).
	"police": '<path d="M12 2.5l7.5 3v6c0 4.6-3.2 8.3-7.5 10-4.3-1.7-7.5-5.4-7.5-10v-6z"/><path d="M12 7.6l1.3 2.6 2.9.4-2.1 2 .5 2.9L12 14.2l-2.6 1.3.5-2.9-2.1-2 2.9-.4z"/>',
	"person": '<circle cx="12" cy="8" r="4"/><path d="M4 21v-1.5a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6V21"/>',
	"screen": '<rect x="2.5" y="4" width="19" height="12.5" rx="1.5"/><path d="M12 16.5v3.5M7.5 20.5h9"/>',

## The icon `name` as a square texture `pixels` wide (cached per size).
static func texture(name: String, pixels: int = 28) -> Texture2D:
	pixels = clampi(pixels, 8, 256)
	var key := "%s@%d" % [name, pixels]
	if _cache.has(key):
		return _cache[key]
	if not SHAPES.has(name):
		push_warning("ui_icons: unknown icon '%s'" % name)
		return null
	var image := Image.new()
	var error := image.load_svg_from_string(_HEAD + str(SHAPES[name]) + "</svg>", pixels / 24.0)
	if error != OK:
		push_warning("ui_icons: could not draw '%s'" % name)
		return null
	var made := ImageTexture.create_from_image(image)
	_cache[key] = made
	return made
