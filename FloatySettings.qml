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

            SliderSetting {
                settingKey: "initialScale"
                label: "Initial Image Size"
                description: "The width (px) of the image when first opened."
                minimumValue: 100
                maximumValue: 800
                stepSize: 50
                unit: "px"
                defaultValue: 400
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
                description: "Shrink to an icon when the mouse leaves the image."
                defaultValue: false
            }

            SliderSetting {
                settingKey: "minimizeDelay"
                label: "Minimize Delay"
                description: "Wait time before shrinking."
                minimumValue: 1000
                maximumValue: 10000
                stepSize: 500
                unit: "ms"
                defaultValue: 3000
                enabled: autoMinimizeToggle.checked
            }
        }
    }
}
