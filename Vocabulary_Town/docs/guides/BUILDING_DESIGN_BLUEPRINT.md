# Building design blueprint

**Project:** Spanish Vocabulary Town  
**Version:** 2.0, 21 October 2026  
**Status:** Design guidance, not an implementation report  
**Scope:** Visual design and safe improvement of new and existing buildings

**Start with the [master town blueprint](TOWN_DESIGN_BRIEF.md#start-here-current-approved-design).**
This file supplies shared architectural standards; the master owns approved
building programs, scope and current decision status.

## Current design authority — 25 October 2026

The [dimension review](BUILDING_DIMENSION_REVIEW.md) contains measured capacity and
dimensional targets: school 24 × 18 single-story and supermarket 26 × 26 are
implemented at runtime; all other proposed dimensional changes remain unapproved.
See the [resize ownership, preservation and evidence](BUILDING_DIMENSION_REVIEW.md#implemented-resize--25-october-2026).
It supersedes the earlier sizing deferral; current site positions stay approved.

The [town design brief](TOWN_DESIGN_BRIEF.md) owns the latest building programs,
confirmed user decisions and exterior audit. It supersedes conflicting older
school, hospital, supermarket and restaurant concepts. This blueprint retains
shared art direction and acceptance rules. Current interiors stay intact during
the exterior audit; their documented future replacements are not blocked by
older blanket preservation instructions. House/library interiors remain protected.

Current exterior milestone: the user accepted the school result and selected **café/bakery and bank** next. Their [implemented result and matching Main views](TOWN_DESIGN_BRIEF.md#café-and-bank-exterior-review--25-october-2026) await review. School remains unchanged; the supermarket subsequently received the [26 October color refinement](TOWN_DESIGN_BRIEF.md#supermarket-color-refinement--26-october-2026). The pilot/backlog below is a suggested future sequence and does not authorize further work.

School interior follow-up: the [26 October single-divider plan](TOWN_DESIGN_BRIEF.md#school-single-divider-layout--26-october-2026) supersedes the earlier two-room/hall arrangement while preserving the exterior and dimensions.

## How to use this blueprint

### Town map blueprint

**23 October update:** the user's compact, horizontal-park redesign supersedes
the original image's exact district positions. The [current rendered layout](../evidence/part2/compact-overview.png)
and [architecture ownership notes](ARCHITECTURE_REVIEW_PART1.md#coordinates-roads-and-visual-standards)
describe the implemented arrangement. The original image remains an art/style
reference; the preservation-of-positions statements below describe earlier passes.

The [user-supplied island map](design-references/town-map-blueprint.png), saved on 21 October 2026,
is the visual blueprint for future town development. Keep the rounded rectangular
road loop around the central park, front parking areas with short approaches,
the pictured district arrangement, and the home south of the loop. Use the
[separate home reference](design-references/home-interior-reference.png) for the home's interior.
Consult these original images, not just screenshots of earlier implementations.

The first implementation pass is intentionally basic: regularize roads and parking,
then outline existing building exteriors with simple eaves and corner posts.
Detailed facades and landscaping are later work. Preserve current interiors,
entrances and vehicle positions when fitting the blueprint. The image is a design
reference, not a replacement coordinate dataset: the saved world's reflected
coordinates and actual collision geometry remain the implementation constraints.
Current road/parking ownership and dimensions are in the
[architecture guide](ARCHITECTURE_REVIEW_PART1.md#coordinates-roads-and-visual-standards).

The subsequent exterior pass uses `building_exteriors.gd::decorate()` on the live
town after the outline pass. Its 20 facade groups cover the 17 main building fronts,
home porch, gazebo and control tower. Map-inspired features now include:

| Buildings | Exterior identity |
| --- | --- |
| Hospital / school | Medical front/cross/canopy retained; school now has a warm brick base, plaster, classroom window groups, small canopy and compact wall clock below its green roof |
| Sports / furniture / clothing | Green sports pediment; cream-trimmed gables and framed display windows |
| Bakery / three restaurants | Warm fronts, striped awnings, gables, separate cafe/pizzeria/restaurant signs |
| Electronics / supermarket | Electronics screen-emblem crown retained; supermarket now has teal fascia and ochre entrance accents, wide framed glazing, central canopy and matte slate roof; see the current review above |
| Bank / library / police | Classical portico columns, gabled fronts and blue/stone palettes |
| Chapel / barn | Tower and faceted spire; red accents and white barn braces |
| Airport / control tower | Blue terminal canopy and framed glazing; observation glass and red faceted cap |
| Gazebo / home | Terracotta faceted gazebo roof; warm porch canopy and terracotta hip roof that lifts inside the home |

These are stylized adaptations within the current footprints and storey heights,
not exact replicas of the illustrated buildings. Existing interiors, stairs, roofs'
physical surfaces, hospital helipad, doors and vehicle placement remain in place.
Additions are non-blocking visual geometry, with vocabulary Areas only where a
canonical exterior word already exists. No new vocabulary keys are introduced.
Use `docs/evidence/town-checks/check_map_facades.gd` for facade coverage, street picking, idempotency and
minimap checks. See the [verification record](FINAL_VERIFICATION.md#map-inspired-exteriors--21-october-2026)
for tested behavior and limitations.

This is the shared art-direction and building-quality standard, not a replacement for game architecture documentation. It sets design goals and verification expectations; it does not imply that existing scenes already comply.

**Source of truth and precedence:** the latest user programs and scoped approvals
in the [town brief](TOWN_DESIGN_BRIEF.md) take precedence over older design goals;
the hierarchy below governs implementation and shared quality rules.

1. [`ARCHITECTURE_REVIEW_PART1.md`](ARCHITECTURE_REVIEW_PART1.md) controls actual scene ownership, coordinate systems, runtime construction, interactions, and vocabulary data.
2. Existing building-specific documentation and live implementation determine the current footprint, rooms, doors, and constraints. If documentation and code disagree, inspect the live scene and record the discrepancy rather than assuming either is correct.
3. **This blueprint** controls proposed shared visual direction and quality checks, except where preserving actual existing functionality requires a different solution.
4. [`BUILDING_SPEC_TEMPLATE.md`](BUILDING_SPEC_TEMPLATE.md) is the compact specification format for one building task. An established building-specific guide may contain the completed specification instead.
5. [`BUILDING_COMPONENT_CATALOG.md`](BUILDING_COMPONENT_CATALOG.md) defines how to audit, identify, and safely reuse existing components. It is a catalog framework, not a claim that all listed components already exist.

**Typical task:** read authoritative references, inspect the live owner, fill in a concise building brief, edit only the approved scope, verify function and appearance, then update the task record. Do not expand scope simply to comply with an aesthetic target.

---

## 1. Design direction

Build a welcoming garden town with warm stone, painted plaster, wood, restrained color and clearly readable architecture. Keep the approachable, stylized geometry of the current game. Buildings should feel deliberately designed and inhabited while allowing the learner to recognize, approach and study objects easily.

A building should read at three distances:

| View | What the player should recognize |
| --- | --- |
| Town overview | Building silhouette, roof color, entrance direction and relationship to its street |
| Walking approach | Purpose, name, main entrance, windows and a small amount of characteristic detail |
| Close exploration | Supported fixtures, finished edges, useful signs, coherent furnishings and individual vocabulary objects |

Give each building one strong architectural gesture: a bakery awning, library reading window, school entrance canopy or chapel gable. Repeat a few town-wide materials and details to connect the buildings. Avoid making every location the same box with a different sign. Spanish vocabulary does not require every building to imitate one regional architectural style.

### Building recognizability and distinctiveness

Consistency comes from material families, proportion logic, and detailing quality. Identity comes from **purpose-led massing**, one signature architectural feature, characteristic openings, and an entrance that fits the activity. Do not rely on sign text or accent color alone to differentiate buildings.

Before choosing details, record a one-sentence silhouette test in the building specification: *If the sign and accent colors were hidden, what would still identify this building?* If the answer is "nothing," revise the proposal while respecting existing functional geometry.

Use contrast and size to support the game's learning purpose. A characteristic feature must remain recognizable from the standard walking camera; small objects must remain individually readable and selectable at close range. Decorative detail must never obscure an important vocabulary object.

## 2. Preserve the town while improving it

For existing buildings, start with finishes, entrance clarity, window framing, roof edges and planting. Keep the established footprint, position, interior root, room arrangement and functioning connections unless a separate task explicitly calls for changing them. Preserve characters, learning displays and their keys.

An existing doorway, staircase, garage bay, rooftop landing or helipad is a functional constraint. New decoration must fit around it. Never shrink or stretch a whole building to obtain a different visual proportion.

For new buildings, establish the intended activity, site, entrance, circulation and learning objects before decorating. Confirm that the footprint fits its plot and connects to the town's streets and pedestrian paths.

### Change boundaries and exceptions

Classify each proposed change before editing:

| Change class | Examples | Default approval rule |
| --- | --- | --- |
| Visual-only | Local trim, color, wall finish, non-obstructing planting | Allowed when the task requests visual improvement and checks pass |
| Geometry-within-footprint | Recessed façade, framed window, canopy supports | Allowed only after checking collision, camera, openings, and existing room compatibility |
| Functional/layout | Doors, walls, room positions, roads, circulation, vehicle access, vocabulary roots | Out of scope unless the task separately authorizes the specific change |
| Global systems | Lighting/exposure, shared material ownership, vocabulary schema, scene manager | Out of scope unless explicitly requested and justified with multi-building regression checks |

When a requested aesthetic cannot be achieved within the allowed class, report the constraint and propose a scoped alternative. Do not silently relocate a building, remove an interior, or introduce a new global system.

## 3. Massing, roofs and façade composition

Compose each façade as a base, wall body and roof edge. A shallow plinth grounds the building; organized openings give it rhythm; an eave, fascia or parapet finishes its silhouette. Use a main volume and, where useful, one subordinate entrance or service volume. Additional volumes need a recognizable purpose.

| Element | Shared design rule |
| --- | --- |
| Base | Use a slightly darker stone/plaster band; stop trim cleanly at doors and ramps |
| Wall body | Align window heads and sills within each floor; use consistent spacing within a façade |
| Entrance | Make one entrance visually dominant with a recess, canopy or framed opening |
| Roof edge | Give the roof visible thickness; align fascia and corners; use a restrained overhang |
| Side/rear walls | Continue materials and trim; use windows or service details where compatible with the rooms behind them |
| Multi-storey buildings | Align structural bays and floor bands vertically; express the ground-floor entry distinctly |
| Large blank walls | Break up with a material band, shallow pilaster, planting or a room-compatible window; choose one treatment first |

The user's 21 October roof request supersedes the earlier open-top home direction. The home now has a decorative terracotta hip roof that lifts while the learner is inside; see [home ownership and dimensions](REFERENCE_HOME.md). Other roofs retain their camera visibility and walkable/landing behavior. Pitched roofs suit small domestic, café or chapel volumes; simple parapets suit the existing civic and retail shells. Preserve the hospital helipad's usable envelope and approach.

### Dimensional starting points

These are **proposed design targets**, in town-local units after any model-local transform and before Apartment's 1.3 scale. They are not measurements of every current building or real-world construction requirements. Check actual player, camera, door swing and collision clearance; keep larger existing clearances.

| Element | Starting target for new work |
| --- | --- |
| Placement grid | 0.25-unit increments for major new parts; align fine trim to the actual opening |
| Single-storey room clear height | 3.2–4.0, adjusted for camera visibility and the building's activity |
| Existing civic storey spacing | Retain the authored spacing; the school/hospital generator uses 5.6 |
| New pedestrian doorway | At least 1.8 clear width and 2.6 clear height; widen for public double entrances |
| Main interior circulation | Aim for 2.8–3.2 clear width; increase at turns, queues and stairs |
| Secondary furniture aisles | Aim for at least 2.2 clear width, including occupied chair positions |
| Exterior approach | Aim for at least 3.0 clear width, with a level area outside the entrance |
| New wall thickness | Start around 0.18–0.25; align visible and collision surfaces |
| Window/door trim | Roughly 0.06–0.14 thick; enough to read without covering glazing or lettering |
| Entrance canopy projection | Roughly 0.8–1.4, with adequate headroom and visible support |
| Small-object displays | Usually 0.8–1.2 above the floor; choose height for recognition and picking |

Existing home door openings use their own established dimensions and eight-door layout. Do not widen them to match this table during a finishes pass. Vehicle bays, medical equipment routes and other special clearances require their own checks.

### Proportion and scale validation

Do not treat proposed unit targets as measurements of existing geometry. At the start of a building task, record actual values for the player avatar, door clear opening, a representative counter/chair, and the applicable approach width, all expressed in a **common final world-space coordinate system**. Include collision bounds when they differ from visible geometry.

| Reference | Record and test |
| --- | --- |
| Player | Standing height, width, controller clearance, and typical camera position |
| Doors | Visible opening, collision opening, operating swing/path, and interaction reach |
| Windows | Sill and head heights relative to the floor, player eye line, and actual interior room |
| Furniture | Counter height, seat/table relationships, and aisle clearance with occupied chairs |
| Vehicles | Actual bay clearance, approach, orientation, and turning/entry needs, if relevant |
| Sign/learning display | Readability or recognition at the intended camera distance; pickability at close range |

Resolve **model-local, building-local, town-local, and final scaled world-space** coordinates explicitly. For the Apartment, account for its existing 1.3 scale at the documented stage rather than applying it twice. Use actual transforms and inspection, not copied dimensions from another building. Preserve a larger existing clearance even if the design target is smaller.

## 4. Shared palette and materials

Use a light neutral body, a secondary natural material and one identity accent. As a starting composition, let neutrals occupy about two thirds of the visible façade, secondary materials most of the remainder, and accents a small portion. Judge the result in the actual renderer rather than enforcing exact percentages.

Reuse existing materials when suitable. The following is the shared palette; selected references come directly from the current home and outdoor refinement scripts. Additional façade colors below are design choices for future work.

| Role | Reference color | Application |
| --- | --- | --- |
| Ivory plaster | `#EEE5D4` | Warm wall body and interior walls; current home reference |
| Pale stone | `#D0CDBB` | Plinths, civic trim and quiet counters; current statue stone reference |
| Oak | `#C4A477` | Doors, furniture, cabinetry and selected façade framing; current home reference |
| Warm paving | `#DBC8A6` | Shared pedestrian approach and garden path family |
| Deep teal | `#496F78` | Doors, sign panels and selected upholstery; current home reference |
| Terracotta | `#B98367` | Bakery/café accents and selected small roofs |
| Ochre | `#C5A267` | School or warm retail identity accents |
| Slate blue | `#647F94` | Electronics, airport or civic identity accents |
| Forest green | `#4C6558` | Library signs, metalwork and garden-facing details |
| Dark lettering | `#293E40` | Lettering on light signs, restrained frames and small hardware |
| Pale glazing | `#B6D5D9` | Shared glazing color family; current home reference |

Use matte plaster, stone and wood; use restrained reflections on metal and glass. A roughness of approximately 0.8–1.0 is a starting point for matte finishes, not a setting to apply to every resource. Create depth with geometry, recesses and shadow. Avoid dense surface noise, shiny plastic walls and a unique texture for every building. Use a limited set of related colors within each material family.

Keep identity accents on entrances, signs, awnings or a selected band. Preserve existing hospital/school floor color coding; do not replace it with a single exterior accent throughout the interior.

### Material ownership and reuse

Maintain a single palette reference here rather than repeating hex colors in building specifications. In the component catalog, identify which material resources are **actually shared**, which are **building-specific instances**, and which are **proposed but not implemented**. Reuse existing resources when safe; duplicate/instance a material for local variations if changing the original would recolor unrelated buildings. Confirm how transparency, normals, light response, and batching behave in the actual renderer.

An accent color alone must not carry a building's identity. Pair color with a distinctive silhouette, opening pattern, or signature detail. Sign readability and learning-object clarity take priority over decorative color matching.

## 5. Windows, entrances and signs

Windows need a sill, frame and convincing connection to the wall. Position mullions within the opening rather than across unrelated wall surfaces. Use room-compatible openings: a large reading window suits a library; a high private window may suit a bathroom. Inspect glass in Compatibility rendering and avoid overlapping transparent panes or glazing that obscures learning displays.

An entrance should show a continuous route from the street to the interior. Frame it with light, a canopy, a shallow recess or a change of paving. Place paired planters beside that route, allowing for door swings and the orbiting camera. Attach canopy posts and lights visibly to supporting geometry. Keep open bays open.

Use one primary building-name sign per main façade. Center lettering within its panel, with visible margins on all sides. Separate the primary sign from smaller opening-hours, department or direction signs. Choose text size by readability at the normal approach camera, not by a fixed font-size value alone. Use light text on a dark panel or dark text on a pale panel; avoid low-contrast lettering.

### Sign readability

Measured 16 November 2026 ([evidence](../evidence/world-signs-20261116/), user: signs were hard
to read). Lettering turns into blobs when its capitals are under about 6 px on screen; on a
landscape phone (390 px high, 70° view, the web LOW tier) that is a letter height (em,
`font_size × pixel_size` in world metres) under about 1/32 of the viewing distance. The cause was
size, not blur, so sharper font rendering (MSDF) was not adopted. The rule:

- **Letter height ≥ reading distance / 30.** The reading distance is the farthest the player
  should read the sign from: an aisle or department band, across the hall (supermarket: 18 m);
  a price or tag, arm's length to a few metres (5–6 m); a facade name, the street (15 m).
- **A translation never shrinks a sign below that height.** It may shrink to the board's free
  width, and a sign with room for lines wraps instead.
- **Contrast 4.5 (WCAG AA)** between the lettering and its board; where the board's own colour
  falls short, an outline in a darker (or lighter) shade of the board supplies it.
- **The board fits the lettering** in every language, with visible margins; a small tag grows to
  its text rather than the text shrinking to the tag.

All of this is built into the [world sign component](COMPONENTS.md#world-signs); new signs use it.

Sign text may be localized using reviewed existing vocabulary. Display labels do not create new dictionary keys or aliases. Preserve building `exterior_word` metadata and existing bilingual interaction behavior. Do not place a large invisible picking slab across an entrance to make a sign selectable.

## 6. Interior design and learning displays

Plan the entrance, central circulation and destination first. From the threshold, show one clear reason to enter: reception, a checkout, a book display or the main classroom activity. Connect secondary rooms to that route without hiding doorways behind furniture. Support fixtures physically and finish their visible backs.

Use the exterior's material family inside, with softer accents and quieter floors. Group related furnishings into recognizable activity areas. Prefer a few complete arrangements over many scattered props: a reading chair with lamp and table; a checkout with a queue area; a patient bed with nearby equipment.

Shop goods follow the [product style guide](TOWN_DESIGN_BRIEF.md#supermarket-product-art--8-november-2026) (8 Nov 2026): a distinct silhouette per word, a picture of the contents on package fronts, three shared finishes and one shared mesh per product.

Learning displays must remain recognizable objects with clear space around them. Use shelves and counters to raise small items; avoid enlarging a whole room or stacking props until only their labels distinguish them. Keep mesh, collision and picking under the established word root. Reuse vocabulary prefabs and the existing interaction controller; follow the architecture guide for any data additions.

Preserve the complete home and library interiors. During exterior-only work, keep current grocery and civic routes operational. Future school, hospital and supermarket interiors follow the latest [building programs](TOWN_DESIGN_BRIEF.md#building-programs-for-future-work), which supersede older room/wing and compact-grocery targets. Do not implement those changes during this audit.

## 7. Building identities and improvement briefs

This table is the starting brief for each type. The improvement column is proposed work to inspect and scope, not a list of confirmed defects or completed changes.

| Building/type | Identity and characteristic detail | First improvement brief |
| --- | --- | --- |
| Home | Ivory, oak and teal; domestic windows, framed doors and a furnished terrace | Terracotta hip roof; retain garage, pool and current eight doors; see REFERENCE_HOME.md |
| Library | Warm plaster, oak and forest green; framed reading windows and a quiet entry | Bring the exterior up to the existing interior's warmth; align sign, windows and entrance trim |
| Supermarket | Cream body, teal fascia, ochre entrance canopy/portal and terracotta plinth; wide framed glazing, existing carts and planters | Implemented at fixed 26 × 26 / 5.71 clear height; awaits user review. Nine-department interior implemented for review on 26 October; see the master brief |
| Bakery/café | Cream/oak, wine awnings, framed glazing, coffee-cup gable and CAFÉ & BAKERY sign | Exterior implemented at unchanged 14 × 22; awaits review. Existing displays/learning content retained; full café interior remains future work |
| School | Warm brick/plaster, green canopy and roof edge, grouped classroom windows, centered SCHOOL sign and compact clock | Exterior implemented at fixed 24 × 18 single-story / 4.6 clear height; awaits user review. Current interior has one rear-half center divider and an open front half; see the master brief |
| Hospital | Pale stone/plaster with teal; canopy, cross and clear wayfinding | Fit the new three-floor program; protect ambulance access, helicopter/helipad and bed design; older departments/wing are not mandatory future requirements |
| Bank | Pale stone, dark blue framing, ordered glazing and flat entry canopy | Exterior implemented at unchanged 12 × 15; awaits review. ATMs remain inside; vault, teller/office layout and learning targets retained |
| Police station | Light neutral with slate blue; simple civic sign and practical canopy | Hold changes pending station decision; explicit approval required for removal, retain police car and useful learning content. Relocated (appearance unchanged) to the east side on 28 October 2026. |
| Clothing store | Warm neutral with a muted rose/terracotta accent; display window and awning | Frame existing displays and give the entrance a distinct outline without crowding it |
| Electronics store | Pale body with slate/teal; crisp glazing and tidy display bays | Improve window framing and fascia alignment; retain visible, separately selectable products |
| Furniture store | Cream and oak; broad framed display bays | Make complete furniture groupings visible from the entrance; preserve generous circulation |
| Sports store | Light neutral with restrained ochre/teal; energetic sign and a clear product display | Distinguish entry and display zones; keep bicycles and larger equipment out of the approach |
| Restaurants | Related warm plaster, wood and distinct muted accents; individual awnings and small terraces | Fine dining (merged Pizza + Burger shells, cream/teal, arched windows) and Pizza and Burger (L-shaped red/cream, glass front) built 28 October 2026 in place of the earlier plan; a Mexican restaurant (TAQUERÍA, Mexican-pink accent `b83a6e`) replaces restaurant Cafe — built 28 October 2026, superseding the Chinese seafood plan. BakeryCafe remains separate; implement only after scope approval |
| Airport | Pale stone with slate/teal; identifiable terminal canopy and simple entrance directory | Clarify terminal frontage and parking arrival; protect taxiway, runway and vehicle clearances |
| Chapel | Warm plaster and stone; simple gable or existing landmark silhouette | Improve entry depth and restrained glazing/trim; preserve its garden approach |
| Barn/farm buildings | Timber and muted red/ochre; broad practical openings | Finish roof edges and supports; preserve gates, animals and their movement space |
| New building types | Shared neutral/natural materials plus one distinct function-led gesture | Establish activity, entrance, silhouette, palette and learning content before adding ornament |

### Architectural identity checklist

For each building task, record the five decisions below in its specification. The defaults are **design proposals**, not verified features of existing buildings.

1. **Massing:** Primary volume and any existing subordinate volume; what must remain untouched?
2. **Signature:** One memorable purpose-led feature (for example, library reading window or bank entrance frame).
3. **Openings:** Window rhythm, entrance emphasis, and connections to actual rooms.
4. **Arrival:** Route from street, entrance orientation, sign position, and functional clearance.
5. **Interior clue:** The first recognizable activity or vocabulary grouping seen on entry.

**Contrast examples:** A library may feel open and informal through a broad reading window and warm wood, while a bank may feel formal through repeated bays and a substantial central entry. A bakery may emphasize a display window and terracotta awning; an electronics store may prioritize crisp glazing and individual product visibility. Do not impose new roof shapes or symmetry on an existing building if doing so conflicts with its footprint or circulation.

A successful building should still be distinguishable from its immediate neighbors in an overview screenshot after temporarily hiding signs and identity accents. Treat this as a qualitative review, not an automatic image test.

## 8. Streetscape, lighting and detail density

Connect the entrance to the existing pavement with compatible materials. Keep pedestrian routes visually distinct from parking and driveways. Place benches, bins and planters where they support arrival or waiting; keep the entrance's centerline clear. Use planting in small groups with deliberate gaps, following the current park's muted green, pink and warm yellow family.

Concentrate detail around entrances, windows and human-scale activity. Keep large wall and roof areas quieter. Check the building from both the street and the town overview; trim that only creates distant flickering is too fine or too repetitive.

Use the game's current daylight as the review baseline. Add local interior light only where the room needs it, with visible supported fixtures. A proposal to change global sunlight, ambient light or exposure must include home, retail and civic interior comparisons. Do not compensate for one building's color with a town-wide lighting change.

## 9. Improvement sequence

The [current prioritized plan](TOWN_DESIGN_BRIEF.md#decisions-still-needed-and-prioritized-implementation-plan)
preserves approved building positions; the latest user request requires dimensional
review and approval before exterior implementation. See the measured capacity review.
Police changes remain frozen pending a retention/removal decision (the 28 October 2026 relocation moved it unchanged).

| Priority | Work package | Review outcome |
| --- | --- | --- |
| P1 | Establish a pilot pair: bakery/café and library exterior | Two complementary façades demonstrate the shared palette, entrance, window and roof-edge rules |
| P1 | Apply common entrance/sign/trim treatment to other shops | Each shop remains identifiable; approaches, signs and merchandise stay readable |
| P2 | Refine school and hospital façades | Civic buildings have a coherent family and distinct identities; current routes remain operational until separately scoped program changes; helicopter and bed design protected |
| P2 | Refine bank, airport and approved restaurant frontage | The public street reads as a connected town with clear arrivals and useful details |
| P3 | Refine home, chapel and farm finishing details | Domestic and landscape buildings feel related without losing their existing character |
| P3 | Audit side/rear elevations and close-up details across completed buildings | Visible gaps, unsupported fixtures, clipping, repeated blank walls and unnecessary detail are resolved |

Complete and render the pilot pair before spreading a new detail treatment across the town. This sequence is a suggested implementation backlog; creating this guide does not implement or verify any of these building changes.

### Pilot release gates

Treat the bakery/café and library as a **pilot pair**, not a mandate to redesign the whole town. Complete each gate before broad rollout:

| Gate | Evidence required | Decision |
| --- | --- | --- |
| A. Baseline | Live owner confirmed; preserved elements and matching before views recorded | Scope can be approved |
| B. Pilot implementation | Exactly scoped changes; materials and reusable candidates identified | Ready for testing |
| C. Functional regression | Doors, player routes, picking, camera, related special access pass | No regressions introduced |
| D. Visual review | Silhouette, entrance, windows, sign, detailing, interior, and neighboring context checked | Pilot aesthetic approved or revised |
| E. Performance | Same-view comparison recorded if detail-heavy; any material cost explained | Reuse design across related buildings or simplify |

Do not generalize a new component or façade treatment to other sites until the pilot demonstrates that it works in the live renderer and does not harm functionality.

## 10. Required brief for each building task

Use the following compact brief in the task or an existing building-specific guide. Keep one authoritative version rather than copying it into several reports.

| Field | Record before implementation |
| --- | --- |
| Building and goal | Location, activity and the specific visual improvement |
| Existing owner | Prefab, saved instance override, runtime builder/pass and relevant node path |
| Preserve | Footprint, interior root, entrances, door states, occupants, learning objects and vehicle/roof access |
| Design | Main silhouette, entrance gesture, base/secondary/accent palette and window/roof treatment |
| Dimensions | Actual opening, approach and aisle clearances; coordinate space and effective scale |
| Work scope | Exact surfaces/details being edited; any separately authorized layout change |
| Views | Before/after town context, street approach, entrance and representative interior |
| Verification | Resource load, relevant route/interaction checks, rendered inspection and observed limitations |

A complete task brief may use [`BUILDING_SPEC_TEMPLATE.md`](BUILDING_SPEC_TEMPLATE.md). Add these fields to the compact table above when they materially affect the change:

| Additional field | What to capture |
| --- | --- |
| Signature and silhouette | Recognition cue beyond color/signage; proposed versus existing geometry |
| Scale references | Player, openings, objects, transforms, and final world-space clearances |
| Components | Verified existing resources; reuse decision; any new reusable candidate |
| Visual reference | Approved images or screenshots and the exact aspect being referenced |
| Acceptance | Per-task pass/fail observations, screenshot paths, and unresolved problems |
| Performance | Baseline and after captures, settings, and reason for meaningful change |

Only record factual implementation paths and measured values after inspection. Mark unverified fields `TBD` rather than filling them with plausible-looking guesses.

For new sites, also record footprint fit, connections, map/location/quest bindings and the canonical vocabulary key. Use the existing site and prefab mechanisms; this blueprint introduces no new building manager or construction layer.

## 11. Implementation and acceptance

Identify the live owner before editing. A generator change may not affect baked content, and a prefab change may be masked by a saved override. The reference home is constructed at runtime. `world_refinements.gd` runs before UI and garden batching and has a repeat-pass guard. Follow the [architecture editing rules](ARCHITECTURE_REVIEW_PART1.md#world-and-asset-workflow) for these contracts, coordinate conversion and data changes. Restart Main for runtime refinement previews; never clear guards on an already modified world.

Use existing scenes, shared materials, Main's geometry helpers and landscape ribbons. Duplicate a material when a local change would otherwise recolor other buildings. Reuse existing geometry where possible; avoid coplanar layers and transparent overlays (set a face at least 4–5 mm in front of the surface it sits on; `docs/evidence/coplanar-scan-20261110/scan.gd` lists faces that fight). Garden batching covers only eligible garden decorations, so do not assume that added façade detail will be batched automatically.

A building task is ready when all of the following are recorded:

- Purpose and entrance read at the normal walking camera; the overview silhouette  remains distinct and compatible with neighboring buildings.
- Materials, roof edges, frames and signs follow this guide; visible parts meet  cleanly, have support and show no clipping or flickering in rendered views.
- Existing routes, door motion, learning objects, picking and applicable vehicle,  stair or rooftop behavior still work. Use player-sized checks, not visual guesses.
- Before/after images use matching cameras, resolution and lighting. Include at  least the approach and representative interior, plus an overview for massing work.
- Resource loading and relevant existing checks run with isolated learner data.  Choose checks from the [README](../../README.md#verification) and building-specific  guides after inspecting their write/capture side effects.
- Verification reports distinguish new failures from the known baseline in  [Final verification](FINAL_VERIFICATION.md). Headless checks do not verify appearance.
- Detail-heavy work includes a comparable frame-time/draw-call measurement. Record  the view and settings; simplify detail if the added cost is not justified.

## 12. AI-assisted editing workflow

These steps govern visual building tasks so agents do not spend tokens repeatedly rebuilding the same features or accidentally undoing working gameplay.

1. **Read and inspect:** Read this guide, the architecture guide, the building-specific references, and the live scene/scripts. Identify whether the building is a baked scene, prefab, runtime-generated structure, or saved override. Do not edit based on a reference screenshot alone.
2. **Audit reuse first:** Check [`BUILDING_COMPONENT_CATALOG.md`](BUILDING_COMPONENT_CATALOG.md) and existing geometry/helpers/materials. Prefer an existing component when it fits without unwanted shared side effects. If it does not fit, document a local solution; do not create a global abstraction for a one-off detail.
3. **Prepare an edit plan:** Name exact files, nodes, proposed visual changes, preservation constraints, expected reusable assets, tests, and before screenshots. Keep the plan concise. Explicitly flag any proposal that crosses from visual-only into layout or global-system changes.
4. **Refactor only when necessary:** If a focused refactor is required to implement the authorized change safely, isolate it, explain why, and verify existing behavior before visual edits. Do not combine broad architecture cleanup with a façade polish task.
5. **Implement incrementally:** Prefer small changes that can be rendered and inspected. Do not duplicate whole buildings, create unbounded helper layers, or reset existing runtime guards to force a preview.
6. **Verify separately:** Run appropriate functional checks and then inspect rendered appearance at the same camera/view settings. Headless tests are not evidence of visual quality. A nice screenshot is not evidence that gameplay still works.
7. **Handoff:** Record modified paths, new component resources, before/after screenshots, relevant test results, performance comparison when needed, known limitations, and any updates to the building-specific guide.

**Stop and report** when ownership is uncertain, a necessary change is unauthorized, a regression cannot be isolated, or an authoritative reference conflicts with observed behavior. Do not invent an implementation path or claim a check passed without executing it.

**Token-efficiency rule:** Inspect and summarize the minimum relevant source files first, use the existing guides instead of rediscovering decisions, and modify only affected resources. This is a workflow preference, not a reason to skip required validation.

## 13. Repeatable visual review and acceptance rubric

A building is not complete until the documented review has been performed in the actual game renderer. Take **matching before and after views** for each changed building:

| View ID | Camera framing | Primary question |
| --- | --- | --- |
| V1, town context | Same overview direction and zoom | Is its silhouette and relationship to road/neighboring buildings readable? |
| V2, walking approach | Normal player camera on the primary approach | Can the player identify purpose, entrance, sign, and uninterrupted route? |
| V3, entrance | Close enough to show openings, threshold, and canopy/supports | Are geometry joins clean and all operational clearances intact? |
| V4, representative interior | Same interior camera position and player height | Is the first activity readable and are vocabulary objects accessible? |
| V5, exception view | Rooftop, garage, service entry, rear wall, or learning wing as applicable | Are building-specific functional/visual constraints preserved? |

Capture screenshots at matching resolution, camera position/orientation, daylight, renderer settings, and graphics quality. Record any deviation. Use referenced example images as **design guidance**, not as proof of what current scenes contain. Re-inspect when a reference asset is old.

**Quality gates, record each as Pass / Fail / Not applicable / Not yet tested:**

- **Identity:** Building has a recognizable silhouette or purpose-led feature beyond its sign and accent color.
- **Composition:** Main entrance reads clearly; windows, base, wall body, trim, and roof edge have coherent proportions and alignments.
- **Construction:** No clipping, z-fighting, unsupported posts/lamps, floating fixtures, misplaced frames, or unintentionally blank unfinished elevations in inspected views.
- **Learning:** Objects remain recognizable, selectable, and correctly tied to existing vocabulary keys; decorations do not obscure labels or pickups.
- **Gameplay:** Player can traverse the actual door/path/aisle; all applicable stairs, vehicles, service routes, and rooftop/helipad uses still work.
- **Context:** Paving meets the entrance, landscape leaves clearances, and identity remains distinct among neighboring buildings.
- **Visual stability:** No obvious flicker, problematic transparency, or unnecessary detail at overview distance.

A failed gameplay/preservation gate blocks acceptance even if the visual result looks better. An untested gate must remain explicitly untested, not silently counted as passed.

## 14. Performance and documentation governance

### Establish measured performance budgets

Do not assign speculative draw-call, polygon, or FPS limits to existing buildings. Establish a repeatable baseline on the actual target hardware, runtime build, and graphics settings. For detail-heavy work, capture a representative town overview and one street/interior view before and after the change. Record:

| Measurement | How to use it |
| --- | --- |
| Frame time (milliseconds), ideally a representative range | Compare at identical camera/render conditions; investigate material regression |
| Draw calls and visible object count | Identify excessive unique materials, geometry fragments, and non-batched details |
| Geometry/triangle count where available | Identify over-modeled trim or unseen interior geometry |
| Collision or interaction complexity where applicable | Avoid decorative collision interfering with player or vocabulary picking |
| Transparency and material instances | Investigate sorting, overdraw, and unexpectedly shared edits |

**Suggested review trigger, not a measured project budget:** investigate a repeatable frame-time increase of roughly 10% in the same comparison view. Do not label an unmeasured scene as passing a budget. Prioritize simplifying tiny repeating trim, hidden surfaces, redundant colliders, and unsupported unique materials before sacrificing the building's purpose-led signature feature.

### Documentation ownership and change discipline

- Keep shared visual rules and palette **here**; keep implementation authority in the architecture guide.
- Keep building-specific measurements, images, node ownership, and exceptions in its existing guide or a file based on [`BUILDING_SPEC_TEMPLATE.md`](BUILDING_SPEC_TEMPLATE.md).
- Keep discovered reusable component facts in [`BUILDING_COMPONENT_CATALOG.md`](BUILDING_COMPONENT_CATALOG.md), clearly marked **Verified**, **Candidate**, or **Deprecated**. Proposed components must not be documented as already implemented.
- Record the files and exact features changed, brief test outcomes, screenshot locations, performance notes if relevant, and remaining limitations after every building task.
- Update references when they become stale; link to existing documents instead of duplicating them. Avoid introducing parallel building managers or vocabulary catalogs to satisfy this design brief.

## 15. Existing references

These references show useful design ingredients and implementation history. Older screenshots and pass counts are evidence of their own snapshots, not proof of the current town's state. Always review the live Main scene before changing a building.

| Reference | Use |
| --- | --- |
| [Building exteriors](../archive/BUILDING_EXTERIORS.md) | Sign alignment, exterior picking and façade regression checks |
| [Reference home](REFERENCE_HOME.md) | Current home layout, materials and eight-door contract |
| [Library and grocery interiors](../evidence/library-market-review/README.md) | Activity groupings, materials and maintained circulation |
| [Three-floor hospital](HOSPITAL_THREE_FLOORS.md) | Civic floor organization, wayfinding, stairs and generator ownership |
| [Civic expansion](../archive/CIVIC_EXPANSION.md) | Learning-wing room concepts; world/bake instructions describe an older snapshot |
| [Rooftop history](../evidence/rooftop-review/README.md) | Historical landing/roof checks; old home and static-helicopter descriptions are superseded |
| [Current outdoor polish](../evidence/part2/HANDOFF.md#town-appearance-polish--21-october-2026) | Current outdoor palette, planting and rendered town context |

Visual references: [library interior](../evidence/library-market-review/library_entry.png), [hospital exterior](../evidence/hospital-review/exterior.png), [earlier bakery façade](../evidence/town-checks/building-BakeryCafe-after.png), and [current park context](../evidence/part2/town-polish-park.png). The library provides a material and furnishing reference; the earlier bakery view illustrates the blank-wall improvement opportunity. These are references, not mandatory models to duplicate.

### Reference-image maintenance

Existing visual references are snapshots from particular iterations. Before using them as the basis for a new design, note the image path, what it demonstrates, whether it still reflects the live scene, and whether it is an **approved target** or simply **historical context**. Attach new approvals to the corresponding building-specific specification. Avoid creating large copied image collections inside the blueprint.

### Version history

- **2.0 (21 October 2026):** Retains the original design and functional-preservation rules; adds document hierarchy, distinctiveness and scale controls, scoped AI editing steps, component-catalog integration, pilot review gates, repeatable screenshots, and measured performance governance. No game source assets were changed by this documentation revision.
