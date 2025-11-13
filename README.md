## ImageJ-macro-workbench

[![DOI](https://zenodo.org/badge/1094337702.svg)](https://doi.org/10.5281/zenodo.17598284)

This repository hosts the `Image Analyzer` Fiji macro for batch-processing ND2, CZI, and TIFF microscopy datasets. The script automates DAPI and multi-channel exports, applies reproducible display settings, and produces figure-ready JPEG panels.

**APA**
```
Saei, H. (2025). ImageJ-macro-workbench (Version 1.0.0) [Computer software]. Zenodo. https://doi.org/10.5281/zenodo.17598284
```

**BibTeX**
```bibtex
@software{saei_imagej_macro_workbench_2025,
  author       = {Saei, Hassan},
  title        = {{ImageJ-macro-workbench}},
  year         = {2025},
  version      = {1.0.0},
  publisher    = {Zenodo},
  doi          = {10.5281/zenodo.17600693},
  url          = {https://doi.org/10.5281/zenodo.17598284}
}
```

### Repository Contents
- `macros/0_ImageAnalyzer_v1.ijm` — the macro for DAPI + multi-channel batch processing.
- `macros/README.md` — feature overview and usage notes.

### Requirements
- Fiji (ImageJ) distribution with the **Bio-Formats** plugin.
- ND2, CZI, or TIFF files from compatible microscopy systems.

### Installation
1. Download or clone this repository.
2. Copy `macros/0_ImageAnalyzer_v1.ijm` into your Fiji macros folder (`Fiji.app/macros/` or another scripts location).
3. Launch Fiji, go to `Plugins → Macros → Run...`, and select the macro.

### Usage Overview
1. Run the macro and choose a folder containing ND2, CZI, or TIFF files.
2. Configure the dialog options:
   - Enhance contrast (global or per-channel saturation).
   - Fixed intensity ranges per channel (C1–C4) with optional LUT baking.
   - Channel colors, including composite colors (Cyan, Magenta, Yellow).
   - Panel layout (choose which image appears larger).
   - Scale-bar length, font size, and thickness.
3. Review the generated outputs saved next to the source data:
   - `__DAPI.jpg`
   - `__DAPI_plus_Cn.jpg` (per detected channel up to C4)
   - `__MERGE_DAPI_C2_C3_...jpg`
   - `__PANEL.jpg`
4. Consult `ImageAnalyzer_Log.txt` for a record of settings and processed files.

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
