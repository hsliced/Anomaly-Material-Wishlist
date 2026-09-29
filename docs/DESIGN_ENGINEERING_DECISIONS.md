# Design and engineering decisions

These decisions are summarized from the supplied development handoff. They preserve reported reasoning; they are not a complete transcript of the early project. Implementation details were compared with the local v0.6.7 source when preparing the baseline. Retrospective interpretation is labeled separately below.

## External material database
**Discussed reasoning:** Separate factual anomaly mappings from code so corrections do not require rewriting rendering/interaction logic. The database carries a revision (`TU5_INFOGRAPHIC_002`) and supports per-source level overrides.

**Alternative:** Hard-code mappings in Lua. Rejected in practice because mapping corrections were consequential and data needed independent maintenance.

**Maintenance warning:** Do not infer or “clean up” monster mappings without verification. Accuracy is a product requirement, not cosmetic data hygiene.

## Core/style separation
**Discussed reasoning:** v0.6.3 split logic and rendering so visual iteration could proceed without destabilizing wishlist state/persistence.

**Alternative:** One large Lua file. Earlier builds effectively followed this direction; it became less attractive as Direct2D styling grew.

## Persistent wishlist and counts
Counts are stored separately from the material database. The user can enter a requirement once and carry it into normal play. Stable JSON filenames were intentionally preserved even after the public name changed.

## Manual editor vs passive viewer
The project deliberately has two modes:
- editor/configuration while REFramework UI is open;
- compact passive HUD during normal play.
This resolves a density conflict: quantity controls and diagnostics do not belong in the always-on farming reminder.

## Shared F8
A shared `_G.HSHotkeys` generation counter avoids several mods independently edge-detecting F8 and getting out of sync. This pattern came from work on the user's other HS overlays, particularly SubCampFinder.

## Save/load handling
Master-player existence is used as a pragmatic save-loaded signal. This is not Smithy detection. It solves lifecycle visibility without claiming more game-state knowledge than is available.

## Classic and Rise themes
Classic remains an intentional cyan/black alternative. Rise style is inspired by native panels but is not intended as a pixel-perfect clone. Keeping both protects a proven readable style while allowing native-integration experiments.

## Resolution-aware positioning and text scale
Default placement scales against a 1440p reference and clamps resolution scale. User-adjustable HUD text scale persists. Testing showed the saved 1.2x setting survived the 0.6.6 update.

## Native UI references
Visual decisions were driven by screenshots of Village Progress / Outpost Progress, native Wishlist, Smithy/Qurious Crafting panels, and native material-gathered messaging. Iterations addressed: panel placement, wedge shape, brown/gold palette, hierarchy, title casing, font weight, text outline, and environmental contrast.

## Vortex packaging
Vortex is the user's deployment path. The correct ZIP has `vortex_override_instructions.json` and `reframework/` at archive root. An earlier generated `_code.zip` failed because packaging was incomplete/wrongly nested. The corrected override copies both Lua modules and the data JSON, then sets mod type `dinput`.

## Naming/data compatibility
Public naming migrated from “Smithy Anomaly Finder” to “Anomaly Material Wishlist,” but internal Lua filenames and persistent JSON filenames remain stable to avoid needless migration risk.

## Automatic Smithy detection deferred
**Discussed reasoning:** Reliable requirement extraction/native Smithy state was not solved. Rather than block the project, manual entry became the current workflow.

**Proposed future behavior:** Detect requirements, preview them, and let the user explicitly “Apply to Wishlist.” Do not silently overwrite the user's persistent list.

## Retrospective interpretation
The project demonstrates a recurring pattern: prefer a smaller interaction that is reliable and testable over a theoretically ideal automation whose game hooks are not yet understood. This is a retrospective framing of the development trajectory, not a quoted design principle from the original conversation.
