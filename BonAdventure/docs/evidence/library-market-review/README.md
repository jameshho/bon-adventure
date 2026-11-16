# Library and grocery interior upgrade

**Design supersession — 25 October 2026:** The compact grocery design below is superseded by the 25 October large open supermarket program; its existing implementation remains until later work. The completed library remains protected. See the [current town brief](../../guides/TOWN_DESIGN_BRIEF.md).

> Historical implementation record. Use the [documentation map](../../README.md)
> for current guides; positions, counts and test results below describe this snapshot.

The runtime interiors now have one owner: `scripts/world/library_market_interiors.gd`, invoked by TownBuilder. Superseded market/library additions in TownBuilder and FurniturePolish no longer run. Other buildings and the house retain their existing builders.

Library: oak flooring with flush joints, green runner, six stocked bookcases, two reading tables with lamps and correctly oriented upholstered chairs, two computer desks, a borrowing/returns desk, framed signs, a children's story corner, plants and supported pendant lights. The center walkway and rear cross-aisle remain clear.

Grocery: tile floor, two stocked double-sided aisles, supported aisle and department signs, two checkout counters, three produce bins, bakery trays with bread, four refrigerated display cabinets, warm pendant lights and perimeter trim. Removed old floating signs, duplicated crates, endcap stands obstructing the center aisle, and conflicting lamps.

Validation: full main-scene rendering from both entrances and interior viewpoints; eight player-sized capsule routes (41 samples per route) clear; all six town pig placements remain free from mesh overlap and selectable; interior learning-word checks and project resource checks pass. The reusable route check is `docs/evidence/town-checks/check_public_interiors.gd`.

Backups: `backups/library_market_before/` contains the original TownBuilder and FurniturePolish scripts. The saved character scenes were not changed.
