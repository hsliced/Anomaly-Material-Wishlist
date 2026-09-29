# Changelog

## Portfolio history and GitHub Pages update

- Replaced the incomplete case-study narrative with the full-conversation v2 handoff, with explicit evidence and uncertainty labels.
- Preserved the surviving v0.1.0–v0.1.2 probe ZIPs and result JSON; qualified what the zero-snapshot result can establish.
- Added a responsive GitHub Pages portfolio and a full reading view of the canonical case study.
- Kept the verified v0.6.7 install files unchanged. This is a documentation/site update, not a new mod release or reconstructed pre-Git commit.

## v0.6.7 — current working milestone / initial Git baseline

This initial Git baseline brings together the existing working mod and its documented development story. Publication uses a README setup commit followed by the complete baseline commit. It does not create retrospective release commits or declare the project finished.

### Baseline features

- External anomaly-material database, revision `TU5_INFOGRAPHIC_002`.
- Persistent manually entered quantities, Material Counts editor, and per-item completion controls.
- Separate interactive editor and passive farming HUD.
- Rise and Classic themes, persistent text scale and layout, shared F8 visibility, and optional save-load-aware display.
- Vortex override instructions for both Lua modules and the database.

### v0.6.7 visual pass

- Title-case Rise heading: **Anomaly Material Wishlist**.
- Lighter Rise title/material typography and dark text outlines.
- Dark translucent outer silhouette around the panel and left wedge, retaining the brown/gold inner border.
- Retained v0.6.6 core behavior and version markers; the style module reports v0.6.7.

### Repository documentation

- Installation, usage, persistence, troubleshooting, and known limitations.
- Portfolio case study with the corrected Smithy ×2 workflow, passive Smithy HUD, village HUD, and historical comparisons.
- Source provenance, validation limits, and original v0.6.3–v0.6.6 packages in a separate archive.

### Remaining work

Automatic Smithy detection, closer native border thickness/falloff, and a stronger Progress-style title outline remain future work. No broad compatibility or performance claim is made.

## Pre-Git development notes

These summaries come from the supplied handoff and preserved artifacts. They are not historical Git releases, and no development dates have been invented.

### v0.6.6

- Renamed the user-facing product from Smithy Anomaly Finder to Anomaly Material Wishlist.
- Consolidated editor instructions into the title and removed the duplicate position reset.
- Added editor breathing room and shifted default HUD placement left toward the native Progress alignment.
- Preserved saved text scaling, as reported during in-game testing.

### v0.6.5

- Lowered the default HUD position to clear the native Progress panels (`DEFAULT_TOP_FRACTION` 0.105 → 0.1675, according to the handoff).

### v0.6.4

- Corrected the Direct2D height-calculation error involving the font context table; the handoff reports use of `fs.scale` and successful subsequent testing.
- Established a complete Vortex package following incomplete/nested packaging attempts.

### v0.6.3

- Separated core behavior from the style module.
- Added the HUD text-scaling architecture.

Earlier motivations and design decisions are retained as narrative context in the case study, not as a complete version-by-version record.
