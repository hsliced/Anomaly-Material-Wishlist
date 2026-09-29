# Pre-Git Development Narrative

This document adapts the updated handoff assembled from the original development conversation. It supersedes the earlier incomplete narrative while preserving the existing Git history. Approximate periods are conversation-synthesized; surviving artifacts are identified separately. It is not a fabricated commit log.

## v0.1.0–v0.1.2 — Smithy anomaly probes
**Artifact-confirmed:** surviving probe ZIPs confirm a read-only REFramework investigation whose goal was to discover runtime objects and fields that change around Smithy upgrades and material requirements. v0.1.2 expanded search terms to include anomaly, Qurious, slot, unlock, require, cost, and contents. The surviving result records `snapshot_count: 0`. The v0.1.2 README explains that this file is also written on startup and after clearing snapshots; an empty result alone does not prove detection failed.

**Conversation-synthesized:** the handoff reports promising Scene / EquipDetailWindow / GUI / View objects, without a dependable requirement snapshot. The product pivot is supported by that account, not inferred solely from the empty JSON.

**Narrative meaning:** automatic Smithy detection was the original hypothesis, not a feature that was later removed. The inability to make it reliable prompted the product pivot.

## Early pivot — useful without automatic detection
The project separated the unresolved technical dependency from the player need. Manual entry could preserve a known requirement and still provide the actionable farming context: quantity, level range, and monster sources.

## ~v0.3.x — editor/passive-view interaction model
The project adopted interaction patterns proven in SubCampFinder: an ImGui editor while REFramework is open, a passive overlay during normal play, persisted positioning, and F8 visibility control. Later work moved toward shared global hotkey/overlay state so related mods would not independently fight over F8.

## ~v0.4.x — editor structure
As material coverage grew, the editor required deliberate information architecture. Iterations added position persistence, explicit columns, aligned quantity controls, clearer headers, and reduced visual clutter.

## ~v0.5.x — persistent wishlist workflow
**Conversation-synthesized:** wishlist requirements became persistent state. The workflow gained per-item Done, Clear Entire Wishlist, a separate Material Counts editor, movable/resizable windows, and persisted size/position. The current source uses a shared requirement map for the editor and wishlist; this is not separate automatic inventory tracking.

## v0.6.x — data, lifecycle, and native-UI direction
The anomaly mapping became an external JSON database. Actual use exposed the cost of incorrect source mappings, leading to stricter data validation. Save-load awareness prevented the passive UI from appearing before the player's character state existed. Classic and Rise became intentional visual alternatives.

## v0.6.3 — core/style split
Core behavior and Direct2D presentation were separated into `SmithyAnomaly.lua` and `SmithyAnomalyStyle.lua`. Text scaling was introduced. The refactor produced a runtime error because `fs` had become a table while some arithmetic still treated it as numeric.

## v0.6.4 — regression fix and packaging lesson
The renderer was corrected to use `fs.scale` for arithmetic and font members separately. A separate packaging mistake also clarified that Vortex needs `vortex_override_instructions.json` and `reframework/` at the ZIP root with the database included.

## v0.6.5 — vertical placement
The default top fraction moved from 0.105 to 0.1675, roughly a 90 px downward change at 1440p, to clear native Progress UI more naturally.

## v0.6.6 — cleanup and alignment
Visible terminology standardized around Anomaly Material Wishlist. Configuration was simplified, redundant instruction text was removed, the passive HUD shifted left toward native Progress alignment, and text-scale persistence was confirmed in testing.

## v0.6.7 — typography and environmental contrast
Testing outside the Smithy showed the translucent Rise wedge could disappear against dark brown scenery. The visual pass introduced title-case typography, lighter Rise fonts, subtle text outlining, and a dark outer silhouette around the panel and wedge. Classic was intentionally preserved.

## Evidence rules
Use the following labels when expanding this history:
- **Artifact-confirmed:** surviving source, ZIP, JSON, or screenshot directly supports it.
- **Test-report confirmed:** contemporaneous user report supports it.
- **Screenshot-visible:** visible in an original screenshot.
- **Conversation-synthesized:** supported by the development conversation but not a surviving standalone artifact.
- **Proposed:** discussed future work, not implemented.

Do not convert this chronology into historical Git commits or releases.
