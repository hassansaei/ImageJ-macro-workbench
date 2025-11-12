## ND2/TIFF Image Analyzer (4-Channel) — Version Comparison Report

I developed the `0_NikonAx_ImageAnalyzer_4Channels` macro series to streamline fluorescent image exports from Nikon ND2/TIFF datasets with speciall focus on reproducibility of the exported results. Below, I describe each release and how the toolset evolved between v1 and v4.


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

### V5 introduces **user-defined color assignment** for all channels, adds **CZI file format support**, and includes significant improvements to color handling and merge logic.

### 1. User-Defined Channel Color Assignment
- **New dialog options** for selecting colors for each channel (C1/DAPI, C2, C3, C4)
- **Available color options**: Red, Green, Blue, Gray, Cyan, Magenta, Yellow, or None
- Colors are applied consistently across:
  - Individual DAPI+channel composites
  - Final multi-channel merge
- **Default colors** (maintained for backward compatibility):
  - C1 (DAPI): Blue
  - C2: Green
  - C3: Red
  - C4: Gray

### 2. CZI File Format Support
- Added support for **Zeiss CZI files** in addition to ND2 and TIFF
- Updated file detection logic to recognize `.czi` extension
- Updated dialog prompt to mention CZI support

### 3. Enhanced Color Handling
- **Bio-Formats import mode changed** from `color_mode=Composite` to `color_mode=Colorized` to preserve original LUT colors from file metadata
- **Automatic LUT removal**: All split channels are converted to grayscale to allow custom color assignment
- **Composite color support**: Handles Cyan (Green+Blue), Magenta (Red+Blue), and Yellow (Red+Green) by duplicating channels as needed

## Technical Changes

### New Helper Functions
1. **`getChannelColor(channelIndex, c2Color, c3Color, c4Color)`**
   - Returns the user-selected color for a specific channel index

2. **`getColorChannelMapping(colorName)`**
   - Maps color names to ImageJ merge channel specifications (c1=red, c2=green, c3=blue, c4=gray)

3. **`getTwoChannelMergeSpecSimple(channelIndex, dapiTitle, channelTitle, dapiColor, channelColor)`**
   - Replaces the old `getTwoChannelMergeSpec()` function
   - Builds merge specifications based on user-defined colors
   - Handles composite colors (Cyan, Magenta, Yellow) by creating channel duplicates

### Removed Functions
- **`getTwoChannelMergeSpec()`** - Replaced by `getTwoChannelMergeSpecSimple()`
- **`addChannelToMergeArgs()`** - Replaced by new color-based merge logic

### Modified Merge Logic
- **Final merge** now uses a sophisticated color assignment system:
  - Tracks which images are assigned to each RGB channel (Red, Green, Blue, Gray)
  - Combines multiple channels assigned to the same color using Image Calculator
  - Handles conflicts when multiple channels use the same color
  - Supports composite colors (Cyan, Magenta, Yellow) through channel duplication

### Bug Fixes
- **Fixed variable name conflict**: Changed inner loop variable from `i` to `j` in Image Calculator combination loops (lines 367, 391, 415, 439) to prevent breaking the outer file iteration loop

### Log File Changes
- **Log filename changed** from `ND2_ImageAnalyzer_Log.txt` to `ImageAnalyzer_Log.txt` (more generic, reflects multi-format support)
- **Log now includes** channel color assignments in the settings section

## Code Statistics
- **Total lines**: ~758 (v5) vs ~396 (v4)
- **New functions**: 3
- **Removed functions**: 2
- **Modified core logic**: Merge operations completely rewritten

## Backward Compatibility
- **Default colors match v4 behavior**: Blue DAPI, Green C2, Red C3, Gray C4
- **All v4 features preserved**: Enhance contrast, fixed ranges, per-channel ranges, scale bars, panel generation
- **File processing workflow unchanged**: Same output file naming and structure

## Migration Notes
- Users can continue using v5 with default colors for v4-like behavior
- Custom color assignments provide flexibility for different imaging conventions
- CZI support expands compatibility with Zeiss microscopy systems
- The new color system requires more processing time for composite colors (Cyan, Magenta, Yellow) due to channel duplication

## Usage Example
To use custom colors in v5:
1. Run the macro
2. In the Settings dialog, scroll to "Channel Color Assignment"
3. Select desired colors for each channel (C1/DAPI, C2, C3, C4)
4. Process files as usual

The selected colors will be consistently applied to all output images.

I use this report as my authoritative reference for communicating release notes and choosing the appropriate macro version for a given dataset.

