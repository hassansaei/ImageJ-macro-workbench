## ND2/CZI/TIFF Image Analyzer (4-Channel) — Version Comparison Report

I developed the `0_NikonAx_ImageAnalyzer_4Channels` macro series to streamline fluorescent image exports from ND2, CZI, and TIFF datasets with speciall focus on reproducibility of the exported results. Below, I describe each release and how the toolset evolved between v1 and v5.


### v1 — Initial Batch Pipeline
- **Goal**: Deliver a one-click batch processor that outputs standardized JPEG panels for DAPI and up to three additional channels.
- **What I built**
  - Batch folder selection and automated Bio-Formats import in composite mode.
  - Optional global `Enhance Contrast` (single saturation value) applied on-the-fly unless a fixed range is specified.
  - Configurable scale-bar length, font size, and thickness, drawn onto all exports.
  - Automatic creation of:
    - DAPI-only JPEG (`__DAPI.jpg`).
    - DAPI + individual channel composites (`__DAPI_plus_C2.jpg`–`C4`).
    - Final merged RGB image (`__MERGE_DAPI_...jpg`) preserving all included channels.
    - Left-stack panel of up to three DAPI+channel composites with the merged image on the right, using ImageJ’s line-width borders.
  - Per-file cleanup of temporary windows and batch-mode toggling for speed.
- **Constraints I noted**
  - Only a single fixed intensity range for all channels via `setMinAndMax`.
  - Panel border thickness depended on ImageJ’s line width, so results could vary with image scaling.
  - No persistent logging of processed files or settings.

---

### v2 — Per-Channel Intensity Control & Border Improvements
- **Goal**: Give myself precise control over contrast when fluorophores have different dynamic ranges.
- **What changed from v1**
  - Added optional per-channel fixed intensity ranges for C2–C4 while keeping the global fixed-range option. The dialog now captures `useFixedPer` alongside individual min/max pairs.
  - Ensured `Enhance Contrast` is skipped whenever any fixed range is active to avoid conflicting adjustments.
  - Switched panel border rendering to a configurable `borderWidth` (default 200) for visibly thicker lines.
- **What stayed the same**
  - Core batch logic, exports, and cleanup routines remain intact.
- **Remaining issues**
  - The thicker border still relied on `setLineWidth`, which could behave inconsistently between Fiji builds.

---

### v3 — Deterministic Border Rendering
- **Goal**: Remove dependence on `setLineWidth` and guarantee consistent panel borders regardless of Fiji’s line-drawing implementation.
- **What changed from v2**
  - Introduced a `drawThickBorder()` helper that draws filled rectangles for each side of the frame, giving predictable border thickness.
  - Replaced every panel border call with this helper (tile borders, merged image border, outer frame).
- **What stayed the same**
  - Dialog structure, per-channel range options, export pipeline, and lack of logging mirror v2.
- **Remaining limitations**
  - Final merge still relied on default merge arguments, so spectral colour assignments weren’t explicitly enforced.
  - I still lacked run metadata or reproducibility tracking.

---

### v4 — Colour-Safe Merges, Three-Channel Support & Logging
- **Goal**: Make the macro robust for three-channel acquisitions, enforce biological colour conventions, and capture processing metadata.
- **What changed from v3**
  - Renamed the macro entry to `(... ALL FILES (v4))` and documented the version in the header.
  - Added helper utilities for logging and merge specification:
    - `boolToString`, `getTimestamp`, and `pad2` provide clean log entries.
    - `getTwoChannelMergeSpec` maps DAPI to blue (`c3`), C2 to green (`c2`), C3 to red (`c1`), and reserves C4 for far-red/gray.
    - `addChannelToMergeArgs` assembles final merge arguments while preserving spectral mapping.
  - Seeded the final merge with `c3=[__TMP_DAPI]` and explicitly placed other channels so colour assignments remain consistent even when fewer than four channels are present.
  - Replaced the `while` loop for DAPI+channel composites with a `for` loop that adapts merge specs per channel index.
  - Began writing a run log (`ND2_ImageAnalyzer_Log.txt`) that captures:
    - Timestamp, input folder, contrast/scale settings.
    - Per-file status, output paths, and skip reasons (e.g., missing DAPI).
    - Total processed file count.
  - Confirmed the macro handles three-channel datasets without requiring a placeholder fourth channel.
  - Retained the deterministic `drawThickBorder` routine from v3.
- **What I still watch**
  - DAPI is hard-coded to blue and C2/C3 to green/red; I adjust the helpers if acquisition order changes.
  - Each run overwrites the log file; I archive it manually if I need historical records.

---

### v5 — User-Defined Colors, CZI Support, Enhanced Controls & Code Refactoring
- **Goal**: Provide flexible color assignment for any imaging convention, expand file format support, add C1 intensity control, enable customizable panel layouts, and improve code maintainability.
- **What changed from v4**
  - Added user-defined color assignment for all channels (C1/DAPI, C2, C3, C4) with options: Red, Green, Blue, Gray, Cyan, Magenta, Yellow, or None. Colors are applied consistently across DAPI+channel composites and the final merge.
  - Added support for Zeiss CZI files in addition to ND2 and TIFF formats.
  - Changed Bio-Formats import mode from `color_mode=Composite` to `color_mode=Colorized` to preserve original LUT colors, then automatically converts all channels to grayscale to allow custom color assignment.
  - Added per-channel intensity control for C1 (DAPI), extending the existing C2–C4 controls. The dialog now includes C1 min/max intensity fields when per-channel ranges are enabled.
  - Added panel layout customization: users can select which image appears larger (Merged, DAPI+C2, DAPI+C3, or DAPI+C4). DAPI alone is excluded from panels.
  - Introduced centralized cleanup routines:
    - `safeClose(windowName)` replaces repetitive `isOpen/selectWindow/close` patterns
    - `cleanupTempWindows(windowNames)` handles batch cleanup of temporary images
    - `trim(str)` utility for string processing
  - Replaced `getTwoChannelMergeSpec()` and `addChannelToMergeArgs()` with `getTwoChannelMergeSpecSimple()` that builds merge specifications based on user-defined colors.
  - Rewrote final merge logic to track RGB channel assignments, combine multiple channels using Image Calculator when conflicts occur, and support composite colors (Cyan, Magenta, Yellow) through channel duplication.
  - Changed log filename from `ND2_ImageAnalyzer_Log.txt` to `ImageAnalyzer_Log.txt` to reflect multi-format support. Log now includes channel color assignments and panel layout choice.
  - Fixed variable name conflict in Image Calculator loops (changed inner loop variable from `i` to `j`).
- **What stayed the same**
  - Core batch processing workflow, export file naming structure, and deterministic border rendering from v3.
  - Default color assignments (Blue DAPI, Green C2, Red C3, Gray C4) maintain backward compatibility with v4 behavior.
  - All v4 features preserved: enhance contrast, fixed ranges, scale bars, logging structure.
- **What I still watch**
  - Composite colors (Cyan, Magenta, Yellow) require channel duplication, which increases processing time.
  - Each run overwrites the log file; I archive it manually if I need historical records.
  - Panel creation requires at least one DAPI+channel composite to exist; if the selected larger image doesn't exist, no panel is created.

I use this report as my authoritative reference for communicating release notes and choosing the appropriate macro version for a given dataset.

