# Building component catalog and reuse rules

**Purpose:** A discovery-led catalog for reusable architecture in Spanish Vocabulary Town. This file records **verified implementation facts** once an agent has inspected the project. It does **not** require building a new framework and it does **not** claim the candidate categories below already exist.

**Related documents:** [Building Design Blueprint](BUILDING_DESIGN_BLUEPRINT.md) | [Building Specification Template](BUILDING_SPEC_TEMPLATE.md) | [Architecture Guide](ARCHITECTURE_REVIEW_PART1.md)

## 1. Source of truth and entry states

- **Verified:** A specific resource, prefab, function, material or helper was found, and its usage/ownership were inspected. Exact implementation paths are documented.
- **Candidate:** A potentially reusable feature has been identified but no reusable implementation is confirmed yet.
- **Deprecated:** A previously verified entry is no longer a preferred choice; document what supersedes it and any migration constraints.
- **Not audited:** The category has not been inspected. Never substitute a guess for a verified file or scene path.

Do not mark a candidate `Verified` just because a coding agent generated example code or a screenshot of a similar design.

## 2. Candidate audit checklist

The following categories are prompts for inspection, not an asset inventory:

| Candidate family | Variations worth checking | Important constraints | Initial state |
| --- | --- | --- | --- |
| Door and entrance surrounds | Single/double, recess, sill, canopy | Collision, swing, pickable sign zones | Not audited |
| Window modules | Reading/display/private, mullions, sills | Correct room placement, transparency | Not audited |
| Shopfront fascia and signs | Name panel, smaller hours/direction signs | Legibility, localization, interaction ownership | Lettering: [world sign component](COMPONENTS.md#world-signs) (16 Nov 2026; supermarket migrated, other buildings not yet). Panels not audited |
| Roof-edge details | Eaves, fascia, parapet, coping | Camera visibility, landing/helipad behavior | Not audited |
| Plinths and wall bands | Stone bands, trim, pilasters | Clean corners and door/ramp cuts | Not audited |
| Awnings and canopies | Fabric, rigid, supported posts | Physical support and approach clearance | Striped shop awning: `shop_row.gd` `add_awnings()` (clothing-store pattern, 18 Nov 2026; sports store) |
| Exterior fixtures | Lamps, planters, benches, bins | Player collision, decorative batching | Not audited |
| Shop interior display groups | Shelf/counter/display backing | Word-root ownership and separate picking | Not audited |
| Shared material resources | Plaster, wood, stone, glass, metals | Shared instance mutation, batching, renderer compatibility | Colours: [game palette](TOWN_DESIGN_BRIEF.md#game-palette-and-shop-row--18-november-2026) `scripts/core/game_palette.gd` (18 Nov 2026; shop row uses it, other buildings not yet). Materials shared by the bake palette ([MODULAR_TOWN](MODULAR_TOWN.md#material-palette)) |
| Landscape/approach connections | Paving paths, planting boundaries | Road and pedestrian continuity, global ownership | Not audited |

For each relevant family, inspect the project's actual scenes, helpers, runtime builders, and rendering behavior before proposing a new prefab or code helper.

## 3. Verified component entry template

Copy this section **only when an actual reusable component is found or approved**. Keep entries short and link to existing authoritative implementations.

### [Component ID and descriptive name]

| Field | Record |
| --- | --- |
| State | Candidate / Verified / Deprecated |
| Role and visual behavior | TBD |
| Actual resource/file/function path | TBD; required before marking Verified |
| Scene or runtime owner | TBD |
| Coordinate space and transform behavior | TBD |
| Configuration inputs | Dimensions, materials, orientation, optional trim, etc., only if implemented |
| Shared-versus-local material ownership | TBD |
| Collision / interaction / vocabulary impact | TBD |
| Tested examples / building users | TBD |
| Limitations and render compatibility | TBD |
| Expected performance tradeoffs | TBD |
| Verification or regression check | TBD |

**Example invocation or usage:** Link to an existing verified use or an inspected code reference. Do not add invented APIs.

### Verified supermarket facade usage — 25 October 2026

`building_exteriors.gd::finish_market()` reuses the verified `part()`/`lettering()`
helpers and Main's `box()`/`material_for()` for non-solid retail surfaces. The local
`building_part()`/`building_lettering()` wrappers (originally named `market_part()`/
`market_lettering()`) convert existing building coordinates into the facade frame.
The approved school follow-up reuses these same functions as a second actual
consumer; this remains local facade code, not a new framework. `prepare()` provides the existing exterior-vocabulary Area picking.
Locally assigned material overrides do not mutate shared material resources.
The existing carts and planters are reused in place. No new downloaded assets,
textures, shaders or vocabulary prefabs were introduced. Tested in Compatibility
with matching rendered views and `docs/check_supermarket_exterior.gd` (retired 7 Nov 2026, see [building access](FINAL_VERIFICATION.md#snapshot-checks-retired--7-november-2026)); see the
[current review](TOWN_DESIGN_BRIEF.md#supermarket-exterior-review--25-october-2026).

### Verified school facade usage — 25 October 2026

`building_exteriors.gd::finish_school()` reuses the above building-frame helpers,
Main's cached box/material resources and existing sphere/cylinder primitives.
Window grouping, porch, compact clock and brick/plaster skins are school-specific;
there is no new scene hierarchy or external asset dependency. `prepare()` skips
only explicitly tagged new apron/planting decoration; existing school picking and
all interior/door roots remain untouched. See [rendered school review](TOWN_DESIGN_BRIEF.md#school-exterior-review--25-october-2026)
and `docs/check_school_exterior.gd` (retired 7 Nov 2026, see [building access](FINAL_VERIFICATION.md#snapshot-checks-retired--7-november-2026)) for verified users and preservation checks.

## 4. Reuse-versus-local decision

Use a shared component when it already exists, serves more than one genuine use case, is compatible with the building's scale and renderer, and does not introduce unintended changes elsewhere. Prefer a local detail when the feature is unique, dependencies are complex, or extraction would cost more than it saves.

Before extracting a new abstraction, identify at least two plausible consumers **in the live game** and a consistent interface. Do not reorganize scene ownership or replace proven geometry merely to reach a theoretical reuse percentage.

| Decision | Suitable situation |
| --- | --- |
| Reuse verified component unchanged | Matches design and functional requirements |
| Parameterize a verified component | Small, stable variations are actually needed by multiple buildings |
| Duplicate/instance a material locally | Shared resource would recolor unintended buildings |
| Create a local geometry detail | Only one building requires it, or extraction increases complexity |
| Propose a reusable candidate | Evidence of repeated need exists, but implementation needs a separately scoped task |

## 5. Safety boundaries

- Protect established door states, collision, word roots, bilingual interaction, building orientation, and vehicle or rooftop behavior.
- Verify local versus global transforms, including any building-specific scale conversion. Never assume similar models share local coordinate values.
- Preserve existing runtime modification ordering and guards. A new visual component must not trigger duplicate passes or bypass the scene's established ownership.
- Avoid unnecessary transparent overlays, coincident surfaces, excessive draw calls, and unique materials on every tiny detail.
- Shared resources must be tested on at least one other actual consumer when modified.

## 6. Audit and update log

| Date | Category or component | Status change | Evidence / verified path | Reviewer |
| --- | --- | --- | --- | --- |
| TBD | TBD | Not audited to Candidate/Verified/Deprecated | TBD | TBD |

Link each building specification to the specific verified components it uses. Avoid duplicating full instructions in every building-specific document.

### Verified café and bank facade usage — 25 October 2026

`finish_cafe()` and `finish_bank()` reuse `building_part()`, `building_lettering()`,
existing material caching and facade picking. The café cup emblem is decorative
primitive geometry, not a new vocabulary prop. New café planters use the existing
`skip_exterior_pick` convention. No new reusable asset package or framework was added.
See [current review](TOWN_DESIGN_BRIEF.md#café-and-bank-exterior-review--25-october-2026).
