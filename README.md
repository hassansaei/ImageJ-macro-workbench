## ImageJ-macro-workbench

[![DOI](https://zenodo.org/badge/1094337702.svg)](https://doi.org/10.5281/zenodo.17598284)

This repository hosts the `Image Analyzer` Fiji macro for batch-processing ND2, CZI, and TIFF microscopy datasets. The script automates C1 (nuclear/reference) and multi-channel exports, applies reproducible display settings, and produces figure-ready JPEG panels.  
**Latest release: v1.3.0** (channel-agnostic naming: DAPI references replaced by C1 in dialogs, filenames, and panel presets).

**APA**
```
Saei, H. (2025). ImageJ-macro-workbench (Version 1.3.0) [Computer software]. Zenodo. https://doi.org/10.5281/zenodo.17598284
```

**BibTeX**
```bibtex
@software{saei_imagej_macro_workbench_2025,
  author       = {Saei, Hassan},
  title        = {{ImageJ-macro-workbench}},
  year         = {2025},
  version      = {1.3.0},
  publisher    = {Zenodo},
  doi          = {10.5281/zenodo.17600693},
  url          = {https://doi.org/10.5281/zenodo.17598284}
}
```

### Repository Contents
- `macros/0_ImageAnalyzer_v1.3.ijm` — latest macro with C1-based naming for all exports.
- `macros/0_ImageAnalyzer_v1.2.ijm` — previous release with DAPI-specific naming (kept for reproducibility).
- `macros/README.md` — feature overview, usage, and release highlights.
- `ImageAnalyzer_v1.2.0/` — packaged assets for the v1.2 release.

### Requirements
- Fiji (ImageJ) distribution with the **Bio-Formats** plugin.
- ND2, CZI, or TIFF files from compatible microscopy systems.

### Installation
1. Download or clone this repository (or package `macros/0_ImageAnalyzer_v1.3.ijm` as needed).
2. Copy `macros/0_ImageAnalyzer_v1.3.ijm` into your Fiji macros folder (`Fiji.app/macros/` or another scripts location).
3. Launch Fiji, go to `Plugins → Macros → Run...`, and select the macro.

### Usage Overview
1. Run the macro and choose a folder containing ND2, CZI, or TIFF files.
2. Configure the dialog options (grouped sections for faster navigation):
   - Enhance contrast (global or per-channel saturation).
   - Fixed intensity ranges per channel (C1–C4) with optional LUT baking.
   - Channel colors, including composite colors (Cyan, Magenta, Yellow) mapped to dedicated merge slots.
   - Panel layout (choose which image appears larger and populate three mini-panels, now with all `C1+C2+C3`-style options).
   - Scale-bar length, font size, and thickness.
3. Review the generated outputs saved next to the source data:
   - `__C1.jpg` plus per-channel exports (`__C2.jpg`, `__C3.jpg`, `__C4.jpg`).
   - `__C1_Cn.jpg` overlays for every detected partner channel up to C4.
   - Pairwise (`__C2_C3.jpg`, etc.) and three-channel composites (`__C1_C2_C3.jpg`, etc.)
   - `__MERGE_C1_C2_C3_...jpg` and `__MERGE_NO_C1.jpg`
   - `__PANEL.jpg`
4. Consult `ImageAnalyzer_Log.txt` for a record of settings and processed files.

### What’s New in v1.3.0
- All dialog prompts and panel presets now label the first channel generically as `C1`, so users can swap a different stain into channel 1 without seeing “DAPI” in the UI.
- Exported filenames follow the `__C1*.jpg` convention (`__C1.jpg`, `__C1_C2.jpg`, `__MERGE_NO_C1.jpg`, etc.), matching how channels C2–C4 were already labeled.
- Panel selection helpers (`getImagePathForLabel`) and log messages were updated to align with the new naming, while the v1.2 macro remains untouched for legacy workflows.

### What’s New in v1.2.0
- Color mapping upgraded to ImageJ merge slots `c1`–`c7`, fixing Magenta/Cyan/Yellow accuracy even when merged with DAPI.
- Added automatic export of every available three-channel combination (with or without DAPI) plus matching panel options.
- `Merge Channels...` now uses `create keep`, preventing source stacks from closing mid-run and ensuring all composites render in one pass.
- Settings dialog reorganized with headings and a default 0.35% enhance-contrast saturation value for a gentler starting point.

### Citation

If this macro supports your research or teaching, please cite it:


### Contributing
I welcome pull requests and issue reports. Please include:
- Fiji/ImageJ version and operating system.
- Dataset characteristics (channel count, acquisition settings).
- Steps to reproduce bugs or justify enhancement ideas.

### License
This project is released under the MIT License. See `LICENSE` for details.  
Thank you to the Image Analysis community for maintaining Fiji and Bio-Formats.
