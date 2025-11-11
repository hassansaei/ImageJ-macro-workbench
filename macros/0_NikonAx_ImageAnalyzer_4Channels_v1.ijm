// ------------------------------------------------------------
// Author: Hassan Saei
// Email: hassan.saeiahan@gmail.com
// Affiliation: Imagine Institute of Genetic Diseases, U1163 INSERM
//
// Description:
// This ImageJ/Fiji macro batch-processes ND2 microscopy files to produce:
//  - A DAPI-only image with a scale bar.
//  - DAPI + up to three other channels (C2–C4) composites, each saved.
//  - A final merged image (DAPI plus up to C2–C4), saved.
//  - A panel combining up to three DAPI+channel composites stacked on the left
//    and the large merged image on the right, with thin white borders.
// Options:
//  - Optional Enhance Contrast (saturation percent) for autoscaling.
//  - Optional fixed display range via setMinAndMax (with optional Apply LUT
//    to bake scaling into pixels).
//  - Scale bar length, font size, and thickness are configurable.
// ------------------------------------------------------------

macro "ND2 Image Analyzer→ DAPI-alone, DAPI+Channels, Final Merge — ALL FILES" {
    // 1) Pick folder
    folder = getDirectory("Choose a folder with ND2 or TIFF files");

    // 2) Settings (once)
    Dialog.create("Settings");
    Dialog.addCheckbox("Enable enhance contrast", true);
	Dialog.addNumber("Enhance contrast (saturated %, e.g. 0.5):", 0.5);
    Dialog.addNumber("Scale bar length (µm):", 50);
    Dialog.addNumber("Scale bar font size:", 90);
    Dialog.addNumber("Scale bar thickness (px):", 100);
    Dialog.addCheckbox("Use fixed display range (setMinAndMax)", false);
    Dialog.addNumber("Fixed min intensity", 50);
    Dialog.addNumber("Fixed max intensity", 3000);
    Dialog.addCheckbox("Apply LUT (bake scaling into pixels)", false);
    Dialog.show();
	satPct  = Dialog.getNumber();
	doEnhance = Dialog.getCheckbox();
	sbLen   = Dialog.getNumber();
    sbFont  = Dialog.getNumber();
    sbThick = Dialog.getNumber();
    useFixed = Dialog.getCheckbox();
    fixedMin = Dialog.getNumber();
    fixedMax = Dialog.getNumber();
    applyLUT = Dialog.getCheckbox();

    // 3) Process all ND2 files
    files = getFileList(folder);
    setBatchMode(true);

	for (i=0; i<files.length; i++) {
		mergeSavePath = "";
        file = files[i];
        fLower = toLowerCase(file);
        isND2 = endsWith(fLower, ".nd2");
        isTIF = endsWith(fLower, ".tif") || endsWith(fLower, ".tiff");
        if (!(isND2 || isTIF)) continue;

        fullPath = folder + file;
        base = getBaseName(file);
        print("\\ Processing: " + fullPath);

        // Open via Bio-Formats as composite hyperstack (supports ND2 and TIFF)
        run("Bio-Formats Importer", "open=[" + fullPath + "] color_mode=Composite view=Hyperstack stack_order=XYCZT autoscale");
        orig = getTitle();
        Stack.setDisplayMode("composite");
        Stack.getDimensions(w,h,C,Z,T);
        if (C < 1) { if (isOpen(orig)) {selectWindow(orig); close();} continue; }
        // Limit to DAPI + 3 channels (C2..C4)
        maxChannel = C;
        if (C > 4) maxChannel = 4;

        // Duplicate & split channels
        run("Duplicate...", "title=Work_Stack duplicate");
        selectWindow("Work_Stack");
        if (useFixed) {
            // Apply fixed display range to each slice/channel before splitting
            Stack.setDisplayMode("composite");
            for (cc=1; cc<=C; cc++) {
                Stack.setChannel(cc);
                setMinAndMax(fixedMin, fixedMax);
            }
            if (applyLUT) {
                run("Apply LUT");
            }
        }
        run("Split Channels");

        // Make clean 8-bit DAPI temp and save DAPI-alone ----------
        dapiSrc = "C1-Work_Stack";
        if (!isOpen(dapiSrc)) {
            print("No C1 (DAPI) found; skipping file.");
            run("Close All");
            if (isOpen(orig)) { selectWindow(orig); close(); }
            continue;
        }
        // clean 8-bit DAPI temp for merging
        selectWindow(dapiSrc);
		if (!useFixed && doEnhance) {
            run("Enhance Contrast", "saturated=" + satPct);
        }
        run("Duplicate...", "title=__TMP_DAPI");
        selectWindow("__TMP_DAPI"); run("8-bit");

        // DAPI alone (with scalebar)
        run("Duplicate...", "title=__TMP_DAPI_SAVE");
        selectWindow("__TMP_DAPI_SAVE");
        run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
        saveAs("Jpeg", folder + base + "__DAPI.jpg");
        close(); // __TMP_DAPI_SAVE

        // DAPI + each other channel (C2..C4)
        c = 2;
        while (true) {
            cname = "C" + c + "-Work_Stack";
            if (!isOpen(cname)) break;

            // 8-bit copy of channel c
            selectWindow(cname);
			if (!useFixed && doEnhance) {
                run("Enhance Contrast", "saturated=" + satPct);
            }
            run("Duplicate...", "title=__TMP_CH");
            selectWindow("__TMP_CH"); run("8-bit");

            // Merge DAPI + channel c
            run("Merge Channels...", "c1=[__TMP_DAPI] c2=[__TMP_CH] create keep");
            run("RGB Color");
            run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
            saveAs("Jpeg", folder + base + "__DAPI_plus_C" + c + ".jpg");
            close(); // merged RGB
            if (isOpen("__TMP_CH")) { selectWindow("__TMP_CH"); close(); } // clean per-channel temp

            c++;
            if (c > maxChannel) break;
        }

        // Final merged image: DAPI + up to 3 other channels
        if (isOpen("__TMP_DAPI")) {
            mergeArgs = "c1=[__TMP_DAPI] ";
            slot = 2;
            for (k = 2; k <= maxChannel; k++) {
                kname = "C" + k + "-Work_Stack";
                if (!isOpen(kname)) continue;
                selectWindow(kname);
				if (!useFixed && doEnhance) {
                    run("Enhance Contrast", "saturated=" + satPct);
                }
                run("Duplicate...", "title=__TMP_C" + k);
                selectWindow("__TMP_C" + k); run("8-bit");
                mergeArgs += "c" + slot + "=[__TMP_C" + k + "] ";
                slot++;
            }

            if (slot > 2) {
                run("Merge Channels...", mergeArgs + "create");
                run("RGB Color");
                run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
                label = "__MERGE_DAPI"; for (k=2; k<=maxChannel; k++) label = label + "_C" + k;
				mergeSavePath = folder + base + label + ".jpg";
				saveAs("Jpeg", mergeSavePath);
                close(); // merged RGB
            }

            // Cleanup temps for merge
            if (isOpen("__TMP_DAPI")) { selectWindow("__TMP_DAPI"); close(); }
            for (k=2; k<=C; k++) {
                tname = "__TMP_C" + k;
                if (isOpen(tname)) { selectWindow(tname); close(); }
            }
        }

        // Create panel: up to three DAPI+channel composites on left, big merged on right
        // Determine how many small panels exist (C2..C4)
		nSmall = 0;
        for (pc=2; pc<=maxChannel; pc++) {
            if (nSmall >= 3) break;
			ppath = folder + base + "__DAPI_plus_C" + pc + ".jpg";
			if (File.exists(ppath)) nSmall++;
		}
		if (nSmall > 0 && mergeSavePath != "") {
			// Find first existing small image to get dimensions
			firstPath = "";
            for (pc=2; pc<=maxChannel; pc++) {
				ppath = folder + base + "__DAPI_plus_C" + pc + ".jpg";
				if (File.exists(ppath)) { firstPath = ppath; break; }
			}
			if (firstPath != "") {
				open(firstPath);
				sW = getWidth(); sH = getHeight();
				close();
				panelH = nSmall * sH;
				// Prepare merged image resized to panel height
				open(mergeSavePath);
				run("Size...", "height=" + panelH + " constrain average interpolation=Bilinear");
				mW = getWidth();
				mergedTitle = getTitle();
				// Create panel canvas
				newImage("PANEL_"+base, "RGB black", sW + mW, panelH, 1);
				panelTitle = getTitle();
				// Prepare border style (thin white lines)
				setForegroundColor(255,255,255);
				setLineWidth(4);
			// Paste small panels stacked on left
				yoff = 0;
				placed = 0;
                for (pc=2; pc<=maxChannel; pc++) {
                    if (placed >= 3) break;
					ppath = folder + base + "__DAPI_plus_C" + pc + ".jpg";
					if (!File.exists(ppath)) continue;
					open(ppath);
					smallTitle = getTitle();
					// Ensure exact size match
					if (getWidth()!=sW || getHeight()!=sH) {
						run("Size...", "width=" + sW + " height=" + sH + " average interpolation=Bilinear");
					}
					run("Copy");
					selectWindow(panelTitle);
					makeRectangle(0, yoff, sW, sH);
					run("Paste");
					// Draw tile border
					makeRectangle(0, yoff, sW, sH);
					run("Draw");
					run("Select None");
					yoff = yoff + sH;
					selectWindow(smallTitle);
					close();
					placed = placed + 1;
				}
				// Paste merged on right
				selectWindow(mergedTitle);
				run("Copy");
				selectWindow(panelTitle);
				makeRectangle(sW, 0, mW, panelH);
				run("Paste");
				// Draw merged image border
				makeRectangle(sW, 0, mW, panelH);
				run("Draw");
				run("Select None");
				// Draw outer border
				makeRectangle(0, 0, sW + mW, panelH);
				run("Draw");
				run("Select None");
                // Save panel
                saveAs("Jpeg", folder + base + "__PANEL_LEFT3_PLUS_MERGE.jpg");
				// Close temp panel and merged
				selectWindow(panelTitle); close();
				selectWindow(mergedTitle); close();
			}
		}

		// Close everything from this file before next
        run("Close All");
        if (isOpen(orig)) { selectWindow(orig); close(); }

        print("Saved: " + base + " (DAPI, DAPI+channels, final merge)");
    }

    setBatchMode(false);
    print("\\ All files processed.");
}

// --- helper: filename without extension ---
function getBaseName(filename){
    dot = lastIndexOf(filename, ".");
    if (dot > 0) return substring(filename, 0, dot);
    return filename;
}