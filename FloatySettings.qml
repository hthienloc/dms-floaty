import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import Quickshell.Io
import "../dms-common"

PluginSettings {
    id: root
    pluginId: "floaty"

    PluginHeader {
        title: "Floaty Settings"
    }

    // Appearance Card
    SettingsCard {
        SectionTitle { text: "Appearance" }

        InfoText {
            text: "Changes apply to newly created windows only."
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

    // Behavior Card
    SettingsCard {
        SectionTitle { text: "Behavior" }

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
            settingKey: "showHints"
            label: "Show Hints"
            description: "Display helpful usage tips and shortcuts at the bottom of the popout."
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

    // Shortcut Guide Card
    SettingsCard {
        SectionTitle { text: "Shortcut Setup Guide" }

        InfoText {
            text: "Use these commands in your Window Manager (Niri, Hyprland, etc.) or custom scripts to trigger Floaty actions:"
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

                delegate: CopyBox {
                    label: modelData.label
                    text: modelData.text
                }
            }
        }

        CopyBox {
            label: "Example for Niri (config.kdl)"
            text: "bindings {\n    Print { spawn \"sh\" \"-c\" \"dms screenshot region --no-file --no-notify && dms ipc call floaty floatFromClipboard\"; }\n}"
        }
    }
}
