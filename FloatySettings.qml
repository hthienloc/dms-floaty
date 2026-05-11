import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

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
}
