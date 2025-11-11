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
// Update (v4):
//  - Automatically adapts to three-channel acquisitions (C1/DAPI blue,
//    C2 green, C3 red) without requiring a dummy fourth channel.
//  - Ensures consistent colour mapping across DAPI+channel composites
//    and the final merge (blue nuclei, green C2, red C3, optional fourth
//    channel reserved for far-red/gray).
// Options:
//  - Optional Enhance Contrast (saturation percent) for autoscaling.
//  - Optional fixed display range via setMinAndMax (with optional Apply LUT
//    to bake scaling into pixels).
//  - Scale bar length, font size, and thickness are configurable.
// ------------------------------------------------------------

macro "ND2 Image Analyzer→ DAPI-alone, DAPI+Channels, Final Merge — ALL FILES (v4)" {
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
    // Optional per-channel fixed ranges for C2–C4
    Dialog.addCheckbox("Use per-channel fixed ranges for C2–C4", false);
    Dialog.addNumber("C2 min intensity", 50);
    Dialog.addNumber("C2 max intensity", 3000);
    Dialog.addNumber("C3 min intensity", 50);
    Dialog.addNumber("C3 max intensity", 3000);
    Dialog.addNumber("C4 min intensity", 50);
    Dialog.addNumber("C4 max intensity", 3000);
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
    useFixedPer = Dialog.getCheckbox();
    c2Min = Dialog.getNumber();
    c2Max = Dialog.getNumber();
    c3Min = Dialog.getNumber();
    c3Max = Dialog.getNumber();
    c4Min = Dialog.getNumber();
    c4Max = Dialog.getNumber();

    timestamp = getTimestamp();
    logFile = folder + "ND2_ImageAnalyzer_Log.txt";
    logText = "ND2 Image Analyzer Log\n";
    logText = logText + "Run timestamp: " + timestamp + "\n";
    logText = logText + "Input folder: " + folder + "\n";
    logText = logText + "Enhance contrast enabled: " + boolToString(doEnhance) + "\n";
    logText = logText + "Enhance contrast saturation (%): " + satPct + "\n";
    logText = logText + "Scale bar length (µm): " + sbLen + "\n";
    logText = logText + "Scale bar font size: " + sbFont + "\n";
    logText = logText + "Scale bar thickness (px): " + sbThick + "\n";
    logText = logText + "Use fixed range for all channels: " + boolToString(useFixed) + "\n";
    logText = logText + "Fixed min intensity: " + fixedMin + "\n";
    logText = logText + "Fixed max intensity: " + fixedMax + "\n";
    logText = logText + "Apply LUT: " + boolToString(applyLUT) + "\n";
    logText = logText + "Use per-channel fixed ranges: " + boolToString(useFixedPer) + "\n";
    logText = logText + "C2 min/max: " + c2Min + " / " + c2Max + "\n";
    logText = logText + "C3 min/max: " + c3Min + " / " + c3Max + "\n";
    logText = logText + "C4 min/max: " + c4Min + " / " + c4Max + "\n";
    logText = logText + "\nProcessed files:\n";
    processedCount = 0;

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
        logText = logText + "- " + file + "\n";
        print("\\ Processing: " + fullPath);

        // Open via Bio-Formats as composite hyperstack (supports ND2 and TIFF)
        run("Bio-Formats Importer", "open=[" + fullPath + "] color_mode=Composite view=Hyperstack stack_order=XYCZT autoscale");
        orig = getTitle();
        Stack.setDisplayMode("composite");
        Stack.getDimensions(w,h,C,Z,T);
        if (C < 1) { if (isOpen(orig)) {selectWindow(orig); close();} continue; }
        // Limit to DAPI + 3 channels (C2..C4)
        maxChannel = C;
        if (maxChannel > 4) maxChannel = 4;

        // Duplicate & split channels
        run("Duplicate...", "title=Work_Stack duplicate");
        selectWindow("Work_Stack");
        if (useFixed) {
            // Apply one fixed display range to all channels before splitting
            Stack.setDisplayMode("composite");
            for (cc=1; cc<=C; cc++) {
                Stack.setChannel(cc);
                setMinAndMax(fixedMin, fixedMax);
            }
            if (applyLUT) {
                run("Apply LUT");
            }
        } else if (useFixedPer) {
            // Apply per-channel fixed ranges for C2–C4 before splitting
            Stack.setDisplayMode("composite");
            for (cc=1; cc<=C; cc++) {
                Stack.setChannel(cc);
                if (cc==2) setMinAndMax(c2Min, c2Max);
                else if (cc==3) setMinAndMax(c3Min, c3Max);
                else if (cc==4) setMinAndMax(c4Min, c4Max);
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
            logText = logText + "    Skipped: no C1 (DAPI) channel detected.\n";
            run("Close All");
            if (isOpen(orig)) { selectWindow(orig); close(); }
            continue;
        }
        // clean 8-bit DAPI temp for merging
        selectWindow(dapiSrc);
        if (!useFixed && !useFixedPer && doEnhance) {
            run("Enhance Contrast", "saturated=" + satPct);
        }
        run("Duplicate...", "title=__TMP_DAPI");
        selectWindow("__TMP_DAPI"); run("8-bit");

        // DAPI alone (with scalebar)
        run("Duplicate...", "title=__TMP_DAPI_SAVE");
        selectWindow("__TMP_DAPI_SAVE");
        run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
        saveAs("Jpeg", folder + base + "__DAPI.jpg");
        logText = logText + "    Saved DAPI image: " + folder + base + "__DAPI.jpg\n";
        close(); // __TMP_DAPI_SAVE

        // DAPI + each other channel (C2..C4)
        for (c=2; c<=maxChannel; c++) {
            cname = "C" + c + "-Work_Stack";
            if (!isOpen(cname)) continue;

            // 8-bit copy of channel c
            selectWindow(cname);
            if (!useFixed && !useFixedPer && doEnhance) {
                run("Enhance Contrast", "saturated=" + satPct);
            }
            run("Duplicate...", "title=__TMP_CH");
            selectWindow("__TMP_CH"); run("8-bit");

            mergeSpec = getTwoChannelMergeSpec(c, "__TMP_DAPI", "__TMP_CH");
            run("Merge Channels...", mergeSpec + " create keep");
            run("RGB Color");
            run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
            saveAs("Jpeg", folder + base + "__DAPI_plus_C" + c + ".jpg");
            logText = logText + "    Saved DAPI + C" + c + ": " + folder + base + "__DAPI_plus_C" + c + ".jpg\n";
            close(); // merged RGB
            if (isOpen("__TMP_CH")) { selectWindow("__TMP_CH"); close(); } // clean per-channel temp
        }

        // Final merged image: DAPI + up to 3 other channels
        if (isOpen("__TMP_DAPI")) {
            mergeArgs = "";
            for (k = 2; k <= maxChannel; k++) {
                kname = "C" + k + "-Work_Stack";
                if (!isOpen(kname)) continue;
                selectWindow(kname);
                if (!useFixed && !useFixedPer && doEnhance) {
                    run("Enhance Contrast", "saturated=" + satPct);
                }
                tmpName = "__TMP_C" + k;
                run("Duplicate...", "title=" + tmpName);
                selectWindow(tmpName); run("8-bit");
                mergeArgs = addChannelToMergeArgs(mergeArgs, k, tmpName);
            }

            mergeArgs = "c3=[__TMP_DAPI] " + mergeArgs;
            run("Merge Channels...", mergeArgs + "create");
            run("RGB Color");
            run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
            label = "__MERGE_DAPI";
            for (k=2; k<=maxChannel; k++) {
                kname = "C" + k + "-Work_Stack";
                if (isOpen(kname)) label = label + "_C" + k;
            }
            mergeSavePath = folder + base + label + ".jpg";
            saveAs("Jpeg", mergeSavePath);
            logText = logText + "    Saved final merge: " + mergeSavePath + "\n";
            close(); // merged RGB

            // Cleanup temps for merge
            if (isOpen("__TMP_DAPI")) { selectWindow("__TMP_DAPI"); close(); }
            for (k=2; k<=maxChannel; k++) {
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
                // Prepare border style (thick white lines)
                setForegroundColor(255,255,255);
                borderWidth = 20;
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
                    drawThickBorder(0, yoff, sW, sH, borderWidth);
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
                drawThickBorder(sW, 0, mW, panelH, borderWidth);
                // Draw outer border
                drawThickBorder(0, 0, sW + mW, panelH, borderWidth);
                // Save panel
                saveAs("Jpeg", folder + base + "__PANEL_LEFT3_PLUS_MERGE.jpg");
                logText = logText + "    Saved panel: " + folder + base + "__PANEL_LEFT3_PLUS_MERGE.jpg\n";
                // Close temp panel and merged
                selectWindow(panelTitle); close();
                selectWindow(mergedTitle); close();
            }
        }

        // Close everything from this file before next
        run("Close All");
        if (isOpen(orig)) { selectWindow(orig); close(); }

        print("Saved: " + base + " (DAPI, DAPI+channels, final merge)");
        logText = logText + "    Status: completed\n";
        processedCount++;
    }

    setBatchMode(false);
    print("\\ All files processed.");
    logText = logText + "\nTotal completed files: " + processedCount + "\n";
    File.saveString(logText, logFile);
    print("Log saved to: " + logFile);
}

function boolToString(value) {
    if (value) return "Yes";
    return "No";
}

function getTimestamp() {
    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, millisecond);
    ts = "" + year;
    ts = ts + "-" + pad2(month);
    ts = ts + "-" + pad2(dayOfMonth);
    ts = ts + " " + pad2(hour);
    ts = ts + ":" + pad2(minute);
    ts = ts + ":" + pad2(second);
    return ts;
}

function pad2(value) {
    if (value < 10) return "0" + value;
    return "" + value;
}

// --- helper: filename without extension ---
function getBaseName(filename){
    dot = lastIndexOf(filename, ".");
    if (dot > 0) return substring(filename, 0, dot);
    return filename;
}

// --- helper: draw thick border rectangle ---
function drawThickBorder(x, y, w, h, thickness) {
    // Draw top edge
    makeRectangle(x, y, w, thickness);
    run("Fill");
    // Draw bottom edge
    makeRectangle(x, y + h - thickness, w, thickness);
    run("Fill");
    // Draw left edge
    makeRectangle(x, y, thickness, h);
    run("Fill");
    // Draw right edge
    makeRectangle(x + w - thickness, y, thickness, h);
    run("Fill");
    run("Select None");
}

// --- helper: merge spec for DAPI + single channel ---
function getTwoChannelMergeSpec(channelIndex, dapiTitle, channelTitle) {
    // c1=red, c2=green, c3=blue, c4=gray in ImageJ merge.
    if (channelIndex == 2) {
        // Channel 2 green, DAPI blue
        return "c2=[" + channelTitle + "] c3=[" + dapiTitle + "]";
    } else if (channelIndex == 3) {
        // Channel 3 red, DAPI blue
        return "c1=[" + channelTitle + "] c3=[" + dapiTitle + "]";
    } else {
        // Default: place other channel in red, DAPI blue
        return "c1=[" + channelTitle + "] c3=[" + dapiTitle + "]";
    }
}

// --- helper: add channel to final merge args ---
function addChannelToMergeArgs(existingArgs, channelIndex, tmpTitle) {
    spec = existingArgs;
    if (channelIndex == 2) {
        spec = spec + "c2=[" + tmpTitle + "] ";
    } else if (channelIndex == 3) {
        spec = spec + "c1=[" + tmpTitle + "] ";
    } else if (channelIndex == 4) {
        spec = spec + "c4=[" + tmpTitle + "] ";
    } else {
        // fallback
        spec = spec + "c1=[" + tmpTitle + "] ";
    }
    return spec;
}


