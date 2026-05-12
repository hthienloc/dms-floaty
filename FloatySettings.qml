import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import Quickshell.Io

PluginSettings {
    id: root
    pluginId: "floaty"

    StyledText {
        width: parent.width
        text: "Floaty Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    // Appearance Card
    StyledRect {
        width: parent.width
        height: appearanceColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: appearanceColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Appearance"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                text: "Changes apply to newly created windows only."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            SliderSetting {
                settingKey: "initialScale"
                label: "Initial Width"
                description: "The width (px) of the image when first opened."
                minimum: 100
                maximum: 800
                unit: "px"
                defaultValue: 400
            }

            SliderSetting {
                settingKey: "maxHeight"
                label: "Max Height"
                description: "Limit image height (px). 0 = no limit."
                minimum: 0
                maximum: 1000
                unit: "px"
                defaultValue: 0
            }

            SliderSetting {
                settingKey: "borderWidth"
                label: "Border Width"
                description: "Thickness of the window border."
                minimum: 0
                maximum: 4
                unit: "px"
                defaultValue: 2
            }

            SelectionSetting {
                settingKey: "borderColor"
                label: "Border Color"
                description: "Color of the window border."
                options: [
                    { label: "Default", value: "outlineVariant" },
                    { label: "Primary", value: "primary" },
                    { label: "Surface", value: "surfaceContainerHighest" },
                    { label: "Transparent", value: "transparent" }
                ]
                defaultValue: "outlineVariant"
            }

            SelectionSetting {
                settingKey: "spawnPosition"
                label: "Spawn Position"
                description: "Where new images appear on screen."
                options: [
                    { label: "Top Left", value: "top-left" },
                    { label: "Top", value: "top" },
                    { label: "Top Right", value: "top-right" },
                    { label: "Left", value: "left" },
                    { label: "Center", value: "center" },
                    { label: "Right", value: "right" },
                    { label: "Bottom Left", value: "bottom-left" },
                    { label: "Bottom", value: "bottom" },
                    { label: "Bottom Right", value: "bottom-right" }
                ]
                defaultValue: "bottom-left"
            }

            SliderSetting {
                settingKey: "edgeSpacing"
                label: "Edge Spacing"
                description: "Distance from screen edges, bars, and other windows."
                minimum: 0
                maximum: 64
                unit: "px"
                defaultValue: Appearance.spacing.normal
            }
        }
    }

    // Auto-Minimize Card
    StyledRect {
        width: parent.width
        height: behaviorColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: behaviorColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Behavior"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            ToggleSetting {
                id: autoMinimizeToggle
                settingKey: "autoMinimize"
                label: "Auto-Minimize"
                description: "Shrink to an icon when idle."
                defaultValue: false
            }

            ToggleSetting {
                settingKey: "showBarPill"
                label: "Show Bar Pill"
                description: "Display the icon on the status bar."
                defaultValue: true
            }

            ToggleSetting {
                settingKey: "autoTiling"
                label: "Auto-Tiling Windows"
                description: "Place new windows in empty spots instead of stacking."
                defaultValue: true
            }

            ToggleSetting {
                settingKey: "showUserGuide"
                label: "Show User Guide"
                description: "Display usage instructions in the popout."
                defaultValue: true
            }

            SliderSetting {
                settingKey: "minImageSize"
                label: "Minimum Image Size"
                description: "Ignore images smaller than this dimension (px) to prevent corrupted spawns."
                minimum: 0
                maximum: 100
                unit: "px"
                defaultValue: 16
            }

            SliderSetting {
                settingKey: "minimizeDelay"
                label: "Minimize Delay"
                description: "Wait time before shrinking (ms)."
                minimum: 1000
                maximum: 10000
                unit: "ms"
                defaultValue: 3000
                enabled: autoMinimizeToggle.checked
            }
        }
    }

    // Shortcut Guide Card
    StyledRect {
        width: parent.width
        height: guideColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: guideColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            StyledText {
                text: "Shortcut Setup Guide"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.primary
            }

            StyledText {
                width: parent.width
                text: "Use these commands in your Window Manager (Niri, Hyprland, etc.) or custom scripts to trigger Floaty actions:"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                wrapMode: Text.WordWrap
            }

            // Command list
            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        { text: "dms screenshot region --no-file --no-notify && dms ipc call floaty floatFromClipboard", label: "Screenshot Region and Float" },
                        { text: "dms screenshot full --no-file --no-notify && dms ipc call floaty floatFromClipboard", label: "Screenshot Full Screen and Float" },
                        { text: "dms ipc call floaty floatFromClipboard", label: "Float from Clipboard" },
                        { text: "dms ipc call floaty selectFileAndFloat", label: "Select File and Float" },
                        { text: "dms ipc call floaty closeAllWindows", label: "Close All Windows" },
                        { text: "dms ipc call floaty toggleMinimizeAll", label: "Toggle Minimize All" },
                        { text: "dms ipc call floaty minimizeAll", label: "Minimize All Windows" },
                        { text: "dms ipc call floaty expandAll", label: "Expand All Windows" },
                        { text: "dms ipc call floaty floatFromUrl \"URL\"", label: "Float from URL/Path" }
                    ]
                    
                    delegate: Column {
                        width: parent.width
                        spacing: 4
                        
                        StyledText {
                            text: modelData.label
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            color: Theme.surfaceVariantText
                        }

                        Rectangle {
                            width: parent.width
                            height: Math.max(40, cmdRow.implicitHeight + 16)
                            color: Theme.surfaceContainer
                            radius: 4
                            
                            Row {
                                id: cmdRow
                                width: parent.width - 16
                                anchors.centerIn: parent
                                spacing: 8
                                
                                StyledText {
                                    width: parent.width - 32
                                    text: modelData.text
                                    font.family: "Monospace"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.secondary
                                    wrapMode: Text.Wrap
                                }

                                DankButton {
                                    width: 24; height: 24
                                    iconName: "content_copy"
                                    backgroundColor: "transparent"
                                    textColor: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: {
                                        Proc.runCommand("copy-ipc", ["wl-copy", "--", modelData.text], function() {
                                            ToastService.showInfo("Copied to clipboard");
                                        });
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                text: "Example for Niri (config.kdl):"
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: Theme.surfaceText
            }

            Rectangle {
                width: parent.width
                height: Math.max(80, niriRow.implicitHeight + 16)
                color: Theme.surfaceContainer
                radius: 4
                
                Row {
                    id: niriRow
                    width: parent.width - 16
                    anchors.centerIn: parent
                    spacing: 8
                    
                    StyledText {
                        id: niriExample
                        width: parent.width - 32
                        text: "bindings {\n    Print { spawn \"sh\" \"-c\" \"dms screenshot region --no-file --no-notify && dms ipc call floaty floatFromClipboard\"; }\n}"
                        font.family: "Monospace"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondary
                        wrapMode: Text.Wrap
                    }

                    DankButton {
                        width: 24; height: 24
                        iconName: "content_copy"
                        backgroundColor: "transparent"
                        textColor: Theme.primary
                        anchors.top: parent.top
                        onClicked: {
                            Proc.runCommand("copy-niri", ["wl-copy", "--", niriExample.text], function() {
                                ToastService.showInfo("Copied to clipboard");
                            });
                        }
                    }
                }
            }
        }
    }
}
