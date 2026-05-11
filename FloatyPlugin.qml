import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

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
        Row {
            spacing: Theme.spacingXS
            DankIcon {
                name: "cloud"
                size: Theme.iconSizeSmall
                color: root.activeWindowCount > 0 ? Theme.primary : Theme.surfaceText
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
    }

    Component {
        id: verticalPillComp
        Column {
            spacing: 2
            DankIcon {
                name: "cloud"
                size: Theme.iconSizeSmall
                color: root.activeWindowCount > 0 ? Theme.primary : Theme.surfaceText
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
    }

    pillRightClickAction: function() {
        root.smartPaste();
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
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            width: 280
            headerText: "Floaty"
            detailsText: "Reference images on top"
            showCloseButton: true
            
            Column {
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
                    height: guideCol.height + Theme.spacingM * 2
                    color: Theme.surfaceContainerHigh
                    radius: Theme.cornerRadius
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
                                DankIcon { name: "bolt"; size: 14; color: Theme.surfaceVariantText }
                                StyledText { text: "Right Click Icon: Fast paste image/link"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
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

    function selectFileAndFloat() {
        Proc.runCommand(
            "select-file",
            ["kdialog", "--getopenfilename", ":", "Images (*.png *.jpg *.jpeg *.webp *.bmp)"],
            function(stdout, exitCode) {
                const filePath = stdout.trim();
                if (exitCode === 0 && filePath !== "") {
                    spawnWindow("file://" + filePath);
                }
            },
            0
        );
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

    function spawnWindow(source) {
        if (!source) return;

        // Validation for local files
        if (source.startsWith("file://")) {
            const path = source.substring(7);
            Proc.runCommand("validate-image", ["file", "-b", path], function(stdout, exitCode) {
                const output = stdout.toLowerCase();
                if (exitCode !== 0 || output.includes("empty") || !output.includes("image data")) {
                    ToastService.showError("Invalid or corrupted image file.");
                    return;
                }

                // Check dimensions if possible (e.g., "1920 x 1080")
                const dimMatch = stdout.match(/(\d+)\s*x\s*(\d+)/);
                if (dimMatch) {
                    const w = parseInt(dimMatch[1]);
                    const h = parseInt(dimMatch[2]);
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
