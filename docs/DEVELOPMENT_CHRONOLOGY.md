# Development chronology

This detailed chronology retains the later development notes and baseline provenance. For the superseding full-conversation account, early probe artifacts, approximate v0.3.x–v0.5.x stages, and evidence labels, read [Pre-Git Development Narrative](PRE_GIT_NARRATIVE.md). Exact development dates are not asserted. Quotes and testing reports remain attributed to the handoff unless directly visible in an included image.

## 1. Problem discovery and early probing
**Problem/observation:** Sunbreak's anomaly crafting economy requires remembering which investigation levels and monsters provide many similarly named afflicted materials. The user wanted an in-game aid rather than repeatedly leaving the game to consult references.

**Action:** The updated handoff supplies v0.1.0–v0.1.2 probe ZIPs and a v0.1.2 result, now preserved in `archive/probes/`. Early work investigated what could be read from REFramework and whether Smithy requirements could be detected directly. The empty result is limited evidence, as explained in the pre-Git narrative.

**Reasoning:** Automatic Smithy detection would have been the ideal interaction, but the relevant native UI/state was not reliably identified. The project therefore evolved toward a useful manual workflow instead of blocking on uncertain reverse engineering.

**Result:** Automatic requirement detection was deferred. Manual quantity entry plus a persistent passive farming list became the practical core.

**Unresolved:** Exact Smithy screen/requirement hooks remain unknown.

## 2. Material data becomes a first-class system
**Problem:** A wishlist is only useful if material → level → monster mappings are accurate. Incorrect mappings directly waste hunts.

**Action:** Material data was moved into external `SmithyAnomalyData.json`, with revision tracking. The current recovered revision is `TU5_INFOGRAPHIC_002`. Sources can be strings or objects with source-specific level ranges.

**Important correction:** Dire Wing family was corrected so Afflicted Dire Wing / Dire Wing+ / Dire Fellwing use Gold Rathian and Silver Rathalos only; Bazelgeuse must not be added.

**Tradeoff:** External JSON adds a deployment file but makes data maintenance safer and separates factual data from UI/logic code.

## 3. Manual Material Counts editor and persistent wishlist
**Problem:** With automatic Smithy reading deferred, entry needed to be fast enough to use while crafting.

**Action:** A Material Counts editor organized material families into columns. Clicking a material name or `+` increments it; `-` decrements. Counts persist. A separate wishlist view shows only active needs, with per-item `Done` and `Clear Entire Wishlist`.

**Reasoning:** Separate editing from passive viewing: dense controls are useful while configuring; compact farming guidance is useful during normal play.

**Result:** The user could reproduce a Smithy requirement manually and then close REFramework while retaining the farming reminder.

## 4. Passive overlay behavior and shared F8
**Problem:** Multiple HS mods independently listening for F8 could fight over visibility state.

**Action:** Adopted a shared global hotkey generation pattern:
`_G.HSHotkeys = { f8_down, f8_generation }` and shared overlay visibility state. This was informed by the proven `SubCampFinder.lua` behavior.

**Result:** F8 became a consistent global show/hide interaction for participating HS overlays. “Visible now (F8)” exposes state in configuration.

## 5. Save/load-aware visibility
**Problem:** Showing the overlay before a character/save is loaded is noisy.

**Action:** Detect `snow.player.PlayerManager` and `findMasterPlayer`. Optional auto-show hides before save load, shows once the master player exists, and hides when leaving the save. F8 still toggles manually.

**Tradeoff:** This detects player/save availability, not the Smithy itself. It improves lifecycle behavior without pretending Smithy detection exists.

## 6. Two visual directions: Classic and Rise
**Problem:** A generic REFramework overlay worked functionally but did not feel integrated with Monster Hunter Rise.

**Action:** Kept a polished cyan/black **Classic** style while developing a brown/gold **Rise** style inspired by native Village/Outpost Progress, Wishlist, Smithy, and Qurious Crafting UI.

**Reasoning:** Keeping Classic avoided throwing away a successful readable design while allowing native-inspired experimentation.

## 7. Core/style architecture split — v0.6.3
**Problem:** Rendering experimentation was making the main script harder to reason about.

**Action:** Split responsibilities:
- `SmithyAnomaly.lua`: database loading, state, persistence, editors, save/F8 behavior.
- `SmithyAnomalyStyle.lua`: Direct2D fonts, colors, geometry, Rise/Classic rendering, default HUD position.

**Added:** HUD text scaling.

**Bug:** v0.6.3 style code treated `fs` (a table) as a number in `rise_height`, producing `attempt to perform arithmetic on a table value (local 'fs')`.

## 8. Direct2D crash fix — v0.6.4
**Action:** Height calculations were corrected to use `fs.scale`, while font access remained under `fs.fonts.*`.

**Evidence:** User tested v0.6.4 successfully; the previous error stopped occurring and the HUD rendered.

**Packaging lesson:** Earlier `_code.zip` attempts had an extra parent folder/missing database and Vortex rejected them. A corrected complete package established the required root layout and override file.

## 9. Native HUD placement — v0.6.5
**Observation:** The default HUD overlapped Rise's native Village/Outpost Progress panels.

**Action:** Style-only change moved default Y from top fraction `0.105` to `0.1675` (~90 px lower at 1440p).

**Result:** Reset-to-default cleared the native progress panels. User then identified horizontal alignment as the remaining issue.

## 10. Product/UI cleanup and horizontal alignment — v0.6.6
**User feedback:** The wishlist editor had redundant body instructions, a clipped bottom control, two reset-position buttons, and user-facing “Finder” naming that no longer matched the product. The passive HUD also needed to move left to align with native Progress UI.

**Action:** The 0.6.6 chat-delivered core/style update:
- User-facing name → `Anomaly Material Wishlist`.
- `Enable finder` → `Enable wishlist`.
- Editor title carries drag/resize guidance; body instruction lines removed.
- Duplicate position reset removed; remaining reset uses resolution-aware default.
- Default editor height increased/breathing room added.
- Style default shifted left while retaining v0.6.5 Y.
- Both files/version/probe markers synchronized to 0.6.6.

**Evidence:** User screenshot showed `Anomaly Material Wishlist 0.6.6`; user said “Not bad. Looks like it preserves the text size setting too.”

## 11. Typography and environmental contrast — v0.6.7
**Observation:** Rise generally uses lighter font weights, title case, text outlines, and a dark translucent perimeter. In a village screenshot the custom wedge visually disappeared into a similarly brown boat.

**Action:** v0.6.7 was scoped as a Rise-style visual pass:
- Rise header changed from all caps to `Anomaly Material Wishlist`.
- Lighter title/material font weights.
- Subtle dark text outline treatment.
- Dark translucent outer silhouette behind the panel and wedge, preserving the gold/brown inner border.
- Classic renderer and functional behavior intentionally left alone.

**Evidence:** User supplied v0.6.7 screenshots in Smithy and village contexts. User noted the outside-Smithy transparent border was still thinner than native UI but acceptable for later refinement.

## 12. Portfolio milestone selection
**Why v0.6.7:** By this point the project had a coherent workflow, external data architecture, persistence, lifecycle controls, two styles, native-inspired positioning/typography/contrast, and clear screenshots showing the problem/solution relationship. Remaining work is incremental or exploratory rather than required to explain the product.

**Important:** v0.6.7 is a **current working milestone**, not a finished release. Automatic Smithy detection and further border/title refinement remain future work.

## 13. Establishing the Git baseline

The handoff's `current/` folder contained older recovery files, so it was not used as v0.6.7 source. A separate local `AnomalyMaterialWishlist_v0.6.7.zip` was found beside it. Every install file matched the adjacent working project byte for byte. The v0.6.6 core, v0.6.7 style module, database, and Vortex override are preserved unchanged in this repository.

The three selected portfolio screenshots and seven historical images were reviewed visually. Older v0.6.3–v0.6.6 packages are preserved as artifacts in the baseline commit, following a README setup commit, with no invented historical commits or release dates. See [baseline provenance](BASELINE_PROVENANCE.md).
