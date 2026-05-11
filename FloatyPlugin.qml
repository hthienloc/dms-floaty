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

    // Bar Pill - Standardized with QR Generator Style
    horizontalBarPill: showBarPill ? horizontalPillComp : null
    verticalBarPill: showBarPill ? verticalPillComp : null

    Component {
        id: horizontalPillComp
        Row {
            spacing: Theme.spacingS
            DankIcon {
                name: "cloud"
                size: Theme.iconSizeSmall
                color: root.activeWindowCount > 0 ? Theme.primary : Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Component {
        id: verticalPillComp
        Column {
            spacing: Theme.spacingS
            DankIcon {
                name: "cloud"
                size: Theme.iconSizeSmall
                color: root.activeWindowCount > 0 ? Theme.primary : Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    pillRightClickAction: function() {
        root.floatFromClipboard();
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

                StyledRect {
                    width: parent.width
                    height: guideCol.height + Theme.spacingM * 2
                    color: Theme.surfaceContainerHigh
                    radius: Theme.cornerRadius
                    
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
                                StyledText { text: "Right Click Icon: Fast paste"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                            }
                        }
                    }
                }
            }
        }
    }

    function floatFromClipboard() {
        const timestamp = Date.now();
        const tempPath = "/tmp/dms_floaty_" + timestamp + ".png";
        const cmd = "wl-paste -t image/png > " + tempPath + " || xclip -selection clipboard -t image/png -o > " + tempPath;

        Proc.runCommand(
            "save-clipboard",
            ["sh", "-c", cmd],
            function(stdout, exitCode) {
                if (exitCode === 0) {
                    spawnWindow("file://" + tempPath);
                } else {
                    ToastService.showError("No image in clipboard.");
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

    function spawnWindow(source) {
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
