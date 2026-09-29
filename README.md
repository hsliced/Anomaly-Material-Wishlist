# Anomaly Material Wishlist

A Monster Hunter Rise: Sunbreak PC mod that turns a manually entered crafting requirement into a persistent farming reminder: **what material, how many, which investigation level, and which monsters**.

**v0.6.7 is a working milestone, still evolving.** Automatic Smithy requirement detection remains future work.

[Explore the portfolio](https://hsliced.github.io/Anomaly-Material-Wishlist/) · [Read the full case study](portfolio/case-study.md) · [Installation and controls](docs/INSTALL_AND_RUNTIME.md)

![Smithy requirement and passive wishlist both show Afflicted Dire Fellwing ×2, with level and monster guidance.](portfolio/screenshots/02_smithy_passive_hud.png)

## Use it

Enter quantities in Material Counts while REFramework is open. Close REFramework for the passive HUD. The wishlist preserves your requirements between sessions; use **Done** to clear completed items and **F8** to toggle visibility. Counts are manual, not synchronized with inventory.

- Persistent wishlist, configurable positions/sizes, and HUD text scale.
- Rise-inspired brown/gold and Classic cyan/black styles.
- Optional auto-show after a save loads and shared F8 behavior with participating HS overlays.
- External anomaly-material database, separate from Lua behavior and presentation.

## Install

Requires **Monster Hunter Rise: Sunbreak (PC)** and **REFramework**. Use **REFramework-D2D** for the styled passive HUD. The documented development environment used REFramework `v1.5.6+8-654bac56` and REFramework-D2D 1.4.1; broader compatibility has not been established.

Copy the root `reframework/` directory into the game folder, preserving its structure. For Vortex, package `reframework/` and `vortex_override_instructions.json` at the ZIP root. GitHub's full repository ZIP includes a parent folder and portfolio/history files, so repackage the install files for Vortex.

See [installation, controls, persistence, and troubleshooting](docs/INSTALL_AND_RUNTIME.md). Keep your generated `smithy_anomaly_wishlist.json` and `smithy_anomaly_settings.json` when updating; personal runtime files are not included here.

The verified package contains the **v0.6.6 core** and **v0.6.7 style module**. Their original bytes and version markers remain unchanged. The updated portfolio handoff did not replace them with its older recovery source.

## Design and development

The [portfolio site](https://hsliced.github.io/Anomaly-Material-Wishlist/) follows the shift from a Smithy-detection hypothesis to a useful manual workflow, then through data architecture, editor/passive-view separation, and native-UI visual iteration.

- [Canonical case study](portfolio/case-study.md)
- [Pre-Git narrative and evidence labels](docs/PRE_GIT_NARRATIVE.md)
- [Evidence, testing, and uncertainty](docs/EVIDENCE_AND_TESTING.md)
- [Original screenshots and captions](portfolio/screenshot-index.md)
- [Source provenance](docs/BASELINE_PROVENANCE.md), [historical artifacts](archive/README.md), and [changelog](CHANGELOG.md)
- [Site editing and publishing](site/README.md)

The full-conversation v2 handoff supersedes the earlier incomplete narrative. Original v0.1.0–v0.1.2 probes are preserved as artifacts, not fabricated historical commits. Intermediate early stages are labeled as conversation-synthesized.

## Remaining work and credits

Automatic requirement detection, exact Smithy-screen detection, a preview/apply flow, further border/title refinement, and broader compatibility/performance testing remain future work. The database revision is `TU5_INFOGRAPHIC_002`; definitive external attribution and redistribution terms remain unresolved. No project license has been invented.

Human-directed, AI-assisted: the repository owner set direction, made scope/design decisions, tested builds in game, corrected data, and supplied screenshots and feedback. AI assisted with implementation, exploration, debugging, packaging, and documentation; it did not independently test the mod in game.

Unofficial fan project. Monster Hunter Rise: Sunbreak and its game imagery belong to Capcom.
