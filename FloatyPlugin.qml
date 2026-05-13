import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import qs.Modals.Common
import qs.Modals.FileBrowser

PluginComponent {
    id: root

    // Simple count is enough and more reliable for QML property binding
    property int activeWindowCount: 0
    property var openWindows: []

    readonly property bool showBarPill: root.pluginData.showBarPill ?? true
    readonly property bool showUserGuide: root.pluginData.showUserGuide ?? true

    // Bar Pill - Standardized with QR Generator Style
    horizontalBarPill: showBarPill ? horizontalPillComp : null
    verticalBarPill: showBarPill ? verticalPillComp : null

    Component {
        id: horizontalPillComp
        Item {
            implicitWidth: horizontalRow.implicitWidth
            implicitHeight: 24 // Standard bar height container
            anchors.verticalCenter: parent.verticalCenter
            
            property bool draggingOver: false

            Row {
                id: horizontalRow
                spacing: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter
                scale: draggingOver ? 1.2 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                DankIcon {
                    name: "cloud"
                    size: Theme.iconSizeSmall
                    color: draggingOver ? Theme.primary : (root.activeWindowCount > 0 ? Theme.primary : Theme.surfaceText)
                    anchors.verticalCenter: parent.verticalCenter
                }
                StyledText {
                    text: root.activeWindowCount
                    visible: root.activeWindowCount > 0
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            DropArea {
                anchors.fill: parent
                onEntered: draggingOver = true
                onExited: draggingOver = false
                onDropped: (drop) => {
                    draggingOver = false;
                    if (drop.hasUrls) {
                        drop.urls.forEach(url => root.spawnWindow(url.toString()));
                    } else if (drop.hasText) {
                        root.spawnWindow(drop.text);
                    }
                }
            }
        }
    }

    Component {
        id: verticalPillComp
        Item {
            implicitWidth: 24
            implicitHeight: verticalCol.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter

            property bool draggingOver: false

            Column {
                id: verticalCol
                spacing: 2
                anchors.horizontalCenter: parent.horizontalCenter
                scale: draggingOver ? 1.2 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                DankIcon {
                    name: "cloud"
                    size: Theme.iconSizeSmall
                    color: draggingOver ? Theme.primary : (root.activeWindowCount > 0 ? Theme.primary : Theme.surfaceText)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                StyledText {
                    text: root.activeWindowCount
                    visible: root.activeWindowCount > 0
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall - 2
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            DropArea {
                anchors.fill: parent
                onEntered: draggingOver = true
                onExited: draggingOver = false
                onDropped: (drop) => {
                    draggingOver = false;
                    if (drop.hasUrls) {
                        drop.urls.forEach(url => root.spawnWindow(url.toString()));
                    } else if (drop.hasText) {
                        root.spawnWindow(drop.text);
                    }
                }
            }
        }
    }

    pillRightClickAction: function() {
        root.smartPaste();
    }

    FileBrowserModal {
        id: fileBrowserModal
        browserTitle: "Select Image or PDF"
        browserIcon: "image"
        fileExtensions: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.svg", "*.pdf"]
        onFileSelected: path => {
            root.spawnWindow("file://" + path);
            close();
        }
    }

    InputModal {
        id: inputModal
    }

    IpcHandler {
        target: "floaty"

        function floatFromClipboard(): string {
            root.floatFromClipboard();
            return "SUCCESS";
        }

        function selectFileAndFloat(): string {
            root.selectFileAndFloat();
            return "SUCCESS";
        }

        function closeAllWindows(): string {
            root.closeAllWindows();
            return "SUCCESS";
        }

        function floatFromUrl(url: string): string {
            root.spawnWindow(url);
            return "SUCCESS";
        }

        function toggleMinimizeAll(): string {
            root.toggleMinimizeAll();
            return "SUCCESS";
        }

        function minimizeAll(): string {
            root.minimizeAll();
            return "SUCCESS";
        }

        function expandAll(): string {
            root.expandAll();
            return "SUCCESS";
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            width: 280
            headerText: "Floaty"
            detailsText: "Reference images on top"
            showCloseButton: true
            
            Item {
                width: parent.width
                implicitHeight: mainCol.implicitHeight

                DropArea {
                    anchors.fill: parent
                    onDropped: (drop) => {
                        if (drop.hasUrls) {
                            drop.urls.forEach(url => root.spawnWindow(url.toString()));
                        } else if (drop.hasText) {
                            root.spawnWindow(drop.text);
                        }
                        root.closePopout();
                    }
                }

                Column {
                    id: mainCol
                    width: parent.width
                    spacing: Theme.spacingM
                    
                    Row {
                        width: parent.width
                        spacing: Theme.spacingS
                        
                        DankButton {
                            text: "Clipboard"
                            width: (parent.width - Theme.spacingS) / 2
                            iconName: "content_paste"
                            backgroundColor: Theme.primaryContainer
                            textColor: Theme.primary
                            onClicked: {
                                root.floatFromClipboard();
                                root.closePopout();
                            }
                        }
                        
                        DankButton {
                            text: "Select File"
                            width: (parent.width - Theme.spacingS) / 2
                            iconName: "folder_open"
                            backgroundColor: Theme.surfaceContainerHighest
                            textColor: Theme.surfaceText
                            onClicked: {
                                root.selectFileAndFloat();
                                root.closePopout();
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: root.activeWindowCount > 0

                        DankButton {
                            text: "Toggle All"
                            width: (parent.width - Theme.spacingS) / 2
                            iconName: "unfold_more"
                            backgroundColor: Theme.secondaryContainer
                            textColor: Theme.secondary
                            onClicked: {
                                root.toggleMinimizeAll();
                                root.closePopout();
                            }
                        }

                        DankButton {
                            text: "Close All"
                            width: (parent.width - Theme.spacingS) / 2
                            iconName: "delete_sweep"
                            backgroundColor: Theme.errorContainer
                            textColor: Theme.error
                            onClicked: {
                                root.closeAllWindows();
                                root.closePopout();
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS
                        
                        StyledText {
                            text: "Float from Link or Path"
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            color: Theme.surfaceVariantText
                        }
                        
                        Row {
                            width: parent.width
                            spacing: Theme.spacingS
                            
                            DankTextField {
                                id: urlInput
                                width: parent.width - 44 - Theme.spacingS
                                placeholderText: "https://... or /path/..."
                                onAccepted: {
                                    if (text !== "") {
                                        root.spawnWindow(text);
                                        root.closePopout();
                                    }
                                }
                            }
                            
                            DankButton {
                                width: 44
                                iconName: "add"
                                backgroundColor: Theme.primaryContainer
                                textColor: Theme.primary
                                onClicked: {
                                    if (urlInput.text !== "") {
                                        root.spawnWindow(urlInput.text);
                                        root.closePopout();
                                    }
                                }
                            }
                        }
                    }

                    StyledRect {
                        width: parent.width
                        height: guideCol.implicitHeight + Theme.spacingL
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHighest
                        visible: root.showUserGuide

                        Column {
                            id: guideCol
                            anchors.centerIn: parent
                            width: parent.width - Theme.spacingM * 2
                            spacing: Theme.spacingS

                            StyledText {
                                text: "User Guide"
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: true
                                color: Theme.primary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Column {
                                width: parent.width
                                spacing: 8

                                Row {
                                    spacing: Theme.spacingS
                                    DankIcon { name: "open_with"; size: 14; color: Theme.surfaceVariantText }
                                    StyledText { text: "Left Click + Drag: Move window"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                                }
                                Row {
                                    spacing: Theme.spacingS
                                    DankIcon { name: "aspect_ratio"; size: 14; color: Theme.surfaceVariantText }
                                    StyledText { text: "Scroll Wheel: Resize image"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                                }
                                Row {
                                    spacing: Theme.spacingS
                                    DankIcon { name: "minimize"; size: 14; color: Theme.surfaceVariantText }
                                    StyledText { text: "Right Click: Toggle minimize"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                                }
                                Row {
                                    spacing: Theme.spacingS
                                    DankIcon { name: "close"; size: 14; color: Theme.surfaceVariantText }
                                    StyledText { text: "Middle Click: Close window"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                                }
                                Row {
                                    spacing: Theme.spacingS
                                    DankIcon { name: "add_photo_alternate"; size: 14; color: Theme.surfaceVariantText }
                                    StyledText { text: "Drop image/link: Quick float"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                                }
                                Row {
                                    spacing: Theme.spacingS
                                    DankIcon { name: "bolt"; size: 14; color: Theme.surfaceVariantText }
                                    StyledText { text: "Right Click Icon: Fast paste image/link"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                                }
                                Row {
                                    spacing: Theme.spacingS
                                    DankIcon { name: "picture_as_pdf"; size: 14; color: Theme.surfaceVariantText }
                                    StyledText { text: "PDF: Enter pages like 1, 1-3, or 1 3 5"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function floatFromClipboard() {
        root.smartPaste();
    }

    function smartPaste() {
        const timestamp = Date.now();
        const tempPath = "/tmp/dms_floaty_" + timestamp + ".png";
        
        // Smarter shell command to detect image or text (URL/Path)
        const checkCmd = `
            if wl-paste -t image/png > ${tempPath} 2>/dev/null || xclip -selection clipboard -t image/png -o > ${tempPath} 2>/dev/null; then
                echo "IMAGE:${tempPath}"
            else
                TEXT=$(wl-paste -n 2>/dev/null || xclip -selection clipboard -o 2>/dev/null)
                if [ -n "$TEXT" ]; then
                    echo "TEXT:$TEXT"
                else
                    echo "EMPTY"
                fi
            fi
        `;

        Proc.runCommand(
            "smart-paste",
            ["sh", "-c", checkCmd],
            function(stdout, exitCode) {
                const output = stdout.trim();
                if (output.startsWith("IMAGE:")) {
                    const path = output.substring(6);
                    spawnWindow("file://" + path);
                } else if (output.startsWith("TEXT:")) {
                    const text = output.substring(5).trim();
                    if (text.startsWith("http://") || text.startsWith("https://") || text.startsWith("/")) {
                        spawnWindow(text.startsWith("/") ? "file://" + text : text);
                    } else {
                        ToastService.showError("Clipboard text is not a valid URL or path.");
                    }
                } else {
                    ToastService.showError("No valid image, URL, or path in clipboard.");
                }
            },
            0
        );
    }

    function raiseWindow(win) {
        if (!win) return;
        root.openWindows.forEach(w => {
            if (w && typeof w.isTop !== 'undefined') {
                w.isTop = (w === win);
            }
        });
    }

    function selectFileAndFloat() {
        fileBrowserModal.open();
    }

    function closeAllWindows() {
        const windows = [...root.openWindows];
        windows.forEach(win => {
            if (win && typeof win.close === "function") {
                win.close();
            } else if (win) {
                win.destroy();
            }
        });
    }

    function toggleMinimizeAll() {
        if (root.openWindows.length === 0) return;
        let anyExpanded = root.openWindows.some(win => !win.isMinimized);
        root.openWindows.forEach(win => {
            win.isMinimized = anyExpanded;
        });
    }

    function minimizeAll() {
        root.openWindows.forEach(win => {
            win.isMinimized = true;
        });
    }

    function expandAll() {
        root.openWindows.forEach(win => {
            win.isMinimized = false;
        });
    }

    function spawnWindow(source) {
        if (!source) return;

        // Validation for local files
        if (source.startsWith("file://")) {
            let path = source.substring(7);
            
            // Handle PDF conversion (Level 2: Page Selection)
            if (path.toLowerCase().endsWith(".pdf")) {
                Proc.runCommand("pdf-info", ["pdfinfo", path], function(stdout, exitCode) {
                    if (exitCode !== 0) {
                        ToastService.showError("Failed to read PDF info. Make sure poppler-utils is installed.");
                        return;
                    }
                    
                    let totalPages = 1;
                    let match = stdout.match(/Pages:\s+(\d+)/);
                    if (match) totalPages = parseInt(match[1]);

                    const parsePageSelection = function(input) {
                        const pages = [];
                        const parts = input.trim().split(/\s+/);
                        
                        for (let part of parts) {
                            part = part.trim();
                            if (!part) continue;

                            if (part.includes("-")) {
                                const range = part.split("-");
                                if (range.length === 2) {
                                    const start = parseInt(range[0]);
                                    const end = parseInt(range[1]);
                                    if (!isNaN(start) && !isNaN(end) && start <= end && start >= 1 && end <= totalPages) {
                                        for (let i = start; i <= end; i++) {
                                            pages.push(i);
                                        }
                                    }
                                }
                            } else {
                                const page = parseInt(part);
                                if (!isNaN(page) && page >= 1 && page <= totalPages && !pages.includes(page)) {
                                    pages.push(page);
                                }
                            }
                        }
                        
                        return pages.sort((a, b) => a - b);
                    };

                    const convertPagesSequentially = function(pages, index) {
                        if (index >= pages.length) return;
                        
                        const page = pages[index];
                        const timestamp = Date.now();
                        const tempBase = "/tmp/dms_floaty_pdf_" + timestamp + "_" + page;
                        const tempPng = tempBase + ".png";
                        
                        Proc.runCommand("pdf-convert", ["pdftocairo", "-png", "-singlefile", "-f", "" + page, "-l", "" + page, path, tempBase], function(stdout, exitCode) {
                            if (exitCode === 0) {
                                root._spawnWindow("file://" + tempPng);
                            } else {
                                ToastService.showError("Failed to convert PDF page " + page);
                            }
                            if (index < pages.length - 1) {
                                Qt.callLater(function() {
                                    convertPagesSequentially(pages, index + 1);
                                });
                            }
                        });
                    };

                    if (totalPages > 1) {
                        inputModal.showWithOptions({
                            title: "Floaty PDF",
                            message: "Enter pages: single (1), range (1-3), or list (1 3 5)",
                            initialText: "1",
                            onConfirm: function(text) {
                                const pages = parsePageSelection(text);
                                if (pages.length === 0) {
                                    ToastService.showError("Invalid page selection.");
                                    return;
                                }
                                
                                ToastService.showInfo("Opening " + pages.length + " page(s)...");
                                convertPagesSequentially(pages, 0);
                            }
                        });
                    } else {
                        const timestamp = Date.now();
                        const tempBase = "/tmp/dms_floaty_pdf_" + timestamp + "_1";
                        const tempPng = tempBase + ".png";
                        Proc.runCommand("pdf-convert", ["pdftocairo", "-png", "-singlefile", "-f", "1", "-l", "1", path, tempBase], function(stdout, exitCode) {
                            if (exitCode === 0) {
                                root._spawnWindow("file://" + tempPng);
                            } else {
                                ToastService.showError("Failed to convert PDF page 1");
                            }
                        });
                    }
                });
                return;
            }

            Proc.runCommand("validate-image", ["file", "-b", path], function(stdout, exitCode) {
                const output = stdout.toLowerCase();
                if (exitCode !== 0 || output.includes("empty") || !output.includes("image")) {
                    ToastService.showError("Invalid or corrupted image file.");
                    return;
                }

                // Capture all occurrences and take the last one (prevents matching "density 1x1")
                let w = 0, h = 0;
                let re = /(\d+)\s*x\s*(\d+)/g;
                let match;
                while ((match = re.exec(stdout)) !== null) {
                    w = parseInt(match[1]);
                    h = parseInt(match[2]);
                }

                if (w > 0 && h > 0) {
                    const minSize = root.pluginData.minImageSize || 16;
                    if (w < minSize || h < minSize) {
                        ToastService.showError("Image is too small (" + w + "x" + h + "). Minimum: " + minSize + "px");
                        return;
                    }
                }
                
                root._spawnWindow(source);
            });
        } else {
            // For URLs, we trust the source for now
            root._spawnWindow(source);
        }
    }

    function _spawnWindow(source) {
        const url = Qt.resolvedUrl("FloatyWindow.qml");
        const component = Qt.createComponent(url);

        const initialWidth = root.pluginService.loadPluginData("floaty", "initialScale", 400);
        const spawnPosition = root.pluginService.loadPluginData("floaty", "spawnPosition", "center");

        const createWin = function() {
            const win = component.createObject(root, {
                imageSource: source,
                spawnPosition: spawnPosition,
                initialWidth: initialWidth,
                pluginData: root.pluginData,
                plugin: root
            });

            if (win !== null) {
                root.activeWindowCount++;
                root.openWindows = [...root.openWindows, win];
                root.raiseWindow(win);

                win.closing.connect(function() {
                    root.activeWindowCount--;
                    root.openWindows = root.openWindows.filter(w => w !== win);

                });
            } else {
                ToastService.showError("Failed to float image.");
            }
        };

        if (component.status === Component.Ready) {
            createWin();
        } else if (component.status === Component.Error) {
            console.error("Error loading window component:", component.errorString());
        } else {
            component.statusChanged.connect(function() {
                if (component.status === Component.Ready) createWin();
            });
        }
    }
}
