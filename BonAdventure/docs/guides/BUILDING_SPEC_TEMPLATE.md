# Building specification template

**Purpose:** Fill out a compact, traceable brief for one Spanish Vocabulary Town building improvement. This is a template, not evidence that any building has been inspected or modified. If an established building guide already contains these facts, edit it rather than maintaining a duplicate.

**Related documents:** [Building Design Blueprint](BUILDING_DESIGN_BLUEPRINT.md) | [Building Component Catalog](BUILDING_COMPONENT_CATALOG.md) | [Architecture Guide](ARCHITECTURE_REVIEW_PART1.md)

## 1. Identification

| Field | Entry |
| --- | --- |
| Building / location in town | TBD |
| Task / expected player benefit | TBD |
| Status and date | Proposed / TBD |
| Scope class | Visual-only / geometry-within-footprint / explicitly authorized layout or systems |
| Existing scene, prefab, generator, or override | TBD, inspect live owner |
| Relevant node paths / scripts | TBD, verified paths only |
| Existing reference docs | TBD |

## 2. Existing baseline and preservation

Record actual conditions, not assumptions. Mark any uninspected item `Not yet verified`.

- **Footprint and orientation:** TBD
- **Main entrance and approach:** TBD
- **Rooms / interior root / stair links:** TBD
- **Working door, garage, vehicle, roof, helipad, or service constraints:** TBD or Not applicable
- **Characters, props, signs, and learning-object roots/keys that must be preserved:** TBD
- **Existing materials and shared ownership:** TBD
- **Known baseline defects versus newly introduced defects:** TBD

## 3. Building identity recipe

| Design decision | Entry |
| --- | --- |
| Function and player learning activity | TBD |
| Silhouette without the sign or accent color | TBD |
| Primary architectural volume and secondary volumes | TBD |
| One characteristic feature | TBD |
| Main entrance emphasis | TBD |
| Window rhythm and room compatibility | TBD |
| Roof edge or parapet treatment | TBD |
| Shared palette roles and building accent | TBD, reference global palette, do not copy color table |
| First visible interior activity | TBD |
| Neighboring-building contrast | TBD |

**One-sentence identity test:** "With the name sign hidden, the player recognizes this as a [type] because [visible feature / massing]."

## 4. Reference images and scale

| Reference | File path / value | What it proves or guides |
| --- | --- | --- |
| Approved style reference | TBD | Aesthetic goal only, unless freshly verified |
| V1 town overview, before | TBD | Massing and context |
| V2 player approach, before | TBD | Entrances and sign |
| V3 threshold, before | TBD | Openings / supports |
| V4 interior, before | TBD | Activity and circulation |
| V5 special access, before, if applicable | TBD | Rooftop, garage, vehicles, or wing |
| Player height and collision width in final world space | TBD | Scale anchor |
| Door opening and real passage clearance | TBD | Access constraint |
| Main aisle / approach clearances | TBD | Circulation |
| Relevant counter, window sill, sign and pickup heights | TBD | Object relationships |
| Applicable scale transforms | TBD | Prevent double-scaling |

Capture after images from the same views and settings. Link to them in the results section rather than adding duplicative large galleries.

## 5. Exact proposed edits

| Item / file or node | Existing state | Change | Reuse decision | Affected systems and expected test |
| --- | --- | --- | --- | --- |
| TBD | TBD | TBD | Verified component / local-only / new candidate | TBD |

**Explicitly excluded changes:** footprint, scene ownership, room arrangement, door connectivity, vocabulary schema, global lighting, and related systems remain unchanged unless separately authorized here.

**Dependencies or refactor justification:** None / TBD. Do not use visual polish as an excuse for a broad refactor.

## 6. Acceptance and observed results

Use `Pass`, `Fail`, `Not applicable`, or `Not yet tested`. No item counts as passed without an executed check or live visual inspection.

| Check | Status | Evidence / observations |
| --- | --- | --- |
| Recognizable identity at normal player camera | Not yet tested | TBD |
| Distinct silhouette in town context | Not yet tested | TBD |
| Entrances, window alignment, supports, roof edges | Not yet tested | TBD |
| No new clipping, z-fighting, transparent sorting defects | Not yet tested | TBD |
| Player approaches, door operation, relevant routes | Not yet tested | TBD |
| Vocabulary labels, roots, individual selection | Not yet tested | TBD |
| Applicable vehicle, rooftop, or stairs access | Not yet tested | TBD |
| Resource load and relevant code/game tests | Not yet tested | TBD |
| Matching screenshots V1 to V4 (and V5 if needed) | Not yet tested | TBD |
| Comparable performance when detail-heavy | Not yet tested | Baseline/after frame time, draw calls, hardware, settings |

## 7. Handoff

- **Changed file paths and resource owners:** TBD
- **New or reused components and catalog updates:** TBD
- **Screenshot / rendered-review paths:** TBD
- **Test commands and results:** TBD
- **Performance comparison and explanation:** TBD or Not applicable
- **Known limitations and differences from desired reference:** TBD
- **Newly observed issues requiring a separate task:** TBD
- **Reviewer / approval / date:** TBD

## 8. Task-specific notes

Use this area only for facts unique to the building. Keep general palette rules, AI workflow, and shared component descriptions in their authoritative documents.
