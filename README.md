# ImageJ-macro-workbench
## ND2/TIFF Image Analyzer (Fiji Macros)

I maintain a set of ImageJ/Fiji macros that automate DAPI and multichannel exports from Nikon ND2 or TIFF acquisitions for reproducibility. Each script supports one to four fluorescence channels and produces publication-ready JPEG outputs and figure panels.

### Repository Contents
- `0_NikonAx_ImageAnalyzer_4Channels_v1.ijm` → My foundational pipeline that generates DAPI-only, DAPI+channel, full-merge, and composite panel outputs.
- `0_NikonAx_ImageAnalyzer_4Channels_v2.ijm` → Adds optional per-channel intensity ranges and thicker panel borders.
- `0_NikonAx_ImageAnalyzer_4Channels_v3.ijm` → Replaces border drawing with a deterministic fill-based helper.
- `0_NikonAx_ImageAnalyzer_4Channels_v4.ijm` → Locks in colour mapping, handles three-channel datasets seamlessly, and writes a processing log.
- `ND2_ImageAnalyzer_Version_Report.md` → My detailed comparison of all releases.

### Requirements
- Fiji (ImageJ) distribution with the **Bio-Formats** plugin.
- ND2 or TIFF files exported from Nikon AX (or any compatible acquisition).

### Installation
1. Download or clone this repository.
2. Copy the `.ijm` macro you want into your Fiji macros folder (`Fiji.app/macros/` or another scripts location).
3. Launch Fiji, go to `Plugins → Macros → Run...`, and select the macro.

### Usage Overview
1. Run the macro and choose the folder containing ND2/TIFF files.
2. Configure the dialog options I expose:
   - Enhance contrast (global or per-channel saturation).
   - Global or per-channel fixed intensity ranges; optional LUT baking.
   - Scale-bar length, font size, and thickness.
3. The macro processes each file and writes JPEG outputs beside the source data:
   - `__DAPI.jpg`
   - `__DAPI_plus_Cn.jpg` for each detected channel (up to C4)
   - `__MERGE_DAPI_C2_C3_...jpg`
   - `__PANEL_LEFT3_PLUS_MERGE.jpg`
4. In v4, I also drop a log file (`ND2_ImageAnalyzer_Log.txt`) summarising the settings and results.

### Choosing a Version
- **v1**: My quickstart option with global contrast control only.
- **v2**: Ideal when individual fluorophores need custom display ranges.
- **v3**: Best when I need perfectly consistent panel borders for figures.
- **v4** *(latest)*: My default choice for colour fidelity, three-channel robustness, and audit logging.

See `ND2_ImageAnalyzer_Version_Report.md` for the full changelog and technical notes.

### Contributing
I welcome pull requests and issue reports. Please include:
- Fiji/ImageJ version and operating system.
- Dataset characteristics (channel count, acquisition settings).
- Steps that reproduce bugs or justify enhancement ideas.

### License
I release this project under the MIT License. See `LICENSE` for details.  
Thank you to the Image Analysis community for building and maintaining Fiji, the platform that makes these macros possible.


