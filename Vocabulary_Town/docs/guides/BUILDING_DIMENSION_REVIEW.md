# Building dimensions and interior capacity review

**25 October 2026 — approved school and supermarket shells implemented at runtime; other dimensional changes unapproved. Sites and entrance axes retained.**

This review follows the latest request to settle dimensions **before exterior improvements**. It supersedes the earlier instruction to defer sizing in the [town brief](TOWN_DESIGN_BRIEF.md). Current building positions remain approved. Programs come from that brief; no interior construction or vocabulary changes are authorized here.

## Approval record

The user approved **only the school and supermarket dimensions**:

- School: **24 × 18 town units, one story**, with the reviewed 4.6 clear-height target.
- Supermarket: **26 × 26 town units**, with the reviewed 5.6–5.8 clear-height target.
- Preserve both existing sites and entrance axes.
- Furniture shortening, airport height reduction and hospital rear-wing removal
  remain **unapproved**. Retain their existing dimensions and structures.

The user subsequently authorized resizing. The implementation below supersedes
the pre-resize measurements and review-stage restrictions later in this document.
Detailed interior allocations remain planning assumptions, not a finished fit-out.

## Implemented resize — 25 October 2026

Run **Main**, not the saved world alone. `world_refinements.gd::resize_school()`
and `resize_supermarket()` run before outlines/facades and compact placement.
They edit the live tree once; the saved snapshots and original prefabs remain
unchanged inputs. Restart Main to preview; never clear guards on a modified tree.

| Building | Implemented geometry in final town coordinates | Preservation / remaining work |
| --- | --- | --- |
| School | External **24 × 18**, x=−12..12, z=221..239; **4.6 clear height**, one floor. Roof overhang .2. Current interior: one 0.2-thick, 4.6-high center divider spanning the rear 9 units (final town z=230..239), with the front half z=221..230 open. The 3.6 front opening is unchanged; the earlier central hall/classroom openings are removed. | Original root/site/entrance axis retained. Upper floors, stair annex and rear wing replaced at runtime. Eight original desk/chair/notebook sets and every distinct old teaching prop retained at original scale. Separate baked supplies/plaques retained too; teachers/students/mascot and adjacent flower bed adjusted only to clear the new school structure. No new permanent vocabulary-location assignments. |
| Supermarket | External **26 × 26**, x=−159..−133, z=113..139; inner floor **25.5 × 25.5**, roof underside 5.81, finished-floor top .10 → **5.71 clear height**. Roof overhang .3. | Front axis x=−133, z=126 retained; expansion rearward/sideways. Existing 301 display/frontage components, props, inventory, checkout/cold fixtures and their transforms remain unchanged. Walls, roof, floor/foundation and edge trim resized individually; obsolete peaked cap removed. The subsequently authorized [nine-department fit-out](TOWN_DESIGN_BRIEF.md#supermarket-interior-review--26-october-2026) now uses the enlarged floor; original display-position preservation below is dated resize evidence. |

Current [school floor plan](../evidence/school-partition-20261026/floor-plan.png) and
[actual furnished cutaway](../evidence/school-partition-20261026/after/floor-plan.png) show the
single rear-half wall. The 25 October space-budget diagram below is historical,
not the current partition layout.

School content is a **provisional preservation arrangement**, not the final general/science
classroom design. Art/music/geography objects remain learnable inside the school;
complete subject-book, anatomy, microscope and other requested fit-out work is deferred.
Repeated obsolete classroom furniture was retired with the extra floors; every original
school-area canonical key remains. An existing pencil prefab was added because the
unchanged School Day mission required it but the previous school had none.
Mission IDs, word lists, ordering, radius rules, save format and translations are unchanged;
markers/destination labels refer to the surviving general/science teaching areas. School location text no
longer advertises three floors. Existing door registry and vehicles are preserved.

No other building resized. Hospital wing/helipad/bed, airport/turboprop, furniture store,
home/library interiors, park landmarks, roads and parking remain unchanged. The school
parking-to-front gap stays 5; market-to-delivery-pad gap stays 3. Retained clear openings
have no new door leaves. Any future doors/ATMs/fixtures must fit the tested corridors.

Verification and limits: [final verification](FINAL_VERIFICATION.md#approved-building-resize--25-october-2026).
Rendered [school](../evidence/resize-20261025/school-front.png), [market](../evidence/resize-20261025/market-front.png),
[player-scale school](../evidence/resize-20261025/school-player.png) and
[player-scale market](../evidence/resize-20261025/market-player.png) views are actual Godot captures.
The two `*-cutaway.png` diagnostics intentionally hide roofs; roofs remain in gameplay.

School exterior follow-up: its [new elementary-school facade](TOWN_DESIGN_BRIEF.md#school-exterior-review--25-october-2026)
retains this exact shell and 4.6 clear height. The subsequent
[26 October single-divider layout](TOWN_DESIGN_BRIEF.md#school-single-divider-layout--26-october-2026)
supersedes its older classroom partition plan. New non-solid
finishes/canopy/planting are separate from the unchanged dimensional construction.

Exterior follow-up: the supermarket now has an updated storefront at these same
approved dimensions. See the [current exterior review](TOWN_DESIGN_BRIEF.md#supermarket-exterior-review--25-october-2026).
Source component geometry/locations remain intact; new non-solid facade skin and
local material/visibility changes are separate from dimensional construction.

## Pre-resize capacity review (historical)

The remaining measurements, diagrams and verification paragraphs describe the review
before construction. Use the implementation section above for current school/market
geometry; keep the other buildings' capacity findings and unapproved options as context.

## Reviewed recommendation

The approved principal targets are a **24 × 18 single-story school** and **26 × 26 supermarket** retaining their existing entrance axes and sites. Retain other footprints initially. Optional refinements are a furniture-store depth reduction **29 → 24**, an airport terminal wall/ceiling height reduction **7 → 5.2**, and retirement of the hospital's redundant rear learning wing after its contents are accommodated in the main three floors. These optional changes were not approved and must not be implemented.

The electronics store, café, sports store and restaurants can accommodate compact versions of the agreed programs without mandatory enlargement. The hospital's main block already has the required approximate room count. Its challenge is assigning equipment and circulation, not adding floors.

## Measurement method and player scale

Measured the fully constructed Main tree in an isolated Godot 4.7.2 copy. Compared 424 source/scene/data/asset/shader files with the working project: identical. Source inspection included current wall/floor/roof geometry, hospital/school room partitions and generator, runtime home construction, player collision/camera, and existing route checks. Evidence: [measurement JSON](../evidence/dimension-audit-20261025/building-measurements.json), [read-only runtime measurement script](../evidence/dimension-audit-20261025/measure_buildings.gd), and [log](../evidence/dimension-audit-20261025/measurement.log).

All table dimensions are **town units**, before Apartment's ×1.3 scale. Multiply lengths by **1.3** and areas by **1.69** for final world units. These are game units, not a building-code certification or a claim that one unit is a real-world meter. Width means frontage, depth runs from entrance toward the rear, independent of compass orientation. Existing nominal dimensions use authored floor plates/wall centerlines, excluding canopies, decorative gables, roof overhangs and landscaping; usable dimensions use inner faces or finished floor coverage. Round to 0.1–0.2 units when implementing against real geometry. A site subtree's bounding box is **not** usable floor area.

| Reference | Measured / proposed value | Consequence |
| --- | --- | --- |
| Player collision | Radius 0.76, height 2.2 **world**, global scale 1 | Diameter 1.52 world = **1.17 town**; do not multiply the player by 1.3 again. |
| Visible character | Runtime visual bounds ≈1.90 wide × 2.24 high world | Arms/model may extend beyond the collision capsule. Test visual as well as physical fit. |
| Camera | Pivot 2.55 world; default arm 6.5 world, adjustable 3–14 | A passable gap does not guarantee a comfortable orbit. Avoid tight tall display canyons. |
| Secondary walking aisle, proposed | **2.2 town / 2.86 world** | About 1.9 collision diameters; keep this genuinely clear of chairs, open doors and tank bases. |
| Main retail aisle, proposed | **2.8 town / 3.64 world** | About 2.4 collision diameters; 3.2 at entrances/turns/queues is preferable. |
| Main entry/spine, proposed | **3.2 town / 4.16 world** | Comfortable visual and movement allowance; larger existing openings stay larger. |
| Hospital bed, complete main-floor prefab instance | **1.70 × 2.93** footprint, 1.52 high town; **2.21 × 3.81**, 1.97 high world | Preserve this design/scale. A bed plus 2.2 clear on all sides uses roughly **6.1 × 7.3 town**, before a separate cabinet. |
| MRI scanner in current wing | **2.70 × 3.15**, 2.85 high town | With 2.0 around it, about **6.7 × 7.2**; fits a main hospital room, but door delivery/turning is a separate test. |
| School desk/chair examples | Desk ≈1.36 × 0.76; chair ≈0.68 × 0.64 town | Use a combined occupied desk/chair zone and aisles, not desk dimensions alone. |
| Appliance examples | Washer ≈1.05 × 0.95; refrigerator ≈1.05 × 1.06, 2.30 high town | Six large appliances can fit a roughly 8-unit display run with small gaps. Door swings need additional aisle allowance. |

Furniture dimension samples are orientation-dependent runtime bounds. In particular, the complete bed root was measured separately: a mesh tagged `hospital bed` alone captures only part of the bed and underestimates its envelope. Old `check_public_interiors.gd` uses a much narrower 0.364-world-radius capsule and old positions; its historical pass cannot establish current player fit.

## Building-by-building capacity

Clear area below means approximately empty internal floor plate **before furniture and internal partitions**, not currently unobstructed walking area. Existing room arrangements and known completion status remain constraints. Height is approximately floor-to-roof/ceiling, with low lights/trim needing individual checks.

| Building | Existing nominal W × D; height and layout | Approximate internal capacity | Assessment and proposed dimensions |
| --- | --- | --- | --- |
| House | Main body **27 × 20**, walls **3.2**; attached **10 × 9** garage partly overlaps body, **6 × 4** guest-bath extension; pool/terrace separate. Three bedrooms, two baths, connected living/dining/kitchen. | Irregular furnished floor plan, not the full 28.4 × 38.1 descendant bound. Existing complete rooms and eight doors. | **Keep all dimensions.** Broad but already serves the completed program. No justification to resize a working home; preserve roof lift, garage and pool. |
| Library | **12 × 15**, shell **5.8**, finished ceiling about **5.14** above floor. One reading/borrowing/computer/story space. | Inner faces ≈**11.77 × 14.77 = 174**; finished floor 11.74 × 14.72. | **Keep.** Existing reading tables, shelves, computer desks and cross-aisle use the space appropriately. Height is generous, not a capacity problem. |
| School | Main **18 × 24.4**, **3 floors** at 5.6 spacing; roof underside ≈16.68; attached stair envelope ≈7.2 × 14.2; rear wing about **20 × 24**. Four rooms per main floor plus wing rooms. | Main rooms roughly **7.04 × 10.04** each. Current core alone has ≈1,318 floor-plate area across three floors, plus wing/stairs. Excessive for two classrooms. | **Change to 24 × 18, one floor, clear height 4.6** (world 31.2 × 23.4 × 5.98). Two ≈**10 × 14.2** classrooms, 3.2 central spine, 3.2 entry band. Widen front by about 3 per side; shorten main depth by 6.4; retire upper floors, stair annex and rear wing only during later approved implementation. |
| Hospital | Main **18 × 24.4**, 3 floors at **5.6** spacing; existing side stair envelope ≈7.2 × 14.2; rear clinical wing ≈**18 × 24**. Main total body height ≈16.9. | Four main rooms/floor, each ≈**7.04 × 10.04 ≈70.6**; corridor ≈3.45 between partitions, ≈3.34 at bumper rails. Clear under lights ≈5.2. | **Keep main block, floor heights and stairs.** The requested 12-room arrangement fits compact learning representations. Optional **remove rear 24-unit wing** after moving its displays into assigned main-floor rooms; no exterior expansion needed. Helicopter/helipad and bed remain protected. Elevator not yet proven to fit without changes; reserve/test separately. |
| Bank | **12 × 15**, shell **5.8**; reception/waiting, teller zone, manager office and vault. | Inner shell ≈**11.77 × 14.77 =174**; rear rooms already consume a portion. | **Keep initially.** Three teller stations, two small consultation spaces and retained vault require repartitioning, not necessarily growth. Use wall screens and a shared waiting area. Exterior ATMs belong in a measured frontage strip, not extra interior area. More than two enclosed offices would require a new budget. |
| Café / bakery | **14 × 22**, clear ≈**4.58**; current long perimeter learning displays. | Inner ≈**13.82 × 21.82 =302**. | **Keep.** Space for 4–6 small tables, coffee/preparation run, pastry/bread displays and clear central route. Generous depth permits service and existing baking vocabulary; shrinking now risks needless rework. |
| Fine dining (Pizza shell) | **13 × 16**, clear ≈**4.92**; empty single room. *(Stale from 28 Oct 2026: merged with the Burger shell into a 30 × 16 room; 1 Nov 2026: plus a 16.25 × 8 rear kitchen wing and a front terrace, see the [Alta Cocina record](TOWN_DESIGN_BRIEF.md#alta-cocina-italian-remodel-and-plush-staff--1-november-2026).)* | Inner ≈**12.75 × 15.75 =201**. | **Keep.** Budget 4–6 four-person tables, host/menu point and modest service station. No full commercial kitchen requested. Around 4 × 4 per occupied table group includes chairs/local access; retain continuous 2.2–2.8 route. |
| Burger | Same **13 × 16**, clear **4.92**, empty. *(Stale from 28 Oct 2026: replaced by the L-shaped Pizza and Burger, dining wing 30 × 10 + kitchen wing 14 × 8, in the former police lot.)* | ≈**201**. | **Keep.** Four tables plus order/pickup queue, 5–6-wide counter and simple rear preparation strip fit. A drive-through or commercial kitchen is outside program and would change the answer. |
| Chinese seafood (Cafe shell) — *superseded 28 October 2026: now the taquería, six tables, see the design brief* | Same **13 × 16**, clear **4.92**, empty. | ≈**201**. | **Keep for four dining tables.** Two entrance-side tank banks around **4 × 1.2** each plus a **3.2** central entry leave room for seating and rear service. A 4–5-deep entry/tank viewing zone is needed. Larger tanks or 6–8 large tables would justify depth **16 → 19** later; not recommended by default. |
| Supermarket | Wall-center footprint **19.6 × 18**, shell **5.8**; open grocery with current aisles/cold displays/checkouts. Width already differs from older generator's grocery dimensions. | Inner ≈**19.28 × 17.72 =342**. Current displays are not nine complete departments. | **Recommend 26 × 26 external target, clear height 5.6–5.8**; world footprint **33.8 × 33.8**. With .25 walls, ≈**25.5 × 25.5 =650** internal area (about 90% more). Supports nine compact open zones with 2.8 circulation. This is a learning supermarket, not full Walmart-scale inventory. |
| Clothing | Nominal **11.2 × 15.2**, shell **5.2**; one boutique with fitting/checkout details. | Finished floor **11 × 15 =165**, slightly reduced by fixtures. | **Keep.** Four wall display groups, central **2 × 3** accessories case, mannequins and checkout fit with ≥2.2 walking routes. Use occupied display envelopes, not densely packed racks. |
| Furniture | **17 × 29**, clear **4.58**, open room with stock around edges. | Inner ≈**16.82 × 28.82 =485**. | Fits comfortably; **optional shorten to 17 × 24**, same front and height. New inner area ≈401. Four **6.5 × 8** furnished bays, a 3.2 central route and front/rear circulation fit. Not necessary; retaining 29 gives more generous displays. |
| Sports | **14 × 24**, clear **4.58**, open long store. | Inner ≈**13.82 × 23.82 =329**. | **Keep.** Five roughly **4.8 × 5.2** equipment zones plus ≈3.2 spine/cross access fit. Outdoor zone accommodates one compact tent and bicycle; skis upright or wall mounted. No court, skating area or snowmobile. |
| Electronics / appliances | Nominal **11.5 × 15.4**, shell **5.25**, clear under roof ≈5.22; open showroom. | Finished floor **11.3 × 15.2 ≈172**. | **Keep with compact displays.** Two 1.2-deep perimeter runs, a 2.0-wide central island and two 2.4 aisles require **9.2** width, leaving ≈2.1 for tolerance/fixtures. A 3.2 entry band + 8-long island + 3.2 rear access uses 14.4 depth. Large appliances on one 8-unit run; small items on shelves. Optional **14 × 18** only if every appliance needs an independent walk-around station. |
| Chapel | **10 × 12**, walls **4**, roof underside ≈4.18; one sanctuary with pews/altar. Tower is decoration above this. | Inner ≈**9.8 × 11.8 =116**. | **Keep.** Two pew banks around 2.4 wide, 2.4 center aisle and side access fit; 3–4 rows plus 2.5–3-deep altar zone. Do not increase tower/body scale to create more sanctuary area. |
| Airport terminal | **34 × 18**, clear **6.92**, empty single floor; tower is separate. | Inner ≈**33.75 × 17.75 =599**. | **Keep footprint. Optional lower roof/clear-height target to 5.2** (6.76 world), preserving canopy/headroom. The current volume is unnecessarily tall for a compact terminal. Five zones + separated departure/arrival circulation fit at this width. Leave runway, tower, aircraft/taxi access unchanged. |
| Barn | **12 × 9**, clear **4.92**, empty. Farm animals already outside. | Inner ≈**11.75 × 8.75 =103**. | **Keep.** Two 1.0–1.5-deep side storage bands, rear hay/feed and 3.2 center route fit tools, wheelbarrow and small mower. Existing 3.4 opening can accommodate paired doors if leaf swing stays outside walking/storage zones. Add pitched roof later without growing footprint. **1 November 2026 (user): footprint kept; walls raised to a 6.0 eave under a gambrel roof (ridge 10.5), floor top 0.16, hayloft deck at 3.0 over the rear 3.8; opening 3.4 × 4.0** ([record](TOWN_DESIGN_BRIEF.md#farm-barn-gambrel-roof-hayloft-and-supplies-interior--1-november-2026)). |
| Police station | **12 × 15**, shell **5.8**; offices/reception plus interview/cell. | Inner ≈**174**, with rear rooms about 3.6 × 6 and 3.7 × 5.2. | **Keep unchanged pending removal decision.** No approved new interior program warrants resizing. Preserve car and lessons. *Relocated 28 Oct 2026 (size unchanged) to the east side south of the supermarket; see the [brief](TOWN_DESIGN_BRIEF.md#restaurants-and-police-relocation--28-october-2026).* **Superseded 6 Nov 2026 (user decision): enlarged to 20 × 22, shell 5.8, front fixed, for the lineup and evidence rooms of the detective games; see the [record](TOWN_DESIGN_BRIEF.md#police-station-enlargement-and-detective-games--6-november-2026).** |

Gazebo and control tower have no newly agreed enclosed-room program. Retain their current dimensions; they are surrounding constraints rather than candidates for interior enlargement.

## How the proposed programs fit

[Historical scaled planning diagrams](../evidence/dimension-audit-20261025/space-budgets.png) show the original school and supermarket budgets. The school partition diagram is superseded by the [current single-divider floor plan](../evidence/school-partition-20261026/floor-plan.png). These are **schematic allocations**, not rendered game changes, furnishing plans or proof of playability. No walls/furniture were added to the project. Blocks include local circulation, while yellow lanes reserve the primary routes.

- **School:** assume eight student places in the general classroom, two laboratory benches in science, teacher station, shelving and wall displays. An occupied desk row with chair access needs more space than the desk mesh; two columns/four rows with a central route fit the approximately 10 × 14.2 room. Skeleton/anatomy/periodic table and books are perimeter displays. If you want 20–30 student places, this target must be reconsidered. One floor removes unnecessary vertical travel and substantially reduces the old program's area.
- **Hospital:** a bed + 2.2 clear on each side is about 6.1 × 7.3; it fits a 7.04 × 10.04 room with a limited equipment/cabinet zone. MRI + 2.0 circulation is about 6.7 × 7.2. Use one main bed/examination/operating fixture per teaching room, rather than multi-bed wards. First floor: reception, waiting, emergency, exam. Second: two patient rooms, ICU, operating room. Third: imaging, lab, physical therapy, doctors' office. This is one plausible allocation of the user's approximate program, not a new mandatory room count. An optional elevator needs roughly 3.2 × 3.2 shaft/cab plus landing allowance; do not silently consume a room, narrow stairs or obstruct the helipad. Existing former-wing land could support an annex, but no annex is approved here.
- **Supermarket:** nine open zones in three bands, divided by 2.8 aisles, each about 6.63 wide. Front band 5 deep: two compact checkouts, produce/entry, beverages/household. Middle 8 deep: dry goods, refrigerated, frozen. Rear 6.9 deep: seafood, meat, bakery. Display zones include counter/service space and local circulation. Keep a 3.2 clear entrance through the central front zone. Seafood/meat use representative counters, not a full behind-counter production facility. No warehouse/backstock room is assumed.
- **Furniture:** four furnished 6.5 × 8 bays total 208 area, plus 3.2 spine and end crossways within the optional 17 × 24. Existing bed ~2.72 × 1.90, sofa ~2.56 × 1.05, desk ~1.6 × .9 are smaller than these activity zones. Do not fill the spare bay area with extra duplicate vocabulary.
- **Bank:** budget about 45 area for teller/staff, 30 waiting/reception, 2 × 14 offices, 16 vault and 45 circulation/partitions, totaling about 164. This is feasible but tight at existing dimensions and may need simpler partitions. Several outside ATMs require approximately 5–6 of frontage and 2.2 clear standing/approach depth outside machine bodies. The existing floor node extends beyond part of the shell; that decorative/offset mesh must not be counted as enclosed room capacity.
- **Airport:** approximate zones: check-in 8 × 5, security 6 × 5, waiting 12 × 7, gate 5 × 4, baggage 8 × 5. These total 214; generous circulation/queue separation brings the budget to roughly 350–450 within 599. This is enough without expansion. A baggage belt represents a compact loop, not a full airport conveyor system.

## Site space and expansion directions

Positions and entrance axes stay fixed. “Rear expansion” means editing the shell relative to its existing front, **not translating the building/site root**. Listed extents are rounded town-space planning rectangles; exact wall/threshold offsets must be reconciled during approved implementation. +X is west, +Z north. No road, parking, attraction or neighbor relocation is included.

| Site / option | Measured surroundings and proposed constraint |
| --- | --- |
| **School 24 × 18** | Keep front near z=221, entrance x=0. Proposed body approximately x=−12..12, z=221..239. School parking is x=−13..13, z=202..216, leaving **5** front approach depth. North loop sidewalk ends near z=208. Hospital's nearest measured bound starts x=46.8, giving at least **34.8** horizontal separation; airport group ends x=−67, giving **55** to the proposed east edge. Existing wing/upper floors/stair annex are the structures to retire, not neighbors to move. |
| **Supermarket 26 × 26** | Retain front near x=−133 and centerline z=126. Proposed rectangle x=−159..−133, z=113..139: increase width north/south and depth **eastward toward the rear**, away from the road. Delivery parking is x=−130..−120, z=102.5..127.5: **3** from proposed front. Road sidewalk outer edge is x=−120: **13** away. Clothing's nearest measured bound starts z=158.1, leaving about **19.1** to the enlarged north side. Do not expand forward into the delivery apron. |
| Supermarket ground / coast | Nine ray samples across proposed front/rear edges hit current terrain or existing roof; the three rear samples x=−159 at z=113/126/139 all hit terrain. This supports feasibility at sampled points, not a continuous foundation/landscape test. Coastal path and ground contours still require an exact polygon check before construction; no coastal path relocation is authorized. |
| Furniture shortened depth | Keep front near z=227.5, width x≈117.5..134.5; optional new rear z=251.5 instead of 256.5. Parking ends z=222: **5.5** front buffer retained. Sports roof ends x=103.15: approximately **14.2** gap to furniture roof. Removing rear depth releases space without using neighboring land. |
| Electronics optional expansion (not required) | If later needed, frontage 14 and depth 18 can stay near x=125.3 front, z=137 center: x≈125.3..143.3, z≈130..144. Parking ends x=122: **3.3** before threshold. Bakery bound starts z=158.85: **14.85** to enlarged north side. Bank bound ends z≈117.35: **12.65** south gap. Rear corner/midpoint samples hit terrain. |
| Three restaurants | Centers are 16 apart; each roof is 13.6 wide, leaving only **2.4** between roofs (≈2.75 between physical side walls). **Do not widen sideways.** Fronts near z=42; shared parking starts z=45: about **3** apron. Any future depth increase should go south/rear, never into parking. Current 13 × 16 is sufficient for the assumed seating counts. |
| Hospital | Main/stair roof envelope ≈x=46.8..72.1; core front ≈z=221, rear ≈245.6; rear wing reached ≈269.45 until it was removed on 27 October 2026; the main block was then extended to a rear ≈253.1 ([hospital guide](HOSPITAL_THREE_FLOORS.md)). Hospital parking ends z=214, leaving about **7** at the main front. Sports roof starts x=88.85, leaving about **16.75** to stair roof. Retiring rear wing releases land northward; main helipad height and stair connectivity stay unchanged. |
| Airport | Terminal roof x=−113.3..−78.7, z=235.7..254.3. Airport parking ends z=225: about **10.7** to terminal roof front. Runway bounding box ends x≈−120.33, a conservative **7.0** horizontal gap to terminal roof; angled runway must be checked geometrically, not from box gap alone. Taxiway and tower further constrain lateral growth. Height-only option avoids these footprints. |
| Bank, bakery, clothing | No expansion required. Bank shell front about x=126.5, parking rear x=123: **3.5** nominal approach; bakery front x=126, parking ends x=123: **3**; clothing front x≈−129.4, parking rear x=−127: **2.4**. ATMs, seating and signage must not consume these entire approach gaps. |
| House / library / police | No enlargement proposed; preserve their southern frontage, parking, garage route and coastal approaches. Library roof front z≈40.8 to parking z=45 gives only **4.2** for entry details. Police roof front z≈37.8 to parking z=46 gives **8.2**, but removal remains undecided *(the station now stands on the east side; this figure describes the old south-row lot)*. |
| Chapel / barn / gazebo | Inside protected park context with trails, trees, fenced habitats and gates. Keep footprints; expansion is unnecessary for the specified interiors and would compete with outdoor attractions. Barn double doors need a swing plan within current habitat/approach. |

These are static planning gaps, not vehicle turning-radius certification. Parking slabs and decorative paths can have different extents from collision or usable circulation. Keep existing driveway widths, vehicle safe exits, crossing approaches and door swings; don't interpret unused grass as automatically available construction space.

## Approval choices and remaining verification

Recommended package:

1. **Approved dimensions: school 24 × 18, one floor, 4.6 clear height**; eight student places and two lab benches were planning assumptions; preserve site/entrance. This implies later removal of obsolete upper floors/stair/wing after lessons and missions are retained in the new arrangement.
2. **Approved dimensions: supermarket 26 × 26, 5.6–5.8 clear height**, expanding rearward and sideways within the proposed site rectangle, retaining front axis and delivery/parking access.
3. **Keep other footprints**. Separately choose whether to shorten furniture **17 × 29 → 17 × 24**, lower airport terminal height **7 → 5.2**, and retire the hospital rear wing once contents fit its main floors. None is needed to begin confirming the principal two targets.

The school/supermarket approval settles **dimensional design intent**, not a final furnished collision layout. Before shell implementation, use actual furniture at existing scales in a disposable mock-up, test the real player capsule and camera through doors/aisles/turns, check the exact terrain/path polygons and vehicle envelopes, and capture walking-height views. Do not scale whole buildings or beds to make a plan fit. Interior/vocabulary work remains a separately scoped stage; shell changes must coordinate those dependencies rather than deleting content first.

Current verification: resource loading **309 resources / 0 failures** and compact-layout **706 checks / 0 failures** rerun in the isolated copy; measurements cover 18 buildings and 16 support rays. Existing rendered views from the exterior audit describe the unchanged current state; planning diagram is not a new render. No proposed geometry exists, so no claim of proposed-layout playability, door operation, furniture picking, camera quality or performance verification. Existing facade-test coordinate and cached-metadata/legacy-vehicle issues remain as recorded in [Final verification](FINAL_VERIFICATION.md). No full-suite pass claimed.

## Café and bank exterior follow-up — 25 October 2026

The [café/bank exterior pass](TOWN_DESIGN_BRIEF.md#café-and-bank-exterior-review--25-october-2026) retains the measured 14 × 22 café and 12 × 15 bank shells, roof geometry, site frames and interior geometry. No additional dimensional approval was inferred.
