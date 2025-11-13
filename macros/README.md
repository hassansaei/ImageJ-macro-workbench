## Image Analyzer Macro Overview

The `0_ImageAnalyzer_v1.ijm` macro processes ND2, CZI, and TIFF microscopy files to produce reproducible figure-ready outputs.

### Key Features
- Supports one to four fluorescence channels with automatic channel detection.
- Generates DAPI-only images, DAPI+channel composites, and a final merged image.
- Lets you select which image appears larger in the panel layout.
- Provides user-defined color assignment for each channel, including composite colors.
- Offers per-channel or global intensity controls with optional LUT baking.
- Draws configurable scale bars on every exported image.
- Logs processing metadata to `ImageAnalyzer_Log.txt` for reproducibility.

### Usage
1. Run the macro from Fiji (`Plugins → Macros → Run...`).
2. Choose the folder containing ND2, CZI, or TIFF files.
3. Configure contrast, intensity ranges, colors, panel layout, and scale bar options in the dialog.
4. Review the generated JPEGs (DAPI, DAPI+channels, merge, panel) and the log file stored next to the source data.

### Suggested Citation
If this macro contributes to your work, please include a citation or URL to this repository when publishing your results.
