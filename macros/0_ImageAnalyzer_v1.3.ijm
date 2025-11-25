// ------------------------------------------------------------
// Author: Hassan Saei
// Email: hassan.saeiahan@gmail.com
// Affiliation: Imagine Institute of Genetic Diseases, U1163 INSERM, Paris, France
//
// Description:
// This ImageJ/Fiji macro batch-processes ND2, CZI, and TIFF microscopy files to produce:
//  - A C1-only image with a scale bar.
//  - Individual channel renderings (C1–C4) with scale bars.
//  - C1 + up to three other channels (C2–C4) composites, each saved.
//  - All pairwise composites of non-C1 channels and an optional no-C1 composite.
//  - A final merged image (C1 plus up to C2–C4), saved.
//  - A panel created after interactive selection of the larger preview image and supporting tiles,
//    with white borders and automatic resizing.
// Options:
//  - File format support: ND2 (Nikon), CZI (Zeiss), and TIFF files
//  - Optional Enhance Contrast (saturation percent) for autoscaling
//  - Optional fixed display range via setMinAndMax (global or per-channel for C1-C4)
//    with optional Apply LUT to bake scaling into pixels
//  - Per-channel intensity control: independent min/max ranges for C1, C2, C3, and C4
//  - Scale bar: configurable length (µm), font size, and thickness (px)
//  - User-defined color assignment for each channel (C1, C2, C3, C4):
//    choose from Red, Green, Blue, Gray, Cyan, Magenta, Yellow, or None
//  - Panel layout: select which image appears larger (Merged, C1+C2, C1+C3, or C1+C4)
//  - Automatic logging: processing details saved to ImageAnalyzer_Log.txt
// ------------------------------------------------------------

macro "Image Analyzer → DAPI and Multi-Channel Processing — ALL FILES (v1.3)" {
    // 1) Pick folder
    folder = getDirectory("Choose a folder with ND2, CZI, or TIFF files");

    // 2) Settings (once)
    Dialog.create("Settings");
    Dialog.addMessage("— Enhance Contrast & Scale Bar —");
    Dialog.addCheckbox("Enable enhance contrast", true);
    Dialog.addNumber("Enhance contrast (saturated %, e.g. 0.35):", 0.35);
    Dialog.addNumber("Scale bar length (µm):", 50);
    Dialog.addNumber("Scale bar font size:", 90);
    Dialog.addNumber("Scale bar thickness (px):", 100);
    Dialog.addMessage("— Display Range —");
    Dialog.addCheckbox("Use fixed display range (setMinAndMax)", false);
    Dialog.addNumber("Fixed min intensity", 50);
    Dialog.addNumber("Fixed max intensity", 3000);
    Dialog.addCheckbox("Apply LUT (bake scaling into pixels)", false);
    Dialog.addMessage("— Per-Channel Fixed Ranges (C1–C4) —");
    // Optional per-channel fixed ranges for C1–C4
    Dialog.addCheckbox("Use per-channel fixed ranges for C1–C4", false);
    Dialog.addNumber("C1 min intensity", 50);
    Dialog.addNumber("C1 max intensity", 3000);
    Dialog.addNumber("C2 min intensity", 50);
    Dialog.addNumber("C2 max intensity", 3000);
    Dialog.addNumber("C3 min intensity", 50);
    Dialog.addNumber("C3 max intensity", 3000);
    Dialog.addNumber("C4 min intensity", 50);
    Dialog.addNumber("C4 max intensity", 3000);
    // Channel Color Selection
    Dialog.addMessage("- Channel Color Assignment -");
    Dialog.addChoice("C1 color:", newArray("Blue", "Red", "Green", "Gray", "Cyan", "Magenta", "Yellow", "None"), "Blue");
    Dialog.addChoice("C2 color:", newArray("Green", "Red", "Blue", "Gray", "Cyan", "Magenta", "Yellow", "None"), "Green");
    Dialog.addChoice("C3 color:", newArray("Red", "Green", "Blue", "Gray", "Cyan", "Magenta", "Yellow", "None"), "Red");
    Dialog.addChoice("C4 color:", newArray("Gray", "Red", "Green", "Blue", "Cyan", "Magenta", "Yellow", "None"), "Gray");
    Dialog.addMessage("- Panel Layout -");
    panelLargeOptions = newArray("Merged (C1)", "C1", "C1+C2", "C1+C3", "C1+C4", "No C1", "C2", "C3", "C4", "C2+C3", "C2+C4", "C3+C4", "C1+C2+C3", "C1+C2+C4", "C1+C3+C4", "C2+C3+C4");
    panelSmallOptions = newArray("None", "C1", "C1+C2", "C1+C3", "C1+C4", "No C1", "C2", "C3", "C4", "C2+C3", "C2+C4", "C3+C4", "C1+C2+C3", "C1+C2+C4", "C1+C3+C4", "C2+C3+C4");
    Dialog.addChoice("Large panel image:", panelLargeOptions, panelLargeOptions[0]);
    Dialog.addChoice("Smaller image slot 1:", panelSmallOptions, "C1");
    Dialog.addChoice("Smaller image slot 2:", panelSmallOptions, "C1+C2");
    Dialog.addChoice("Smaller image slot 3:", panelSmallOptions, "C1+C3");
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
    c1Min = Dialog.getNumber();
    c1Max = Dialog.getNumber();
    c2Min = Dialog.getNumber();
    c2Max = Dialog.getNumber();
    c3Min = Dialog.getNumber();
    c3Max = Dialog.getNumber();
    c4Min = Dialog.getNumber();
    c4Max = Dialog.getNumber();
    // Get color choices (must be retrieved in order after all other fields)
    c1Color = Dialog.getChoice();
    c2Color = Dialog.getChoice();
    c3Color = Dialog.getChoice();
    c4Color = Dialog.getChoice();
    panelLargerImage = Dialog.getChoice();
    panelSmallChoice1 = Dialog.getChoice();
    panelSmallChoice2 = Dialog.getChoice();
    panelSmallChoice3 = Dialog.getChoice();
    
    // Debug: Print selected colors
    panelSmallerSelections = newArray(panelSmallChoice1, panelSmallChoice2, panelSmallChoice3);
    panelSmallerChoicesLog = panelSmallChoice1 + ", " + panelSmallChoice2 + ", " + panelSmallChoice3;

    print("Selected colors - C1: " + c1Color + ", C2: " + c2Color + ", C3: " + c3Color + ", C4: " + c4Color);
    print("Panel - Large: " + panelLargerImage + ", Smaller slots: [" + panelSmallChoice1 + ", " + panelSmallChoice2 + ", " + panelSmallChoice3 + "]");

    timestamp = getTimestamp();
    analysisSuffix = getDateFolderSuffix();
    outputDir = folder + "analysis_" + analysisSuffix + "/";
    File.makeDirectory(outputDir);
    logFile = outputDir + "ImageAnalyzer_Log_" + analysisSuffix + ".txt";
    logText = "Image Analyzer Log\n";
    logText = logText + "Run timestamp: " + timestamp + "\n";
    logText = logText + "Input folder: " + folder + "\n";
    logText = logText + "Output folder: " + outputDir + "\n";
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
    logText = logText + "C1 min/max: " + c1Min + " / " + c1Max + "\n";
    logText = logText + "C2 min/max: " + c2Min + " / " + c2Max + "\n";
    logText = logText + "C3 min/max: " + c3Min + " / " + c3Max + "\n";
    logText = logText + "C4 min/max: " + c4Min + " / " + c4Max + "\n";
    logText = logText + "Channel colors - C1: " + c1Color + ", C2: " + c2Color + ", C3: " + c3Color + ", C4: " + c4Color + "\n";
    logText = logText + "Panel larger image: " + panelLargerImage + "\n";
    logText = logText + "Panel smaller images: " + panelSmallerChoicesLog + "\n";
    logText = logText + "\nProcessed files:\n";
    processedCount = 0;

    // 4) Process all files
    files = getFileList(folder);
    setBatchMode(true);

    for (i=0; i<files.length; i++) {
        mergeSavePath = "";
        c1AlonePath = "";
        noC1Path = "";
        file = files[i];
        fLower = toLowerCase(file);
        isND2 = endsWith(fLower, ".nd2");
        isTIF = endsWith(fLower, ".tif") || endsWith(fLower, ".tiff");
        isCZI = endsWith(fLower, ".czi");
        if (!(isND2 || isTIF || isCZI)) continue;

        fullPath = folder + file;
        base = getBaseName(file);
        logText = logText + "- " + file + "\n";
        print("\\ Processing: " + fullPath);

        // Open via Bio-Formats as composite hyperstack (supports ND2, CZI, and TIFF)
        // Using color_mode=Colorized to preserve original LUT colors from file metadata
        run("Bio-Formats Importer", "open=[" + fullPath + "] color_mode=Colorized view=Hyperstack stack_order=XYCZT autoscale");
        orig = getTitle();
        Stack.setDisplayMode("composite");
        Stack.getDimensions(w,h,C,Z,T);
        if (C < 1) { safeClose(orig); continue; }
        // Limit to C1 + 3 additional channels (C2..C4)
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
            // Apply per-channel fixed ranges for C1–C4 before splitting
            Stack.setDisplayMode("composite");
            for (cc=1; cc<=C; cc++) {
                Stack.setChannel(cc);
                if (cc==1) setMinAndMax(c1Min, c1Max);
                else if (cc==2) setMinAndMax(c2Min, c2Max);
                else if (cc==3) setMinAndMax(c3Min, c3Max);
                else if (cc==4) setMinAndMax(c4Min, c4Max);
            }
            if (applyLUT) {
                run("Apply LUT");
            }
        }
        run("Split Channels");

        // Remove LUT colors from all split channels to allow custom color assignment
        // Convert all channels to grayscale (removes LUT colors)
        for (cc=1; cc<=C; cc++) {
            cname = "C" + cc + "-Work_Stack";
            if (isOpen(cname)) {
                selectWindow(cname);
                // Set LUT to grayscale to remove original colors
                run("Grays");
            }
        }

        // Make clean 8-bit C1 temp and save C1-alone ----------
        c1Src = "C1-Work_Stack";
        if (!isOpen(c1Src)) {
            print("No C1 channel found; skipping file.");
            logText = logText + "    Skipped: no C1 channel detected.\n";
            run("Close All");
            safeClose(orig);
            continue;
        }
        // clean 8-bit C1 temp for merging
        selectWindow(c1Src);
        if (!useFixed && !useFixedPer && doEnhance) {
            run("Enhance Contrast", "saturated=" + satPct);
        }
        run("Duplicate...", "title=__TMP_C1");
        selectWindow("__TMP_C1"); 
        run("8-bit");
        run("Grays");  // Ensure grayscale LUT

        // C1 alone (with scalebar and user-selected color)
        run("Duplicate...", "title=__TMP_C1_SAVE");
        selectWindow("__TMP_C1_SAVE");
        applyColorLUT(c1Color);
        run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
        c1AlonePath = outputDir + base + "__C1.jpg";
        saveAs("Jpeg", c1AlonePath);
        logText = logText + "    Saved C1 image: " + c1AlonePath + "\n";
        registerPanelOption("C1", c1AlonePath);
        close(); // __TMP_C1_SAVE

        // C1 + each other channel (C2..C4)
        for (c=2; c<=maxChannel; c++) {
            cname = "C" + c + "-Work_Stack";
            if (!isOpen(cname)) continue;

            // 8-bit copy of channel c
            selectWindow(cname);
            if (!useFixed && !useFixedPer && doEnhance) {
                run("Enhance Contrast", "saturated=" + satPct);
            }
            run("Duplicate...", "title=__TMP_CH");
            selectWindow("__TMP_CH"); 
            run("8-bit");
            run("Grays");  // Ensure grayscale LUT

            chColor = getChannelColor(c, c2Color, c3Color, c4Color);

            // Save channel alone with scale bar and user-selected color
            run("Duplicate...", "title=__TMP_CH_SAVE");
            selectWindow("__TMP_CH_SAVE");
            applyColorLUT(chColor);
            run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
            channelSavePath = outputDir + base + "__C" + c + ".jpg";
            saveAs("Jpeg", channelSavePath);
            logText = logText + "    Saved C" + c + " channel: " + channelSavePath + "\n";
            registerPanelOption("C" + c, channelSavePath);
            close();
            selectWindow("__TMP_CH");
            mergeSpec = getTwoChannelMergeSpecSimple(c, "__TMP_C1", "__TMP_CH", c1Color, chColor);
            print("Merge spec for C1+C" + c + ": " + mergeSpec);
            print("C1 color: " + c1Color + ", Channel " + c + " color: " + chColor);
            run("Merge Channels...", mergeSpec + " create keep");
            run("RGB Color");
            run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
            c1ComboPath = outputDir + base + "__C1_C" + c + ".jpg";
            saveAs("Jpeg", c1ComboPath);
            logText = logText + "    Saved C1 + C" + c + ": " + c1ComboPath + "\n";
            registerPanelOption("C1+C" + c, c1ComboPath);
            close(); // merged RGB
            // Cleanup temp channels
            cleanupTempWindows("__TMP_CH,__TMP_CH_R,__TMP_CH_G,__TMP_CH_B,__TMP_C1_R,__TMP_C1_G,__TMP_C1_B");
        }

        // Build merged composites using shared helper
        mergeChannelList = "";
        if (isOpen("__TMP_C1")) mergeChannelList = "1";
        for (k = 2; k <= maxChannel; k++) {
            kname = "C" + k + "-Work_Stack";
            if (isOpen(kname)) {
                if (mergeChannelList == "") mergeChannelList = "" + k;
                else mergeChannelList = mergeChannelList + "," + k;
            }
        }

        // Final merged image including C1
        if (mergeChannelList != "" && indexOf(mergeChannelList, "1") == 0) {
            mergeLabel = "__MERGE_C1";
            for (k = 2; k <= maxChannel; k++) {
                if (isOpen("C" + k + "-Work_Stack")) mergeLabel = mergeLabel + "_C" + k;
            }
            mergeSavePath = createComposite(mergeChannelList, mergeLabel, true, "final merge");
            if (mergeSavePath != "") {
                registerPanelOption("Merged (C1)", mergeSavePath);
            }
        }

        // Composite without C1 (if any other channels exist)
        nonC1List = "";
        for (k = 2; k <= maxChannel; k++) {
            if (isOpen("C" + k + "-Work_Stack")) {
                if (nonC1List == "") nonC1List = "" + k;
                else nonC1List = nonC1List + "," + k;
            }
        }
        noC1Path = "";
        if (nonC1List != "") {
            noC1Path = createComposite(nonC1List, "__MERGE_NO_C1", true, "composite without C1");
            if (noC1Path != "") {
                registerPanelOption("No C1", noC1Path);
            }
        }

        // Pairwise composites among non-C1 channels
        for (cA = 2; cA <= maxChannel; cA++) {
            nameA = "C" + cA + "-Work_Stack";
            if (!isOpen(nameA)) continue;
            for (cB = cA + 1; cB <= maxChannel; cB++) {
                nameB = "C" + cB + "-Work_Stack";
                if (!isOpen(nameB)) continue;
                pairLabel = "__C" + cA + "_C" + cB;
                pairChannels = "" + cA + "," + cB;
                pairPath = createComposite(pairChannels, pairLabel, true, "pairwise composite C" + cA + "+C" + cB);
                if (pairPath != "") {
                    registerPanelOption("C" + cA + "+C" + cB, pairPath);
                }
            }
        }

        // Three-channel composites (all combinations of available channels, including C1 if present)
        channelIndices = newArray(maxChannel);
        availCount = 0;
        if (isOpen("__TMP_C1")) {
            channelIndices[availCount] = 1;
            availCount++;
        }
        for (k = 2; k <= maxChannel; k++) {
            if (isOpen("C" + k + "-Work_Stack")) {
                channelIndices[availCount] = k;
                availCount++;
            }
        }
        if (availCount >= 3) {
            generateThreeChannelComposites(channelIndices, availCount, base);
        }

        safeClose("__TMP_C1");

        // Create panel using pre-selected options from settings dialog
        // Map user-selected names to actual file paths
        selectedPath = getImagePathForLabel(panelLargerImage, base, outputDir, mergeSavePath, noC1Path, maxChannel);
        
        // Resolve smaller image selections into actual file paths
        panelSmallerPaths = newArray(3);
        smallerCount = 0;
        for (si = 0; si < panelSmallerSelections.length && smallerCount < 3; si++) {
            name = trim(panelSmallerSelections[si]);
            if (name == "" || name == "None") continue;
            smallPath = getImagePathForLabel(name, base, outputDir, mergeSavePath, noC1Path, maxChannel);
            if (smallPath == "" || !File.exists(smallPath) || smallPath == selectedPath) continue;
            // Avoid duplicates
            duplicate = false;
            for (sj = 0; sj < smallerCount; sj++) {
                if (panelSmallerPaths[sj] == smallPath) {
                    duplicate = true;
                    break;
                }
            }
            if (!duplicate) {
                panelSmallerPaths[smallerCount] = smallPath;
                smallerCount++;
            }
        }

        // Create panel if we have valid paths
        if (smallerCount > 0 && selectedPath != "" && File.exists(selectedPath) && File.exists(panelSmallerPaths[0])) {
            open(panelSmallerPaths[0]);
            sW = getWidth(); sH = getHeight();
            close();

            panelH = smallerCount * sH;

            open(selectedPath);
            run("Size...", "height=" + panelH + " constrain average interpolation=Bilinear");
            lW = getWidth();
            largerTitle = getTitle();

            newImage("PANEL_"+base, "RGB black", sW + lW, panelH, 1);
            panelTitle = getTitle();

            setForegroundColor(255,255,255);
            borderWidth = 20;

            yoff = 0;
            for (si = 0; si < smallerCount; si++) {
                smallPath = panelSmallerPaths[si];
                if (!File.exists(smallPath)) continue;
                open(smallPath);
                smallTitle = getTitle();
                if (getWidth()!=sW || getHeight()!=sH) {
                    run("Size...", "width=" + sW + " height=" + sH + " average interpolation=Bilinear");
                }
                run("Copy");
                selectWindow(panelTitle);
                makeRectangle(0, yoff, sW, sH);
                run("Paste");
                drawThickBorder(0, yoff, sW, sH, borderWidth);
                yoff = yoff + sH;
                selectWindow(smallTitle);
                close();
            }

            selectWindow(largerTitle);
            run("Copy");
            selectWindow(panelTitle);
            makeRectangle(sW, 0, lW, panelH);
            run("Paste");
            drawThickBorder(sW, 0, lW, panelH, borderWidth);
            drawThickBorder(0, 0, sW + lW, panelH, borderWidth);

            panelSavePath = outputDir + base + "__PANEL.jpg";
            saveAs("Jpeg", panelSavePath);
            logText = logText + "    Saved panel: " + panelSavePath + " (larger: " + panelLargerImage + ")\n";

            selectWindow(panelTitle); close();
            selectWindow(largerTitle); close();
        } else {
            reason = "selected resources unavailable";
            if (smallerCount == 0) {
                reason = "no smaller images available";
            } else if (selectedPath == "" || !File.exists(selectedPath)) {
                reason = "large image \"" + panelLargerImage + "\" not available";
            }
            logText = logText + "    Panel skipped: " + reason + ".\n";
        }

        // Close everything from this file before next
        run("Close All");
        safeClose(orig);

        print("Saved: " + base + " (C1, C1+channels, final merge)");
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

function getDateFolderSuffix() {
    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, millisecond);
    suffix = "" + year;
    suffix = suffix + pad2(month);
    suffix = suffix + pad2(dayOfMonth);
    return suffix;
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

// --- helper: get color for a specific channel index ---
function getChannelColor(channelIndex, c2Color, c3Color, c4Color) {
    if (channelIndex == 2) return c2Color;
    if (channelIndex == 3) return c3Color;
    if (channelIndex == 4) return c4Color;
    return "None";
}

// --- helper: map color name to ImageJ merge channel (c1=red, c2=green, c3=blue, c4=gray) ---
function getColorChannelMapping(colorName) {
    if (colorName == "Red") return "c1";
    if (colorName == "Green") return "c2";
    if (colorName == "Blue") return "c3";
    if (colorName == "Gray") return "c4";
    if (colorName == "Cyan") return "c5";
    if (colorName == "Magenta") return "c6";
    if (colorName == "Yellow") return "c7";
    if (colorName == "None") return "";
    return "";
}

// --- helper: safely close a window if it exists ---
function safeClose(windowName) {
    if (isOpen(windowName)) {
        selectWindow(windowName);
        close();
    }
}

// --- helper: cleanup multiple temporary windows from comma-separated list ---
function cleanupTempWindows(windowNames) {
    if (windowNames == "") return;
    names = split(windowNames, ",");
    for (i = 0; i < names.length; i++) {
        safeClose(trim(names[i]));
    }
}

function registerPanelOption(label, path) {
    // No-op: panel selection now uses pre-selected options from settings dialog
}

function initCompositeLists() {
    lists = newArray(8);
    lists[0] = ""; // c1 / Red
    lists[1] = ""; // c2 / Green
    lists[2] = ""; // c3 / Blue
    lists[3] = ""; // c4 / Gray
    lists[4] = ""; // c5 / Cyan
    lists[5] = ""; // c6 / Magenta
    lists[6] = ""; // c7 / Yellow
    lists[7] = ""; // Cleanup list
    return lists;
}

function appendListItem(existing, item) {
    if (item == "") return existing;
    if (existing == "") return item;
    return existing + "," + item;
}

function assignToColorLists(baseName, colorName, lists, uniqueTag, addBaseToCleanup) {
    cleanupIdx = lists.length - 1;
    if (addBaseToCleanup) lists[cleanupIdx] = appendListItem(lists[cleanupIdx], baseName);
    if (colorName == "" || colorName == "None") return;

    slotIndex = getColorSlotIndex(colorName);
    if (slotIndex < 0) return;
    lists[slotIndex] = appendListItem(lists[slotIndex], baseName);
}

function getColorSlotIndex(colorName) {
    if (colorName == "Red") return 0;
    if (colorName == "Green") return 1;
    if (colorName == "Blue") return 2;
    if (colorName == "Gray") return 3;
    if (colorName == "Cyan") return 4;
    if (colorName == "Magenta") return 5;
    if (colorName == "Yellow") return 6;
    return -1;
}

function buildMergeSegment(listString, channelCode, combinedBase, lists) {
    if (listString == "") return "";
    parts = split(listString, ",");
    if (parts.length == 1) return channelCode + "=[" + parts[0] + "] ";

    combinedName = combinedBase;
    selectWindow(parts[0]);
    run("Duplicate...", "title=" + combinedName);
    cleanupIdx = lists.length - 1;
    lists[cleanupIdx] = appendListItem(lists[cleanupIdx], combinedName);
    for (j = 1; j < parts.length; j++) {
        run("Image Calculator...", "image1=[" + combinedName + "] operation=Add image2=[" + parts[j] + "] create 32-bit");
        safeClose(combinedName);
        selectWindow("Result of " + combinedName);
        run("Rename...", "title=" + combinedName);
    }
    selectWindow(combinedName);
    run("8-bit");
    run("Grays");
    return channelCode + "=[" + combinedName + "] ";
}

function getColorForChannelIndex(channelIndex) {
    if (channelIndex == 1) return "" + c1Color;
    return "" + getChannelColor(channelIndex, c2Color, c3Color, c4Color);
}

function createComposite(channelIndexString, labelSuffix, addScaleBar, logDescription) {
    if (channelIndexString == "") return "";
    lists = initCompositeLists();
    indexParts = split(channelIndexString, ",");
    includedCount = 0;

    for (ci = 0; ci < indexParts.length; ci++) {
        rawIndex = trim(indexParts[ci]);
        if (rawIndex == "") continue;
        chan = strToInt(rawIndex);
        if (chan < 1) continue;

        if (chan == 1) {
            if (!isOpen("__TMP_C1")) continue;
            colorName = "" + getColorForChannelIndex(chan);
            assignToColorLists("__TMP_C1", colorName, lists, "__TMP_C1_" + labelSuffix + "_" + ci, false);
            if (colorName != "" && colorName != "None") includedCount++;
        } else {
            srcName = "C" + chan + "-Work_Stack";
            if (!isOpen(srcName)) continue;
            selectWindow(srcName);
            if (!useFixed && !useFixedPer && doEnhance) {
                run("Enhance Contrast", "saturated=" + satPct);
            }
            tmpName = "__TMP_C" + chan + "_" + labelSuffix + "_" + ci;
            run("Duplicate...", "title=" + tmpName);
            selectWindow(tmpName);
            run("8-bit");
            run("Grays");
            colorName = "" + getColorForChannelIndex(chan);
            // Track duplicate for cleanup even if color is None
            assignToColorLists(tmpName, colorName, lists, tmpName, true);
            if (colorName == "" || colorName == "None") {
                // Not used; no increment but duplicate recorded for cleanup
            } else {
                includedCount++;
            }
        }
    }

    mergeArgs = "";
    mergeArgs = mergeArgs + buildMergeSegment(lists[0], "c1", "__TMP_RED_COMBINED" + labelSuffix, lists);
    mergeArgs = mergeArgs + buildMergeSegment(lists[1], "c2", "__TMP_GREEN_COMBINED" + labelSuffix, lists);
    mergeArgs = mergeArgs + buildMergeSegment(lists[2], "c3", "__TMP_BLUE_COMBINED" + labelSuffix, lists);
    mergeArgs = mergeArgs + buildMergeSegment(lists[3], "c4", "__TMP_GRAY_COMBINED" + labelSuffix, lists);
    mergeArgs = mergeArgs + buildMergeSegment(lists[4], "c5", "__TMP_CYAN_COMBINED" + labelSuffix, lists);
    mergeArgs = mergeArgs + buildMergeSegment(lists[5], "c6", "__TMP_MAGENTA_COMBINED" + labelSuffix, lists);
    mergeArgs = mergeArgs + buildMergeSegment(lists[6], "c7", "__TMP_YELLOW_COMBINED" + labelSuffix, lists);

    if (mergeArgs == "" || includedCount == 0) {
        cleanupTempWindows(lists[lists.length - 1]);
        return "";
    }

    run("Merge Channels...", mergeArgs + "create keep");
    run("RGB Color");
    if (addScaleBar) {
        run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
    }

    savePath = outputDir + base + labelSuffix + ".jpg";
    saveAs("Jpeg", savePath);
    logText = logText + "    Saved " + logDescription + ": " + savePath + "\n";
    close();

    cleanupTempWindows(lists[lists.length - 1]);
    return savePath;
}

function strToInt(str) {
    if (str == "") return 0;
    v = parseFloat(str);
    if ("" + v == "NaN") return 0;
    return floor(v + 0.5);
}

// --- helper: trim whitespace from string (simple implementation) ---
function trim(str) {
    // Remove leading spaces
    while (lengthOf(str) > 0 && substring(str, 0, 1) == " ") {
        str = substring(str, 1);
    }
    // Remove trailing spaces
    len = lengthOf(str);
    while (len > 0 && substring(str, len - 1, len) == " ") {
        str = substring(str, 0, len - 1);
        len = lengthOf(str);
    }
    return str;
}

// --- helper: merge spec for C1 + single channel using user-defined colors ---
function getTwoChannelMergeSpecSimple(channelIndex, c1Title, channelTitle, c1Color, channelColor) {
    mergeSpec = "";
    mergeSpec = appendMergeSlot(mergeSpec, getColorChannelMapping(c1Color), c1Title);
    mergeSpec = appendMergeSlot(mergeSpec, getColorChannelMapping(channelColor), channelTitle);
    return mergeSpec;
}

function appendMergeSlot(mergeSpec, channelCode, imageTitle) {
    if (channelCode == "" || imageTitle == "") return mergeSpec;
    if (indexOf(mergeSpec, channelCode + "=") >= 0) return mergeSpec;
    return mergeSpec + channelCode + "=[" + imageTitle + "] ";
}

// --- helper: apply color LUT based on color name ---
function applyColorLUT(colorName) {
    if (colorName == "Red") {
        run("Red");
    } else if (colorName == "Green") {
        run("Green");
    } else if (colorName == "Blue") {
        run("Blue");
    } else if (colorName == "Gray") {
        run("Grays");
    } else if (colorName == "Cyan") {
        run("Cyan");
    } else if (colorName == "Magenta") {
        run("Magenta");
    } else if (colorName == "Yellow") {
        run("Yellow");
    } else {
        // None or unknown - keep grayscale
        run("Grays");
    }
}

// --- helper: get file path for a given image label ---
function getImagePathForLabel(label, base, outputDir, mergeSavePath, noC1Path, maxChannel) {
    label = trim(label);
    if (label == "Merged (C1)" || label == "Merged") {
        return mergeSavePath;
    } else if (label == "C1") {
        return outputDir + base + "__C1.jpg";
    } else if (label == "No C1") {
        return noC1Path;
    } else if (label == "C1+C2") {
        return outputDir + base + "__C1_C2.jpg";
    } else if (label == "C1+C3") {
        return outputDir + base + "__C1_C3.jpg";
    } else if (label == "C1+C4") {
        return outputDir + base + "__C1_C4.jpg";
    } else if (label == "C2") {
        return outputDir + base + "__C2.jpg";
    } else if (label == "C3") {
        return outputDir + base + "__C3.jpg";
    } else if (label == "C4") {
        return outputDir + base + "__C4.jpg";
    } else if (label == "C2+C3") {
        return outputDir + base + "__C2_C3.jpg";
    } else if (label == "C2+C4") {
        return outputDir + base + "__C2_C4.jpg";
    } else if (label == "C3+C4") {
        return outputDir + base + "__C3_C4.jpg";
    } else if (lengthOf(label) > 0 && substring(label, 0, 1) == "C" && indexOf(label, "+") >= 0) {
        suffix = convertPlusLabelToUnderscore(label);
        return outputDir + base + "__" + suffix + ".jpg";
    }
    return "";
}

function generateThreeChannelComposites(channelIndices, count, base) {
    for (i = 0; i <= count - 3; i++) {
        for (j = i + 1; j <= count - 2; j++) {
            for (k = j + 1; k <= count - 1; k++) {
                chA = channelIndices[i];
                chB = channelIndices[j];
                chC = channelIndices[k];
                if (chA == 0 || chB == 0 || chC == 0) continue;

                comboIndices = "" + chA + "," + chB + "," + chC;
                comboLabelUnderscore = getComboLabel(chA, chB, chC, "_");
                comboLabelPlus = getComboLabel(chA, chB, chC, "+");
                labelSuffix = "__" + comboLabelUnderscore;
                description = "3-channel composite " + comboLabelPlus;
                comboPath = createComposite(comboIndices, labelSuffix, true, description);
                if (comboPath != "") {
                    registerPanelOption(comboLabelPlus, comboPath);
                }
            }
        }
    }
}

function getComboLabel(chA, chB, chC, delimiter) {
    label = "C" + chA;
    label = label + delimiter + "C" + chB;
    label = label + delimiter + "C" + chC;
    return label;
}

function convertPlusLabelToUnderscore(label) {
    parts = split(label, "+");
    if (parts.length == 0) return label;
    suffix = "";
    for (i = 0; i < parts.length; i++) {
        token = trim(parts[i]);
        if (token == "") continue;
        if (suffix == "") suffix = token;
        else suffix = suffix + "_" + token;
    }
    return suffix;
}


