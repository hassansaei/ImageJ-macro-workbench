## Image Analyzer Macro Overview

The latest macro script, `0_ImageAnalyzer_v1.2.ijm`, batch-processes ND2, CZI, and TIFF microscopy files to produce reproducible, figure-ready exports.

### Key Features
- Supports one to four fluorescence channels with automatic channel detection.
- Generates DAPI-only images, DAPI + each channel, all pairwise composites, all three-channel combinations, and a final merged image (with or without DAPI).
- Lets you select which image appears larger in the panel layout, now including every three-channel combo (e.g., `C1+C2+C3`).
- Provides user-defined color assignment for each channel, including composite colors (Cyan, Magenta, Yellow) mapped to ImageJ’s extended merge slots to preserve color fidelity in exports.
- Offers per-channel or global intensity controls with optional LUT baking.
- Draws configurable scale bars on every exported image.
- Logs processing metadata to `ImageAnalyzer_Log.txt` for reproducibility.

### Usage
1. Run the macro from Fiji (`Plugins → Macros → Run...`).
2. Choose the folder containing ND2, CZI, or TIFF files.
3. Configure contrast, intensity ranges, colors, panel layout, and scale bar options in the dialog (grouped sections in v1.2 make navigation easier).
4. Review the generated JPEGs (DAPI, DAPI+channels, pairwise and three-channel composites, merge, panel) plus the log file stored next to the source data.

### What’s New in v1.2
- Dialog reorganized with grouped headings and updated default enhance-contrast saturation (0.35) for quicker setup.
- Color routing rewritten so Magenta/Cyan/Yellow land on dedicated merge slots (c5–c7), preventing color shifts when exporting with DAPI.
- Added automatic generation of all available three-channel composites (including any combination that includes DAPI).
- Panel layout choices expanded to reference the new composites.
- `Merge Channels...` calls now keep source stacks open, ensuring every requested combination renders in one pass.

### Suggested Citation
If this macro contributes to your work, please include a citation or URL to this repository when publishing your results.
