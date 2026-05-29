import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import Quickshell.Io
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "floaty"

    // Appearance Card
    SettingsCard {
        SectionTitle { text: I18n.tr("Appearance"); icon: "palette" }

        InfoText {
            text: I18n.tr("Changes apply to newly created windows only.")
        }

        SliderSetting {
            settingKey: "initialScale"
            label: I18n.tr("Initial Width")
            description: I18n.tr("The width (px) of the image when first opened.")
            minimum: 100
            maximum: 800
            unit: "px"
            defaultValue: 400
        }

        SliderSetting {
            settingKey: "maxHeight"
            label: I18n.tr("Max Height")
            description: I18n.tr("Limit image height (px). 0 = no limit.")
            minimum: 0
            maximum: 1000
            unit: "px"
            defaultValue: 0
        }

        SliderSetting {
            settingKey: "borderWidth"
            label: I18n.tr("Border Width")
            description: I18n.tr("Thickness of the window border.")
            minimum: 0
            maximum: 4
            unit: "px"
            defaultValue: 2
        }

        SelectionSetting {
            settingKey: "borderColor"
            label: I18n.tr("Border Color")
            description: I18n.tr("Color of the window border.")
            options: [
                { label: I18n.tr("Default"), value: "outlineVariant" },
                { label: I18n.tr("Primary"), value: "primary" },
                { label: I18n.tr("Surface"), value: "surfaceContainerHighest" },
                { label: I18n.tr("Transparent"), value: "transparent" }
            ]
            defaultValue: "outlineVariant"
        }

        SelectionSetting {
            settingKey: "spawnPosition"
            label: I18n.tr("Spawn Position")
            description: I18n.tr("Where new images appear on screen.")
            options: [
                { label: I18n.tr("Top Left"), value: "top-left" },
                { label: I18n.tr("Top"), value: "top" },
                { label: I18n.tr("Top Right"), value: "top-right" },
                { label: I18n.tr("Left"), value: "left" },
                { label: I18n.tr("Center"), value: "center" },
                { label: I18n.tr("Right"), value: "right" },
                { label: I18n.tr("Bottom Left"), value: "bottom-left" },
                { label: I18n.tr("Bottom"), value: "bottom" },
                { label: I18n.tr("Bottom Right"), value: "bottom-right" }
            ]
            defaultValue: "bottom-left"
        }

        SliderSetting {
            settingKey: "edgeSpacing"
            label: I18n.tr("Edge Spacing")
            description: I18n.tr("Distance from screen edges, bars, and other windows.")
            minimum: 0
            maximum: 64
            unit: "px"
            defaultValue: Appearance.spacing.normal
        }
    }

    // Behavior Card
    SettingsCard {
        SectionTitle { text: I18n.tr("Behavior"); icon: "settings" }

        ToggleSetting {
            id: autoMinimizeToggle
            settingKey: "autoMinimize"
            label: I18n.tr("Auto-Minimize")
            description: I18n.tr("Shrink to an icon when idle.")
            defaultValue: false
        }

        ToggleSetting {
            settingKey: "showBarPill"
            label: I18n.tr("Show Bar Pill")
            description: I18n.tr("Display the icon on the status bar.")
            defaultValue: true
        }

        ToggleSetting {
            settingKey: "autoTiling"
            label: I18n.tr("Auto-Tiling Windows")
            description: I18n.tr("Place new windows in empty spots instead of stacking.")
            defaultValue: true
        }

        SliderSetting {
            settingKey: "minImageSize"
            label: I18n.tr("Minimum Image Size")
            description: I18n.tr("Ignore images smaller than this dimension (px) to prevent corrupted spawns.")
            minimum: 0
            maximum: 100
            unit: "px"
            defaultValue: 16
        }

        SliderSetting {
            settingKey: "minimizeDelay"
            label: I18n.tr("Minimize Delay")
            description: I18n.tr("Wait time before shrinking (ms).")
            minimum: 1000
            maximum: 10000
            unit: "ms"
            defaultValue: 3000
            enabled: autoMinimizeToggle.checked
        }
    }

    // Shortcut Guide Card
    SettingsCard {
        SectionTitle { text: I18n.tr("Shortcut Setup Guide"); icon: "keyboard" }

        InfoText {
            text: I18n.tr("Use these commands in your Window Manager (Niri, Hyprland, etc.) or custom scripts to trigger Floaty actions:")
        }

        // Command list
        Column {
            width: parent.width
            spacing: Theme.spacingS

            Repeater {
                model: [
                    { text: "dms screenshot region --no-file --no-notify && dms ipc call floaty floatFromClipboard", label: I18n.tr("Screenshot Region and Float") },
                    { text: "dms screenshot full --no-file --no-notify && dms ipc call floaty floatFromClipboard", label: I18n.tr("Screenshot Full Screen and Float") },
                    { text: "dms ipc call floaty floatFromClipboard", label: I18n.tr("Float from Clipboard") },
                    { text: "dms ipc call floaty selectFileAndFloat", label: I18n.tr("Select File and Float") },
                    { text: "dms ipc call floaty closeAllWindows", label: I18n.tr("Close All Windows") },
                    { text: "dms ipc call floaty toggleMinimizeAll", label: I18n.tr("Toggle Minimize All") },
                    { text: "dms ipc call floaty minimizeAll", label: I18n.tr("Minimize All Windows") },
                    { text: "dms ipc call floaty expandAll", label: I18n.tr("Expand All Windows") },
                    { text: "dms ipc call floaty floatFromUrl \"URL\"", label: I18n.tr("Float from URL/Path") }
                ]

                delegate: CopyBox {
                    label: modelData.label
                    text: modelData.text
                }
            }
        }

        CopyBox {
            label: I18n.tr("Example for Niri (config.kdl)")
            text: "bindings {\n    Print { spawn \"sh\" \"-c\" \"dms screenshot region --no-file --no-notify && dms ipc call floaty floatFromClipboard\"; }\n}"
        }
    }

    SettingsCard {
        SectionTitle { text: I18n.tr("Interface"); icon: "display_settings" }

        ToggleSetting {
            settingKey: "showHints"
            label: I18n.tr("Show Hints")
            description: I18n.tr("Display helpful usage tips and shortcuts at the bottom of the popout.")
            defaultValue: true
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-floaty"
    }
}
