# Baseline provenance and validation

## Updated portfolio handoff

The v2 handoff assembled from the full original conversation supersedes the earlier incomplete portfolio narrative. Its early probe artifacts are now preserved in `archive/probes/`; the [pre-Git narrative](PRE_GIT_NARRATIVE.md) and [evidence register](EVIDENCE_AND_TESTING.md) explain their scope. The v2 warning about missing source concerns that recovery package: the exact local v0.6.7 package was already recovered and verified below. The four install files remain unchanged.

## Source selection

The supplied `AnomalyMaterialWishlist_v0.6.7_Handoff.zip` is a recovery archive. Its `current/` directory explicitly contains older recoverable components, not the final v0.6.7 implementation. That directory was not published as current source.

A separate `AnomalyMaterialWishlist_v0.6.7.zip` was present beside the handoff in the user's local project folder. Its four install files matched the neighboring working files byte for byte. Those exact files form this baseline; no implementation was reconstructed, reformatted, or relabeled.

| Install file | SHA-256 |
| --- | --- |
| `reframework/autorun/SmithyAnomaly.lua` | `C2CFD0D79964789D5674B43A9BFA5D4BD1057BB68EDC197A05C72AB5CC686931` |
| `reframework/autorun/SmithyAnomalyStyle.lua` | `E9AE9A53BDDAE402780765570DB464E33ECFD63D4702288D93F3178F0B0CD356` |
| `reframework/data/SmithyAnomalyData.json` | `A195A4D7BAA6D3F64953823A1D8A061600E2232FB70F9A00EF82679029DB1E8D` |
| `vortex_override_instructions.json` | `BDEC5912E646AB209611199D3C37C64656AD620714399E64EE068A3D0BC1A51F` |

The core declares 0.6.6; the style module declares 0.6.7. This matches the handoff's description of a style-only final pass. The UI/probe version markers remain 0.6.6. `.gitattributes` disables line-ending conversion for the install files to preserve their bytes in Git.

## Data and persistence

The database revision is `TU5_INFOGRAPHIC_002`. Each family contains tiers with a display name, short label, level label, and sources. Sources can be strings or objects with a name and source-specific level label. The core validates the principal family/tier fields before use.

The preserved Dire Wing family names Gold Rathian and Silver Rathalos as sources, including Dire Fellwing at Lv 201+. This documents the packaged mapping, not an independent fresh verification of game drop tables.

Wishlist persistence uses `smithy_anomaly_wishlist.json`, with schema version 1 and a `wishlist` map keyed by material name, plus mod/UI/database metadata. Settings use `smithy_anomaly_settings.json`, schema version 26. Diagnostics use `smithy_anomaly_probe_v0.6.6.json`. These runtime files are excluded from Git and are not seeded from the developer's personal state.

## Evidence and its limits

| Evidence | What it establishes |
| --- | --- |
| ZIP-to-working-file and repository hash comparison | Exact preservation of the four supplied local install files. |
| JSON parsing and structural checks | Readable JSON, expected family/tier fields, unique material names, and Vortex copy entries pointing to real files. |
| Lua source inspection | Controls, persistence names, optional save-load visibility, manual quantities, separate themes, and an explicit statement that automatic Smithy detection is not implemented. |
| Ten original screenshots, visually reviewed | The corrected ×2 workflow, passive HUD, placement iterations, boat contrast issue, and current village result. |
| Handoff testing reports | Historical in-game observations, including layout, retained text scale, and successful rendering after the reported Direct2D fix. |

No new in-game execution, Lua-runtime test, performance benchmark, or broad compatibility test was performed during baseline preparation. Documentation link checks and package checks do not substitute for runtime testing.

## Development feedback preserved by the handoff

The following quotations are carried over from the handoff's account of the conversation; they are not new testing performed for this commit:

- “Not bad. Looks like it preserves the text size setting too.” — after the 0.6.6 iteration.
- “In the third screenshot, you can see how the triangle disappears into the boat” — motivation for environmental contrast work.
- “Outside the smithy, the transparent border area isn't as thick as it is in game, but it can refined in future updates” — remaining visual refinement.
- “Oh I should've put two wings” — correction of the selected workflow example's manually entered quantity.

## Historical coverage

The handoff supplies the portfolio narrative and v0.6.3/v0.6.4 archives. The local project archive supplies v0.6.5/v0.6.6 packages. These are retained as original snapshots, all added together in the baseline commit after the README setup commit. Dates, historical Git commits, tags, and release claims are not reconstructed.

Earlier motivations and design decisions are handoff-reported context; the repository does not claim a complete pre-v0.6.3 record. The original handoffs remain outside the repository, including their superseded source-recovery instructions. Ten original portfolio images remain unchanged. The three selected images are also copied into the Pages assets directory for independent site hosting.

## Remaining provenance gaps

The definitive external database source URL, author credit, and redistribution terms were not recovered. The database revision string alone is not an attribution. No project license was selected, and none is invented here. Future documentation can add verified credits and an owner-selected license.
