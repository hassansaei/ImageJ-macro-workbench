// ------------------------------------------------------------
// Author: Hassan Saei
// Email: hassan.saeiahan@gmail.com
// Affiliation: Imagine Institute of Genetic Diseases, U1163 INSERM
//
// Description:
// This ImageJ/Fiji macro batch-processes ND2, CZI, and TIFF microscopy files to produce:
//  - A DAPI-only image with a scale bar.
//  - DAPI + up to three other channels (C2–C4) composites, each saved.
//  - A final merged image (DAPI plus up to C2–C4), saved.
//  - A panel combining DAPI+channel composites with user-selectable larger image
//    (smaller images stacked on left, selected larger image on right), with white borders.
// Options:
//  - File format support: ND2 (Nikon), CZI (Zeiss), and TIFF files
//  - Optional Enhance Contrast (saturation percent) for autoscaling
//  - Optional fixed display range via setMinAndMax (global or per-channel for C1-C4)
//    with optional Apply LUT to bake scaling into pixels
//  - Per-channel intensity control: independent min/max ranges for C1 (DAPI), C2, C3, and C4
//  - Scale bar: configurable length (µm), font size, and thickness (px)
//  - User-defined color assignment for each channel (C1/DAPI, C2, C3, C4):
//    choose from Red, Green, Blue, Gray, Cyan, Magenta, Yellow, or None
//  - Panel layout: select which image appears larger (Merged, DAPI+C2, DAPI+C3, or DAPI+C4)
//  - Automatic logging: processing details saved to ImageAnalyzer_Log.txt
// ------------------------------------------------------------

macro "Image Analyzer → DAPI and Multi-Channel Processing — ALL FILES (v1)" {
    // 1) Pick folder
    folder = getDirectory("Choose a folder with ND2, CZI, or TIFF files");

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
    // Optional per-channel fixed ranges for C1–C4
    Dialog.addCheckbox("Use per-channel fixed ranges for C1–C4", false);
    Dialog.addNumber("C1 (DAPI) min intensity", 50);
    Dialog.addNumber("C1 (DAPI) max intensity", 3000);
    Dialog.addNumber("C2 min intensity", 50);
    Dialog.addNumber("C2 max intensity", 3000);
    Dialog.addNumber("C3 min intensity", 50);
    Dialog.addNumber("C3 max intensity", 3000);
    Dialog.addNumber("C4 min intensity", 50);
    Dialog.addNumber("C4 max intensity", 3000);
    // Channel Color Selection
    Dialog.addMessage("--- Channel Color Assignment ---");
    Dialog.addChoice("C1 (DAPI) color:", newArray("Blue", "Red", "Green", "Gray", "Cyan", "Magenta", "Yellow", "None"), "Blue");
    Dialog.addChoice("C2 color:", newArray("Green", "Red", "Blue", "Gray", "Cyan", "Magenta", "Yellow", "None"), "Green");
    Dialog.addChoice("C3 color:", newArray("Red", "Green", "Blue", "Gray", "Cyan", "Magenta", "Yellow", "None"), "Red");
    Dialog.addChoice("C4 color:", newArray("Gray", "Red", "Green", "Blue", "Cyan", "Magenta", "Yellow", "None"), "Gray");
    Dialog.addMessage("--- Panel Layout ---");
    Dialog.addChoice("Larger panel image:", newArray("Merged", "DAPI+C2", "DAPI+C3", "DAPI+C4"), "Merged");
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
    
    // Debug: Print selected colors
    print("Selected colors - C1: " + c1Color + ", C2: " + c2Color + ", C3: " + c3Color + ", C4: " + c4Color);

    timestamp = getTimestamp();
    logFile = folder + "ImageAnalyzer_Log.txt";
    logText = "Image Analyzer Log\n";
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
    logText = logText + "C1 (DAPI) min/max: " + c1Min + " / " + c1Max + "\n";
    logText = logText + "C2 min/max: " + c2Min + " / " + c2Max + "\n";
    logText = logText + "C3 min/max: " + c3Min + " / " + c3Max + "\n";
    logText = logText + "C4 min/max: " + c4Min + " / " + c4Max + "\n";
    logText = logText + "Channel colors - C1: " + c1Color + ", C2: " + c2Color + ", C3: " + c3Color + ", C4: " + c4Color + "\n";
    logText = logText + "Panel larger image: " + panelLargerImage + "\n";
    logText = logText + "\nProcessed files:\n";
    processedCount = 0;

    // 4) Process all files
    files = getFileList(folder);
    setBatchMode(true);

    for (i=0; i<files.length; i++) {
        mergeSavePath = "";
        dapiAlonePath = "";
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

        // Make clean 8-bit DAPI temp and save DAPI-alone ----------
        dapiSrc = "C1-Work_Stack";
        if (!isOpen(dapiSrc)) {
            print("No C1 (DAPI) found; skipping file.");
            logText = logText + "    Skipped: no C1 (DAPI) channel detected.\n";
            run("Close All");
            safeClose(orig);
            continue;
        }
        // clean 8-bit DAPI temp for merging
        selectWindow(dapiSrc);
        if (!useFixed && !useFixedPer && doEnhance) {
            run("Enhance Contrast", "saturated=" + satPct);
        }
        run("Duplicate...", "title=__TMP_DAPI");
        selectWindow("__TMP_DAPI"); 
        run("8-bit");
        run("Grays");  // Ensure grayscale LUT

        // DAPI alone (with scalebar)
        run("Duplicate...", "title=__TMP_DAPI_SAVE");
        selectWindow("__TMP_DAPI_SAVE");
        run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
        dapiAlonePath = folder + base + "__DAPI.jpg";
        saveAs("Jpeg", dapiAlonePath);
        logText = logText + "    Saved DAPI image: " + dapiAlonePath + "\n";
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
            selectWindow("__TMP_CH"); 
            run("8-bit");
            run("Grays");  // Ensure grayscale LUT

            chColor = getChannelColor(c, c2Color, c3Color, c4Color);
            mergeSpec = getTwoChannelMergeSpecSimple(c, "__TMP_DAPI", "__TMP_CH", c1Color, chColor);
            print("Merge spec for DAPI+C" + c + ": " + mergeSpec);
            print("DAPI color: " + c1Color + ", Channel " + c + " color: " + chColor);
            run("Merge Channels...", mergeSpec + " create keep");
            run("RGB Color");
            run("Scale Bar...", "width=" + sbLen + " height=" + sbThick + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
            saveAs("Jpeg", folder + base + "__DAPI_plus_C" + c + ".jpg");
            logText = logText + "    Saved DAPI + C" + c + ": " + folder + base + "__DAPI_plus_C" + c + ".jpg\n";
            close(); // merged RGB
            // Cleanup temp channels
            cleanupTempWindows("__TMP_CH,__TMP_CH_R,__TMP_CH_G,__TMP_CH_B,__TMP_DAPI_R,__TMP_DAPI_G,__TMP_DAPI_B");
        }

        // Final merged image: DAPI + up to 3 other channels
        if (isOpen("__TMP_DAPI")) {
            // Track which images are assigned to each RGB channel (using comma-separated strings)
            c1List = "";  // Red channel images (comma-separated)
            c2List = "";  // Green channel images (comma-separated)
            c3List = "";  // Blue channel images (comma-separated)
            c4List = "";  // Gray channel images (comma-separated)
            
            // First, assign DAPI channel
            if (c1Color == "Red") {
                if (c1List == "") c1List = "__TMP_DAPI"; else c1List = c1List + ",__TMP_DAPI";
            } else if (c1Color == "Green") {
                if (c2List == "") c2List = "__TMP_DAPI"; else c2List = c2List + ",__TMP_DAPI";
            } else if (c1Color == "Blue") {
                if (c3List == "") c3List = "__TMP_DAPI"; else c3List = c3List + ",__TMP_DAPI";
            } else if (c1Color == "Gray") {
                if (c4List == "") c4List = "__TMP_DAPI"; else c4List = c4List + ",__TMP_DAPI";
            } else if (c1Color == "Cyan") {
                // Green + Blue - duplicate needed
                selectWindow("__TMP_DAPI");
                run("Duplicate...", "title=__TMP_DAPI_G");
                selectWindow("__TMP_DAPI_G");
                run("Grays");  // Ensure grayscale
                if (c2List == "") c2List = "__TMP_DAPI_G"; else c2List = c2List + ",__TMP_DAPI_G";
                selectWindow("__TMP_DAPI");
                run("Duplicate...", "title=__TMP_DAPI_B");
                selectWindow("__TMP_DAPI_B");
                run("Grays");  // Ensure grayscale
                if (c3List == "") c3List = "__TMP_DAPI_B"; else c3List = c3List + ",__TMP_DAPI_B";
            } else if (c1Color == "Magenta") {
                // Red + Blue - duplicate needed
                selectWindow("__TMP_DAPI");
                run("Duplicate...", "title=__TMP_DAPI_R");
                selectWindow("__TMP_DAPI_R");
                run("Grays");  // Ensure grayscale
                if (c1List == "") c1List = "__TMP_DAPI_R"; else c1List = c1List + ",__TMP_DAPI_R";
                selectWindow("__TMP_DAPI");
                run("Duplicate...", "title=__TMP_DAPI_B");
                selectWindow("__TMP_DAPI_B");
                run("Grays");  // Ensure grayscale
                if (c3List == "") c3List = "__TMP_DAPI_B"; else c3List = c3List + ",__TMP_DAPI_B";
            } else if (c1Color == "Yellow") {
                // Red + Green - duplicate needed
                selectWindow("__TMP_DAPI");
                run("Duplicate...", "title=__TMP_DAPI_R");
                selectWindow("__TMP_DAPI_R");
                run("Grays");  // Ensure grayscale
                if (c1List == "") c1List = "__TMP_DAPI_R"; else c1List = c1List + ",__TMP_DAPI_R";
                selectWindow("__TMP_DAPI");
                run("Duplicate...", "title=__TMP_DAPI_G");
                selectWindow("__TMP_DAPI_G");
                run("Grays");  // Ensure grayscale
                if (c2List == "") c2List = "__TMP_DAPI_G"; else c2List = c2List + ",__TMP_DAPI_G";
            }
            
            // Then add other channels, combining if conflicts occur
            for (k = 2; k <= maxChannel; k++) {
                kname = "C" + k + "-Work_Stack";
                if (!isOpen(kname)) continue;
                selectWindow(kname);
                if (!useFixed && !useFixedPer && doEnhance) {
                    run("Enhance Contrast", "saturated=" + satPct);
                }
                tmpName = "__TMP_C" + k;
                run("Duplicate...", "title=" + tmpName);
                selectWindow(tmpName); 
                run("8-bit");
                run("Grays");  // Ensure grayscale LUT
                
                chColor = getChannelColor(k, c2Color, c3Color, c4Color);
                if (chColor == "Red") {
                    if (c1List == "") c1List = tmpName; else c1List = c1List + "," + tmpName;
                } else if (chColor == "Green") {
                    if (c2List == "") c2List = tmpName; else c2List = c2List + "," + tmpName;
                } else if (chColor == "Blue") {
                    if (c3List == "") c3List = tmpName; else c3List = c3List + "," + tmpName;
                } else if (chColor == "Gray") {
                    if (c4List == "") c4List = tmpName; else c4List = c4List + "," + tmpName;
                } else if (chColor == "Cyan") {
                    // Green + Blue - duplicate needed
                    selectWindow(tmpName);
                    run("Duplicate...", "title=" + tmpName + "_G");
                    selectWindow(tmpName + "_G");
                    run("Grays");  // Ensure grayscale
                    if (c2List == "") c2List = tmpName + "_G"; else c2List = c2List + "," + tmpName + "_G";
                    selectWindow(tmpName);
                    run("Duplicate...", "title=" + tmpName + "_B");
                    selectWindow(tmpName + "_B");
                    run("Grays");  // Ensure grayscale
                    if (c3List == "") c3List = tmpName + "_B"; else c3List = c3List + "," + tmpName + "_B";
                } else if (chColor == "Magenta") {
                    // Red + Blue - duplicate needed
                    selectWindow(tmpName);
                    run("Duplicate...", "title=" + tmpName + "_R");
                    selectWindow(tmpName + "_R");
                    run("Grays");  // Ensure grayscale
                    if (c1List == "") c1List = tmpName + "_R"; else c1List = c1List + "," + tmpName + "_R";
                    selectWindow(tmpName);
                    run("Duplicate...", "title=" + tmpName + "_B");
                    selectWindow(tmpName + "_B");
                    run("Grays");  // Ensure grayscale
                    if (c3List == "") c3List = tmpName + "_B"; else c3List = c3List + "," + tmpName + "_B";
                } else if (chColor == "Yellow") {
                    // Red + Green - duplicate needed
                    selectWindow(tmpName);
                    run("Duplicate...", "title=" + tmpName + "_R");
                    selectWindow(tmpName + "_R");
                    run("Grays");  // Ensure grayscale
                    if (c1List == "") c1List = tmpName + "_R"; else c1List = c1List + "," + tmpName + "_R";
                    selectWindow(tmpName);
                    run("Duplicate...", "title=" + tmpName + "_G");
                    selectWindow(tmpName + "_G");
                    run("Grays");  // Ensure grayscale
                    if (c2List == "") c2List = tmpName + "_G"; else c2List = c2List + "," + tmpName + "_G";
                }
            }
            
            // Build merge arguments by combining images for each RGB channel
            mergeArgs = "";
            
            // Process Red channel (c1)
            if (c1List != "") {
                c1Parts = split(c1List, ",");
                if (c1Parts.length == 1) {
                    mergeArgs = mergeArgs + "c1=[" + c1Parts[0] + "] ";
                } else {
                    // Combine multiple images using Image Calculator
                    combinedName = "__TMP_RED_COMBINED";
                    selectWindow(c1Parts[0]);
                    run("Duplicate...", "title=" + combinedName);
                    for (j = 1; j < c1Parts.length; j++) {
                        run("Image Calculator...", "image1=[" + combinedName + "] operation=Add image2=[" + c1Parts[j] + "] create 32-bit");
                        safeClose(combinedName);
                        selectWindow("Result of " + combinedName);
                        run("Rename...", "title=" + combinedName);
                    }
                    // Convert back to 8-bit for merging
                    selectWindow(combinedName);
                    run("8-bit");
                    run("Grays");  // Ensure grayscale LUT
                    mergeArgs = mergeArgs + "c1=[" + combinedName + "] ";
                }
            }
            
            // Process Green channel (c2)
            if (c2List != "") {
                c2Parts = split(c2List, ",");
                if (c2Parts.length == 1) {
                    mergeArgs = mergeArgs + "c2=[" + c2Parts[0] + "] ";
                } else {
                    // Combine multiple images using Image Calculator
                    combinedName = "__TMP_GREEN_COMBINED";
                    selectWindow(c2Parts[0]);
                    run("Duplicate...", "title=" + combinedName);
                    for (j = 1; j < c2Parts.length; j++) {
                        run("Image Calculator...", "image1=[" + combinedName + "] operation=Add image2=[" + c2Parts[j] + "] create 32-bit");
                        safeClose(combinedName);
                        selectWindow("Result of " + combinedName);
                        run("Rename...", "title=" + combinedName);
                    }
                    // Convert back to 8-bit for merging
                    selectWindow(combinedName);
                    run("8-bit");
                    run("Grays");  // Ensure grayscale LUT
                    mergeArgs = mergeArgs + "c2=[" + combinedName + "] ";
                }
            }
            
            // Process Blue channel (c3)
            if (c3List != "") {
                c3Parts = split(c3List, ",");
                if (c3Parts.length == 1) {
                    mergeArgs = mergeArgs + "c3=[" + c3Parts[0] + "] ";
                } else {
                    // Combine multiple images using Image Calculator
                    combinedName = "__TMP_BLUE_COMBINED";
                    selectWindow(c3Parts[0]);
                    run("Duplicate...", "title=" + combinedName);
                    for (j = 1; j < c3Parts.length; j++) {
                        run("Image Calculator...", "image1=[" + combinedName + "] operation=Add image2=[" + c3Parts[j] + "] create 32-bit");
                        safeClose(combinedName);
                        selectWindow("Result of " + combinedName);
                        run("Rename...", "title=" + combinedName);
                    }
                    // Convert back to 8-bit for merging
                    selectWindow(combinedName);
                    run("8-bit");
                    run("Grays");  // Ensure grayscale LUT
                    mergeArgs = mergeArgs + "c3=[" + combinedName + "] ";
                }
            }
            
            // Process Gray channel (c4)
            if (c4List != "") {
                c4Parts = split(c4List, ",");
                if (c4Parts.length == 1) {
                    mergeArgs = mergeArgs + "c4=[" + c4Parts[0] + "] ";
                } else {
                    // Combine multiple images using Image Calculator
                    combinedName = "__TMP_GRAY_COMBINED";
                    selectWindow(c4Parts[0]);
                    run("Duplicate...", "title=" + combinedName);
                    for (j = 1; j < c4Parts.length; j++) {
                        run("Image Calculator...", "image1=[" + combinedName + "] operation=Add image2=[" + c4Parts[j] + "] create 32-bit");
                        safeClose(combinedName);
                        selectWindow("Result of " + combinedName);
                        run("Rename...", "title=" + combinedName);
                    }
                    // Convert back to 8-bit for merging
                    selectWindow(combinedName);
                    run("8-bit");
                    run("Grays");  // Ensure grayscale LUT
                    mergeArgs = mergeArgs + "c4=[" + combinedName + "] ";
                }
            }
            
            print("Final merge args: " + mergeArgs);
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
            cleanupTempWindows("__TMP_DAPI,__TMP_DAPI_R,__TMP_DAPI_G,__TMP_DAPI_B,__TMP_RED_COMBINED,__TMP_GREEN_COMBINED,__TMP_BLUE_COMBINED,__TMP_GRAY_COMBINED");
            for (k=2; k<=maxChannel; k++) {
                tname = "__TMP_C" + k;
                cleanupTempWindows(tname + "," + tname + "_R," + tname + "_G," + tname + "_B");
            }
        }

        // Create panel with user-selected larger image
        // Determine which image should be larger and collect smaller images
        largerImagePath = "";
        smallerImagePaths = newArray("");
        smallerCount = 0;
        
        // Determine the larger image path based on user choice
        if (panelLargerImage == "Merged" && mergeSavePath != "") {
            largerImagePath = mergeSavePath;
        } else if (panelLargerImage == "DAPI+C2") {
            largerImagePath = folder + base + "__DAPI_plus_C2.jpg";
        } else if (panelLargerImage == "DAPI+C3") {
            largerImagePath = folder + base + "__DAPI_plus_C3.jpg";
        } else if (panelLargerImage == "DAPI+C4") {
            largerImagePath = folder + base + "__DAPI_plus_C4.jpg";
        }
        
        // Collect smaller images (all available DAPI+channel composites except the larger one)
        for (pc=2; pc<=maxChannel; pc++) {
            if (smallerCount >= 3) break;
            ppath = folder + base + "__DAPI_plus_C" + pc + ".jpg";
            if (File.exists(ppath) && ppath != largerImagePath) {
                smallerImagePaths[smallerCount] = ppath;
                smallerCount++;
            }
        }
        if (mergeSavePath != "" && mergeSavePath != largerImagePath) {
            if (smallerCount < 3) {
                smallerImagePaths[smallerCount] = mergeSavePath;
                smallerCount++;
            }
        }
        
        // Create panel if we have at least one smaller image and the larger image exists
        if (smallerCount > 0 && largerImagePath != "" && File.exists(largerImagePath)) {
            // Get dimensions of first smaller image
            open(smallerImagePaths[0]);
            sW = getWidth(); sH = getHeight();
            close();
            
            // Calculate panel height based on number of smaller images
            panelH = smallerCount * sH;
            
            // Prepare larger image resized to panel height
            open(largerImagePath);
            run("Size...", "height=" + panelH + " constrain average interpolation=Bilinear");
            lW = getWidth();
            largerTitle = getTitle();
            
            // Create panel canvas
            newImage("PANEL_"+base, "RGB black", sW + lW, panelH, 1);
            panelTitle = getTitle();
            
            // Prepare border style (thick white lines)
            setForegroundColor(255,255,255);
            borderWidth = 20;
            
            // Paste smaller images stacked on left
            yoff = 0;
            for (si=0; si<smallerCount; si++) {
                if (!File.exists(smallerImagePaths[si])) continue;
                open(smallerImagePaths[si]);
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
            }
            
            // Paste larger image on right
            selectWindow(largerTitle);
            run("Copy");
            selectWindow(panelTitle);
            makeRectangle(sW, 0, lW, panelH);
            run("Paste");
            // Draw larger image border
            drawThickBorder(sW, 0, lW, panelH, borderWidth);
            // Draw outer border
            drawThickBorder(0, 0, sW + lW, panelH, borderWidth);
            
            // Save panel
            saveAs("Jpeg", folder + base + "__PANEL.jpg");
            logText = logText + "    Saved panel: " + folder + base + "__PANEL.jpg (larger: " + panelLargerImage + ")\n";
            
            // Close temp panel and larger image
            selectWindow(panelTitle); close();
            selectWindow(largerTitle); close();
        }

        // Close everything from this file before next
        run("Close All");
        safeClose(orig);

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

// --- helper: get color for a specific channel index ---
function getChannelColor(channelIndex, c2Color, c3Color, c4Color) {
    if (channelIndex == 2) return c2Color;
    if (channelIndex == 3) return c3Color;
    if (channelIndex == 4) return c4Color;
    return "None";
}

// --- helper: map color name to ImageJ merge channel (c1=red, c2=green, c3=blue, c4=gray) ---
function getColorChannelMapping(colorName) {
    if (colorName == "Red") return "c1=";
    if (colorName == "Green") return "c2=";
    if (colorName == "Blue") return "c3=";
    if (colorName == "Gray") return "c4=";
    if (colorName == "Cyan") return "c2= c3=";  // Green + Blue
    if (colorName == "Magenta") return "c1= c3=";  // Red + Blue
    if (colorName == "Yellow") return "c1= c2=";  // Red + Green
    if (colorName == "None") return "";
    return "";  // Default: no mapping
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

// --- helper: merge spec for DAPI + single channel using user-defined colors ---
function getTwoChannelMergeSpecSimple(channelIndex, dapiTitle, channelTitle, dapiColor, channelColor) {
    // Build merge spec based on user-defined colors
    // For composite colors, duplicate images are needed
    mergeSpec = "";
    dapiAssigned = false;
    chAssigned = false;
    
    // Map DAPI to RGB channels (c1=red, c2=green, c3=blue, c4=gray)
    if (dapiColor == "Red") {
        mergeSpec = mergeSpec + "c1=[" + dapiTitle + "] ";
        dapiAssigned = true;
    } else if (dapiColor == "Green") {
        mergeSpec = mergeSpec + "c2=[" + dapiTitle + "] ";
        dapiAssigned = true;
    } else if (dapiColor == "Blue") {
        mergeSpec = mergeSpec + "c3=[" + dapiTitle + "] ";
        dapiAssigned = true;
    } else if (dapiColor == "Gray") {
        mergeSpec = mergeSpec + "c4=[" + dapiTitle + "] ";
        dapiAssigned = true;
    } else if (dapiColor == "Cyan") {
        // Green + Blue - duplicate needed
        selectWindow(dapiTitle);
        run("Duplicate...", "title=__TMP_DAPI_G");
        selectWindow("__TMP_DAPI_G");
        run("Grays");  // Ensure grayscale
        selectWindow(dapiTitle);
        run("Duplicate...", "title=__TMP_DAPI_B");
        selectWindow("__TMP_DAPI_B");
        run("Grays");  // Ensure grayscale
        mergeSpec = mergeSpec + "c2=[__TMP_DAPI_G] c3=[__TMP_DAPI_B] ";
        dapiAssigned = true;
    } else if (dapiColor == "Magenta") {
        // Red + Blue - duplicate needed
        selectWindow(dapiTitle);
        run("Duplicate...", "title=__TMP_DAPI_R");
        selectWindow("__TMP_DAPI_R");
        run("Grays");  // Ensure grayscale
        selectWindow(dapiTitle);
        run("Duplicate...", "title=__TMP_DAPI_B");
        selectWindow("__TMP_DAPI_B");
        run("Grays");  // Ensure grayscale
        mergeSpec = mergeSpec + "c1=[__TMP_DAPI_R] c3=[__TMP_DAPI_B] ";
        dapiAssigned = true;
    } else if (dapiColor == "Yellow") {
        // Red + Green - duplicate needed
        selectWindow(dapiTitle);
        run("Duplicate...", "title=__TMP_DAPI_R");
        selectWindow("__TMP_DAPI_R");
        run("Grays");  // Ensure grayscale
        selectWindow(dapiTitle);
        run("Duplicate...", "title=__TMP_DAPI_G");
        selectWindow("__TMP_DAPI_G");
        run("Grays");  // Ensure grayscale
        mergeSpec = mergeSpec + "c1=[__TMP_DAPI_R] c2=[__TMP_DAPI_G] ";
        dapiAssigned = true;
    }
    
    // Map channel to RGB channels (avoid conflicts)
    if (channelColor == "Red" && indexOf(mergeSpec, "c1=") < 0) {
        mergeSpec = mergeSpec + "c1=[" + channelTitle + "] ";
        chAssigned = true;
    } else if (channelColor == "Green" && indexOf(mergeSpec, "c2=") < 0) {
        mergeSpec = mergeSpec + "c2=[" + channelTitle + "] ";
        chAssigned = true;
    } else if (channelColor == "Blue" && indexOf(mergeSpec, "c3=") < 0) {
        mergeSpec = mergeSpec + "c3=[" + channelTitle + "] ";
        chAssigned = true;
    } else if (channelColor == "Gray" && indexOf(mergeSpec, "c4=") < 0) {
        mergeSpec = mergeSpec + "c4=[" + channelTitle + "] ";
        chAssigned = true;
    } else if (channelColor == "Cyan") {
        // Green + Blue - duplicate needed
        selectWindow(channelTitle);
        run("Duplicate...", "title=__TMP_CH_G");
        selectWindow("__TMP_CH_G");
        run("Grays");  // Ensure grayscale
        selectWindow(channelTitle);
        run("Duplicate...", "title=__TMP_CH_B");
        selectWindow("__TMP_CH_B");
        run("Grays");  // Ensure grayscale
        if (indexOf(mergeSpec, "c2=") < 0) mergeSpec = mergeSpec + "c2=[__TMP_CH_G] ";
        if (indexOf(mergeSpec, "c3=") < 0) mergeSpec = mergeSpec + "c3=[__TMP_CH_B] ";
        chAssigned = true;
    } else if (channelColor == "Magenta") {
        // Red + Blue - duplicate needed
        selectWindow(channelTitle);
        run("Duplicate...", "title=__TMP_CH_R");
        selectWindow("__TMP_CH_R");
        run("Grays");  // Ensure grayscale
        selectWindow(channelTitle);
        run("Duplicate...", "title=__TMP_CH_B");
        selectWindow("__TMP_CH_B");
        run("Grays");  // Ensure grayscale
        if (indexOf(mergeSpec, "c1=") < 0) mergeSpec = mergeSpec + "c1=[__TMP_CH_R] ";
        if (indexOf(mergeSpec, "c3=") < 0) mergeSpec = mergeSpec + "c3=[__TMP_CH_B] ";
        chAssigned = true;
    } else if (channelColor == "Yellow") {
        // Red + Green - duplicate needed
        selectWindow(channelTitle);
        run("Duplicate...", "title=__TMP_CH_R");
        selectWindow("__TMP_CH_R");
        run("Grays");  // Ensure grayscale
        selectWindow(channelTitle);
        run("Duplicate...", "title=__TMP_CH_G");
        selectWindow("__TMP_CH_G");
        run("Grays");  // Ensure grayscale
        if (indexOf(mergeSpec, "c1=") < 0) mergeSpec = mergeSpec + "c1=[__TMP_CH_R] ";
        if (indexOf(mergeSpec, "c2=") < 0) mergeSpec = mergeSpec + "c2=[__TMP_CH_G] ";
        chAssigned = true;
    }
    
    return mergeSpec;
}


